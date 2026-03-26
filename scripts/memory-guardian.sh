#!/bin/bash
set -euo pipefail
# =============================================================================
# memory-guardian.sh — Memory Guardian Pro v2
# =============================================================================
# Auto-cleanup, bloat detection, compression, deduplication, token estimation
#
# Usage:
#   bash memory-guardian.sh [OPTIONS]
#     --analyze    Solo analizar, no cambiar nada
#     --clean      Ejecutar limpieza completa
#     --compress   Comprimir archivos >30 días
#     --status     Ver estado de memoria
#     --dry-run    Simulación de limpieza (no borra nada)
#     --dedupe     Detectar duplicados
#     --full       Todo: analyze + clean + compress + dedupe
# =============================================================================

set -euo pipefail

trap 'log_error "Script interrupted"; exit 1' INT TERM

WORKSPACE="/home/mleon/.openclaw/workspace"
MEMORY_DIR="$WORKSPACE/memory"

# Verify directories exist before proceeding
if [[ ! -d "$MEMORY_DIR" ]]; then
    echo "ERROR: Memory directory not found: $MEMORY_DIR"
    exit 1
fi
STATE_FILE="$MEMORY_DIR/guardian-state.json"
REPORT_FILE="$MEMORY_DIR/$(date +%Y-%m-%d)-memory-guardian.md"
DRY_RUN=false
REPORT=""

# Protected paths (never touch these)
PROTECTED_DIRS=("$MEMORY_DIR/CORE" "$MEMORY_DIR/PROTOCOLS")
PROTECTED_FILES=(
    "$WORKSPACE/MEMORY.md"
    "$WORKSPACE/SOUL.md"
    "$WORKSPACE/IDENTITY.md"
    "$WORKSPACE/TOOLS.md"
    "$WORKSPACE/AGENTS.md"
    "$MEMORY_DIR/INDEX.md"
)

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_title() { echo -e "\n${BLUE}═══ $1 ═══${NC}\n"; }

# Check if path is protected
is_protected() {
    local file="$1"
    for pf in "${PROTECTED_FILES[@]}"; do
        [[ "$file" == "$pf" ]] && return 0
    done
    for pd in "${PROTECTED_DIRS[@]}"; do
        [[ "$file" == "$pd"* ]] && return 0
    done
    return 1
}

# Safe delete: use trash if available, else move to .trash/
safe_delete() {
    local file="$1"
    if is_protected "$file"; then
        log_warn "PROTECTED, skipping: $file"
        return 1
    fi
    if $DRY_RUN; then
        log_info "[DRY-RUN] Would delete: ${file#$WORKSPACE/}"
        return 0
    fi
    if command -v trash &>/dev/null; then
        trash "$file"
    else
        local trash_dir="$WORKSPACE/.trash/$(date +%Y%m%d)"
        mkdir -p "$trash_dir"
        mv "$file" "$trash_dir/"
    fi
    return 0
}

report() { REPORT+="$1"$'\n'; }

