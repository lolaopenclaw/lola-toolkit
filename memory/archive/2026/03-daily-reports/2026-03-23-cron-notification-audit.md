# Cron Notification Audit - 2026-03-23

## Summary

Audited and fixed ALL cron jobs to comply with new notification policy:

**New Policy:**
- ❌ Crons NEVER send messages directly to Telegram or Discord
- ✅ Crons write results to memory files
- ✅ Actionable items → append to `memory/pending-actions.md`
- ✅ ONLY exception: Morning Report (10:00 AM) consolidates and delivers via Discord

## Changes Made

### 1. Disabled Direct Messaging (26 jobs)

Set `delivery.mode = none` for all jobs except Morning Report:

| ID (prefix) | Job Name | Action |
|-------------|----------|--------|
| ad742767 | Backup diario | ❌ No Telegram → ✅ Write to memory/last-backup.json |
| fdf38b8f | security-audit-weekly | ❌ No Telegram → ✅ Write to memory/YYYY-MM-DD-security-audit-weekly.md |
| c8522805 | fail2ban-alert | ❌ No Telegram → ✅ Write to memory/pending-reports/ or pending-actions.md |
| edc0db6e | lynis-scan-weekly | ❌ No Telegram → ✅ Write to memory/YYYY-MM-DD-lynis-scan.md |
| 78d3556f | rkhunter-scan-weekly | ❌ No Telegram → ✅ Write to memory/YYYY-MM-DD-rkhunter-scan.md |
| 07256dbe | Cleanup audit semanal | ❌ No Telegram → ✅ Write to memory/YYYY-MM-DD-cleanup-audit.md |
| a2cb9eec | Memory Guardian Pro | ❌ No Telegram → ✅ Write to memory/YYYY-MM-DD-memory-guardian.md |
| 6344d609 | Populate Google Sheets | ❌ No Telegram → ✅ Silent operation |
| e763c896 | Backup validation | ❌ No Telegram → ✅ Write to memory |
| e5ebcbf4 | Backup retention cleanup | ❌ No Telegram → ✅ Write to memory/YYYY-MM-DD-backup-cleanup.md |
| b491ec4a | OpenClaw release check | ❌ No Telegram → ✅ Write to memory if updates found |
| 72d256fe | security:rotate-gateway-token | ❌ No Telegram → ✅ Write to memory, add to pending-actions.md |
| 522ae7ca | Resumen Semanal Garmin | ❌ No Telegram → ✅ Write to memory |
| 7a7086e5 | Driving Mode Auto-Reset | ❌ No Telegram → ✅ Silent operation |
| 56ab2039 | Driving Mode Review | ❌ No Telegram → ✅ Write to memory/driving-mode-improvements.md |
| 4de42cb2 | Autoresearch Karpathy | ❌ No Telegram → ✅ Write to memory/YYYY-MM-DD-autoresearch-tracking.md |
| dcae7b06 | Autoimprove Scripts | ❌ No Telegram → ✅ Write to autoimprove/experiment-log.jsonl |
| ed1d9b11 | System Updates Nightly | ❌ No Telegram → ✅ Write to memory/system-updates-last.json |
| 6982dc7e | memory-decay-weekly | ❌ No Telegram → ✅ Silent operation, git commit |
| 53577b95 | Memory Search Reindex | ❌ No Telegram → ✅ Report only on errors |
| ad5285c3 | Lola Toolkit Sync | ❌ No Telegram → ✅ Write to memory if changes found |
| e42db2e2 | Model Reset Nightly | ❌ No Telegram → ✅ Silent operation |
| 8d65b575 | Autoimprove Skills | ❌ No Telegram → ✅ Write to autoimprove/experiment-log.jsonl |
| 881d2943 | Autoimprove Memory | ❌ No Telegram → ✅ Write to autoimprove/experiment-log.jsonl |
| 7926a522 | Surf Conditions Daily | ❌ No Telegram → ✅ Write to memory/surf/conditions-YYYY-MM-DD.md |

### 2. Special Case: Morning Report (cb5d3743)

**ONLY job that sends messages!**

- ✅ Changed channel: Telegram → **Discord**
- ✅ Sends at 10:00 AM Madrid time
- ✅ Consolidates overnight work:
  - Autoimprove results
  - System updates status
  - Backup results
  - Security scan summaries
  - Pending actions from `memory/pending-actions.md`
  - Any warnings or alerts

### 3. Updated Instructions for Key Jobs

Updated message instructions to explicitly state:

- **Write to appropriate memory file**
- **If actionable → append to pending-actions.md**
- **DO NOT send messages to Telegram or Discord**
- **Morning report will pick it up**

Jobs with updated instructions:
- `4de42cb2` - Autoresearch Karpathy
- `fdf38b8f` - Security audit weekly

## Verification

All changes verified with:
```bash
openclaw cron list
```

All jobs now have:
- `delivery.mode = "none"` (except Morning Report)
- `delivery.bestEffort = true` (preserves existing setting)
- Channel references removed or set to "none"

## Benefits

1. **Reduced notification noise** - Only 1 consolidated message per day
2. **Better organization** - All results in memory, searchable
3. **Decision batching** - Manu sees pending actions once, can prioritize
4. **Audit trail** - Everything written to files, can review history
5. **Cleaner Telegram/Discord** - No spam from individual cron jobs

## Files Updated

- `/home/mleon/.openclaw/cron/jobs.json` - All cron job configurations
- `memory/2026-03-23-cron-notification-audit.md` - This audit report

## Next Steps

- ✅ Audit complete
- ⏳ Monitor morning report delivery (tomorrow 10:00 AM)
- ⏳ Verify Discord channel receives the message correctly
- ⏳ Ensure pending-actions.md is populated by cron jobs as needed

## Status

**✅ COMPLETE** - All 26 cron jobs audited and fixed.

No cron job will send direct messages except the Morning Report at 10:00 AM via Discord.
