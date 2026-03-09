#!/bin/bash
# =============================================================================
# autoimprove/runner.sh — Automated experiment runner
# =============================================================================
# Runs the iterate→test→keep/discard loop for a given program.
# This is what gets called by the cron or manually.
#
# Usage: bash runner.sh <program-dir> [max-experiments]
#
# The program-dir must contain:
#   - program.md (target file, eval command, goal, constraints)
#   - eval.sh (evaluation script that outputs a score number)
# =============================================================================

set -euo pipefail

PROGRAM_DIR="${1:?Usage: runner.sh <program-dir> [max-experiments]}"
MAX_EXP="${2:-10}"

# --- Colors ------------------------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${BLUE}[runner]${NC} $1"; }
kept() { echo -e "${GREEN}[✅ KEPT]${NC} $1"; }
discard() { echo -e "${YELLOW}[❌ DISCARD]${NC} $1"; }

# --- Parse program.md -------------------------------------------------------
PROGRAM_FILE="$PROGRAM_DIR/program.md"
EVAL_SCRIPT="$PROGRAM_DIR/eval.sh"

if [ ! -f "$PROGRAM_FILE" ] || [ ! -f "$EVAL_SCRIPT" ]; then
    echo "Error: Need program.md and eval.sh in $PROGRAM_DIR"
    exit 1
fi

TARGET_FILE=$(grep -oP "^TARGET_FILE:\s*\K.*" "$PROGRAM_FILE" | head -1)
GOAL=$(grep -oP "^GOAL:\s*\K.*" "$PROGRAM_FILE" | head -1)

if [ ! -f "$TARGET_FILE" ]; then
    echo "Error: TARGET_FILE not found: $TARGET_FILE"
    exit 1
fi

# --- Setup results -----------------------------------------------------------
RESULTS_DIR="$PROGRAM_DIR/results"
mkdir -p "$RESULTS_DIR"
RESULTS_TSV="$RESULTS_DIR/experiments.tsv"

# Backup original
cp "$TARGET_FILE" "$RESULTS_DIR/original.bak"
cp "$TARGET_FILE" "$RESULTS_DIR/current-best.bak"

# --- Baseline ----------------------------------------------------------------
log "Target: $TARGET_FILE"
log "Goal: $GOAL"
log "Max experiments: $MAX_EXP"

BASELINE=$(bash "$EVAL_SCRIPT" 2>/dev/null | tail -1)
BEST_SCORE="$BASELINE"

log "Baseline score: ${CYAN}${BASELINE}${NC}"

# Initialize TSV
echo -e "exp\tscore\tstatus\tdescription\ttimestamp" > "$RESULTS_TSV"
echo -e "0\t${BASELINE}\tbaseline\toriginal\t$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$RESULTS_TSV"

# --- Export for agent use ---
echo ""
echo "=== AUTOIMPROVE CONTEXT ==="
echo "TARGET_FILE=$TARGET_FILE"
echo "EVAL_SCRIPT=$EVAL_SCRIPT"
echo "BASELINE=$BASELINE"
echo "BEST_SCORE=$BEST_SCORE"
echo "RESULTS_TSV=$RESULTS_TSV"
echo "RESULTS_DIR=$RESULTS_DIR"
echo "MAX_EXPERIMENTS=$MAX_EXP"
echo "GOAL=$GOAL"
echo ""
echo "The agent should now:"
echo "1. Read $TARGET_FILE"
echo "2. Propose a change"
echo "3. Apply it"
echo "4. Run: bash $EVAL_SCRIPT"
echo "5. If score < $BEST_SCORE → KEEP, else DISCARD"
echo "6. Record in $RESULTS_TSV"
echo "7. Repeat up to $MAX_EXP times"
echo ""
echo "To restore original: cp $RESULTS_DIR/original.bak $TARGET_FILE"
echo "To restore best: cp $RESULTS_DIR/current-best.bak $TARGET_FILE"
echo "==========================="
