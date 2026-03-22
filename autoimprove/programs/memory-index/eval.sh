#!/bin/bash
# =============================================================================
# eval.sh — MEMORY.md index efficiency evaluation
# =============================================================================
# Composite metric: tokens + time + error_penalty
# Lower score = better
# =============================================================================

set -euo pipefail

TARGET_FILE="/home/mleon/.openclaw/workspace/MEMORY.md"

if [ ! -f "$TARGET_FILE" ]; then
    echo "999999"
    exit 1
fi

# === 1. Token count ===
TOKEN_COUNT=$(wc -c < "$TARGET_FILE")

# === 2. Execution time (parse the file) ===
START=$(date +%s%N)
# Count number of entries
ENTRY_COUNT=$(grep -c "^##" "$TARGET_FILE" || echo 0)
if [ "$ENTRY_COUNT" -lt 5 ]; then
    ERROR_PENALTY=10000  # Too few entries = broken
else
    ERROR_PENALTY=0
fi
END=$(date +%s%N)
TIME_MS=$(( (END - START) / 1000000 ))

# === 3. Output validation ===
VALIDATION_PENALTY=0

# Check for duplicates (same topic mentioned multiple times)
DUPLICATES=$(grep "^##" "$TARGET_FILE" | sort | uniq -d | wc -l)
VALIDATION_PENALTY=$((DUPLICATES * 200))

# Check for stale references (very old dates)
CURRENT_YEAR=$(date +%Y)
OLD_YEAR=$((CURRENT_YEAR - 2))
if grep -qP "## .*${OLD_YEAR}" "$TARGET_FILE"; then
    VALIDATION_PENALTY=$((VALIDATION_PENALTY + 500))  # Stale content
fi

# Check index density (chars per entry)
if [ "$ENTRY_COUNT" -gt 0 ]; then
    CHARS_PER_ENTRY=$((TOKEN_COUNT / ENTRY_COUNT))
    # If entries are too verbose (>500 chars avg), penalize
    if [ "$CHARS_PER_ENTRY" -gt 500 ]; then
        VALIDATION_PENALTY=$((VALIDATION_PENALTY + 1000))
    fi
fi

# === 4. Composite score ===
SCORE=$(echo "$TOKEN_COUNT + ($TIME_MS * 0.1) + $ERROR_PENALTY + $VALIDATION_PENALTY" | bc)
SCORE=${SCORE%.*}

echo "$SCORE"
