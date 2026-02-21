# Skill Security Audit Tool

## Overview

A comprehensive bash script to analyze ClawHub skills for security risks **before installation**. It produces a risk score (0-100) and detailed findings to help users make informed decisions about which skills to install.

## Problem Statement

OpenClaw skills run with the same permissions as the agent itself. A malicious or poorly-written skill could:

- **Exfiltrate data** from the workspace, credentials, or system files
- **Execute arbitrary commands** on the host
- **Modify system files** or configuration
- **Steal API keys** and tokens stored in `.env` files
- **Inject prompts** into the agent's context

Currently, there's no built-in way to vet skills before installation. This tool fills that gap.

## Solution

`skill-security-audit.sh` analyzes skill code for security patterns and outputs a **risk score** and **findings**.

### Example Output

```bash
$ bash scripts/skill-security-audit.sh my-skill

🔍 Auditing skill: my-skill
   Path: /home/user/.openclaw/workspace/skills/my-skill

[1/5] Code Analysis...
[2/5] Credential Detection...
[3/5] Dependency Audit...
[4/5] Permission Analysis...
[5/5] Metadata Review...

===== SKILL SECURITY AUDIT =====
Skill:   my-skill
Version: 1.2.3
Author:  John Doe
Date:    2026-02-21

RISK SCORE: 42/100 — 🟢 BAJO (probably OK)

FINDINGS:
  ⛔ [HIGH] Found 2 network calls — review endpoints
  ⚠️  [MEDIUM] Config files may contain sensitive values
  ✅ [LOW] No eval() calls found
  ✅ [LOW] No hardcoded credentials found

Summary: 0 errors, 1 warnings, 8 clean
Status:  GREEN
```

### JSON Output

For CI/CD integration, output as JSON:

```bash
$ bash scripts/skill-security-audit.sh my-skill --json

{
  "skill": "my-skill",
  "version": "1.2.3",
  "author": "John Doe",
  "score": 42,
  "label": "🟢 BAJO (probably OK)",
  "status": "GREEN",
  "summary": {
    "errors": 0,
    "warnings": 1,
    "clean": 8
  },
  "findings": [
    {
      "severity": "HIGH",
      "message": "Found 2 network calls — review endpoints"
    },
    // ...
  ],
  "pass_strict": true,
  "installable": true
}
```

## Features

### Risk Scoring

| Range | Label | Meaning |
|-------|-------|---------|
| 0-24 | 🟢 VERDE | Install with confidence |
| 25-49 | 🟢 BAJO | Probably OK, minor concerns |
| 50-74 | 🟡 AMARILLO | Review before installing |
| 75-94 | 🟡 MEDIO | Needs thorough audit |
| 95-100 | 🔴 CRÍTICO | Do NOT install |

### Analysis Categories

| Category | Checks |
|----------|--------|
| **Code** | eval(), exec(), shell spawning, prompt injection, obfuscation patterns |
| **Credentials** | Hardcoded secrets, .env files, API keys, config files |
| **Dependencies** | npm packages (count, known vulnerabilities via npm audit) |
| **Permissions** | sudo usage, chmod 777, setuid, shell escaping |
| **Metadata** | SKILL.md validation, package.json integrity |

### Flags

```bash
# Standard usage
bash scripts/skill-security-audit.sh <SKILL_NAME|PATH>

# Options
--analyze       Full analysis (default)
--score         Only show risk score (integer output)
--json          JSON output for CI/CD
--strict        Fail (exit 1) if any warnings or errors detected
--report        Generate markdown report to memory/audits/
--detailed      Deep analysis with dependency tree
--all           Audit all installed skills
-h, --help      Show help and examples
```

### Environment Variables

- `OPENCLAW_WORKSPACE` — Base workspace path (default: `$HOME/.openclaw/workspace`)
- `STRICTNESS` — Set to `1` to enable strict mode globally (alternative to `--strict` flag)

## Usage Examples

### 1. Audit Before Installing

```bash
# Check a skill from ClawHub (already in workspace)
bash scripts/skill-security-audit.sh blogger

# Check a local skill path
bash scripts/skill-security-audit.sh ./my-custom-skill

# Get just the score (human-readable)
bash scripts/skill-security-audit.sh blogger --score
# Output: 23 — 🟢 VERDE (Install with confidence)
```

### 2. CI/CD Integration

```bash
# Get JSON output for automation
bash scripts/skill-security-audit.sh blogger --json > skill-report.json

# Fail if any issues detected
bash scripts/skill-security-audit.sh blogger --strict --json
# Exit code 1 if warnings/errors found

# Use in GitHub Actions
- name: Audit skill security
  run: |
    bash scripts/skill-security-audit.sh my-skill --strict --json
    if [ $? -ne 0 ]; then
      echo "Skill failed security audit!"
      exit 1
    fi
```

