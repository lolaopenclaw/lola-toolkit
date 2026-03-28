# 🚨 CRITICAL PROTOCOL CONTRADICTION

**Date:** 2026-03-25 07:54  
**Severity:** 🔴 HIGH  
**Impact:** Conflicting guidance to agent about quiet hours

---

## THE CONTRADICTION

### **preferences.md says:**

> **00:00–10:00 Madrid:** No messages to Manu unless CRITICAL (system down, security breach). All crons, backups, autoimprove, and background work run normally 24/7. Results go to memory + pending-actions.md, never to Telegram/Discord.
>
> **Crons NEVER send messages directly** — they write to memory. Only the morning report summarizes and delivers.

**Interpretation:** Quiet hours are 00:00-10:00 (10 HOURS), NO messages to Telegram/Discord at all during this time.

---

### **night-notification-protocol.md says:**

> **Definition:** 00:00 - 07:00 (Europe/Madrid timezone)
>
> **Rule:** NO notifications during quiet hours EXCEPT for CRITICAL emergencies.

**Interpretation:** Quiet hours are 00:00-07:00 (7 HOURS), CRITICAL messages ARE allowed to Telegram during this time.

---

### **AGENTS.md says:**

> **Night notifications:** Quiet hours 00:00-07:00 Madrid. Use topic routing. CRITICAL only during quiet hours (see `memory/night-notification-protocol.md`).

**Interpretation:** Matches night-notification-protocol.md (7 hours, CRITICAL allowed).

---

## THE PROBLEM

**preferences.md** (older, more restrictive):
- Quiet hours: **10 HOURS** (00:00-10:00)
- Crons: **NEVER send messages directly**, write to memory only
- Morning report: **Consolidates everything at 10:00**

**night-notification-protocol.md** (newer, less restrictive):
- Quiet hours: **7 HOURS** (00:00-07:00)
- Crons: **CAN send CRITICAL messages** during quiet hours
- Scripts: **Have topic routing + quiet hours checks**

**Which is correct?** Both have merit, but they **CONTRADICT**.

---

## IMPACT ANALYSIS

### **If we follow preferences.md:**

✅ **Pros:**
- Longer uninterrupted sleep (10 hours vs 7)
- Morning report at 10:00 consolidates everything (less notification fatigue)
- Simpler: crons write to memory, morning report delivers

❌ **Cons:**
- CRITICAL emergencies during 07:00-10:00 are delayed (e.g., gateway down at 8 AM → Manu doesn't know until 10 AM)
- Morning report might not exist (it's a cron at 10 AM, if it fails Manu never sees anything)
- Less flexible (what if Manu is awake at 9 AM and needs to know something?)

### **If we follow night-notification-protocol.md:**

✅ **Pros:**
- Shorter quiet hours (7 hours) aligns with typical sleep (23:00-07:00)
- CRITICAL alerts arrive immediately (gateway down at 8 AM → Manu knows right away)
- More flexible: crons can notify if truly critical

❌ **Cons:**
- More notifications (CRITICAL threshold might be subjective)
- Morning report at 10:00 might duplicate alerts (if cron already sent at 7:30)

---

## ROOT CAUSE

**preferences.md** was written **before** night-notification-protocol.md:

1. **preferences.md** created: ~Feb 2026 (early system setup)
2. **night-notification-protocol.md** created: TODAY (2026-03-25) during night notification fix

**What happened:**
- preferences.md established **00:00-10:00 quiet hours** + **crons write to memory only**
- Over time, crons evolved to send Telegram messages (violating preferences.md)
- Today's fix created night-notification-protocol.md with **00:00-07:00 quiet hours** + **CRITICAL allowed**
- **Nobody checked preferences.md for conflict**

---

## WHICH IS MANU'S TRUE PREFERENCE?

**Evidence from today's conversation:**

1. Manu complained about **messages at 4:00 AM** (nightly security review) → Wants quiet hours
2. Manu complained about **messages at 7:30 AM** (log review matutino) → But 7:30 is OUTSIDE 00:00-07:00 window, so maybe quiet hours should extend to 10:00?
3. Manu said **"quiet hours 00:00-07:00"** in initial problem description → Suggests 7-hour window

**Ambiguity:** Did Manu mean:
- A) Quiet hours are 00:00-07:00, and 7:30 AM message was wrong because it went to personal chat (not because of time)?
- B) Quiet hours are actually 00:00-10:00, and BOTH 4:00 AM and 7:30 AM messages were wrong?

---

## RECOMMENDED RESOLUTION

### **Option 1: Align to preferences.md (Stricter, 10-hour quiet hours)**

**Changes:**
1. Update night-notification-protocol.md: 00:00-10:00 (not 07:00)
2. Update AGENTS.md: 00:00-10:00
3. Update all script quiet hours checks: 00:00-10:00
4. Keep CRITICAL exception (but 00:00-10:00 window)
5. Morning report at 10:00 consolidates everything

**Pros:** Longer sleep, less notification fatigue  
**Cons:** CRITICAL alerts delayed if they happen 07:00-10:00

---

