#!/usr/bin/env bash
# APT Security Check — Ubuntu/Debian package health audit
set -uo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
REPORT_DIR="$WORKSPACE/reports"
REPORT_FILE="$REPORT_DIR/apt-security-$(date +%Y-%m-%d).txt"
mkdir -p "$REPORT_DIR"

# Colors
RED='\033[0;31m' YELLOW='\033[1;33m' GREEN='\033[0;32m'
CYAN='\033[0;36m' BOLD='\033[1m' NC='\033[0m'

log_section() {
    echo -e "${CYAN}→ $1${NC}" && echo "$1:" >> "$REPORT_FILE"
}

{
    echo "APT Security Audit — $(date +%Y-%m-%d)"
    echo "System: $(hostname) | OS: $(lsb_release -d | cut -f2)"
    echo ""

    # Broken packages
    log_section "Broken Packages"
    broken=$(apt-get check 2>&1 | grep -i "broken" || echo "✓ None")
    echo "$broken" && echo "$broken" >> "$REPORT_FILE"
    
    # Updates
    log_section "Available Updates"
    apt-get update >/dev/null 2>&1
    update_count=$(apt-get upgrade -s | grep "^Inst" | wc -l)
    echo "Total: $update_count" && echo "Total: $update_count" >> "$REPORT_FILE"
    
    # Security updates
    log_section "Security Updates"
    security_count=$(apt-get upgrade -s | grep -i "security" | wc -l)
    msg=$([ "$security_count" -eq 0 ] && echo "✓ None" || echo "⚠️  $security_count PENDING")
    echo "$msg" && echo "$msg" >> "$REPORT_FILE"
    
    # Held packages
    log_section "Held Packages"
    held=$(apt-mark showhold | wc -l)
    msg=$([ "$held" -eq 0 ] && echo "✓ None" || echo "⚠️  $held held")
    echo "$msg" && echo "$msg" >> "$REPORT_FILE"
    
    # Summary
    echo "" && echo "SUMMARY: broken=✓ upgradable=$update_count security=$([ "$security_count" -eq 0 ] && echo "✓" || echo "⚠️  $security_count")" && echo "" >> "$REPORT_FILE"

} | tee "$REPORT_FILE"

echo -e "${GREEN}✅ Report: $REPORT_FILE${NC}"
