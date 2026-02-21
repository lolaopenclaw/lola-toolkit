# Proposal: Skill Security Audit Tool

## Problem

OpenClaw skills from ClawHub run with the same permissions as the agent. A malicious or poorly-written skill could:
- Exfiltrate data from the workspace
- Execute arbitrary commands
- Modify system files
- Access credentials stored in `.env`

There's currently no built-in way to vet skills before installation.

## Solution

A bash script (`skill-security-audit.sh`) that analyzes skills for security risks before installation, producing a risk score and detailed findings.

### What It Checks

| Category | Checks |
|----------|--------|
| **Network** | `curl`, `wget`, outbound connections, hardcoded IPs/URLs |
| **Filesystem** | Writes outside workspace, access to `/etc`, `~/.ssh`, etc. |
| **Execution** | `eval`, `exec`, process spawning, shell injection patterns |
| **Credentials** | Access to `.env`, token files, keyring, API keys |
| **Permissions** | `sudo`, `chmod 777`, setuid patterns |
| **Data exfil** | Base64 encoding + network, file uploads, piped outputs |

### Output

```
🔍 Skill Security Audit: example-skill
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Score: 72/100 (MODERATE RISK)

⚠️  WARNINGS (3):
  - Uses curl to fetch external resources (line 45)
  - Reads environment variables broadly (line 12)
  - Spawns subprocesses via exec (line 78)

✅ CLEAN (4):
  - No sudo/privilege escalation
  - No credential file access
  - No writes outside workspace
  - No eval/shell injection patterns

📋 Recommendation: Review flagged lines before installing.
```

### Usage

```bash
# Audit a skill before installing
bash scripts/skill-security-audit.sh my-skill-name

# Audit from a local path
bash scripts/skill-security-audit.sh ./path/to/skill/

# Strict mode (fail on any warning)
bash scripts/skill-security-audit.sh my-skill --strict

# JSON output for automation
bash scripts/skill-security-audit.sh my-skill --json
```

## Current Status

- ✅ Working locally with real skills
- ✅ Already uses `$OPENCLAW_WORKSPACE` env var
- ✅ English output
- 🔲 Needs: JSON output mode, `--strict` flag, test suite

## Why This Should Be in OpenClaw

1. **Security by default** — Every package manager has audit tools; OpenClaw should too
2. **Community trust** — Users can share skills knowing they'll be vetted
3. **Low risk to merge** — Standalone script, no core changes
4. **Extensible** — Rule-based, easy to add new checks
