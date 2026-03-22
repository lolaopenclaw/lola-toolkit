#!/usr/bin/env bash
# eval.sh - Score all shell scripts in lola-toolkit
# Lower score = better

set -euo pipefail

# Ensure shellcheck is installed
if ! command -v shellcheck &>/dev/null; then
    echo "Installing shellcheck..." >&2
    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y shellcheck >/dev/null 2>&1
    elif command -v brew &>/dev/null; then
        brew install shellcheck >/dev/null 2>&1
    else
        echo "ERROR: Cannot install shellcheck automatically" >&2
        exit 1
    fi
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

# Find all .sh files
mapfile -t SCRIPTS < <(find . -type f -name "*.sh" | grep -v -E '(eval\.sh|run-loop\.sh)')

# 1. Shellcheck warnings/errors
SHELLCHECK_COUNT=0
for script in "${SCRIPTS[@]}"; do
    # Count issues (ignore SC1091 for sourcing external files)
    set +e
    count=$(shellcheck -f gcc "$script" 2>/dev/null | { grep -v SC1091 || true; } | wc -l | head -1 | xargs)
    set -e
    count=${count:-0}  # Default to 0 if empty
    [[ "$count" =~ ^[0-9]+$ ]] || count=0  # Ensure it's a number
    SHELLCHECK_COUNT=$((SHELLCHECK_COUNT + count))
done

# 2. Total lines of code (excluding comments and blank lines)
LOC=0
for script in "${SCRIPTS[@]}"; do
    lines=$(grep -v '^\s*#' "$script" | grep -v '^\s*$' | wc -l | head -1 | xargs || echo 0)
    lines=${lines:-0}  # Default to 0 if empty
    [[ "$lines" =~ ^[0-9]+$ ]] || lines=0  # Ensure it's a number
    LOC=$((LOC + lines))
done

# 3. Anti-patterns detected
ANTIPATTERNS=0

for script in "${SCRIPTS[@]}"; do
    # Check for missing set -e or set -u
    if ! grep -q 'set -[euo]' "$script"; then
        ANTIPATTERNS=$((ANTIPATTERNS + 1))
    fi
    
    # Check for unquoted variables (basic heuristic)
    # Look for $VAR not followed by } or inside quotes
    unquoted=$(grep -oP '\$[A-Z_][A-Z0-9_]*(?![}"\047])' "$script" 2>/dev/null | wc -l | xargs || echo 0)
    if [[ -n "$unquoted" && "$unquoted" =~ ^[0-9]+$ ]]; then
        ANTIPATTERNS=$((ANTIPATTERNS + unquoted / 10))  # Divide by 10 to reduce weight
    fi
    
    # Check for missing error handling in pipelines
    if grep -q '|' "$script" && ! grep -q 'pipefail' "$script"; then
        ANTIPATTERNS=$((ANTIPATTERNS + 1))
    fi
done

# 4. Execution time (placeholder - would need actual benchmarks)
AVG_EXEC_MS=0  # Not implemented yet

# Calculate composite score
# score = (shellcheck * 3) + (loc * 1) + (antipatterns * 2) + (exec_ms * 0.5)
SCORE=$(echo "scale=2; ($SHELLCHECK_COUNT * 3) + ($LOC * 1) + ($ANTIPATTERNS * 2) + ($AVG_EXEC_MS * 0.5)" | bc)

# Output JSON for easy parsing
cat <<EOF
{
  "score": $SCORE,
  "shellcheck_issues": $SHELLCHECK_COUNT,
  "lines_of_code": $LOC,
  "antipatterns": $ANTIPATTERNS,
  "avg_exec_ms": $AVG_EXEC_MS,
  "scripts_analyzed": ${#SCRIPTS[@]},
  "timestamp": "$(date -Iseconds)"
}
EOF
