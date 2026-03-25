#!/usr/bin/env bash
# notification-batcher.sh - Batch notifications by priority to reduce noise
# Usage:
#   bash scripts/notification-batcher.sh add <priority> <source> <message>
#   bash scripts/notification-batcher.sh flush <priority-level>

set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
QUEUE_FILE="$WORKSPACE/data/notification-queue.jsonl"
LOCK_FILE="$WORKSPACE/data/notification-queue.lock"

# Emoji mapping for common sources
declare -A SOURCE_EMOJI=(
    ["security-audit"]="🔐"
    ["backup"]="💾"
    ["autoimprove"]="🔬"
    ["cleanup"]="🧹"
    ["surf"]="🌊"
    ["surf-conditions"]="🌊"
    ["health"]="💊"
    ["cost-alert"]="💰"
    ["api-health"]="🏥"
    ["rate-limit"]="⚡"
    ["config-drift"]="⚙️"
    ["github"]="🐙"
    ["pr-review"]="👀"
)

# Priority levels (for reference)
# critical: send immediately, skip batching
# high: batch every 1 hour
# medium: batch every 3 hours
# low: batch in morning report only

usage() {
    cat <<EOF
Usage:
  $0 add <priority> <source> <message>
      Add notification to queue
      Priority: critical | high | medium | low

  $0 flush <priority-level> [--telegram-chat-id CHAT_ID]
      Flush and send digest for given priority level and below
      Priority levels: critical | high | medium | low
      Optional: --telegram-chat-id (defaults to TELEGRAM_CHAT_ID env var)

Examples:
  $0 add low "surf-conditions" "Olas de 1.2m en Zarautz"
  $0 flush medium
  $0 flush high --telegram-chat-id -1003768820594
EOF
    exit 1
}

# Initialize queue file if needed
init_queue() {
    mkdir -p "$(dirname "$QUEUE_FILE")"
    touch "$QUEUE_FILE"
}

# Add notification to queue with file locking
add_notification() {
    local priority="$1"
    local source="$2"
    local message="$3"
    
    # Validate priority
    if [[ ! "$priority" =~ ^(critical|high|medium|low)$ ]]; then
        echo "❌ Invalid priority: $priority" >&2
        echo "   Must be: critical, high, medium, or low" >&2
        exit 1
    fi
    
    init_queue
    
    # Create JSON line (compact, single line)
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local json_line
    json_line=$(jq -nc \
        --arg ts "$timestamp" \
        --arg src "$source" \
        --arg pri "$priority" \
        --arg msg "$message" \
        '{timestamp: $ts, source: $src, priority: $pri, message: $msg}')
    
    # Atomic append with flock
    (
        flock -x 200
        echo "$json_line" >> "$QUEUE_FILE"
    ) 200>"$LOCK_FILE"
    
    echo "✅ Queued [$priority] $source: $message"
    
    # If critical, flush immediately
    if [[ "$priority" == "critical" ]]; then
        echo "🚨 Critical priority - flushing immediately"
        flush_notifications "critical" "${TELEGRAM_CHAT_ID:-}"
    fi
}

