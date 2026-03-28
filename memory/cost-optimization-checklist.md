# ✅ Cost Optimization — Post-Implementation Checklist

**Implementation Date:** _____________  
**Implemented By:** _____________

---

## Pre-Implementation

- [ ] Read full report: `memory/cost-optimization-report-2026-03-28.md`
- [ ] Review executive summary: `memory/cost-optimization-summary-2026-03-28.md`
- [ ] Backup created: `~/.openclaw/backups/cost-optimization-YYYY-MM-DD/`
- [ ] Current spending documented: $_______/day

---

## Implementation (TIER 1)

### 1. Model Switch
- [ ] Default model changed: Opus → Sonnet
- [ ] Verification: `openclaw config get agents.defaults.model`
- [ ] Expected output: `anthropic/claude-sonnet-4-5`

### 2. Cron Frequency Reduction
- [ ] Notification flush: 3h → 6h (ID: 529c7e09...)
- [ ] Memory reindex: daily → weekly (ID: 53577b95...)
- [ ] Verification: `openclaw cron list | grep -E "Notification|Memory"`

### 3. Autoimprove → Haiku
- [ ] Scripts cron → Haiku (ID: ae60d161...)
- [ ] Skills cron → Haiku (ID: f22e5eaf...)
- [ ] Memory cron → Haiku (ID: 5645185b...)
- [ ] Verification: `openclaw cron list | grep Autoimprove`

### 4. Cost Guardian
- [ ] Script created: `scripts/cost-guardian.sh`
- [ ] Script executable: `chmod +x scripts/cost-guardian.sh`
- [ ] Dry run test: `bash scripts/cost-guardian.sh`
- [ ] (Optional) Hourly cron added

---

## Post-Implementation Testing (First 24h)

### Hour 1
- [ ] Test conversation quality (Sonnet vs Opus)
- [ ] Check daily spend: `bash scripts/usage-report.sh --today`
- [ ] Expected: <$20/day
- [ ] Actual: $_______

### Hour 6
- [ ] Verify crons still running
- [ ] Check for errors: `openclaw cron list | grep error`
- [ ] Daily spend update: $_______

### Hour 24
- [ ] Daily spend final: $_______
- [ ] Quality assessment: ___/10
- [ ] Any issues? (describe below)

**Issues/Notes:**
```
(Write any problems encountered here)
```

---

## Week 1 Review (April 4, 2026)

### Metrics
- [ ] Daily average spend: $_______
- [ ] Weekly total: $_______
- [ ] Target: <$140/week
- [ ] Quality score (Manu): ___/10

### Quality Check
- [ ] Conversation quality acceptable? Y/N
- [ ] Crons functioning properly? Y/N
- [ ] Any data loss/corruption? Y/N
- [ ] Any service interruptions? Y/N

### Decision
- [ ] **SUCCESS** → Keep TIER 1, skip TIER 2
- [ ] **PARTIAL** → Adjust and monitor another week
- [ ] **FAILURE** → Rollback (see below)

---

## Rollback (If Needed)

### Emergency Rollback (Quality Issues)
```bash
# Restore Opus
openclaw config set agents.defaults.model anthropic/claude-opus-4-6

# Restore cron frequencies
openclaw cron edit 529c7e09-940c-4b95-ae75-f0de2e84e41b --schedule "55 */3 * * *"
openclaw cron edit 53577b95-936e-4f91-b4b9-0c3c3ad630f2 --schedule "30 4 * * *"

# Restore Sonnet for autoimprove
openclaw cron edit ae60d161-3a14-4029-a4de-8b2ba08be992 --model sonnet
openclaw cron edit f22e5eaf-2d28-4ffa-b733-f6c5b007dc61 --model sonnet
openclaw cron edit 5645185b-ac2f-4631-80d5-8eaf7320aed1 --model sonnet
```

### Restore from Backup
```bash
cp ~/.openclaw/backups/cost-optimization-YYYY-MM-DD/default.yaml.backup \
   ~/.openclaw/config/default.yaml
```

- [ ] Rollback executed: Date _____________
- [ ] Reason: _________________________________
- [ ] Spending after rollback: $_______/day

---

## Month 1 Review (End of April 2026)

### Final Metrics
- [ ] Total April spend: $_______
- [ ] Target: <$600
- [ ] Daily average: $_______
- [ ] Savings vs. baseline: $_______

### Outcomes
- [ ] **SUCCESS** (spend <$600) → Archive report, done
- [ ] **PARTIAL** (spend $600-900) → Consider selective TIER 2
- [ ] **FAILURE** (spend >$900) → Full review + TIER 2

### Lessons Learned
```
(What worked, what didn't, what to change)
```

---

## Notes

**Backup Location:** `~/.openclaw/backups/cost-optimization-YYYY-MM-DD/`  
**Original Config:** `default.yaml.backup`  
**Original Crons:** `cron-list-backup.txt`

**Support Docs:**
- Full Report: `memory/cost-optimization-report-2026-03-28.md`
- Summary: `memory/cost-optimization-summary-2026-03-28.md`
- Implementation Script: `scripts/cost-optimization-implement.sh`

---

**Sign-off:**

- [ ] Implementation complete: _____________ (Date)
- [ ] Week 1 review complete: _____________ (Date)
- [ ] Month 1 review complete: _____________ (Date)
- [ ] Final decision: KEEP / ROLLBACK / ADJUST

**Approved by:** Manu (signature) _____________