# =============================================================================
# STATUS: Quick overview
# =============================================================================
cmd_status() {
    log_title "MEMORY STATUS"
    
    local total_size=$(du -sh "$MEMORY_DIR" 2>/dev/null | cut -f1)
    local file_count=$(find "$MEMORY_DIR" -type f | wc -l)
    local md_count=$(find "$MEMORY_DIR" -type f -name "*.md" | wc -l)
    
    echo "Total memory size:  $total_size"
    echo "Total files:        $file_count"
    echo "Markdown files:     $md_count"
    echo ""
    
    echo "Directory breakdown:"
    for dir in "$MEMORY_DIR"/*/; do
        [ -d "$dir" ] || continue
        local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        local name=$(basename "$dir")
        printf "  %-20s %s\n" "$name/" "$size"
    done
    echo ""
    
    # HOT/WARM/COLD
    for tier in HOT WARM COLD; do
        local tdir="$MEMORY_DIR/DAILY/$tier"
        if [ -d "$tdir" ]; then
            local tsize=$(du -sh "$tdir" 2>/dev/null | cut -f1)
            local tcount=$(find "$tdir" -type f | wc -l)
            printf "  DAILY/%-12s %s (%d files)\n" "$tier" "$tsize" "$tcount"
        fi
    done
    echo ""
    
    # Temp/backup files
    local tmp_count=$(find "$MEMORY_DIR" -type f \( -name "*.tmp" -o -name "*.bak" -o -name "*.temp" -o -name "*.backup-*" \) 2>/dev/null | wc -l)
    local bloat_count=$(find "$MEMORY_DIR" -type f -size +500k 2>/dev/null | wc -l)
    
    echo "Temp/backup files:  $tmp_count"
    echo "Large files (>500K): $bloat_count"
    
    # Token estimation
    local total_lines=$(find "$MEMORY_DIR" -type f -name "*.md" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}')
    local est_tokens=$((total_lines * 12))  # ~12 tokens per line avg for markdown
    echo "Estimated tokens:   ~$est_tokens (${total_lines} lines)"
    
    # Last guardian run
    if [ -f "$STATE_FILE" ]; then
        local last_run=$(cat "$STATE_FILE" 2>/dev/null | grep -o '"lastRun":"[^"]*"' | cut -d'"' -f4)
        echo "Last guardian run:  $last_run"
    else
        echo "Last guardian run:  never"
    fi
}

# =============================================================================
# ANALYZE: Detect bloat, issues, waste
# =============================================================================
cmd_analyze() {
    log_title "MEMORY ANALYSIS"
    report "# Memory Guardian Analysis — $(date '+%Y-%m-%d %H:%M')"
    report ""
    
    # Storage breakdown
    report "## 📊 Storage Breakdown"
    report ""
    local total_size=$(du -sh "$MEMORY_DIR" 2>/dev/null | cut -f1)
    report "**Total:** $total_size"
    report ""
    for dir in "$MEMORY_DIR"/*/; do
        [ -d "$dir" ] || continue
        local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        report "- $(basename "$dir")/: $size"
    done
    report ""
    
    # Large files
    report "## ⚠️ Large Files (>500KB)"
    report ""
    local large_found=false
    while IFS= read -r file; do
        large_found=true
        local size=$(du -h "$file" | cut -f1)
        report "- ${file#$MEMORY_DIR/}: **$size**"
    done < <(find "$MEMORY_DIR" -type f -size +500k 2>/dev/null)
    $large_found || report "✅ No large files detected"
    report ""
    
    # Temp/backup files
    report "## 🗑️ Cleanable Files"
    report ""
    local cleanable=0
    local cleanable_size=0
    while IFS= read -r file; do
        cleanable=$((cleanable + 1))
        local bytes=$(stat -c %s "$file" 2>/dev/null || echo 0)
        cleanable_size=$((cleanable_size + bytes))
        report "- ${file#$MEMORY_DIR/} ($(du -h "$file" | cut -f1))"
    done < <(find "$MEMORY_DIR" -type f \( -name "*.tmp" -o -name "*.bak" -o -name "*.temp" -o -name "*.backup-*" \) 2>/dev/null)
    
    # Empty/tiny files (<100 bytes, not protected)
    while IFS= read -r file; do
        is_protected "$file" && continue
        [[ "$(basename "$file")" == ".gitkeep" ]] && continue
        cleanable=$((cleanable + 1))
        report "- ${file#$MEMORY_DIR/} (tiny, <100B)"
    done < <(find "$MEMORY_DIR" -type f -size -100c -name "*.md" 2>/dev/null)
    
    if [ $cleanable -eq 0 ]; then
        report "✅ Nothing to clean"
    else
        report ""
        report "**Cleanable files:** $cleanable (~$((cleanable_size / 1024))KB)"
    fi
    report ""
    
    # Old files (>30 days) not in COLD
    report "## 📦 Compressible (>30 days, not in COLD)"
    report ""
    local compressible=0
    local thirty_days_ago=$(date -d "30 days ago" +%s 2>/dev/null || date -v-30d +%s 2>/dev/null || echo 0)
    for tier in HOT WARM; do
        local tdir="$MEMORY_DIR/DAILY/$tier"
        [ -d "$tdir" ] || continue
        while IFS= read -r file; do
            local mtime=$(stat -c %Y "$file" 2>/dev/null || echo 999999999999)
            if [ "$mtime" -lt "$thirty_days_ago" ]; then
                compressible=$((compressible + 1))
                report "- ${file#$MEMORY_DIR/}"
            fi
        done < <(find "$tdir" -type f 2>/dev/null)
    done
    [ $compressible -eq 0 ] && report "✅ No files need compression"
    report ""
    
    # Token estimation
    report "## 🎯 Token Estimation"
    report ""
    for tier in HOT WARM COLD; do
        local tdir="$MEMORY_DIR/DAILY/$tier"
        [ -d "$tdir" ] || continue
        local lines=$(find "$tdir" -type f -name "*.md" -exec cat {} + 2>/dev/null | wc -l)
        local chars=$(find "$tdir" -type f -name "*.md" -exec cat {} + 2>/dev/null | wc -c)
        local tokens=$((chars / 4))  # ~4 chars per token
        report "- DAILY/$tier: ~$tokens tokens ($lines lines, $((chars/1024))KB)"
    done
    local total_chars=$(find "$MEMORY_DIR" -type f -name "*.md" -exec cat {} + 2>/dev/null | wc -c)
    local total_tokens=$((total_chars / 4))
    report ""
    report "**Total estimated tokens:** ~$total_tokens"
    report ""
    
    echo "$REPORT"
    log_info "Analysis complete"
}

