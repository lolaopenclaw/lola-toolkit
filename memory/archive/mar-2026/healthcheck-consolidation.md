# Healthcheck Consolidation - 2026-03-26

## ✅ Completed

### 1. Script Created
- **File:** `scripts/healthcheck-unified.sh`
- **Size:** 1.5KB (under 50 lines as requested)
- **Modes:** 
  - `--quick` (daily): fail2ban, config-drift, system basics
  - `--full` (weekly): adds security-scanner and rkhunter
- **Output:** Reports to `memory/healthcheck/YYYY-MM-DD.md`
- **Status:** Returns `HEALTHCHECK_OK` when clean

### 2. Validation
✅ Syntax check passed (`bash -n`)
✅ Shellcheck passed (no warnings)
✅ Test run successful (--quick mode)
✅ Report generated at `memory/healthcheck/2026-03-26.md`

### 3. Crons Created/Updated

**Daily Quick (4:15 AM):**
- ID: `376288ed-ec41-49d1-918d-a03c6147e162`
- Name: 🛡️ Healthcheck Daily (Quick)
- Schedule: `15 4 * * *` @ Europe/Madrid
- Model: haiku
- Status: ✅ Enabled
- Prompt: "Run: bash scripts/healthcheck-unified.sh --quick. If HEALTHCHECK_OK respond HEARTBEAT_OK. Otherwise forward the report."

**Weekly Full (Monday 9:30 AM):**
- ID: `bf115ea1-46ce-4641-9caf-63aff58ef922`
- Name: 🛡️ Healthcheck Weekly (Full)
- Schedule: `30 9 * * 1` @ Europe/Madrid
- Model: sonnet
- Status: ✅ Enabled
- Prompt: "Run: bash scripts/healthcheck-unified.sh --full. Read memory/healthcheck/YYYY-MM-DD.md (use today's date). Summarize findings. If clean say HEALTHCHECK_OK."

### 4. Old Crons Status

The following IDs mentioned in the task were not found in current active crons:
- c8522805 (fail2ban) - NOT FOUND
- 78d3556f (rkhunter) - NOT FOUND
- edc0db6e (lynis) - NOT FOUND
- fdf38b8f (security-audit-weekly) - NOT FOUND
- f01924d2 (nightly-security-review) - NOT FOUND
- a3bd469e (config-drift-check) - NOT FOUND

**Note:** These crons may have been previously disabled/removed, or the IDs are partial. The legacy configs exist in `workspace/cron-jobs.json` but are not active in the gateway.

## Script Design

The script follows the "Ralph Wiggum principle" (keep it simple):
- ✅ Calls existing tools (config-drift-detector.py, security-scanner.py, fail2ban-client, rkhunter)
- ✅ Does NOT rewrite check logic
- ✅ Compiles results into sections
- ✅ Saves timestamped reports
- ✅ Returns simple status code

## Next Steps

If the old cron IDs need to be explicitly disabled:
1. Search for them in `~/.openclaw/cron/` directory
2. Disable using `openclaw cron disable <id>`
3. Or manually edit the gateway's cron storage

## Testing Commands

```bash
# Quick mode (daily)
bash scripts/healthcheck-unified.sh --quick

# Full mode (weekly)
bash scripts/healthcheck-unified.sh --full

# View last report
cat memory/healthcheck/$(date +%Y-%m-%d).md

# List healthcheck crons
openclaw cron list | grep -i healthcheck
```
