#!/usr/bin/env bash
# Rate Limit Alert Sender
# Checks for pending alerts and sends them via Telegram

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


WORKSPACE="$HOME/.openclaw/workspace"
ALERT_FILE="$WORKSPACE/memory/rate-limit-alert-pending.json"
SENT_FILE="$WORKSPACE/memory/rate-limit-alerts-sent.jsonl"

# Check if alert file exists
if [[ ! -f "$ALERT_FILE" ]]; then
    exit 0
fi

# Read alert (single jq call for all fields)
ALERT_DATA=$(cat "$ALERT_FILE")
read -r MESSAGE TIMESTAMP API <<< "$(echo "$ALERT_DATA" | jq -r '.message, .timestamp, .api' | tr '\n' ' ')"

# Send via openclaw CLI
echo "Sending rate limit alert for $API..."

# Create a temp script for openclaw to execute
TEMP_SCRIPT=$(mktemp)
cat > "$TEMP_SCRIPT" << 'EOF'
#!/usr/bin/env bash
ALERT_FILE="$HOME/.openclaw/workspace/memory/rate-limit-alert-pending.json"
MESSAGE=$(cat "$ALERT_FILE" | jq -r '.message')

# Send message via openclaw
openclaw message send --channel telegram --target "-1003768820594" --topic 25 --message "$MESSAGE"
EOF

chmod +x "$TEMP_SCRIPT"
"$TEMP_SCRIPT"
rm "$TEMP_SCRIPT"

# Log to sent file
echo "$ALERT_DATA" >> "$SENT_FILE"

# Remove pending file
rm "$ALERT_FILE"

echo "Alert sent successfully"
