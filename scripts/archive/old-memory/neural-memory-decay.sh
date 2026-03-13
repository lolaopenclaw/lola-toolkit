#!/usr/bin/env bash
# ============================================================
# Neural Memory Decay — Temporal memory deprecation system
# Implements gradual "forgetting" for stale/less-important information
# ============================================================
set -uo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
MEMORY_DIR="$WORKSPACE/memory"
DECAY_RATE="${DECAY_RATE:-0.1}"  # 10% decay per month
DRY_RUN="${1:-true}"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}🧠 Neural Memory Decay System${NC}"
echo "Decay rate: $DECAY_RATE per month"
echo "Dry-run: $DRY_RUN"
echo ""

# ============================================================
# Memory Decay Scoring
# ============================================================

calculate_decay_score() {
    local file="$1"
    local days_old=$2
    local months_old=$((days_old / 30))
    
    # Start with 100% relevance
    local relevance=100
    
    # Apply decay: 10% per month = 90% of previous relevance
    for ((i=0; i<months_old; i++)); do
        relevance=$(echo "$relevance * (1 - $DECAY_RATE)" | bc)
    done
    
    echo $relevance
}

# ============================================================
# Analyze Memory Files
# ============================================================
echo -e "${CYAN}[1/4] Analyzing memory files for decay...${NC}"

declare -a OLD_FILES=()
declare -a RECENT_FILES=()
declare -a STABLE_FILES=()

current_date=$(date +%s)

