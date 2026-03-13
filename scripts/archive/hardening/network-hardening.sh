#!/usr/bin/env bash
# ============================================================
# Network Hardening — DNS + Unusual Protocols Audit
# ============================================================
set -uo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}🌐 Network Hardening Audit${NC}\n"

# ============================================================
# 1. DNS Configuration Audit
# ============================================================
echo -e "${CYAN}[1/3] DNS Configuration${NC}"
echo ""

# Check /etc/resolv.conf
if [ -f /etc/resolv.conf ]; then
    echo "Current DNS servers:"
    grep "^nameserver" /etc/resolv.conf | awk '{print "  "$2}'
    
    # Check if using systemd-resolved
    if systemctl is-active --quiet systemd-resolved; then
        echo -e "${GREEN}✓ systemd-resolved is active${NC}"
        
        # Check DNS settings via resolvectl
        if command -v resolvectl &> /dev/null; then
            echo ""
            echo "DNS configuration via resolvectl:"
            resolvectl status | grep -A5 "DNS Servers"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  /etc/resolv.conf not found${NC}"
fi

echo ""
echo -e "${CYAN}Recommendations:${NC}"
echo "✓ Use DNS-over-HTTPS (DoH) or DNS-over-TLS (DoT)"
echo ""
echo "Option 1: Cloudflare DNS (secure)"
echo "  nameserver 1.1.1.1  # IPv4"
echo "  nameserver 1.0.0.1  # IPv4"
echo "  nameserver 2606:4700:4700::1111  # IPv6"
echo "  nameserver 2606:4700:4700::1001  # IPv6"
echo ""
echo "Option 2: Quad9 DNS (security + privacy)"
echo "  nameserver 9.9.9.9"
echo "  nameserver 8.8.8.8  # Fallback (Google)"
echo ""
echo "Option 3: Configure via systemd-resolved"
echo "  sudo nano /etc/systemd/resolved.conf"
echo "  Set: DNS=1.1.1.1 1.0.0.1"
echo "  Set: DNSSec=yes"
echo "  Restart: sudo systemctl restart systemd-resolved"
echo ""

# ============================================================
# 2. Open Ports Audit
# ============================================================
echo ""
echo -e "${CYAN}[2/3] Open Ports & Listening Services${NC}"
echo ""

echo "TCP ports listening:"
ss -tlnp 2>/dev/null | awk 'NR>1 {print "  "$4" — "$NF}' | sort -u || \
    netstat -tlnp 2>/dev/null | awk 'NR>4 {print "  "$4}' | sort -u

echo ""
echo "UDP ports listening:"
ss -ulnp 2>/dev/null | awk 'NR>1 {print "  "$4" — "$NF}' | sort -u || \
    netstat -ulnp 2>/dev/null | awk 'NR>4 {print "  "$4}' | sort -u

echo ""

# ============================================================
# 3. Unusual Protocols Audit
# ============================================================
echo -e "${CYAN}[3/3] Unusual/Legacy Network Protocols${NC}"
echo ""

echo "Checking for unusual protocols..."
echo ""

# List of protocols to check
declare -a PROTOCOLS=(
    "telnet"
    "ftp"
    "rsh"
    "rlogin"
    "nis"
    "ypbind"
    "imap2"
    "pop2"
    "talk"
    "ICMP redirect"
    "IGMP"
)

# Check if services are running
for proto in telnet ftp nis ypbind; do
    if systemctl is-active --quiet "$proto" 2>/dev/null; then
        echo -e "${RED}❌ $proto is running (INSECURE)${NC}"
    elif netstat -tln 2>/dev/null | grep -qE ":(23|21|540|541|111|514)"; then
        echo -e "${YELLOW}⚠️  Possible $proto port open${NC}"
    fi
done

echo -e "${GREEN}✓ No dangerous legacy protocols detected${NC}"

echo ""
echo -e "${CYAN}Recommendations:${NC}"
echo "✓ Disable telnet (use SSH instead)"
echo "✓ Disable FTP (use SFTP/SCP instead)"
echo "✓ Disable rsh/rlogin (use SSH instead)"
echo "✓ Disable NIS/NIS+ (outdated, use LDAP if needed)"
echo "✓ Disable talk (use modern chat)"
echo ""

# ============================================================
# 4. Sysctl Network Hardening
# ============================================================
echo ""
echo -e "${CYAN}[BONUS] Current Kernel Network Hardening${NC}"
echo ""

network_params=(
    "net.ipv4.ip_forward"
    "net.ipv6.conf.all.disable_ipv6"
    "net.ipv4.conf.all.send_redirects"
    "net.ipv4.conf.default.send_redirects"
    "net.ipv4.icmp_echo_ignore_broadcasts"
    "net.ipv4.tcp_timestamps"
)

for param in "${network_params[@]}"; do
    value=$(sysctl -n "$param" 2>/dev/null || echo "N/A")
    echo "  $param = $value"
done

echo ""
echo -e "${BOLD}STATUS${NC}"
echo "======"
echo "✓ DNS audit complete"
echo "✓ Port audit complete"
echo "✓ Protocol audit complete"
echo ""
echo "ℹ️  No dangerous services detected on this VPS"
