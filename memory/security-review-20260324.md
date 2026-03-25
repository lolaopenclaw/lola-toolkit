# Nightly Security Review
**Date:** 2026-03-24 21:28:54
**Baseline:** /home/mleon/.openclaw/workspace/memory/security-checksums.json

---

## 1. File Permissions
[CRITICAL] Incorrect permissions on /home/mleon/.openclaw/.env: 660 (should be 600)
- ✅ /home/mleon/.openclaw/openclaw.json: 600
- ✅ /home/mleon/.openclaw/credentials/telegram-allowFrom.json: 600
- ✅ /home/mleon/.openclaw/credentials/telegram-pairing.json: 600
- ✅ /home/mleon/.openclaw/exec-approvals.json: 600
- ✅ /home/mleon/.openclaw/identity/device-auth.json: 600

## 2. Secrets in Version Control
[CRITICAL] Secrets detected in tracked files: 12 occurrences
[CRITICAL]   → CRITICAL-RESTORE-AUDIT.md
[CRITICAL]   → RECOVERY.md
[CRITICAL]   → SETUP-CRITICAL.md
[CRITICAL]   → docs/DRS-disaster-recovery.md
[CRITICAL]   → scripts/archive/setup/setup-critical-restore.sh
[CRITICAL]   → scripts/archive/sheets-populate-proper.sh
[CRITICAL]   → skills/truthcheck/SKILL.md
- ❌ **12 secrets found in tracked files** — review and rotate!

## 3. Security Module Integrity
- ✅ All security modules verified

## 4. Suspicious Log Entries
- ✅ No critical patterns detected in gateway log (last 1000 lines)

## 5. Exec Approvals
- ✅ 0 approvals, no suspicious commands

## 6. Security Scanner Self-Test
- ✅ Security scanner functional (Layer 1: 12 checks, exit code: 0)

## 7. Permissions Matrix
- ✅ /home/mleon/.openclaw/credentials: 700
[WARNING] Protected directory has weak permissions: /home/mleon/.openclaw/identity (755)
- ✅ /home/mleon/.openclaw/cron: 700

---

## Summary

⚠️  **3 findings detected** — review report above.

**Report:** /home/mleon/.openclaw/workspace/memory/security-review-20260324.md
**Log:** /home/mleon/.openclaw/workspace/memory/security-review.log

