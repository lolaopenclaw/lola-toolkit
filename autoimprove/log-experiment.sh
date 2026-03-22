#!/bin/bash
# =============================================================================
# log-experiment.sh — Log experiment results to JSONL
# =============================================================================
# Usage: log-experiment.sh <target> <change_description> <score_before> <score_after> <kept|discarded>
# Format: {"ts": "ISO8601", "target": "...", "change": "...", "before": N, "after": N, "kept": bool, "delta": N}
# =============================================================================

set -euo pipefail

if [ $# -ne 5 ]; then
    echo "Usage: $0 <target> <change_description> <score_before> <score_after> <kept|discarded>"
    exit 1
fi

TARGET="$1"
CHANGE="$2"
BEFORE="$3"
AFTER="$4"
STATUS="$5"

# Validate status
if [ "$STATUS" != "kept" ] && [ "$STATUS" != "discarded" ]; then
    echo "Error: status must be 'kept' or 'discarded'"
    exit 1
fi

# Convert status to boolean
if [ "$STATUS" = "kept" ]; then
    KEPT="true"
else
    KEPT="false"
fi

# Calculate delta
DELTA=$(echo "$BEFORE - $AFTER" | bc)

# Generate timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Log file location
LOG_FILE="/home/mleon/.openclaw/workspace/autoimprove/experiment-log.jsonl"

# Escape JSON strings
escape_json() {
    echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\n/\\n/g'
}

TARGET_ESC=$(escape_json "$TARGET")
CHANGE_ESC=$(escape_json "$CHANGE")

# Build JSON line
JSON_LINE=$(cat <<EOF
{"ts":"$TIMESTAMP","target":"$TARGET_ESC","change":"$CHANGE_ESC","before":$BEFORE,"after":$AFTER,"kept":$KEPT,"delta":$DELTA}
EOF
)

# Append to log file
echo "$JSON_LINE" >> "$LOG_FILE"

# Output confirmation
echo "✅ Logged experiment: $TARGET ($STATUS, Δ=$DELTA)"
