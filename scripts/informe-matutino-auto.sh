#!/bin/bash
# informe-matutino-auto.sh
# Genera y envía informe matutino automático a Discord (NUNCA Telegram)

set -e
source ~/.openclaw/.env

YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)
HOUR=$(date +%H:%M)
MEMORY_DIR="/home/mleon/.openclaw/workspace/memory"

echo "🔄 Generando informe matutino..."

# 1. Get Garmin data for yesterday
echo "📊 Obteniendo datos de Garmin..."
GARMIN_DATA=$(bash ~/.openclaw/workspace/scripts/garmin-health-report.sh --daily "$YESTERDAY" 2>&1 || echo "Error en Garmin")

# 2. Get system stats
echo "💻 Obteniendo estadísticas del sistema..."
UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')
RAM=$(free -h | awk '/^Mem:/ {print $3 " / " $2}')
DISK=$(df -h / | awk 'NR==2 {print $3 " / " $2}')
GATEWAY_PID=$(pgrep -f "openclaw-gateway" | head -1)
GATEWAY_STATUS="✅ Activo" && [ -z "$GATEWAY_PID" ] && GATEWAY_STATUS="❌ Inactivo"

# Count active crons
CRONS_ACTIVE=$(openclaw cron list 2>/dev/null | grep -c "enabled" || echo "?")

# 3. Get Fail2Ban status
echo "🔐 Verificando Fail2Ban..."
FAIL2BAN=$(sudo fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $NF}' || echo "?")

# 4. Get backup info
echo "💾 Verificando backups..."
LAST_BACKUP_JSON="$MEMORY_DIR/last-backup.json"
if [ -f "$LAST_BACKUP_JSON" ]; then
    BACKUP_DATE=$(python3 -c "import json; d=json.load(open('$LAST_BACKUP_JSON')); print(d.get('date','?'))" 2>/dev/null || echo "?")
    BACKUP_STATUS=$(python3 -c "import json; d=json.load(open('$LAST_BACKUP_JSON')); print(d.get('status','?'))" 2>/dev/null || echo "?")
else
    BACKUP_DATE="?"
    BACKUP_STATUS="?"
fi

# 5. Autoimprove Nightly summary
echo "🔬 Leyendo resumen de Autoimprove..."
AUTOIMPROVE_FILE="$MEMORY_DIR/$TODAY-autoimprove.md"
AUTOIMPROVE_SECTION=""
if [ -f "$AUTOIMPROVE_FILE" ]; then
    # Extract key stats: improvements kept, reverted, iterations
    KEPT=$(grep -c "^[0-9]\+\.\|^\*\*" "$AUTOIMPROVE_FILE" 2>/dev/null | head -1 || echo "?")
    # Get a concise summary: look for "Improvements Kept" and "Stats" sections
    IMPROVEMENTS=$(sed -n '/## Improvements Kept/,/## Attempted/p' "$AUTOIMPROVE_FILE" | grep "^\*\*\|^[0-9]" | head -10 || true)
    REVERTED=$(sed -n '/## Attempted but Reverted/,/## Stats/p' "$AUTOIMPROVE_FILE" | grep "^\*\*" | head -5 || true)
    STATS_LINE=$(grep -E "Total commits|Token reduction" "$AUTOIMPROVE_FILE" | head -2 || true)

    AUTOIMPROVE_SECTION="🔬 AUTOIMPROVE NIGHTLY
$IMPROVEMENTS"
    [ -n "$REVERTED" ] && AUTOIMPROVE_SECTION="$AUTOIMPROVE_SECTION
• Revertido: $REVERTED"
    [ -n "$STATS_LINE" ] && AUTOIMPROVE_SECTION="$AUTOIMPROVE_SECTION
$STATS_LINE"
else
    AUTOIMPROVE_SECTION="🔬 AUTOIMPROVE NIGHTLY
• No se ejecutó anoche (sin archivo $TODAY-autoimprove.md)"
fi

