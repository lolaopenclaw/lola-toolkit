#!/bin/bash
# EXA Cron Report - Run searches and send results to Telegram
# Usage: exa-cron-report.sh "topic" "query" num_results

set -e

TOPIC="${1:-AI News}"
QUERY="${2:-latest AI developments}"
NUM_RESULTS="${3:-5}"
TELEGRAM_ID="6884477"

echo "📰 Running EXA search cron: $TOPIC"

# Get search results
results=$("$HOME/.openclaw/workspace/scripts/exa-search.sh" "$QUERY" "$NUM_RESULTS" 2>&1)

# Format message for Telegram
message="📰 $TOPIC - $(date '+%A %d %b %Y')

$results

$(date '+Actualizado: %H:%M %Z')"

# Send to Telegram via openclaw
openclaw message send \
  --channel telegram \
  --target "$TELEGRAM_ID" \
  --message "$message" 2>/dev/null || {
    echo "⚠️ Telegram send failed, but search was successful:"
    echo "$message"
  }

echo "✅ Cron report sent"