# Flush notifications at or below given priority level
flush_notifications() {
    local flush_priority="$1"
    local telegram_chat_id="${2:-${TELEGRAM_CHAT_ID:-}}"
    
    # Validate priority
    if [[ ! "$flush_priority" =~ ^(critical|high|medium|low)$ ]]; then
        echo "❌ Invalid priority level: $flush_priority" >&2
        exit 1
    fi
    
    init_queue
    
    # Priority order for filtering (higher number = higher priority)
    # When flushing at a level, include that level AND all lower levels
    declare -A priority_levels=(
        ["critical"]=4
        ["high"]=3
        ["medium"]=2
        ["low"]=1
    )
    
    local flush_level=${priority_levels[$flush_priority]}
    
    # Check if queue is empty early
    if [[ ! -s "$QUEUE_FILE" ]]; then
        echo "📭 Queue is empty"
        return 0
    fi
    
    # Create temp files for filtered messages
    local messages_file=$(mktemp)
    local remaining_file=$(mktemp)
    
    # Read and filter messages with file locking
    (
        flock -x 200
        
        while IFS= read -r line; do
            # Skip empty lines
            [[ -z "$line" ]] && continue
            
            local msg_priority
            msg_priority=$(echo "$line" | jq -r '.priority' 2>/dev/null) || continue
            
            # Skip malformed JSON
            [[ -z "$msg_priority" || "$msg_priority" == "null" ]] && continue
            
            local msg_level=${priority_levels[$msg_priority]:-0}
            
            # Include messages at flush_level or BELOW (lower numbers)
            # e.g., flush medium (2) includes medium (2) + low (1)
            if (( msg_level > 0 && msg_level <= flush_level )); then
                echo "$line" >> "$messages_file"
            else
                # Keep higher priority messages in queue
                echo "$line" >> "$remaining_file"
            fi
        done < "$QUEUE_FILE"
        
        # Write back remaining messages
        if [[ -s "$remaining_file" ]]; then
            cat "$remaining_file" > "$QUEUE_FILE"
        else
            : > "$QUEUE_FILE"
        fi
        
    ) 200>"$LOCK_FILE"
    
    # Check if we have messages to flush
    local message_count=$(wc -l < "$messages_file" 2>/dev/null || echo "0")
    
    if [[ "$message_count" -eq 0 ]]; then
        echo "📭 No messages at or below priority '$flush_priority'"
        rm -f "$messages_file" "$remaining_file"
        return 0
    fi
    
    # Format digest
    local count="$message_count"
    local digest_header
    
    local plural="notifications"
    [[ "$count" -eq 1 ]] && plural="notification"
    
    case "$flush_priority" in
        critical) digest_header="🚨 Critical Alert" ;;
        high) digest_header="📬 Digest (1h) — $count $plural" ;;
        medium) digest_header="📬 Digest (3h) — $count $plural" ;;
        low) digest_header="🌅 Morning Report — $count $plural" ;;
    esac
    
    local digest="$digest_header\n\n"
    
    while IFS= read -r msg_json; do
        [[ -z "$msg_json" ]] && continue
        
        local source
        local message
        source=$(echo "$msg_json" | jq -r '.source')
        message=$(echo "$msg_json" | jq -r '.message')
        
        # Get emoji for source
        local emoji="${SOURCE_EMOJI[$source]:-📌}"
        
        digest+="$emoji [$source] $message\n"
    done < "$messages_file"
    
    # Cleanup temp files
    rm -f "$messages_file" "$remaining_file"
    
    # Output digest
    echo -e "$digest"
    
    # Send to Telegram if chat ID provided
    if [[ -n "$telegram_chat_id" ]]; then
        echo ""
        echo "📤 Sending to Telegram chat: $telegram_chat_id"
        
        # Use openclaw message tool or direct telegram-send
        if command -v openclaw &>/dev/null; then
            echo -e "$digest" | openclaw message send --target "$telegram_chat_id" --stdin
        elif command -v telegram-send &>/dev/null; then
            echo -e "$digest" | telegram-send --stdin
        else
            echo "⚠️  No Telegram sender available (openclaw message or telegram-send)"
        fi
    fi
    
    echo ""
    local msg_plural="messages"
    [[ "$count" -eq 1 ]] && msg_plural="message"
    echo "✅ Flushed $count $msg_plural at priority '$flush_priority' and below"
}

# Main command dispatcher
main() {
    if [[ $# -lt 1 ]]; then
        usage
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        add)
            if [[ $# -lt 3 ]]; then
                echo "❌ Missing arguments for 'add'" >&2
                usage
            fi
            add_notification "$1" "$2" "$3"
            ;;
        flush)
            if [[ $# -lt 1 ]]; then
                echo "❌ Missing priority level for 'flush'" >&2
                usage
            fi
            local priority="$1"
            shift
            
            local chat_id=""
            if [[ $# -ge 2 ]] && [[ "$1" == "--telegram-chat-id" ]]; then
                chat_id="$2"
            fi
            
            flush_notifications "$priority" "$chat_id"
            ;;
        *)
            echo "❌ Unknown command: $command" >&2
            usage
            ;;
    esac
}

main "$@"
