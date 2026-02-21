#!/usr/bin/env bash
# ============================================================
# Setup Health Dashboard Crons
# Installs automated daily health checks
# ============================================================
set -uo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
SCRIPT_DIR="$WORKSPACE/scripts"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}🔧 Setting up Health Dashboard Crons${NC}\n"

# Create cron entries (to be added manually or via OpenClaw cron system)
CRON_ENTRIES=$(cat << 'EOF'
# Health Dashboard Automation
# Daily 9:00 AM - Full health dashboard + alerts
0 9 * * * bash ~/.openclaw/workspace/scripts/health-dashboard-auto.sh >> ~/.openclaw/workspace/.cache/health-dashboard/cron.log 2>&1

# Daily 14:00 - Alert checks (afternoon)
0 14 * * * bash ~/.openclaw/workspace/scripts/health-alerts.sh >> ~/.openclaw/workspace/.cache/health-dashboard/alerts.log 2>&1

# Daily 20:00 - Evening alert checks
0 20 * * * bash ~/.openclaw/workspace/scripts/health-alerts.sh >> ~/.openclaw/workspace/.cache/health-dashboard/alerts.log 2>&1

# Weekly summary (Monday 8:30 AM)
30 8 * * 1 bash ~/.openclaw/workspace/scripts/garmin-health-report.sh --weekly >> ~/.openclaw/workspace/.cache/health-dashboard/weekly.log 2>&1
EOF
)

echo -e "${CYAN}Recommended Cron Entries:${NC}\n"
echo "$CRON_ENTRIES"
echo ""

echo -e "${CYAN}Option 1: Add via crontab (manual)${NC}"
echo ""
echo "Edit your crontab:"
echo "  crontab -e"
echo ""
echo "Then paste the entries above"
echo ""

echo -e "${CYAN}Option 2: Use OpenClaw cron system${NC}"
echo ""
echo "If using OpenClaw's native cron scheduler, run:"
echo "  openclaw cron create daily-health-dashboard --schedule '0 9 * * *' --command 'bash ~/.openclaw/workspace/scripts/health-dashboard-auto.sh'"
echo ""

echo -e "${CYAN}Option 3: Manual daily execution${NC}"
echo ""
echo "To run manually now:"
echo "  bash $SCRIPT_DIR/health-dashboard-auto.sh"
echo ""

echo -e "${BOLD}Verification:${NC}"
echo ""
echo "After adding crons, verify with:"
echo "  crontab -l"
echo ""

echo -e "${BOLD}Health Dashboard Files:${NC}"
echo "  • Main script: $SCRIPT_DIR/health-dashboard-auto.sh"
echo "  • Alerts script: $SCRIPT_DIR/health-alerts.sh"
echo "  • Garmin export: $SCRIPT_DIR/garmin-json-export.sh"
echo "  • Reports directory: $WORKSPACE/reports/"
echo "  • Cache directory: $WORKSPACE/.cache/health-dashboard/"
echo ""

echo -e "${GREEN}✅ Setup complete${NC}"
echo ""
echo "Next steps:"
echo "  1. Choose Option 1, 2, or 3 above"
echo "  2. Add cron entries to your system"
echo "  3. Verify with: crontab -l"
echo "  4. Check logs: tail -f ~/.openclaw/workspace/.cache/health-dashboard/*.log"
