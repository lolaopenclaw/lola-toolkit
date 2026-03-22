# AIPM Quick Reference

**AI Product Management Cheat Sheet**

---

## The Core Shift

| Traditional PO | AI Product Manager |
|----------------|-------------------|
| User stories | program.md files |
| Sprint planning | Loop definition |
| PR reviews | Experiment logs |
| 2-week cycles | 24/7 iteration |
| Manage activities | Manage outcomes |

**Key insight:** You define "better", agents execute the 500 rounds.

---

## The 8 Principles

1. **Define "better" with a number** — If you can't measure it, you can't improve it
2. **Make evaluation automatic** — No human judgment in the loop
3. **One file, one metric, one loop** — Focus beats multitasking
4. **Agent-first architecture** — Agent IS the interface, not a tool
5. **Parallel over sequential** — Maximize throughput
6. **Speed over ceremony** — Phase by dependencies, not calendar
7. **Verify before claiming** — Evidence > assertions
8. **Sparse but critical human** — Direction, not execution

---

## The Toolkit

### program.md
```
# Objective: [Clear goal]
# Metric: [How to measure success]
# Constraints: [What must NOT change]
# Mutable Files: [What agent can modify]
# Stopping Criteria: [When to stop]
```

### eval.sh
```bash
#!/bin/bash
# Measure current state
# Return single number (lower = better)
# Run in <5 minutes
```

### experiment-log.jsonl
```json
{"timestamp": "...", "target": "...", "score_before": 100, 
 "score_after": 85, "kept": true}
```

---

## Common Workflows

### Nightly Loop
```
02:00 cron → Agent reads program.md → Iterate 50x → 
Morning report (improvements applied)
```

### Subagent Delegation
```
Main: "Research X" → Spawn subagent → 
Subagent investigates → Reports back → Main acts
```

### Agent-First Project
```
Data pipelines → Knowledge base → Agent instructions → 
User asks agent (not app) → Continuous improvement
```

---

## Decision Trees

### Agent vs App?

**Choose AGENT if:**
- Conversational / personalized
- Context-heavy decisions
- Exploratory use case
- Small user base (<1k)

**Choose APP if:**
- Visual / spatial interface
- Standardized workflow
- Real-time collaboration
- High scale (>10k users)

### Ready for Autonomous Loop?

**YES if:**
- ✅ Clear numeric metric
- ✅ Automated evaluation
- ✅ Runs in bounded time
- ✅ No human judgment needed

**NO if:**
- ❌ "Better" is subjective
- ❌ Requires human review each time
- ❌ Takes hours per evaluation
- ❌ Safety-critical without verification

---

## Anti-Patterns to Avoid

| ❌ Don't | ✅ Do Instead |
|---------|--------------|
| Micromanage every step | Set objectives, review outcomes |
| "Make it better" (no metric) | Define numeric success criteria |
| Sprint-based delays | Work at dependency speed |
| Build app for conversational task | Agent-first architecture |
| Trust agent claims | Verify with evidence |
| Block main session | Spawn subagents for heavy work |

---

## The AIPM Checklist

Before starting any project:

- [ ] **What is "better"?** (numeric metric defined)
- [ ] **Can it be measured automatically?** (eval.sh works)
- [ ] **What can the agent change?** (mutable scope clear)
- [ ] **What must stay fixed?** (constraints documented)
- [ ] **How do I verify results?** (verification plan ready)
- [ ] **App or agent interface?** (decision made)

---

## Quick Start (5 Steps)

1. **Pick small target** (optimize script, improve tests)
2. **Define metric** (execution time, coverage %, error count)
3. **Create eval.sh** (measure current state → number)
4. **Write program.md** (objective, metric, constraints)
5. **Run loop** (manual first, automate next)

---

## Key Metrics to Track

### Per-Project
- Experiments run (total attempts)
- Success rate (% improvements kept)
- Current score vs baseline
- Best single improvement
- Trend (improving/plateauing)

