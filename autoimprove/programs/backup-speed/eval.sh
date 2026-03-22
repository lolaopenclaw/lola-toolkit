#!/bin/bash
# =============================================================================
# eval.sh — backup-memory.sh speed evaluation
# =============================================================================
# Composite metric: execution_time + exit_code_penalty + error_penalty
# Lower score = better
# =============================================================================

set -euo pipefail

TARGET_FILE="/home/mleon/.openclaw/workspace/scripts/backup-memory.sh"

if [ ! -f "$TARGET_FILE" ]; then
    echo "999999"
    exit 1
fi

# === 1. Syntax check (must be valid bash) ===
if ! bash -n "$TARGET_FILE" 2>/dev/null; then
    echo "999999"  # Syntax error = max penalty
    exit 1
fi

# === 2. Execution time (dry-run simulation) ===
# We can't actually run the backup, but we can simulate the logic
START=$(date +%s%N)

# Check script structure and complexity
LINE_COUNT=$(wc -l < "$TARGET_FILE")
COMMAND_COUNT=$(grep -cE "^\s*(cp|tar|gzip|rsync|git)" "$TARGET_FILE" || echo 0)

# Estimate time based on complexity (in ms)
# Simple heuristic: 10ms per command + 1ms per 10 lines
ESTIMATED_TIME_MS=$((COMMAND_COUNT * 10 + LINE_COUNT / 10))

END=$(date +%s%N)
VALIDATION_TIME_MS=$(( (END - START) / 1000000 ))

# === 3. Error checking ===
ERROR_PENALTY=0

# Check for proper error handling
if ! grep -q "set -e" "$TARGET_FILE"; then
    ERROR_PENALTY=$((ERROR_PENALTY + 1000))  # No error handling
fi

# Check for dangerous patterns
if grep -qE "rm -rf /|sudo rm" "$TARGET_FILE"; then
    ERROR_PENALTY=$((ERROR_PENALTY + 10000))  # Dangerous command
fi

# === 4. Code quality penalties ===
QUALITY_PENALTY=0

# Penalize if no functions defined (monolithic script)
FUNCTION_COUNT=$(grep -cE "^[a-z_]+\(\)" "$TARGET_FILE" 2>/dev/null || echo 0)
FUNCTION_COUNT=$(echo "$FUNCTION_COUNT" | tr -d '\n')
if [ "$FUNCTION_COUNT" -eq 0 ] && [ "$LINE_COUNT" -gt 50 ]; then
    QUALITY_PENALTY=$((QUALITY_PENALTY + 500))
fi

# Penalize redundant commands
TAR_COUNT=$(grep -c "tar" "$TARGET_FILE" || echo 0)
if [ "$TAR_COUNT" -ge 3 ]; then
    QUALITY_PENALTY=$((QUALITY_PENALTY + 300))  # Multiple tar calls could be combined
fi

# === 5. Composite score ===
# Formula: estimated_time + validation_time + error_penalty + quality_penalty
SCORE=$((ESTIMATED_TIME_MS + VALIDATION_TIME_MS + ERROR_PENALTY + QUALITY_PENALTY))

echo "$SCORE"
