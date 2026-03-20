#!/usr/bin/env bash
# ============================================================
# Health Alerts — Check health metrics against thresholds
# ============================================================
set -euo pipefail

# === DEPENDENCY CHECK ===
for cmd in jq bc free df ss; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ Error: '$cmd' is required but not installed." >&2
        exit 1
    fi
done

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$WORKSPACE/.cache/health-dashboard"
ALERTS_FILE="$CACHE_DIR/alerts.json"

# Verify garmin export script exists
if [ ! -f "$SCRIPT_DIR/garmin-json-export.sh" ]; then
    echo "❌ Error: garmin-json-export.sh not found in $SCRIPT_DIR" >&2
    exit 1
fi

# Alert thresholds
HR_HIGH="${HR_HIGH:-70}"
HR_LOW="${HR_LOW:-45}"
STRESS_HIGH="${STRESS_HIGH:-60}"
BATTERY_LOW="${BATTERY_LOW:-20}"
SLEEP_MIN="${SLEEP_MIN:-6}"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

mkdir -p "$CACHE_DIR"

echo -e "${CYAN}🏥 Health Alerts Check${NC}\n"

# Get Garmin data as JSON
GARMIN_DATA=$(bash "$SCRIPT_DIR/garmin-json-export.sh" 2>&1)

if [ -z "$GARMIN_DATA" ]; then
    echo "Error: Failed to fetch Garmin data"
    exit 1
fi

# Validate JSON
if ! echo "$GARMIN_DATA" | jq empty 2>/dev/null; then
    echo "Error: Invalid JSON from Garmin API"
    echo "Debug: $GARMIN_DATA" | head -5
    exit 1
fi

# Parse JSON safely
HR=$(echo "$GARMIN_DATA" | jq -r '.hr.current // .hr.resting // 0' 2>/dev/null || echo 0)
STRESS=$(echo "$GARMIN_DATA" | jq -r '.stress.level // 0' 2>/dev/null || echo 0)
BATTERY=$(echo "$GARMIN_DATA" | jq -r '.body_battery.level // 0' 2>/dev/null || echo 0)
SLEEP=$(echo "$GARMIN_DATA" | jq -r '.sleep.duration_hours // 0' 2>/dev/null || echo 0)
STEPS=$(echo "$GARMIN_DATA" | jq -r '.activity.steps // 0' 2>/dev/null || echo 0)

# Check system metrics
MEMORY_USED=$(free | awk 'NR==2 {printf "%.0f", ($3/$2)*100}')
DISK_USED=$(df /home | awk 'NR==2 {print $5}' | sed 's/%//')
GATEWAY_UP=$(ss -tlnp 2>/dev/null | grep -q 18789 && echo "yes" || echo "no")

# Initialize alerts
declare -a ALERTS=()
declare -a WARNINGS=()
declare -a INFO=()

# Health checks
[ "$HR" -gt "$HR_HIGH" ] && ALERTS+=("❤️ High HR: $HR bpm (threshold: $HR_HIGH)")
[ "$HR" -lt "$HR_LOW" ] && [ "$HR" -gt 0 ] && WARNINGS+=("❤️ Low HR: $HR bpm (threshold: $HR_LOW)")
[ "$STRESS" -gt "$STRESS_HIGH" ] && ALERTS+=("😰 High stress: $STRESS (threshold: $STRESS_HIGH)")
[ "$BATTERY" -lt "$BATTERY_LOW" ] && ALERTS+=("🔋 Low battery: $BATTERY% (threshold: $BATTERY_LOW%)")
[ "$(echo "$SLEEP < $SLEEP_MIN" | bc)" -eq 1 ] && WARNINGS+=("😴 Low sleep: ${SLEEP%.*}h (target: $SLEEP_MIN h)")

# System checks
[ "$MEMORY_USED" -gt 80 ] && WARNINGS+=("💾 Memory: $MEMORY_USED% (high)")
[ "$DISK_USED" -gt 85 ] && ALERTS+=("💿 Disk: $DISK_USED% (critical)")
[ "$GATEWAY_UP" = "no" ] && ALERTS+=("⚡ OpenClaw gateway not responding")

# Activity check
[ "$STEPS" -lt 1000 ] && INFO+=("👣 Low activity: $STEPS steps (consider moving)")

# Generate JSON output
cat > "$ALERTS_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "metrics": {
    "heart_rate": $HR,
    "stress_level": $STRESS,
    "body_battery": $BATTERY,
    "sleep_hours": $SLEEP,
    "steps": $STEPS,
    "memory_used_percent": $MEMORY_USED,
    "disk_used_percent": $DISK_USED
  },
  "alerts": {
    "critical": [
$(for alert in "${ALERTS[@]}"; do echo "      \"$alert\","; done | sed '$ s/,$//')
    ],
    "warning": [
$(for warn in "${WARNINGS[@]}"; do echo "      \"$warn\","; done | sed '$ s/,$//')
    ],
    "info": [
$(for inf in "${INFO[@]}"; do echo "      \"$inf\","; done | sed '$ s/,$//')
    ]
  },
  "summary": {
    "critical_count": ${#ALERTS[@]},
    "warning_count": ${#WARNINGS[@]},
    "info_count": ${#INFO[@]},
    "status": "$([ ${#ALERTS[@]} -gt 0 ] && echo "CRITICAL" || ([ ${#WARNINGS[@]} -gt 0 ] && echo "WARNING" || echo "OK"))"
  }
}
EOF

# Print console output
echo -e "${CYAN}Metrics:${NC}"
echo "  💓 HR: $HR bpm"
echo "  😰 Stress: $STRESS"
echo "  🔋 Battery: $BATTERY%"
echo "  😴 Sleep: ${SLEEP%.*}h"
echo "  👣 Steps: $STEPS"
echo ""

if [ ${#ALERTS[@]} -gt 0 ]; then
    echo -e "${RED}🚨 CRITICAL ALERTS (${#ALERTS[@]}):${NC}"
    for alert in "${ALERTS[@]}"; do
        echo -e "  ${RED}✗${NC} $alert"
    done
    echo ""
fi

if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  WARNINGS (${#WARNINGS[@]}):${NC}"
    for warn in "${WARNINGS[@]}"; do
        echo -e "  ${YELLOW}!${NC} $warn"
    done
    echo ""
fi

if [ ${#INFO[@]} -gt 0 ]; then
    echo -e "${CYAN}ℹ️  INFO (${#INFO[@]}):${NC}"
    for inf in "${INFO[@]}"; do
        echo -e "  ${CYAN}i${NC} $inf"
    done
    echo ""
fi

# Summary
total_issues=$((${#ALERTS[@]} + ${#WARNINGS[@]}))
if [ $total_issues -eq 0 ]; then
    echo -e "${GREEN}✅ All metrics normal${NC}"
else
    echo -e "${RED}Issues: $total_issues${NC}"
fi

echo ""
echo "📄 JSON saved to: $ALERTS_FILE"
