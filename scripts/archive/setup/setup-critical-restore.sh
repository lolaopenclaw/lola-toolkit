#!/bin/bash
# setup-critical-restore.sh
# Script MASTER de restauración post-fallo crítico
# Ejecutar como usuario mleon (NO sudo al inicio, pero pedirá sudo cuando necesite)

set -e

WORKSPACE="$HOME/.openclaw/workspace"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}🆘 CRITICAL RESTORE — Setup Completo${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""

# Función para paso con validación
step() {
    echo -e "${YELLOW}→ $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    return 1
}

# PASO 0: Validar que existe restore.sh
if [ ! -f "$WORKSPACE/scripts/restore.sh" ]; then
    error "restore.sh no encontrado. ¿Ejecutaste esto desde directorio correcto?"
    exit 1
fi

# PASO 1: Restaurar workspace desde backup
step "PASO 1: Restaurar workspace desde backup"
if [ -z "$1" ]; then
    error "Uso: bash setup-critical-restore.sh ~/openclaw-backup-YYYY-MM-DD.tar.gz"
    exit 1
fi

BACKUP_FILE="$1"
if [ ! -f "$BACKUP_FILE" ]; then
    error "Backup no encontrado: $BACKUP_FILE"
    exit 1
fi

bash "$WORKSPACE/scripts/restore.sh" "$BACKUP_FILE" > /dev/null 2>&1
success "Workspace restaurado desde $BACKUP_FILE"

# PASO 2: Reinstalar git hooks
step "PASO 2: Reinstalar git hooks (backup post-commit)"
bash "$WORKSPACE/scripts/setup-git-hooks.sh"
success "Git hooks reinstalados"

# PASO 3: Instalar OpenClaw service
step "PASO 3: Instalar OpenClaw gateway service"
if ! openclaw gateway status > /dev/null 2>&1; then
    openclaw gateway install > /dev/null 2>&1 || true
    success "OpenClaw service instalado"
else
    success "OpenClaw service ya estaba instalado"
fi

# PASO 4: Verificar dependencias del sistema
step "PASO 4: Verificar dependencias críticas del sistema"

MISSING_DEPS=""
for dep in python3 git curl; do
    if ! command -v "$dep" &> /dev/null; then
        MISSING_DEPS="$MISSING_DEPS $dep"
    fi
done

if [ -n "$MISSING_DEPS" ]; then
    error "Dependencias faltantes:$MISSING_DEPS"
    echo "Intenta: sudo apt-get install -y$MISSING_DEPS"
else
    success "Todas las dependencias críticas presentes"
fi

# PASO 5: Verificar/instalar global packages
step "PASO 5: Verificar OpenClaw npm package"
if ! npm list -g openclaw > /dev/null 2>&1; then
    echo "  Instalando openclaw globalmente..."
    npm install -g openclaw > /dev/null 2>&1 || true
    success "OpenClaw npm package instalado/actualizado"
else
    success "OpenClaw npm package ya instalado"
fi

# PASO 6: Verificar permisos
step "PASO 6: Verificar permisos de archivos"
echo "  Requiere sudo..."
sudo chown -R mleon:mleon ~/.openclaw > /dev/null 2>&1
sudo chmod 700 ~/.openclaw > /dev/null 2>&1
sudo chmod 600 ~/.openclaw/.env > /dev/null 2>&1
success "Permisos corregidos"

# PASO 7: Restaurar keyring (GOG) si existe
step "PASO 7: Verificar keyring de GOG"
if [ -d "$WORKSPACE/keyrings-backup" ]; then
    mkdir -p ~/.local/share/keyrings
    cp -r "$WORKSPACE/keyrings-backup"/* ~/.local/share/keyrings/ > /dev/null 2>&1
    success "Keyring GOG restaurado"
else
    echo "  (Sin backup de keyring local — GOG necesitará reauth)"
fi

# PASO 8: Reiniciar servicios críticos
step "PASO 8: Reiniciar servicios de usuario"
systemctl --user restart dbus > /dev/null 2>&1 || true
success "Servicios reiniciados"

# PASO 9: Ejecutar verificación
step "PASO 9: Ejecutar verificación de integridad"
if [ -f "$WORKSPACE/scripts/verify.sh" ]; then
    bash "$WORKSPACE/scripts/verify.sh"
    success "Verificación completada"
else
    echo "  (verify.sh no encontrado)"
fi

# PASO 10: Resumen de API keys a reconfigurar
step "PASO 10: VERIFICAR API KEYS (Acción manual posible)"
echo ""
echo "  Las siguientes credenciales pueden necesitar reauth:"
echo "  • ANTHROPIC_API_KEY (en ~/.openclaw/.env)"
echo "  • NOTION_API_KEY (en ~/.openclaw/.env)"
echo "  • GOG_KEYRING_PASSWORD (variable de entorno)"
echo "  • Google Drive OAuth (si se perdió)"
echo ""
echo "  Ver: $WORKSPACE/SETUP-CRITICAL.md para instrucciones"

# PASO 11: Preparar para arrancar
step "PASO 11: Preparar para arrancar OpenClaw"
echo ""
echo "  Una vez verificado todo, arranca:"
echo "  $ openclaw gateway start"
echo "  $ openclaw doctor"
echo ""

echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Setup crítico completado${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
echo "Próximos pasos:"
echo "1. Revisar SETUP-CRITICAL.md para instrucciones de reauth"
echo "2. Ejecutar: openclaw gateway start"
echo "3. Ejecutar: openclaw doctor"
echo "4. Verificar que todo funciona"
echo ""

exit 0
