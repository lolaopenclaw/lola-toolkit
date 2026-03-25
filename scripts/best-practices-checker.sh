#!/usr/bin/env bash
# best-practices-checker.sh - Download and compare AI provider best practices
# Part of OpenClaw workspace automation

set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
MEMORY_DIR="$WORKSPACE/memory/best-practices"
CHANGELOG="$MEMORY_DIR/changelog.md"
DATE=$(date +%Y-%m-%d)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

# Ensure directory exists
mkdir -p "$MEMORY_DIR"

# Function to download and save best practices
download_practices() {
    local provider="$1"
    local url="$2"
    local output_file="$MEMORY_DIR/${provider}-${DATE}.md"
    
    log "Downloading $provider best practices..."
    
    # Use readable text extraction (lynx/w3m preferred, curl as fallback)
    if command -v lynx &> /dev/null; then
        # Lynx does excellent HTML -> text conversion
        if lynx -dump -nolist -width=120 "$url" > "$output_file" 2>/dev/null; then
            log "✓ Fetched using lynx"
        else
            warn "Lynx fetch failed, trying curl..."
            curl -sSL -A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" "$url" > "$output_file" || {
                error "Failed to download $provider practices from $url"
                return 1
            }
        fi
    elif command -v w3m &> /dev/null; then
        # w3m is also good for text extraction
        if w3m -dump "$url" > "$output_file" 2>/dev/null; then
            log "✓ Fetched using w3m"
        else
            warn "w3m fetch failed, trying curl..."
            curl -sSL -A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" "$url" > "$output_file" || {
                error "Failed to download $provider practices from $url"
                return 1
            }
        fi
    else
        # Fallback to curl (will be HTML)
        warn "No text browser available (lynx/w3m), downloading raw HTML..."
        curl -sSL -A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" "$url" > "$output_file" || {
            error "Failed to download $provider practices from $url"
            return 1
        }
    fi
    
    # Verify we got content
    if [[ ! -s "$output_file" ]]; then
        error "Downloaded file is empty: $output_file"
        return 1
    fi
    
    log "Saved to: $output_file"
    return 0
}

# Function to find most recent previous version
find_previous() {
    local provider="$1"
    # Find most recent file that's not today's
    find "$MEMORY_DIR" -name "${provider}-*.md" ! -name "${provider}-${DATE}.md" -type f | sort -r | head -n1
}

# Function to compare and generate diff summary
compare_versions() {
    local provider="$1"
    local current="$MEMORY_DIR/${provider}-${DATE}.md"
    local previous=$(find_previous "$provider")
    
    if [[ -z "$previous" ]]; then
        log "$provider: First download, no comparison available"
        echo "## $provider - $DATE (Initial Download)" >> "$CHANGELOG"
        echo "" >> "$CHANGELOG"
        echo "First baseline download. No changes to compare." >> "$CHANGELOG"
        echo "" >> "$CHANGELOG"
        return 0
    fi
    
    log "$provider: Comparing with previous version..."
    
    # Check if files are identical
    if diff -q "$current" "$previous" &> /dev/null; then
        log "$provider: No changes detected"
        return 0
    fi
    
    # Generate diff summary
    log "$provider: Changes detected! Generating summary..."
    
    echo "## $provider - $DATE" >> "$CHANGELOG"
    echo "" >> "$CHANGELOG"
    echo "**Previous version:** $(basename "$previous")" >> "$CHANGELOG"
    echo "" >> "$CHANGELOG"
    echo "### Changes Summary" >> "$CHANGELOG"
    echo "" >> "$CHANGELOG"
    
    # Get line count differences
    local prev_lines=$(wc -l < "$previous")
    local curr_lines=$(wc -l < "$current")
    local line_diff=$((curr_lines - prev_lines))
    
    if [[ $line_diff -gt 0 ]]; then
        echo "- Document grew by $line_diff lines" >> "$CHANGELOG"
    elif [[ $line_diff -lt 0 ]]; then
        echo "- Document shortened by ${line_diff#-} lines" >> "$CHANGELOG"
    fi
    
    # Generate unified diff (limited to significant changes)
    echo "" >> "$CHANGELOG"
    echo "### Detailed Changes" >> "$CHANGELOG"
    echo "" >> "$CHANGELOG"
    echo '```diff' >> "$CHANGELOG"
    diff -u "$previous" "$current" | head -n 200 >> "$CHANGELOG" || true
    echo '```' >> "$CHANGELOG"
    echo "" >> "$CHANGELOG"
    
    warn "$provider: CHANGES DETECTED - Review $CHANGELOG"
    return 1  # Return 1 to indicate changes found
}

# Main execution
main() {
    log "Starting best practices check for $DATE"
    
    # Initialize changelog if it doesn't exist
    if [[ ! -f "$CHANGELOG" ]]; then
        cat > "$CHANGELOG" << 'EOF'
# Best Practices Changelog

This file tracks changes in AI provider prompting best practices over time.

---

EOF
    fi
    
    local changes_detected=0
    
    # Anthropic
    if download_practices "anthropic" "https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview"; then
        compare_versions "anthropic" || changes_detected=1
    fi
    
    # Google
    if download_practices "google" "https://ai.google.dev/gemini-api/docs/prompting-strategies"; then
        compare_versions "google" || changes_detected=1
    fi
    
    # OpenAI
    if download_practices "openai" "https://platform.openai.com/docs/guides/prompt-engineering"; then
        compare_versions "openai" || changes_detected=1
    fi
    
    # Summary
    log "Best practices check complete"
    log "Files saved in: $MEMORY_DIR"
    log "Changelog: $CHANGELOG"
    
    if [[ $changes_detected -eq 1 ]]; then
        warn "⚠️  Changes detected in best practices - review recommended"
        return 1
    else
        log "✓ No significant changes detected"
        return 0
    fi
}

# Run main function
main "$@"
