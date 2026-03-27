#!/bin/bash
set -euo pipefail
TARGET_FILE="/home/mleon/.openclaw/workspace/scripts/track-autoresearch.sh"
[ ! -f "$TARGET_FILE" ] && echo "999999" && exit 1
bash -n "$TARGET_FILE" 2>/dev/null || { echo "999999"; exit 1; }

START=$(date +%s%N)
LINE_COUNT=$(wc -l < "$TARGET_FILE")
COMMAND_COUNT=$(grep -cE "gh api" "$TARGET_FILE" || echo 0)
ESTIMATED_TIME_MS=$((COMMAND_COUNT * 25 + LINE_COUNT / 10))
END=$(date +%s%N)
VALIDATION_TIME_MS=$(( (END - START) / 1000000 ))

ERROR_PENALTY=0
grep -q "set -e" "$TARGET_FILE" || ERROR_PENALTY=$((ERROR_PENALTY + 1000))

QUALITY_PENALTY=0
PARALLEL_COUNT=$(grep -c " &$" "$TARGET_FILE" || echo 0)
[ "$PARALLEL_COUNT" -ge 3 ] && QUALITY_PENALTY=$((QUALITY_PENALTY - 60))

SCORE=$((ESTIMATED_TIME_MS + VALIDATION_TIME_MS + ERROR_PENALTY + QUALITY_PENALTY))
echo "$SCORE"