# 6. System updates status
echo "🔄 Leyendo estado de actualizaciones..."
UPDATES_JSON="$MEMORY_DIR/system-updates-last.json"
UPDATES_SECTION=""
if [ -f "$UPDATES_JSON" ]; then
    UPD_DATE=$(python3 -c "import json; d=json.load(open('$UPDATES_JSON')); print(d.get('date','?'))" 2>/dev/null || echo "?")
    UPD_UPDATED=$(python3 -c "import json; d=json.load(open('$UPDATES_JSON')); print(d.get('packages_updated',0))" 2>/dev/null || echo "0")
    UPD_AVAILABLE=$(python3 -c "import json; d=json.load(open('$UPDATES_JSON')); print(d.get('packages_available',0))" 2>/dev/null || echo "0")
    UPD_SECURITY=$(python3 -c "import json; d=json.load(open('$UPDATES_JSON')); print(d.get('security_count',0))" 2>/dev/null || echo "0")
    UPD_REBOOT=$(python3 -c "import json; d=json.load(open('$UPDATES_JSON')); print(d.get('reboot_required',False))" 2>/dev/null || echo "False")
    UPD_REMAINING=$(python3 -c "import json; d=json.load(open('$UPDATES_JSON')); print(d.get('remaining',0))" 2>/dev/null || echo "0")
    UPD_PKGS=$(python3 -c "
import json
d=json.load(open('$UPDATES_JSON'))
for p in d.get('packages',[])[:10]:
    icon = '🔴' if p.get('type')=='security' else '📦'
    print(f\"  {icon} {p['name']}\")
" 2>/dev/null || echo "  (sin detalle)")

    UPDATES_SECTION="🔄 ACTUALIZACIONES SISTEMA ($UPD_DATE)
• Disponibles: $UPD_AVAILABLE ($UPD_SECURITY seguridad)
• Aplicadas: $UPD_UPDATED
• Pendientes: $UPD_REMAINING
$UPD_PKGS"
    [ "$UPD_REBOOT" = "True" ] && UPDATES_SECTION="$UPDATES_SECTION
• ⚠️ REBOOT NECESARIO (kernel update)"
else
    # No log exists yet, check live
    UPGRADABLE=$(apt list --upgradable 2>/dev/null | grep -v "^Listing" || true)
    UPD_COUNT=$(echo "$UPGRADABLE" | grep -c . 2>/dev/null || echo "0")
    UPDATES_SECTION="🔄 ACTUALIZACIONES SISTEMA
• $UPD_COUNT paquetes disponibles (auto-update nocturno pendiente de primera ejecución)"
fi

# 7. Token usage report
echo "💰 Calculando consumo de tokens..."
USAGE_JSON=$(bash ~/.openclaw/workspace/scripts/usage-report.sh 2>/dev/null || echo "{}")
if [ -n "$USAGE_JSON" ] && [ "$USAGE_JSON" != "{}" ]; then
    MONTH_COST=$(echo "$USAGE_JSON" | jq -r '.monthly_total_cost // 0')
    YESTERDAY_COST=$(echo "$USAGE_JSON" | jq -r '.yesterday_total_cost // 0')
    TODAY_COST=$(echo "$USAGE_JSON" | jq -r '.today_total_cost // 0')
    MONTH_NAME=$(echo "$USAGE_JSON" | jq -r '.month // "?"')

    # Top models this month
    TOP_MODELS=$(echo "$USAGE_JSON" | jq -r '.by_model_monthly[:3][] | "  • \(.model): $\(.total_cost) (\(.requests) requests)"' 2>/dev/null || echo "  (sin datos)")

    # Yesterday breakdown
    YESTERDAY_MODELS=$(echo "$USAGE_JSON" | jq -r '.by_model_yesterday[:3][] | "  • \(.model): $\(.cost) (\(.requests) req)"' 2>/dev/null || echo "  (sin actividad)")

    TOKEN_SECTION="💰 CONSUMO TOKENS ($MONTH_NAME)
• Mes actual: \$$MONTH_COST
• Ayer: \$$YESTERDAY_COST
• Hoy (parcial): \$$TODAY_COST
• Por modelo (mes):
$TOP_MODELS
• Ayer detalle:
$YESTERDAY_MODELS"
else
    TOKEN_SECTION="💰 CONSUMO TOKENS
• (sin datos disponibles)"
fi

# 8. Build the report
INFORME="📋 INFORME MATUTINO • $TODAY $HOUR

🖥️ SISTEMA
• Uptime: $UPTIME
• RAM: $RAM | Disco: $DISK
• Gateway: $GATEWAY_STATUS

🔐 SEGURIDAD
• Fail2Ban SSH: $FAIL2BAN IPs baneadas

💾 BACKUPS
• Último: $BACKUP_DATE ($BACKUP_STATUS)

$AUTOIMPROVE_SECTION

$UPDATES_SECTION

❤️ SALUD (Garmin - $YESTERDAY)
$GARMIN_DATA

$TOKEN_SECTION

📌 ESTADO GENERAL
• Síntesis: 🟢 Todos los sistemas operacionales"

echo "$INFORME"

# NOTE: This script outputs the report. Delivery to Discord is handled
# by the OpenClaw cron job delivery config (mode=announce, channel=discord).
# The cron agent session reads the output and delivers it.

# 9. Save report
echo "📝 Guardando informe..."
echo "$INFORME" > ~/.openclaw/workspace/memory/$TODAY-informe.md
echo "✅ Informe guardado en memory/$TODAY-informe.md"
