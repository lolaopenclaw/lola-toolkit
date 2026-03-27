#!/usr/bin/env bash
# verify-message-delivery.sh — Quick verification of message delivery after gateway restart
# Usage: bash scripts/verify-message-delivery.sh

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TELEGRAM_CHAT_ID="6884477"
TIMESTAMP=$(date '+%H:%M:%S')

echo -e "${YELLOW}🧪 Message Delivery Verification${NC}"
echo "Time: $TIMESTAMP"
echo ""

# Test 1: Check for recent "Outbound not configured" errors
echo -e "${YELLOW}[1/4] Checking gateway logs for errors...${NC}"
ERROR_COUNT=$(journalctl --user -u openclaw-gateway --since "5 min ago" 2>&1 | \
  grep -c "Outbound not configured" || echo "0")

if [[ $ERROR_COUNT -eq 0 ]]; then
  echo -e "${GREEN}✅ No 'Outbound not configured' errors in last 5 minutes${NC}"
else
  echo -e "${RED}❌ Found $ERROR_COUNT 'Outbound not configured' errors${NC}"
  echo "   Gateway may need restart or deeper fix"
  exit 1
fi
echo ""

# Test 2: Send test message
echo -e "${YELLOW}[2/4] Sending test message to Telegram...${NC}"
TEST_MSG="🧪 Delivery verification test at $TIMESTAMP"

if openclaw message send --target "$TELEGRAM_CHAT_ID" --message "$TEST_MSG" 2>/dev/null; then
  echo -e "${GREEN}✅ Test message sent (check Telegram)${NC}"
else
  echo -e "${RED}❌ Failed to send test message${NC}"
  exit 1
fi
echo ""

# Test 3: Check gateway status
echo -e "${YELLOW}[3/4] Checking gateway status...${NC}"
if openclaw status 2>&1 | grep -q "telegram"; then
  echo -e "${GREEN}✅ Gateway status shows telegram channel${NC}"
else
  echo -e "${RED}❌ Gateway status doesn't show telegram${NC}"
  exit 1
fi
echo ""

# Test 4: Check recent announce queue activity
echo -e "${YELLOW}[4/4] Checking announce queue activity...${NC}"
QUEUE_ACTIVITY=$(journalctl --user -u openclaw-gateway --since "5 min ago" 2>&1 | \
  grep -c "announce queue" || echo "0")

if [[ $QUEUE_ACTIVITY -gt 0 ]]; then
  # Check if any FAILED
  QUEUE_FAILURES=$(journalctl --user -u openclaw-gateway --since "5 min ago" 2>&1 | \
    grep "announce queue" | grep -c "failed" || echo "0")
  
  if [[ $QUEUE_FAILURES -eq 0 ]]; then
    echo -e "${GREEN}✅ Announce queue active, no failures${NC}"
  else
    echo -e "${RED}❌ Announce queue has $QUEUE_FAILURES failures${NC}"
    exit 1
  fi
else
  echo -e "${YELLOW}ℹ️  No recent announce queue activity (normal if no subagents running)${NC}"
fi
echo ""

# Summary
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ ALL CHECKS PASSED${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Next steps:"
echo "  1. Verify test message arrived in Telegram"
echo "  2. Optionally spawn test subagent:"
echo "     openclaw sessions spawn --task 'echo Test && exit 0' --label delivery-test"
echo "  3. Monitor for subagent completion announcement"
echo ""

exit 0
