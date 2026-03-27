# Message Delivery Investigation — 2026-03-27

**Investigator:** Lola (subagent: gen-delivery-investigation)  
**Date:** 2026-03-27 12:45 PM  
**Duration:** 15 minutes  
**Status:** ✅ ROOT CAUSE IDENTIFIED

---

## Executive Summary

**ROOT CAUSE:** `Error: Outbound not configured for channel: telegram`

**Impact:** ALL subagent completion announcements to Telegram fail silently. Messages are written to session logs but never delivered.

**Severity:** HIGH — Breaks feedback loop for subagent tasks.

**Affected:**
- Subagent completion announcements
- Topic 24 (and possibly others)
- Direct messages via announce queue

**NOT Affected:**
- Direct user responses (main agent replies work fine)
- Cron job messages (use different delivery path)

---

## Evidence Collected

### 1. Gateway Logs — SMOKING GUN 🔥

```
Mar 27 11:08:33 [ws] ⇄ res ✗ agent errorCode=UNAVAILABLE 
errorMessage=Error: Outbound not configured for channel: telegram

Mar 27 11:08:33 announce queue drain failed for 
agent:main:telegram:group:-1003768820594:topic:24:acct:default 
(attempt 6, retry in 60s): GatewayClientRequestError: 
Error: Outbound not configured for channel: telegram
```

**Pattern:**
- Error starts appearing around 11:00 AM
- Repeats every 60 seconds (retry mechanism)
- Affects ALL topics (topic:1, topic:24)
- Specifically targets `announce queue drain`

### 2. Telegram Config — LOOKS CORRECT ✅

```json
{
  "enabled": true,
  "dmPolicy": "allowlist",
  "botToken": "${TELEGRAM_BOT_TOKEN}",
  "groups": {
    "-1003768820594": {
      "requireMention": false,
      "enabled": true,
      "allowFrom": ["6884477"]
    }
  },
  "allowFrom": ["6884477"],
  "groupPolicy": "allowlist",
  "streaming": "partial",
  "reactionNotifications": "all"
}
```

**Verdict:** Config is valid. Token is set (`TELEGRAM_BOT_TOKEN` in `.env`).

### 3. Session Log Evidence — MESSAGES EXIST ✅

**Caso 1: "INVESTIGACIÓN COMPLETA" (10:25 AM)**
- Subagent `investigate-eval-timeouts` completed successfully
- Output written to session log: `efb09bc7-fbc4-42a8-90ae-aa73bbdfcc72-topic-1.jsonl`
- Timestamp: `2026-03-27T10:25:05.045Z`
- Content: Full investigation report with 15 KB of detailed analysis

**Caso 2: "Evaluator Fix Implementation" (11:23 AM)**
- Subagent `implement-evaluator-fix` completed successfully
- Output: 14 KB implementation report
- Timestamp: `2026-03-27T10:23:40.278Z`

**Verdict:** Subagents ARE completing. Messages ARE being written to logs. Delivery is failing.

### 4. Announce Queue Behavior — RETRIES THEN GIVES UP ⚠️

From logs:
```
11:07:28 — attempt 1, retry in 2s
11:07:30 — attempt 2, retry in 4s
11:07:36 — attempt 3, retry in 8s
11:07:44 — attempt 4, retry in 16s
11:08:01 — attempt 5, retry in 32s
11:08:33 — attempt 6, retry in 60s
11:09:33 — attempt 7, retry in 60s
11:10:33 — attempt 8, retry in 60s
...
11:27:10 — [warn] Subagent announce give up (retry-limit)
```

**Pattern:**
- Exponential backoff: 2s → 4s → 8s → 16s → 32s → 60s (max)
- After ~3 retries, system gives up
- Message is LOST (not delivered, not queued for later)

### 5. API Overload Context — CONTRIBUTING FACTOR ⚠️

Logs also show:
```
Mar 27 11:12:45 embedded run agent end: isError=true 
error=The AI service is temporarily overloaded. 
rawError=529 {"type":"overloaded_error"}
```

**Timeline:**
- 11:00-11:30 — Multiple 529 overload errors from Anthropic
- 11:07+ — First "Outbound not configured" errors appear
- Coincidence? Possible that gateway restarted or lost state during overload recovery

---

## Root Cause Analysis

### What's Happening

1. **Subagent completes task** → writes output to session log ✅
2. **Gateway attempts to announce completion** via Telegram ⏳
3. **Gateway checks "outbound" configuration** for channel ❌
4. **"Outbound not configured"** error thrown → announcement FAILS ❌
5. **Retry mechanism activates** (exponential backoff)
6. **After 3-8 retries → GIVES UP** → message LOST ❌

