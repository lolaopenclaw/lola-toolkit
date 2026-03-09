#!/bin/bash
# =============================================================================
# autoimprove/engine.sh — Motor de auto-mejora inspirado en Karpathy's autoresearch
# =============================================================================
# Patrón: iterate → test → keep/discard
# 
# Uso: bash engine.sh <program.md> [--max-experiments N] [--timeout SECS]
#
# El program.md define:
#   - TARGET_FILE: archivo a optimizar
#   - EVAL_COMMAND: cómo evaluar (debe devolver un número, menor = mejor)
#   - BASELINE_SCORE: score actual (o "auto" para calcularlo)
#   - CONSTRAINTS: qué NO cambiar
#   - GOAL: qué optimizar
# =============================================================================

set -euo pipefail

# --- Config ------------------------------------------------------------------
PROGRAM_FILE="${1:?Uso: engine.sh <program.md>}"
MAX_EXPERIMENTS="${2:-20}"
TIMEOUT_SECS="${3:-300}"  # 5 min por defecto (como autoresearch)
RESULTS_DIR="$(dirname "$PROGRAM_FILE")/results"
BRANCH_NAME="autoimprove-$(date +%Y%m%d-%H%M%S)"

# --- Colores -----------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${BLUE}[engine]${NC} $1"; }
ok()   { echo -e "${GREEN}[✅ KEPT]${NC} $1"; }
skip() { echo -e "${YELLOW}[❌ DISCARDED]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Parse program.md -------------------------------------------------------
log "Leyendo programa: $PROGRAM_FILE"

parse_field() {
    grep -oP "^${1}:\s*\K.*" "$PROGRAM_FILE" 2>/dev/null | head -1
}

TARGET_FILE=$(parse_field "TARGET_FILE")
EVAL_COMMAND=$(parse_field "EVAL_COMMAND")
BASELINE_SCORE=$(parse_field "BASELINE_SCORE")
GOAL=$(parse_field "GOAL")
CONSTRAINTS=$(parse_field "CONSTRAINTS")

if [ -z "$TARGET_FILE" ] || [ -z "$EVAL_COMMAND" ]; then
    err "program.md debe definir TARGET_FILE y EVAL_COMMAND"
    exit 1
fi

if [ ! -f "$TARGET_FILE" ]; then
    err "TARGET_FILE no existe: $TARGET_FILE"
    exit 1
fi

# --- Setup -------------------------------------------------------------------
mkdir -p "$RESULTS_DIR"
RESULTS_TSV="$RESULTS_DIR/experiments.tsv"
BEST_FILE="$RESULTS_DIR/best.txt"
LOG_FILE="$RESULTS_DIR/log.txt"

# Header del TSV
echo -e "experiment\tscore\tstatus\tdescription\ttimestamp" > "$RESULTS_TSV"

# Backup original
cp "$TARGET_FILE" "$RESULTS_DIR/original.bak"

# --- Calcular baseline -------------------------------------------------------
log "Calculando baseline..."

if [ "$BASELINE_SCORE" = "auto" ] || [ -z "$BASELINE_SCORE" ]; then
    BASELINE_SCORE=$(eval "$EVAL_COMMAND" 2>/dev/null | tail -1 | grep -oP '[\d.]+' | head -1)
    if [ -z "$BASELINE_SCORE" ]; then
        err "No se pudo calcular baseline automáticamente"
        exit 1
    fi
fi

BEST_SCORE="$BASELINE_SCORE"
echo "$BEST_SCORE" > "$BEST_FILE"

log "Baseline score: ${CYAN}${BASELINE_SCORE}${NC}"
log "Goal: ${GOAL:-'minimize score'}"
log "Max experiments: $MAX_EXPERIMENTS"
log "Timeout per experiment: ${TIMEOUT_SECS}s"
echo ""

# --- Registro de experimento -------------------------------------------------
record_experiment() {
    local exp_num=$1 score=$2 status=$3 desc=$4
    echo -e "${exp_num}\t${score}\t${status}\t${desc}\t$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$RESULTS_TSV"
}

# Registrar baseline
record_experiment 0 "$BASELINE_SCORE" "baseline" "original"

# --- Export para que el agente LLM pueda leerlo ------------------------------
export AUTOIMPROVE_TARGET="$TARGET_FILE"
export AUTOIMPROVE_EVAL="$EVAL_COMMAND"
export AUTOIMPROVE_BEST_SCORE="$BEST_SCORE"
export AUTOIMPROVE_GOAL="$GOAL"
export AUTOIMPROVE_CONSTRAINTS="$CONSTRAINTS"
export AUTOIMPROVE_RESULTS_DIR="$RESULTS_DIR"
export AUTOIMPROVE_RESULTS_TSV="$RESULTS_TSV"
export AUTOIMPROVE_MAX_EXPERIMENTS="$MAX_EXPERIMENTS"

# --- Summary function --------------------------------------------------------
print_summary() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  📊 Autoimprove Results                          ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local total=$(tail -n +2 "$RESULTS_TSV" | wc -l)
    local kept=$(grep -c "kept" "$RESULTS_TSV" || echo 0)
    local discarded=$(grep -c "discarded" "$RESULTS_TSV" || echo 0)
    
    echo -e "  Experiments: ${total}"
    echo -e "  Kept:        ${GREEN}${kept}${NC}"
    echo -e "  Discarded:   ${YELLOW}${discarded}${NC}"
    echo -e "  Baseline:    ${BASELINE_SCORE}"
    echo -e "  Best:        ${GREEN}$(cat "$BEST_FILE")${NC}"
    
    local improvement=$(echo "scale=4; $BASELINE_SCORE - $(cat "$BEST_FILE")" | bc 2>/dev/null || echo "?")
    echo -e "  Improvement: ${GREEN}${improvement}${NC}"
    echo ""
    
    echo -e "${BLUE}Kept improvements:${NC}"
    grep "kept" "$RESULTS_TSV" | while IFS=$'\t' read -r num score status desc ts; do
        echo -e "  ${GREEN}#${num}${NC} → ${score} — ${desc}"
    done
    echo ""
}

# Export summary function
export -f print_summary 2>/dev/null || true

log "Engine listo. Variables exportadas para el agente."
log "El agente debe:"
log "  1. Leer \$AUTOIMPROVE_TARGET"
log "  2. Proponer un cambio"
log "  3. Aplicar el cambio"
log "  4. Ejecutar \$AUTOIMPROVE_EVAL"
log "  5. Si score < \$AUTOIMPROVE_BEST_SCORE → guardar (kept)"
log "  6. Si no → revertir (discarded)"
log "  7. Actualizar \$AUTOIMPROVE_RESULTS_TSV"
log "  8. Repetir hasta \$AUTOIMPROVE_MAX_EXPERIMENTS"
echo ""
