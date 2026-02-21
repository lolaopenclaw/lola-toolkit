# OpenClaw Contributions Roadmap

**Goal:** Contribute skill-security-audit.sh + 4 more tools over 4-5 weeks  
**Status:** Week 1 (Research & Planning)  
**Author:** Lola + Manu  

---

## 📅 Timeline

### ✅ Week 1: Research & Planning (2026-02-21)

**Completed:**
- [x] Improved skill-security-audit.sh (--json, --strict, better eval detection)
- [x] Test suite (15/15 passing)
- [x] PR documentation (9KB, comprehensive)
- [x] Read CONTRIBUTING.md from OpenClaw
- [x] Prepared Discussion draft (DISCUSSION-DRAFT.md)
- [x] Documented strategy in memory

**Still TODO (this week):**
- [ ] **Fork openclaw/openclaw** — Create personal fork on GitHub
- [ ] **Search issues/discussions** — Look for security, skills, audit related
- [ ] **Set up dev environment** — Clone fork, understand repo structure
- [ ] **Final review** — Ensure skill-security-audit is completely generic

---

### 📅 Week 2: Discussion & Feedback (2026-02-28 target)

**Tasks:**
- [ ] **Post GitHub Discussion** — Use DISCUSSION-DRAFT.md as template
- [ ] **Wait for maintainer feedback** — 2-3 days typical
- [ ] **Engage in comments** — Answer questions, clarify design
- [ ] **Iterate if needed** — Adjust based on feedback
- [ ] **Get thumbs-up** — Maintainers say "looks good, submit PR"

**Success criteria:**
- Discussion opened
- At least 1 maintainer engaged
- No objections raised
- Green light to submit PR

---

### 📅 Week 3: Submit PR #1 (2026-03-07 target)

**PR Content:**
```
Title: feat: Add Skill Security Audit Tool

Files:
- scripts/skill-security-audit.sh (514 lines)
- scripts/test-skill-security-audit.sh (test suite)
- docs/skill-security-audit.md (documentation)
- tests/ folder (if applicable)

Body:
- Link to Discussion
- Summary of changes
- Testing instructions
- Examples
```

**Expected timeline:**
- PR opened → Review within 1-3 days
- Feedback cycle → 3-5 days
- Iteration → 3-5 days per round
- Merge → When all conversations resolved

---

### 📅 Week 4+: Next Contributions (2026-03-14+)

**Based on PR #1 feedback:**

**Option A: Continue with PR #2 (if PR #1 merged)**
- Tool #2: memory-guardian.sh (high impact, universal)
- Same workflow: Discussion → Feedback → PR

**Option B: Pause for PR #1 feedback**
- Address review comments
- Iterate on design
- Optimize based on maintainer preferences

**Option C: Parallel track**
- Start genericizing Tool #2
- While waiting for PR #1 review
- Have backup ready to submit

---

## 🎯 5 Contributions (Prioritized)

| # | Tool | Status | Week | Complexity | Impact |
|---|------|--------|------|-----------|--------|
| 1 | skill-security-audit.sh | ✅ Ready | 3 | Low | High |
| 2 | memory-guardian.sh | Backlog | 4 | Medium | High |
| 3 | critical-update.sh | Backlog | 5 | Medium | Medium |
| 4 | restore.sh | Backlog | 6+ | High | High |
| 5 | garmin-health | Backlog | 7+ | Medium | Low |

---

## 📋 Checklist for Week 1 (This Week)

### Step 1: GitHub Setup
- [ ] Verify GitHub account ready
- [ ] GitHub SSH keys configured (if not, set up)
- [ ] Check GitHub email verified

### Step 2: Fork Repository
- [ ] Go to https://github.com/openclaw/openclaw
- [ ] Click "Fork" (top right)
- [ ] Select your account as fork destination
- [ ] Clone fork locally:
  ```bash
  git clone https://github.com/YOUR_USERNAME/openclaw.git
  cd openclaw
  git remote add upstream https://github.com/openclaw/openclaw.git
  ```

### Step 3: Explore Repository
- [ ] Read `README.md` (understand project)
- [ ] Read `CONTRIBUTING.md` ✅ (already done)
- [ ] Check `/scripts` or `/tools` directory structure
- [ ] Look for existing security/audit tools
- [ ] Search issues: "security", "audit", "skill vetting"
- [ ] Search discussions: "skill security", "review", "vet"

