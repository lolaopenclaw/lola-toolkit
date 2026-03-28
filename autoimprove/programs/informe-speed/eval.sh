#!/bin/bash
set -euo pipefail
TARGET_FILE="/home/mleon/.openclaw/workspace/scripts/informe-matutino-auto.sh"
[ ! -f "$TARGET_FILE" ] && echo "999999" && exit 1
bash -n "$TARGET_FILE" 2>/dev/null || { echo "999999"; exit 1; }
LINE_COUNT=$(wc -l < "$TARGET_FILE")
COMMAND_COUNT=$(grep -cE "^\s*(curl|echo|grep|awk|sed)" "$TARGET_FILE" || echo 0)
ESTIMATED_TIME_MS=$((COMMAND_COUNT * 10 + LINE_COUNT / 10))
ERROR_PENALTY=0
! grep -q "set -e" "$TARGET_FILE" && ERROR_PENALTY=$((ERROR_PENALTY + 1000))
QUALITY_PENALTY=0
FUNCTION_COUNT=$(grep -E "^[a-z_]+\(\)" "$TARGET_FILE" 2>/dev/null | wc -l || echo 0)
FUNCTION_COUNT=$(echo "$FUNCTION_COUNT" | tr -d '\n' | tr -d ' ')
if [ "$FUNCTION_COUNT" -eq 0 ] && [ "$LINE_COUNT" -gt 50 ]; then
    QUALITY_PENALTY=$((QUALITY_PENALTY + 500))
fi
echo $((ESTIMATED_TIME_MS + ERROR_PENALTY + QUALITY_PENALTY))
