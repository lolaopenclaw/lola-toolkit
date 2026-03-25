# Night Notification Protocol

**Version:** 1.0  
**Date:** 2026-03-25  
**Status:** Active

---

## Overview

This protocol defines how OpenClaw handles notifications during quiet hours to respect Manu's sleep schedule while still alerting on critical issues.

---

## Quiet Hours

**Definition:** 00:00 - 07:00 (Europe/Madrid timezone)

**Rule:** NO notifications during quiet hours EXCEPT for CRITICAL emergencies.

---

## Severity Levels

### 🔴 CRITICAL (Always notify, even during quiet hours)

**When:**
- Security breach detected (secrets exposed, unauthorized access)
- Gateway down or unresponsive
- Data loss or corruption imminent
- Health emergency (Garmin detects anomalous vitals)

**Action:** Immediate notification with alert emoji (🚨)

**Examples:**
- Secrets found in git history (exposed API keys)
- Gateway crash loop
- Backup failed + no recent backup exists (>48h)
- Heart rate >180 BPM sustained or <40 BPM

---

### 🟡 HIGH (Notify if outside quiet hours)

**When:**
- System updates available (security patches)
- Cron job failed
- API rate limit approaching (>80% consumed)
- Disk space low (<10% free)

**Action:** Notify immediately if outside quiet hours, log + queue for morning report if during quiet hours

**Examples:**
- Auto-update found new OpenClaw version
- Autoimprove cron failed
- Anthropic API quota at 85%

---

### 🟢 MEDIUM (Silent during quiet hours, log only)

**When:**
- Routine system updates completed
- Backup succeeded
- Non-critical warnings

**Action:** Log to memory, include in morning report, NO immediate notification during quiet hours

**Examples:**
- System packages updated (12 packages)
- Backup completed successfully
- Minor config drift detected

---

### 🔵 LOW/INFO (Always silent, log only)

**When:**
- Routine operations completed
- Informational messages
- Scheduled reports

**Action:** Log only, include in morning report if relevant

**Examples:**
- Reindex completed
- Memory decay ran
- Daily stats generated

---

## Topic Routing

All notifications MUST use topic routing (never personal chat `6884477` directly).

| Notification Type | Topic ID | Topic Name | Example |
|-------------------|----------|------------|---------|
| Security findings | 29 | 🛡️ Seguridad & Audits | Secret found in git |
| System updates/errors | 25 | 🔧 Sistema & Logs | Cron failed, Gateway restart |
| Backup status | 25 | 🔧 Sistema & Logs | Backup completed |
| Health/Garmin | 28 | 🏃 Salud & Garmin | Workout summary, anomaly |
| Finance | 26 | 💰 Finanzas | Sheets update |
| Daily reports | 24 | 📊 Reportes Diarios | Morning briefing |
| GitHub/PRs | 27 | 🐙 GitHub & PRs | PR review, CI status |
| Calendar/Tasks | 30 | 📅 Calendario & Tareas | Upcoming event |

**Command format:**
```bash
openclaw message send \
    --channel telegram \
    --target "-1003768820594" \
    --topic <TOPIC_ID> \
    --message "<MESSAGE>"
```

---

## Implementation Guide

### For Bash Scripts

**Add quiet hours check:**

```bash
#!/bin/bash
# Check quiet hours (00:00-07:00 Madrid)
check_quiet_hours() {
    local HOUR=$(TZ=Europe/Madrid date +%H)
    local SEVERITY=${1:-"MEDIUM"}  # Default to MEDIUM if not specified
    
    if [ "$HOUR" -ge 0 ] && [ "$HOUR" -lt 7 ]; then
        # During quiet hours
        if [ "$SEVERITY" = "CRITICAL" ]; then
            # Allow notification
            return 0
        else
            # Suppress notification
            echo "Quiet hours: suppressing $SEVERITY notification" >&2
            return 1
        fi
    fi
    
    # Outside quiet hours: always allow
    return 0
}

# Usage:
if check_quiet_hours "HIGH"; then
    openclaw message send \
        --channel telegram \
        --target "-1003768820594" \
        --topic 25 \
        --message "⚠️ High priority alert"
fi
```

