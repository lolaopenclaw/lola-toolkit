#!/bin/bash
# =============================================================================
# verify.sh — Verificación post-recovery completa
# =============================================================================
# Ejecutar después de bootstrap.sh + restore.sh para confirmar que todo funciona.
# No modifica nada, solo comprueba y reporta.
# =============================================================================

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check_pass() { echo -e "  ${GREEN}✅ $1${NC}"; ((PASS++)); }
check_fail() { echo -e "  ${RED}❌ $1${NC}"; ((FAIL++)); }
check_warn() { echo -e "  ${YELLOW}⚠️  $1${NC}"; ((WARN++)); }

# DRY helpers
check_cmd()    { command -v "$1" &>/dev/null && check_pass "$2 instalado" || check_fail "$2 NO instalado"; }
check_file()   { [ -f "$1" ] && check_pass "$2 existe" || check_fail "$2 NO existe"; }
check_dir()    { [ -d "$1" ] && check_pass "$2 existe" || check_fail "$2 NO existe"; }
check_service() { systemctl is-active "$1" &>/dev/null && check_pass "$2 activo" || check_fail "$2 NO activo"; }

echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🔍 Verificación Post-Recovery                   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo "Fecha: $(date -u '+%Y-%m-%d %H:%M UTC')"
echo ""

# =============================================================================
echo -e "${BLUE}━━━ Sistema${NC}"
# =============================================================================

# OS
if [ -f /etc/os-release ] && grep -q "24.04" /etc/os-release; then
    check_pass "Ubuntu 24.04 ($(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2))"
else
    check_warn "Ubuntu version inesperada ($(lsb_release -ds 2>/dev/null || echo 'unknown'))"
fi

# User
[ "$(whoami)" = "mleon" ] && check_pass "Usuario: mleon" || check_warn "Usuario: $(whoami) (esperado: mleon)"

# Sudo
sudo -n true 2>/dev/null && check_pass "Sudo sin contraseña (para apt)" || check_fail "Sudo no configurado"

# Linger
loginctl show-user "$(whoami)" 2>/dev/null | grep -q "Linger=yes" && check_pass "Linger habilitado" || check_fail "Linger NO habilitado (sudo loginctl enable-linger $(whoami))"

# =============================================================================
echo -e "${BLUE}━━━ Seguridad${NC}"
# =============================================================================

# SSH
grep -q "^PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null && check_pass "SSH: PermitRootLogin no" || check_fail "SSH: PermitRootLogin no falta"
grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config 2>/dev/null && check_pass "SSH: PasswordAuth no" || check_fail "SSH: PasswordAuth no falta"
grep -q "^AllowTcpForwarding no" /etc/ssh/sshd_config 2>/dev/null && check_pass "SSH: TcpForwarding no" || check_warn "SSH: AllowTcpForwarding no falta"

# UFW
sudo ufw status 2>/dev/null | grep -q "Status: active" && check_pass "Firewall UFW activo" || check_fail "Firewall UFW NO activo"

# Fail2ban
systemctl is-active fail2ban &>/dev/null && check_pass "Fail2ban activo" || check_fail "Fail2ban NO activo"
[ -f /etc/fail2ban/jail.local ] && check_pass "Fail2ban: jail.local existe" || check_warn "Fail2ban: falta jail.local"

# Core dumps
grep -q "hard core 0" /etc/security/limits.conf 2>/dev/null && check_pass "Core dumps deshabilitados" || check_warn "Core dumps no deshabilitados"

# libpam-tmpdir
dpkg -s libpam-tmpdir &>/dev/null && check_pass "libpam-tmpdir instalado" || check_warn "libpam-tmpdir no instalado"

# rkhunter
command -v rkhunter &>/dev/null && check_pass "rkhunter instalado" || check_warn "rkhunter no instalado"

# Lynis
[ -x /usr/bin/lynis ] || [ -x /usr/sbin/lynis ] || command -v lynis &>/dev/null && check_pass "Lynis instalado" || check_warn "Lynis no instalado"

# Unattended upgrades
systemctl is-active unattended-upgrades &>/dev/null && check_pass "Unattended-upgrades activo" || check_warn "Unattended-upgrades no activo"

# =============================================================================
echo -e "${BLUE}━━━ Software${NC}"
# =============================================================================

# Versioned software
command -v node &>/dev/null && check_pass "Node.js: $(node --version)" || check_fail "Node.js NO instalado"
command -v npm &>/dev/null && check_pass "npm: $(npm --version)" || check_fail "npm NO instalado"
if command -v openclaw &>/dev/null; then
    check_pass "OpenClaw: $(openclaw --version 2>/dev/null || echo 'ok')"
