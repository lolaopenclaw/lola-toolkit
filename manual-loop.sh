#!/usr/bin/env bash
# Manual loop runner - to be controlled by the subagent

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

# Config
MAX_ITERATIONS="${1:-50}"
LOG_FILE="experiment-log.jsonl"

# Get baseline
BASELINE=$(./eval.sh)
BASELINE_SCORE=$(echo "$BASELINE" | jq -r '.score')
echo "BASELINE_SCORE=$BASELINE_SCORE"

# Find all scripts
mapfile -t ALL_SCRIPTS < <(find . -type f -name "*.sh" | grep -v -E '(eval\.sh|run-loop\.sh|manual-loop\.sh)')
NUM_SCRIPTS=${#ALL_SCRIPTS[@]}
echo "NUM_SCRIPTS=$NUM_SCRIPTS"

# Output scripts list
for script in "${ALL_SCRIPTS[@]}"; do
    echo "SCRIPT:$script"
done
