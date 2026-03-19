# 🔐 Security Summary

## Current Status (2026-03-16)
- ✅ 0 CRITICAL issues
- ⚠️ 4 warnings (non-critical)
- HARDENED: DROP policy, SSH key-only, AppArmor active

## Key Config
- `gateway.bind=loopback` when `tailscale.mode=serve`
- SSH: key-only, no password auth
- Firewall: UFW with DROP default
- Fail2ban: active

## Secret Rotation
- Schedule: Quarterly (next: Q2 2026)
- Gateway token rotation cron: 25th every 3 months

## Protocols
- Protocol A+B before SSH/firewall/service changes
- Details: `memory/security-change-protocol.md`
- Last weekly audit: `memory/2026-03-16-security-audit-weekly.md`