### **Option 2: Align to night-notification-protocol.md (Less strict, 7-hour quiet hours)**

**Changes:**
1. Update preferences.md: 00:00-07:00 (not 10:00)
2. Remove "crons NEVER send messages directly" from preferences.md
3. Morning report at 10:00 still runs, but might be redundant if crons already notified at 7:30

**Pros:** CRITICAL alerts arrive faster, more flexible  
**Cons:** Shorter sleep protection, more notifications

---

### **Option 3: Hybrid (Recommended)**

**Quiet hours: 00:00-07:00 (sleep)**  
**Buffer zone: 07:00-10:00 (waking up, no non-critical messages)**

**Rules:**
- 00:00-07:00: ONLY CRITICAL emergencies (security breach, gateway down)
- 07:00-10:00: HIGH priority allowed (log review, security findings, cron failures)
- 10:00+: All messages allowed

**Morning report at 10:00:** Consolidates LOW/MEDIUM priority items that were suppressed during 00:00-10:00

**Implementation:**
```bash
# In scripts:
HOUR=$(TZ=Europe/Madrid date +%H)

if [ "$HOUR" -ge 0 ] && [ "$HOUR" -lt 7 ]; then
    # 00:00-07:00: ONLY CRITICAL
    [ "$SEVERITY" != "CRITICAL" ] && exit 0
elif [ "$HOUR" -ge 7 ] && [ "$HOUR" -lt 10 ]; then
    # 07:00-10:00: HIGH or above
    [ "$SEVERITY" = "MEDIUM" ] || [ "$SEVERITY" = "LOW" ] && exit 0
fi
# 10:00+: All messages allowed
```

**Pros:** Best of both worlds  
**Cons:** More complex logic

---

## DECISION NEEDED

**Manu needs to decide:**

1. **What are your true quiet hours?**
   - A) 00:00-07:00 (7 hours, typical sleep)
   - B) 00:00-10:00 (10 hours, includes waking up buffer)
   - C) Hybrid (00:00-07:00 CRITICAL only, 07:00-10:00 HIGH only)

2. **Should crons send messages directly, or write to memory only?**
   - A) Crons can send messages (with quiet hours + severity checks)
   - B) Crons NEVER send messages, only morning report at 10:00
   - C) Hybrid (CRITICAL crons can send, others write to memory)

3. **What about the morning report?**
   - A) Keep it at 10:00, consolidates LOW/MEDIUM items from night
   - B) Move it to 07:30 (right after quiet hours end)
   - C) Eliminate it (crons notify directly)

---

## INTERIM STATE (Until Manu decides)

**Current behavior (after today's fixes):**
- Quiet hours: 00:00-07:00 (per night-notification-protocol.md)
- Scripts check quiet hours, suppress non-CRITICAL
- Crons use topic routing (not personal chat)
- Morning report at 10:00 still runs

**Conflicts:**
- preferences.md still says 00:00-10:00 (ignored by current implementation)
- preferences.md says "crons NEVER send messages" (violated by current implementation)

**Risk:**
- If Manu expects 00:00-10:00 quiet hours, he might get messages at 7:30 AM (log review) and be annoyed
- If Manu expects 00:00-07:00, current behavior is correct

---

## 🔴 ADDITIONAL CONTRADICTION: Discord vs Telegram

### **preferences.md says:**

> **Morning Reports (Matutino)**
> - **Destination:** Discord ONLY ❌ NUNCA Telegram
> - **Discord Channel:** `📊-reportes-matutino` (ID: `1475057935368458312`)
> - **Time:** 10:00 Madrid (cron `cb5d3743`)

### **Current cron config says:**

| Cron | Time | Destination |
|------|------|-------------|
| Log Review Matutino | 7:30 AM | Telegram topic 25 (Sistema & Logs) |
| Informe Matutino | 10:00 AM | Telegram topic 24 (Reportes Diarios) |

**Problem:** Both crons send to **Telegram**, but preferences.md says **Discord ONLY**.

**Impact:** Manu requested morning reports go to Discord (cleaner, separate from chat), but today's fix routed them to Telegram.

**Possible causes:**
1. **Discord was used before Telegram topics existed** → Once topics were added (2026-03-24), made sense to move to Telegram
2. **preferences.md is outdated** → Discord preference no longer valid after Telegram topics migration
3. **Today's fix was overly aggressive** → Applied Telegram topic routing to ALL crons without checking preferences

**Question for Manu:** Should morning reports go to:
- A) Discord `📊-reportes-matutino` channel (as per preferences.md)
- B) Telegram topic 24 (Reportes Diarios) — current state
- C) Both (Discord for archive, Telegram for immediate view)

---

## NEXT STEPS

1. **ASK MANU** which option he prefers (1, 2, or 3 above)
2. **Update all 3 files** to be consistent (preferences.md, night-notification-protocol.md, AGENTS.md)
3. **Update script logic** to match final decision
4. **Update crons** if needed (e.g., move morning report from 10:00 to 07:30)
5. **Test** during next quiet hours window

---

**Analysis completed:** 2026-03-25 07:56  
**Awaiting:** Manu's decision on quiet hours policy
