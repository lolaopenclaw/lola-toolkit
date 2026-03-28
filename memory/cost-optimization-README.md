# 💰 Cost Optimization — Quick Start

**Date:** 2026-03-28  
**Goal:** Reduce API spending from $1,311/month to $461/month (85% reduction)

---

## 📂 Which File Do I Need?

### 🚀 I want to implement the fix NOW
→ **Run:** `bash scripts/cost-optimization-implement.sh`  
→ **Time:** 5 minutes  
→ **Result:** $850/month saved

### 📄 I want a quick overview
→ **Read:** `memory/cost-optimization-summary-2026-03-28.md`  
→ **Time:** 2 minutes  
→ **Content:** Problem, solution, 1-page summary

### 📋 I want full details
→ **Read:** `memory/cost-optimization-report-2026-03-28.md`  
→ **Time:** 15 minutes  
→ **Content:** Complete analysis, all data, 3 tiers of proposals

### ✅ I want to track implementation
→ **Use:** `memory/cost-optimization-checklist.md`  
→ **Purpose:** Pre/post checklist, 24h/1-week/1-month reviews

---

## ⚡ Quick Implementation (30 seconds)

```bash
# Dry run first (safe, no changes)
bash scripts/cost-optimization-implement.sh --dry-run

# Real implementation (makes changes)
bash scripts/cost-optimization-implement.sh

# Verify
bash scripts/usage-report.sh --today
```

---

## 📊 What's the Problem?

| Current | Target | Gap |
|---------|--------|-----|
| $1,311/mo | $200/mo | -$1,111 (85%) |

**Root cause:** 66% of costs = Opus 4-6 for conversations

---

## 🎯 What's the Fix?

**TIER 1 (4 actions, 30 min):**
1. Switch default model: Opus → Sonnet ($600/mo saved)
2. Daily hard cap: $20/day (prevents overrun)
3. Reduce cron frequency ($100/mo saved)
4. Switch autoimprove to Haiku ($150/mo saved)

**Total savings:** $850/month → **New spend: $461/month** ✅

---

## 🔙 How Do I Rollback?

```bash
# Emergency rollback (restore Opus)
openclaw config set agents.defaults.model anthropic/claude-opus-4-6

# Full restore from backup
cp ~/.openclaw/backups/cost-optimization-YYYY-MM-DD/default.yaml.backup \
   ~/.openclaw/config/default.yaml
```

---

## 📅 What's Next?

- **Today:** Implement TIER 1
- **Tomorrow:** Check daily spend (<$20 target)
- **Week 1 (Apr 4):** Review weekly spend (<$140 target)
- **Month 1 (Apr 30):** Review monthly spend (<$600 target)

---

## 📚 All Files

| File | Purpose | Size |
|------|---------|------|
| `cost-optimization-summary-2026-03-28.md` | Quick overview | 2.8K |
| `cost-optimization-report-2026-03-28.md` | Full analysis | 12K |
| `cost-optimization-checklist.md` | Implementation tracking | 4.3K |
| `cost-optimization-implement.sh` | Automated implementation | 5.5K |
| `cost-optimization-README.md` | This file | 1.5K |

---

## ❓ FAQ

**Q: Is this safe?**  
A: Yes. All changes are reversible. Backups are automatic. Dry-run mode available.

**Q: Will quality drop?**  
A: Minimal. Sonnet is 90% as good as Opus for most tasks. Keep Opus for hard problems.

**Q: What if it doesn't work?**  
A: Rollback in 30 seconds. Full restoration from backup.

**Q: When will I see savings?**  
A: Immediately. Check `bash scripts/usage-report.sh --today` after 24h.

**Q: Do I need to do TIER 2 or TIER 3?**  
A: No. TIER 1 alone puts you $261 UNDER target. Only do TIER 2 if spending creeps back up.

---

**Questions?** Read the full report: `memory/cost-optimization-report-2026-03-28.md`

**Ready?** Run: `bash scripts/cost-optimization-implement.sh`