for file in "$MEMORY_DIR"/*.md; do
    [ ! -f "$file" ] && continue
    
    filename=$(basename "$file")
    mod_time=$(stat -c%Y "$file" 2>/dev/null || stat -f%m "$file" 2>/dev/null)
    [ -z "$mod_time" ] && continue
    days_old=$(( (current_date - mod_time) / 86400 ))
    
    relevance=$(calculate_decay_score "$file" "$days_old")
    
    # Categorize
    if [ "$days_old" -gt 90 ]; then
        OLD_FILES+=("$filename:$days_old:$relevance")
    elif [ "$days_old" -gt 30 ]; then
        RECENT_FILES+=("$filename:$days_old:$relevance")
    else
        STABLE_FILES+=("$filename:$days_old:$relevance")
    fi
done

echo "✓ Old (>90 days): ${#OLD_FILES[@]} files"
echo "✓ Recent (30-90d): ${#RECENT_FILES[@]} files"
echo "✓ Stable (<30d): ${#STABLE_FILES[@]} files"

# ============================================================
# Detect Stale Information Patterns
# ============================================================
echo ""
echo -e "${CYAN}[2/4] Detecting stale information patterns...${NC}"

declare -A STALE_PATTERNS
STALE_PATTERNS["TODO"]="Incomplete tasks"
STALE_PATTERNS["BLOCKED"]="Blocked work items"
STALE_PATTERNS["DEPRECATED"]="Obsolete decisions"
STALE_PATTERNS["REVISIT"]="Items needing review"
STALE_PATTERNS["WAITING"]="Waiting on external input"

stale_count=0
for file in "$MEMORY_DIR"/*.md; do
    [ ! -f "$file" ] && continue
    
    for pattern in "${!STALE_PATTERNS[@]}"; do
        if grep -qi "$pattern" "$file"; then
            stale_count=$((stale_count + 1))
        fi
    done
done

echo "✓ Found $stale_count potential stale markers"

# ============================================================
# Memory Decay Proposal
# ============================================================
echo ""
echo -e "${CYAN}[3/4] Proposing memory consolidation...${NC}"
echo ""

if [ ${#OLD_FILES[@]} -gt 0 ]; then
    echo -e "${YELLOW}Old memory files (>90 days) — Consider consolidating:${NC}"
    for file_info in "${OLD_FILES[@]}"; do
        IFS=':' read -r file days relevance <<< "$file_info"
        echo "  • $file ($days days old, relevance: ${relevance%.*}%)"
    done
    echo ""
    echo "Action: Review and consolidate into MEMORY.md long-term knowledge"
fi

if [ ${#RECENT_FILES[@]} -gt 0 ]; then
    echo -e "${YELLOW}Recent files (30-90 days) — Monitor for staleness:${NC}"
    count=0
    for file_info in "${RECENT_FILES[@]}"; do
        [ $count -ge 5 ] && echo "  ... and $((${#RECENT_FILES[@]} - 5)) more" && break
        IFS=':' read -r file days relevance <<< "$file_info"
        printf "  • %-40s (%2d days, relevance: %3d%%)\n" "$file" "$days" "${relevance%.*}"
        count=$((count + 1))
    done
    echo ""
fi

# ============================================================
# Neural Memory Decay Algorithm
# ============================================================
echo ""
echo -e "${CYAN}[4/4] Generating decay recommendations...${NC}"
echo ""

echo -e "${BOLD}RECOMMENDATIONS:${NC}"
echo ""

echo "1. COMPRESS OLD MEMORY (>90 days)"
echo "   • Extract key facts from memory/2025-11-*.md → MEMORY.md"
echo "   • Keep compressed archive: memory/ARCHIVE/"
echo "   • Remove originals to reduce memory footprint"
echo "   Space saved: ~50-70% reduction"
echo ""

echo "2. TAG INFORMATION BY RELEVANCE"
echo "   • Add metadata to memory files:"
echo "     [CORE] — Essential knowledge (never decay)"
echo "     [SEASONAL] — Annual/recurring items"
echo "     [EPHEMERAL] — Temporary context (safe to discard)"
echo "     [DEPRECATED] — Known obsolete"
echo ""

echo "3. IMPLEMENT ACTIVE FORGETTING"
echo "   • Weekly review of files >60 days old"
echo "   • Remove entries that are:"
echo "     ✓ Implemented (task done)"
echo "     ✓ Resolved (problem solved)"
echo "     ✓ Superseded (newer version exists)"
echo "     ✓ No longer relevant (context changed)"
echo ""

echo "4. MAINTAIN DECISION LOG (KEEP)"
echo "   • NEVER decay: MEMORY.md (key decisions)"
echo "   • NEVER decay: Major milestones"
echo "   • NEVER decay: Security configurations"
echo "   • Safe to age: Daily logs, temporary tasks"
echo ""

# ============================================================
# Current Memory Health
# ============================================================
echo ""
echo -e "${BOLD}CURRENT MEMORY HEALTH${NC}"
echo ""

memory_size=$(du -sh "$MEMORY_DIR" 2>/dev/null | awk '{print $1}')
file_count=$(find "$MEMORY_DIR" -name "*.md" -type f | wc -l)
avg_age=$(find "$MEMORY_DIR" -name "*.md" -type f -printf '%T@\n' | awk -v now=$(date +%s) '{sum+=now-$1; n++} END {if(n>0) printf "%.0f", sum/n/86400}')

echo "📊 Memory Statistics:"
echo "  Total size: $memory_size"
echo "  Files: $file_count"
echo "  Average age: ~${avg_age} days"
echo ""

if [ "$memory_size" != "0" ] && [ ${#OLD_FILES[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Opportunity: Archive old files to save space${NC}"
fi

echo ""
echo -e "${BOLD}IMPLEMENTATION STATUS${NC}"
echo ""
echo "Current: ℹ️  Informational analysis (no changes applied)"
echo ""

if [ "$DRY_RUN" = "false" ]; then
    echo -e "${GREEN}To apply decay and consolidation:${NC}"
    echo ""
    echo "1. Review memory/MEMORY.md for retention"
    echo "2. Archive old files:"
    echo "   mkdir -p $MEMORY_DIR/ARCHIVE"
    echo "   mv $MEMORY_DIR/2025-11-*.md $MEMORY_DIR/ARCHIVE/"
    echo "3. Commit changes:"
    echo "   git add memory/"
    echo "   git commit -m 'refactor(memory): Archive old files, apply decay'"
fi

echo ""
echo -e "${CYAN}Reference:${NC}"
echo "See: memory/PROTOCOLS/memory-guardian-protocol.md (cleanup)"
echo "See: memory/DAILY/daily-structure.md (modular memory)"
echo ""
echo -e "${BOLD}Status:${NC} ℹ️  Proposal ready"
