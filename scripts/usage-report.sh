#!/bin/bash
# usage-report.sh - API cost tracker for OpenClaw sessions
# Aggregates costs from session JSONL files with flexible reporting

set -euo pipefail

# Configuration
SESSIONS_DIR="$HOME/.openclaw/agents/main/sessions"
DEFAULT_MODE="month"

# Parse arguments
MODE="$DEFAULT_MODE"
BY_MODEL=false
BY_SESSION=false
ALERT_THRESHOLD=""

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

API cost reporter for OpenClaw session logs.

OPTIONS:
  --today           Show today's costs only
  --yesterday       Show yesterday's costs only
  --week            Show last 7 days
  --month           Show current month (default)
  --by-model        Breakdown by model
  --by-session      Breakdown by session/cron
  --alert AMOUNT    Exit code 1 if daily spend exceeds AMOUNT (e.g., --alert 10)
  -h, --help        Show this help

EXAMPLES:
  $(basename "$0")                    # Monthly report
  $(basename "$0") --today --by-model # Today's spend by model
  $(basename "$0") --alert 25         # Alert if today > \$25

Session logs: $SESSIONS_DIR
EOF
  exit 0
}

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --today)     MODE="today"; shift ;;
    --yesterday) MODE="yesterday"; shift ;;
    --week)      MODE="week"; shift ;;
    --month)     MODE="month"; shift ;;
    --by-model)  BY_MODEL=true; shift ;;
    --by-session) BY_SESSION=true; shift ;;
    --alert)     ALERT_THRESHOLD="$2"; shift 2 ;;
    -h|--help)   show_help ;;
    *) echo "❌ Unknown option: $1 (try --help)"; exit 1 ;;
  esac
done

# Validate dependencies
for cmd in jq date; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "❌ Required: $cmd"; exit 1; }
done

# Validate directory
[ -d "$SESSIONS_DIR" ] || { echo "❌ Sessions directory not found: $SESSIONS_DIR"; exit 1; }

# Date calculations
CURRENT_MONTH=$(date +%Y-%m)
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)
WEEK_AGO=$(date -d "7 days ago" +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d)

# Determine date filter based on mode
case "$MODE" in
  today)
    DATE_FILTER=".date == \"$TODAY\""
    PERIOD_LABEL="Today ($TODAY)"
    ;;
  yesterday)
    DATE_FILTER=".date == \"$YESTERDAY\""
    PERIOD_LABEL="Yesterday ($YESTERDAY)"
    ;;
  week)
    DATE_FILTER=".date >= \"$WEEK_AGO\""
    PERIOD_LABEL="Last 7 Days ($WEEK_AGO to $TODAY)"
    ;;
  month)
    DATE_FILTER=".date | startswith(\"$CURRENT_MONTH\")"
    PERIOD_LABEL="Month ($CURRENT_MONTH)"
    ;;
esac

# Build jq aggregation script
JQ_SCRIPT='
  # Extract and parse records
  (map({
    date: .date,
    model: .model,
    session: .session,
    cost: .cost,
    input: .input,
    output: .output
  })) as $records |

  # Calculate totals
  ($records | map(.cost) | add // 0 | . * 10000 | round / 10000) as $total_cost |
  ($records | map(.input) | add // 0) as $total_input |
  ($records | map(.output) | add // 0) as $total_output |
  ($records | length) as $total_requests |

  # Build base result
  {
    period: "'"$PERIOD_LABEL"'",
    total_cost: $total_cost,
    total_input: $total_input,
    total_output: $total_output,
    total_requests: $total_requests
  }
'

# Add by-model breakdown if requested
if $BY_MODEL; then
  JQ_SCRIPT+=' | . + {
    by_model: ($records | group_by(.model) | map({
      model: .[0].model,
      cost: (map(.cost) | add | . * 10000 | round / 10000),
      input: (map(.input) | add),
      output: (map(.output) | add),
      requests: length
    }) | sort_by(-.cost))
  }'
fi

# Add by-session breakdown if requested
if $BY_SESSION; then
  JQ_SCRIPT+=' | . + {
    by_session: ($records | group_by(.session) | map({
      session: .[0].session,
      cost: (map(.cost) | add | . * 10000 | round / 10000),
      input: (map(.input) | add),
      output: (map(.output) | add),
      requests: length
    }) | sort_by(-.cost) | .[0:20])
  }'
fi

# Extract and aggregate
# Process each file to capture session ID from filename
# Support both .jsonl and .jsonl.gz files
RESULT=$(
  (
    # Process uncompressed .jsonl files
    for file in "$SESSIONS_DIR"/*.jsonl; do
      [ -f "$file" ] || continue
      session_id=$(basename "$file" .jsonl)
      jq -c --arg session_id "$session_id" \
        'select(.message.usage.cost.total != null) | {
          date: (.timestamp | split("T")[0]),
          model: .message.model,
          session: $session_id,
          cost: .message.usage.cost.total,
          input: .message.usage.input,
          output: .message.usage.output
        }' "$file" 2>/dev/null
    done
    
    # Process compressed .jsonl.gz files
    for file in "$SESSIONS_DIR"/*.jsonl.gz; do
      [ -f "$file" ] || continue
      session_id=$(basename "$file" .jsonl.gz)
      zcat "$file" 2>/dev/null | jq -c --arg session_id "$session_id" \
        'select(.message.usage.cost.total != null) | {
          date: (.timestamp | split("T")[0]),
          model: .message.model,
          session: $session_id,
          cost: .message.usage.cost.total,
          input: .message.usage.input,
          output: .message.usage.output
        }' 2>/dev/null
    done
  ) | jq -s --arg date_filter "$DATE_FILTER" \
    "map(select($DATE_FILTER)) | $JQ_SCRIPT" 2>/dev/null
)


# Output result
echo "$RESULT" | jq .

# Check alert threshold (only for today mode)
if [[ -n "$ALERT_THRESHOLD" ]]; then
  DAILY_COST=$(echo "$RESULT" | jq -r '.total_cost')
  
  # Use bc for floating point comparison
  if command -v bc >/dev/null 2>&1; then
    if (( $(echo "$DAILY_COST > $ALERT_THRESHOLD" | bc -l) )); then
      echo "⚠️  ALERT: Today's spend (\$$DAILY_COST) exceeds threshold (\$$ALERT_THRESHOLD)" >&2
      exit 1
    fi
  else
    # Fallback: integer comparison (multiply by 100 for cents)
    DAILY_CENTS=$(echo "$DAILY_COST * 100 / 1" | bc 2>/dev/null || echo "0")
    THRESHOLD_CENTS=$(echo "$ALERT_THRESHOLD * 100 / 1" | bc 2>/dev/null || echo "0")
    if [[ "$DAILY_CENTS" -gt "$THRESHOLD_CENTS" ]]; then
      echo "⚠️  ALERT: Today's spend (\$$DAILY_COST) exceeds threshold (\$$ALERT_THRESHOLD)" >&2
      exit 1
    fi
  fi
fi

exit 0