# =============================================================================
# CLEAN: Remove temp files, backups, tiny files
# =============================================================================
cmd_clean() {
    log_title "MEMORY CLEANUP${DRY_RUN:+ (DRY-RUN)}"
    
    local deleted=0
    local freed_bytes=0
    report "## 🧹 Cleanup Results"
    report ""
    
    # Backups (.backup-*)
    while IFS= read -r file; do
        local bytes=$(stat -c %s "$file" 2>/dev/null || echo 0)
        if safe_delete "$file"; then
            deleted=$((deleted + 1))
            freed_bytes=$((freed_bytes + bytes))
            report "- Deleted: ${file#$WORKSPACE/} ($((bytes/1024))KB)"
        fi
    done < <(find "$MEMORY_DIR" -type f -name "*.backup-*" 2>/dev/null)
    
    # Temp files
    while IFS= read -r file; do
        local bytes=$(stat -c %s "$file" 2>/dev/null || echo 0)
        if safe_delete "$file"; then
            deleted=$((deleted + 1))
            freed_bytes=$((freed_bytes + bytes))
            report "- Deleted: ${file#$WORKSPACE/} ($((bytes/1024))KB)"
        fi
    done < <(find "$MEMORY_DIR" -type f \( -name "*.tmp" -o -name "*.bak" -o -name "*.temp" \) 2>/dev/null)
    
    # Tiny empty .md files (<100 bytes, not protected)
    while IFS= read -r file; do
        is_protected "$file" && continue
        [[ "$(basename "$file")" == ".gitkeep" ]] && continue
        local bytes=$(stat -c %s "$file" 2>/dev/null || echo 0)
        if safe_delete "$file"; then
            deleted=$((deleted + 1))
            freed_bytes=$((freed_bytes + bytes))
            report "- Deleted (tiny): ${file#$WORKSPACE/}"
        fi
    done < <(find "$MEMORY_DIR" -type f -size -100c -name "*.md" 2>/dev/null)
    
    # Old guardian reports (keep last 4)
    local report_count=0
    while IFS= read -r file; do
        report_count=$((report_count + 1))
        if [ $report_count -gt 4 ]; then
            local bytes=$(stat -c %s "$file" 2>/dev/null || echo 0)
            if safe_delete "$file"; then
                deleted=$((deleted + 1))
                freed_bytes=$((freed_bytes + bytes))
                report "- Deleted (old report): ${file#$WORKSPACE/}"
            fi
        fi
    done < <(find "$MEMORY_DIR" -maxdepth 1 -name "*-memory-guardian.md" -type f | sort -r)
    
    report ""
    report "**Deleted:** $deleted files (~$((freed_bytes/1024))KB freed)"
    $DRY_RUN && report "*(dry-run mode — nothing was actually deleted)*"
    report ""
    
    echo "$REPORT"
    log_info "Cleanup complete: $deleted files, ~$((freed_bytes/1024))KB freed"
}

# =============================================================================
# COMPRESS: Archive files >30 days to COLD
# =============================================================================
cmd_compress() {
    log_title "MEMORY COMPRESSION${DRY_RUN:+ (DRY-RUN)}"
    
    local compressed=0
    local cold_dir="$MEMORY_DIR/DAILY/COLD"
    mkdir -p "$cold_dir"
    
    local thirty_days_ago=$(date -d "30 days ago" +%s 2>/dev/null || echo 0)
    
    report "## 📦 Compression Results"
    report ""
    
    for tier in HOT WARM; do
        local tdir="$MEMORY_DIR/DAILY/$tier"
        [ -d "$tdir" ] || continue
        
        # Check both files and directories
        while IFS= read -r item; do
            local mtime=$(stat -c %Y "$item" 2>/dev/null || echo 999999999999)
            if [ "$mtime" -lt "$thirty_days_ago" ]; then
                local name=$(basename "$item")
                if $DRY_RUN; then
                    log_info "[DRY-RUN] Would compress: DAILY/$tier/$name → COLD/"
                    report "- Would compress: DAILY/$tier/$name"
                else
                    if [ -d "$item" ]; then
                        tar czf "$cold_dir/${name}.tar.gz" -C "$tdir" "$name" 2>/dev/null && rm -rf "$item"
                    else
                        gzip -c "$item" > "$cold_dir/${name}.gz" && rm -f "$item"
                    fi
                    report "- Compressed: DAILY/$tier/$name → COLD/"
                fi
                compressed=$((compressed + 1))
            fi
        done < <(find "$tdir" -maxdepth 1 -mindepth 1 2>/dev/null)
    done
    
    report ""
    report "**Compressed:** $compressed items"
    report ""
    
    echo "$REPORT"
    log_info "Compression complete: $compressed items"
}

