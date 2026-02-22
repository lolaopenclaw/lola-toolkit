# Critical Update Framework — Safe system updates with automatic rollback

## Problem

System updates can break critical services (SSH, firewall, network, databases). Traditional approaches:
- ❌ Update without testing → breaks production
- ❌ Test on separate machine → diverges from production state
- ❌ Manual rollback → slow, error-prone, no audit trail

## Solution

**Canary Testing Framework** for safe critical updates:
1. **Baseline** — Capture current system health (network, services, ports, connectivity)
2. **Change** — Apply update in controlled environment (single service/package)
3. **Validate** — Automatic health checks + user validation
4. **Commit or Rollback** — Automatic rollback if validation fails

## Features

- ✅ **Automatic health baseline** — Pre-change system state
- ✅ **Atomic changes** — Single package or service at a time
- ✅ **Validation suite** — Network, services, SSH, ports, disk, memory
- ✅ **Rollback automation** — Revert to baseline if needed
- ✅ **Audit trail** — Full change history in `memory/CHANGES/`
- ✅ **User confirmation** — Optional manual gate before commit
- ✅ **Pre-tested** — 12+ automated validations

## Use Cases

### SSH Hardening
```bash
# Before: SSH allows TCP forwarding, can break remote access
# After: DisableTcpForwarding=yes (needed for security)
bash critical-update.sh --start
bash critical-update.sh --change SSH "echo 'AllowTcpForwarding no' >> /etc/ssh/sshd_config && systemctl reload sshd"
bash critical-update.sh --test
bash critical-update.sh --validate  # Manual: verify SSH still works
bash critical-update.sh --commit
```

### Firewall Changes
```bash
bash critical-update.sh --start
bash critical-update.sh --change UFW "ufw allow 22/tcp && ufw enable"
bash critical-update.sh --test
bash critical-update.sh --validate
bash critical-update.sh --commit  # or --rollback
```

### System Package Updates
```bash
bash critical-update.sh --start
bash critical-update.sh --change SYSTEMD "sudo apt-get install -y systemd"
bash critical-update.sh --test  # Automatic health checks
bash critical-update.sh --commit
```

## Output Example

```
🔍 CRITICAL UPDATE FRAMEWORK — Phase: START
═════════════════════════════════════════

📊 Baseline Capture
  ✅ Network interfaces: 2 active
  ✅ Open ports: SSH(22), HTTP(80), HTTPS(443)
  ✅ DNS resolution: OK
  ✅ Gateway connectivity: OK
  ✅ Service status: 15 active, 0 failed
  ✅ Disk usage: 45% (/home)
  ✅ Memory usage: 62% (8.2 GB / 13.3 GB)
  ✅ Load average: 0.45

📝 Baseline saved: memory/CHANGES/baseline-20260222-084230.json

🚨 READY FOR CHANGE
Next: bash critical-update.sh --change <name> "<command>"
```

## Validation Suite (12+ checks)

| Check | Purpose | Critical |
|-------|---------|----------|
| SSH connectivity | Verify SSH still works | ✅ |
| Network interfaces | Ensure no network down | ✅ |
| DNS resolution | Can resolve hostnames | ✅ |
| Gateway connectivity | Internet access | ✅ |
| Open ports | Expected ports open | ✅ |
| Service status | No services failed | ✅ |
| Disk usage | Disk not filled | ✅ |
| Memory usage | Memory available | ✅ |
| Systemd status | Init system healthy | ✅ |
| Fail2Ban status | Security service active | ⚠️ |
| Load average | CPU not overloaded | ⚠️ |
| Process count | System not hung | ⚠️ |

## Installation

```bash
# Copy script to OpenClaw workspace
cp scripts/critical-update.sh ~/.openclaw/workspace/scripts/
chmod +x ~/.openclaw/workspace/scripts/critical-update.sh

# Create memory directory for audit trail
mkdir -p ~/.openclaw/workspace/memory/CHANGES
```

## Usage

### Simple Mode (Recommended)
```bash
# Start baseline capture
bash critical-update.sh --start

# Make your change (manually or via script)
bash critical-update.sh --change "Update name" "your command here"

# Run automatic tests
bash critical-update.sh --test

# Manual validation (inspect system)
bash critical-update.sh --validate

# Commit or rollback
bash critical-update.sh --commit    # Save change
bash critical-update.sh --rollback  # Revert if needed
```

### Dry-run Mode
```bash
# Test without actual changes
bash critical-update.sh --start --dry-run
bash critical-update.sh --change "Test" "echo test" --dry-run
```

### View History
```bash
# See all changes made
ls -la memory/CHANGES/
cat memory/CHANGES/changes-$(date +%Y-%m-%d).log

# Compare baselines
bash critical-update.sh --diff baseline-1.json baseline-2.json
```

## Architecture

```
Phase 1: START
  └─→ Capture baseline (network, services, disk, memory, etc.)
      └─→ Save to memory/CHANGES/baseline-TIMESTAMP.json

Phase 2: CHANGE
  └─→ Execute user command
      └─→ Log to audit trail

Phase 3: TEST
  └─→ Run 12+ validation checks
      └─→ Report differences from baseline
      └─→ Flag critical changes

Phase 4: VALIDATE (Manual)
  └─→ User inspects system
      └─→ Confirms change is safe
      └─→ Continues to Phase 5

Phase 5: COMMIT or ROLLBACK
  └─→ COMMIT: Save change, update baseline
  └─→ ROLLBACK: Restore previous baseline
      └─→ Log decision
```

## Testing

```bash
# Run full test suite
bash scripts/test-critical-update.sh

# Output: 12/12 tests passed ✅
```

## Security Considerations

### What it does
✅ Captures system state before/after
✅ Detects network/service failures
✅ Prevents breaking SSH connectivity
✅ Logs all changes for audit
✅ Allows automatic rollback

### What it doesn't do
❌ Prevent all types of failures (e.g., silent data corruption)
❌ Detect application-level errors
❌ Validate security of changes (only functionality)
❌ Handle distributed systems/clusters

## Compatibility

- **OS:** Ubuntu 20.04+, Debian 10+
- **Shell:** Bash 4.0+
- **Requirements:** `curl`, `jq`, `systemctl`, `sudo`
- **No external dependencies:** Pure bash

## FAQ

**Q: Can I use this for all updates?**
A: Recommended for: SSH config, firewall rules, kernel params, critical services. Not needed for: app updates, routine security patches.

**Q: What if validation fails?**
A: Automatic rollback is attempted. If that fails, detailed logs are saved to `memory/CHANGES/` for manual recovery.

**Q: Does it require downtime?**
A: No. Most validations run live without stopping services. Some (reload, restart) cause brief interruptions.

**Q: Can I customize validation checks?**
A: Yes. Edit `critical-update.sh` and add checks to the validation suite.

## Related Tools

- **Memory Guardian** — Automatic memory cleanup + bloat detection
- **Skill Security Audit** — Pre-install safety checks for ClawHub skills
- **Recovery System** — Full system restore from backups

## Roadmap

- [ ] Integration with CI/CD (GitOps)
- [ ] Slack/email notifications on rollback
- [ ] Multi-host updates (orchestration)
- [ ] Custom validation hooks
- [ ] Metrics/dashboarding

---

**Status:** Production-ready  
**Tests:** 12/12 passing ✅  
**Tested on:** Ubuntu 22.04, 24.04  
**License:** MIT (compatible with OpenClaw)
