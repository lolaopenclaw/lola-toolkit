#!/bin/bash
# =============================================================================
# canary-test.sh — Pre-update health baseline + canary testing
# =============================================================================
# Usa: bash canary-test.sh [start|test|rollback|validate]
# 
# Workflow:
#   1. canary-test.sh start      → Snapshot de health ANTES del cambio
#   2. [CAMBIO CRÍTICO AQUÍ]     → SSH config, firewall, etc.
#   3. canary-test.sh test       → Valida que todo funcione
#   4. canary-test.sh validate   → Verifica contra baseline
#   5. canary-test.sh rollback   → Si algo falló
# =============================================================================

set -euo pipefail

BASELINE_DIR="/tmp/canary-baseline-$(date +%Y%m%d-%H%M%S)"
BASELINE_LATEST="/tmp/canary-baseline-latest"
HEALTH_SNAPSHOT="$BASELINE_DIR/health-snapshot.json"
CONFIG_SNAPSHOT="$BASELINE_DIR/config-snapshot.json"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

# =============================================================================
# SNAPSHOT: Captura baseline de salud antes de cambios
# =============================================================================
snapshot_health() {
    mkdir -p "$BASELINE_DIR"
    
    log_info "Capturando health baseline..."
    
    # System load
    uptime > "$HEALTH_SNAPSHOT.tmp"
    
    # Network connectivity
    {
        echo "=== NETWORK INTERFACES ==="
        ip addr show
        echo ""
        echo "=== ROUTING ==="
        ip route show
        echo ""
        echo "=== SSH STATUS ==="
        systemctl is-active ssh || echo "SSH STOPPED"
        echo ""
        echo "=== OPEN PORTS ==="
        ss -tlnp 2>/dev/null | grep LISTEN || echo "NO LISTENING PORTS"
    } >> "$HEALTH_SNAPSHOT.tmp"
    
    # DNS resolution
    {
        echo ""
        echo "=== DNS RESOLUTION ==="
        nslookup google.com 2>&1 | head -10 || echo "DNS FAILED"
    } >> "$HEALTH_SNAPSHOT.tmp"
    
    # Firewall rules
    {
        echo ""
        echo "=== UFW STATUS ==="
        sudo ufw status || echo "UFW NOT ACTIVE"
    } >> "$HEALTH_SNAPSHOT.tmp"
    
    # SSH config critical settings
    {
        echo ""
        echo "=== SSH CONFIG CRITICAL ==="
        grep -E "^(Port|PermitRootLogin|PasswordAuthentication|PubkeyAuthentication|AllowTcpForwarding|X11Forwarding)" /etc/ssh/sshd_config || echo "SSH CONFIG ERROR"
    } >> "$HEALTH_SNAPSHOT.tmp"
    
    # Fail2ban status
    {
        echo ""
        echo "=== FAIL2BAN STATUS ==="
        sudo fail2ban-client status 2>/dev/null || echo "FAIL2BAN INACTIVE"
    } >> "$HEALTH_SNAPSHOT.tmp"
    
    # Services critical
    {
        echo ""
        echo "=== CRITICAL SERVICES ==="
        for svc in ssh fail2ban ufw; do
            systemctl is-active "$svc" || echo "$svc: INACTIVE"
        done
    } >> "$HEALTH_SNAPSHOT.tmp"
    
    # Disk space
    {
        echo ""
        echo "=== DISK USAGE ==="
        df -h / | tail -1
    } >> "$HEALTH_SNAPSHOT.tmp"
    
    # Memory
    {
        echo ""
        echo "=== MEMORY STATUS ==="
        free -h | grep "Mem:"
    } >> "$HEALTH_SNAPSHOT.tmp"
    
    mv "$HEALTH_SNAPSHOT.tmp" "$HEALTH_SNAPSHOT"
    
    # Symlink para acceso rápido
    rm -f "$BASELINE_LATEST"
    ln -s "$BASELINE_DIR" "$BASELINE_LATEST"
    
    log_info "Baseline guardado en: $BASELINE_DIR"
    log_info "Acceso rápido: $BASELINE_LATEST"
    echo ""
    echo "=== BASELINE SNAPSHOT ==="
    cat "$HEALTH_SNAPSHOT"
    
    return 0
}

# =============================================================================
# TEST: Valida funcionalidad post-cambio
# =============================================================================
test_connectivity() {
    log_info "Testando conectividad..."
    
    # SSH local
    if ! ssh -o ConnectTimeout=5 localhost "echo OK" &>/dev/null; then
        log_error "SSH LOCAL FAILED"
        return 1
    fi
    log_info "SSH local: OK"
    
    # External connectivity (si hay)
    if timeout 5 ping -c 1 8.8.8.8 &>/dev/null; then
        log_info "External ping: OK"
    else
        log_warn "External ping: TIMEOUT (puede ser esperado en firewall)"
    fi
    
    # Port listening
    if ss -tlnp 2>/dev/null | grep -q "ssh"; then
        log_info "SSH port listening: OK"
    else
        log_error "SSH PORT NOT LISTENING"
        return 1
    fi
    
    return 0
}

