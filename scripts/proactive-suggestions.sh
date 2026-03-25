#!/usr/bin/env bash
# proactive-suggestions.sh - Genera sugerencias proactivas para heartbeat
# Created: 2026-03-24
# Purpose: Context-aware suggestions basadas en weather, calendar, health, finance, pending actions

set -uo pipefail

# Paths
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
MEMORY="$WORKSPACE/memory"
STATE_FILE="$MEMORY/.proactive-suggestions-today.json"
METRICS_FILE="$MEMORY/.proactive-metrics.jsonl"
PENDING_ACTIONS="$MEMORY/pending-actions.md"
PROACTIVE_RULES="$MEMORY/proactive-rules.md"

# Timezone
TZ="Europe/Madrid"
export TZ

# Get current time
NOW=$(date +"%Y-%m-%dT%H:%M:%S%z")
TODAY=$(date +"%Y-%m-%d")
HOUR=$(date +"%H")

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Max suggestions per run
MAX_SUGGESTIONS=3

# ============================================================================
# HELPERS
# ============================================================================

log() {
    echo -e "${BLUE}[proactive]${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}[proactive]${NC} $*" >&2
}

error() {
    echo -e "${RED}[proactive]${NC} $*" >&2
}

# Check quiet hours (23:00-07:00 Madrid)
is_quiet_hours() {
    local hour=$1
    [[ $hour -ge 23 || $hour -lt 7 ]]
}

# Initialize state file
init_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo '{"date":"'"$TODAY"'","suggestions_sent":[],"count":0}' > "$STATE_FILE"
    fi
    
    # Reset if new day
    local state_date
    state_date=$(jq -r '.date' "$STATE_FILE" 2>/dev/null || echo "")
    if [[ "$state_date" != "$TODAY" ]]; then
        log "New day detected, resetting state"
        echo '{"date":"'"$TODAY"'","suggestions_sent":[],"count":0}' > "$STATE_FILE"
    fi
}

# Check if suggestion already sent today
was_sent_today() {
    local type=$1
    local key=$2
    
    jq -e --arg type "$type" --arg key "$key" \
        '.suggestions_sent[] | select(.type==$type and .key==$key)' \
        "$STATE_FILE" >/dev/null 2>&1
}

# Record suggestion
record_suggestion() {
    local type=$1
    local key=$2
    local message=$3
    
    # Update state file
    local tmp
    tmp=$(mktemp)
    jq --arg type "$type" --arg key "$key" --arg ts "$NOW" \
        '.suggestions_sent += [{"type":$type,"key":$key,"timestamp":$ts}] | .count += 1' \
        "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
    
    # Log to metrics (JSONL)
    echo "{\"timestamp\":\"$NOW\",\"type\":\"$type\",\"key\":\"$key\",\"message\":\"$message\"}" >> "$METRICS_FILE"
}

# Get current suggestion count
get_count() {
    jq -r '.count' "$STATE_FILE" 2>/dev/null || echo 0
}

# ============================================================================
# SUGGESTION GENERATORS
# ============================================================================

# Weather-aware suggestions
check_weather() {
    local count
    count=$(get_count)
    [[ $count -ge $MAX_SUGGESTIONS ]] && return
    
    # Only during morning hours (8-10)
    [[ $HOUR -lt 8 || $HOUR -gt 10 ]] && return
    
    # Check cache (4h)
    local cache_file="$MEMORY/.weather-cache.json"
    if [[ -f "$cache_file" ]]; then
        local cache_age
        cache_age=$(( $(date +%s) - $(stat -c %Y "$cache_file") ))
        [[ $cache_age -lt 14400 ]] && return # 4h = 14400s
    fi
    
    # Get weather (using wttr.in for simplicity)
    local weather
    weather=$(curl -s "wttr.in/Logrono?format=j1" 2>/dev/null || echo "")
    
    if [[ -n "$weather" ]]; then
        echo "$weather" > "$cache_file"
        
        # Parse conditions
        local temp rain wind
        temp=$(echo "$weather" | jq -r '.current_condition[0].temp_C' 2>/dev/null || echo "")
        rain=$(echo "$weather" | jq -r '.current_condition[0].precipMM' 2>/dev/null || echo "")
        wind=$(echo "$weather" | jq -r '.current_condition[0].windspeedKmph' 2>/dev/null || echo "")
        
        # Rain check
        if [[ -n "$rain" ]] && (( $(echo "$rain > 5" | bc -l) )); then
            if ! was_sent_today "weather" "rain-logrono"; then
                echo "🌧️ Hoy llueve en Logroño (${rain}mm), quizás no es día de surf"
                record_suggestion "weather" "rain-logrono" "Rain detected: ${rain}mm"
            fi
        fi
        
        # Strong wind check
        if [[ -n "$wind" ]] && [[ $wind -gt 40 ]]; then
            if ! was_sent_today "weather" "wind-strong"; then
                echo "💨 Viento fuerte hoy (${wind}km/h), ideal para windsurf en Mundaka"
                record_suggestion "weather" "wind-strong" "Strong wind: ${wind}km/h"
            fi
        fi
        
        # Extreme temperature
        if [[ -n "$temp" ]]; then
            if [[ $temp -gt 35 ]]; then
                if ! was_sent_today "weather" "temp-hot"; then
                    echo "🔥 Hace mucho calor hoy (${temp}°C), ajusta actividades"
                    record_suggestion "weather" "temp-hot" "Hot: ${temp}°C"
                fi
            elif [[ $temp -lt 5 ]]; then
                if ! was_sent_today "weather" "temp-cold"; then
                    echo "❄️ Hace mucho frío hoy (${temp}°C), abrígate bien"
                    record_suggestion "weather" "temp-cold" "Cold: ${temp}°C"
                fi
            fi
        fi
    fi
}

