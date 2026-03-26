#!/usr/bin/env bash
set -euo pipefail
# calendar-tasks.sh — Google Calendar integration for task management
# Uses gog CLI with lolaopenclaw@gmail.com calendar
#
# Usage:
#   calendar-tasks.sh check          — Check tasks for today/tomorrow (for heartbeats)
#   calendar-tasks.sh add "title" "2026-03-05" ["description"] ["HH:MM"]
#   calendar-tasks.sh list [days]    — List events for next N days (default: 7)
#   calendar-tasks.sh today          — Events for today only
#   calendar-tasks.sh tomorrow       — Events for tomorrow only

set -euo pipefail

# Check dependencies
for cmd in gog python3 date; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ Missing required dependency: $cmd" >&2
        exit 1
    fi
done

CALENDAR_ID="lolaopenclaw@gmail.com"
TZ="Europe/Madrid"

# Color codes for task types (gog calendar colors)
# 1=Lavender 2=Sage 3=Grape 4=Flamingo 5=Banana 
# 6=Tangerine 7=Peacock 8=Graphite 9=Blueberry 10=Basil 11=Tomato
COLOR_TASK=9        # Blueberry - regular tasks
COLOR_REMINDER=5    # Banana - reminders
COLOR_IMPORTANT=11  # Tomato - important/urgent
COLOR_RECURRING=10  # Basil - recurring tasks

cmd="${1:-help}"

case "$cmd" in
  check)
    # Check today + tomorrow for heartbeat integration
    TODAY=$(date +%Y-%m-%d)
    TOMORROW=$(date -d "+1 day" +%Y-%m-%d)
    DAY_AFTER=$(date -d "+2 days" +%Y-%m-%d)
    
    echo "📅 Checking calendar..."
    
    # Today's events
    TODAY_EVENTS=$(gog calendar events "$CALENDAR_ID" --from "$TODAY" --to "$TOMORROW" --json 2>/dev/null)
    TODAY_COUNT=$(echo "$TODAY_EVENTS" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('events',[])))" 2>/dev/null || echo "0")
    
    # Tomorrow's events  
    TOMORROW_EVENTS=$(gog calendar events "$CALENDAR_ID" --from "$TOMORROW" --to "$DAY_AFTER" --json 2>/dev/null)
    TOMORROW_COUNT=$(echo "$TOMORROW_EVENTS" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('events',[])))" 2>/dev/null || echo "0")
    
    if [ "$TODAY_COUNT" = "0" ] && [ "$TOMORROW_COUNT" = "0" ]; then
      echo "OK: No pending tasks"
      exit 0
    fi
    
    # Format output
    if [ "$TODAY_COUNT" != "0" ]; then
      echo ""
      echo "📌 HOY ($TODAY):"
      echo "$TODAY_EVENTS" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for e in data.get('events', []):
    time = e.get('start', {}).get('dateTime', e.get('start', {}).get('date', ''))
    if 'T' in time:
        time = time[11:16]
    else:
        time = 'todo el día'
    summary = e.get('summary', 'Sin título')
    desc = e.get('description', '')
    print(f'  ⏰ {time} — {summary}')
    if desc:
        print(f'    📝 {desc[:80]}')
"
    fi
    
    if [ "$TOMORROW_COUNT" != "0" ]; then
      echo ""
      echo "📅 MAÑANA ($TOMORROW):"
      echo "$TOMORROW_EVENTS" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for e in data.get('events', []):
    time = e.get('start', {}).get('dateTime', e.get('start', {}).get('date', ''))
    if 'T' in time:
        time = time[11:16]
    else:
        time = 'todo el día'
    summary = e.get('summary', 'Sin título')
    print(f'  ⏰ {time} — {summary}')
