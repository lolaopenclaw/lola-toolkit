#!/bin/bash
# Log Review Matutino - Reviews overnight logs for issues
# Runs daily at 07:30 Madrid time

set -euo pipefail

# Check quiet hours (00:00-07:00 Madrid)
check_quiet_hours() {
    local SEVERITY=${1:-"MEDIUM"}
    local HOUR=$(TZ=Europe/Madrid date +%H)
    
    if [ "$HOUR" -ge 0 ] && [ "$HOUR" -lt 7 ]; then
        # During quiet hours
        if [ "$SEVERITY" = "CRITICAL" ]; then
            return 0  # Allow
        else
            echo "Quiet hours: suppressing $SEVERITY notification" >&2
            return 1  # Suppress
        fi
    fi
    
    return 0  # Outside quiet hours: allow
}


# Paths
WORKSPACE="/home/mleon/.openclaw/workspace"
MEMORY_DIR="$WORKSPACE/memory"
TELEGRAM_CHAT_ID="-1002381931352"  # Manu's default Telegram channel

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Get logs from last night (22:00 yesterday to 07:30 today)
get_overnight_logs() {
    local today
    local yesterday
    today=$(date +'%Y-%m-%d')
    yesterday=$(date -d yesterday +'%Y-%m-%d')
    
    local logs=""
    
    # Check today's gateway log
    if [ -f "/tmp/openclaw/openclaw-${today}.log" ]; then
        # Extract logs from 00:00 to 07:30 today
        logs="$logs$(grep "\"time\":\"${today}T0[0-7]:" /tmp/openclaw/openclaw-${today}.log 2>/dev/null || true)"
    fi
    
    # Check yesterday's gateway log
    if [ -f "/tmp/openclaw/openclaw-${yesterday}.log" ]; then
        # Extract logs from 22:00 onwards yesterday
        logs="$logs$(grep "\"time\":\"${yesterday}T2[2-3]:" /tmp/openclaw/openclaw-${yesterday}.log 2>/dev/null || true)"
    fi
    
    # Fallback to journalctl if file logs are not available
    if [ -z "$logs" ]; then
        logs=$(journalctl --user -u openclaw-gateway \
            --since "22:00 yesterday" \
            --until "07:30 today" \
            --no-pager 2>/dev/null || echo "")
    fi
    
    echo "$logs"
}

# Check for errors and warnings
check_errors() {
    local logs="$1"
    echo "$logs" | grep -i "error\|ERROR" || true
}

check_warnings() {
    local logs="$1"
    echo "$logs" | grep -i "warning\|WARN" || true
}

check_crashes() {
    local logs="$1"
    echo "$logs" | grep -i "crash\|segfault\|fatal\|SIGTERM\|SIGKILL" || true
}

check_restarts() {
    local logs="$1"
    local restart_count
    restart_count=$(echo "$logs" | grep -i "starting\|started" | wc -l)
    
    # More than 1 restart is suspicious (initial start + unexpected restarts)
    if [ "$restart_count" -gt 1 ]; then
        echo "$logs" | grep -i "starting\|started"
    fi
}

# Check cron job status
check_cron_failures() {
    local logs="$1"
    
    # Look for cron failures
    local failures
    failures=$(echo "$logs" | grep -i "cron.*fail\|cron.*error" || true)
    
    # Check if autoimprove ran (should run around 02:00)
    local autoimprove_ran
    autoimprove_ran=$(echo "$logs" | grep -i "autoimprove" | wc -l)
    
    # Check if backup ran (should run around 01:30)
    local backup_ran
    backup_ran=$(echo "$logs" | grep -i "checkpoint-backup\|backup.*complete" | wc -l)
    
    local issues=""
    
    if [ -n "$failures" ]; then
        issues="${issues}Cron failures detectados:\n$failures\n\n"
    fi
    
    if [ "$autoimprove_ran" -eq 0 ]; then
        issues="${issues}⚠️  Autoimprove no ejecutado esta noche\n\n"
    fi
    
    if [ "$backup_ran" -eq 0 ]; then
        issues="${issues}⚠️  Backup no ejecutado esta noche\n\n"
    fi
    
    echo -e "$issues"
}

# Save issues to memory file
save_issues() {
    local date="$1"
    local errors="$2"
    local warnings="$3"
    local crashes="$4"
    local restarts="$5"
    local cron_issues="$6"
    
    local filename="$MEMORY_DIR/log-review-${date}.md"
    
    {
        echo "# Log Review - $date"
        echo ""
        echo "**Período:** 22:00 $(date -d yesterday +'%Y-%m-%d') → 07:30 $(date +'%Y-%m-%d')"
        echo ""
        
        if [ -n "$errors" ]; then
            echo "## 🔴 Errors"
            echo ""
            echo '```'
            echo "$errors"
            echo '```'
            echo ""
        fi
        
        if [ -n "$warnings" ]; then
            echo "## ⚠️  Warnings"
            echo ""
            echo '```'
            echo "$warnings"
            echo '```'
            echo ""
        fi
        
        if [ -n "$crashes" ]; then
            echo "## 💥 Crashes / Fatal Errors"
            echo ""
            echo '```'
            echo "$crashes"
            echo '```'
            echo ""
        fi
        
        if [ -n "$restarts" ]; then
            echo "## 🔄 Unexpected Restarts"
            echo ""
            echo '```'
            echo "$restarts"
            echo '```'
            echo ""
        fi
        
        if [ -n "$cron_issues" ]; then
            echo "## 📅 Cron Issues"
            echo ""
            echo "$cron_issues"
            echo ""
        fi
        
        echo "---"
        echo ""
        echo "Generado automáticamente por log-review.sh"
    } > "$filename"
    
    echo "$filename"
}

