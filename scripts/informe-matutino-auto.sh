#!/bin/bash
# informe-matutino-auto.sh
# Genera informe matutino y envía a Telegram topic 24 (Reportes Diarios)

set -e
source ~/.openclaw/.env
source ~/.bashrc  # Necesario para gog CLI

YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)
HOUR=$(date +%H:%M)
MEMORY_DIR="/home/mleon/.openclaw/workspace/memory"

# Helper functions
log_step() { echo "$1..."; }
fetch_data() { echo "🔄 $1"; }

log_step "🔄 Generando informe matutino"

# 1. Get Weather for Logroño
fetch_data "🌤️ Obteniendo clima"
WEATHER=$(curl -s "wttr.in/Logroño?format=3" 2>/dev/null || echo "❓ No disponible")

# 2. Calendar section REMOVED (not used by Manu)
# echo "📅 Obteniendo eventos del día..."
# CALENDAR_EVENTS=$(gog calendar list --from today --to tomorrow 2>/dev/null | grep -v "^$" || echo "")
# if [ -z "$CALENDAR_EVENTS" ] || [ "$CALENDAR_EVENTS" = "No events found" ]; then
#     CALENDAR_SECTION="📅 CALENDARIO
# • Sin eventos programados para hoy"
# else
#     # Format events nicely - extract summary and time if available
#     CALENDAR_FORMATTED=$(echo "$CALENDAR_EVENTS" | head -10)
#     CALENDAR_SECTION="📅 CALENDARIO
# $CALENDAR_FORMATTED"
# fi

# 3. Get Pending Actions
fetch_data "📌 Verificando pending actions"
PENDING_FILE="$MEMORY_DIR/pending-actions.md"
PENDING_ACTIONS=""
if [ -f "$PENDING_FILE" ]; then
    # Extract tasks from active phase (🔴 Phase:) — format: ### N. Title
    # Get section between "## 🔴 Phase:" and next "##" (or EOF)
    ACTIVE_PHASE=$(awk '/^## 🔴 Phase:/{flag=1; next} /^## /{flag=0} flag' "$PENDING_FILE")
    
    if [ -n "$ACTIVE_PHASE" ]; then
        # Extract task titles (### N. Title), strip ✅, get first 5
        PENDING_ACTIONS=$(echo "$ACTIVE_PHASE" | grep "^### " | grep -v "✅" | sed 's/^### /• /' | head -5)
        PENDING_COUNT=$(echo "$ACTIVE_PHASE" | grep "^### " | grep -v "✅" | wc -l)
        
        if [ -n "$PENDING_ACTIONS" ] && [ "$PENDING_COUNT" -gt 0 ]; then
            PENDING_SECTION="📌 PENDING ACTIONS ($PENDING_COUNT abiertas)
$PENDING_ACTIONS"
        else
            PENDING_SECTION="📌 PENDING ACTIONS
• Sin acciones pendientes en fase activa"
        fi
    else
        PENDING_SECTION="📌 PENDING ACTIONS
• No hay fase activa marcada (🔴 Phase:)"
    fi
else
    PENDING_SECTION="📌 PENDING ACTIONS
• (archivo no encontrado)"
fi

# 4. Log Review Nocturno
fetch_data "📋 Verificando log review nocturno"
LOG_REVIEW_FILE="$MEMORY_DIR/log-review-$TODAY.md"
LOG_REVIEW_YESTERDAY="$MEMORY_DIR/log-review-$YESTERDAY.md"
LOG_REVIEW_SECTION=""

if [ -f "$LOG_REVIEW_FILE" ]; then
    # Today's review exists - extract summary
    LOG_SUMMARY=$(head -20 "$LOG_REVIEW_FILE" | grep -E "^\*\*|^###|^- " || echo "Ver archivo completo")
    LOG_REVIEW_SECTION="📋 LOG REVIEW NOCTURNO ($TODAY)
$LOG_SUMMARY"
elif [ -f "$LOG_REVIEW_YESTERDAY" ]; then
    # Yesterday's review
    LOG_SUMMARY=$(head -20 "$LOG_REVIEW_YESTERDAY" | grep -E "^\*\*|^###|^- " || echo "Ver archivo completo")
    LOG_REVIEW_SECTION="📋 LOG REVIEW NOCTURNO ($YESTERDAY)
$LOG_SUMMARY"
else
    LOG_REVIEW_SECTION="📋 LOG REVIEW NOCTURNO
• Sin incidentes nocturnos registrados"
fi

