#!/bin/bash
# =============================================================================
# critical-update.sh — Framework de cambios críticos con safety & rollback
# =============================================================================
# Uso: bash scripts/critical-update.sh [OPCIÓN] [ARGS...]
#
#   --baseline              Capturar health snapshot completo
#   --test FILE             Validar cambio en sandbox (copia temporal)
#   --apply FILE            Aplicar cambio real (backup + validate + auto-rollback)
#   --rollback [FILE]       Rollback a último backup conocido
#   --validate              Ejecutar todas las validaciones
#   --status                Ver estado actual del sistema
#   --dry-run FILE          Simular apply sin cambios reales
#   --log MSG               Registrar entrada en audit trail
#
# Ejemplo flujo completo:
#   bash scripts/critical-update.sh --baseline
#   sudo nano /tmp/critical-sandbox/sshd_config   # editar copia
#   bash scripts/critical-update.sh --test /etc/ssh/sshd_config
#   bash scripts/critical-update.sh --apply /etc/ssh/sshd_config
#   bash scripts/critical-update.sh --validate
# =============================================================================

set -euo pipefail

# --- Config ---
WORKSPACE="${WORKSPACE:-/home/mleon/.openclaw/workspace}"
CHANGES_DIR="$WORKSPACE/memory/CHANGES"
BASELINE_DIR="/tmp/critical-baseline-$(date +%Y%m%d-%H%M%S)"
BASELINE_LATEST="/tmp/critical-baseline-latest"
BACKUP_DIR="/tmp/critical-backups"
SANDBOX_DIR="/tmp/critical-sandbox"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log_ok()   { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_fail() { echo -e "${RED}[✗]${NC} $1"; }
log_info() { echo -e "${BLUE}[i]${NC} $1"; }

mkdir -p "$CHANGES_DIR" "$BACKUP_DIR" "$SANDBOX_DIR"

# =============================================================================
# VALIDATIONS — Individual health checks
# =============================================================================
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_TOTAL=0

check() {
    local name="$1"; shift
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
    if eval "$@" >/dev/null 2>&1; then
        log_ok "$name"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
        return 0
    else
        log_fail "$name"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
        return 1
    fi
}

validate_ssh() {
    log_info "=== SSH Validations ==="
    check "SSH service active" "systemctl is-active ssh"
    check "SSH port 22 listening" "ss -tlnp | grep -q ':22 '"
    check "sshd_config syntax" "sudo sshd -t"
}

validate_firewall() {
    log_info "=== Firewall Validations ==="
    check "UFW active" "sudo ufw status | grep -q 'Status: active'"
    check "SSH allowed in UFW" "sudo ufw status | grep -q '22'"
}

validate_network() {
    log_info "=== Network Validations ==="
    check "DNS resolves" "host google.com"
    check "Gateway reachable" "ip route | grep default | head -1 | awk '{print \$3}' | xargs ping -c1 -W2"
    check "Internet connectivity" "ping -c1 -W3 8.8.8.8"
    check "HTTPS works" "curl -sf --max-time 5 https://api.ipify.org >/dev/null"
}

validate_services() {
    log_info "=== Critical Services ==="
    check "fail2ban active" "systemctl is-active fail2ban"
    # openclaw-gateway may not exist on all systems
    if systemctl list-units --type=service | grep -q openclaw-gateway; then
        check "openclaw-gateway active" "systemctl is-active openclaw-gateway"
    fi
}

validate_resources() {
    log_info "=== Resources ==="
    check "Disk >10% free" "test \$(df / --output=pcent | tail -1 | tr -d '% ') -lt 90"
    check "Memory available" "test \$(free | awk '/Mem:/{printf \"%.0f\", \$7/\$2*100}') -gt 5"
}

validate_all() {
    CHECKS_PASSED=0; CHECKS_FAILED=0; CHECKS_TOTAL=0
    echo ""
    validate_ssh
    echo ""
    validate_firewall
    echo ""
    validate_network
    echo ""
    validate_services
    echo ""
    validate_resources
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ $CHECKS_FAILED -eq 0 ]; then
        log_ok "ALL CHECKS PASSED: $CHECKS_PASSED/$CHECKS_TOTAL"
    else
        log_fail "FAILED: $CHECKS_FAILED/$CHECKS_TOTAL checks failed"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    return $CHECKS_FAILED
}

