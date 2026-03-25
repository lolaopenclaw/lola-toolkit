# Cron Notifications Audit Report

**Date:** 2026-03-25 07:24:37
**Scope:** All scripts + cron jobs

---

## Executive Summary

This audit checks:
1. ✅ Quiet hours compliance (00:00-07:00 Madrid)
2. ✅ Correct routing (topics vs personal chat)
3. ✅ Hardcoded targets (should use topics, not 6884477)
4. ✅ NO_REPLY handling
5. ✅ Message send patterns

---

## Detailed Findings

### Scripts Analysis


#### `apply-model-strategy.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `apt-security-check.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `send-informe-to-discord.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `send-morning-report-to-discord.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `send-to-discord.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `exa-cron-report.sh`

- ❌ **Hardcoded personal chat target (`6884477`)**
```
10:TELEGRAM_ID="6884477"
```
- 📤 **Telegram message calls:**
```bash
25:openclaw message send \
```
- ⚠️ No quiet hours check (sends messages without time check)

#### `exa-search.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `apply-sysctl-hardening.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `critical-update.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `cups-hardening.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `grub-password-protect.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `hardening.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `luks-encryption-setup.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `network-hardening.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `password-policies-harden.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `security-hardening.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `health-to-notion.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `canary-test.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `neural-memory-decay.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `reorganize-daily-memory.sh`

- ✅ No hardcoded personal chat target
- ✅ Has quiet hours awareness

#### `tier-rotation.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `setup-critical-restore.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `setup-git-hooks.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `setup-health-crons.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `share-drive-folder.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `sheets-add-charts.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `sheets-create-charts-local.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `sheets-create-charts.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `sheets-populate-consumption.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `sheets-populate-daily-FIXED.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `sheets-populate-daily.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `sheets-populate-proper.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `sheets-populate-v1.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `sheets-populate-v2.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `sheets-setup.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `skill-security-audit.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `test-skill-security-audit.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `audit-cron-notifications.sh`

- ❌ **Hardcoded personal chat target (`6884477`)**
```
39:3. ✅ Hardcoded targets (should use topics, not 6884477)
84:    # Check 1: Hardcoded personal chat (6884477)
85:    if grep -q "6884477" "$script" 2>/dev/null; then
```
- 📤 **Telegram message calls:**
```bash
106:    TELEGRAM_CALLS=$(grep -n "openclaw message send\|message.*--target\|telegram.*send" "$script" 2>/dev/null || true)
402:openclaw message send \
```
- ✅ Has quiet hours awareness
- ℹ️ Uses `NO_REPLY` mechanism

#### `auto-update-openclaw.sh`

- ✅ No hardcoded personal chat target
- 📤 **Telegram message calls:**
```bash
70:    /home/mleon/.npm-global/bin/openclaw message send \
```
- ⚠️ No quiet hours check (sends messages without time check)

#### `autoimprove-trigger.sh`

- ✅ No hardcoded personal chat target
- 📤 **Telegram message calls:**
```bash
28:openclaw message send --text "/autoimprove --max 10" 2>&1 || {
```
- ✅ Has quiet hours awareness
- 🌙 **Likely night script** (by name pattern)

#### `backup-memory.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)
- 🌙 **Likely night script** (by name pattern)

#### `backup-validator.sh`

- ✅ No hardcoded personal chat target
- ✅ Has quiet hours awareness
- 🌙 **Likely night script** (by name pattern)

#### `best-practices-checker.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `bootstrap.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `calendar-tasks.sh`

- ✅ No hardcoded personal chat target
- ✅ Has quiet hours awareness

#### `check-driving-mode.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `cleanup-drive-backup.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)
- 🌙 **Likely night script** (by name pattern)

#### `deliver-pending-reports.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `garmin-activities-weekly.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `garmin-check-alerts.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `garmin-health-report.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `garmin-historical-analysis.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `garmin-json-export.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `gateway-health-check.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `gemini-reindex-watchdog.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `gemini-reindex.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `gemini-slow-reindex.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `generate-morning-report.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `google-tts.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `health-alerts.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `health-dashboard-auto.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `health-dashboard.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `healthcheck-api.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `informe-matutino-auto.sh`

- ✅ No hardcoded personal chat target
- ✅ Has quiet hours awareness

#### `log-review.sh`

- ✅ No hardcoded personal chat target
- 📤 **Telegram message calls:**
```bash
163:    /home/mleon/.npm-global/bin/openclaw message send \
```
- ⚠️ No quiet hours check (sends messages without time check)

#### `memory-decay.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `memory-guardian.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `memory-maintenance.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `migrate-to-local-models.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `model-release-checker.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `monitor-github-24586-robust.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `nightly-security-review.sh`

- ✅ No hardcoded personal chat target
- 📤 **Telegram message calls:**
```bash
345:        openclaw message send --channel telegram --target "$ALERT_CHANNEL" \
```
- ⚠️ No quiet hours check (sends messages without time check)
- 🌙 **Likely night script** (by name pattern)

