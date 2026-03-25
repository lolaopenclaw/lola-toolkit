# Night Notifications Fix Plan

**Date:** 2026-03-25
**Based on:** cron-notifications-audit-20260325-072437.md

---

## Executive Summary

**Issues found:** 4 scripts sending notifications without quiet hours checks  
**Critical issues:** 0 (no hardcoded personal chat 6884477)  
**Night crons:** 2 (Model Reset, System Updates)

---

## Fix Plan

### 🔴 Priority 1: Add Quiet Hours + Topic Routing

#### 1. `scripts/nightly-security-review.sh`

**Current behavior:**
- Runs at 4:00 AM (via cron, not confirmed which)
- Sends Telegram notifications without checking quiet hours
- No topic routing (uses `--target` only)

**Fixes needed:**
```bash
# Around line 340, before sending alert:
# Add quiet hours check
HOUR=$(TZ=Europe/Madrid date +%H)
if [ "$HOUR" -ge 0 ] && [ "$HOUR" -lt 7 ]; then
    # During quiet hours: only alert if CRITICAL findings
    if [ "$CRITICAL_FINDINGS" -eq 0 ]; then
        echo "Quiet hours: non-critical findings logged, no notification" >> "$LOG_FILE"
        exit 0
    fi
fi

# Change notification command (around line 345):
# FROM:
openclaw message send --channel telegram --target "$ALERT_CHANNEL" \
    --message "🚨 Nightly Security Review: $FINDINGS findings detected. Review: $REPORT_FILE"

# TO:
openclaw message send --channel telegram \
    --target "-1003768820594" --topic 29 \
    --message "🚨 Security Review: $FINDINGS findings detected. Review: $REPORT_FILE"
```

**Testing:**
```bash
# Dry run with simulated findings
bash scripts/nightly-security-review.sh --verbose --alert-channel "-1003768820594"

# Check that it respects quiet hours
TZ=Europe/Madrid date  # Should be 00:00-07:00 to test
```

---

#### 2. `scripts/log-review.sh`

**Current behavior:**
- Unknown schedule (probably 7:30 AM via cron)
- Sends Telegram without quiet hours check
- No topic routing

**Fixes needed:**
```bash
# Around line 160, before sending notification:
# Add quiet hours check
HOUR=$(TZ=Europe/Madrid date +%H)
if [ "$HOUR" -ge 0 ] && [ "$HOUR" -lt 7 ]; then
    echo "Quiet hours: log review findings logged, no notification"
    exit 0
fi

# Change notification (around line 163):
# FROM:
openclaw message send "$MESSAGE"

# TO:
openclaw message send --channel telegram \
    --target "-1003768820594" --topic 25 \
    --message "$MESSAGE"
```

**Note:** If log-review runs at 7:30 AM, it's OUTSIDE quiet hours (00:00-07:00), so this fix is defensive for future schedule changes.

---

#### 3. `scripts/rate-limit-alert-sender.sh`

**Current behavior:**
- Sends rate limit alerts without quiet hours
- No topic routing

**Fixes needed:**
```bash
# Around line 30, before sending alert:
# Add quiet hours check with severity threshold
HOUR=$(TZ=Europe/Madrid date +%H)
if [ "$HOUR" -ge 0 ] && [ "$HOUR" -lt 7 ]; then
    # Only alert during quiet hours if quota is critically low (< 10%)
    PERCENT=$(echo "$REMAINING / $TOTAL * 100" | bc)
    if [ "$PERCENT" -gt 10 ]; then
        echo "Quiet hours: rate limit warning logged, no notification"
        exit 0
    fi
fi

# Change notification (around line 34):
# FROM:
openclaw message send "$MESSAGE"

# TO:
openclaw message send --channel telegram \
    --target "-1003768820594" --topic 25 \
    --message "$MESSAGE"
```

---

### 🟡 Priority 2: Add Topic Routing (no quiet hours needed)

#### 4. `scripts/auto-update-openclaw.sh`

**Current behavior:**
- Runs at 21:30 (outside quiet hours)
- Sends without topic routing

**Fix needed:**
```bash
# Around line 70:
# FROM:
openclaw message send "$MESSAGE"

# TO:
openclaw message send --channel telegram \
    --target "-1003768820594" --topic 25 \
    --message "$MESSAGE"
```

---

#### 5. `scripts/autoimprove-trigger.sh`

**Current behavior:**
- Runs at night (2:00 AM likely)
- Already has quiet hours check ✅
- No topic routing

**Fix needed:**
```bash
# Around line 28:
# FROM:
openclaw message send "$MESSAGE"

# TO:
openclaw message send --channel telegram \
    --target "-1003768820594" --topic 25 \
    --message "$MESSAGE"
```

---

### 🟢 Priority 3: Cleanup

#### 6. Archive/Delete `scripts/exa-cron-report.sh`

**Reason:** Unused, hardcoded `6884477`

```bash
mkdir -p scripts/archive/exa
mv scripts/exa-cron-report.sh scripts/archive/exa/
mv scripts/exa-search.sh scripts/archive/exa/
```

---

## Implementation Order

1. **Create night notification protocol** (`memory/night-notification-protocol.md`) — FIRST
2. **Fix nightly-security-review.sh** — CRITICAL (runs at 4 AM)
3. **Fix rate-limit-alert-sender.sh** — HIGH (can trigger anytime)
4. **Fix log-review.sh** — MEDIUM (runs at 7:30 AM, outside quiet hours)
5. **Fix auto-update-openclaw.sh** — LOW (runs at 21:30, outside quiet hours)
6. **Fix autoimprove-trigger.sh** — LOW (already has quiet hours)
7. **Archive exa scripts** — LOWEST

---

## Testing Checklist

After applying fixes, verify:

- [ ] `nightly-security-review.sh` respects quiet hours (test with simulated 3 AM)
- [ ] `nightly-security-review.sh` sends to topic 29
- [ ] `log-review.sh` sends to topic 25
- [ ] `rate-limit-alert-sender.sh` respects quiet hours + sends to topic 25
- [ ] `auto-update-openclaw.sh` sends to topic 25
- [ ] `autoimprove-trigger.sh` sends to topic 25
- [ ] No scripts send to personal chat `6884477`
- [ ] Re-run audit script: `bash scripts/audit-cron-notifications.sh`

---

## Night Notification Protocol (to be created)

**File:** `memory/night-notification-protocol.md`

**Contents:**
1. Quiet hours definition: 00:00-07:00 Madrid
2. Severity levels:
   - CRITICAL: Always notify (security breach, secrets exposed, gateway down)
   - HIGH: Notify if outside quiet hours
   - MEDIUM/LOW: Silent during quiet hours, log only
3. Topic routing table (as in audit recommendations)
4. Code snippets for bash scripts
5. Reference for AGENTS.md

---

## Verification

After fixes:
```bash
# Re-run audit
bash scripts/audit-cron-notifications.sh

# Check for remaining issues
grep -r "6884477" scripts/*.sh  # Should be empty (except audit script itself)
grep -r "openclaw message send" scripts/*.sh | grep -v "topic"  # Should be minimal
```

---

**Status:** Ready to implement  
**Next:** Create night-notification-protocol.md, then apply fixes in order