else
    check_fail "OpenClaw NO instalado"
fi
command -v google-chrome &>/dev/null && check_pass "Chrome: $(google-chrome --version 2>/dev/null | head -1)" || check_fail "Chrome NO instalado"

# Critical tools
[ -x /usr/local/bin/chrome-shim ] && check_pass "chrome-shim" || check_fail "chrome-shim NO encontrado"

# Optional tools
check_cmd brew "Homebrew"
check_cmd gog "GOG CLI"
check_cmd rclone "rclone"
check_cmd rg "ripgrep"
check_cmd yt-dlp "yt-dlp"

# =============================================================================
echo -e "${BLUE}━━━ OpenClaw Config${NC}"
# =============================================================================

# openclaw.json
[ -f "$HOME/.openclaw/openclaw.json" ] && check_pass "openclaw.json existe" || check_fail "openclaw.json NO existe"

# .env
if [ -f "$HOME/.openclaw/.env" ]; then
    check_pass ".env existe"
    grep -q "GOG_KEYRING_PASSWORD" "$HOME/.openclaw/.env" && check_pass ".env: GOG credentials presentes" || check_warn ".env: GOG credentials faltan"
    grep -q "ELEVENLABS" "$HOME/.openclaw/.env" && check_pass ".env: ElevenLabs key presente" || check_warn ".env: ElevenLabs key falta"
else
    check_fail ".env NO existe"
fi

# Gateway service
if systemctl --user is-active openclaw-gateway &>/dev/null; then
    check_pass "Gateway: activo (running)"
else
    systemctl --user is-enabled openclaw-gateway &>/dev/null 2>&1 && check_warn "Gateway: habilitado pero no activo" || check_fail "Gateway: NO instalado/habilitado"
fi

# Hooks
if openclaw hooks list 2>/dev/null | grep -q "boot-md"; then
    check_pass "Hook boot-md: configurado"
else
    check_warn "Hook boot-md: no configurado"
fi

# =============================================================================
echo -e "${BLUE}━━━ Workspace${NC}"
# =============================================================================

WS="$HOME/.openclaw/workspace"
for f in SOUL.md USER.md AGENTS.md IDENTITY.md MEMORY.md RECOVERY.md TOOLS.md HEARTBEAT.md BOOT.md; do
    check_file "$WS/$f" "Workspace: $f"
done
for d in memory scripts skills; do
    check_dir "$WS/$d" "Workspace: $d/"
done

# =============================================================================
echo -e "${BLUE}━━━ Cron Jobs${NC}"
# =============================================================================

# OpenClaw crons
if [ -f "$HOME/.openclaw/cron/jobs.json" ]; then
    NJOBS=$(python3 -c "import json; d=json.load(open('$HOME/.openclaw/cron/jobs.json')); print(len(d.get('jobs',[])))" 2>/dev/null || echo "0")
    [ "$NJOBS" -ge 5 ] && check_pass "OpenClaw cron jobs: $NJOBS" || check_warn "OpenClaw cron jobs: $NJOBS (esperados ≥5)"
else
    check_fail "OpenClaw cron jobs: NO existe jobs.json"
fi

# System crontab (rclone)
crontab -l 2>/dev/null | grep -q "rclone" && check_pass "Crontab: rclone sync configurado" || check_warn "Crontab: rclone sync no encontrado"

# =============================================================================
echo -e "${BLUE}━━━ Conectividad externa${NC}"
# =============================================================================

# rclone remote
if command -v rclone &>/dev/null; then
    rclone listremotes 2>/dev/null | grep -q "grive_lola" && check_pass "Rclone: remote grive_lola configurado" || check_warn "Rclone: remote grive_lola no configurado"
fi

# GOG auth
if command -v gog &>/dev/null; then
    gog auth list 2>/dev/null | grep -q "lolaopenclaw" && check_pass "GOG: autenticado como lolaopenclaw@gmail.com" || check_warn "GOG: no autenticado (requiere OAuth flow)"
fi

# =============================================================================
# Resumen
# =============================================================================
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
TOTAL=$((PASS+FAIL+WARN))
if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}║  ✅ Verificación completada                      ║${NC}"
else
    echo -e "${YELLOW}║  ⚠️  Verificación con problemas                   ║${NC}"
fi
echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${GREEN}Pasaron:${NC} $PASS"
echo -e "  ${RED}Fallaron:${NC} $FAIL"
echo -e "  ${YELLOW}Warnings:${NC} $WARN"
echo -e "  Total: $TOTAL checks"
echo ""

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}⚠️  Hay $FAIL checks que fallaron. Revisa los errores arriba.${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Sistema listo para operar${NC}"
    exit 0
fi
