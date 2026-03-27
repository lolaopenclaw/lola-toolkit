#!/bin/bash
set -euo pipefail
TARGET_FILE="/home/mleon/.openclaw/workspace/scripts/session-log-rotation.sh"
[ ! -f "$TARGET_FILE" ] && echo "999999" && exit 1
bash -n "$TARGET_FILE" 2>/dev/null || { echo "999999"; exit 1; }

START=$(date +%s%N)
LINE_COUNT=$(wc -l < "$TARGET_FILE")
COMMAND_COUNT=$(grep -cE "^\s*(find|gzip|rm)" "$TARGET_FILE" || echo 0)
ESTIMATED_TIME_MS=$((COMMAND_COUNT * 12 + LINE_COUNT / 10))
END=$(date +%s%N)
VALIDATION_TIME_MS=$(( (END - START) / 1000000 ))

ERROR_PENALTY=0
grep -q "set -" "$TARGET_FILE" || ERROR_PENALTY=$((ERROR_PENALTY + 1000))

QUALITY_PENALTY=0
FOR_COUNT=$(grep -c "^for " "$TARGET_FILE" || echo 0)
[ "$FOR_COUNT" -ge 2 ] && QUALITY_PENALTY=$((QUALITY_PENALTY + 100))
XARGS_COUNT=$(grep -c "xargs" "$TARGET_FILE" || echo 0)
[ "$XARGS_COUNT" -ge 1 ] && QUALITY_PENALTY=$((QUALITY_PENALTY - 30))

SCORE=$((ESTIMATED_TIME_MS + VALIDATION_TIME_MS + ERROR_PENALTY + QUALITY_PENALTY))
echo "$SCORE"