### Step 4: Prepare Discussion
- [ ] Copy DISCUSSION-DRAFT.md content
- [ ] Personalize (your name, GitHub handle)
- [ ] Adjust tone if needed
- [ ] Proof-read for typos
- [ ] Test: Can you copy/paste without weird formatting?

### Step 5: Final Review of Script
- [ ] Verify `$OPENCLAW_WORKSPACE` used everywhere ✅
- [ ] Check no hardcoded paths ✅
- [ ] Verify English comments/output ✅
- [ ] Run test suite one more time ✅
- [ ] Document any edge cases discovered

### Step 6: Post Discussion
- [ ] Go to https://github.com/openclaw/openclaw/discussions
- [ ] Click "New discussion"
- [ ] Category: "General" or "Feature request"
- [ ] Paste DISCUSSION-DRAFT.md (adapt as needed)
- [ ] Submit
- [ ] Copy Discussion URL to memory for tracking

---

## 📞 Key Contacts

### OpenClaw Maintainers (from CONTRIBUTING.md)
- **Peter Steinberger** (@steipete) — Benevolent Dictator
- **Shadow** (@thewilloftheshadow) — Community, Clawhub, Discord
- **Vignesh** (@vignesh07) — Memory, TUI
- **Tyler Yust** (@tyler6204) — Agents, cron
- **Seb Slight** (@sebslight) — Docs, Runtime Hardening ⭐ (likely interested in security)
- **Mariano Belinky** (@mbelinky) — **Security expert** ⭐

**Tip:** If no response within 3 days, mention @steipete in a comment to get attention.

### Communication
- **Discord:** https://discord.gg/qkhbAGHRBT (ask in #help or #general)
- **Twitter/X:** @openclaw, @steipete
- **Security:** security@openclaw.ai (for security reports)

---

## 🚀 Success Metrics

### Week 1 (this week)
- [ ] Fork created
- [ ] Issues/discussions reviewed
- [ ] Discussion draft finalized
- [ ] Ready to post

### Week 2 (next week)
- [ ] Discussion posted
- [ ] ≥1 maintainer engaged
- [ ] Feedback received
- [ ] Green light to PR

### Week 3 (2026-03-07)
- [ ] PR #1 submitted
- [ ] Tests passing in CI
- [ ] Review started

### Week 4+
- [ ] PR #1 merged OR
- [ ] Iterating on feedback
- [ ] Tool #2 in progress

---

## ⚠️ Potential Blockers & Solutions

| Blocker | Solution |
|---------|----------|
| No response to Discussion | Mention @steipete, ask in Discord |
| Maintainer wants changes | Pivot + iterate, no big deal |
| Script doesn't work on their env | Debug + test on clean Ubuntu 22.04 |
| Placement disagree (scripts/ vs tools/) | Flexible, follow their preference |
| They want ClawHub instead | Move to clawhub/clawhub repo instead |
| Security concerns raised | Discuss threat model, document assumptions |

---

## 💾 Files Reference

```
CONTRIB/
├── CONTRIBUTION-PLAN.md           ← General 4-week strategy
├── DISCUSSION-DRAFT.md            ← GitHub Discussion template
├── ROADMAP.md                     ← This file (detailed week-by-week)
├── DOCS/
│   └── skill-security-audit.md    ← Full PR documentation
└── EXAMPLES/
    └── (placeholder for example PRs if needed)

scripts/
├── skill-security-audit.sh        ← Main tool (514 lines)
└── test-skill-security-audit.sh   ← Test suite (15 tests)

memory/
└── 2026-02-21-openclaw-contributions.md ← Process notes
```

---

## 🎓 Learning Resources

If needed:
- **Git workflow:** https://guides.github.com/introduction/flow/
- **GitHub Discussions:** https://docs.github.com/en/discussions
- **PR best practices:** https://github.blog/2015-01-21-how-to-write-the-perfect-pull-request/
- **OpenClaw repo:** https://github.com/openclaw/openclaw
- **OpenClaw docs:** https://docs.openclaw.ai

---

## 📊 Expected Outcomes

**By end of Week 3:**
- [ ] First PR submitted to OpenClaw
- [ ] Community sees our tool
- [ ] Feedback channels open

**By end of Week 4:**
- [ ] PR #1 merged OR iterating on feedback
- [ ] Tool #2 in progress
- [ ] Established presence as contributor

**By end of 5 weeks:**
- [ ] ≥1 PR merged
- [ ] ≥2 tools contributed
- [ ] Potential maintainer path discussion

---

**Let's ship it! 🦞**
