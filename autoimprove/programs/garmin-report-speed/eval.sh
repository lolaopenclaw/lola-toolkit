#!/bin/bash
set -euo pipefail

TARGET_FILE="/home/mleon/.openclaw/workspace/scripts/garmin-health-report.sh"

if [ ! -f "$TARGET_FILE" ]; then
    echo "999999"
    exit 1
fi

# Syntax check
if ! bash -n "$TARGET_FILE" 2>/dev/null; then
    echo "999999"
    exit 1
fi

START=$(date +%s%N)
LINE_COUNT=$(wc -l < "$TARGET_FILE")
COMMAND_COUNT=$(grep -cE "^\s*(curl|jq|awk|sed|grep)" "$TARGET_FILE" || echo 0)
ESTIMATED_TIME_MS=$((COMMAND_COUNT * 10 + LINE_COUNT / 10))
END=$(date +%s%N)
VALIDATION_TIME_MS=$(( (END - START) / 1000000 ))

ERROR_PENALTY=0
if ! grep -q "set -e" "$TARGET_FILE"; then
    ERROR_PENALTY=$((ERROR_PENALTY + 1000))
fi

QUALITY_PENALTY=0
FUNCTION_COUNT=$(grep -cE "^[a-z_]+\(\)" "$TARGET_FILE" 2>/dev/null || echo 0)
FUNCTION_COUNT=$(echo "$FUNCTION_COUNT" | tr -d '\n')
if [ "$FUNCTION_COUNT" -eq 0 ] && [ "$LINE_COUNT" -gt 50 ]; then
    QUALITY_PENALTY=$((QUALITY_PENALTY + 500))
fi

SCORE=$((ESTIMATED_TIME_MS + VALIDATION_TIME_MS + ERROR_PENALTY + QUALITY_PENALTY))
echo "$SCORE"
