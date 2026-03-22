#!/usr/bin/env bash
# run-loop.sh - Autoresearch loop for lola-toolkit
# Applies the Karpathy pattern: measure, change one thing, measure, keep or discard

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

# Config
MAX_ITERATIONS=50
DRY_RUN=false
LOG_FILE="experiment-log.jsonl"
TIMEOUT_SECONDS=120  # 2 minutes

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --max)
            MAX_ITERATIONS="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--dry-run] [--max N]"
            exit 1
            ;;
    esac
done

# Initialize log file if it doesn't exist
if [[ ! -f "$LOG_FILE" ]]; then
    touch "$LOG_FILE"
fi

# Read program.md to show the agent
if [[ ! -f "program.md" ]]; then
    echo "ERROR: program.md not found" >&2
    exit 1
fi

# Get baseline score
echo "📊 Establishing baseline..." >&2
BASELINE=$(./eval.sh)
BASELINE_SCORE=$(echo "$BASELINE" | jq -r '.score')
echo "Baseline score: $BASELINE_SCORE" >&2
echo "$BASELINE" | jq -c '. + {iteration: 0, type: "baseline"}' >> "$LOG_FILE"

# Find all modifiable scripts
mapfile -t ALL_SCRIPTS < <(find . -type f -name "*.sh" | grep -v -E '(eval\.sh|run-loop\.sh)')
NUM_SCRIPTS=${#ALL_SCRIPTS[@]}

if [[ $NUM_SCRIPTS -eq 0 ]]; then
    echo "ERROR: No shell scripts found to optimize" >&2
    exit 1
fi

echo "Found $NUM_SCRIPTS scripts to optimize" >&2
echo "Starting loop with max $MAX_ITERATIONS iterations..." >&2
echo "" >&2

# Main loop
for ((i=1; i<=MAX_ITERATIONS; i++)); do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "🔄 Iteration $i/$MAX_ITERATIONS" >&2
    
    # Pick a random script
    RANDOM_IDX=$((RANDOM % NUM_SCRIPTS))
    TARGET_SCRIPT="${ALL_SCRIPTS[$RANDOM_IDX]}"
    echo "🎯 Target: $TARGET_SCRIPT" >&2
    
    # Create experiment prompt
    PROMPT="You are a shell script optimization expert. Your task is to make ONE improvement to the following script.

Read program.md for the full context and constraints.

Target script: $TARGET_SCRIPT

Current content:
\`\`\`bash
$(cat "$TARGET_SCRIPT")
\`\`\`

Make ONE focused improvement that will reduce the composite score. Priorities:
1. Fix shellcheck warnings
2. Add error handling (set -euo pipefail)
3. Quote variables
4. Simplify code
5. Remove dead code

Output ONLY the improved script content, nothing else. No explanations, no markdown fences."

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would optimize $TARGET_SCRIPT" >&2
        continue
    fi
    
    # Create a temporary file for the agent's work
    TEMP_SCRIPT=$(mktemp)
    trap 'rm -f "$TEMP_SCRIPT"' EXIT
    
    # Spawn subagent to make improvement
    echo "🤖 Spawning optimization agent..." >&2
    
    # Use claude CLI if available, otherwise fall back to openclaw
    if command -v claude &>/dev/null; then
        timeout "$TIMEOUT_SECONDS" claude --print > "$TEMP_SCRIPT" 2>/dev/null <<EOF
$(cat program.md)

---

$PROMPT
EOF
        if [[ $? -ne 0 ]]; then
            echo "⚠️  Agent timeout or error, skipping this iteration" >&2
            continue
        fi
    else
        # Fallback: use openclaw sessions spawn
        echo "⚠️  claude CLI not found, using openclaw subagent" >&2
        # This would need actual openclaw subagent implementation
        # For now, skip
        echo "⚠️  Skipping - openclaw subagent not implemented yet" >&2
        continue
    fi
    
    # Check if agent produced valid output
    if [[ ! -s "$TEMP_SCRIPT" ]]; then
        echo "⚠️  Agent produced no output, skipping" >&2
        continue
    fi
    
    # Backup original
    cp "$TARGET_SCRIPT" "$TARGET_SCRIPT.backup"
    
    # Apply change
    cat "$TEMP_SCRIPT" > "$TARGET_SCRIPT"
    
    # Re-evaluate
    echo "📊 Re-evaluating..." >&2
    NEW_EVAL=$(./eval.sh 2>/dev/null || echo '{"score": 999999, "error": true}')
    NEW_SCORE=$(echo "$NEW_EVAL" | jq -r '.score')
    
    # Compare scores
    IMPROVEMENT=$(echo "scale=2; $BASELINE_SCORE - $NEW_SCORE" | bc)
    
    if (( $(echo "$NEW_SCORE < $BASELINE_SCORE" | bc -l) )); then
        # Score improved!
        echo "✅ Score improved by $IMPROVEMENT ($BASELINE_SCORE → $NEW_SCORE)" >&2
        
        # Commit the change
        git add "$TARGET_SCRIPT"
        git commit -m "autoresearch: improve $TARGET_SCRIPT (score: $BASELINE_SCORE → $NEW_SCORE)" >/dev/null 2>&1 || true
        
        # Update baseline
        BASELINE_SCORE=$NEW_SCORE
        
        # Log success
        echo "$NEW_EVAL" | jq -c ". + {iteration: $i, type: \"success\", target: \"$TARGET_SCRIPT\", improvement: $IMPROVEMENT}" >> "$LOG_FILE"
        
        rm -f "$TARGET_SCRIPT.backup"
    else
        # Score got worse or stayed same
        echo "❌ Score regressed by ${IMPROVEMENT#-} ($BASELINE_SCORE → $NEW_SCORE)" >&2
        
        # Revert
        mv "$TARGET_SCRIPT.backup" "$TARGET_SCRIPT"
        git reset --hard HEAD >/dev/null 2>&1 || true
        
        # Log failure
        echo "$NEW_EVAL" | jq -c ". + {iteration: $i, type: \"failure\", target: \"$TARGET_SCRIPT\", regression: ${IMPROVEMENT#-}}" >> "$LOG_FILE"
    fi
    
    echo "" >&2
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
echo "✨ Loop complete!" >&2
echo "Final score: $BASELINE_SCORE (started at $(echo "$BASELINE" | jq -r '.score'))" >&2
echo "Log saved to: $LOG_FILE" >&2