### Overall AIPM Effectiveness
- Experiments per night (throughput)
- Improvements per week (delivery)
- Cost per improvement (efficiency)
- Human hours saved (ROI)

---

## Formulas

### Composite Score
```
score = performance_metric + (errors × penalty)
Example: runtime_ms + (error_count × 1000)
```

### Improvement Percentage
```
improvement_pct = ((before - after) / before) × 100
Example: ((180 - 58) / 180) × 100 = 67.7%
```

### Success Rate
```
success_rate = (kept / total_experiments) × 100
Example: (12 / 45) × 100 = 26.7%
```

---

## Common Commands

### Experiment Log Analysis
```bash
# Total experiments
wc -l experiment-log.jsonl

# Success rate
jq -r '.kept' experiment-log.jsonl | grep -c true

# Best improvement
jq -r '.improvement' experiment-log.jsonl | sort -n | tail -1

# Recent trend
tail -20 experiment-log.jsonl | jq -r .score_after
```

### Dashboard Generation
```bash
# Quick stats
cat experiment-log.jsonl | jq -s '
{
  total: length,
  kept: [.[] | select(.kept == true)] | length,
  best: [.[] | .improvement] | max,
  current: .[-1].score_after
}
'
```

---

## Resource Estimates

### Nightly Loop (Single Agent)
- **Cost:** ~$0.05-0.10/night (Haiku-class)
- **Experiments:** 10-50 iterations
- **Duration:** 2-4 hours
- **Improvements:** 2-10 kept changes

### Loop Gordo (48h Multi-Agent)
- **Cost:** ~$2-5 total
- **Experiments:** 100-300 iterations
- **Duration:** 48 hours
- **Improvements:** 20-50 kept changes

---

## When to Use What

### Main Session
- User conversation
- Quick tasks (<5 min)
- Oversight/monitoring
- Decision-making

### Subagent
- Heavy computation
- Research/investigation
- Parallel tasks
- Time-consuming work (>5 min)

### Nightly Loop
- Continuous improvement
- Performance optimization
- Code quality
- Documentation refinement

### On-Demand Loop
- Crisis response
- Major releases
- Research sprints
- Proof-of-concept

---

## The Karpathy Pattern

```
program.md (immutable instructions)
    ↓
train.py (mutable code)
    ↓
prepare.py → eval.sh (immutable evaluation)
    ↓
result (single number)
    ↓
better? → keep : discard
    ↓
repeat 500x
```

**Abstraction:**
```
Objective → Code → Evaluation → Score → Decision → Loop
```

---

## Troubleshooting

### Loop Not Improving?
- Check: Is eval.sh giving clear signal?
- Check: Are constraints too restrictive?
- Check: Is metric actually measuring what matters?
- Try: Adjust program.md to be more specific

### Agent Going Off-Track?
- Check: Are instructions ambiguous?
- Check: Is scope too broad?
- Try: Narrow mutable files
- Try: Add explicit constraints

### Too Slow?
- Check: Is eval.sh taking too long?
- Try: Parallelize evaluation
- Try: Reduce evaluation scope
- Try: Multiple agents on different targets

### Too Expensive?
- Check: Using smallest viable model?
- Try: Reduce iteration count
- Try: Better stopping criteria (quit early on plateau)
- Try: Batch experiments

---

## Remember

**Your job:**
- Define what "better" means
- Make it measurable
- Set the constraints
- Review the outcomes

**Agent's job:**
- Explore solution space
- Execute iterations
- Self-evaluate
- Work 24/7

**The power:** While you sleep, agents run 500 rounds. You wake up to the best solutions.

---

## Further Reading

Full framework: `aipm-framework.md`  
Karpathy's autoresearch: https://github.com/karpathy/autoresearch

---

**Version:** 1.0  
**Last Updated:** 2026-03-22

*"A PO defines value for humans. An AIPM defines 'better' for agents."*