# Send Telegram notification
notify_telegram() {
    local message="$1"
    
    # Use openclaw message tool to send notification
    /home/mleon/.npm-global/bin/openclaw message send \
        --channel telegram \
        --target "$TELEGRAM_CHAT_ID" \
        --message "$message" \
        >/dev/null 2>&1 || log "${YELLOW}⚠️  No se pudo enviar notificación a Telegram${NC}"
}

# Main logic
main() {
    log "🔍 Revisando logs nocturnos..."
    
    local date
    date=$(date +'%Y-%m-%d')
    
    # Get logs
    local logs
    logs=$(get_overnight_logs)
    
    if [ -z "$logs" ]; then
        log "${YELLOW}⚠️  No se encontraron logs del gateway para el período nocturno${NC}"
        log "Verificado en:"
        log "  - /tmp/openclaw/openclaw-*.log"
        log "  - journalctl --user -u openclaw-gateway"
        log ""
        log "Si el gateway está corriendo, esto puede indicar un problema con file logs o systemd journal."
        
        # Create a warning report
        local filename="$MEMORY_DIR/log-review-${date}.md"
        {
            echo "# Log Review - $date"
            echo ""
            echo "**Período:** 22:00 $(date -d yesterday +'%Y-%m-%d') → 07:30 $(date +'%Y-%m-%d')"
            echo ""
            echo "## ⚠️  Warning"
            echo ""
            echo "No se encontraron logs del gateway para revisar."
            echo ""
            echo "**Ubicaciones verificadas:**"
            echo "- /tmp/openclaw/openclaw-*.log"
            echo "- journalctl --user -u openclaw-gateway"
            echo ""
            echo "**Gateway status:** \`openclaw gateway status\` reporta running"
            echo ""
            echo "**Acción requerida:** Verificar configuración de file logs en gateway."
            echo ""
            echo "---"
            echo "Generado automáticamente por log-review.sh"
        } > "$filename"
        
        notify_telegram "⚠️  *Log Review - Sin logs disponibles*

No se encontraron logs del gateway para revisar (22:00-07:30).

Gateway: running (PID $(pgrep -u mleon node | head -1 || echo 'unknown'))

📄 \`memory/log-review-${date}.md\`"
        
        exit 0
    fi
    
    # Check for issues
    local errors
    local warnings
    local crashes
    local restarts
    local cron_issues
    
    errors=$(check_errors "$logs")
    warnings=$(check_warnings "$logs")
    crashes=$(check_crashes "$logs")
    restarts=$(check_restarts "$logs")
    cron_issues=$(check_cron_failures "$logs")
    
    # Count issues
    local error_count
    local warning_count
    local crash_count
    
    error_count=$(echo -n "$errors" | grep -c "." || echo "0")
    warning_count=$(echo -n "$warnings" | grep -c "." || echo "0")
    crash_count=$(echo -n "$crashes" | grep -c "." || echo "0")
    
    # Determine if there are significant issues
    local has_issues=false
    
    if [ "$error_count" -gt 0 ] || [ "$crash_count" -gt 0 ] || [ -n "$restarts" ] || [ -n "$cron_issues" ]; then
        has_issues=true
    fi
    
    if [ "$has_issues" = true ]; then
        log "${RED}❌ Issues detectados en logs nocturnos${NC}"
        
        # Save to memory
        local report_file
        report_file=$(save_issues "$date" "$errors" "$warnings" "$crashes" "$restarts" "$cron_issues")
        
        log "${GREEN}💾 Report guardado en $report_file${NC}"
        
        # Prepare notification summary
        local summary=""
        
        if [ "$error_count" -gt 0 ]; then
            summary="${summary}🔴 $error_count errors\n"
        fi
        
        if [ "$crash_count" -gt 0 ]; then
            summary="${summary}💥 $crash_count crashes\n"
        fi
        
        if [ -n "$restarts" ]; then
            summary="${summary}🔄 Reinicios inesperados\n"
        fi
        
        if [ -n "$cron_issues" ]; then
            summary="${summary}📅 Problemas con crons\n"
        fi
        
        # Notify
        notify_telegram "⚠️  *Log Review - Problemas detectados*

$summary
📄 Detalles guardados en:
\`memory/log-review-${date}.md\`"
        
    else
        log "${GREEN}✅ No se detectaron problemas en logs nocturnos${NC}"
        
        # Silent success - no notification, no memory file
        if [ "$warning_count" -gt 5 ]; then
            log "${YELLOW}ℹ️  Se encontraron $warning_count warnings (dentro de lo normal)${NC}"
        fi
    fi
}

main "$@"
