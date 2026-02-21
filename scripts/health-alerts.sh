#!/bin/bash

# Health Alerts — Notificaciones de métricas críticas
# Integra: Garmin + Weather + System

set -e

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
ALERTS_FILE="${WORKSPACE}/.cache/health-dashboard/alerts.json"
ALERT_COUNT=0
ALERT_TYPES=()

echo "🚨 Checking health metrics for alerts..."

# === GARMIN CRITICAL CHECKS ===

# HR resting too high
HR=$(bash "$WORKSPACE/scripts/garmin-health-report.sh" --current 2>/dev/null | jq '.garmin.hr_resting // 58')
if (( $(echo "$HR > 70" | bc -l) )); then
    ALERT_TYPES+=("HR_HIGH")
    ((ALERT_COUNT++))
    echo "⚠️ ALERT: HR reposo ALTA ($HR bpm) — Posible estrés o enfermedad"
fi

# Stress too high
STRESS=$(bash "$WORKSPACE/scripts/garmin-health-report.sh" --current 2>/dev/null | jq '.garmin.stress // 28')
if (( $(echo "$STRESS > 60" | bc -l) )); then
    ALERT_TYPES+=("STRESS_HIGH")
    ((ALERT_COUNT++))
    echo "⚠️ ALERT: Estrés ALTO ($STRESS) — Considera pausas"
fi

# Body battery critical
BATTERY=$(bash "$WORKSPACE/scripts/garmin-health-report.sh" --current 2>/dev/null | jq '.garmin.body_battery // 37')
if (( $(echo "$BATTERY < 20" | bc -l) )); then
    ALERT_TYPES+=("BATTERY_CRITICAL")
    ((ALERT_COUNT++))
    echo "🔋 ALERT: Body Battery CRÍTICA ($BATTERY%) — Descansa"
fi

# Sleep too low
SLEEP=$(bash "$WORKSPACE/scripts/garmin-health-report.sh" --current 2>/dev/null | jq '.garmin.sleep_hours // 6.8')
if (( $(echo "$SLEEP < 6" | bc -l) )); then
    ALERT_TYPES+=("SLEEP_LOW")
    ((ALERT_COUNT++))
    echo "😴 ALERT: Sueño BAJO ($SLEEP h) — Prioriza descanso"
fi

# === SYSTEM CRITICAL CHECKS ===

# Memory > 80%
MEMORY_USED=$(free | grep Mem | awk '{printf "%.0f", ($3/$2)*100}')
if (( MEMORY_USED > 80 )); then
    ALERT_TYPES+=("MEMORY_HIGH")
    ((ALERT_COUNT++))
    echo "⚠️ ALERT: Memoria ALTA ($MEMORY_USED%) — Posible leak"
fi

# Disk > 85%
DISK_USED=$(df / | tail -1 | awk '{printf "%d", $5}' | sed 's/%//')
if (( DISK_USED > 85 )); then
    ALERT_TYPES+=("DISK_FULL")
    ((ALERT_COUNT++))
    echo "🔴 ALERT: Disco LLENO ($DISK_USED%) — CRITICAL"
fi

# Gateway down
if ! ss -tlnp | grep -q 18789; then
    ALERT_TYPES+=("GATEWAY_DOWN")
    ((ALERT_COUNT++))
    echo "🔴 ALERT: Gateway DOWN — Port 18789 no listening"
fi

# === SAVE ALERTS JSON ===
mkdir -p "$(dirname "$ALERTS_FILE")"
cat > "$ALERTS_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "alert_count": $ALERT_COUNT,
  "alert_types": [$(printf '"%s"' "${ALERT_TYPES[@]}" | sed 's/" "/"," "/g')],
  "metrics": {
    "hr_resting": $HR,
    "stress": $STRESS,
    "body_battery": $BATTERY,
    "sleep_hours": $SLEEP,
    "memory_percent": $MEMORY_USED,
    "disk_percent": $DISK_USED
  }
}
EOF

echo ""
echo "✅ Alerts saved: $ALERTS_FILE"
echo "📊 Alert count: $ALERT_COUNT"

# === EXPORT FOR CRONS ===
export ALERT_COUNT
export ALERT_TYPES

exit 0
