#!/bin/bash
# =============================================================================
# hardening.sh — Aplicar todas las mejoras de seguridad
# =============================================================================
# Este script aplica TODOS los hardenings documentados en:
# - memory/2026-02-20-hardening-applied.md
# - memory/2026-02-20-hardening-phase2.md
# - memory/2026-02-20-security-audit.md
#
# Es IDEMPOTENTE: detecta qué ya está aplicado y solo aplica lo pendiente.
# =============================================================================

set -euo pipefail

# --- Colores y helpers -------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✅ $1${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $1${NC}"; }
skip() { echo -e "  ${YELLOW}⏭️  $1 (ya aplicado)${NC}"; }

CHANGES=0
TOTAL=7

echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🛡️  Hardening de Seguridad VPS                  ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# =============================================================================
# 1. SSH Hardening
# =============================================================================
echo -e "${BLUE}━━━ [1/$TOTAL] SSH Hardening${NC}"

SSHD_CHANGED=false
declare -A SSH_SETTINGS=(
    ["PermitRootLogin"]="no"
    ["PasswordAuthentication"]="no"
    ["AllowTcpForwarding"]="no"
    ["KbdInteractiveAuthentication"]="yes"
)

for key in "${!SSH_SETTINGS[@]}"; do
    val="${SSH_SETTINGS[$key]}"
    current=$(grep "^${key}" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | tail -1)
    if [ "$current" != "$val" ]; then
        sudo sed -i "/^${key} /d" /etc/ssh/sshd_config
        sudo sed -i "/^#${key} /d" /etc/ssh/sshd_config
        echo "${key} ${val}" | sudo tee -a /etc/ssh/sshd_config > /dev/null
        SSHD_CHANGED=true
        ok "SSH: ${key} ${val}"
        ((CHANGES++))
    else
        skip "SSH: ${key} ${val}"
    fi
done

if [ "$SSHD_CHANGED" = true ]; then
    if sudo sshd -t; then
        sudo systemctl reload sshd
        ok "SSHD recargado"
    else
        warn "Error en config SSHD — NO recargado (revisar manualmente)"
    fi
fi

# =============================================================================
# 2. Firewall UFW
# =============================================================================
echo -e "${BLUE}━━━ [2/$TOTAL] Firewall UFW${NC}"

if ! sudo ufw status | grep -q "Status: active"; then
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 22/tcp
    sudo ufw --force enable
    ok "UFW activado (deny incoming, allow outgoing, SSH permitido)"
    ((CHANGES++))
else
    skip "UFW ya activo"
fi

# =============================================================================
# 3. Fail2ban
# =============================================================================
echo -e "${BLUE}━━━ [3/$TOTAL] Fail2ban${NC}"

if ! command -v fail2ban-client &>/dev/null; then
    sudo apt-get install -y -qq fail2ban
    ok "Fail2ban instalado"
    ((CHANGES++))
fi

if [ ! -f /etc/fail2ban/jail.local ]; then
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    sudo systemctl restart fail2ban
    ok "jail.local creado (config persistente)"
    ((CHANGES++))
else
    skip "jail.local ya existe"
fi

if ! sudo systemctl is-active fail2ban &>/dev/null; then
    sudo systemctl enable --now fail2ban
    ok "Fail2ban activado"
else
    skip "Fail2ban ya activo"
fi

# =============================================================================
# 4. Core dumps deshabilitados
# =============================================================================
echo -e "${BLUE}━━━ [4/$TOTAL] Core dumps${NC}"

if ! grep -q "hard core 0" /etc/security/limits.conf 2>/dev/null; then
    echo "* hard core 0" | sudo tee -a /etc/security/limits.conf > /dev/null
    ok "Core dumps deshabilitados"
    ((CHANGES++))
else
    skip "Core dumps ya deshabilitados"
fi

# =============================================================================
# 5. libpam-tmpdir
# =============================================================================
echo -e "${BLUE}━━━ [5/$TOTAL] libpam-tmpdir (aislamiento /tmp)${NC}"

if ! dpkg -s libpam-tmpdir &>/dev/null 2>&1; then
    sudo apt-get install -y -qq libpam-tmpdir
    ok "libpam-tmpdir instalado"
    ((CHANGES++))
else
    skip "libpam-tmpdir ya instalado"
fi

# =============================================================================
# 6. rkhunter (malware scanner)
# =============================================================================
echo -e "${BLUE}━━━ [6/$TOTAL] rkhunter${NC}"

if ! command -v rkhunter &>/dev/null; then
    sudo apt-get install -y -qq rkhunter
    ok "rkhunter instalado"
    ((CHANGES++))
fi

if grep -q 'WEB_CMD="/bin/false"' /etc/rkhunter.conf 2>/dev/null; then
    sudo sed -i 's|WEB_CMD="/bin/false"|WEB_CMD="/usr/bin/curl"|' /etc/rkhunter.conf
    sudo rkhunter --update 2>/dev/null || true
    sudo rkhunter --propupd 2>/dev/null || true
    ok "rkhunter configurado y actualizado"
    ((CHANGES++))
else
    skip "rkhunter ya configurado"
fi

# =============================================================================
# 7. Lynis (security auditing)
# =============================================================================
echo -e "${BLUE}━━━ [7/$TOTAL] Lynis${NC}"

if ! command -v lynis &>/dev/null; then
    sudo apt-get install -y -qq lynis
    ok "Lynis instalado"
    ((CHANGES++))
else
    skip "Lynis ya instalado"
fi

# =============================================================================
# 8. Unattended upgrades
# =============================================================================
echo -e "${BLUE}━━━ [Bonus] Unattended upgrades${NC}"

if ! systemctl is-active unattended-upgrades &>/dev/null; then
    sudo apt-get install -y -qq unattended-upgrades
    sudo systemctl enable --now unattended-upgrades
    ok "Unattended-upgrades activado"
    ((CHANGES++))
else
    skip "Unattended-upgrades ya activo"
fi

# =============================================================================
# Resumen
# =============================================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  🛡️  Hardening completado                        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Cambios aplicados: $CHANGES"
echo ""

# Verificación rápida
echo -e "${BLUE}━━━ Verificación rápida${NC}"
echo -n "  SSH PermitRootLogin: "; grep "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}'
echo -n "  SSH PasswordAuth: "; grep "^PasswordAuthentication" /etc/ssh/sshd_config | awk '{print $2}'
echo -n "  SSH TcpForwarding: "; grep "^AllowTcpForwarding" /etc/ssh/sshd_config | awk '{print $2}'
echo -n "  UFW: "; sudo ufw status | head -1
echo -n "  Fail2ban: "; systemctl is-active fail2ban
echo -n "  Core dumps: "; ulimit -c
echo -n "  libpam-tmpdir: "; dpkg -s libpam-tmpdir 2>/dev/null | grep Status || echo "no instalado"
echo -n "  rkhunter: "; rkhunter --version 2>/dev/null | head -1 || echo "no instalado"
echo -n "  Lynis: "; lynis --version 2>/dev/null || echo "no instalado"
echo -n "  Unattended: "; systemctl is-active unattended-upgrades
echo ""
echo -e "${BLUE}💡 Para scan completo: sudo lynis audit system --quick${NC}"
