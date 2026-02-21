#!/bin/bash

# Health Dashboard → Notion Integration
# Pushea datos de salud a página Notion

set -e

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
NOTION_PAGE_ID="${NOTION_HEALTH_PAGE_ID:-30c676c3-86c8-81d5-health}"
API_KEY="${NOTION_API_KEY}"

if [ -z "$API_KEY" ]; then
    echo "⚠️ NOTION_API_KEY not set. Skipping Notion sync."
    exit 0
fi

echo "📱 Syncing health data to Notion..."

# === GET LATEST DATA ===
DASHBOARD_JSON="${WORKSPACE}/.cache/health-dashboard/dashboard-data.json"
ALERTS_JSON="${WORKSPACE}/.cache/health-dashboard/alerts.json"

if [ ! -f "$DASHBOARD_JSON" ]; then
    echo "⚠️ Dashboard data not found. Run health-dashboard.sh first."
    exit 1
fi

# Extract metrics
HR=$(jq '.garmin.hr_resting // "N/A"' "$DASHBOARD_JSON")
STRESS=$(jq '.garmin.stress // "N/A"' "$DASHBOARD_JSON")
BATTERY=$(jq '.garmin.body_battery // "N/A"' "$DASHBOARD_JSON")
SLEEP=$(jq '.garmin.sleep_hours // "N/A"' "$DASHBOARD_JSON")
STEPS=$(jq '.garmin.steps // "N/A"' "$DASHBOARD_JSON")
TEMP=$(jq '.weather.temp_c // "N/A"' "$DASHBOARD_JSON")
ALERTS=$(jq '.alert_count // 0' "$ALERTS_JSON" 2>/dev/null || echo "0")

# === PUSH TO NOTION ===
# Create/update a child page under Health dashboard

BLOCK_CONTENT=$(cat <<'EOF'
{
  "object": "block",
  "type": "paragraph",
  "paragraph": {
    "rich_text": [
      {
        "type": "text",
        "text": {
          "content": "📊 Health Update — {DATE}\n\n❤️ HR: {HR} bpm | 😰 Estrés: {STRESS} | 🔋 Battery: {BATTERY}% | 😴 Sueño: {SLEEP}h | 👣 Pasos: {STEPS}\n🌡️ Clima: {TEMP}°C | 🚨 Alertas: {ALERTS}"
        }
      }
    ]
  }
}
EOF
)

# Replace placeholders
BLOCK_CONTENT="${BLOCK_CONTENT//{DATE}/$(date +%Y-%m-%d)}"
BLOCK_CONTENT="${BLOCK_CONTENT//{HR}/$HR}"
BLOCK_CONTENT="${BLOCK_CONTENT//{STRESS}/$STRESS}"
BLOCK_CONTENT="${BLOCK_CONTENT//{BATTERY}/$BATTERY}"
BLOCK_CONTENT="${BLOCK_CONTENT//{SLEEP}/$SLEEP}"
BLOCK_CONTENT="${BLOCK_CONTENT//{STEPS}/$STEPS}"
BLOCK_CONTENT="${BLOCK_CONTENT//{TEMP}/$TEMP}"
BLOCK_CONTENT="${BLOCK_CONTENT//{ALERTS}/$ALERTS}"

# Create/append to Notion page
curl -s -X POST "https://api.notion.com/v1/blocks/${NOTION_PAGE_ID}/children" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d "$BLOCK_CONTENT" > /dev/null 2>&1 && echo "✅ Synced to Notion" || echo "⚠️ Notion sync failed"

echo "✅ Health data pushed to Notion page"