"
    fi
    ;;
    
  add)
    TITLE="${2:?Usage: calendar-tasks.sh add \"title\" \"YYYY-MM-DD\" [\"description\"] [\"HH:MM\"]}"
    DATE="${3:?Usage: calendar-tasks.sh add \"title\" \"YYYY-MM-DD\" [\"description\"] [\"HH:MM\"]}"
    DESC="${4:-}"
    TIME="${5:-}"
    
    if [ -n "$TIME" ]; then
      # Timed event (1 hour default)
      FROM="${DATE}T${TIME}:00+01:00"
      TO_HOUR=$(date -d "${DATE} ${TIME} +1 hour" +%H:%M 2>/dev/null || echo "$TIME")
      TO="${DATE}T${TO_HOUR}:00+01:00"
      
      ARGS=(gog calendar create "$CALENDAR_ID" --summary "$TITLE" --from "$FROM" --to "$TO" --event-color "$COLOR_TASK")
    else
      # All-day event (task/reminder style)
      NEXT_DATE=$(date -d "$DATE +1 day" +%Y-%m-%d)
      ARGS=(gog calendar create "$CALENDAR_ID" --summary "$TITLE" --from "$DATE" --to "$NEXT_DATE" --all-day --event-color "$COLOR_TASK")
    fi
    
    if [ -n "$DESC" ]; then
      ARGS+=(--description "$DESC")
    fi
    
    # Add popup reminder
    ARGS+=(--reminder "popup:30m")
    
    "${ARGS[@]}" 2>&1
    echo "✅ Tarea creada: $TITLE ($DATE${TIME:+ $TIME})"
    ;;
    
  add-important)
    # Same as add but with Tomato color and extra reminders
    TITLE="${2:?}"
    DATE="${3:?}"
    DESC="${4:-}"
    TIME="${5:-}"
    
    if [ -n "$TIME" ]; then
      FROM="${DATE}T${TIME}:00+01:00"
      TO_HOUR=$(date -d "${DATE} ${TIME} +1 hour" +%H:%M 2>/dev/null || echo "$TIME")
      TO="${DATE}T${TO_HOUR}:00+01:00"
      ARGS=(gog calendar create "$CALENDAR_ID" --summary "🔴 $TITLE" --from "$FROM" --to "$TO" --event-color "$COLOR_IMPORTANT")
    else
      NEXT_DATE=$(date -d "$DATE +1 day" +%Y-%m-%d)
      ARGS=(gog calendar create "$CALENDAR_ID" --summary "🔴 $TITLE" --from "$DATE" --to "$NEXT_DATE" --all-day --event-color "$COLOR_IMPORTANT")
    fi
    
    [ -n "$DESC" ] && ARGS+=(--description "$DESC")
    ARGS+=(--reminder "popup:1d" --reminder "popup:2h" --reminder "popup:30m")
    
    "${ARGS[@]}" 2>&1
    echo "🔴 Tarea IMPORTANTE creada: $TITLE ($DATE${TIME:+ $TIME})"
    ;;
    
  add-recurring)
    # Create recurring task
    TITLE="${2:?}"
    DATE="${3:?}"
    RRULE="${4:?Usage: calendar-tasks.sh add-recurring \"title\" \"YYYY-MM-DD\" \"RRULE:FREQ=WEEKLY;BYDAY=MO\"}"
    DESC="${5:-}"
    
    NEXT_DATE=$(date -d "$DATE +1 day" +%Y-%m-%d)
    ARGS=(gog calendar create "$CALENDAR_ID" --summary "🔄 $TITLE" --from "$DATE" --to "$NEXT_DATE" --all-day --event-color "$COLOR_RECURRING" --rrule "$RRULE" --reminder "popup:30m")
    [ -n "$DESC" ] && ARGS+=(--description "$DESC")
    
    "${ARGS[@]}" 2>&1
    echo "🔄 Tarea recurrente creada: $TITLE"
    ;;
    
  list)
    DAYS="${2:-7}"
    FROM=$(date +%Y-%m-%d)
    TO=$(date -d "+${DAYS} days" +%Y-%m-%d)
    
    echo "📅 Eventos: $FROM → $TO"
    gog calendar events "$CALENDAR_ID" --from "$FROM" --to "$TO" --json 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
events = data.get('events', [])
if not events:
    print('  (vacío)')
else:
    for e in events:
        start = e.get('start', {})
        time = start.get('dateTime', start.get('date', ''))
        if 'T' in time:
            day = time[:10]
            hour = time[11:16]
            display = f'{day} {hour}'
        else:
            display = f'{time} (todo el día)'
        summary = e.get('summary', 'Sin título')
        print(f'  📌 {display} — {summary}')
"
    ;;
    
  today)
    TODAY=$(date +%Y-%m-%d)
    TOMORROW=$(date -d "+1 day" +%Y-%m-%d)
    gog calendar events "$CALENDAR_ID" --from "$TODAY" --to "$TOMORROW" 2>&1
    ;;
    
  tomorrow)
    TOMORROW=$(date -d "+1 day" +%Y-%m-%d)
    DAY_AFTER=$(date -d "+2 days" +%Y-%m-%d)
    gog calendar events "$CALENDAR_ID" --from "$TOMORROW" --to "$DAY_AFTER" 2>&1
    ;;
    
  help|*)
    echo "📅 calendar-tasks.sh — Google Calendar task management"
    echo ""
    echo "Commands:"
    echo "  check                              Check today/tomorrow (heartbeat)"
    echo "  add \"title\" \"YYYY-MM-DD\" [desc] [HH:MM]  Create task"
    echo "  add-important \"title\" \"date\" [desc] [HH:MM]  Create urgent task"  
    echo "  add-recurring \"title\" \"date\" \"RRULE\"    Create recurring task"
    echo "  list [days]                        List next N days (default: 7)"
    echo "  today                              Today's events"
    echo "  tomorrow                           Tomorrow's events"
    ;;
esac
