# Proposal: Critical Update Framework

## Problem

When an OpenClaw agent modifies system files (SSH config, firewall rules, service configs), there's no safety net. A bad change can lock you out of your own server.

## Solution

A framework for safely applying critical system changes with automatic backup, validation, and rollback.

### Workflow

```
1. --baseline    → Capture system health snapshot
2. --test FILE   → Validate change in sandbox copy
3. --apply FILE  → Apply with automatic backup + validation
4. --validate    → Run all health checks post-change
5. --rollback    → Revert to last known-good state
```

### Key Features

- **Automatic backups** before every change
- **Health baselines** (SSH, network, services, disk)
- **Sandbox testing** — validate syntax/config before applying
- **Auto-rollback** if validation fails after apply
- **Audit trail** — every change logged with timestamp and diff
- **Dry-run mode** — simulate without touching anything

### Usage

```bash
# Capture current system state
bash scripts/critical-update.sh --baseline

# Test a config change safely
bash scripts/critical-update.sh --test /etc/ssh/sshd_config

# Apply with safety net
bash scripts/critical-update.sh --apply /etc/ssh/sshd_config

# Check everything still works
bash scripts/critical-update.sh --validate

# Something broke? Rollback
bash scripts/critical-update.sh --rollback /etc/ssh/sshd_config
```

## Genericization Needed

- Replace default workspace path with `$OPENCLAW_WORKSPACE`
- Translate Spanish comments to English
- Make validation checks configurable
- Add support for non-Ubuntu systems (detect OS)

## Why This Should Be in OpenClaw

1. **Safety** — Agents modifying system files is inherently dangerous
2. **Self-hosting** — Many OpenClaw users run on VPS; this prevents lockouts
3. **Audit trail** — Know exactly what changed and when
4. **Confidence** — Users can let agents make changes knowing there's a rollback
