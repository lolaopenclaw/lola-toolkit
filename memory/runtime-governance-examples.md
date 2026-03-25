# Runtime Governance - Examples & Quick Start

Quick reference guide for using the runtime governance system.

---

## Quick Commands

### Check Current Status
```bash
bash scripts/runtime-governance.sh
```

**Example output (normal):**
```
🛡️ Runtime Governance Check — 2026-03-25 10:30

💰 Spending: $8.45 today (avg $9.23/day)
🔄 Loops: None detected
📊 Volume: 456 API calls today (avg ~45/hour)
🔥 Sessions: Top consumer: telegram:group:-1003768820594 (123 msgs, $6.20)

Status: GOVERNANCE_OK
```

**Example output (warning):**
```
🛡️ Runtime Governance Check — 2026-03-25 14:30

💰 Spending: $63.03 today (avg $13.45/day)
🔄 Loops: None detected
📊 Volume: 2695 API calls today (avg ~112/hour)
🔥 Sessions: Top consumer: subagent:a3e5ea75 (492 msgs, $22.85)

⚠️ ALERTS:
  • 💰 HIGH: Today's spend is $63.03 (threshold: $50)
  • 📈 ANOMALY: Today's spend ($63.03) is >2x the 7-day average ($13.45/day)
  • 📊 HIGH VOLUME: Session 'subagent:a3e5ea75' has 492 messages today (threshold: 200)
  • 📊 HIGH VOLUME: Total 2695 API calls today (threshold: 2000)

Status: ⚠️ WARNING
```

### Emergency Stop (Panic Button)
```bash
# Only use in emergencies!
bash scripts/emergency-cost-stop.sh "Runaway loop detected in autoimprove"
```

**What it does:**
1. Kills all active subagent sessions
2. Disables all non-essential crons (keeps: backup, driving-mode-reset)
3. Sends Telegram alert
4. Creates emergency log

**After emergency stop:**
```bash
# Review what happened
cat data/emergency-stop.log

# Check today's damage
bash scripts/usage-report.sh --today --by-session

# Investigate root cause
journalctl --user -u openclaw-gateway --since "1 hour ago" | less

# Re-enable crons when safe
openclaw cron list
openclaw cron enable <id>
```

---

## Typical Scenarios

### Scenario 1: High Spend Alert ($50-$100)
**Symptoms:** Governance check shows WARNING status, spend > $50

**Actions:**
1. Check what's consuming:
   ```bash
   bash scripts/usage-report.sh --today --by-session
   bash scripts/usage-report.sh --today --by-model
   ```

2. Review top session:
   ```bash
   # Find session ID from governance output
   tail -100 ~/.openclaw/agents/main/sessions/<session-id>.jsonl | jq -r '.message.content.text'
   ```

3. If legitimate (e.g., you started a big batch job):
   - Monitor, let it complete
   - Consider adding to whitelist (future feature)

4. If suspicious:
   - Kill specific session: `openclaw sessions kill <id>`
   - Review gateway logs: `journalctl --user -u openclaw-gateway --since "30 minutes ago"`

### Scenario 2: Loop Detected
**Symptoms:** "🔄 LOOP: Tool 'X' called 23 times in 5 minutes"

**Actions:**
1. Identify which session:
   ```bash
   journalctl --user -u openclaw-gateway --since "10 minutes ago" | grep "tool: X"
   ```

2. Check session activity:
   ```bash
   openclaw sessions list
   # Look for session with high message count
   ```

3. If confirmed loop:
   ```bash
   # Kill the session
   openclaw sessions kill <session-id>
   
   # OR if multiple sessions affected:
   bash scripts/emergency-cost-stop.sh "Loop detected in tool X"
   ```

4. Post-mortem:
   - Review session log to understand why loop occurred
   - Fix root cause (likely: tool returning same error repeatedly)
   - Consider adding circuit breaker to skill

### Scenario 3: Critical Alert ($100+)
**Symptoms:** Status shows "🚨 CRITICAL", spend > $100

**Actions:**
1. **IMMEDIATE:** Run emergency stop
   ```bash
   bash scripts/emergency-cost-stop.sh "Critical spend exceeded $100"
   ```

2. Assess damage:
   ```bash
   bash scripts/usage-report.sh --today --by-model
   bash scripts/usage-report.sh --today --by-session
   ```

3. Find root cause:
   ```bash
   # Check for loops
   journalctl --user -u openclaw-gateway --since "1 hour ago" | grep -i "error\|loop\|retry"
   
   # Check session with highest cost
   cat ~/.openclaw/agents/main/sessions/<top-session>.jsonl | \
     jq -r 'select(.message.usage.cost.total > 1) | "\(.timestamp) \(.message.model) $\(.message.usage.cost.total)"'
   ```

4. Document incident:
   ```bash
   # Add to emergency log
   echo "Root cause: <description>" >> data/emergency-stop.log
   echo "Prevention: <what you'll change>" >> data/emergency-stop.log
   ```

