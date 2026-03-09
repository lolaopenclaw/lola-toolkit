#!/bin/bash
# =============================================================================
# bootstrap.sh — VPS nueva → OpenClaw operativo desde cero
# =============================================================================
# Uso: curl -sL <URL> | bash   (o descargarlo y ejecutar)
# Prerequisitos: Ubuntu 24.04 fresh, usuario mleon con sudo, SSH keys ya puestas
#
# Este script NO contiene secrets. Los secrets vienen del backup o se piden.
# Es IDEMPOTENTE: se puede ejecutar múltiples veces sin romper nada.
# =============================================================================

set -euo pipefail

# --- Colores y helpers -------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

step() { echo -e "\n${BLUE}━━━ [$1/$TOTAL_STEPS] $2${NC}"; }
ok()   { echo -e "  ${GREEN}✅ $1${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $1${NC}"; }
fail() { echo -e "  ${RED}❌ $1${NC}"; }
skip() { echo -e "  ${YELLOW}⏭️  $1 (ya existe)${NC}"; }

TOTAL_STEPS=13
ERRORS=0

# --- Pre-checks --------------------------------------------------------------
echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🚀 OpenClaw Bootstrap — VPS Nueva              ║${NC}"
echo -e "${BLUE}║  Ubuntu 24.04 → OpenClaw completo               ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo "Fecha: $(date -u '+%Y-%m-%d %H:%M UTC')"
echo "Usuario: $(whoami)"
echo "Sistema: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"
echo ""

if [ "$(whoami)" = "root" ]; then
    fail "No ejecutar como root. Usa tu usuario normal (mleon) con sudo."
    exit 1
fi

# =============================================================================
# PASO 1: Actualización del sistema
# =============================================================================
step 1 "Actualizando sistema operativo"

sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y -qq
ok "Sistema actualizado"

# =============================================================================
# PASO 2: Paquetes esenciales del sistema
# =============================================================================
step 2 "Instalando paquetes del sistema"

SYSTEM_PACKAGES=(
    # Seguridad
    ufw
    fail2ban
    lynis
    rkhunter
    libpam-tmpdir
    unattended-upgrades
    # Utilidades
    curl
    wget
    git
    build-essential
    jq
    htop
    tmux
    trash-cli
    # Para Chrome headless
    fonts-liberation
    libnss3
    libatk-bridge2.0-0
    libdrm2
    libxkbcommon0
    libxcomposite1
    libxdamage1
    libxrandr2
    libgbm1
    libasound2t64
    libpango-1.0-0
    libcairo2
    # Rclone para backups
    rclone
)

# Instalar solo los que faltan
TO_INSTALL=()
for pkg in "${SYSTEM_PACKAGES[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        TO_INSTALL+=("$pkg")
    fi
done