# Calendar-aware suggestions
check_calendar() {
    local count
    count=$(get_count)
    [[ $count -ge $MAX_SUGGESTIONS ]] && return
    
    # Only during work hours (9-21)
    [[ $HOUR -lt 9 || $HOUR -gt 21 ]] && return
    
    # Check if gog is available
    if ! command -v gog &>/dev/null; then
        return
    fi
    
    # Get today's events
    local events
    events=$(gog calendar list --today --json 2>/dev/null || echo "[]")
    
    if [[ "$events" != "[]" ]]; then
        # Parse upcoming event (next 30 min)
        local next_event
        next_event=$(echo "$events" | jq -r --arg now "$NOW" \
            'map(select(.start > $now)) | sort_by(.start) | first | .summary' 2>/dev/null || echo "")
        
        if [[ -n "$next_event" && "$next_event" != "null" ]]; then
            local event_key
            event_key=$(echo "$next_event" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
            
            if ! was_sent_today "calendar" "meeting-$event_key"; then
                echo "📅 Tienes reunión en 30 min: $next_event"
                record_suggestion "calendar" "meeting-$event_key" "Upcoming: $next_event"
            fi
        fi
        
        # Check for busy day (>5 events)
        local event_count
        event_count=$(echo "$events" | jq 'length' 2>/dev/null || echo 0)
        
        if [[ $event_count -gt 5 ]]; then
            if ! was_sent_today "calendar" "busy-day"; then
                echo "📆 Día intenso hoy: $event_count eventos"
                record_suggestion "calendar" "busy-day" "Busy day: $event_count events"
            fi
        fi
    fi
}

# Health-aware suggestions
check_health() {
    local count
    count=$(get_count)
    [[ $count -ge $MAX_SUGGESTIONS ]] && return
    
    # Only during morning briefing (8-9)
    [[ $HOUR -lt 8 || $HOUR -gt 9 ]] && return
    
    # Check if Garmin data is available
    local garmin_cache="$MEMORY/.garmin-last-sync.json"
    [[ ! -f "$garmin_cache" ]] && return
    
    # Parse sleep data
    local sleep_hours
    sleep_hours=$(jq -r '.sleep.hours' "$garmin_cache" 2>/dev/null || echo "")
    
    if [[ -n "$sleep_hours" && "$sleep_hours" != "null" ]]; then
        if (( $(echo "$sleep_hours < 4" | bc -l) )); then
            if ! was_sent_today "health" "sleep-critical"; then
                echo "⚠️ Sueño crítico (${sleep_hours}h), prioriza descanso hoy"
                record_suggestion "health" "sleep-critical" "Sleep: ${sleep_hours}h"
            fi
        elif (( $(echo "$sleep_hours < 6" | bc -l) )); then
            if ! was_sent_today "health" "sleep-low"; then
                echo "😴 Dormiste poco anoche (${sleep_hours}h), tómatelo con calma"
                record_suggestion "health" "sleep-low" "Sleep: ${sleep_hours}h"
            fi
        fi
    fi
    
    # Parse body battery
    local body_battery
    body_battery=$(jq -r '.body_battery' "$garmin_cache" 2>/dev/null || echo "")
    
    if [[ -n "$body_battery" && "$body_battery" != "null" && $body_battery -lt 30 ]]; then
        if ! was_sent_today "health" "battery-low"; then
            echo "🔋 Body battery bajo (${body_battery}%), recarga energías"
            record_suggestion "health" "battery-low" "Battery: ${body_battery}%"
        fi
    fi
}

# Finance-aware suggestions
check_finance() {
    local count
    count=$(get_count)
    [[ $count -ge $MAX_SUGGESTIONS ]] && return
    
    # Check if finance data is available
    local finance_cache="$MEMORY/.finance-daily.json"
    [[ ! -f "$finance_cache" ]] && return
    
    # Parse daily expenses
    local daily_expense
    daily_expense=$(jq -r '.today.total' "$finance_cache" 2>/dev/null || echo "0")
    
    if [[ -n "$daily_expense" ]] && (( $(echo "$daily_expense > 100" | bc -l) )); then
        if ! was_sent_today "finance" "daily-high"; then
            echo "💰 Llevas €${daily_expense} gastados hoy"
            record_suggestion "finance" "daily-high" "Daily: €${daily_expense}"
        fi
    fi
    
    # Check for pending bank statement
    local last_update
    last_update=$(jq -r '.last_update' "$finance_cache" 2>/dev/null || echo "")
    
    if [[ -n "$last_update" ]]; then
        local days_ago
        days_ago=$(( ( $(date +%s) - $(date -d "$last_update" +%s) ) / 86400 ))
        
        if [[ $days_ago -gt 15 ]]; then
            if ! was_sent_today "finance" "statement-pending"; then
                echo "📊 Hace ${days_ago} días del último extracto, recordar actualizar"
                record_suggestion "finance" "statement-pending" "Last update: ${days_ago} days ago"
            fi
        fi
    fi
}

# Pending actions suggestions
check_pending_actions() {
    local count
    count=$(get_count)
    [[ $count -ge $MAX_SUGGESTIONS ]] && return
    
    [[ ! -f "$PENDING_ACTIONS" ]] && return
    
    # Parse pending actions (simple markdown parsing)
    local urgent_old
    urgent_old=$(grep -E '^\- \[ \].*\*\*urgent\*\*' "$PENDING_ACTIONS" 2>/dev/null | wc -l)
    
    if [[ $urgent_old -gt 0 ]]; then
        if ! was_sent_today "pending" "urgent-old"; then
            echo "⏰ Tienes $urgent_old items urgentes pendientes"
            record_suggestion "pending" "urgent-old" "Urgent items: $urgent_old"
        fi
    fi
    
    # Count total pending
    local total_pending
    total_pending=$(grep -E '^\- \[ \]' "$PENDING_ACTIONS" 2>/dev/null | wc -l)
    
    if [[ $total_pending -gt 10 ]]; then
        if ! was_sent_today "pending" "many-items"; then
            echo "📋 Tienes $total_pending items pendientes, ¿priorizamos?"
            record_suggestion "pending" "many-items" "Total: $total_pending"
        fi
    fi
}

# System-aware suggestions (bonus)
check_system() {
    local count
    count=$(get_count)
    [[ $count -ge $MAX_SUGGESTIONS ]] && return
    
    # Only during nocturnal heartbeat (22-23)
    [[ $HOUR -lt 22 || $HOUR -gt 23 ]] && return
    
    # Check backup age
    local backup_dir="$WORKSPACE/.backups"
    if [[ -d "$backup_dir" ]]; then
        local last_backup
        last_backup=$(find "$backup_dir" -type f -name "*.tar.gz" -printf '%T@\n' 2>/dev/null | sort -rn | head -1)
        
        if [[ -n "$last_backup" ]]; then
            local days_ago
            days_ago=$(( ( $(date +%s) - ${last_backup%.*} ) / 86400 ))
            
            if [[ $days_ago -gt 7 ]]; then
                if ! was_sent_today "system" "backup-old"; then
                    echo "💾 Último backup hace ${days_ago} días, considera ejecutar"
                    record_suggestion "system" "backup-old" "Backup: ${days_ago} days ago"
                fi
            fi
        fi
    fi
    
    # Check active subagents
    if command -v openclaw &>/dev/null; then
        local active_subagents
        active_subagents=$(openclaw sessions list --json 2>/dev/null | jq '[.[] | select(.type=="subagent")] | length' 2>/dev/null || echo 0)
        
        if [[ -n "$active_subagents" && "$active_subagents" != "0" && $active_subagents -gt 5 ]]; then
            if ! was_sent_today "system" "many-subagents"; then
                echo "🤖 Tienes $active_subagents subagentes activos, monitor overhead"
                record_suggestion "system" "many-subagents" "Subagents: $active_subagents"
            fi
        fi
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    # Check quiet hours
    if is_quiet_hours "$HOUR"; then
        log "Quiet hours (23:00-07:00), skipping suggestions"
        exit 0
    fi
    
    # Initialize state
    init_state
    
    log "Generating proactive suggestions for $TODAY at ${HOUR}:00"
    
    # Run all checks
    check_weather
    check_calendar
    check_health
    check_finance
    check_pending_actions
    check_system
    
    local final_count
    final_count=$(get_count)
    
    if [[ $final_count -eq 0 ]]; then
        log "No suggestions generated (all good or already sent)"
    else
        log "Total suggestions sent today: $final_count"
    fi
}

# Run
main "$@"
