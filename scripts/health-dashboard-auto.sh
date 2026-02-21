#!/usr/bin/env bash
# ============================================================
# Health Dashboard Auto — Daily health metrics aggregation
# Runs: 9:00 AM every day
# ============================================================
set -uo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORTS_DIR="$WORKSPACE/reports"
CACHE_DIR="$WORKSPACE/.cache/health-dashboard"
DASHBOARD_FILE="$REPORTS_DIR/health-dashboard-$(date +%Y-%m-%d).md"

mkdir -p "$REPORTS_DIR" "$CACHE_DIR"

echo "🏥 Daily Health Dashboard — $(date +%Y-%m-%d\ %H:%M)"

# Step 1: Collect Garmin data
echo "  [1/3] Fetching Garmin metrics..."
GARMIN_JSON=$(bash "$SCRIPT_DIR/garmin-json-export.sh" 2>&1)

# Step 2: Check alerts
echo "  [2/3] Checking health alerts..."
bash "$SCRIPT_DIR/health-alerts.sh" > /tmp/health-alerts-output.txt 2>&1
ALERTS_JSON=$(cat "$CACHE_DIR/alerts.json")

# Step 3: Generate markdown report
echo "  [3/3] Generating dashboard report..."

cat > "$DASHBOARD_FILE" << 'EOF'
# 🏥 Daily Health Dashboard
EOF

echo "**Date:** $(date '+%d %B %Y')" >> "$DASHBOARD_FILE"
echo "**Time:** $(date '+%H:%M')" >> "$DASHBOARD_FILE"
echo "" >> "$DASHBOARD_FILE"

# Extract metrics from JSON
HR=$(echo "$GARMIN_JSON" | jq -r '.hr.current // .hr.resting // 0')
STRESS=$(echo "$GARMIN_JSON" | jq -r '.stress.level // 0')
BATTERY=$(echo "$GARMIN_JSON" | jq -r '.body_battery.level // 0')
SLEEP=$(echo "$GARMIN_JSON" | jq -r '.sleep.duration_hours // 0')
STEPS=$(echo "$GARMIN_JSON" | jq -r '.activity.steps // 0')
DISTANCE=$(echo "$GARMIN_JSON" | jq -r '.activity.distance_km // 0')
CALORIES=$(echo "$GARMIN_JSON" | jq -r '.activity.calories // 0')

# Alerts summary
ALERT_COUNT=$(echo "$ALERTS_JSON" | jq -r '.summary.critical_count')
WARNING_COUNT=$(echo "$ALERTS_JSON" | jq -r '.summary.warning_count')
ALERT_STATUS=$(echo "$ALERTS_JSON" | jq -r '.summary.status')

# Health metrics section
cat >> "$DASHBOARD_FILE" << EOF

## 📊 Health Metrics

| Metric | Value | Status |
|--------|-------|--------|
| 💓 Heart Rate | $HR bpm | $([ "$HR" -gt 70 ] && echo "⚠️" || echo "✅") |
| 😰 Stress Level | $STRESS | $([ "$STRESS" -gt 60 ] && echo "⚠️" || echo "✅") |
| 🔋 Body Battery | $BATTERY% | $([ "$BATTERY" -lt 20 ] && echo "🔴" || echo "✅") |
| 😴 Sleep | ${SLEEP%.*}h | $([ "$(echo "$SLEEP < 6" | bc)" -eq 1 ] && echo "⚠️" || echo "✅") |

## 👥 Activity

| Metric | Value |
|--------|-------|
| 👣 Steps | $STEPS |
| 📏 Distance | ${DISTANCE%.*} km |
| 🔥 Calories | ${CALORIES%.*} kcal |

## 🚨 Status

**Overall Status:** $ALERT_STATUS

EOF

# Add alerts if any
if [ "$ALERT_COUNT" -gt 0 ] || [ "$WARNING_COUNT" -gt 0 ]; then
    echo "### 🚨 Issues Detected" >> "$DASHBOARD_FILE"
    echo "" >> "$DASHBOARD_FILE"
    
    if [ "$ALERT_COUNT" -gt 0 ]; then
        echo "**Critical ($ALERT_COUNT):**" >> "$DASHBOARD_FILE"
        echo "$ALERTS_JSON" | jq -r '.alerts.critical[]' | sed 's/^/- /' >> "$DASHBOARD_FILE"
        echo "" >> "$DASHBOARD_FILE"
    fi
    
    if [ "$WARNING_COUNT" -gt 0 ]; then
        echo "**Warnings ($WARNING_COUNT):**" >> "$DASHBOARD_FILE"
        echo "$ALERTS_JSON" | jq -r '.alerts.warning[]' | sed 's/^/- /' >> "$DASHBOARD_FILE"
        echo "" >> "$DASHBOARD_FILE"
    fi
else
    echo "### ✅ All metrics normal" >> "$DASHBOARD_FILE"
fi

# JSON summary
echo "" >> "$DASHBOARD_FILE"
echo "## 📋 Raw Data" >> "$DASHBOARD_FILE"
echo "" >> "$DASHBOARD_FILE"
echo "\`\`\`json" >> "$DASHBOARD_FILE"
echo "$GARMIN_JSON" | jq . >> "$DASHBOARD_FILE"
echo "\`\`\`" >> "$DASHBOARD_FILE"

echo "✅ Dashboard saved: $DASHBOARD_FILE"
echo "✅ Alerts JSON: $CACHE_DIR/alerts.json"

# Return JSON for piping
echo ""
echo "Dashboard complete at $(date -Iseconds)"
