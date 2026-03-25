# 🚀 Quick Start: Git History Sanitization

**Generated:** 2026-03-25 07:05 GMT+1  
**For:** Manu / Main Agent

---

## TL;DR

Remove 18 secret occurrences from 6 commits in ~/.openclaw/workspace git history.

**Time:** 2-3 minutes  
**Risk:** Low (triple backup strategy)  
**Reversible:** Yes (within 30 days before git gc)

---

## Pre-Flight Checklist

```bash
# 1. Verify you're in the right place
cd ~/.openclaw/workspace
git status

# 2. Commit any uncommitted changes
git add -A
git commit -m "chore: pre-sanitization checkpoint"

# 3. Verify secrets exist (should show 6 commits)
git log --all --oneline | grep -E "2026-03-25|2026-03-13|2026-03-06|2026-02-23|2026-02-21|2026-02-20" | head -6
```

✅ **Ready to proceed**

---

## Execution (3 Steps)

### Step 1: Run Sanitization
```bash
cd ~/.openclaw/workspace
./git-sanitization.sh
```

**What it does:**
- Creates 3 backups (tag, bundle, archive)
- Installs git-filter-repo if needed
- Rewrites history to replace secrets with placeholders
- Verifies results

**Interactive prompts:**
- Confirmation before rewrite: type `yes`

**Duration:** ~60 seconds

---

### Step 2: Verify Results
```bash
./verify-sanitization.sh
```

**Expected output:**
```
✅ ALL CHECKS PASSED
```

If you see ❌, check SANITIZATION-REPORT.md for troubleshooting.

---

### Step 3: Rotate Secrets
```bash
# Open .env for editing
nano ~/.openclaw/.env

# Update these keys:
# - GOOGLE_CLIENT_SECRET (from console.cloud.google.com)
# - ANTHROPIC_API_KEY (from console.anthropic.com)
# - GEMINI_API_KEY (from console.cloud.google.com)

# Restart OpenClaw
openclaw gateway restart

# Test
openclaw status
```

---

## Rollback (If Needed)

### Quick rollback (within same session):
```bash
cd ~/.openclaw/workspace
git reset --hard pre-sanitization-backup-$(date +%Y%m%d)*
```

### Full rollback (from bundle):
```bash
cd ~/.openclaw
mv workspace workspace.broken
git clone openclaw-backup-pre-sanitization-*.bundle workspace
```

### Nuclear rollback (from archive):
```bash
cd ~/.openclaw
mv workspace workspace.broken
tar -xzf openclaw-full-backup-*.tar.gz
```

---

## What Gets Changed?

### Secrets → Placeholders

| Original | Replacement |
|----------|-------------|
| `***REDACTED***-RFYFN6l5u84_wySc9` | `GOOGLE_CLIENT_SECRET_REDACTED` |
| `***REDACTED***...` | `ANTHROPIC_API_KEY_REDACTED` |
| `***REDACTED***` | `GOOGLE_API_KEY_REDACTED` |
| `sk-proj-abc123` | `OPENAI_PROJECT_KEY_REDACTED` |

### What's Preserved

✅ Commit messages  
✅ Author info  
✅ Timestamps  
✅ File tree  
✅ Branch structure  

### What Changes

⚠️ **Commit hashes** (entire history rewritten)  
⚠️ **Git signatures** (if commits were signed)

---

## Files Delivered

| File | Purpose |
|------|---------|
| `git-sanitization.sh` | Main script (interactive) |
| `verify-sanitization.sh` | Verification checks |
| `SANITIZATION-REPORT.md` | Full audit report |
| `QUICK-START-SANITIZATION.md` | This file |

---

## Safety Net

### Backups Created
1. **Git tag:** `pre-sanitization-backup-YYYYMMDD-HHMMSS`
2. **Git bundle:** `~/.openclaw/openclaw-backup-pre-sanitization-*.bundle`
3. **Full archive:** `~/.openclaw/openclaw-full-backup-*.tar.gz`

### Expiry
- Backups: Keep for 90 days
- Git reflog: 30 days (default)
- After rotation: Old secrets are useless

---

## Common Issues

### "git-filter-repo not found"
Script will auto-install via pip. If it fails:
```bash
pip install --user git-filter-repo
export PATH="$HOME/.local/bin:$PATH"
```

### "uncommitted changes"
```bash
git add -A
git commit -m "temp checkpoint"
```

### Verification fails
Check which secrets remain:
```bash
rg 'GOCSPX|sk-ant-oat01|AIza' memory/ --type md
```

---

## After Sanitization

### ✅ Immediate
- [ ] Secrets rotated (Google, Anthropic)
- [ ] .env updated
- [ ] OpenClaw restarted
- [ ] Integrations tested

### 🔄 Optional
- [ ] Force push to remote (if exists)
- [ ] Notify collaborators (if shared)
- [ ] Add pre-commit hook to prevent future leaks

### 🗑️ Cleanup (after 90 days)
```bash
# Remove backups
rm ~/.openclaw/openclaw-backup-pre-sanitization-*.bundle
rm ~/.openclaw/openclaw-full-backup-*.tar.gz

# Remove backup tag
git tag -d pre-sanitization-backup-*
```

---

## Questions?

See detailed report: `SANITIZATION-REPORT.md`

Or check specific commit:
```bash
git show <commit-hash> | grep REDACTED
```

---

**Status:** ✅ Ready to execute  
**Deliverable by:** Subagent `git-history-sanitization`