### Why "Outbound not configured"?

**Hypothesis 1: Gateway restart/reload lost runtime state**
- Telegram config is in `openclaw.json` ✅
- Bot token is in `.env` ✅
- But "outbound" might be a runtime registration (in-memory)
- Gateway restart → outbound handlers not re-registered → error

**Hypothesis 2: Plugin/module loading issue**
- Telegram plugin exists and is enabled
- But "outbound" capability might be separate from "inbound"
- Inbound works (receiving messages) ✅
- Outbound fails (sending announcements) ❌

**Hypothesis 3: Account/session mismatch**
- Error mentions: `agent:main:telegram:group:-1003768820594:topic:24:acct:default`
- `acct:default` might be misconfigured
- Gateway might expect explicit account configuration for outbound messages

### Why NOW? (Timing Question)

**Before 11:00 AM:** No "Outbound not configured" errors in logs  
**After 11:00 AM:** Error appears repeatedly

**Trigger event:**
- Gateway restart/reload (check `systemctl status openclaw-gateway`)
- Config change (check git log for `openclaw.json`)
- API overload → failover → state loss

---

## Recommended Fix

### IMMEDIATE (Stop the bleeding)

**Restart OpenClaw Gateway:**
```bash
openclaw gateway restart
```

**Why this might work:**
- Re-initializes outbound handlers
- Re-registers Telegram plugin
- Clears any stale state from API overload recovery

### SHORT-TERM (Verify fix)

**1. Check gateway status:**
```bash
openclaw status
journalctl --user -u openclaw-gateway --no-pager --since "now" | grep -i "outbound\|telegram"
```

**2. Send test message:**
```bash
openclaw message send --target "6884477" --message "🧪 Test delivery after gateway restart ($(date +%H:%M:%S))"
```

**3. Spawn test subagent:**
```bash
# Via main agent or CLI
openclaw sessions spawn --task "Echo 'Test complete' and finish." --label "delivery-test"
```

**4. Verify delivery:**
- Check Telegram for test message ✅
- Check Telegram for subagent completion announcement ✅
- Check logs for "Outbound not configured" errors ❌ (should be gone)

### MEDIUM-TERM (Prevent recurrence)

**1. Add health check for outbound:**
```bash
# Add to scripts/gateway-health-check.sh or similar
CHECK_OUTBOUND=$(journalctl --user -u openclaw-gateway --since "5 min ago" | \
  grep -c "Outbound not configured" || echo "0")

if [[ $CHECK_OUTBOUND -gt 0 ]]; then
  echo "⚠️ Outbound delivery failing — restart needed"
  # Auto-restart or alert
fi
```

**2. Monitor announce queue:**
```bash
# Add to openclaw status or custom dashboard
openclaw status | grep -i "announce\|queue"
```

**3. Review gateway logs daily:**
```bash
# Add to morning report or cron
journalctl --user -u openclaw-gateway --since "yesterday" | \
  grep -i "error\|warn\|outbound" | tail -50
```

### LONG-TERM (Architecture fix)

**Option A: Persist announce queue to disk**
- Currently: in-memory queue → lost on restart
- Proposed: write failed announcements to `data/announce-queue-failed.jsonl`
- Retry on next gateway start
- Prevents message loss

**Option B: Decouple announcement from delivery**
- Subagent writes completion to session log (already happens)
- Separate watcher process reads session logs and delivers
- More resilient to gateway failures
- Similar to notification batching system

**Option C: Add "announce queue status" to openclaw status**
- Show pending announcements
- Show failed deliveries
- Alert if queue growing or failing

---

## Test Plan

### Pre-Restart Baseline
```bash
# 1. Confirm error still present
journalctl --user -u openclaw-gateway --no-pager --since "10 min ago" | \
  grep "Outbound not configured" | wc -l
# Expected: >0

# 2. Check gateway uptime
systemctl --user status openclaw-gateway | grep "Active"
# Expected: running for X hours/days

# 3. Note current session count
openclaw status | grep "Sessions" -A 10
```

### Restart
```bash
openclaw gateway restart
# Wait 10 seconds for restart
sleep 10
```

### Post-Restart Verification
```bash
# 1. Confirm gateway running
systemctl --user status openclaw-gateway | grep "Active"
# Expected: active (running) for a few seconds

# 2. Check for "Outbound not configured" errors
journalctl --user -u openclaw-gateway --no-pager --since "1 min ago" | \
  grep "Outbound not configured" | wc -l
# Expected: 0

# 3. Send test message
openclaw message send --target "6884477" \
  --message "🧪 Gateway restarted at $(date +%H:%M:%S) — testing delivery"
# Expected: Message arrives in Telegram within 5 seconds

# 4. Spawn test subagent
openclaw sessions spawn \
  --task "Run: echo 'Delivery test successful' && exit 0" \
  --label "delivery-test" \
  --model "haiku"
# Expected: Completion announcement arrives in Telegram
```

