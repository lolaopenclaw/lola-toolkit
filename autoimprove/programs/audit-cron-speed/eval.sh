#!/bin/bash
# =============================================================================
# eval.sh — audit-cron-notifications.sh evaluation
# =============================================================================

set -euo pipefail

TARGET_FILE="/home/mleon/.openclaw/workspace/scripts/audit-cron-notifications.sh"

if [ ! -f "$TARGET_FILE" ]; then
    echo "999999"
    exit 1
fi

# Syntax check
if ! bash -n "$TARGET_FILE" 2>/dev/null; then
    echo "999999"
    exit 1
fi

# Check script structure
LINE_COUNT=$(wc -l < "$TARGET_FILE")
COMMAND_COUNT=$(grep -cE "^\s*(cp|tar|gzip|rsync|git|echo|cat)" "$TARGET_FILE" || echo 0)
ESTIMATED_TIME_MS=$((COMMAND_COUNT * 10 + LINE_COUNT / 10))

# Error checking
ERROR_PENALTY=0
if ! grep -q "set -e" "$TARGET_FILE"; then
    ERROR_PENALTY=$((ERROR_PENALTY + 1000))
fi

# Code quality
QUALITY_PENALTY=0
FUNCTION_COUNT=$(grep -cE "^[a-z_]+\(\)" "$TARGET_FILE" 2>/dev/null || echo 0)
if [ "$FUNCTION_COUNT" -eq 0 ] && [ "$LINE_COUNT" -gt 50 ]; then
    QUALITY_PENALTY=$((QUALITY_PENALTY + 500))
fi

SCORE=$((ESTIMATED_TIME_MS + ERROR_PENALTY + QUALITY_PENALTY))
echo "$SCORE"
