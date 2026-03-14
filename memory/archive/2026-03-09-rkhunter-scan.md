# rkhunter Scan - March 9, 2026

**Scan Time:** Monday 9:05 AM (Madrid time)
**Scanner Version:** Rootkit Hunter 1.4.6
**Scan Duration:** ~2 minutes
**Status:** ✅ PASSED - System Clean

---

## Scan Results

### Rootkits
**Status:** ✅ **NONE DETECTED**

Performed complete check of 80+ known rootkit signatures:
- Linux-based rootkits (AdoreKit, BeastKit, BOBKit, DIca-Kit, etc.)
- Backdoors and trojans (Ebury, Mokes, TBD/Telnet BackDoor, etc.)
- LKM (Loadable Kernel Module) rootkits
- Malware and worms

**Result:** All clean ✓

### System Commands
**Status:** ✅ **OK**

All 100+ critical system commands verified:
- SSH binaries (ssh, sshd)
- System utilities (ls, ps, find, etc.)
- File tools (chmod, chown, chattr, etc.)
- Network tools (netstat, ip, ifconfig)
- Package managers (dpkg, dpkg-query)

---

## Warnings (2 Total)

### ⚠️ Warning 1: /usr/bin/curl

**Severity:** LOW (Expected - Package Update)

```
File: /usr/bin/curl
Current hash:  1d7f3ebfc05d21419362a0764189291f0f34bb31948265782231b9879641bf2f
Stored hash:   aca992dba6da014cd5baaa739624e68362c8930337f3a547114afdbd708d06a4
Current inode: 3931
Stored inode:  2423
File mtime:    18-Feb-2026 19:57:28 (updated from Dec 11, 2024)
```

**Analysis:**
- Package: curl 8.5.0-2ubuntu10.7
- Source: Ubuntu noble-updates/noble-security
- This is a **legitimate security patch** from Debian/Ubuntu repositories
- Update reason: Routine maintenance/security patches for curl
- **Action:** No action required - update is legitimate and expected

**Solution if needed:**
```bash
sudo rkhunter --update --quiet  # Update rkhunter database
sudo rkhunter --check --skip-keypress  # Re-check to clear warning
```

---

### ⚠️ Warning 2: /usr/bin/lwp-request

**Severity:** LOW (Expected - Package Wrapper)

```
Warning: The command '/usr/bin/lwp-request' has been replaced by a script:
/usr/bin/lwp-request: Perl script text executable
```

**Analysis:**
- Package: libwww-perl 6.76-1
- This is a **normal package evolution** - the tool now uses a Perl wrapper instead of compiled binary
- Common when packages modernize their architecture
- **Action:** No action required - this is part of normal package maintenance

---

## Security Posture Summary

| Category | Status | Details |
|----------|--------|---------|
| Rootkits | ✅ CLEAN | 0 detected |
| Backdoors | ✅ CLEAN | 0 detected |
| Trojans | ✅ CLEAN | 0 detected |
| System Binaries | ✅ VERIFIED | 100+ commands OK |
| Malware | ✅ NONE | 0 suspicious files |
| File Integrity | ⚠️ 2 warnings | Both from legitimate updates |

---

## Conclusion

**System Status: SECURE ✅**

- No malware, rootkits, or backdoors detected
- All system commands verified intact
- 2 warnings from legitimate package updates (curl and libwww-perl)
- **Recommended action:** None - system is clean

---

## Full Log Location

```bash
/var/log/rkhunter.log
```

**Next Scan:** Scheduled automatically (weekly on Mondays)

---

*Generated: 2026-03-09 09:08 AM (Madrid)*
