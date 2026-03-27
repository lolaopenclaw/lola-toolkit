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
- Schedule: Quarterly
- **Last rotation: 2026-03-25 (Q1 2026)**
  - ✅ Telegram Bot Token — rotated
  - ✅ Discord Bot Token — rotated
  - ✅ Brave Search API Key — rotated
  - ⏸️ Anthropic API Key — POSTPONED (enterprise account, no console access)
  - ⏭️ GitHub — SKIP (OAuth via `gh`, auto-renewable)
- Next rotation: Q2 2026 (June)
- Gateway token rotation cron: 25th every 3 months

## Protocols
- Protocol A+B before SSH/firewall/service changes
- Details: `memory/security-change-protocol.md`
- Last weekly audit: `memory/2026-03-16-security-audit-weekly.md`

## Latest Nightly Review
- **Date:** 2026-03-26
- **Status:** ✅ All critical checks passing
- **Findings:** 89 secrets in docs (cleanup ongoing), 2 expected hash updates
- **Weekly audit:** `memory/2026-03-16-security-audit-weekly.md`

_(Historical nightly reviews available in daily logs)_