if [ ${#TO_INSTALL[@]} -gt 0 ]; then
    echo "  Instalando: ${TO_INSTALL[*]}"
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${TO_INSTALL[@]}"
    ok "Paquetes instalados (${#TO_INSTALL[@]} nuevos)"
else
    skip "Todos los paquetes ya instalados"
fi

# =============================================================================
# PASO 3: Google Chrome
# =============================================================================
step 3 "Instalando Google Chrome"

if ! command -v google-chrome &>/dev/null; then
    wget -q -O /tmp/google-chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    sudo dpkg -i /tmp/google-chrome.deb 2>/dev/null || sudo apt-get install -f -y -qq
    rm -f /tmp/google-chrome.deb
    ok "Chrome $(google-chrome --version 2>/dev/null | head -1) instalado"
else
    skip "Chrome ya instalado: $(google-chrome --version 2>/dev/null | head -1)"
fi

# Chrome shim para OpenClaw
if [ ! -f /usr/local/bin/chrome-shim ]; then
    sudo tee /usr/local/bin/chrome-shim > /dev/null << 'SHIMEOF'
#!/bin/bash
# chrome-shim: Script v5 (Minimalista - Sin conflictos)
export DBUS_SESSION_BUS_ADDRESS=/dev/null
export XDG_CURRENT_DESKTOP=Generic
export MOZ_HEADLESS=1
REAL_CHROME="/opt/google/chrome/google-chrome"
exec "$REAL_CHROME" \
  --headless=new \
  --no-sandbox \
  --disable-setuid-sandbox \
  --disable-gpu \
  --disable-dev-shm-usage \
  --no-first-run \
  --no-default-browser-check \
  "$@"
SHIMEOF
    sudo chmod +x /usr/local/bin/chrome-shim
    ok "chrome-shim creado en /usr/local/bin/"
else
    skip "chrome-shim ya existe"
fi

# =============================================================================
# PASO 4: Homebrew + herramientas
# =============================================================================
step 4 "Instalando Homebrew y herramientas"

if ! command -v brew &>/dev/null; then
    echo "  Instalando Homebrew (puede tardar unos minutos)..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
    ok "Homebrew instalado"
else
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
    skip "Homebrew ya instalado"
fi

# Añadir brew a .bashrc si no está
if ! grep -q 'linuxbrew.*shellenv' ~/.bashrc 2>/dev/null; then
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"' >> ~/.bashrc
    ok "Brew añadido a .bashrc"
fi

# Paquetes brew esenciales
BREW_PACKAGES=(ripgrep yt-dlp steipete/tap/gogcli)
for pkg in "${BREW_PACKAGES[@]}"; do
    pkg_name=$(basename "$pkg")
    if ! brew list "$pkg_name" &>/dev/null 2>&1; then
        echo "  Instalando brew: $pkg_name..."
        brew install "$pkg" 2>/dev/null || warn "Error instalando $pkg_name (no crítico)"
    else
        skip "brew: $pkg_name"
    fi
done

ok "Herramientas brew configuradas"

# =============================================================================
# PASO 5: Node.js y OpenClaw
# =============================================================================
step 5 "Instalando Node.js y OpenClaw"

# NVM
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    ok "NVM + Node.js instalados"
else
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    skip "NVM ya instalado"
fi

# npm global dir
mkdir -p "$HOME/.npm-global"
npm config set prefix "$HOME/.npm-global" 2>/dev/null || true

# Añadir npm-global a PATH si no está
if ! grep -q 'npm-global/bin' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
fi
export PATH="$HOME/.npm-global/bin:$PATH"

# OpenClaw (última versión estable)
if ! command -v openclaw &>/dev/null; then
    echo "  Instalando OpenClaw (última versión)..."
    npm install -g openclaw
    ok "OpenClaw $(openclaw --version 2>/dev/null || echo '?') instalado"
else
    CURRENT_OC=$(openclaw --version 2>/dev/null || echo "unknown")
    skip "OpenClaw ya instalado: $CURRENT_OC"
fi

# =============================================================================
# PASO 6: Sudoers
# =============================================================================
step 6 "Configurando sudoers"

SUDOERS_FILE="/etc/sudoers.d/mleon"
SUDOERS_CONTENT="mleon ALL=(ALL) NOPASSWD: /usr/bin/apt, $HOME/.npm-global/bin/openclaw"

if [ ! -f "$SUDOERS_FILE" ] || ! sudo grep -q "NOPASSWD" "$SUDOERS_FILE" 2>/dev/null; then
    echo "$SUDOERS_CONTENT" | sudo tee "$SUDOERS_FILE" > /dev/null
    sudo chmod 440 "$SUDOERS_FILE"
    ok "Sudoers configurado"
else
    skip "Sudoers ya configurado"
fi

# =============================================================================
# PASO 7: Hardening de seguridad
# =============================================================================
step 7 "Aplicando hardening de seguridad"

# 7a. SSH hardening
SSHD_CHANGED=false
for setting in "PermitRootLogin no" "PasswordAuthentication no" "AllowTcpForwarding no"; do
    key=$(echo "$setting" | cut -d' ' -f1)
    if ! grep -q "^${key}.*$(echo $setting | cut -d' ' -f2)" /etc/ssh/sshd_config 2>/dev/null; then
        # Remove any existing uncommented line for this key
        sudo sed -i "/^${key} /d" /etc/ssh/sshd_config
        echo "$setting" | sudo tee -a /etc/ssh/sshd_config > /dev/null
        SSHD_CHANGED=true
    fi
done

if [ "$SSHD_CHANGED" = true ]; then
    sudo sshd -t && sudo systemctl reload sshd
    ok "SSH hardening aplicado"
else
    skip "SSH ya hardened"
fi

# 7b. Firewall UFW
if ! sudo ufw status | grep -q "Status: active"; then
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 22/tcp
    sudo ufw --force enable
    ok "Firewall UFW activado"
else
    skip "UFW ya activo"
fi

# 7c. Fail2ban
if [ ! -f /etc/fail2ban/jail.local ]; then
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    sudo systemctl restart fail2ban
    ok "Fail2ban jail.local creado"
else
    skip "Fail2ban jail.local ya existe"
fi

# 7d. Core dumps
if ! grep -q "hard core 0" /etc/security/limits.conf 2>/dev/null; then
    echo "* hard core 0" | sudo tee -a /etc/security/limits.conf > /dev/null
    ok "Core dumps deshabilitados"
else
    skip "Core dumps ya deshabilitados"
fi

# 7e. rkhunter config
if command -v rkhunter &>/dev/null; then
    if grep -q 'WEB_CMD="/bin/false"' /etc/rkhunter.conf 2>/dev/null; then
        sudo sed -i 's|WEB_CMD="/bin/false"|WEB_CMD="/usr/bin/curl"|' /etc/rkhunter.conf
        sudo rkhunter --update 2>/dev/null || true
        sudo rkhunter --propupd 2>/dev/null || true
        ok "rkhunter configurado"
    else
        skip "rkhunter ya configurado"
    fi
fi

# 7f. Unattended upgrades
if ! systemctl is-active unattended-upgrades &>/dev/null; then
    sudo systemctl enable --now unattended-upgrades
    ok "Unattended-upgrades activado"
else
    skip "Unattended-upgrades ya activo"
fi

ok "Hardening completo"

# =============================================================================
# PASO 8: Linger para systemd user services
# =============================================================================
step 8 "Habilitando linger para servicios persistentes"

if ! loginctl show-user "$(whoami)" 2>/dev/null | grep -q "Linger=yes"; then
    sudo loginctl enable-linger "$(whoami)"
    ok "Linger habilitado"
else
    skip "Linger ya habilitado"
fi

# =============================================================================
# PASO 9: Estructura de directorios
# =============================================================================
step 9 "Creando estructura de directorios"

mkdir -p "$HOME/.openclaw/workspace/memory"
mkdir -p "$HOME/.openclaw/workspace/scripts"
mkdir -p "$HOME/.openclaw/workspace/skills"
mkdir -p "$HOME/.openclaw/logs"
mkdir -p "$HOME/.config/rclone"
mkdir -p "$HOME/.config/systemd/user"

ok "Directorios creados"

# =============================================================================
# PASO 10: Auto-restore desde backup (si disponible)
# =============================================================================
step 10 "Buscando backup para restaurar"

BACKUP_FOUND=false
RESTORE_FILE=""

# Opción 1: Backup pasado como argumento
if [ -n "${1:-}" ] && [ -f "${1:-}" ]; then
    RESTORE_FILE="$1"
    BACKUP_FOUND=true
    ok "Backup proporcionado como argumento: $RESTORE_FILE"
fi

# Opción 2: Buscar en /tmp o $HOME
if [ "$BACKUP_FOUND" = false ]; then
    RESTORE_FILE=$(ls -t /tmp/openclaw-backup-*.tar.gz $HOME/openclaw-backup-*.tar.gz 2>/dev/null | head -1)
    if [ -n "$RESTORE_FILE" ]; then
        BACKUP_FOUND=true
        ok "Backup encontrado localmente: $RESTORE_FILE"
    fi
fi

# Opción 3: Intentar descargar de Drive (si rclone configurado)
if [ "$BACKUP_FOUND" = false ] && command -v rclone &>/dev/null; then
    if rclone lsd grive_lola: &>/dev/null 2>&1; then
        echo "  Descargando último backup de Google Drive..."
        mkdir -p /tmp/openclaw-restore
        rclone copy "grive_lola:openclaw_backups/" /tmp/openclaw-restore/ \
            --include "openclaw-backup-*.tar.gz" \
            --max-age 7d \
            --max-depth 1 \
            2>/dev/null || true
        RESTORE_FILE=$(ls -t /tmp/openclaw-restore/openclaw-backup-*.tar.gz 2>/dev/null | head -1)
        if [ -n "$RESTORE_FILE" ]; then
            BACKUP_FOUND=true
            ok "Backup descargado de Drive: $(basename $RESTORE_FILE)"
        else
            warn "No se encontró backup reciente en Drive"
        fi
    else
        warn "rclone no configurado — no se puede descargar de Drive automáticamente"
        echo "  Configura rclone luego: rclone config → grive_lola (Google Drive)"
    fi
fi

# Ejecutar restore si hay backup
if [ "$BACKUP_FOUND" = true ] && [ -f "$RESTORE_FILE" ]; then
    RESTORE_SCRIPT="$HOME/.openclaw/workspace/scripts/restore.sh"
    if [ -f "$RESTORE_SCRIPT" ]; then
        echo "  Ejecutando restore.sh..."
        bash "$RESTORE_SCRIPT" "$RESTORE_FILE" || warn "Restore tuvo errores (puede requerir config manual)"
        ok "Restore ejecutado"
    else
        # Extraer restore.sh del backup
        echo "  Extrayendo restore.sh del backup..."
        tar xzf "$RESTORE_FILE" --wildcards "*/restore.sh" -C /tmp/ 2>/dev/null || true
        EXTRACTED_RESTORE=$(find /tmp -name "restore.sh" -newer "$RESTORE_FILE" 2>/dev/null | head -1)
        if [ -n "$EXTRACTED_RESTORE" ]; then
            bash "$EXTRACTED_RESTORE" "$RESTORE_FILE" || warn "Restore tuvo errores"
            ok "Restore ejecutado desde backup"
        else
            warn "No se encontró restore.sh — restaurar manualmente después"
        fi
    fi
else
    warn "Sin backup disponible — configuración manual necesaria"
    echo "  Descarga backup de Drive manualmente o pásalo como argumento:"
    echo "  bash bootstrap.sh /path/to/openclaw-backup-YYYY-MM-DD.tar.gz"
fi

# =============================================================================
# PASO 11: Variables de entorno en .bashrc
# =============================================================================
step 11 "Configurando variables de entorno"

# GOG env vars (placeholders - el restore.sh pondrá los valores reales)
if ! grep -q 'GOG_KEYRING_BACKEND' ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << 'ENVEOF'
export GOG_KEYRING_BACKEND=file
export GOG_KEYRING_PASSWORD='PLACEHOLDER_CHANGE_ME'
export GOG_ACCOUNT=lolaopenclaw@gmail.com
ENVEOF
    warn "Variables GOG añadidas con PLACEHOLDER — se actualizarán con restore.sh"
else
    skip "Variables GOG ya en .bashrc"
fi

ok "Entorno configurado"

# =============================================================================
# PASO 12: Crontab del sistema (rclone sync)
# =============================================================================
step 12 "Configurando crontab del sistema"

CRON_LINE='0 3 * * * /usr/bin/rclone sync /home/mleon/.openclaw/workspace/ grive_lola:openclaw_backups --create-empty-src-dirs >> /home/mleon/.openclaw/logs/rclone_backup.log 2>&1'
if ! crontab -l 2>/dev/null | grep -q "rclone sync"; then
    (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
    ok "Crontab rclone sync configurado"
else
    skip "Crontab rclone ya existe"
fi

# =============================================================================
# PASO 13: Resumen y siguientes pasos
# =============================================================================
step 13 "Resumen"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Bootstrap completado                         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Errores: ${ERRORS}"
echo ""
echo -e "${YELLOW}📋 PASOS MANUALES PENDIENTES:${NC}"
echo ""
echo "  1. 🔑 API KEY de Anthropic:"
echo "     openclaw onboard"
echo "     (seguir wizard interactivo, pegar API key)"
echo ""
echo "  2. 📦 RESTAURAR BACKUP (si hay backup disponible):"
echo "     # Opción A: Descargar desde Drive manualmente"
echo "     # Opción B: Si rclone ya está configurado:"
echo "     rclone copy grive_lola:openclaw_backups/ /tmp/backups/ --include '*.tar.gz' --max-age 7d"
echo "     # Luego:"
echo "     bash ~/.openclaw/workspace/scripts/restore.sh /tmp/backups/openclaw-backup-YYYY-MM-DD.tar.gz"
echo ""
echo "  3. 🔐 RCLONE (para backups a Google Drive):"
echo "     rclone config"
echo "     # Crear remote 'grive_lola' tipo 'drive'"
echo "     # Requiere OAuth flow (navegador)"
echo ""
echo "  4. 📧 GOG (Gmail/Drive CLI):"
echo "     gog auth credentials ~/.config/gog/credentials.json"
echo "     gog auth add lolaopenclaw@gmail.com --services gmail,calendar,drive,contacts,docs,sheets"
echo "     # Requiere OAuth flow"
echo ""
echo "  5. 🚀 ARRANCAR OPENCLAW:"
echo "     openclaw gateway install"
echo "     openclaw gateway start"
echo "     openclaw hooks enable boot-md"
echo "     openclaw doctor"
echo ""
echo "  6. 📋 RECREAR CRON JOBS:"
echo "     # Pedirle a Lola que recree desde cron-jobs.json"
echo "     # O copiar manualmente desde backup/.openclaw/cron/"
echo ""
echo -e "${BLUE}💡 Para restore completo, usa: scripts/restore.sh <backup.tar.gz>${NC}"
echo -e "${BLUE}   Luego: scripts/hardening.sh (ya ejecutado por bootstrap)${NC}"
echo ""
