#!/usr/bin/env bash
# ============================================================
# CUPS Printing Hardening — Disable if not needed
# ============================================================
set -uo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}🖨️  CUPS Printing Hardening${NC}\n"

# Check CUPS status
echo -e "${CYAN}[1] Current CUPS Status${NC}"

if systemctl is-active --quiet cups; then
    echo -e "${YELLOW}⚠️  CUPS is currently running${NC}"
    systemctl status cups --no-pager | grep "active"
else
    echo -e "${GREEN}✓ CUPS is stopped${NC}"
fi

cups_enabled=$(systemctl is-enabled cups 2>/dev/null || echo "disabled")
echo "Auto-start: $cups_enabled"

echo ""

# Check if printing is actually used
echo -e "${CYAN}[2] Do You Need Printing?${NC}"

printers=$(lpstat -p 2>/dev/null | wc -l)
if [ "$printers" -eq 0 ]; then
    echo -e "${GREEN}✓ No printers configured${NC}"
else
    echo -e "${YELLOW}⚠️  $printers printer(s) configured${NC}"
fi

echo ""
echo -e "${BOLD}ASSESSMENT${NC}"
echo "========="
echo ""

if [ "$printers" -eq 0 ] && [ "$cups_enabled" = "disabled" ]; then
    echo -e "${GREEN}✓ CUPS is properly disabled${NC}"
    echo ""
    echo "Recommendation: SAFE (no changes needed)"
    exit 0
fi

echo ""
echo -e "${BOLD}HARDENING OPTIONS${NC}"
echo "=================="
echo ""

if [ "$printers" -eq 0 ]; then
    echo -e "${CYAN}Option 1: Disable CUPS (Recommended for VPS/Headless Systems)${NC}"
    echo ""
    echo "1. Stop CUPS service:"
    echo "   sudo systemctl stop cups"
    echo ""
    echo "2. Disable at boot:"
    echo "   sudo systemctl disable cups"
    echo ""
    echo "3. Verify:"
    echo "   systemctl is-enabled cups"
    echo ""
else
    echo -e "${CYAN}Option 1: Enable CUPS Hardening (If printing needed)${NC}"
    echo ""
    echo "1. Restrict CUPS configuration:"
    echo "   sudo nano /etc/cups/cupsd.conf"
    echo ""
    echo "   Make sure these settings exist:"
    echo "   • LogLevel warn (not debug)"
    echo "   • MaxLogSize 0 (or set limit)"
    echo "   • ListenLocalhost"
    echo "   • MaxLogSize 0"
    echo ""
    echo "2. Restrict access:"
    echo "   <Location />"
    echo "     Order allow,deny"
    echo "     Allow 127.0.0.1"
    echo "     Allow [::1]"
    echo "   </Location>"
    echo ""
    echo "3. Restart CUPS:"
    echo "   sudo systemctl restart cups"
fi

echo ""
echo -e "${CYAN}Option 2: Remove CUPS Entirely (Most Secure)${NC}"
echo ""
echo "If no printers ever used:"
echo "   sudo apt-get remove cups cups-filters"
echo "   sudo apt-get purge cups"
echo "   sudo apt-get autoremove"
echo ""

echo ""
echo -e "${BOLD}CURRENT RECOMMENDATION FOR THIS SYSTEM${NC}"
echo "======================================"
echo ""
echo "This is a VPS (headless, no physical printers)"
echo ""
echo "✓ RECOMMENDED: Disable and remove CUPS"
echo "  └─ Reduces attack surface"
echo "  └─ Frees resources"
echo "  └─ Not needed in headless environment"
echo ""
echo "To apply:"
echo "   sudo systemctl stop cups"
echo "   sudo systemctl disable cups"
echo "   sudo apt-get remove --purge cups cups-filters"
echo ""

echo ""
echo -e "${BOLD}CUPS SECURITY AUDIT CHECKLIST${NC}"
echo "=============================="
echo ""
echo "If you keep CUPS, verify:"
echo ""
echo "[ ] LogLevel is 'warn' or 'error' (not 'debug')"
echo "[ ] Access restricted to localhost only"
echo "[ ] No remote printing enabled"
echo "[ ] cupsd.conf has restrictive permissions (640)"
echo "[ ] Unnecessary printer drivers removed"
echo "[ ] CUPS daemon runs as unprivileged user"
echo ""
echo "Verify:"
echo "   grep '^LogLevel' /etc/cups/cupsd.conf"
echo "   grep -A3 '<Location' /etc/cups/cupsd.conf"
echo ""

echo ""
echo -e "${BOLD}Status:${NC} ℹ️  Informational guide (no changes applied)"
