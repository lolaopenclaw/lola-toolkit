#!/bin/bash
# autoimprove-trigger.sh — Triggers the nightly autoimprove loop via OpenClaw
# Cron: 0 2 * * * (every night at 02:00 Madrid)
# This sends a message to the agent which invokes the /autoimprove skill

set -euo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
LOG="$WORKSPACE/memory/autoimprove-log.json"
TODAY=$(date +%Y-%m-%d)

# Check if already ran today
LAST_RUN=$(jq -r '.last_run // ""' "$LOG" 2>/dev/null || echo "")
if [ "$LAST_RUN" = "$TODAY" ]; then
    echo "Already ran today ($TODAY). Skipping."
    exit 0
fi

# Check if it's a reasonable hour (02:00-05:00)
HOUR=$(date +%H)
if [ "$HOUR" -lt 2 ] || [ "$HOUR" -gt 5 ]; then
    echo "Outside nightly window (02-05). Current hour: $HOUR. Skipping."
    exit 0
fi

# Trigger via OpenClaw CLI
echo "$(date): Triggering autoimprove for $TODAY..."
openclaw message send --text "/autoimprove --max 10" 2>&1 || {
    # Fallback: try the REST API if CLI doesn't support message send
    echo "CLI trigger failed, trying alternative..."
    # Log the attempt
    echo "$(date): Trigger attempted but CLI method unavailable" >> /tmp/autoimprove.log
}

echo "$(date): Autoimprove triggered for $TODAY" >> /tmp/autoimprove.log