#### `install.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `post-commit-backup.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)
- 🌙 **Likely night script** (by name pattern)

#### `pr-reviewer.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `pre-restart-validator.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `proactive-suggestions.sh`

- ✅ No hardcoded personal chat target
- ✅ Has quiet hours awareness

#### `rate-limit-alert-sender.sh`

- ✅ No hardcoded personal chat target
- 📤 **Telegram message calls:**
```bash
34:openclaw message send "$MESSAGE"
```
- ⚠️ No quiet hours check (sends messages without time check)

#### `restore.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `resumen-garmin-semanal-robust.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `review-github-issues.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `sanitize-exposed-secrets.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `secret-get.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `spawn-agents.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `surf-conditions.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `system-updates-nightly.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)
- 🌙 **Likely night script** (by name pattern)

#### `test-proactive-suggestions.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `test-security-scanner.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `track-autoresearch.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `usage-report.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `verify.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `weekly-audit.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

#### `worktree-manager.sh`

- ✅ No hardcoded personal chat target
- ✅ Silent script (no notifications)

---

### Cron Jobs Schedule

- ✅ `368b84ad-e8fb-4c4a-a141-5f03f4465c86` — Day cron (`cron 30 7 * * * @`)
- ✅ `6344d609-2bfd-4295-8471-373125381779` — Day cron (`cron 30 9 * * * (exact)`)
- ✅ `cb5d3743-2d8b-480b-ac64-ef030a689cf0` — Day cron (`cron 0 10 * * * (exact)`)
- ✅ `c8522805-6bc4-451e-887b-69866ddf5b95` — Day cron (`every 6h in 4h 2h ago ok`)
- ✅ `3a82af7d-4acf-4a0f-9772-46efc2895e46` — Day cron (`cron 30 21 * * * @`)
- ✅ `7a7086e5-5a3c-41ad-880b-64a25a927aae` — Day cron (`cron 0 22 * * * (exact)`)
- 🌙 `e42db2e2-f6a8-40f7-810d-91e821cefa6b` — **NIGHT CRON** (`cron 0 0 * * * (exact)`)
- 🌙 `ed1d9b11-5ba1-44ed-8f8b-0b359ddcd45e` — **NIGHT CRON** (`cron 30 1 * * * @`)

---

### High-Risk Scripts (Detailed Review)

Scripts that are known to run at night or send critical notifications:


#### `nightly-security-review.sh`

- ✅ No personal chat target
- ❌ **NO quiet hours check**
- ⚠️ No topic routing found

#### `system-updates-nightly.sh`

- ✅ No personal chat target
- ❌ **NO quiet hours check**
- ⚠️ No topic routing found

#### `backup-memory.sh`

- ✅ No personal chat target
- ❌ **NO quiet hours check**
- ⚠️ No topic routing found

#### `autoimprove-trigger.sh`

- ✅ No personal chat target
- ❌ **NO quiet hours check**
- ⚠️ No topic routing found
- ⚠️ `log-review-matutino.sh`: **Not found** (may have been renamed or removed)
- ⚠️ `morning-briefing.sh`: **Not found** (may have been renamed or removed)

---

## Summary

| Metric | Count |
|--------|-------|
| Total scripts scanned | 0 |
| Total issues | 0 |
| **Critical issues** | **0** |

---

## Recommendations

### 🔴 Priority 1: Fix Critical Issues

[0;32m✅ No critical issues found[0m

### 🟡 Priority 2: Add Quiet Hours Checks

All scripts that send notifications during night hours (00:00-07:00) should check quiet hours:

```bash
# Check quiet hours (00:00-07:00 Madrid)
HOUR=$(TZ=Europe/Madrid date +%H)
if [ "$HOUR" -ge 0 ] && [ "$HOUR" -lt 7 ]; then
    # Only notify if CRITICAL
    [ "$SEVERITY" != "CRITICAL" ] && exit 0
fi
```

### 🟢 Priority 3: Standardize Topic Routing

All notification scripts should use topic routing:

| Script Type | Topic ID | Topic Name |
|-------------|----------|------------|
| Security findings | 29 | 🛡️ Seguridad & Audits |
| System updates | 25 | 🔧 Sistema & Logs |
| Backup/cron errors | 25 | 🔧 Sistema & Logs |
| Health/Garmin | 28 | 🏃 Salud & Garmin |
| Finance | 26 | 💰 Finanzas |
| Daily reports | 24 | 📊 Reportes Diarios |

**Example:**
```bash
openclaw message send \
    --channel telegram \
    --target "-1003768820594" \
    --topic 29 \
    --message "🚨 Security finding: ..."
```

---

## Next Steps

1. ✅ Apply fixes to critical scripts (replace personal chat with topic routing)
2. ✅ Add quiet hours checks to all night scripts
3. ✅ Create night notification protocol document
4. ✅ Update AGENTS.md to reference protocol
5. ✅ Re-run this audit after fixes

---

**Audit completed:** $(date +%Y-%m-%d\ %H:%M:%S)