# =============================================================================
# BASELINE — Capture system health snapshot
# =============================================================================
do_baseline() {
    mkdir -p "$BASELINE_DIR"
    log_info "Capturing baseline → $BASELINE_DIR"

    # System info
    date > "$BASELINE_DIR/timestamp"
    uname -a > "$BASELINE_DIR/uname"
    uptime > "$BASELINE_DIR/uptime"

    # Network
    ip addr show > "$BASELINE_DIR/ip-addr" 2>&1
    ip route show > "$BASELINE_DIR/ip-route" 2>&1
    ss -tlnp > "$BASELINE_DIR/listening-ports" 2>&1
    cat /etc/resolv.conf > "$BASELINE_DIR/resolv.conf" 2>&1

    # Services
    systemctl list-units --type=service --state=running > "$BASELINE_DIR/services-running" 2>&1

    # Firewall
    sudo ufw status verbose > "$BASELINE_DIR/ufw-status" 2>&1 || true

    # SSH config
    cp /etc/ssh/sshd_config "$BASELINE_DIR/sshd_config" 2>/dev/null || true

    # Resources
    df -h > "$BASELINE_DIR/disk" 2>&1
    free -h > "$BASELINE_DIR/memory" 2>&1

    # Fail2ban
    sudo fail2ban-client status > "$BASELINE_DIR/fail2ban" 2>&1 || true

    # Run validations and save
    validate_all > "$BASELINE_DIR/validation-results.txt" 2>&1 || true

    # Update latest symlink
    ln -sfn "$BASELINE_DIR" "$BASELINE_LATEST"

    log_ok "Baseline saved: $BASELINE_DIR"
    log_ok "Symlink: $BASELINE_LATEST"
    audit_log "BASELINE" "Health baseline captured" "$BASELINE_DIR"
}