### 3. Bulk Auditing

```bash
# Audit all installed skills and generate reports
bash scripts/skill-security-audit.sh --all --report

# Check with strict rules
bash scripts/skill-security-audit.sh --all --json | jq '.[] | select(.pass_strict == false)'
```

## Implementation Details

### Design Principles

1. **Heuristic-based** — Uses pattern matching, not full static analysis
2. **Privacy-first** — Runs locally, no data leaves the workspace
3. **Extensible** — Easy to add new rules and checks
4. **Lenient defaults** — Flags issues without being overly strict
5. **Environment-aware** — Uses `$OPENCLAW_WORKSPACE` for portability

### Architecture

```
Main Script
├── analyze_code()            — Code patterns (eval, exec, network, obfuscation)
├── analyze_credentials()     — Secret detection (hardcoded, .env files)
├── analyze_dependencies()    — npm package audit
├── analyze_permissions()     — Privilege patterns (sudo, chmod)
├── analyze_skill_metadata()  — SKILL.md and package.json checks
├── generate_report()         — Human-readable output
├── generate_json()           — JSON for automation
└── main()                    — Entry point, argument parsing
```

## Testing

A comprehensive test suite validates all features:

```bash
# Run all tests
bash scripts/test-skill-security-audit.sh

# Expected: 15+ test cases covering
#   - Help/usage
#   - Skill detection (eval, credentials, network, .env)
#   - Output modes (human, JSON, score-only)
#   - Strict mode behavior
#   - Environment variable overrides
```

## Security Considerations

### What This Tool Does

✅ Detects common anti-patterns (eval, hardcoded secrets, unsafe I/O)
✅ Helps identify suspicious code patterns
✅ Provides a heuristic risk score
✅ Works offline, no external dependencies

### What This Tool Does NOT Do

❌ Perform full static code analysis (not a linter)
❌ Detect all possible vulnerabilities
❌ Execute untrusted code
❌ Replace manual code review for critical skills

**Use Case:** Pre-filter skills before deeper review. Use for:
- First-pass screening in ClawHub submission pipeline
- CI/CD gates for internal skill development
- User education (help people understand security risks)

**NOT suitable for:** Security-critical systems where perfect accuracy is required (always do manual review)

## Installation

### Prerequisites

- bash 4.0+
- python3 (for JSON parsing)
- jq (optional, for filtering results)

### Setup

```bash
# Copy script to OpenClaw scripts directory
cp scripts/skill-security-audit.sh ~/.openclaw/workspace/scripts/

# Or as a system command
ln -s /path/to/skill-security-audit.sh /usr/local/bin/openclaw-audit

# Make executable
chmod +x ~/.openclaw/workspace/scripts/skill-security-audit.sh
```

## Compatibility

- **OS:** Linux, macOS, WSL
- **Shell:** bash 4.0+
- **Python:** 3.6+
- **OpenClaw:** v2026.2.0+ (uses `$OPENCLAW_WORKSPACE` env var)

Tested on:
- Ubuntu 22.04 LTS, 24.04 LTS
- Debian 12
- macOS 12+

## Contributing

Found a gap in detection? Want to add a check?

1. **Add pattern to `analyze_*` functions** — Update relevant function to detect new pattern
2. **Add test case** — Update `test-skill-security-audit.sh` with example
3. **Submit PR** — Link issue, explain the vulnerability being detected

Example: Add detection for hardcoded AWS credentials

```bash
# In analyze_credentials():
local aws_count
aws_count=$(grep -rn 'AKIA[0-9A-Z]\{16\}' "$dir" 2>/dev/null | wc -l)
if [ "$aws_count" -gt 0 ]; then
    add_finding "CRITICAL" "Found $aws_count AWS access keys!" 30
fi
```

## Roadmap

- [ ] Integration with ClawHub submission pipeline
- [ ] GitHub Actions workflow for skill publishers
- [ ] Database of known-vulnerable skills/packages
- [ ] Formal static analysis backend (AST-based detection)
- [ ] IDE plugins for real-time skill vetting

## FAQ

**Q: Why not just use existing SAST tools?**  
A: They're designed for full applications, not skill bundles. This tool is lightweight, purpose-built, and requires zero configuration.

**Q: Can I override the risk score?**  
A: No — this is intentional. Scores reflect patterns found. If you disagree, submit a PR to adjust scoring logic.

**Q: Does this replace code review?**  
A: No. Use this as a first-pass filter, then always review critical skills manually.

**Q: Can I add custom rules?**  
A: Currently no, but it's extensible via PR. Community-contributed rules welcome.

## License

Same as OpenClaw project.

## Support

- **Issues:** GitHub Issues on openclaw/openclaw
- **Discussions:** GitHub Discussions
- **Contact:** OpenClaw Discord community
