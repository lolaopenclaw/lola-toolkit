#!/bin/bash
set -euo pipefail
TARGET_FILE="/home/mleon/.openclaw/workspace/scripts/rate-limit-alert-sender.sh"
[ ! -f "$TARGET_FILE" ] && echo "999999" && exit 1
bash -n "$TARGET_FILE" 2>/dev/null || { echo "999999"; exit 1; }

START=$(date +%s%N)
LINE_COUNT=$(wc -l < "$TARGET_FILE")
COMMAND_COUNT=$(grep -cE "^\s*(jq|cat|echo)" "$TARGET_FILE" || echo 0)
ESTIMATED_TIME_MS=$((COMMAND_COUNT * 10 + LINE_COUNT / 10))
END=$(date +%s%N)
VALIDATION_TIME_MS=$(( (END - START) / 1000000 ))

ERROR_PENALTY=0
grep -q "set -e" "$TARGET_FILE" || ERROR_PENALTY=$((ERROR_PENALTY + 1000))
grep -qE "rm -rf /|sudo rm" "$TARGET_FILE" && ERROR_PENALTY=$((ERROR_PENALTY + 10000))

QUALITY_PENALTY=0
JQ_COUNT=$(grep -c "jq -r" "$TARGET_FILE" || echo 0)
[ "$JQ_COUNT" -ge 4 ] && QUALITY_PENALTY=$((QUALITY_PENALTY + 100))

SCORE=$((ESTIMATED_TIME_MS + VALIDATION_TIME_MS + ERROR_PENALTY + QUALITY_PENALTY))
echo "$SCORE"
