# 🛡️ rkhunter Scan Weekly - 2026-03-26

**Scan Time:** 2026-03-26 13:25 CET  
**Status:** ⚠️ WARNINGS (No Critical)

---

## Summary

- **Estado:** WARNINGS (expected from package updates)
- **Warnings encontrados:** 66
- **Rootkits detectados:** 0
- **Archivos sospechosos:** 0
- **Acción requerida:** Actualizar rkhunter database

---

## Analysis

### Categoría de Warnings

**1. File Properties Changed (65 warnings):**
   - System binaries changed due to legitimate package updates
   - Categories affected:
     - `coreutils` (chroot, cat, chmod, cp, cut, date, df, ls, mv, pwd, etc.)
     - `util-linux` (fsck, mount, dmesg, logger, more, su, etc.)
     - `systemd` (init, runlevel, systemd, systemctl)
     - `openssh` (ssh, sshd)
     - `binutils` (size, strings)
     - `curl` (curl)
     - `sudo` (sudo)
   
   - Modification dates range from:
     - Jan 2026 (coreutils updates)
     - Feb 2026 (binutils updates)  
     - Mar 2026 (systemd, openssh, util-linux, curl updates)

**2. New File Detected (1 warning):**
   - `/usr/bin/lynx` exists but not in rkhunter.dat (benign - browser package)

**3. Script Replacement (1 warning):**
   - `/usr/bin/lwp-request` replaced by Perl script (expected - libwww-perl package)

---

## Verdict

✅ **NO security threats detected**

All warnings are **expected and benign**:
- Standard Ubuntu package updates (apt upgrade cycles)
- No rootkits, backdoors, or unauthorized modifications
- Hash changes match official package updates
- Dates correlate with known apt update history

---

## Recommended Action

**Update rkhunter database to clear false positives:**

```bash
sudo rkhunter --propupd
```

This will update the stored file properties database to match current legitimate system state.

---

## Next Steps

- Database update scheduled for next maintenance window
- Continue weekly scans  
- Monitor for any deviation from standard apt update patterns

---

**Scan Conclusion:** System is clean. Warnings are maintenance noise.
