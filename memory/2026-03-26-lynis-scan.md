# Lynis Security Scan — 2026-03-26

**Timestamp:** 2026-03-26 13:28 (Europe/Madrid)

## Current Metrics

- **Hardening Index:** 75%
- **Warnings:** 0
- **Suggestions:** 31

## Comparison vs Baseline (2026-02-20)

- **Hardening Index:** 75% → 75% (sin cambios)
- **Warnings:** 0 → 0 (sin cambios)
- **Suggestions:** 31 → 31 (sin cambios)

## Status

✅ **ESTABLE** — Sin regresiones detectadas

- Sin cambios en el índice de hardening
- Sin nuevos warnings
- Número de suggestions estable

## Suggestion Categories (31 total)

- **Boot Security:** GRUB password (BOOT-5122), systemd services (BOOT-5264)
- **SSH Hardening:** AllowTcpForwarding, Port, TCPKeepAlive, AllowAgentForwarding (SSH-7408)
- **APT Tools:** apt-listbugs, apt-listchanges (DEB-0810, DEB-0811)
- **PAM/Authentication:** Password rounds, strength testing, expiry (AUTH-9229, AUTH-9262, AUTH-9282)
- **Disk Layout:** Separate /home, /tmp, /var partitions (FILE-6310)
- **DNS Configuration:** Domain name, /etc/hosts entries (NAME-4028, NAME-4404)
- **Package Management:** Purge old packages, apt-show-versions (PKGS-7346, PKGS-7394)
- **Firewall:** Review iptables rules (FIRE-4513)
- **Logging:** External logging, deleted files in use (LOGG-2154, LOGG-2190)
- **Banners:** Legal warnings /etc/issue and /etc/issue.net (BANN-7126, BANN-7130)
- **Process Accounting:** Enable process accounting, sysstat (ACCT-9622, ACCT-9626)
- **Auditing:** Enable auditd (ACCT-9628)
- **File Integrity:** Install integrity monitoring tool (FINT-4350)
- **Automation Tools:** Check for system management tools (TOOL-5002)
- **File Permissions:** Restrict sensitive file permissions (FILE-7524)
- **Kernel Sysctl:** Tune sysctl values (KRNL-6000)
- **Compiler Hardening:** Restrict compiler access (HRDN-7222)

## Notes

- Sistema estable sin cambios significativos en seguridad desde baseline
- Todas las suggestions son mejoras preventivas, no problemas críticos
- Índice de hardening del 75% apropiado para workstation de desarrollo
- Próximo scan programado: próxima semana (cron healthcheck:lynis-scan-weekly)
