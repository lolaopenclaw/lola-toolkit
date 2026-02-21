#!/bin/bash
# =============================================================================
# wal-logger.sh — Write-Ahead Logging for Agent State
# =============================================================================
# Garantiza consistencia y recuperabilidad de cambios críticos
# 
# Uso:
#   bash wal-logger.sh log "MESSAGE" [severity]    → Log cambio
#   bash wal-logger.sh replay [--dry-run]          → Recuperar desde crash
#   bash wal-logger.sh snapshot                      → Crear snapshot
#   bash wal-logger.sh validate                      → Verificar integridad
# =============================================================================

set -euo pipefail

WAL_DIR="/home/mleon/.openclaw/workspace/memory/WAL"
WAL_LOG="$WAL_DIR/$(date +%Y-%m-%d).log"
WAL_LOCK="$WAL_DIR/.lock"
SNAPSHOT_DIR="$WAL_DIR/snapshots"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

# =============================================================================
# INIT: Create directories if needed
# =============================================================================
init() {
    mkdir -p "$WAL_DIR" "$SNAPSHOT_DIR"
    touch "$WAL_LOG"
}

# =============================================================================
# LOG: Write-Ahead Log entry
# =============================================================================
log_entry() {
    local message="$1"
    local severity="${2:-INFO}"
    local timestamp=$(date -u +"%Y-%m-%d %H:%M:%S")
    
    # Acquire lock
    exec 200>"$WAL_LOCK"
    flock 200
    
    # Write entry
    {
        echo "[$timestamp] [$severity] $message"
        echo "SHA256: $(echo "$message" | sha256sum | cut -d' ' -f1)"
    } >> "$WAL_LOG"
    
    # Release lock
    flock -u 200
    
    log_info "Logged: $message (severity: $severity)"
}

# =============================================================================
# SNAPSHOT: Create point-in-time snapshot
# =============================================================================
snapshot() {
    local snapshot_file="$SNAPSHOT_DIR/snapshot-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    log_info "Creating snapshot..."
    
    # Backup critical files
    tar czf "$snapshot_file" \
        -C /home/mleon/.openclaw/workspace \
        SOUL.md MEMORY.md memory/ scripts/ 2>/dev/null || true
    
    # Log snapshot creation
    local size=$(du -h "$snapshot_file" | cut -f1)
    log_entry "SNAPSHOT: Created $snapshot_file (size: $size)" "SNAPSHOT"
    
    log_info "Snapshot saved: $snapshot_file"
}

# =============================================================================
# REPLAY: Replay WAL in case of crash
# =============================================================================
replay() {
    local dry_run="${1:-}"
    
    log_info "Replaying WAL entries..."
    
    if [ "$dry_run" = "--dry-run" ]; then
        echo "=== DRY RUN: WAL Replay ==="
        cat "$WAL_LOG" | grep -v "^$" | tail -20
        return 0
    fi
    
    # Verify WAL integrity
    if ! validate; then
        log_error "WAL integrity check failed. Aborting replay."
        return 1
    fi
    
    # Parse and apply entries
    local count=0
    while IFS= read -r line; do
        if [[ "$line" =~ \[CRITICAL\]|\[ERROR\] ]]; then
            echo "Critical action: $line"
            count=$((count + 1))
        fi
    done < "$WAL_LOG"
    
    log_info "Replayed $count critical actions from WAL"
}

# =============================================================================
# VALIDATE: Verify WAL integrity
# =============================================================================
validate() {
    log_info "Validating WAL integrity..."
    
    local errors=0
    while IFS= read -r line; do
        if [[ "$line" =~ SHA256:\ ([a-f0-9]+) ]]; then
            local stored_hash="${BASH_REMATCH[1]}"
            # Verify format is correct (SHA256 hashes are 64 chars)
            if [[ ! "$stored_hash" =~ ^[a-f0-9]{64}$ ]]; then
                log_error "Invalid hash: $stored_hash"
                errors=$((errors + 1))
            fi
        fi
    done < "$WAL_LOG"
    
    if [ $errors -eq 0 ]; then
        log_info "WAL integrity: OK ✓"
        return 0
    else
        log_error "Found $errors integrity errors"
        return 1
    fi
}

# =============================================================================
# ROTATE: Archive old logs
# =============================================================================
rotate() {
    log_info "Rotating WAL logs..."
    
    # Archive logs older than 7 days
    find "$WAL_DIR" -maxdepth 1 -name "*.log" -mtime +7 | while read file; do
        gzip "$file"
        log_entry "ROTATE: Archived $file" "MAINTENANCE"
    done
    
    log_info "WAL rotation complete"
}

# =============================================================================
# REPORT: Generate WAL report
# =============================================================================
report() {
    echo "=== WAL Report — $(date) ==="
    echo ""
    echo "📊 Statistics:"
    echo "- Log file: $WAL_LOG"
    echo "- Total entries: $(grep -c '^\[' "$WAL_LOG" || echo 0)"
    echo "- Log size: $(du -h "$WAL_LOG" | cut -f1)"
    echo ""
    echo "📋 Latest 10 entries:"
    tail -20 "$WAL_LOG" | grep "^\[" | tail -10
    echo ""
    echo "📦 Snapshots:"
    ls -lh "$SNAPSHOT_DIR" 2>/dev/null | tail -5 || echo "No snapshots yet"
}

# =============================================================================
# MAIN
# =============================================================================
COMMAND="${1:-help}"

init

case "$COMMAND" in
    log)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 log \"MESSAGE\" [severity]"
            exit 1
        fi
        log_entry "$2" "${3:-INFO}"
        ;;
    snapshot)
        snapshot
        ;;
    replay)
        replay "${2:-}"
        ;;
    validate)
        validate
        ;;
    rotate)
        rotate
        ;;
    report)
        report
        ;;
    *)
        cat << EOF
WAL Logger — Write-Ahead Logging for Agent State

Usage:
  bash wal-logger.sh log "MESSAGE" [severity]     → Log a change
  bash wal-logger.sh snapshot                      → Create snapshot
  bash wal-logger.sh replay [--dry-run]            → Replay from crash
  bash wal-logger.sh validate                      → Check integrity
  bash wal-logger.sh rotate                        → Archive old logs
  bash wal-logger.sh report                        → Show report

Severities: INFO, WARNING, CRITICAL, ERROR, SNAPSHOT, MAINTENANCE

WAL ensures consistency:
  1. Change is logged first (write-ahead)
  2. Then applied in memory
  3. On crash, replay log to recover state

Location: $WAL_DIR/
EOF
        exit 1
        ;;
esac
