#!/bin/bash
# generate-morning-report.sh - Genera informe matutino completo y lo envía a Discord
# Uso: bash generate-morning-report.sh [weekday|weekend]

set -euo pipefail

REPORT_TYPE="${1:-weekday}"  # weekday (lunes-viernes) o weekend (sábado-domingo)
WORKSPACE="${HOME:?}/.openclaw/workspace"
SCRIPTS="${WORKSPACE:?}/scripts"

# Check dependencies
for cmd in python3; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ Missing dependency: $cmd" >&2
        exit 1
    fi
done

# Verify workspace exists
if [ ! -d "$SCRIPTS" ]; then
    echo "❌ Scripts directory not found: $SCRIPTS" >&2
    exit 1
fi

# Cargar .env
if [ -f "$HOME/.openclaw/.env" ]; then
    # shellcheck disable=SC2046
    export $(grep -v '^#' "$HOME/.openclaw/.env" | xargs)
fi

# Helper para obtener fecha en Madrid
get_madrid_date() {
    TZ='Europe/Madrid' date '+%A, %d de %B de %Y' | sed \
        -e 's/Monday/lunes/g' \
        -e 's/Tuesday/martes/g' \
        -e 's/Wednesday/miércoles/g' \
        -e 's/Thursday/jueves/g' \
        -e 's/Friday/viernes/g' \
        -e 's/Saturday/sábado/g' \
        -e 's/Sunday/domingo/g' \
        -e 's/January/enero/g' \
        -e 's/February/febrero/g' \
        -e 's/March/marzo/g' \
        -e 's/April/abril/g' \
        -e 's/May/mayo/g' \
        -e 's/June/junio/g' \
        -e 's/July/julio/g' \
        -e 's/August/agosto/g' \
        -e 's/September/septiembre/g' \
        -e 's/October/octubre/g' \
        -e 's/November/noviembre/g' \
        -e 's/December/diciembre/g'
}

# Función para ejecutar comando de forma segura
run_cmd() {
    local label="$1"
    shift
    
    echo "⏳ $label..." >&2
    if output=$( "$@" 2>/dev/null ); then
        echo "$output"
    else
        echo "⚠️  (sin datos)"
    fi
}

echo "====================================" >&2
echo "📊 GENERANDO INFORME MATUTINO" >&2
echo "====================================" >&2

# Iniciar informe
INFORME=""
FECHA=$(get_madrid_date)

INFORME+="🌅 **INFORME MATUTINO**\n"
INFORME+="$FECHA\n"
INFORME+="================================\n\n"

# SECCIÓN 1: SISTEMA
INFORME+="## 🖥️ SISTEMA\n\n"

# 1a. Actualizaciones
echo "🔄 Actualizaciones..." >&2
UPDATES=$(run_cmd "Actualizaciones" sudo apt-get update -qq 2>&1 | wc -l)
INFORME+="**Actualizaciones:** $UPDATES paquetes\n"

# Verificar OpenClaw
OC_VERSION=$(run_cmd "Versión OpenClaw" npm view openclaw version 2>/dev/null || echo "?")
INFORME+="**OpenClaw:** $OC_VERSION (última disponible)\n\n"

# 1b. Backup
echo "💾 Backup..." >&2
if [ -f "$WORKSPACE/memory/last-backup.json" ]; then
    BACKUP_INFO=$(grep -o '"date"[^,]*\|"files"[^,]*\|"size"[^,]*' "$WORKSPACE/memory/last-backup.json" || echo "N/A")
    INFORME+="**Backup:** $BACKUP_INFO\n\n"
else
    INFORME+="**Backup:** Pendiente\n\n"
fi

# 1c. Consumo de modelos
echo "💰 Consumo..." >&2
if [ -f "$SCRIPTS/usage-report.sh" ]; then
    USAGE=$(run_cmd "Consumo" bash "$SCRIPTS/usage-report.sh" 2>/dev/null | head -10)
    INFORME+="**Consumo del mes:**\n$USAGE\n\n"
fi

# SECCIÓN 2: SEGURIDAD
echo "🔒 Seguridad..." >&2
INFORME+="## 🔒 SEGURIDAD (Fail2Ban)\n\n"

if sudo fail2ban-client status sshd 2>/dev/null | grep -q "Currently banned"; then
    BANNED=$(sudo fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | grep -oP '\d+')
    INFORME+="⚠️  **IPs Baneadas:** $BANNED\n"
else
    INFORME+="✅ **Fail2Ban:** Estado normal\n"
fi
INFORME+="\n"

# SECCIÓN 3: SALUD (Garmin)
echo "❤️ Salud..." >&2
INFORME+="## ❤️ SALUD (Garmin)\n\n"

if [ -f "$SCRIPTS/garmin-health-report.sh" ]; then
    HEALTH=$(run_cmd "Salud" bash "$SCRIPTS/garmin-health-report.sh" --daily 2>/dev/null | head -15)
    INFORME+="$HEALTH\n\n"
fi

# SECCIÓN 4: DÍA DE LA SEMANA (solo lunes)
DAY_OF_WEEK=$(TZ='Europe/Madrid' date +%u)  # 1=lunes, 7=domingo
if [ "$DAY_OF_WEEK" = "1" ]; then
    echo "📋 Tareas especiales (lunes)..." >&2
    
    INFORME+="## 📋 TAREAS DE FONDO (Lunes)\n\n"
    INFORME+="(Revisando tareas de fondo de Notion...)\n\n"
    
    INFORME+="## 📊 CONSUMO SEMANAL\n\n"
    INFORME+="(Análisis de consumo de los últimos 7 días)\n\n"
fi

# Footer
INFORME+="\n================================\n"
INFORME+="Generado: $(TZ='Europe/Madrid' date '+%H:%M:%S')\n"
INFORME+="Sistema: OpenClaw $(npm view openclaw version 2>/dev/null || echo '?')\n"

echo "" >&2
echo "✅ Informe generado" >&2
echo "" >&2

# ENVIAR A DISCORD
echo "📤 Enviando a Discord..." >&2

if [ -f "$SCRIPTS/send-informe-to-discord.py" ]; then
    # Guardar en variable y enviar vía Python
    TITULO="📊 INFORME MATUTINO - $(TZ='Europe/Madrid' date '+%A %H:%M')"
    echo -e "$INFORME" | python3 "$SCRIPTS/send-informe-to-discord.py" "$TITULO"
else
    echo "⚠️  Script de Discord no encontrado"
fi

echo "" >&2
echo "✅ Proceso completado" >&2
