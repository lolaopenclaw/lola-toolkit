# 📋 Git Sanitization Execution Checklist

**Generated:** 2026-03-25 07:10 GMT+1  
**Use this:** Step-by-step validation before/during/after sanitization

---

## ✅ PRE-EXECUTION (5 minutes)

### Environment Check
- [ ] You are in: `~/.openclaw/workspace`
- [ ] Git status: No uncommitted changes
- [ ] Disk space: >2 GB free (for backups)
- [ ] Python installed: `python3 --version`
- [ ] Git version: `git --version` (>= 2.22)

**Commands:**
```bash
cd ~/.openclaw/workspace
git status
df -h ~
python3 --version
git --version
```

---

### Read Documentation
- [ ] Read: `QUICK-START-SANITIZATION.md`
- [ ] Understand: Blast radius (6 commits affected)
- [ ] Aware: Commit hashes WILL change
- [ ] Confirm: You can rotate secrets after

---

### Verify Secrets Exist (Baseline)
- [ ] Run baseline check:
```bash
git log --all --full-history -S"GOCSPX" --format="%H" | wc -l
# Expected: 1

git log --all --full-history -S"sk-ant-oat01" --format="%H" | wc -l
# Expected: 1

git log --all --full-history -S"AIza" --format="%H" | wc -l
# Expected: 6
```

---

## 🚀 EXECUTION (2 minutes)

### Run Sanitization Script
- [ ] Execute: `./git-sanitization.sh`
- [ ] Watch for: Backup creation messages
- [ ] When prompted: Type `yes` to confirm
- [ ] Wait for: "Cleanup complete" message

**Output should show:**
```
✅ Created tag: pre-sanitization-backup-YYYYMMDD-HHMMSS
✅ Created bundle: ../openclaw-backup-pre-sanitization-*.bundle
✅ Created archive: ../openclaw-full-backup-*.tar.gz
✅ Installed git-filter-repo
✅ History rewrite complete
```

---

## 🔍 VERIFICATION (1 minute)

### Run Verification Script
- [ ] Execute: `./verify-sanitization.sh`
- [ ] All checks: GREEN ✅
- [ ] Exit code: 0

**Expected output:**
```
✅ ALL CHECKS PASSED
```

If any check shows ❌ RED:
1. STOP immediately
2. Check `SANITIZATION-REPORT.md` troubleshooting section
3. Consider rollback if multiple failures

---

### Manual Spot Check
- [ ] No secrets in HEAD:
```bash
rg '***REDACTED***|***REDACTED***|***REDACTED***' memory/ || echo "CLEAN ✅"
```

- [ ] Placeholders inserted:
```bash
git log --all --oneline | grep -c "REDACTED"
# Expected: >0
```

- [ ] Commit count unchanged:
```bash
git rev-list --all --count
# Expected: 280
```

---

## 🔐 SECRET ROTATION (10 minutes)

### Google OAuth Client Secret
- [ ] Console: https://console.cloud.google.com/apis/credentials
- [ ] Project: optimal-courage-486312-c8
- [ ] Delete old: `***REDACTED***-RFYFN6l5u84_wySc9`
- [ ] Create new: OAuth 2.0 Client ID
- [ ] Copy new secret
- [ ] Update: `~/.openclaw/.env` → `GOOGLE_CLIENT_SECRET=GOCSPX-NEW-SECRET`

---

### Anthropic API Key
- [ ] Console: https://console.anthropic.com/settings/keys
- [ ] Delete old: `***REDACTED***...`
- [ ] Create new: API Key
- [ ] Copy new key
- [ ] Update: `~/.openclaw/.env` → `ANTHROPIC_API_KEY=sk-ant-NEW-KEY`

---

### Google Gemini API Key (if active)
- [ ] Console: https://console.cloud.google.com/apis/credentials
- [ ] Delete old: `***REDACTED***`
- [ ] Create new: API Key (restrict to Gemini API)
- [ ] Copy new key
- [ ] Update: `~/.openclaw/.env` → `GEMINI_API_KEY=AIza-NEW-KEY`

