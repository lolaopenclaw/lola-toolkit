# Lynis Security Scan — 2026-03-23

**Timestamp:** Monday, March 23rd, 2026 — 9:02 AM (Europe/Madrid)

## Results

- **Hardening Index:** 75%
- **Warnings:** 0
- **Suggestions:** 31
- **Command:** `sudo lynis audit system --quick --quiet`

## Baseline Note

This is the **first scan** in this cron job. No previous scan exists at `memory/2026-02-20-lynis-initial-scan.md` to compare against.

## Top Suggestions (Priority Areas)

1. **Boot Security:** Set GRUB boot loader password (BOOT-5122)
2. **SSH Hardening:** Consider restricting TCP forwarding, agent forwarding, and TCP keep-alive (SSH-7408)
3. **APT Tools:** Install apt-listbugs and apt-listchanges (DEB-0810, DEB-0811)
4. **PAM/Authentication:** Add password strength testing and expiration policies (AUTH-9262, AUTH-9282)
5. **Disk Layout:** Consider separate partitions for /home, /tmp, /var (FILE-6310)
6. **File Integrity:** Install a monitoring tool like AIDE or Tripwire (FINT-4350)
7. **Auditing:** Enable auditd and sysstat (ACCT-9628, ACCT-9626)

## Next Steps

- Create baseline: `memory/2026-02-20-lynis-initial-scan.md` with this data for future comparisons
- Weekly cron will compare hardening_index and alert on regression
- No critical issues detected; all are improvement suggestions
