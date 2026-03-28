# Night Notifications Fix — COMPLETED

**Date:** 2026-03-25 07:44  
**Duration:** ~40 minutes  
**Status:** ✅ ALL FIXES APPLIED

---

## Problem Summary

**Root cause:** Crons and scripts sending notifications to personal chat (6884477) during quiet hours (00:00-07:00 Madrid) instead of using topic routing.

**Symptoms:**
1. Messages arriving at personal chat instead of group topics
2. Notifications during quiet hours (e.g., 4:00 AM security review)
3. `channel: "last"` causing unpredictable routing

**Impact:** Sleep disruption + notification clutter in wrong chat

---

## Fixes Applied

### 1. Created Night Notification Protocol ✅

**File:** `memory/night-notification-protocol.md`

**Contents:**
- Quiet hours definition (00:00-07:00 Madrid)
- Severity levels (CRITICAL/HIGH/MEDIUM/LOW)
- Topic routing table
- Implementation guide (bash + cron)
- Testing checklist

### 2. Fixed 23 Cron Jobs ✅

**Script:** `scripts/fix-cron-delivery.py`

**Changes:**
- Replaced `"to": "6884477"` with `"to": "-1003768820594:<topic>"`
- Replaced `"channel": "last"` with `"channel": "telegram"`
- Auto-assigned topics based on cron name/purpose

**Topic mapping:**
- Security → topic 29 (🛡️ Seguridad & Audits)
- System/Logs → topic 25 (🔧 Sistema & Logs)
- Health/Garmin → topic 28 (🏃 Salud & Garmin)
- Finance → topic 26 (💰 Finanzas)
- Reports → topic 24 (📊 Reportes Diarios)

**Fixed crons:**
- Backup diario de memoria
- Garmin informes (3 crons)
- System Updates Nightly
- Model Reset Nightly
- Driving Mode Auto-Reset
- Autoimprove crons (3)
- Memory Search Reindex
- Security token rotation
- Best Practices Checker
- Log Review Matutino
- Auto-update OpenClaw
- And 8 more...

### 3. Fixed 5 Scripts ✅

**Script:** `scripts/apply-all-notification-fixes.sh`

**Scripts fixed:**

1. **nightly-security-review.sh**
   - Added quiet hours check (only CRITICAL during 00:00-07:00)
   - Changed to topic 29 (Seguridad & Audits)

2. **log-review.sh**
   - Added quiet hours function
   - Changed to topic 25 (Sistema & Logs)

3. **rate-limit-alert-sender.sh**
   - Added quiet hours check (HIGH severity threshold)
   - Changed to topic 25

4. **auto-update-openclaw.sh**
   - Changed to topic 25 (runs at 21:30, outside quiet hours)

5. **autoimprove-trigger.sh**
   - Changed to topic 25 (already had quiet hours logic)

**Backups:** `scripts/.backups.20260325-074357/`

### 4. Updated AGENTS.md ✅

Added night notification protocol reference:
```
- **Night notifications:** Quiet hours 00:00-07:00 Madrid. Use topic routing. CRITICAL only during quiet hours (see `memory/night-notification-protocol.md`).
```

### 5. Gateway Restart ✅

Restarted gateway to apply cron config changes.

---

## Verification

**Post-fix audit:** `scripts/audit-cron-notifications.sh`

**Results:**
- ✅ **0 critical issues** (down from 4)
- ✅ **0 scripts with hardcoded personal chat** (6884477)
- ✅ **nightly-security-review.sh** has quiet hours + topic routing
- ✅ All high-risk scripts verified

**Remaining warnings (false positives):**
- `system-updates-nightly.sh` — Silent script (cron handles delivery)
- `backup-memory.sh` — Silent script (cron handles delivery)
- `autoimprove-trigger.sh` — Has quiet hours but not detected by audit pattern

These are **OK** because notification is handled by cron delivery config (already fixed).

---

## Testing

**Quiet hours:**
```bash
# Simulate 3 AM run
TZ=Europe/Madrid faketime '2026-03-25 03:00:00' bash scripts/nightly-security-review.sh --verbose

# Should suppress non-CRITICAL findings
```

**Topic routing:**
```bash
# Test message to topic 25
openclaw message send \
    --channel telegram \
    --target "-1003768820594" \
    --topic 25 \
    --message "🧪 Test: Sistema & Logs"
```

---

## Files Created/Modified

### Created:
- `memory/night-notification-protocol.md` (7.4 KB)
- `memory/night-notifications-fix-plan.md` (6.2 KB)
- `memory/cron-notifications-audit-20260325-072437.md` (audit report)
- `memory/cron-notifications-audit-20260325-074429.md` (post-fix audit)
- `scripts/audit-cron-notifications.sh` (14 KB, reusable)
- `scripts/fix-cron-delivery.py` (4 KB)
- `scripts/apply-all-notification-fixes.sh` (5.3 KB)

### Modified:
- `~/.openclaw/cron/jobs.json` (23 crons updated)
- `scripts/nightly-security-review.sh`
- `scripts/log-review.sh`
- `scripts/rate-limit-alert-sender.sh`
- `scripts/auto-update-openclaw.sh`
- `scripts/autoimprove-trigger.sh`
- `AGENTS.md`

### Backups:
- `~/.openclaw/cron/jobs.json.bak.20260325-074308`
- `scripts/.backups.20260325-074357/` (5 scripts)

---

## Impact

**Before:**
- 23 crons sending to personal chat or using `channel: "last"`
- 5 scripts without quiet hours checks
- No centralized protocol

**After:**
- ✅ All crons use topic routing
- ✅ Critical scripts respect quiet hours
- ✅ Documented protocol for future scripts/crons
- ✅ Audit script available for compliance checks

**Expected behavior:**
- Security findings → topic 29 (only CRITICAL during quiet hours)
- System logs → topic 25
- Health/Garmin → topic 28
- Daily reports → topic 24
- No messages to personal chat during 00:00-07:00 (except CRITICAL emergencies)

---

## Next Steps (Optional)

1. **Weekly audit:** Run `bash scripts/audit-cron-notifications.sh` every Monday
2. **Monitor compliance:** Check that new crons/scripts follow protocol
3. **Update protocol:** Add new rules as edge cases emerge
4. **Document exceptions:** If any CRITICAL alert fires during quiet hours, log it

---

## Learnings

1. **Cron delivery config > script hardcoding** — Using cron-level delivery config is cleaner than hardcoding in every script
2. **"channel: last" is dangerous** — Always specify explicit channel + target
3. **Quiet hours need explicit checks** — Default behavior doesn't respect time of day
4. **Topic routing prevents clutter** — Group topics keep personal chat clean
5. **Audit scripts are gold** — Automated compliance checking catches regressions

---

## References

- Night notification protocol: `memory/night-notification-protocol.md`
- Fix plan: `memory/night-notifications-fix-plan.md`
- Audit script: `scripts/audit-cron-notifications.sh`
- Telegram topics: `memory/telegram-topics.md`
- User preferences: `memory/preferences.md` (quiet hours 00:00-07:00)

---

**Status:** ✅ COMPLETE  
**Next cron run:** 21:30 tonight (Auto-update OpenClaw) → Will test new topic routing  
**Next night cron:** 00:00 tonight (Model Reset) → Silent, should not notify
