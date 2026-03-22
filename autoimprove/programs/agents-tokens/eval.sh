#!/bin/bash
# =============================================================================
# eval.sh — AGENTS.md token efficiency evaluation
# =============================================================================
# Composite metric: tokens + time + error_penalty
# Lower score = better
# =============================================================================

set -euo pipefail

TARGET_FILE="/home/mleon/.openclaw/workspace/AGENTS.md"

if [ ! -f "$TARGET_FILE" ]; then
    echo "999999"
    exit 1
fi

# === 1. Token count ===
TOKEN_COUNT=$(wc -c < "$TARGET_FILE")

# === 2. Execution time (validate file structure) ===
START=$(date +%s%N)
# Check required sections
if ! grep -q "## Every Session" "$TARGET_FILE" || \
   ! grep -q "## Memory" "$TARGET_FILE"; then
    ERROR_PENALTY=10000
else
    ERROR_PENALTY=0
fi
END=$(date +%s%N)
TIME_MS=$(( (END - START) / 1000000 ))

# === 3. Output validation ===
VALIDATION_PENALTY=0

# Check for critical keywords
REQUIRED_KEYWORDS=("SOUL.md" "USER.md" "PROJECTS.md" "MEMORY.md" "memory/")
for keyword in "${REQUIRED_KEYWORDS[@]}"; do
    if ! grep -q "$keyword" "$TARGET_FILE"; then
        VALIDATION_PENALTY=$((VALIDATION_PENALTY + 500))
    fi
done

# Check for redundancy with other files
if grep -qi "logroño\|la rioja\|manuel león" "$TARGET_FILE"; then
    # This info should be in USER.md, not AGENTS.md
    VALIDATION_PENALTY=$((VALIDATION_PENALTY + 1000))
fi

# === 4. Composite score ===
SCORE=$(echo "$TOKEN_COUNT + ($TIME_MS * 0.1) + $ERROR_PENALTY + $VALIDATION_PENALTY" | bc)
SCORE=${SCORE%.*}

echo "$SCORE"
