# Accepted Security Risks

## Risk Register

### 1. Anthropic API Key (sk-ant-oat01) — Cannot Rotate
**Date accepted:** 2026-03-26  
**Accepted by:** Manu  
**Reason:** Token cannot be rotated (OAuth token tied to account)  
**Mitigation:**
- Key is in `.env` (perms 600) — not directly committed to git
- Only truncated reference (`sk-ant-oat01...`) appears in docs
- Monitor Anthropic usage for anomalies
- Added to nightly scanner allowlist (won't flag as CRITICAL)

**Review cadence:** Monthly — check if rotation becomes possible

---

*Add new accepted risks below with date, owner, reason, and mitigations.*
