# Security Audit Report - Weekly
**Date:** 2026-03-26 13:29 CET  
**Type:** Scheduled weekly deep audit (cron: fdf38b8f-6d68-4798-84ea-1e2a24c61e75)  
**Status:** ✅ ALL CLEAR — no critical issues detected

---

## Executive Summary

Sistema en buen estado general. Todas las defensas activas y actualizadas. No se detectaron vulnerabilidades críticas, accesos sospechosos ni servicios inesperadamente expuestos.

**Overall Security Posture:** 🟢 **GOOD**

---

## 1. OpenClaw Security Audit

```
openclaw security audit --deep
Summary: 0 critical · 1 warn · 2 info
```

### Warnings
- **WARN:** Potential multi-user setup detected (personal-assistant model warning)
  - **Context:** Telegram groupPolicy="allowlist" configured for group targets
  - **Tools exposed:** runtime=[exec, process], fs=[read, write, edit, apply_patch]
  - **Assessment:** Expected configuration for personal assistant with Telegram group access
  - **Action:** No action required. This is the intended setup for Manu's use case.

### Info
- Gateway exposed via Tailscale Serve (mode="serve") — expected behavior, internal tailnet only
- Attack surface: groups=2 (allowlist), elevated tools enabled, browser control enabled
- Trust model: personal assistant (single trusted operator) — appropriate for this deployment

---

## 2. Firewall Status (UFW)

```bash
Status: active
Default: deny (incoming), deny (outgoing)
```

### Inbound Rules
- **DENY** from 2.57.122.208 — Persistent SSH brute-force attacker (36 bans in 3 days)
- All other inbound: **DENIED by default** ✅

### Outbound Rules (whitelist)
- ✅ localhost (lo)
- ✅ tailscale0
- ✅ DNS (53)
- ✅ HTTP/HTTPS (80, 443)
- ✅ NTP (123)
- ✅ Tailscale UDP (41641)
- ✅ FCM (5228) — Firebase Cloud Messaging for Android notifications

**Assessment:** 🟢 Excellent egress filtering. Only essential services whitelisted.

---

## 3. Fail2ban Status

```bash
Number of jails: 3
- openclaw (0 currently banned, 0 total banned)
- recidive (0 currently banned, 0 total banned)
- sshd (0 currently banned, 0 total banned)
```

**Status:** ✅ Active and running (uptime: 1d 14h)  
**Assessment:** No recent ban activity. Manual UFW rule in place for persistent offender (2.57.122.208).

---

## 4. System Updates

```bash
All packages are up to date.
OS: Ubuntu 24.04.4 LTS
```

### Unattended Upgrades
- **Status:** ✅ enabled and active
- **Last check:** 2026-03-26 06:25
- **Recent upgrades:** 2026-03-17 libssh-4, python3-cryptography (security patches)
- **Cadence:** Daily automatic security updates

**Assessment:** 🟢 Fully patched. Automatic security updates working correctly.

---

## 5. SSH Access Review

### Recent SSH Activity (last 72 hours)
```
Mar 24 22:50:16 ubuntu sshd[1116]: error: Bind to port 22 on 100.121.147.45 failed: Cannot assign requested address.
```

- **Assessment:** Single binding error during system boot (non-critical, race condition with Tailscale interface)
- **No successful SSH logins** in the last 72 hours ✅
- **No failed login attempts** detected ✅

### Last Human SSH Sessions
- **Feb 25 11:35-12:18** — mleon from 100.112.177.91 (Tailscale)
- **Feb 25 09:16-11:34** — mleon from 82.223.200.207 (home IP)

**Assessment:** 🟢 All SSH access legitimate and from expected sources (Tailscale/home IP).

---

## 6. Open Ports

### Listening Services
| Port  | Service              | Bind Address    | Exposure        | Status |
|-------|----------------------|-----------------|-----------------|--------|
| 18790 | OpenClaw Gateway     | 127.0.0.1       | Loopback only   | ✅ Safe |
| 18792 | OpenClaw (secondary) | 127.0.0.1       | Loopback only   | ✅ Safe |
| 8080  | Dashboard            | 127.0.0.1       | Loopback only   | ✅ Safe |
| 3333  | Canvas               | 127.0.0.1       | Loopback only   | ✅ Safe |
| 5001  | API                  | 0.0.0.0         | All interfaces  | ⚠️ Review |
| 5901  | VNC (Xtigervnc)      | 127.0.0.1       | Loopback only   | ✅ Safe |
| 5902  | VNC (Xtigervnc)      | 127.0.0.1       | Loopback only   | ✅ Safe |
| 9222  | Chrome DevTools      | 127.0.0.1       | Loopback only   | ✅ Safe |
| 11434 | Ollama               | 127.0.0.1       | Loopback only   | ✅ Safe |
| 22    | SSH                  | 127.0.0.1       | Loopback only   | ✅ Safe |

**Tailscale Exposed Ports (tailnet-only):**
- 443, 8443, 8444, 36705 (Tailscale Serve endpoints)
- 60449 (IPv6 tailnet listener)

### ⚠️ Observation
- **Port 5001** bound to `0.0.0.0` but protected by UFW deny-by-default incoming policy
- External access blocked at firewall level
- **Recommendation:** If not intentionally public, bind to 127.0.0.1 for defense-in-depth

---

## 7. OpenClaw Update Status

```
Install: pnpm
Channel: stable (default)
Update: pnpm · up to date · npm latest 2026.3.24
```

**Assessment:** ✅ Running latest stable version.

---

## 8. System Resources

```
Filesystem: /dev/vda1
Size: 464G | Used: 87G | Available: 378G | Use: 19%
```

**Assessment:** ✅ Plenty of disk space available.

---

## 9. Iptables Summary

```
INPUT policy: DROP (default deny)
OUTPUT policy: DROP (default deny, explicit whitelist)
FORWARD policy: DROP
```

- Tailscale traffic accepted via ts-input chain
- UFW rules enforcing strict ingress/egress filtering
- No unexpected ACCEPT rules

**Assessment:** 🟢 Robust netfilter rules. Deny-by-default everywhere.

---

## Recommendations

1. **Port 5001 binding** — Consider binding to 127.0.0.1 unless public API access needed
2. **Monitoring continuity** — Keep weekly audits scheduled (current setup is good)
3. **Backup verification** — No explicit backup system detected. Consider implementing if critical data present.

---

## Commands Executed

```bash
openclaw security audit --deep
sudo ufw status verbose
sudo systemctl status fail2ban --no-pager
sudo fail2ban-client status [sshd|recidive|openclaw]
sudo apt update
sudo apt list --upgradable
sudo last -n 30 -w -F
ss -ltnup
openclaw update status
sudo journalctl -u ssh -S "72 hours ago" --no-pager
sudo iptables -L -n -v
df -h /
cat /etc/apt/apt.conf.d/20auto-upgrades
systemctl is-enabled unattended-upgrades
sudo systemctl status unattended-upgrades --no-pager
sudo grep -E "upgraded|install" /var/log/unattended-upgrades/unattended-upgrades.log
lsb_release -d
openclaw status --deep
```

---

## Final Assessment

**✅ ALL SYSTEMS SECURE**

No critical issues detected. System is well-hardened, fully patched, and actively monitored. All access vectors protected by appropriate layers (firewall, fail2ban, SSH restrictions, Tailscale isolation).

Continue weekly audits as scheduled.

---

**Next Audit:** 2026-04-02 09:00 CET (Monday)