---

### Verify .env
- [ ] File exists: `~/.openclaw/.env`
- [ ] Contains: `GOOGLE_CLIENT_SECRET=GOCSPX-...`
- [ ] Contains: `ANTHROPIC_API_KEY=sk-ant-...`
- [ ] Contains: `GEMINI_API_KEY=AIza...` (if used)
- [ ] Permissions: `chmod 600 ~/.openclaw/.env`

---

## 🔄 RESTART & TEST (5 minutes)

### Restart OpenClaw
- [ ] Stop: `openclaw gateway stop`
- [ ] Wait 5 seconds
- [ ] Start: `openclaw gateway start`
- [ ] Check: `openclaw status`

**Expected:** Gateway running, no auth errors

---

### Test Integrations

#### Google Workspace (gog)
- [ ] Test: `gog calendar list` or `gog gmail list`
- [ ] Expected: Calendar/email list (no auth errors)

#### Anthropic Claude
- [ ] Test: Ask main agent a question
- [ ] Expected: Response from Claude (no API errors)

#### Garmin (if using)
- [ ] Test: Check Garmin health data fetch
- [ ] Expected: Data retrieved (no OAuth errors)

---

## 🗂️ CLEANUP (Optional, after 90 days)

### Remove Backups
- [ ] Verify sanitization worked for 90 days
- [ ] Remove bundle: `rm ~/.openclaw/openclaw-backup-pre-sanitization-*.bundle`
- [ ] Remove archive: `rm ~/.openclaw/openclaw-full-backup-*.tar.gz`
- [ ] Remove tag: `git tag -d pre-sanitization-backup-*`

---

## 🚨 ROLLBACK (Only if needed)

### Method 1: Git Tag (Quick)
```bash
cd ~/.openclaw/workspace
git reset --hard pre-sanitization-backup-YYYYMMDD-HHMMSS
git clean -fdx
```

### Method 2: Git Bundle (Safe)
```bash
cd ~/.openclaw
mv workspace workspace.broken
git clone openclaw-backup-pre-sanitization-*.bundle workspace
```

### Method 3: Full Archive (Nuclear)
```bash
cd ~/.openclaw
mv workspace workspace.broken
tar -xzf openclaw-full-backup-*.tar.gz
```

---

## 📊 Success Criteria

All must be ✅:
- [ ] Sanitization script completed without errors
- [ ] Verification script: ALL CHECKS PASSED
- [ ] No secrets in: `rg 'GOCSPX|sk-ant|AIza' memory/`
- [ ] Secrets rotated (Google OAuth, Anthropic, Gemini)
- [ ] .env updated with new secrets
- [ ] OpenClaw restarted successfully
- [ ] Integrations tested (gog, Claude, Garmin)
- [ ] Backups exist in `~/.openclaw/`

---

## 🆘 Troubleshooting

### "git-filter-repo not found"
```bash
pip install --user git-filter-repo
export PATH="$HOME/.local/bin:$PATH"
```

### "uncommitted changes"
```bash
git add -A
git commit -m "temp checkpoint before sanitization"
```

### Verification fails (secrets still found)
1. Check replacements file: `/tmp/git-replacements-*.txt`
2. Add missing patterns
3. Run rollback method 1 (git tag)
4. Re-run sanitization

### OpenClaw won't start after rotation
1. Check .env syntax: `cat ~/.openclaw/.env`
2. Verify secret format (no quotes, no spaces)
3. Check logs: `openclaw gateway logs`
4. Rollback secrets if needed

### Integration broken (gog/Claude/Garmin)
1. Test API directly (curl or tool CLI)
2. Verify secret is correct in console
3. Re-rotate if secret was copied incorrectly
4. Check OpenClaw logs for auth errors

---

**Estimated total time:** 20-25 minutes (including secret rotation)  
**Point of no return:** After typing "yes" in sanitization script  
**Rollback window:** 30 days (git reflog) + indefinite (backups)
