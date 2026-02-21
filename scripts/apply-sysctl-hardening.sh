#!/bin/bash
# Apply sysctl kernel hardening
# Usage: sudo bash scripts/apply-sysctl-hardening.sh

set -e

echo "=== Sysctl Hardening ==="
echo "Applying /etc/sysctl.d/99-hardening.conf..."
sysctl -p /etc/sysctl.d/99-hardening.conf

# Also apply to specific interfaces
for iface in $(ls /proc/sys/net/ipv4/conf/); do
    sysctl -w "net.ipv4.conf.${iface}.accept_source_route=0" 2>/dev/null || true
    sysctl -w "net.ipv4.conf.${iface}.log_martians=1" 2>/dev/null || true
done

echo ""
echo "✅ Hardening applied. Verify with:"
echo "   sysctl -a | grep -E 'kptr_restrict|ptrace_scope|log_martians|swappiness'"