5. Resume operations:
   ```bash
   # Re-enable crons carefully
   openclaw cron list
   openclaw cron enable <id>  # one at a time
   ```

### Scenario 4: Anomaly (>2x Average)
**Symptoms:** "📈 ANOMALY: Today's spend is >2x the 7-day average"

**Not necessarily bad!** Could be:
- Legitimate spike (you asked for complex research)
- New feature testing
- Catch-up processing after downtime

**Actions:**
1. Correlate with your activity:
   ```bash
   # What sessions are you running?
   openclaw sessions list
   ```

2. Check if it's tapering off:
   ```bash
   # Run governance check a few times over 30 minutes
   watch -n 600 "bash scripts/runtime-governance.sh | tail -20"
   ```

3. If sustained and unexplained → investigate per Scenario 1

---

## Log Files Reference

### Runtime Governance Log
**Location:** `data/runtime-governance.log`

**Contents:** Every governance check result (timestamp + status + alerts)

**Example:**
```
[2026-03-25 21:59] ⚠️ WARNING
  💰 HIGH: Today's spend is $61.73 (threshold: $50)
  📈 ANOMALY: Today's spend ($61.73) is >2x the 7-day average ($13.26/day)
  📊 HIGH VOLUME: Session 'subagent:xyz' has 492 messages today (threshold: 200)
```

**Use:**
```bash
# Show last 50 lines
tail -50 data/runtime-governance.log

# Find all CRITICAL alerts
grep "CRITICAL" data/runtime-governance.log

# Show alerts from today
grep "$(date +%Y-%m-%d)" data/runtime-governance.log
```

### Emergency Stop Log
**Location:** `data/emergency-stop.log`

**Contents:** Emergency stop events (who, when, why, what actions taken)

**Use:**
```bash
# Review all emergency stops
cat data/emergency-stop.log

# Show last emergency stop
tail -30 data/emergency-stop.log
```

---

## Integration with Existing Tools

### Usage Report
```bash
# Today's spend (what governance check uses)
bash scripts/usage-report.sh --today

# By model (which models are expensive?)
bash scripts/usage-report.sh --today --by-model

# By session (which crons/subagents?)
bash scripts/usage-report.sh --today --by-session

# Week trend
bash scripts/usage-report.sh --week
```

### Cost Alert Script
```bash
# Alert if today > $25
bash scripts/cost-alert.sh  # (if exists, else use usage-report.sh --alert 25)

# Or with usage-report:
bash scripts/usage-report.sh --today --alert 25
```

### Subagents Dashboard
```bash
# Real-time view of active sessions
bash scripts/subagents-dashboard
```

---

## Cron Schedule (After Setup)

The governance check will run every 30 minutes:
```
*/30 * * * * bash /home/mleon/.openclaw/workspace/scripts/runtime-governance.sh
```

**Why 30 minutes?**
- Fast enough to catch runaway loops before too much damage
- Infrequent enough to not add overhead
- Balanced against typical session durations

**Notifications:**
- Only sends Telegram alerts on CRITICAL status (spend > $100)
- WARNING/HIGH alerts logged but not messaged (check log manually)

---

## Thresholds (Reminder)

| Metric | Threshold | Severity |
|--------|-----------|----------|
| Daily spend | $25 | ⚠️ WARNING |
| Daily spend | $50 | ⚠️ HIGH |
| Daily spend | $100 | 🚨 CRITICAL |
| Spend anomaly | >2x 7-day avg | ⚠️ HIGH |
| Tool calls (5 min) | >10 | 🔄 LOOP |
| Same error (5 min) | >5 | 🔄 LOOP |
| Session messages/day | >200 | 📊 HIGH VOLUME |
| Total API calls/day | >2000 | 📊 HIGH VOLUME |

**Adjusting thresholds:**
Edit `scripts/runtime-governance.sh` variables:
```bash
DAILY_WARNING=25
DAILY_HIGH=50
DAILY_CRITICAL=100
SESSION_MSG_THRESHOLD=200
TOTAL_CALLS_THRESHOLD=2000
```

---

## Testing (Before Cron Setup)

### Test 1: Normal Run
```bash
bash scripts/runtime-governance.sh
# Should output status report, exit code 0
echo "Exit code: $?"
```

### Test 2: Emergency Stop (Dry Run)
```bash
# Review the script first - it WILL try to kill sessions!
# Only test in a safe environment or read the code carefully
bash scripts/emergency-cost-stop.sh "Test run"
```

**IMPORTANT:** Emergency stop is NOT a dry-run script. It WILL:
- Kill all active sessions
- Disable crons
- Send Telegram alert

Only use for testing if you're prepared for these actions.

---

## Related Documentation

- **Main docs:** `memory/runtime-governance.md`
- **API cost tracking:** `memory/api-cost-tracking.md`
- **Session logs:** `~/.openclaw/agents/main/sessions/*.jsonl`
