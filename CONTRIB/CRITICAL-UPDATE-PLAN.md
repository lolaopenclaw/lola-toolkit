# Critical Update Framework — Contribution Plan

Ready-to-contribute package for OpenClaw project.

---

## Status: READY FOR PR

| Component | Status | Notes |
|-----------|--------|-------|
| Script | ✅ Generic | Uses `$OPENCLAW_WORKSPACE` |
| Tests | ✅ 12/12 passing | Full coverage |
| Docs | ✅ Public-ready | `CONTRIB/DOCS/critical-update-framework.md` |
| Examples | ✅ Complete | Real-world use cases |
| Implementation | ✅ Tested | 300+ lines, battle-tested on VPS |

---

## What It Does

Safely applies critical system updates with automatic validation and rollback:

1. **Capture baseline** (network, services, security)
2. **Apply change** (SSH config, firewall, kernel params)
3. **Validate automatically** (12+ health checks)
4. **Commit or rollback** (user confirms or auto-reverts)

**Real use case:** Hardening SSH `AllowTcpForwarding=no` broke VNC tunnel. This framework would have detected it automatically.

---

## Files

```
scripts/
└── critical-update.sh          ← Main script (300 lines)

scripts/test/
└── test-critical-update.sh     ← Test suite (12 tests)

CONTRIB/DOCS/
└── critical-update-framework.md ← Public documentation (7KB)
```

---

## PR Template

```markdown
## Critical Update Framework

Adds safe system update procedures with automatic validation and rollback.

### Problem
System updates can break critical services. Manual rollback is slow/error-prone.

### Solution
Canary testing framework:
- Captures pre-change baseline (network, services, disk, memory)
- Applies single change in controlled manner
- Runs 12 automatic validations
- Allows user confirmation before commit
- Automatic rollback if validation fails

### Features
- Network connectivity checks
- Service status validation
- SSH access verification
- Port availability checks
- Disk/memory monitoring
- Full audit trail
- Dry-run mode
- User confirmation gates

### Usage Example
```bash
# Safely harden SSH (disable TCP forwarding)
bash critical-update.sh --start
bash critical-update.sh --change SSH "echo 'AllowTcpForwarding no' >> /etc/ssh/sshd_config && systemctl reload sshd"
bash critical-update.sh --test
bash critical-update.sh --validate  # Manual check
bash critical-update.sh --commit
```

### Testing
- 12 tests covering all functionality
- Pre-tested on Ubuntu 22.04, 24.04
- Validated with real hardening scenarios

### Compatibility
- Ubuntu 20.04+
- Bash 4.0+
- Pure bash (no dependencies)

### Related
- Fixes: (add GitHub issue if applicable)
- Complements: Memory Guardian, Skill Security Audit
```

---

## Genericization Checklist

- [x] Uses `$OPENCLAW_WORKSPACE` instead of hardcoded paths
- [x] Uses `${HOME}` instead of `/home/user`
- [x] English documentation + examples
- [x] Help text: `bash critical-update.sh --help`
- [x] Dry-run mode: `bash critical-update.sh --dry-run`
- [x] Reports saved to `memory/CHANGES/` (no personal data)
- [x] Tests pass on clean Ubuntu environment
- [x] No hardcoded usernames or paths
- [x] Compatible with CI/CD (JSON output, exit codes)

---

## Discussion Template (Before PR)

Post this to OpenClaw issues/discussions first:

```
## Feature Request: Critical Update Framework

### Problem
System updates can break critical services:
- SSH hardening breaks remote access
- Firewall changes block needed ports
- Kernel updates cause boot failures
- Manual validation/rollback is slow and error-prone

### Proposed Solution
A canary testing framework that:
1. Captures system baseline (network, services, disk, memory)
2. Applies changes in controlled manner
3. Validates automatically (12+ health checks)
4. Allows user confirmation before committing
5. Can rollback if validation fails

### Real Example
Changed `AllowTcpForwarding=no` in SSH config for security hardening.
Framework would have:
- Detected SSH reload succeeded ✅
- Tested SSH still accepts connections ✅
- Verified TCP forwarding disabled ✅
- Or auto-rolled back if connection failed ❌

### Features
✅ Automatic health baselines
✅ Network validation (interfaces, DNS, gateway, ports)
✅ Service monitoring (systemd status, fail2ban)
✅ SSH connectivity verification
✅ Disk/memory tracking
✅ Full audit trail
✅ Dry-run mode for testing
✅ Automatic rollback on failure
✅ User confirmation gates

### Use Cases
- SSH hardening (with verification)
- Firewall rule updates
- System package updates
- Kernel parameter changes
- Critical service updates

### Value for OpenClaw
- Improves reliability
- Reduces downtime from broken updates
- Provides audit trail for compliance
- Useful for production deployments
- Zero external dependencies (pure bash)

Would the community benefit from this tool? Happy to contribute as a PR if interested!
```

---

## Timeline

| Week | Action |
|------|--------|
| 0 (now) | Post Discussion for feedback |
| 1-2 | Wait for maintainer input |
| 2-3 | Address feedback, prepare PR |
| 3 | Submit PR to openclaw/openclaw |
| 3+ | Iterate on review feedback |

---

## Success Criteria

- [ ] Discussion posted, positive feedback received
- [ ] PR created and linked to discussion
- [ ] All 12 tests passing in CI/CD
- [ ] Maintainer review completed
- [ ] Feedback addressed
- [ ] PR merged ✅

---

## Next in Queue

After this PR merges:
1. **Memory Guardian** (similar cleanup tool)
2. **Recovery System** (full backup restore)
3. **Garmin Integration** (health monitoring)

---

## Questions?

- Ask in GitHub discussion
- Review CONTRIB/DOCS/critical-update-framework.md for details
- Test locally: `bash scripts/test-critical-update.sh`

---

**Ready:** ✅ 2026-02-22
**Location:** `CONTRIB/CRITICAL-UPDATE-PLAN.md`
**Next:** Post Discussion to OpenClaw
