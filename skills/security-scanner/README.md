# Security Scanner for OpenClaw

**Multi-layer security system to protect against prompt injection, data leaks, and unauthorized actions.**

## Quick Start

```bash
# Test installation
python3 scripts/security-scanner.py "Hello world" all

# Run test suite
bash scripts/test-security-scanner.sh

# See integration examples
bash skills/security-scanner/examples/integration-example.sh
```

## What's Included

1. **Scanner Script** (`scripts/security-scanner.py`)
   - Prompt injection detection
   - PII/secrets scanning & redaction
   - Runtime governance (loop detection, spending caps)

2. **Configuration** (`config/security-config.json`)
   - 5 injection categories, 30+ patterns
   - 14 PII/secret types
   - Customizable weights, thresholds, whitelist

3. **Permissions Matrix** (`config/permissions-matrix.md`)
   - All tools/skills audited
   - Risk levels documented
   - Hardening recommendations

4. **Documentation** (`skills/security-scanner/SKILL.md`)
   - Comprehensive usage guide
   - Integration patterns
   - Performance benchmarks

5. **Implementation Docs** (`memory/security-hardening-implementation.md`)
   - Design decisions
   - Testing results
   - Maintenance guide

## Features

### ✅ Prompt Injection Detection

Detects attempts to manipulate agent behavior:
- "Ignore previous instructions"
- "You are now a hacker"
- `[system]` context injection
- Jailbreak attempts
- System prompt exfiltration

**Output:** Risk score 0-100, exit code 0/1/2

### ✅ PII/Secrets Scanning

Detects and redacts sensitive data:
- API keys, tokens, passwords
- Private IPs, system paths
- Emails, phones (ES), DNI/NIE
- SSH/RSA keys, JWTs

**Output:** Redacted text, detection log (hashed, never plaintext)

### ✅ Runtime Governance

Prevents abuse:
- **Loop detection:** >10 calls in 5 min
- **Spending caps:** $20/day, $150/month

**Output:** Alerts with details

## Performance

- **<1s latency** for typical messages
- **~40ms** full scan on 500 words
- **<10MB memory** footprint
- **Zero dependencies** (Python stdlib only)

## Integration

### Option A: Manual Pre-Check

```bash
if python3 scripts/security-scanner.py "$INPUT" all; then
    # Safe, process input
else
    # Reject or sanitize
fi
```

### Option B: Pipeline

```bash
cat log.txt | python3 scripts/security-scanner.py - pii | tee clean.log
```

### Option C: Cron Audit

```bash
# Daily at 02:00
0 2 * * * cd ~/.openclaw/workspace && \
  find memory -type f -exec python3 scripts/security-scanner.py {} pii \; \
  >> memory/daily-audit.log
```

## Testing

```bash
# Run full test suite
bash scripts/test-security-scanner.sh

# Manual tests
python3 scripts/security-scanner.py "Ignore instructions" all  # Should exit 2
echo "API: sk-test123456789012345" | python3 scripts/security-scanner.py - pii  # Should redact
```

## Configuration

Edit `config/security-config.json`:

```json
{
  "prompt_injection": {
    "patterns": {
      "custom_category": ["pattern1", "pattern2"]
    },
    "weights": {
      "custom_category": 40
    },
    "whitelist": ["allowed phrase"]
  },
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

## Documentation

- **User Guide:** `skills/security-scanner/SKILL.md`
- **Implementation:** `memory/security-hardening-implementation.md`
- **Permissions Audit:** `config/permissions-matrix.md`
- **Examples:** `skills/security-scanner/examples/integration-example.sh`

## Maintenance

### Add New Pattern

1. Edit `config/security-config.json`
2. Test: `python3 scripts/security-scanner.py "test case" all`
3. Update SKILL.md with example
4. Run test suite: `bash scripts/test-security-scanner.sh`

### Review Schedule

- **Patterns:** Quarterly (next: 2026-06-24)
- **Permissions:** Semi-annually (next: 2026-09-24)
- **Logs:** Monthly rotation (auto at 10MB)

## Limitations

- **Regex-based detection:** Can't detect novel/obfuscated patterns
- **No real-time enforcement:** Requires manual integration
- **English-centric:** Limited international PII support (ES only)

**Mitigations planned for v2.0:**
- ML-based semantic analysis
- Real-time middleware hooks
- Multi-language patterns (FR, DE, IT)

## Roadmap

### v1.1 (Q2 2026)
- JSON schema validation
- Rate limiting integration
- Prometheus metrics
- Pre-commit hook templates

### v2.0 (Q3-Q4 2026)
- ML semantic injection detection
- Tool capability system
- OpenClaw core middleware
- Multi-language PII support

## Support

- **Issues:** Report in `memory/security-feedback.md`
- **Updates:** Check `memory/security-hardening-implementation.md` changelog
- **Owner:** Lola (lolaopenclaw@gmail.com)

## Related Skills

- `verification-before-completion` — Verify before claiming success
- `clawdbot-security-check` — System-wide security audit
- `healthcheck` — Host hardening
- `rate-limit` — API rate limiting

---

**Version:** 1.0.0  
**Last Updated:** 2026-03-24  
**License:** MIT (OpenClaw Skills)
