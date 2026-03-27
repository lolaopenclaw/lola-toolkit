#!/bin/bash
# =============================================================================
# eval.sh — memory-maintenance.sh speed evaluation
# =============================================================================
# Composite metric: execution_time + exit_code_penalty + error_penalty
# Lower score = better
# =============================================================================

set -euo pipefail

TARGET_FILE="/home/mleon/.openclaw/workspace/scripts/memory-maintenance.sh"

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
START=$(date +%s%N)

# Check script structure and complexity
LINE_COUNT=$(wc -l < "$TARGET_FILE")
COMMAND_COUNT=$(grep -cE "^\s*(find|du|wc|awk)" "$TARGET_FILE" || echo 0)

# Estimate time based on complexity (in ms)
# Simple heuristic: 15ms per command + 1ms per 10 lines
ESTIMATED_TIME_MS=$((COMMAND_COUNT * 15 + LINE_COUNT / 10))

END=$(date +%s%N)
VALIDATION_TIME_MS=$(( (END - START) / 1000000 ))

# === 3. Error checking ===
ERROR_PENALTY=0

# Check for proper error handling
if ! grep -q "set -e" "$TARGET_FILE"; then
    ERROR_PENALTY=$((ERROR_PENALTY + 1000))  # No error handling
fi

# Check for dangerous patterns
if grep -qE "rm -rf \$|sudo rm" "$TARGET_FILE"; then
    ERROR_PENALTY=$((ERROR_PENALTY + 10000))  # Dangerous command
fi

# === 4. Code quality penalties ===
QUALITY_PENALTY=0

# Penalize if no functions defined (monolithic script)
FUNCTION_COUNT=$(grep -cE "^[a-z_]+\(\)" "$TARGET_FILE" 2>/dev/null || echo 0)
FUNCTION_COUNT=$(echo "$FUNCTION_COUNT" | tr -d '\n')
if [ "$FUNCTION_COUNT" -eq 0 ] && [ "$LINE_COUNT" -gt 50 ]; then
    QUALITY_PENALTY=$((QUALITY_PENALTY + 100))
fi

# Penalize redundant find calls
FIND_COUNT=$(grep -c "find " "$TARGET_FILE" || echo 0)
if [ "$FIND_COUNT" -ge 4 ]; then
    QUALITY_PENALTY=$((QUALITY_PENALTY + 200))  # Multiple find calls could be combined
fi

# Bonus for parallelization
PARALLEL_COUNT=$(grep -c " &$" "$TARGET_FILE" || echo 0)
if [ "$PARALLEL_COUNT" -ge 2 ]; then
    QUALITY_PENALTY=$((QUALITY_PENALTY - 50))  # Reward for parallelization
fi

# === 5. Composite score ===
SCORE=$((ESTIMATED_TIME_MS + VALIDATION_TIME_MS + ERROR_PENALTY + QUALITY_PENALTY))

echo "$SCORE"
