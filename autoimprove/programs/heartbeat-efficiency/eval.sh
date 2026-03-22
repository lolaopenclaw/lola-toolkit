#!/bin/bash
# =============================================================================
# eval.sh — HEARTBEAT.md efficiency evaluation
# =============================================================================
# Composite metric: tokens + time + error_penalty
# Lower score = better
# =============================================================================

set -euo pipefail

TARGET_FILE="/home/mleon/.openclaw/workspace/HEARTBEAT.md"

if [ ! -f "$TARGET_FILE" ]; then
    echo "999999"  # Penalty for missing file
    exit 1
fi

# === 1. Token count (primary metric) ===
TOKEN_COUNT=$(wc -c < "$TARGET_FILE")

# === 2. Execution time (validate file structure) ===
START=$(date +%s%N)
# Check that file has required sections
if ! grep -q "## Morning Ritual" "$TARGET_FILE" || \
   ! grep -q "## Evening Ritual" "$TARGET_FILE"; then
    ERROR_PENALTY=10000
else
    ERROR_PENALTY=0
fi
END=$(date +%s%N)
TIME_MS=$(( (END - START) / 1000000 ))

# === 3. Output validation ===
# Check for known issues:
# - Empty sections
# - Broken links
# - Missing critical keywords
VALIDATION_PENALTY=0

if grep -q "## .*\n\n##" "$TARGET_FILE"; then
    VALIDATION_PENALTY=$((VALIDATION_PENALTY + 500))  # Empty section
fi

if ! grep -qi "memory" "$TARGET_FILE"; then
    VALIDATION_PENALTY=$((VALIDATION_PENALTY + 1000))  # Missing critical keyword
fi

# === 4. Composite score ===
# Formula: tokens + (time_ms * 0.1) + error_penalty + validation_penalty
# Time weight is low because file validation is fast
SCORE=$(echo "$TOKEN_COUNT + ($TIME_MS * 0.1) + $ERROR_PENALTY + $VALIDATION_PENALTY" | bc)

# Round to integer
SCORE=${SCORE%.*}

echo "$SCORE"
