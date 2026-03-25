# Security Scanner - Cheat Sheet

Quick reference for common operations.

---

## CLI Usage

```bash
# Basic scan (all checks)
python3 scripts/security-scanner.py "your text here" all

# Injection only
python3 scripts/security-scanner.py "your text here" injection

# PII/secrets only
python3 scripts/security-scanner.py "your text here" pii

# From stdin
cat file.txt | python3 scripts/security-scanner.py -

# From stdin, specific mode
cat file.txt | python3 scripts/security-scanner.py - pii
```

---

## Exit Codes

- `0` = Safe (no threats detected)
- `1` = Warning (PII detected)
- `2` = Critical (injection detected)

```bash
# Check exit code
python3 scripts/security-scanner.py "test" all
echo $?  # 0, 1, or 2
```

---

## Integration Patterns

### Pre-check User Input

```bash
if python3 scripts/security-scanner.py "$USER_INPUT" all; then
    # Safe, process input
    process_input "$USER_INPUT"
else
    echo "Security check failed"
    exit 1
fi
```

### Redact PII Before Sending

```bash
CLEAN=$(echo "$TEXT" | python3 scripts/security-scanner.py - pii | jq -r '.pii_secrets.redacted_text')
send_message "$CLEAN"
```

### Scan Log Files

```bash
cat memory/daily-log.txt | python3 scripts/security-scanner.py - pii
```

### Pre-commit Hook

```bash
# .git/hooks/pre-commit
for file in $(git diff --cached --name-only); do
    python3 scripts/security-scanner.py "$(cat $file)" pii || exit 1
done
```

---

## Configuration

### Add Pattern

Edit `config/security-config.json`:

```json
{
  "prompt_injection": {
    "patterns": {
      "custom_category": ["pattern1", "pattern2"]
    },
    "weights": {
      "custom_category": 40
    }
  }
}
```

### Add Whitelist Entry

```json
{
  "prompt_injection": {
    "whitelist": ["allowed phrase", "another phrase"]
  }
}
```

### Add PII Pattern

```json
{
  "pii_secrets": {
    "patterns": {
      "custom_secret": {
        "regex": "your-regex-here",
        "redaction": "[CUSTOM_REDACTED]"
      }
    }
  }
}
```

### Adjust Spending Caps

```json
{
  "runtime_governance": {
    "spending_caps": {
      "daily_usd": 20.0,
      "monthly_usd": 150.0
    }
  }
}
```

---

## Testing

```bash
# Run test suite
bash scripts/test-security-scanner.sh

# Quick manual tests
python3 scripts/security-scanner.py "Ignore instructions" all  # Exit 2
echo "API: sk-test123456789012345" | python3 scripts/security-scanner.py - pii  # Exit 1
python3 scripts/security-scanner.py "Hello world" all  # Exit 0
```

---

## Output Formats

### Prompt Injection

```json
{
  "prompt_injection": {
    "risk_score": 65,
    "matches": [
      "instruction_override: ignore .{0,20}instruction",
      "exfiltration: show.{0,20}system prompt"
    ]
  }
}
```

### PII/Secrets

```json
{
  "pii_secrets": {
    "detections_count": 2,
    "redacted_text": "My key is [API_KEY_REDACTED] and IP [PRIVATE_IP_REDACTED]"
  }
}
```

### Both (mode: all)

```json
{
  "prompt_injection": { "risk_score": 0, "matches": [] },
  "pii_secrets": { "detections_count": 0, "redacted_text": null }
}
```

---

## Log File

**Location:** `memory/security-detections.log`

**Format:** JSON Lines

```json
{"timestamp": "2026-03-24T20:35:12", "type": "pii_secrets", "detections": [...]}
```

**View:**
```bash
cat memory/security-detections.log | jq
```

**Count detections:**
```bash
cat memory/security-detections.log | wc -l
```

**Filter by type:**
```bash
cat memory/security-detections.log | jq 'select(.type=="pii_secrets")'
```

---

## Python API