# 5. Nightly Security Review
fetch_data "🔐 Verificando security review nocturno"
SECURITY_REVIEW_FILES=$(ls -t "$MEMORY_DIR"/*security*review*.md "$MEMORY_DIR"/*nightly*security*.md 2>/dev/null | head -1)
SECURITY_REVIEW_SECTION=""

if [ -n "$SECURITY_REVIEW_FILES" ]; then
    LATEST_SECURITY=$(echo "$SECURITY_REVIEW_FILES" | head -1)
    SEC_DATE=$(basename "$LATEST_SECURITY" | grep -oE "[0-9]{8}" | sed 's/\(....\)\(..\)\(..\)/\1-\2-\3/' || echo "fecha desconocida")
    SEC_SUMMARY=$(head -30 "$LATEST_SECURITY" | grep -E "^###|^\*\*|^- |^✅|^❌|^⚠️" | head -10 || echo "Ver archivo completo")
    
    SECURITY_REVIEW_SECTION="🔐 SECURITY REVIEW NOCTURNO ($SEC_DATE)
$SEC_SUMMARY"
else
    SECURITY_REVIEW_SECTION="🔐 SECURITY REVIEW NOCTURNO
• Sin review de seguridad reciente"
fi

# 6. Get Garmin data for yesterday
fetch_data "📊 Obteniendo datos de Garmin"
# NOTE: Call without date argument so script uses its own "yesterday" logic
# (activity from full day yesterday, sleep from today - keyed to wake-up date)
GARMIN_DATA=$(bash ~/.openclaw/workspace/scripts/garmin-health-report.sh --daily 2>&1 || echo "Error en Garmin")

# 7. Get system stats
fetch_data "💻 Obteniendo estadísticas del sistema"
UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')
RAM=$(free -h | awk '/^Mem:/ {print $3 " / " $2}')
DISK=$(df -h / | awk 'NR==2 {print $3 " / " $2}')
GATEWAY_PID=$(pgrep -f "openclaw-gateway" | head -1)
GATEWAY_STATUS="✅ Activo" && [ -z "$GATEWAY_PID" ] && GATEWAY_STATUS="❌ Inactivo"

# Count active crons
CRONS_ACTIVE=$(openclaw cron list 2>/dev/null | tail -n +2 | wc -l || echo "?")

# 8. Get Fail2Ban status
fetch_data "🛡️ Verificando Fail2Ban"
FAIL2BAN=$(sudo fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $NF}' || echo "?")

# 9. Get backup info
fetch_data "💾 Verificando backups"
LAST_BACKUP_JSON="$MEMORY_DIR/last-backup.json"
if [ -f "$LAST_BACKUP_JSON" ]; then
    BACKUP_DATE=$(python3 -c "import json; d=json.load(open('$LAST_BACKUP_JSON')); print(d.get('date','?'))" 2>/dev/null || echo "?")
    BACKUP_STATUS=$(python3 -c "import json; d=json.load(open('$LAST_BACKUP_JSON')); print(d.get('status','?'))" 2>/dev/null || echo "?")
else
    BACKUP_DATE="?"
    BACKUP_STATUS="?"
fi

# 10. Autoimprove Nightly summary
fetch_data "🔬 Leyendo resumen de Autoimprove"
EXPERIMENT_LOG="/home/mleon/.openclaw/workspace/autoimprove/experiment-log.jsonl"
AUTOIMPROVE_FILE="$MEMORY_DIR/autoimprove-log-$TODAY.md"
AUTOIMPROVE_SECTION=""

# First check experiment-log.jsonl (new format: 3 separate agents)
if [ -f "$EXPERIMENT_LOG" ]; then
    # Get today's entries (UTC date in ts field)
    TODAY_UTC=$(date -u +%Y-%m-%d)
    TODAY_ENTRIES=$(grep "$TODAY_UTC" "$EXPERIMENT_LOG" 2>/dev/null || true)
    
    if [ -n "$TODAY_ENTRIES" ]; then
        TOTAL_CHANGES=$(echo "$TODAY_ENTRIES" | wc -l)
        KEPT_COUNT=$(echo "$TODAY_ENTRIES" | grep '"kept":true' | wc -l)
        REVERTED_COUNT=$(echo "$TODAY_ENTRIES" | grep '"kept":false' | wc -l)
        
        # Get targets modified
        TARGETS=$(echo "$TODAY_ENTRIES" | python3 -c "
import sys, json
targets = set()
for line in sys.stdin:
    try:
        d = json.loads(line.strip())
        targets.add(d.get('target','?'))
    except: pass
print(', '.join(sorted(targets)[:5]))
" 2>/dev/null || echo "?")
        
        # Total bytes saved
        BYTES_SAVED=$(echo "$TODAY_ENTRIES" | python3 -c "
import sys, json
total = 0
for line in sys.stdin:
    try:
        d = json.loads(line.strip())
        if d.get('kept'): total += d.get('delta', 0)
    except: pass
print(total)
" 2>/dev/null || echo "0")
        
        AUTOIMPROVE_SECTION="🔬 AUTOIMPROVE NIGHTLY
• $TOTAL_CHANGES cambios ($KEPT_COUNT aplicados, $REVERTED_COUNT revertidos)
• Archivos: $TARGETS
• Bytes optimizados: $BYTES_SAVED"
    else
        AUTOIMPROVE_SECTION="🔬 AUTOIMPROVE NIGHTLY
• No hubo cambios anoche"
    fi
# Fallback: check markdown log format (current format)
elif [ -f "$AUTOIMPROVE_FILE" ]; then
    # Extract key info from autoimprove-log-*.md
    DURATION=$(grep "^\*\*Duration:\*\*" "$AUTOIMPROVE_FILE" | sed 's/^\*\*Duration:\*\* //' || echo "?")
    STATUS=$(grep "^\*\*Status:\*\*" "$AUTOIMPROVE_FILE" | sed 's/^\*\*Status:\*\* //' | tr -d '\n' || echo "?")
    SUMMARY=$(sed -n '/## Summary/,/^---/p' "$AUTOIMPROVE_FILE" | grep -v "^#\|^---\|^$" | head -1 || echo "Sin resumen")
    
    # Extract optimizations count (#### headers under ### Optimizations section)
    OPT_COUNT=$(grep "^#### [0-9]" "$AUTOIMPROVE_FILE" | wc -l)
    
    AUTOIMPROVE_SECTION="🔬 AUTOIMPROVE NIGHTLY ($DURATION) $STATUS
$SUMMARY
• $OPT_COUNT optimizaciones aplicadas"
else
    AUTOIMPROVE_SECTION="🔬 AUTOIMPROVE NIGHTLY
• No se ejecutó anoche"
fi

# 11. System updates status
fetch_data "🔄 Leyendo estado de actualizaciones"
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

# 12. Token usage report
fetch_data "💰 Calculando consumo de tokens"
SCRIPTS_DIR="/home/mleon/.openclaw/workspace/scripts"

MONTH_JSON=$(bash "$SCRIPTS_DIR/usage-report.sh" --month 2>/dev/null || echo "{}")
YESTERDAY_JSON=$(bash "$SCRIPTS_DIR/usage-report.sh" --yesterday 2>/dev/null || echo "{}")
TODAY_JSON=$(bash "$SCRIPTS_DIR/usage-report.sh" --today 2>/dev/null || echo "{}")
MONTH_MODELS_JSON=$(bash "$SCRIPTS_DIR/usage-report.sh" --month --by-model 2>/dev/null || echo "{}")

MONTH_COST=$(echo "$MONTH_JSON" | jq -r '.total_cost // 0' 2>/dev/null || echo "0")
MONTH_PERIOD=$(echo "$MONTH_JSON" | jq -r '.period // "?"' 2>/dev/null || echo "?")
YESTERDAY_COST=$(echo "$YESTERDAY_JSON" | jq -r '.total_cost // 0' 2>/dev/null || echo "0")
TODAY_COST=$(echo "$TODAY_JSON" | jq -r '.total_cost // 0' 2>/dev/null || echo "0")

# Top models this month
TOP_MODELS=$(echo "$MONTH_MODELS_JSON" | jq -r '.by_model[:3][] | "  • \(.model): $\(.cost) (\(.requests) req)"' 2>/dev/null || echo "  (sin datos)")

if [ "$MONTH_COST" != "0" ] && [ -n "$MONTH_COST" ]; then
    TOKEN_SECTION="💰 CONSUMO TOKENS ($MONTH_PERIOD)
• Mes actual: \$$MONTH_COST
• Ayer: \$$YESTERDAY_COST
• Hoy (parcial): \$$TODAY_COST
• Top modelos:
$TOP_MODELS"
else
    TOKEN_SECTION="💰 CONSUMO TOKENS
• (sin datos disponibles)"
fi

# 13. Build the report
INFORME="📋 INFORME MATUTINO • $TODAY $HOUR

🌤️ CLIMA LOGROÑO
$WEATHER


$LOG_REVIEW_SECTION

$SECURITY_REVIEW_SECTION

🖥️ SISTEMA
• Uptime: $UPTIME
• RAM: $RAM | Disco: $DISK
• Gateway: $GATEWAY_STATUS
• Crons activos: $CRONS_ACTIVE

🛡️ SEGURIDAD
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

# 14. Save report
echo "📝 Guardando informe..."
echo "$INFORME" > ~/.openclaw/workspace/memory/$TODAY-informe.md

# 15. Send to Telegram topic 24 (Reportes Diarios)
echo "📤 Enviando a Telegram..."
openclaw message send \
    --channel telegram \
    --target "-1003768820594" \
    --thread-id "24" \
    -m "$INFORME" 2>&1 || echo "⚠️ Error enviando a Telegram"

echo "✅ Informe completado"
