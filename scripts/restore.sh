#!/bin/bash
set -euo pipefail
# =============================================================================
# restore.sh — Restaurar OpenClaw desde backup
# =============================================================================
# Uso: ./restore.sh <openclaw-backup-YYYY-MM-DD.tar.gz>
# 
# Restaura: workspace, openclaw.json, .env, cron-db, GOG keyring, rclone config
# Es IDEMPOTENTE: se puede ejecutar múltiples veces sin romper nada.
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
fail() { echo -e "  ${RED}❌ $1${NC}"; exit 1; }
info() { echo -e "  ${BLUE}ℹ️  $1${NC}"; }

# --- Validación de argumentos ------------------------------------------------
if [ $# -lt 1 ]; then
    echo "Uso: $0 <openclaw-backup-YYYY-MM-DD.tar.gz>"
    echo ""
    echo "Si no tienes el backup localmente:"
    echo "  1. Descarga de Google Drive (carpeta openclaw_backups)"
    echo "  2. O usa rclone: rclone copy grive_lola:openclaw_backups/ /tmp/ --include '*.tar.gz' --max-age 3d"
    exit 1
fi

BACKUP_FILE="$1"
WORKSPACE="$HOME/.openclaw/workspace"
OPENCLAW_DIR="$HOME/.openclaw"

if [ ! -f "$BACKUP_FILE" ]; then
    fail "No se encuentra el archivo: $BACKUP_FILE"
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  📦 OpenClaw Restore                             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo "Archivo: $BACKUP_FILE"
echo "Tamaño: $(du -h "$BACKUP_FILE" | cut -f1)"
echo "Fecha: $(date -u '+%Y-%m-%d %H:%M UTC')"
echo ""

# --- Validación del tarball --------------------------------------------------
echo -e "${BLUE}━━━ [0/8] Validando integridad del backup${NC}"
if ! tar tzf "$BACKUP_FILE" &>/dev/null; then
    fail "Tarball corrupto o inválido. Verificar con: tar tzf '$BACKUP_FILE'"
fi
ok "Tarball válido"

# --- Extracción --------------------------------------------------------------
echo -e "${BLUE}━━━ [1/8] Extrayendo backup${NC}"
TMPDIR=$(mktemp -d)
tar xzf "$BACKUP_FILE" -C "$TMPDIR"

EXTRACTED=$(find "$TMPDIR" -maxdepth 1 -type d -name 'openclaw-backup-*' | head -1)
if [ -z "$EXTRACTED" ]; then
    rm -rf "$TMPDIR"
    fail "No se encontró carpeta openclaw-backup-* en el tarball"
fi

FILE_COUNT=$(find "$EXTRACTED" -type f | wc -l)
ok "Extraídos $FILE_COUNT archivos"

# --- Backup de seguridad del estado actual -----------------------------------
echo -e "${BLUE}━━━ [2/8] Backup de seguridad del estado actual${NC}"
if [ -d "$WORKSPACE" ] && [ "$(ls -A $WORKSPACE 2>/dev/null)" ]; then
    SAFETY_BACKUP="/tmp/openclaw-pre-restore-$(date +%Y%m%d%H%M%S).tar.gz"
    tar czf "$SAFETY_BACKUP" -C "$HOME" .openclaw/workspace/ 2>/dev/null || true
    ok "Backup de seguridad: $SAFETY_BACKUP"
else
    info "No hay workspace previo, saltando backup de seguridad"
fi

# --- Restaurar openclaw.json ------------------------------------------------
echo -e "${BLUE}━━━ [3/8] Restaurando configuración OpenClaw${NC}"
mkdir -p "$OPENCLAW_DIR"

if [ -f "$EXTRACTED/openclaw.json" ]; then
    cp "$EXTRACTED/openclaw.json" "$OPENCLAW_DIR/openclaw.json"
    ok "openclaw.json restaurado"
    rm "$EXTRACTED/openclaw.json"
else
    warn "No se encontró openclaw.json en backup"
fi

# --- Restaurar .env ----------------------------------------------------------
echo -e "${BLUE}━━━ [4/8] Restaurando secrets (.env)${NC}"

if [ -f "$EXTRACTED/dot-env" ]; then
    cp "$EXTRACTED/dot-env" "$OPENCLAW_DIR/.env"
    chmod 600 "$OPENCLAW_DIR/.env"
    ok ".env restaurado (API keys, credenciales GOG)"
    
    # Actualizar .bashrc con valores del .env
    while IFS='=' read -r key value; do
        [ -z "$key" ] && continue
        [[ "$key" =~ ^# ]] && continue
        case "$key" in
            GOG_KEYRING_PASSWORD|GOG_KEYRING_BACKEND|GOG_ACCOUNT)
                # Actualizar en .bashrc si existe como PLACEHOLDER
                if grep -q "PLACEHOLDER_CHANGE_ME" ~/.bashrc 2>/dev/null; then
                    sed -i "s|export ${key}=.*|export ${key}='${value}'|" ~/.bashrc 2>/dev/null || true
                fi
                ;;
        esac
    done < "$OPENCLAW_DIR/.env"
    ok "Variables de entorno actualizadas en .bashrc"
    rm "$EXTRACTED/dot-env"
else
    warn "No se encontró .env en backup — necesitarás configurar API keys manualmente"
fi

# --- Restaurar cron database -------------------------------------------------
echo -e "${BLUE}━━━ [5/8] Restaurando cron jobs${NC}"

if [ -d "$EXTRACTED/cron-db" ]; then
    mkdir -p "$OPENCLAW_DIR/cron"
    cp -r "$EXTRACTED/cron-db/"* "$OPENCLAW_DIR/cron/" 2>/dev/null || true
    ok "Base de datos de cron jobs restaurada"
    rm -rf "$EXTRACTED/cron-db"
    
    # Mostrar jobs restaurados
    if command -v python3 &>/dev/null && [ -f "$OPENCLAW_DIR/cron/jobs.json" ]; then
        NJOBS=$(python3 -c "import json; d=json.load(open('$OPENCLAW_DIR/cron/jobs.json')); print(len(d.get('jobs',[])))" 2>/dev/null || echo "?")
        info "$NJOBS cron jobs restaurados"
    fi
else
    warn "No se encontró cron-db en backup — recrear cron jobs manualmente"
fi

# --- Restaurar workspace ----------------------------------------------------
echo -e "${BLUE}━━━ [6/8] Restaurando workspace${NC}"
mkdir -p "$WORKSPACE"
mkdir -p "$WORKSPACE/memory"
mkdir -p "$WORKSPACE/scripts"
mkdir -p "$WORKSPACE/skills"

# Limpiar items no-workspace que ya procesamos
rm -f "$EXTRACTED/openclaw.json" 2>/dev/null || true
rm -f "$EXTRACTED/dot-env" 2>/dev/null || true
rm -rf "$EXTRACTED/cron-db" 2>/dev/null || true

# Copiar todo al workspace
cp -r "$EXTRACTED"/* "$WORKSPACE/" 2>/dev/null || true

# Permisos de ejecución en scripts
chmod +x "$WORKSPACE"/scripts/*.sh 2>/dev/null || true

# Contar archivos restaurados
WS_FILES=$(find "$WORKSPACE" -type f | wc -l)
ok "Workspace restaurado ($WS_FILES archivos)"

# Listar archivos principales
echo "  Archivos clave:"
for f in SOUL.md USER.md AGENTS.md IDENTITY.md MEMORY.md RECOVERY.md TOOLS.md HEARTBEAT.md BOOT.md; do
    if [ -f "$WORKSPACE/$f" ]; then
        echo -e "    ${GREEN}✓${NC} $f"
    else
        echo -e "    ${RED}✗${NC} $f (no encontrado)"
    fi
done

# --- Limpieza ----------------------------------------------------------------
echo -e "${BLUE}━━━ [7/8] Limpieza${NC}"
rm -rf "$TMPDIR"
ok "Archivos temporales limpiados"

# --- Resumen y siguientes pasos -----------------------------------------------
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Restauración completada                      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ✅ Workspace: $WS_FILES archivos"
echo -e "  ✅ Config: openclaw.json"
[ -f "$OPENCLAW_DIR/.env" ] && echo -e "  ✅ Secrets: .env (API keys, GOG)"
[ -d "$OPENCLAW_DIR/cron" ] && echo -e "  ✅ Cron jobs: restaurados"
echo ""
echo -e "${YELLOW}📋 PASOS SIGUIENTES:${NC}"
echo ""
echo "  1. Revisar y actualizar API key de Anthropic si es nueva:"
echo "     cat ~/.openclaw/.env"
echo "     # O: openclaw config set auth.profiles.anthropic:default.apiKey <KEY>"
echo ""
echo "  2. Instalar y arrancar el servicio gateway:"
echo "     openclaw gateway install"
echo "     openclaw gateway start"
echo "     openclaw doctor"
echo ""
echo "  3. Habilitar hooks:"
echo "     openclaw hooks enable boot-md"
echo ""
echo "  4. Verificar linger:"
echo "     loginctl show-user \$(whoami) | grep Linger"
echo "     # Si Linger=no: sudo loginctl enable-linger \$(whoami)"
echo ""
echo "  5. Configurar rclone (si no está configurado):"
echo "     rclone config"
echo "     # Remote: grive_lola, Type: drive, Scope: drive"
echo ""
echo "  6. Configurar GOG (si tokens expiraron):"
echo "     gog auth credentials ~/.config/gog/credentials.json"
echo "     gog auth add lolaopenclaw@gmail.com --services gmail,calendar,drive,contacts,docs,sheets"
echo ""
echo "  7. Verificar todo:"
echo "     bash ~/.openclaw/workspace/scripts/verify.sh"
echo ""
echo -e "${BLUE}💡 Leer RECOVERY.md para instrucciones detalladas${NC}"