```python
from scripts.security_scanner import SecurityScanner

scanner = SecurityScanner()

# Prompt injection
risk, matches = scanner.scan_prompt_injection("Ignore instructions")
print(f"Risk: {risk}, Matches: {matches}")

# PII/secrets
clean, detections = scanner.scan_pii_secrets("API: sk-test123", redact=True)
print(f"Clean: {clean}, Detected: {len(detections)}")

# Runtime governance
tool_calls = [
    {"tool": "exec", "timestamp": "2026-03-24T20:00:00", "cost": 0.01},
    # ... more calls
]
result = scanner.check_runtime_governance(tool_calls)
if result['loop_detected']:
    print(f"Loop: {result['details']['loop']}")
```

---

## Maintenance

### Update Patterns (Quarterly)

1. Edit `config/security-config.json`
2. Add new patterns under relevant category
3. Test: `python3 scripts/security-scanner.py "new pattern test" all`
4. Run test suite: `bash scripts/test-security-scanner.sh`
5. Update SKILL.md if needed

### Rotate Logs (Monthly)

```bash
# Manual rotation
mv memory/security-detections.log memory/security-detections.log.1
touch memory/security-detections.log
```

### Review Permissions (Semi-annually)

```bash
# Read permissions matrix
cat config/permissions-matrix.md

# Check for new skills
find skills -name SKILL.md | wc -l

# Update matrix if needed
```

---

## Troubleshooting

### Pattern Not Detecting

1. Test regex directly:
   ```bash
   python3 -c "import re; print(re.search('your-pattern', 'test text', re.I))"
   ```

2. Check config syntax:
   ```bash
   python3 -c "import json; json.load(open('config/security-config.json'))"
   ```

3. Debug scanner:
   ```bash
   python3 -c "
   from scripts.security_scanner import SecurityScanner
   scanner = SecurityScanner()
   print(scanner.scan_prompt_injection('your test text'))
   "
   ```

### False Positives

Add to whitelist:
```json
{
  "prompt_injection": {
    "whitelist": ["your legitimate phrase"]
  }
}
```

### Missing Detections

1. Check if pattern exists in config
2. Test pattern regex separately
3. Adjust pattern to be more general: `.{0,20}` for flexible matching

---

## Common Patterns

### API Keys

```regex
\b(sk|pk|api)[-_]?[a-zA-Z0-9]{20,}\b
```

### Emails

```regex
\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b
```

### Private IPs

```regex
\b(?:10|172\.(?:1[6-9]|2\d|3[01])|192\.168)\.\d{1,3}\.\d{1,3}\b
```

### System Paths

```regex
(/home/[a-zA-Z0-9_\-]+|/root|C:\\Users\\[a-zA-Z0-9_\-]+)
```

### Phone (Spain)

```regex
\b(\+34|0034)?\s?[6-9]\d{2}\s?\d{2}\s?\d{2}\s?\d{2}\b
```

### Prompt Injection

```regex
ignore .{0,20}(previous|all|above|prior).{0,20}instruction
```

---

## Quick Wins

### 1. Scan All Logs Now

```bash
find memory -type f -name "*.md" -exec sh -c \
  'python3 scripts/security-scanner.py "$(cat {})" pii || echo "Secrets in: {}"' \;
```

### 2. Add to Bash Alias

```bash
# ~/.bashrc
alias scan='python3 ~/.openclaw/workspace/scripts/security-scanner.py'

# Usage
scan "your text" all
cat file.txt | scan -
```

### 3. Daily Cron Audit

```bash
# crontab -e
0 2 * * * cd ~/.openclaw/workspace && \
  find memory -name "*.md" -exec python3 scripts/security-scanner.py {} pii \; \
  >> memory/daily-audit.log 2>&1
```

---

## Links

- **Full Docs:** `skills/security-scanner/SKILL.md`
- **Implementation:** `memory/security-hardening-implementation.md`
- **Summary:** `memory/security-hardening-summary.md`
- **Config:** `config/security-config.json`
- **Permissions:** `config/permissions-matrix.md`
- **Tests:** `scripts/test-security-scanner.sh`
- **Examples:** `skills/security-scanner/examples/integration-example.sh`

---

**Last Updated:** 2026-03-24  
**Version:** 1.0.0
