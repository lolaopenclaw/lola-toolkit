#!/usr/bin/env bash
# Rate Limit Alert Sender
# Checks for pending alerts and sends them via Telegram

set -euo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
ALERT_FILE="$WORKSPACE/memory/rate-limit-alert-pending.json"
SENT_FILE="$WORKSPACE/memory/rate-limit-alerts-sent.jsonl"

# Check if alert file exists
if [[ ! -f "$ALERT_FILE" ]]; then
    exit 0
fi

# Read alert
ALERT_DATA=$(cat "$ALERT_FILE")
MESSAGE=$(echo "$ALERT_DATA" | jq -r '.message')
TIMESTAMP=$(echo "$ALERT_DATA" | jq -r '.timestamp')
API=$(echo "$ALERT_DATA" | jq -r '.api')

# Send via openclaw CLI
# Using echo to pipe message to openclaw message tool
echo "Sending rate limit alert for $API..."

# Create a temp script for openclaw to execute
TEMP_SCRIPT=$(mktemp)
cat > "$TEMP_SCRIPT" << 'EOF'
#!/usr/bin/env bash
ALERT_FILE="$HOME/.openclaw/workspace/memory/rate-limit-alert-pending.json"
MESSAGE=$(cat "$ALERT_FILE" | jq -r '.message')

# Send message via openclaw
openclaw message send "$MESSAGE"
EOF

chmod +x "$TEMP_SCRIPT"
"$TEMP_SCRIPT"
rm "$TEMP_SCRIPT"

# Log to sent file
echo "$ALERT_DATA" >> "$SENT_FILE"

# Remove pending file
rm "$ALERT_FILE"

echo "Alert sent successfully"
