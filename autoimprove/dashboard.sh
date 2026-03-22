#!/bin/bash
# =============================================================================
# dashboard.sh — Autoimprove Analytics Dashboard
# =============================================================================
# Reads experiment-log.jsonl and generates summary statistics
# Can be called on demand or as part of morning report
# =============================================================================

set -euo pipefail

LOG_FILE="/home/mleon/.openclaw/workspace/autoimprove/experiment-log.jsonl"

# Color codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  📊 Autoimprove Dashboard                        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# Check if log exists and has data
if [ ! -f "$LOG_FILE" ]; then
    echo -e "${YELLOW}No experiment log found yet.${NC}"
    echo "Run autoimprove to start collecting data."
    exit 0
fi

TOTAL_EXPERIMENTS=$(wc -l < "$LOG_FILE")
if [ "$TOTAL_EXPERIMENTS" -eq 0 ]; then
    echo -e "${YELLOW}No experiments logged yet.${NC}"
    exit 0
fi

echo -e "${CYAN}Total Experiments:${NC} $TOTAL_EXPERIMENTS"

# Parse JSONL with jq if available, otherwise grep/awk
if command -v jq &>/dev/null; then
    # === Use jq for precise parsing ===
    
    KEPT=$(jq -r 'select(.kept == true) | .target' "$LOG_FILE" | wc -l)
    DISCARDED=$(jq -r 'select(.kept == false) | .target' "$LOG_FILE" | wc -l)
    
    KEPT_PCT=$(echo "scale=1; $KEPT * 100 / $TOTAL_EXPERIMENTS" | bc)
    
    echo -e "${GREEN}Kept:${NC}              $KEPT (${KEPT_PCT}%)"
    echo -e "${RED}Discarded:${NC}         $DISCARDED"
    echo ""
    
    # Calculate current streak (consecutive nights with kept experiments)
    STREAK=0
    LAST_DATE=""
    while IFS= read -r line; do
        DATE=$(echo "$line" | jq -r '.ts' | cut -d'T' -f1)
        KEPT_FLAG=$(echo "$line" | jq -r '.kept')
        
        if [ "$KEPT_FLAG" = "true" ]; then
            if [ "$DATE" != "$LAST_DATE" ]; then
                STREAK=$((STREAK + 1))
                LAST_DATE="$DATE"
            fi
        fi
    done < "$LOG_FILE"
    
    echo -e "${CYAN}Current Streak:${NC}    $STREAK nights with improvements"
    echo ""
    
    # Best improvements (top 5 by delta)
    echo -e "${CYAN}🏆 Top 5 Improvements:${NC}"
    jq -r 'select(.kept == true) | "\(.delta)\t\(.target)\t\(.change)"' "$LOG_FILE" \
        | sort -rn \
        | head -5 \
        | awk -F'\t' '{printf "  %s%-8s%s → %-20s %s\n", "'$GREEN'", $1, "'$NC'", $2, $3}'
    echo ""
    
    # Trends: compare last 7 days vs previous 7 days
    CURRENT_WEEK=$(tail -n 50 "$LOG_FILE" | jq -r 'select(.kept == true)' | wc -l)
    PREVIOUS_WEEK=$(head -n -50 "$LOG_FILE" 2>/dev/null | tail -n 50 | jq -r 'select(.kept == true)' | wc -l || echo 0)
    
    echo -e "${CYAN}📈 Trends:${NC}"
    if [ "$CURRENT_WEEK" -gt "$PREVIOUS_WEEK" ]; then
        echo -e "  ${GREEN}↑ Improving${NC} (recent: $CURRENT_WEEK kept, previous: $PREVIOUS_WEEK)"
    elif [ "$CURRENT_WEEK" -lt "$PREVIOUS_WEEK" ]; then
        echo -e "  ${YELLOW}↓ Declining${NC} (recent: $CURRENT_WEEK kept, previous: $PREVIOUS_WEEK)"
    else
        echo -e "  ${CYAN}→ Stable${NC} (recent: $CURRENT_WEEK kept)"
    fi
    echo ""
    
    # Target breakdown
    echo -e "${CYAN}📁 By Target:${NC}"
    jq -r '.target' "$LOG_FILE" \
        | sort \
        | uniq -c \
        | sort -rn \
        | head -10 \
        | awk '{printf "  %-30s %s\n", $2, $1}'
    
else
    # === Fallback: simple grep/awk parsing ===
    
    KEPT=$(grep -c '"kept":true' "$LOG_FILE" || echo 0)
    DISCARDED=$(grep -c '"kept":false' "$LOG_FILE" || echo 0)
    
    KEPT_PCT=$(echo "scale=1; $KEPT * 100 / $TOTAL_EXPERIMENTS" | bc)
    
    echo -e "${GREEN}Kept:${NC}              $KEPT (${KEPT_PCT}%)"
    echo -e "${RED}Discarded:${NC}         $DISCARDED"
    echo ""
    
    echo -e "${YELLOW}Install jq for detailed analytics:${NC} sudo apt install jq"
fi

echo ""
echo -e "${BLUE}Log location:${NC} $LOG_FILE"