# =============================================================================
# DEDUPE: Find duplicate files by MD5
# =============================================================================
cmd_dedupe() {
    log_title "DUPLICATE DETECTION"
    
    report "## 🔍 Duplicate Analysis"
    report ""
    
    local tmpfile="/tmp/memory-guardian-hashes-$$.txt"
    find "$MEMORY_DIR" -type f -size +1k -name "*.md" -exec md5sum {} \; 2>/dev/null | sort > "$tmpfile"
    
    local dup_found=false
    local prev_hash=""
    local prev_file=""
    
    while IFS=' ' read -r hash file; do
        hash="${hash%% *}"
        if [ "$hash" = "$prev_hash" ] && [ -n "$prev_hash" ]; then
            if ! $dup_found; then
                dup_found=true
            fi
            report "- **Duplicate pair:**"
            report "  - ${prev_file#$MEMORY_DIR/}"
            report "  - ${file#$MEMORY_DIR/}"
            report ""
        fi
        prev_hash="$hash"
        prev_file="$file"
    done < "$tmpfile"
    
    $dup_found || report "✅ No duplicates found"
    report ""
    
    rm -f "$tmpfile"
    echo "$REPORT"
    log_info "Deduplication analysis complete"
}

# =============================================================================
# Save state
# =============================================================================
save_state() {
    local action="$1"
    local total_size=$(du -sb "$MEMORY_DIR" 2>/dev/null | cut -f1)
    local file_count=$(find "$MEMORY_DIR" -type f | wc -l)
    
    cat > "$STATE_FILE" << EOF
{
  "lastRun": "$(date -Iseconds)",
  "lastAction": "$action",
  "totalSizeBytes": $total_size,
  "fileCount": $file_count,
  "dryRun": $DRY_RUN
}
EOF
}

# =============================================================================
# Write report to file
# =============================================================================
write_report() {
    if [ -n "$REPORT" ] && ! $DRY_RUN; then
        echo "$REPORT" > "$REPORT_FILE"
        log_info "Report saved: $REPORT_FILE"
    fi
}

# =============================================================================
# MAIN
# =============================================================================
ACTION=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --analyze)  ACTION="analyze" ;;
        --clean)    ACTION="clean" ;;
        --compress) ACTION="compress" ;;
        --status)   ACTION="status" ;;
        --dry-run)  DRY_RUN=true ;;
        --dedupe)   ACTION="dedupe" ;;
        --full)     ACTION="full" ;;
        # Legacy positional commands
        analyze)    ACTION="analyze" ;;
        cleanup|clean) ACTION="clean" ;;
        compress)   ACTION="compress" ;;
        dedupe)     ACTION="dedupe" ;;
        full)       ACTION="full" ;;
        status)     ACTION="status" ;;
        *)
            echo "Unknown option: $1"
            ACTION="help"
            ;;
    esac
    shift
done

[ -z "$ACTION" ] && ACTION="help"

case "$ACTION" in
    status)
        cmd_status
        ;;
    analyze)
        cmd_analyze
        write_report
        save_state "analyze"
        ;;
    clean)
        cmd_clean
        write_report
        save_state "clean"
        ;;
    compress)
        cmd_compress
        write_report
        save_state "compress"
        ;;
    dedupe)
        cmd_dedupe
        write_report
        save_state "dedupe"
        ;;
    full)
        cmd_analyze
        cmd_clean
        cmd_compress
        cmd_dedupe
        write_report
        save_state "full"
        ;;
    *)
        cat << 'EOF'
Memory Guardian Pro v2 — Auto-cleanup & optimization

Usage:
  bash memory-guardian.sh [OPTIONS]

Options:
  --status     Quick memory overview
  --analyze    Detect bloat, waste, duplicates (read-only)
  --clean      Remove temp/backup files
  --compress   Archive files >30 days to COLD
  --dedupe     Find duplicate files (MD5)
  --full       Run all (analyze + clean + compress + dedupe)
  --dry-run    Simulate without changes (combine with --clean/--compress)

Examples:
  bash memory-guardian.sh --status
  bash memory-guardian.sh --dry-run --clean
  bash memory-guardian.sh --full

Protected (never touched):
  CORE/, PROTOCOLS/, MEMORY.md, SOUL.md, IDENTITY.md, TOOLS.md, AGENTS.md

All deletions use .trash/ (recoverable).
EOF
        exit 1
        ;;
esac
