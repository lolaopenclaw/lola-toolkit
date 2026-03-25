# Runtime Governance System

**Purpose:** Prevent runaway API costs from recursive loops, excessive token usage, or external abuse.

**Created:** 2026-03-25  
**Last updated:** 2026-03-25

---

## Problem

With Opus 4.6 as default model ($15/M input, $75/M output), a single runaway loop could cost hundreds of dollars in minutes.

**We need:**
1. Detection of recursive/infinite loops
2. Spending caps per day
3. Rate limiting per session
4. Alerts when thresholds are exceeded

---

## Components

### 1. Runtime Governance Check (`scripts/runtime-governance.sh`)

**Runs:** Every 30 minutes via cron  
**Duration:** < 10 seconds  
**Purpose:** Monitor spending, detect loops, check session volume

#### Checks Performed

##### A. Spending Check
- Reads today's costs via `scripts/usage-report.sh`
- Compares against thresholds:
  - **$25/day** → ⚠️ WARNING
  - **$50/day** → ⚠️ HIGH ALERT
  - **$100/day** → 🚨 CRITICAL (recommend emergency stop)
- Detects anomalies: if today's spend > 2x the 7-day average → HIGH alert

##### B. Loop Detection
- Reads last 100 lines of OpenClaw gateway logs
- Looks for patterns:
  - Same tool called **>10 times** in 5 minutes
  - Same error message repeated **>5 times**
  - Session with **>50 messages** in 10 minutes
- Outputs alert with session details if detected

##### C. Session Rate Limiting
- Analyzes JSONL session files for today
- Flags:
  - Any session with **>200 messages** today → potential runaway
  - Total API calls **>2000** → unusual volume
- Reports top consumer session (name, message count, cost)

#### Output Format

**Normal (everything OK):**
```
🛡️ Runtime Governance Check — 2026-03-25 14:30

💰 Spending: $12.45 today (avg $8.23/day)
🔄 Loops: None detected
📊 Volume: 456 API calls today (avg ~19/hour)
🔥 Sessions: Top consumer: telegram:group:-1003768820594 (123 msgs, $8.20)

Status: GOVERNANCE_OK
```

**Warning/Critical:**
```
🛡️ Runtime Governance Check — 2026-03-25 14:30

💰 Spending: $78.50 today (avg $8.23/day)
🔄 Loops: ⚠️ Potential loops detected (see alerts above)
📊 Volume: 3245 API calls today (avg ~135/hour)
🔥 Sessions: Top consumer: subagent:a3e5ea75 (847 msgs, $42.10)

⚠️ ALERTS:
  • 💰 HIGH: Today's spend is $78.50 (threshold: $50)
  • 📈 ANOMALY: Today's spend ($78.50) is >2x the 7-day average ($8.23/day)
  • 🔄 LOOP: Tool 'web_search' called 23 times in 5 minutes (threshold: 10)
  • 📊 HIGH VOLUME: Session 'subagent:a3e5ea75' has 847 messages today (threshold: 200)

Status: 🚨 CRITICAL
```

#### Exit Codes
- **0** → OK or WARNING (logged but not critical)
- **1** → CRITICAL (spend ≥$100 or severe loop detected)

#### Log File
All checks logged to: `data/runtime-governance.log`

---

### 2. Emergency Cost Stop (`scripts/emergency-cost-stop.sh`)

**Purpose:** Panic button to immediately halt all API spending  
**Usage:** `bash scripts/emergency-cost-stop.sh "Reason for emergency stop"`

#### Actions Taken

1. **List running subagent sessions** → `openclaw sessions list`
2. **Terminate ALL active sessions** → `openclaw sessions kill <id>`
3. **Disable non-essential crons:**
   - Keeps ONLY: `backup`, `driving-mode-reset`
   - Disables everything else
4. **Send Telegram alert** with summary
5. **Create emergency log:** `data/emergency-stop.log`

#### Example Usage

```bash
# Detected runaway loop burning $200/hour
bash scripts/emergency-cost-stop.sh "Runaway loop in autoimprove subagent"
```

#### Recovery Steps

After emergency stop:

1. **Review log:** `cat data/emergency-stop.log`
2. **Check spending:** `bash scripts/usage-report.sh --today`
3. **Investigate root cause** (check session logs, gateway logs)
4. **Re-enable crons when safe:**
   ```bash
   openclaw cron list
   openclaw cron enable <id>
   ```

---

## Thresholds Summary

| Metric | Threshold | Action |
|--------|-----------|--------|
| Daily spend | $25 | ⚠️ WARNING alert |
| Daily spend | $50 | ⚠️ HIGH alert |
| Daily spend | $100 | 🚨 CRITICAL alert (consider emergency stop) |
| Spend anomaly | >2x 7-day avg | ⚠️ HIGH alert |
| Tool calls | >10 in 5 min | 🔄 LOOP alert |
| Same error | >5 in 5 min | 🔄 LOOP alert |
| Session messages | >200/day | 📊 HIGH VOLUME alert |
| Total API calls | >2000/day | 📊 UNUSUAL VOLUME alert |
| Session burst | >50 msgs in 10 min | 🔄 LOOP alert |

---

## Setup

### 1. Test Scripts (Manual)

```bash
# Test governance check
bash scripts/runtime-governance.sh

# Should output:
# 🛡️ Runtime Governance Check — ...
# Status: GOVERNANCE_OK (or alerts if thresholds exceeded)
```

```bash
# Test emergency stop (DRY RUN - does NOT actually kill/disable)
# Create test reason, review output, but DO NOT run in production yet
bash scripts/emergency-cost-stop.sh "Test run"
```

### 2. Add Cron (Done by Lola, Not You)

Governance check will be added to cron by main agent after validation.

**Proposed schedule:** Every 30 minutes
```
*/30 * * * * bash scripts/runtime-governance.sh
```

---

## When to Use Emergency Stop

**USE when:**
- Daily spend exceeds $100 and still climbing
- Confirmed runaway loop (same tool >50 calls, no progress)
- External abuse detected (unauthorized API access)
- Multiple CRITICAL alerts from governance check

**DO NOT USE when:**
- Just a WARNING alert (investigate first)
- Legitimate high usage (e.g., large batch job you started)
- Single spike that's already resolved

**Remember:** Emergency stop is DESTRUCTIVE. It kills all work in progress.

---

## Files

- **Governance script:** `scripts/runtime-governance.sh`
- **Emergency stop:** `scripts/emergency-cost-stop.sh`
- **Governance log:** `data/runtime-governance.log` (created on first run)
- **Emergency log:** `data/emergency-stop.log` (created on emergency stop)
- **Cost data source:** Session JSONL files in `~/.openclaw/agents/main/sessions/`

---

## Future Improvements

Ideas for v2:
- [ ] Auto-trigger emergency stop on 2x consecutive CRITICAL alerts
- [ ] Per-model spending caps (e.g., Opus limited to $50/day)
- [ ] Whitelist for high-volume sessions (e.g., legitimate batch jobs)
- [ ] Slack/Discord alerting in addition to Telegram
- [ ] Historical trend analysis (spending velocity, not just absolute)
- [ ] Integration with `openclaw gateway restart` to enforce caps

---

## Related Documentation

- **API Cost Tracking:** `memory/api-cost-tracking.md`
- **Usage Report Script:** `scripts/usage-report.sh --help`
- **Session Logs:** `~/.openclaw/agents/main/sessions/*.jsonl`
- **Cron Management:** `openclaw cron list`, `openclaw cron disable <id>`