# =============================================================================
# TEST — Validate change in sandbox
# =============================================================================
do_test() {
    local target_file="$1"
    if [ ! -f "$target_file" ]; then
        log_fail "File not found: $target_file"
        exit 1
    fi

    local basename=$(basename "$target_file")
    local sandbox_file="$SANDBOX_DIR/$basename"

    # Copy to sandbox if not already there
    if [ ! -f "$sandbox_file" ]; then
        cp "$target_file" "$sandbox_file"
        log_info "Copied to sandbox: $sandbox_file"
        log_info "Edit this file, then re-run --test to validate"
    fi

    log_info "Testing sandbox copy: $sandbox_file"

    # Service-specific validation
    case "$target_file" in
        */sshd_config)
            log_info "=== SSH Config Validation ==="
            check "Syntax check" "sudo sshd -t -f $sandbox_file"
            # Check for dangerous settings
            if grep -qi "^PermitRootLogin yes" "$sandbox_file"; then
                log_warn "PermitRootLogin is YES — risky!"
            fi
            if grep -qi "^PasswordAuthentication yes" "$sandbox_file"; then
                log_warn "PasswordAuthentication is YES — consider key-only"
            fi
            if grep -qi "^AllowTcpForwarding no" "$sandbox_file"; then
                log_warn "AllowTcpForwarding=no — THIS BREAKS VNC/TUNNELS!"
            fi
            # Diff
            echo ""
            log_info "Changes from current config:"
            diff "$target_file" "$sandbox_file" || true
            ;;
        */ufw/*)
            log_info "=== Firewall Config Validation ==="
            log_warn "UFW configs should be tested via ufw commands, not file edits"
            diff "$target_file" "$sandbox_file" || true
            ;;
        *)
            log_info "=== Generic Config Validation ==="
            diff "$target_file" "$sandbox_file" || true
            ;;
    esac

    audit_log "TEST" "Sandbox test for $target_file" "$sandbox_file"
}

# =============================================================================
# APPLY — Apply change with backup + validation + auto-rollback
# =============================================================================
do_apply() {
    local target_file="$1"
    local sandbox_file="$SANDBOX_DIR/$(basename "$target_file")"
    local dry_run="${2:-false}"

    if [ ! -f "$target_file" ]; then
        log_fail "Target file not found: $target_file"
        exit 1
    fi

    if [ ! -f "$sandbox_file" ]; then
        log_fail "No sandbox version found. Run --test first."
        exit 1
    fi

    # Check for changes
    if diff -q "$target_file" "$sandbox_file" >/dev/null 2>&1; then
        log_info "No changes detected between current and sandbox"
        return 0
    fi

    # Show diff
    echo ""
    log_info "Changes to apply:"
    diff "$target_file" "$sandbox_file" || true
    echo ""

    if [ "$dry_run" = "true" ]; then
        log_info "[DRY RUN] Would apply changes above to $target_file"
        log_info "[DRY RUN] Would restart related service"
        log_info "[DRY RUN] Would validate post-change"
        return 0
    fi

    # Confirmation
    echo -e "${YELLOW}Apply these changes to $target_file? [y/N]${NC}"
    read -r confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        log_info "Aborted by user"
        return 1
    fi

    # Backup current version
    local backup_ts=$(date +%Y%m%d-%H%M%S)
    local backup_file="$BACKUP_DIR/$(echo "$target_file" | tr '/' '_').$backup_ts"
    cp "$target_file" "$backup_file"
    log_ok "Backup: $backup_file"

    # Track latest backup for rollback
    echo "$backup_file|$target_file" > "$BACKUP_DIR/.last-change"

    # Apply
    sudo cp "$sandbox_file" "$target_file"
    log_ok "Applied changes to $target_file"

    # Restart related service
    case "$target_file" in
        */sshd_config)
            log_info "Reloading SSH..."
            sudo systemctl reload ssh || sudo systemctl restart ssh
            sleep 2
            ;;
        */fail2ban/*)
            log_info "Restarting fail2ban..."
            sudo systemctl restart fail2ban
            sleep 2
            ;;
    esac

    # Validate
    log_info "Running post-change validations..."
    if validate_all; then
        log_ok "✅ Change applied successfully — all validations passed"
        audit_log "APPLY" "Applied change to $target_file" "OK — $CHECKS_PASSED/$CHECKS_TOTAL passed"
        # Cleanup sandbox
        rm -f "$sandbox_file"
    else
        log_fail "❌ VALIDATIONS FAILED — INITIATING AUTO-ROLLBACK"
        audit_log "APPLY-FAILED" "Change to $target_file failed validation" "ROLLING BACK"
        do_rollback "$target_file"
    fi
}

# =============================================================================
# ROLLBACK — Restore from backup
# =============================================================================
do_rollback() {
    local target_file="${1:-}"

    if [ -n "$target_file" ]; then
        # Find latest backup for this file
        local pattern=$(echo "$target_file" | tr '/' '_')
        local latest_backup=$(ls -t "$BACKUP_DIR/${pattern}."* 2>/dev/null | head -1)
        if [ -z "$latest_backup" ]; then
            log_fail "No backup found for $target_file"
            exit 1
        fi
        log_info "Rolling back $target_file from $latest_backup"
        sudo cp "$latest_backup" "$target_file"
    elif [ -f "$BACKUP_DIR/.last-change" ]; then
        # Use last tracked change
        local backup_file=$(cut -d'|' -f1 "$BACKUP_DIR/.last-change")
        target_file=$(cut -d'|' -f2 "$BACKUP_DIR/.last-change")
        log_info "Rolling back $target_file from $backup_file"
        sudo cp "$backup_file" "$target_file"
    else
        log_fail "No rollback target found. Specify file or run --apply first."
        exit 1
    fi

    # Restart related service
    case "$target_file" in
        */sshd_config)
            sudo systemctl reload ssh || sudo systemctl restart ssh
            sleep 2
            ;;
        */fail2ban/*)
            sudo systemctl restart fail2ban
            sleep 2
            ;;
    esac

    log_ok "Rollback complete for $target_file"

    # Validate after rollback
    log_info "Validating after rollback..."
    if validate_all; then
        log_ok "✅ System healthy after rollback"
        audit_log "ROLLBACK" "Rolled back $target_file" "OK — system healthy"
    else
        log_fail "⚠️ System still has issues after rollback!"
        log_fail "MANUAL INTERVENTION REQUIRED"
        audit_log "ROLLBACK-WARN" "Rolled back $target_file but issues remain" "NEEDS MANUAL FIX"
    fi
}

# =============================================================================
# STATUS — Current system health
# =============================================================================
do_status() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  CRITICAL UPDATE FRAMEWORK — System Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Baseline:  $(readlink -f "$BASELINE_LATEST" 2>/dev/null || echo 'none')"
    echo "Backups:   $(ls "$BACKUP_DIR" 2>/dev/null | wc -l) files"
    echo "Sandbox:   $(ls "$SANDBOX_DIR" 2>/dev/null | wc -l) files pending"
    echo "Audit log: $(ls "$CHANGES_DIR"/changes-*.log 2>/dev/null | wc -l) entries"
    echo ""

    if [ -f "$BACKUP_DIR/.last-change" ]; then
        echo "Last change:"
        echo "  Backup: $(cut -d'|' -f1 "$BACKUP_DIR/.last-change")"
        echo "  File:   $(cut -d'|' -f2 "$BACKUP_DIR/.last-change")"
    fi
    echo ""

    validate_all
}

# =============================================================================
# AUDIT LOG — Record changes
# =============================================================================
audit_log() {
    local action="$1" description="$2" details="${3:-}"
    local logfile="$CHANGES_DIR/changes-$(date +%Y-%m-%d).log"
    local ts=$(date '+%Y-%m-%d %H:%M:%S')

    cat >> "$logfile" <<EOF

=== CRITICAL CHANGE LOG ===
Date: $ts
Action: $action
Description: $description
Details: $details
User: $(whoami)
Baseline: $(readlink -f "$BASELINE_LATEST" 2>/dev/null || echo 'none')
===========================
EOF
}

# =============================================================================
# MAIN
# =============================================================================
case "${1:-}" in
    --baseline)
        do_baseline
        ;;
    --test)
        [ -z "${2:-}" ] && { echo "Usage: $0 --test FILE"; exit 1; }
        do_test "$2"
        ;;
    --apply)
        [ -z "${2:-}" ] && { echo "Usage: $0 --apply FILE"; exit 1; }
        do_apply "$2" "false"
        ;;
    --dry-run)
        [ -z "${2:-}" ] && { echo "Usage: $0 --dry-run FILE"; exit 1; }
        do_apply "$2" "true"
        ;;
    --rollback)
        do_rollback "${2:-}"
        ;;
    --validate)
        validate_all
        ;;
    --status)
        do_status
        ;;
    --log)
        [ -z "${2:-}" ] && { echo "Usage: $0 --log 'message'"; exit 1; }
        audit_log "MANUAL" "$2"
        log_ok "Logged: $2"
        ;;
    *)
        echo "Critical Update Safety Framework"
        echo ""
        echo "Usage: bash $0 [OPTION] [ARGS]"
        echo ""
        echo "Options:"
        echo "  --baseline        Capture health snapshot"
        echo "  --test FILE       Validate change in sandbox"
        echo "  --apply FILE      Apply change (backup + validate + auto-rollback)"
        echo "  --dry-run FILE    Simulate apply without changes"
        echo "  --rollback [FILE] Restore from backup"
        echo "  --validate        Run all health validations"
        echo "  --status          Show system status"
        echo "  --log MSG         Record manual audit entry"
        echo ""
        echo "Typical flow:"
        echo "  1. $0 --baseline"
        echo "  2. Edit /tmp/critical-sandbox/FILE"
        echo "  3. $0 --test /path/to/FILE"
        echo "  4. $0 --apply /path/to/FILE"
        echo "  5. $0 --validate"
        ;;
esac
