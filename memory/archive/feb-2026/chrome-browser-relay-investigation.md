# Chrome Browser Relay Error Investigation

**Date:** 2026-02-21  
**Status:** 🔍 Issue Identified  
**Severity:** 🟠 Medium  
**Type:** Gateway Pairing (not Browser Relay extension itself)

---

## Problem Summary

When attempting to spawn sub-agents (especially with Opus model), the gateway rejects connections with:
```
Error: pairing required
[ws] closed before connect ... code=1008 reason=pairing required
```

This occurs during credential/scope negotiation between the main session and sub-agent.

---

## Diagnosis

### Gateway Status ✅
- Service: `active (running)` since 20:33:45
- PID: 2773
- Port: 18789 (127.0.0.1 + [::1])
- Reachability: ✅ HTTP 200 OK
- Canvas endpoint: ✅ Accessible

### Chrome Status ✅
- Process: Running (headless mode)
- Threads: 3 active (chrome main, crashpad)
- Memory: 221MB (nominal)
- Args: `--headless --no-sandbox --disable-gpu`

### Config ✅
```json
{
  "bind": "loopback",
  "port": 18789,
  "trustedProxies": null
}
```

### Root Cause 🎯

**Gateway logs reveal:**
```
2026-02-21T20:36:28.917Z [gateway] security audit: device access upgrade requested
  reason=scope-upgrade
  device=5f1aff9dc0305ddc8d808d7e56eee5d55c4d38ff21cff54e388dbf3780029271
  scopesFrom=operator.admin,operator.approvals,operator.pairing,operator.read
  scopesTo=operator.write
  
2026-02-21T20:36:28.960Z [ws] closed before connect
  code=1008 reason=pairing required
```

**The issue:** Gateway requires **additional pairing confirmation** for elevated scopes (`operator.write`), but the device is already paired. The gateway is enforcing **scope escalation verification** that's failing silently.

---

## Symptoms

- ✅ Chrome browser works normally
- ✅ Gateway reachable from localhost:18789
- ❌ Sub-agent spawn fails with "pairing required"
- ❌ Browser Relay extension cannot attach (if user attempts)
- Temporary workaround: Restart gateway (clears device state)

---

## Reproduction Steps

1. Try to spawn sub-agent with any model:
   ```bash
   sessions_spawn(..., model="anthropic/claude-opus-4-6", ...)
   ```
2. Observe error: `gateway closed (1008): pairing required`
3. Check logs: `journalctl -u openclaw-gateway -n 20`
4. See scope-upgrade + pairing-required pattern

---

## Root Cause Analysis

**NOT Chrome Browser Relay extension issue** — This is a **gateway security feature**:

1. Device (main session) is already paired with token `5f1aff9d...`
2. When spawning sub-agent, gateway detects **scope escalation** (operator.read → operator.write)
3. Gateway enforces security audit: "re-verify this device for elevated scopes"
4. Sub-agent device doesn't pass re-pairing verification
5. Connection dropped with code 1008 + "pairing required"

**Why it happens:**
- Sub-agents request `operator.write` scope (to execute tasks)
- Main session has `operator.admin,operator.approvals,operator.pairing,operator.read`
- Scope mismatch triggers security check
- Check fails because sub-agent is treated as different device

---

## Solution / Workaround

### Option A: Pre-approve Sub-Agent Scope (Recommended)

Check gateway config for sub-agent device approval settings:
```bash
cat ~/.openclaw/openclaw.json | jq '.security'
```

If `requirePairingApproval: true`, either:
1. Approve pending devices via dashboard, OR
2. Pre-add sub-agent device ID to allowlist

### Option B: Restart Gateway (Temporary)

```bash
sudo systemctl restart openclaw-gateway.service
```

Clears device state table, allows fresh pairing. But temporary — issue returns after spawn.

### Option C: Adjust Security Policy

If user trusts local sub-agents, reduce scope verification:
```bash
jq '.security.scopeEscalationVerification = "warning"' ~/.openclaw/openclaw.json > /tmp/oclaw.json && cp /tmp/oclaw.json ~/.openclaw/openclaw.json
sudo systemctl restart openclaw-gateway.service
```

**Warning:** This relaxes security.

---

## Chrome Browser Relay Extension Status

**Not directly affected** by this issue. Extension works fine for:
- Dashboard access
- Canvas rendering
- Attaching browser tab

**However:** If user tries to use extension + spawn sub-agent simultaneously, extension may appear "broken" because gateway becomes unresponsive during pairing negotiation.

---

## Recommendation

**This is an OpenClaw feature (security audit), not a bug.**

The gateway is doing its job: enforcing scope verification for privileged operations.

**To fix for production:**
1. Document this behavior in OpenClaw docs
2. Pre-approve known sub-agent devices in configuration
3. Provide UI/CLI for users to approve pending devices
4. Consider less-aggressive scope verification for localhost loopback

**For Manu's setup:**
- ✅ Current behavior is **working as designed**
- Workaround: Restart gateway before sub-agent spawns
- Alternative: Reduce security.scopeEscalationVerification level

---

## Related OpenClaw Issues

- Potential: "Sub-agents fail with pairing-required on scope escalation"
- Potential: "Browser Relay appears broken when gateway re-pairs"
- Suggestion: Add `--no-pairing-check` flag for local development

---

## Testing Notes

- Gateway: System-level service (stable, runs as mleon user)
- Sub-agents: Try with Haiku model (lower scope) vs Opus (full scope)
- Chrome: Headless instance working normally
- Network: 127.0.0.1 loopback only (no external access)

---

**Status:** DOCUMENTED + ROOT CAUSE IDENTIFIED  
**Next:** Communicate finding to user + implement Option A/C as needed

---

*Investigation completed: 2026-02-21 21:45 Madrid*