**Send with topic routing:**

```bash
# Security notification
openclaw message send \
    --channel telegram \
    --target "-1003768820594" \
    --topic 29 \
    --message "🚨 CRITICAL: Security finding detected"

# System notification
openclaw message send \
    --channel telegram \
    --target "-1003768820594" \
    --topic 25 \
    --message "✅ System update completed"

# Health notification
openclaw message send \
    --channel telegram \
    --target "-1003768820594" \
    --topic 28 \
    --message "🏃 Workout completed: 5.2 km run"
```

---

### For Cron Jobs

**Configure delivery in cron:**

```json
{
  "delivery": {
    "mode": "announce",
    "channel": "telegram",
    "to": "-1003768820594",
    "topic": 25
  }
}
```

**Create cron with proper delivery:**

```bash
openclaw cron add \
  --name "Example Cron" \
  --schedule "cron 0 4 * * *" \
  --task "bash /path/to/script.sh" \
  --delivery-mode announce \
  --delivery-channel telegram \
  --delivery-to "-1003768820594" \
  --delivery-topic 25
```

**Update existing cron:**

```bash
openclaw cron update <CRON_ID> \
  --delivery-mode announce \
  --delivery-channel telegram \
  --delivery-to "-1003768820594" \
  --delivery-topic 25
```

---

### For Agent Tasks

**In prompt:**

```
Generate a security report and send to topic 29 (Seguridad & Audits) using:

openclaw message send --channel telegram --target "-1003768820594" --topic 29 --message "Your report here"

Respect quiet hours (00:00-07:00 Madrid): only send CRITICAL alerts during this time.
```

---

## Cron Delivery Modes

| Mode | Behavior | Use Case |
|------|----------|----------|
| `none` | No automatic delivery, script handles output | Script uses `openclaw message send` internally |
| `announce` | Deliver output to specified channel/topic | Agent generates report, auto-send to topic |
| `silent` | Never deliver (log only) | Background tasks, no user notification needed |

**Best practice:** Use `mode: "none"` + explicit `openclaw message send` in scripts for full control.

---

## Testing

**Test quiet hours check:**

```bash
# Simulate 3 AM
TZ=Europe/Madrid faketime '2026-03-25 03:00:00' bash your-script.sh

# Should suppress non-CRITICAL notifications
```

**Test topic routing:**

```bash
# Send test message to topic 25
openclaw message send \
    --channel telegram \
    --target "-1003768820594" \
    --topic 25 \
    --message "🧪 Test message to Sistema & Logs"
```

---

## Audit Checklist

Run regularly (weekly) to verify compliance:

- [ ] No scripts send to personal chat `6884477` directly
- [ ] All notification scripts check quiet hours (unless CRITICAL only)
- [ ] All crons have correct `delivery.channel` (not "last")
- [ ] All notifications use topic routing
- [ ] CRITICAL alerts work during quiet hours

**Audit command:**
```bash
bash scripts/audit-cron-notifications.sh
```

---

## Exceptions

**Approved exceptions to quiet hours:**

1. **Security breaches** (secrets exposed, unauthorized access)
2. **Gateway down** (service unresponsive)
3. **Health emergencies** (Garmin detects anomalous vitals)
4. **Explicit user request** (e.g., "wake me if X happens")

---

## History

| Date | Change | Reason |
|------|--------|--------|
| 2026-03-25 | Initial protocol | Fix night notification issues (messages to wrong chat, no quiet hours) |

---

## References

- Topic mapping: `memory/telegram-topics.md`
- Fix plan: `memory/night-notifications-fix-plan.md`
- Audit script: `scripts/audit-cron-notifications.sh`
- Preferences: `memory/preferences.md` (quiet hours 00:00-07:00)
