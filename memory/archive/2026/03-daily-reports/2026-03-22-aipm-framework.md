# AIPM Framework — Created 2026-03-22

## Summary

Created comprehensive AIPM (AI Product Management) Framework documentation capturing Manu's transition from Product Owner to AI Product Manager. This formalizes the patterns we've been developing through Lola's work and the Karpathy autoresearch insights.

## What Was Created

### 1. Main Framework Document
**Location:** `/home/mleon/.openclaw/workspace/docs/aipm-framework.md` (34KB)

**Structure:**
- **From PO to AIPM** — Transition from managing human teams to managing AI agents
- **8 Core Principles:**
  1. Define "better" with a number (metrics)
  2. Make evaluation automatic (eval.sh)
  3. One file, one metric, one loop (Karpathy pattern)
  4. Agent-first architecture (agent as interface)
  5. Parallel over sequential (maximize throughput)
  6. Speed over ceremony (dependency-based phases)
  7. Verify before claiming (evidence > assertions)
  8. Sparse but critical human contribution
- **The Toolkit:** program.md, eval.sh, experiment-log.jsonl, dashboard, agent-instructions.md, memory/
- **Workflows:** Nightly loops, on-demand research, agent-first projects, multi-agent orchestration, "loop gordo"
- **4 Real Case Studies:**
  - Autoimprove: 0 → 45+ experiments/night
  - Lola Toolkit: 5.2% improvement, 73% shellcheck reduction
  - Surfing Coach: Agent-first architecture (no app)
  - Cron remediation: 11% → 100% compliance
- **7 Anti-Patterns** — Common mistakes to avoid
- **AIPM Checklist** — 6 questions before starting any project
- **Getting Started Guide** — 7-step onboarding

**Writing approach:**
- Professional, publishable English
- Real examples from our setup (anonymized)
- No sensitive data (tokens, IPs, paths, personal info)
- Could be published to GitHub as part of lola-toolkit

### 2. Quick Reference
**Location:** `/home/mleon/.openclaw/workspace/docs/aipm-quickref.md` (7KB)

One-page cheat sheet with:
- Core shift table (PO vs AIPM)
- 8 principles (condensed)
- Toolkit templates
- Common workflows
- Decision trees (agent vs app, ready for loop?)
- Anti-patterns
- AIPM checklist
- Quick start (5 steps)
- Metrics & formulas
- Common commands
- Resource estimates
- Troubleshooting guide

**Purpose:** Quick lookup without reading full framework.

## Key Insights Captured

### The Fundamental Shift
**Traditional PO:** Manages activities (sprint planning, PR reviews, team coordination)  
**AIPM:** Manages outcomes (define metric, set constraints, review results)

**Key quote:**
> "A PO defines value for a human team. An AIPM defines 'better' for agents and lets them run the loops."

### The Karpathy Pattern (Generalized)
```
Objective → Code → Evaluation → Score → Decision → Loop
```

Not just for ML research—applicable to:
- Script optimization (execution time)
- Code quality (linting, complexity)
- Documentation (comprehension, completeness)
- System configuration (performance, security)

### Agent-First Architecture
Major insight: Many "app" problems are actually "context synthesis" problems.

**Don't build an app when:**
- Problem is conversational
- Highly personalized (context-dependent)
- Exploratory use case
- Frequent requirement changes

**Build agent-first:**
- Data pipelines feed the agent
- Knowledge base provides context
- User asks questions
- Agent synthesizes answers
- Continuous improvement loop

**Example:** Surf coach doesn't need an app—just data + agent.

### The Power of Parallel Agents
**Traditional:** 1 human does task A, then B, then C (sequential)  
**AIPM:** 3 agents do A, B, C simultaneously (parallel)

**Scaling:**
- Start: 1 agent, 10 experiments/night (~$0.05)
- Current: 3 agents, 45+ experiments/night (~$0.15)
- Future: N agents, 100+ experiments/night (~$0.30-0.50)

**Limit:** System resources (CPU, memory) and cost budget, not human coordination.

### Verification Protocol
Critical learning from our cron failures and other issues:

**Never claim success without evidence.**

**Protocol:**
1. Propose solution
2. **Run verification command**
3. **Show output**
4. Confirm results
5. Then claim success

**Prevents:**
- Hallucinated fixes
- Partial solutions
- Undetected regressions

## Relationship to Master Plan

This framework captures the theoretical foundation for the "Loopy Era" described in the 2026-03-22 Master Plan.

**Master Plan implements:**
- Phase 1 (Stability): Foundation for reliable loops
- Phase 2 (Auto-mejora): Karpathy Loop at scale
- Phase 3 (Surf Coach): Agent-first architecture
- Phase 4 (Consolidation): AIPM as reproducible methodology

**This framework documents:**
- Why this approach works
- How to apply it to new domains
- Lessons learned from our implementations
- Reusable patterns for others

## Publishing Strategy

**Publishable as-is:**
- No sensitive data
- Anonymized examples
- Professional tone
- Clear structure
- MIT License suggested

**Potential venues:**
- GitHub (lola-toolkit repo)
- Blog post / Medium article
- HN submission (Show HN: AIPM Framework)
- Presentation / talk

**Value proposition:**
- Practical, not theoretical
- Battle-tested patterns
- Real case studies with numbers
- Reproducible methodology

## Next Steps (Not Done Here)

Potential extensions (not in scope for this task):
- [ ] Video walkthrough of implementing first loop
- [ ] Template repo with program.md + eval.sh examples
- [ ] Metrics dashboard implementation
- [ ] Integration with existing PM tools (Notion, Linear)
- [ ] Community contributions (other case studies)

## Metrics

**Documents created:** 2 (framework + quickref)  
**Total content:** ~41KB  
**Structure:** 9 major sections, 4 case studies, 7 anti-patterns  
**Time investment:** ~90 minutes (research + writing + editing)  
**Publishable:** Yes (no PII, no secrets)  
**Value:** Captures 3+ months of learning in reusable format

## Files Changed

```
Created:
- docs/aipm-framework.md (34,321 bytes)
- docs/aipm-quickref.md (7,267 bytes)
- memory/2026-03-22-aipm-framework.md (this file)
```

## Commit Message (For Git)

```
feat: AIPM Framework - AI Product Management methodology

Created comprehensive framework documenting the transition from
Product Owner (managing human teams) to AI Product Manager 
(managing AI agents).

Key components:
- 8 core principles (metrics, automation, loops, agent-first)
- Complete toolkit (program.md, eval.sh, experiment logs)
- 4 real case studies (autoimprove, lola-toolkit, surf coach, cron)
- Decision frameworks and anti-patterns
- Quick-reference cheat sheet

Inspired by Karpathy's autoresearch pattern and refined through
real-world implementation. Publishable under MIT license.

Files:
- docs/aipm-framework.md (34KB main document)
- docs/aipm-quickref.md (7KB cheat sheet)
- memory/2026-03-22-aipm-framework.md (session notes)
```

---

**Status:** ✅ Complete  
**Quality:** Publication-ready  
**Next:** Git commit + optional publishing
