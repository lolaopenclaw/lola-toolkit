#!/bin/bash
# emergency-cost-stop.sh - Emergency shutdown for runaway costs
# Usage: bash scripts/emergency-cost-stop.sh "Reason for emergency stop"

set -euo pipefail

# Configuration
DATA_DIR="$HOME/.openclaw/workspace/data"
TELEGRAM_CHAT_ID="6884477"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validate reason provided
if [[ $# -eq 0 ]]; then
  echo -e "${RED}❌ ERROR: Must provide reason for emergency stop${NC}"
  echo "Usage: $0 \"Reason for emergency stop\""
  exit 1
fi

REASON="$1"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "${RED}🚨 EMERGENCY COST STOP INITIATED${NC}"
echo "Reason: $REASON"
echo "Time: $TIMESTAMP"
echo ""

# Log the event
mkdir -p "$DATA_DIR"
LOG_FILE="$DATA_DIR/emergency-stop.log"
{
  echo "=========================================="
  echo "EMERGENCY STOP: $TIMESTAMP"
  echo "Reason: $REASON"
  echo "=========================================="
  echo ""
} >> "$LOG_FILE"

# 1. List running subagent sessions
echo -e "${YELLOW}📋 Listing running subagent sessions...${NC}"
SESSIONS=$(openclaw sessions list --json 2>/dev/null || echo "[]")
ACTIVE_SESSIONS=$(echo "$SESSIONS" | jq -r '.[] | select(.status == "active") | .id' 2>/dev/null || echo "")

if [[ -n "$ACTIVE_SESSIONS" ]]; then
  echo "Active sessions found:"
  echo "$ACTIVE_SESSIONS"
  echo ""
  
  # 2. Kill all subagent sessions
  echo -e "${YELLOW}💀 Terminating all active sessions...${NC}"
  while IFS= read -r session_id; do
    if [[ -n "$session_id" ]]; then
      echo "  Killing session: $session_id"
      openclaw sessions kill "$session_id" 2>/dev/null || echo "  ⚠️ Failed to kill $session_id"
      echo "  - Killed session: $session_id" >> "$LOG_FILE"
    fi
  done <<< "$ACTIVE_SESSIONS"
  echo ""
else
  echo "No active sessions found."
  echo "No active sessions to kill" >> "$LOG_FILE"
  echo ""
fi

# 3. Disable non-essential crons
echo -e "${YELLOW}⏸️  Disabling non-essential cron jobs...${NC}"
ESSENTIAL_CRONS=("backup" "driving-mode-reset")
ALL_CRONS=$(openclaw cron list --json 2>/dev/null || echo "[]")

# Get all cron IDs except essential ones
CRONS_TO_DISABLE=$(echo "$ALL_CRONS" | jq -r \
  --argjson essential "$(printf '%s\n' "${ESSENTIAL_CRONS[@]}" | jq -R . | jq -s .)" \
  '.[] | select(.enabled == true) | select([.label, .id] | inside($essential) | not) | .id' \
  2>/dev/null || echo "")

if [[ -n "$CRONS_TO_DISABLE" ]]; then
  while IFS= read -r cron_id; do
    if [[ -n "$cron_id" ]]; then
      cron_label=$(echo "$ALL_CRONS" | jq -r ".[] | select(.id == \"$cron_id\") | .label // .id" 2>/dev/null)
      echo "  Disabling cron: $cron_label ($cron_id)"
      openclaw cron disable "$cron_id" 2>/dev/null || echo "  ⚠️ Failed to disable $cron_id"
      echo "  - Disabled cron: $cron_label ($cron_id)" >> "$LOG_FILE"
    fi
  done <<< "$CRONS_TO_DISABLE"
  echo ""
else
  echo "No non-essential crons to disable."
  echo "No non-essential crons found" >> "$LOG_FILE"
  echo ""
fi

# 4. Send Telegram alert
echo -e "${YELLOW}📱 Sending Telegram alert...${NC}"
ALERT_MESSAGE="🚨 EMERGENCY COST STOP

Reason: $REASON
Time: $TIMESTAMP

Actions taken:
✅ All subagent sessions terminated
✅ Non-essential crons disabled
✅ Essential crons kept: backup, driving-mode-reset

To re-enable crons:
openclaw cron list
openclaw cron enable <id>

Log: $LOG_FILE"

# Send via openclaw message tool (if available) or fallback to telegram CLI
if command -v openclaw >/dev/null 2>&1; then
  echo "$ALERT_MESSAGE" | openclaw message send --target "$TELEGRAM_CHAT_ID" 2>/dev/null || {
    echo "⚠️ Failed to send Telegram alert via openclaw"
    echo "Failed to send Telegram alert" >> "$LOG_FILE"
  }
else
  echo "⚠️ openclaw CLI not available, skipping Telegram alert"
  echo "Telegram alert skipped (no CLI)" >> "$LOG_FILE"
fi

echo ""

# Final summary
{
  echo ""
  echo "Actions completed:"
  echo "  ✅ Sessions terminated"
  echo "  ✅ Non-essential crons disabled"
  echo "  ✅ Alert sent to Telegram"
  echo "  ✅ Log written to: $LOG_FILE"
  echo ""
} | tee -a "$LOG_FILE"

echo -e "${RED}🚨 EMERGENCY STOP COMPLETE${NC}"
echo ""
echo "Next steps:"
echo "  1. Review log: cat $LOG_FILE"
echo "  2. Check spending: bash scripts/usage-report.sh --today"
echo "  3. Investigate root cause"
echo "  4. Re-enable crons when safe: openclaw cron enable <id>"

exit 0