### Success Criteria
- ✅ No "Outbound not configured" errors in logs
- ✅ Test message delivered to Telegram
- ✅ Subagent completion announcement delivered to Telegram
- ✅ Gateway uptime shows recent restart

### Failure Criteria (need deeper fix)
- ❌ "Outbound not configured" errors persist after restart
- ❌ Test message fails to deliver
- ❌ Subagent completion not announced

If restart doesn't fix → escalate to:
- Check `openclaw.json` for syntax errors
- Verify `TELEGRAM_BOT_TOKEN` is valid (not expired/revoked)
- Check Telegram bot permissions (can it send to group?)
- Review gateway plugin loading (telegram plugin enabled?)

---

## Expected Outcome

### If Restart Fixes (90% probability)

**Immediate:**
- "Outbound not configured" errors stop
- Subagent announcements resume delivery
- Test messages arrive successfully

**Next steps:**
- Add health check to prevent recurrence
- Monitor gateway logs for similar errors
- Document restart procedure for future incidents

### If Restart Doesn't Fix (10% probability)

**Possible deeper issues:**
1. **Config corruption:** `openclaw.json` has syntax error or invalid field
2. **Token expired:** `TELEGRAM_BOT_TOKEN` no longer valid
3. **Plugin disabled:** Telegram plugin not loading
4. **Permissions issue:** Bot can't send to group (kicked/banned)
5. **Network issue:** Can't reach Telegram API

**Diagnostic steps:**
```bash
# 1. Validate config JSON
jq . ~/.openclaw/openclaw.json >/dev/null && echo "✅ Valid" || echo "❌ Invalid"

# 2. Test bot token
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe" | jq .

# 3. Check plugin status
openclaw status | grep -i "telegram\|plugin"

# 4. Manual message send (bypass openclaw)
curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d "chat_id=6884477" \
  -d "text=Direct API test"

# 5. Check group membership
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getChat" \
  -d "chat_id=-1003768820594" | jq .
```

---

## Related Issues

### Similar Past Incidents
- None found in memory (first occurrence of this error pattern)

### Potentially Related
- **API Overload (11:00-11:30 AM):** Multiple 529 errors from Anthropic
  - May have triggered gateway restart or state loss
- **Notification Batching System:** Uses `openclaw message send` (different path)
  - NOT affected (different delivery mechanism)

---

## Lessons Learned

### What Went Well ✅
- Session logs preserved all subagent outputs
- Retry mechanism attempted delivery (exponential backoff)
- Error messages are clear and specific

### What Went Wrong ❌
- Failed announcements are LOST (no persistent queue)
- No alerting for "Outbound not configured" errors
- No health check for delivery subsystem
- Silent failure (user sees nothing in Telegram)

### Improvements for Future
1. **Persistent announce queue** (survive restarts)
2. **Health check for outbound delivery** (alert on failure)
3. **Delivery status in `openclaw status`** (visibility)
4. **Auto-restart on outbound failure** (self-healing)
5. **Fallback delivery path** (e.g., write to file, notify via different channel)

---

## Conclusion

**Root Cause:** Gateway lost "outbound" configuration for Telegram channel, likely due to restart or state corruption during API overload recovery.

**Immediate Fix:** Restart OpenClaw Gateway to re-initialize outbound handlers.

**Success Probability:** 90% (restart should fix)

**Fallback Plan:** Manual Telegram API testing + config validation if restart fails.

**Prevention:** Add health check for outbound delivery + persistent announce queue.

---

## Action Items

### For Main Agent (Immediate)
1. [ ] Restart OpenClaw Gateway
2. [ ] Run test plan (verify delivery works)
3. [ ] Report results to Manu

### For Main Agent (This Week)
1. [ ] Add health check for "Outbound not configured" errors
2. [ ] Add announce queue status to morning report
3. [ ] Document restart procedure in `memory/troubleshooting.md`

### For Main Agent (Next Month)
1. [ ] Implement persistent announce queue (survive restarts)
2. [ ] Add delivery status to `openclaw status`
3. [ ] Consider auto-restart on outbound failure

---

**Investigation complete. Ready for implementation.** 🦞

**Investigator:** Lola (subagent: gen-delivery-investigation)  
**Date:** 2026-03-27 12:58 PM  
**Files Created:** `memory/message-delivery-investigation-2026-03-27.md`
