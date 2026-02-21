#!/usr/bin/env bash
# ============================================================
# APT Security Check — Ubuntu/Debian package health audit
# Detects broken packages, security updates, deprecated tools
# ============================================================
set -uo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
REPORT_DIR="$WORKSPACE/reports"
REPORT_FILE="$REPORT_DIR/apt-security-$(date +%Y-%m-%d).txt"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Create report dir
mkdir -p "$REPORT_DIR"

echo -e "${BOLD}🔍 APT Security Check${NC}\n"
{
    echo "APT Security Audit Report"
    echo "========================="
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo "OS: $(lsb_release -d | cut -f2)"
    echo ""

    # 1. Check for broken packages
    echo -e "${CYAN}[1/6] Checking for broken packages...${NC}"
    echo "BROKEN PACKAGES:"
    broken=$(apt-get check 2>&1 | grep -i "broken" || echo "✓ None")
    echo "$broken"
    echo ""

    # 2. Available updates
    echo -e "${CYAN}[2/6] Available updates...${NC}"
    echo "AVAILABLE UPDATES:"
    apt-get update >/dev/null 2>&1
    update_count=$(apt-get upgrade -s | grep "^Inst" | wc -l)
    echo "Total upgradable packages: $update_count"
    echo ""

    # 3. Security updates specifically
    echo -e "${CYAN}[3/6] Security updates...${NC}"
    echo "SECURITY UPDATES:"
    security_count=$(apt-get upgrade -s | grep -i "security" | wc -l)
    if [ "$security_count" -gt 0 ]; then
        echo "⚠️  PENDING SECURITY UPDATES: $security_count"
        apt-get upgrade -s | grep -i "security"
    else
        echo "✓ No pending security updates"
    fi
    echo ""

    # 4. Check for held packages
    echo -e "${CYAN}[4/6] Held packages...${NC}"
    echo "HELD PACKAGES:"
    held=$(apt-mark showhold | wc -l)
    if [ "$held" -gt 0 ]; then
        echo "⚠️  Held packages found ($held):"
        apt-mark showhold
    else
        echo "✓ No held packages"
    fi
    echo ""

    # 5. Obsolete/local packages
    echo -e "${CYAN}[5/6] Obsolete/local packages...${NC}"
    echo "OBSOLETE/LOCAL PACKAGES:"
    obsolete=$(apt-get autoclean -s 2>&1 | grep "^Del" | wc -l)
    if [ "$obsolete" -gt 0 ]; then
        echo "⚠️  Obsolete packages: $obsolete"
        apt-get autoclean -s 2>&1 | grep "^Del" | head -10
    else
        echo "✓ No obsolete packages"
    fi
    echo ""

    # 6. Check APT configuration
    echo -e "${CYAN}[6/6] APT configuration...${NC}"
    echo "APT CONFIGURATION:"
    echo "Unattended upgrades: $(systemctl is-enabled unattended-upgrades 2>/dev/null || echo 'disabled')"
    
    if [ -f /etc/apt/apt.conf.d/50unattended-upgrades ]; then
        echo "Unattended upgrades config exists ✓"
        # Check if automatic reboot on kernel updates is enabled
        if grep -q "Unattended-Upgrade::Automatic-Reboot \"true\"" /etc/apt/apt.conf.d/50unattended-upgrades; then
            echo "  → Automatic reboot on kernel updates: ENABLED"
        else
            echo "  → Automatic reboot on kernel updates: disabled (consider enabling)"
        fi
    fi
    echo ""

    # Summary
    echo "SUMMARY:"
    echo "========"
    echo "Broken packages: $([ "$broken" = "✓ None" ] && echo "0 ✓" || echo "⚠️  CHECK MANUALLY")"
    echo "Upgradable: $update_count"
    echo "Security updates: $([ "$security_count" -eq 0 ] && echo "0 ✓" || echo "⚠️  $security_count PENDING")"
    echo "Held packages: $([ "$held" -eq 0 ] && echo "0 ✓" || echo "⚠️  $held")"
    echo ""

    # Recommendations
    echo "RECOMMENDATIONS:"
    echo "================"
    if [ "$security_count" -gt 0 ]; then
        echo "⚠️  Install security updates:"
        echo "   sudo apt-get update && sudo apt-get upgrade"
    fi
    if [ "$held" -gt 0 ]; then
        echo "⚠️  Review held packages (may be blocking security updates):"
        echo "   apt-mark showhold"
    fi
    if [ "$update_count" -gt 20 ]; then
        echo "⚠️  Large number of pending updates. Consider:"
        echo "   sudo apt-get update && sudo apt-get dist-upgrade"
    fi
    echo "✓ Consider enabling unattended automatic security updates"
    echo "✓ Check /var/log/apt/history.log for recent changes"

} | tee "$REPORT_FILE"

echo ""
echo -e "${GREEN}✅ Report saved to: $REPORT_FILE${NC}"
