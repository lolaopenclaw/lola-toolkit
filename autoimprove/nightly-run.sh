#!/bin/bash
# =============================================================================
# nightly-run.sh — Wrapper for nightly auto-optimization
# =============================================================================
# Called by cron at 3 AM Madrid. Determines today's target and runs experiments.
# Must finish before 4 AM backup.
# =============================================================================

set -euo pipefail

AUTOIMPROVE_DIR="/home/mleon/.openclaw/workspace/autoimprove"
WORKSPACE="/home/mleon/.openclaw/workspace"
DOW=$(date +%u)  # 1=Monday, 7=Sunday

cd "$WORKSPACE"

echo "🔬 Autoimprove Nightly — $(date '+%Y-%m-%d %H:%M') (day $DOW)"
echo ""

# Determine today's target
case $DOW in
    1) TARGET="heartbeat-efficiency"; DESC="HEARTBEAT.md" ;;
    2) TARGET="agents-tokens"; DESC="AGENTS.md" ;;
    3) TARGET="memory-index"; DESC="MEMORY.md" ;;
    4) TARGET="agents-tokens"; DESC="AGENTS.md (review)" ;;  # Re-check
    5) TARGET="heartbeat-efficiency"; DESC="HEARTBEAT.md (review)" ;;
    6) TARGET="backup-speed"; DESC="backup-memory.sh" ;;
    7) echo "Sunday — review day. Checking weekly results."; 
       # Count improvements this week
       KEPT=$(find "$AUTOIMPROVE_DIR/programs" -name "experiments.tsv" -exec grep -c "kept" {} + 2>/dev/null | tail -1 || echo 0)
       echo "Improvements kept this week: $KEPT"
       echo "STATUS: REVIEW_COMPLETE"
       exit 0 ;;
esac

PROGRAM_DIR="$AUTOIMPROVE_DIR/programs/$TARGET"

if [ ! -d "$PROGRAM_DIR" ] || [ ! -f "$PROGRAM_DIR/eval.sh" ]; then
    echo "⚠️ Program not found: $TARGET"
    echo "STATUS: SKIP"
    exit 0
fi

echo "Target: $DESC ($TARGET)"
echo ""

# Run baseline
BASELINE=$(bash "$PROGRAM_DIR/eval.sh" 2>/dev/null | tail -1)
echo "Baseline score: $BASELINE"

# If already very optimized, skip
if [ "$BASELINE" -lt 200 ]; then
    echo "Already well-optimized (score < 200). Skipping."
    echo "STATUS: SKIP_OPTIMIZED"
    exit 0
fi

# Output context for the agent
echo ""
echo "=== AUTOIMPROVE CONTEXT ==="
echo "PROGRAM_DIR=$PROGRAM_DIR"
echo "TARGET=$(grep -oP '^TARGET_FILE:\s*\K.*' "$PROGRAM_DIR/program.md" | head -1)"
echo "BASELINE=$BASELINE"
echo "EVAL=bash $PROGRAM_DIR/eval.sh"
echo ""
echo "Agent should now iterate on the target file."
echo "STATUS: READY_FOR_AGENT"
