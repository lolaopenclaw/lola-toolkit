# Nightly Security Review
**Date:** 2026-03-26 04:54:19
**Baseline:** /home/mleon/.openclaw/workspace/memory/security-checksums.json

---

## 1. File Permissions
- ✅ /home/mleon/.openclaw/.env: 600
- ✅ /home/mleon/.openclaw/openclaw.json: 600
- ✅ /home/mleon/.openclaw/credentials/telegram-allowFrom.json: 600
- ✅ /home/mleon/.openclaw/credentials/telegram-pairing.json: 600
- ✅ /home/mleon/.openclaw/exec-approvals.json: 600
- ✅ /home/mleon/.openclaw/identity/device-auth.json: 600

## 2. Secrets in Version Control
[CRITICAL] Secrets detected in tracked files: 89 occurrences
[CRITICAL]   → CRITICAL-RESTORE-AUDIT.md
[CRITICAL]   → EXECUTION-CHECKLIST.md
[CRITICAL]   → QUICK-START-SANITIZATION.md
[CRITICAL]   → RECOVERY.md
[CRITICAL]   → SANITIZATION-REPORT.md
[CRITICAL]   → SECURITY-HARDENING-DELIVERY.md
[CRITICAL]   → SETUP-CRITICAL.md
[CRITICAL]   → SUBAGENT-COMPLETION-SUMMARY.md
[CRITICAL]   → config/subagent-validator-config.json
[CRITICAL]   → docs/DRS-disaster-recovery.md
[CRITICAL]   → docs/SDD.md
[CRITICAL]   → git-sanitization.sh
[CRITICAL]   → memory/advanced-harness-research.md
[CRITICAL]   → memory/api-health-implementation.md
[CRITICAL]   → memory/logging-implementation.md
[CRITICAL]   → memory/openclaw-backup.json
[CRITICAL]   → memory/security-hardening-plan.md
[CRITICAL]   → memory/security-scanner-v2-implementation.md
[CRITICAL]   → memory/subagent-validator-implementation.md
[CRITICAL]   → memory/subscription-vs-api-analysis.md
[CRITICAL]   → scripts/.backups.20260325-074357/nightly-security-review.sh
[CRITICAL]   → scripts/api-health-checker.py
[CRITICAL]   → scripts/archive/google-sheets/sheets-populate-proper.sh
[CRITICAL]   → scripts/archive/setup/setup-critical-restore.sh
[CRITICAL]   → scripts/config-drift-detector.py
[CRITICAL]   → scripts/nightly-security-review.sh
[CRITICAL]   → scripts/sanitize-exposed-secrets.sh
[CRITICAL]   → scripts/security-scanner.py
[CRITICAL]   → scripts/subagent-validator.py
[CRITICAL]   → scripts/test-security-scanner.sh
[CRITICAL]   → skills/api-health/SKILL.md
[CRITICAL]   → skills/security-scanner/SKILL.md
[CRITICAL]   → skills/truthcheck/SKILL.md
[CRITICAL]   → verify-sanitization.sh
- ❌ **89 secrets found in tracked files** — review and rotate!

## 3. Security Module Integrity
[CRITICAL] Security module tampered: /home/mleon/.openclaw/workspace/scripts/security-scanner.py (hash mismatch)
[CRITICAL] Security module tampered: /home/mleon/.openclaw/openclaw.json (hash mismatch)
- ❌ **2 security modules tampered** — investigate immediately!

## 4. Suspicious Log Entries
- ✅ No critical patterns detected in gateway log (last 1000 lines)

## 5. Exec Approvals
- ✅ 0 approvals, no suspicious commands

## 6. Security Scanner Self-Test
- ✅ Security scanner functional (Layer 1: 12 checks, exit code: 0)

## 7. Permissions Matrix
- ✅ /home/mleon/.openclaw/credentials: 700
- ✅ /home/mleon/.openclaw/identity: 700
- ✅ /home/mleon/.openclaw/cron: 700

---

## Summary

⚠️  **3 findings detected** — review report above.

**Report:** /home/mleon/.openclaw/workspace/memory/security-review-20260326.md
**Log:** /home/mleon/.openclaw/workspace/memory/security-review.log