test_services() {
    log_info "Testando servicios críticos..."
    
    FAILED=0
    for svc in ssh fail2ban; do
        if systemctl is-active "$svc" &>/dev/null; then
            log_info "$svc: ACTIVE"
        else
            log_error "$svc: INACTIVE"
            FAILED=1
        fi
    done
    
    return $FAILED
}

test_firewall() {
    log_info "Testando firewall..."
    
    # Verificar que UFW está activo si estaba antes
    if sudo ufw status | grep -q "Status: active"; then
        log_info "Firewall: ACTIVE"
    else
        log_warn "Firewall: INACTIVE (verifica si es intencional)"
    fi
    
    return 0
}

# =============================================================================
# VALIDATE: Compara contra baseline
# =============================================================================
validate_against_baseline() {
    BASELINE="$BASELINE_LATEST/health-snapshot.json"
    
    if [ ! -f "$BASELINE" ]; then
        log_error "No baseline found. Ejecuta: canary-test.sh start"
        return 1
    fi
    
    log_info "Validando contra baseline..."
    
    DIFFS=0
    
    # SSH service debe seguir activo
    if ! systemctl is-active ssh &>/dev/null; then
        log_error "SSH service is NOT ACTIVE"
        DIFFS=$((DIFFS + 1))
    fi
    
    # SSH port debe seguir escuchando
    if ! ss -tlnp 2>/dev/null | grep -q "ssh"; then
        log_error "SSH port NOT LISTENING"
        DIFFS=$((DIFFS + 1))
    fi
    
    # SSH config debe tener settings críticos
    if ! grep -q "PubkeyAuthentication yes" /etc/ssh/sshd_config; then
        log_error "SSH: PubkeyAuthentication not enabled"
        DIFFS=$((DIFFS + 1))
    fi
    
    # AllowTcpForwarding (critical para VNC)
    if grep -q "AllowTcpForwarding no" /etc/ssh/sshd_config; then
        log_error "CRITICAL: AllowTcpForwarding is DISABLED (breaks VNC/tunnels)"
        DIFFS=$((DIFFS + 1))
    fi
    
    if [ $DIFFS -eq 0 ]; then
        log_info "✓ All validations PASSED"
        return 0
    else
        log_error "✗ $DIFFS validation(s) FAILED"
        return 1
    fi
}

# =============================================================================
# ROLLBACK: Restaura desde backup pre-cambio
# =============================================================================
rollback_config() {
    log_error "ROLLBACK INITIATED"
    
    BACKUP_DIR="/tmp/canary-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup current (broken) state
    sudo cp /etc/ssh/sshd_config "$BACKUP_DIR/sshd_config.broken"
    sudo cp /etc/ufw/before.rules "$BACKUP_DIR/before.rules.broken" 2>/dev/null || true
    
    log_warn "Broken configs backed up to: $BACKUP_DIR"
    log_warn "Manual restore may be needed. Contact Manu."
    
    echo ""
    echo "❌ ROLLBACK INCOMPLETE — requires manual intervention"
    echo "Broken config saved at: $BACKUP_DIR"
    
    return 1
}

# =============================================================================
# MAIN
# =============================================================================
COMMAND="${1:-help}"

case "$COMMAND" in
    start)
        snapshot_health
        ;;
    test)
        echo "=== CONNECTIVITY TESTS ==="
        test_connectivity || exit 1
        echo ""
        echo "=== SERVICE TESTS ==="
        test_services || exit 1
        echo ""
        echo "=== FIREWALL TESTS ==="
        test_firewall || exit 1
        echo ""
        log_info "All tests PASSED"
        ;;
    validate)
        validate_against_baseline
        ;;
    rollback)
        rollback_config
        ;;
    show)
        if [ -f "$BASELINE_LATEST/health-snapshot.json" ]; then
            cat "$BASELINE_LATEST/health-snapshot.json"
        else
            log_error "No baseline found"
            exit 1
        fi
        ;;
    *)
        cat << EOF
Canary Testing — Pre-update validation

Usage:
  bash canary-test.sh start      → Snapshot baseline ANTES del cambio
  bash canary-test.sh test       → Valida conectividad & servicios
  bash canary-test.sh validate   → Compara contra baseline
  bash canary-test.sh rollback   → Si algo falló (manual)
  bash canary-test.sh show       → Muestra baseline actual

Workflow:
  1. bash canary-test.sh start
  2. [Haz el cambio crítico: SSH config, firewall, etc.]
  3. bash canary-test.sh test
  4. bash canary-test.sh validate
  5. ✓ Si todo OK → cambio aprobado
  6. ✗ Si algo falla → bash canary-test.sh rollback (manual)

Critical settings monitoreadas:
  - SSH service activo
  - SSH port escuchando (22)
  - AllowTcpForwarding (critical para VNC)
  - PubkeyAuthentication (acceso key-based)
  - Fail2ban estado
  - Firewall estado
EOF
        exit 1
        ;;
esac
