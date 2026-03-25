#!/bin/bash
# fix-cron-delivery.sh
# Fix all crons with incorrect delivery configuration
# - Replace "to": "6884477" with topic routing
# - Replace "channel": "last" with "telegram"

set -euo pipefail

CRON_FILE="$HOME/.openclaw/cron/jobs.json"
BACKUP_FILE="$HOME/.openclaw/cron/jobs.json.bak.$(date +%Y%m%d-%H%M%S)"

echo "🔧 Fixing cron delivery configurations..."
echo ""

# Backup
cp "$CRON_FILE" "$BACKUP_FILE"
echo "✅ Backup created: $BACKUP_FILE"
echo ""

# Topic mapping (based on cron name/purpose)
declare -A TOPIC_MAP=(
    # Health/Garmin → topic 28
    ["Garmin"]="28"
    ["garmin"]="28"
    ["health"]="28"
    
    # Security → topic 29
    ["security"]="29"
    ["Security"]="29"
    
    # System/Logs → topic 25
    ["System"]="25"
    ["Log"]="25"
    ["Backup"]="25"
    ["Model"]="25"
    ["Auto-update"]="25"
    ["Autoimprove"]="25"
    ["autoimprove"]="25"
    ["Driving"]="25"
    ["memory-decay"]="25"
    ["Memory Search"]="25"
    ["Best Practices"]="25"
    ["Cleanup"]="25"
    ["filesystem"]="25"
    ["Surf"]="25"
    
    # Finance → topic 26
    ["Finanzas"]="26"
    ["Sheets"]="26"
    ["Finance"]="26"
    
    # Reports → topic 24
    ["Informe"]="24"
    ["Report"]="24"
)

# Function to determine topic from cron name
get_topic() {
    local name="$1"
    local topic="25"  # Default to Sistema & Logs
    
    for key in "${!TOPIC_MAP[@]}"; do
        if echo "$name" | grep -qi "$key"; then
            topic="${TOPIC_MAP[$key]}"
            break
        fi
    done
    
    echo "$topic"
}

# Process the JSON
jq --arg group_id "-1003768820594" '
.jobs |= map(
  if (.delivery.to == "6884477" or .delivery.channel == "last") then
    . + {
      delivery: (
        .delivery + {
          channel: "telegram"
        } | 
        if .to == "6884477" then
          # Will be replaced with topic in next step
          .to = ($group_id)
        elif .channel == "last" then
          .channel = "telegram" | .to = ($group_id)
        else
          .
        end
      )
    }
  else
    .
  end
)
' "$BACKUP_FILE" > "$CRON_FILE.tmp"

# Now add topics based on cron names
# This is a bit hacky because jq can't easily call bash functions
# So we'll do a two-pass approach

cat > /tmp/fix-cron-topics.jq << 'JQ_SCRIPT'
.jobs |= map(
  if (.delivery.to == "-1003768820594" and (.delivery.topic // null) == null) then
    . + {
      delivery: (
        .delivery + {
          topic: (
            if (.name | contains("Garmin")) or (.name | contains("garmin")) or (.name | contains("health")) then 28
            elif (.name | contains("security")) or (.name | contains("Security")) then 29
            elif (.name | contains("Finanzas")) or (.name | contains("Sheets")) or (.name | contains("Finance")) then 26
            elif (.name | contains("Informe") and (.name | contains("matutino") or .name | contains("Matutino"))) then 24
            else 25
            end
          )
        }
      )
    }
  else
    .
  end
)
JQ_SCRIPT

jq -f /tmp/fix-cron-topics.jq "$CRON_FILE.tmp" > "$CRON_FILE"
rm "$CRON_FILE.tmp" /tmp/fix-cron-topics.jq

echo "✅ Cron delivery configurations fixed"
echo ""

# Show changes
echo "📊 Summary of changes:"
echo ""

# Count fixed crons
FIXED_COUNT=$(jq -r '.jobs[] | select(.delivery.to == "6884477" or .delivery.channel == "last") | .id' "$BACKUP_FILE" 2>/dev/null | wc -l || echo "0")

if [ "$FIXED_COUNT" -gt 0 ]; then
    echo "Fixed $FIXED_COUNT crons:"
    echo ""
    
    jq -r '.jobs[] | select(.delivery.to == "6884477" or .delivery.channel == "last") | "  - \(.name) (ID: \(.id[0:8]))"' "$BACKUP_FILE" 2>/dev/null
    
    echo ""
    echo "New delivery config for these crons:"
    echo ""
    
    # Show updated configs
    while IFS= read -r id; do
        NAME=$(jq -r --arg id "$id" '.jobs[] | select(.id == $id) | .name' "$CRON_FILE")
        DELIVERY=$(jq -r --arg id "$id" '.jobs[] | select(.id == $id) | .delivery | "    channel: \(.channel), to: \(.to), topic: \(.topic // "none")"' "$CRON_FILE")
        echo "  - $NAME"
        echo "$DELIVERY"
        echo ""
    done < <(jq -r '.jobs[] | select(.delivery.to == "6884477" or .delivery.channel == "last") | .id' "$BACKUP_FILE" 2>/dev/null)
else
    echo "No crons needed fixing (all already correct)"
fi

echo ""
echo "🔄 Changes saved to: $CRON_FILE"
echo "📦 Backup available at: $BACKUP_FILE"
echo ""
echo "⚠️  Gateway restart required for changes to take effect:"
echo "    openclaw gateway restart"
echo ""

exit 0
