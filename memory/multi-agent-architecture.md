# 🤝 Multi-Agent Collaboration Architecture

**Implemented:** 2026-03-22  
**Status:** Active  
**Vision:** "Emulate a research community, not a single PhD student" — Andrej Karpathy

---

## 🎯 Core Principle

**Lola Main = Orchestrator, never executor.**

The main session stays free for conversation with Manu. All heavy work delegated to specialized subagents that run in parallel.

---

## 🏗️ Agent Roles

### 1. Lola Main (Orchestrator)
**Purpose:** Manu's conversational interface + supervisor  
**Never does:**
- Heavy computation
- Long-running searches
- Multi-step data processing
- Complex analysis

**Always does:**
- Understand request
- Decide which agents to spawn
- Monitor subagent progress (passive, push-based)
- Synthesize results for Manu
- Make final decisions

**Working directory:** `/home/mleon/.openclaw/workspace`

---

### 2. Autoimprove Agents (Nightly) ✅ ACTIVE
**Count:** 3 specialized agents  
**Schedule:** Nightly at 03:00, 03:05, 03:10 Madrid  
**Already implemented:** See `autoimprove/PARALLEL_SETUP.md`

- **Scripts Agent** — Optimizes bash scripts (execution time + error handling)
- **Skills Agent** — Optimizes documentation (token count + clarity)
- **Memory Agent** — Optimizes memory organization (coverage + duplication)

**Communication:** Experiment log (`autoimprove/experiment-log.jsonl`)  
**Metrics:** Composite scores from `eval.sh`  
**Cost:** ~$0.15/night (3x Haiku)

---

### 3. Domain Agents (On-Demand)
**Purpose:** Deep analysis in specialized areas  
**Domains:** `surf`, `health`, `finanzas`, `music`

**When to spawn:**
- Question requires domain expertise
- Need to cross-reference multiple data sources
- Analysis takes >30 seconds
- Manu asks "what do you think about X?"

**Example spawns:**
```bash
# Surf conditions analysis
openclaw sessions spawn \
  --label surf-analysis \
  --instructions "$(cat agents/templates/domain-agent.md)" \
  --model haiku \
  "Analyze surf conditions for this weekend in Logroño. Check: memory/surf/conditions-2026-03-22.md, Garmin fatigue data, calendar availability. Recommend best day/time."

# Multi-domain (surf + health)
# Spawn 2 agents in parallel, synthesize results
```

**Output format:** Markdown report in `memory/<domain>/analysis-YYYY-MM-DD-<topic>.md`  
**Git commit:** Always commit findings before reporting

---

### 4. Research Agents (On-Demand)
**Purpose:** Web research, data gathering, investigation

**When to spawn:**
- Need to search multiple sources
- Compare options (products, services, solutions)
- Investigate unfamiliar topic
- Build knowledge base on new subject

**Example spawns:**
```bash
# Research surf coaching resources
openclaw sessions spawn \
  --label research-surf-coaching \
  --instructions "$(cat agents/templates/research-agent.md)" \
  --model haiku \
  "Research surf coaching methodologies. Find: progression frameworks, common mistakes, corrective exercises. Create knowledge base in memory/surf/coaching/. Cite all sources."
```

**Output format:** 
- Findings: `memory/research/<topic>-YYYY-MM-DD.md`
- Sources: Always include URLs + access date
- Knowledge base: Structured .md files

**Tools:** `web_search`, `web_fetch`, `browser` (when needed)

---

### 5. Builder Agents (On-Demand)
**Purpose:** Create scripts, pipelines, automation

**When to spawn:**
- Building new functionality
- Complex script that needs iteration
- Pipeline with multiple stages
- Integration with external services

**Example spawns:**
```bash
# Build surf data pipeline
openclaw sessions spawn \
  --label build-surf-pipeline \
  --instructions "$(cat agents/templates/builder-agent.md)" \
  --model sonnet \
  "Build daily surf data pipeline: fetch Windguru API → parse → save to memory/surf/conditions-YYYY-MM-DD.md. Include cron setup, error handling, logging. Test before committing."
```

**Output format:**
- Code: `scripts/<name>.sh` or `scripts/<name>.py`
- Documentation: Comments + usage in script header
- Test results: Include in commit message

**Always:**
- Test before committing
- Include error handling
- Log to appropriate location
- Add cron job if recurring

---

### 6. Audit Agents (On-Demand)
**Purpose:** Verification, testing, security checks

**When to spawn:**
- Before deploying new code
- After system changes
- Security review
- Data integrity check
- Pre-publish validation

**Example spawns:**
```bash
# Audit cron jobs
openclaw sessions spawn \
  --label audit-crons \
  --instructions "$(cat agents/templates/audit-agent.md)" \
  --model haiku \
  "Audit all cron jobs. Check: delivery configured, best-effort-deliver used, ran successfully at least once, no errors in last 7 days. Report findings to memory/audits/crons-2026-03-22.md"
```

**Output format:**
- Report: `memory/audits/<subject>-YYYY-MM-DD.md`
- Findings: Structured list (OK / WARNING / CRITICAL)
- Recommendations: Actionable fixes

**Never:**
- Make destructive changes without approval
- Auto-fix critical issues
- Skip verification steps

---

## 📡 Communication Protocol

### Shared Filesystem
All agents share `/home/mleon/.openclaw/workspace`

**Read locations:**
- `SOUL.md`, `AGENTS.md`, `USER.md`, `IDENTITY.md` — Core identity
- `memory/*.md` — Persistent knowledge
- `memory/YYYY-MM-DD.md` — Daily logs
- `autoimprove/experiment-log.jsonl` — Experiment history

**Write locations:**
- Domain agents → `memory/<domain>/`
- Research agents → `memory/research/`
- Audit agents → `memory/audits/`
- Builder agents → `scripts/` or `agents/`

### Result Delivery (Push-Based)
**DO NOT POLL.** Subagent results auto-announce to parent.

```bash
# ✅ CORRECT: Spawn and wait (passive)
openclaw sessions spawn --label task ...
# Results arrive automatically when done

# ❌ WRONG: Polling loop
while true; do
  openclaw sessions list | grep task
  sleep 5
done
```

### Experiment Log (JSONL)
Shared knowledge base: `autoimprove/experiment-log.jsonl`

**Format:**
```json
{
  "ts": "2026-03-22T03:15:00Z",
  "agent": "scripts",
  "target": "backup-memory.sh",
  "change": "parallelize tar+gzip",
  "score_before": 450,
  "score_after": 380,
  "kept": true,
  "iterations": 3
}
```

**Agents can:**
- Read log to see what's been tried
- Avoid duplicate experiments
- Learn from past failures
- Identify high-value targets

### Memory Files
Persistent context shared across sessions:
- `MEMORY.md` — High-level index (main session only)
- `memory/preferences.md` — Behavioral rules
- `memory/verification-protocol.md` — Safety rules
- `memory/<domain>/*.md` — Domain knowledge

---

## 🎛️ Orchestration Rules

### Resource Limits
**VPS capacity:** 16GB RAM, 8 cores  
**Max concurrent agents:** 5  
**Typical load:**
- 3x autoimprove agents (nightly): ~3GB RAM
- 2x on-demand agents: ~2GB RAM
- Main session: ~1GB RAM
- Headroom: ~10GB

**Monitoring:**
```bash
# Check load before spawning
top -bn1 | grep "Cpu(s)"
free -h
```

### Parallelization Strategy

**Always prefer parallel over sequential** when tasks are independent.

**Examples:**

✅ **Parallel (GOOD):**
```bash
# Multi-domain question: spawn both, synthesize results
openclaw sessions spawn --label surf-analysis ...
openclaw sessions spawn --label health-analysis ...
# Wait for both → synthesize
```

✅ **Parallel build + research:**
```bash
openclaw sessions spawn --label build-pipeline ...
openclaw sessions spawn --label research-apis ...
# Build can reference research findings later
```

❌ **Sequential (BAD) unless dependencies:**
```bash
# DON'T: spawn 1, wait, spawn 2, wait...
# Only if task 2 NEEDS output from task 1
```

### Task Assignment

**Quick question (<30s):** Main handles directly  
**Deep analysis (1-5min):** Spawn 1 domain agent  
**Multi-domain:** Spawn N agents in parallel, synthesize  
**Big project:** Spawn builder + research in parallel  
**Verification:** Spawn audit agent

### Result Verification

**Main agent ALWAYS verifies before reporting to Manu:**
1. Subagent completed successfully?
2. Output format correct?
3. Git commit made (if required)?
4. Claims backed by evidence?
5. No hallucinations?

**If subagent fails:**
1. Retry ONCE with clearer instructions
2. If fails again → report to Manu with details
3. Never hide failures

### Failure Handling

**Subagent crashes:**
- Check logs: `openclaw sessions list`
- Analyze error message
- Retry with adjusted instructions OR
- Report to Manu if unrecoverable

**Subagent hallucinates:**
- Verify claims with independent check
- Re-run with stricter verification rules
- Update template to prevent recurrence

**Subagent hangs:**
- Sessions have timeout (default: 30min)
- If timeout insufficient, kill and restart
- Investigate cause (infinite loop, waiting for input?)

---

## 🎨 Agent Spawning Patterns

### Pattern 1: Single Domain Analysis
```bash
openclaw sessions spawn \
  --label <domain>-analysis \
  --instructions "$(cat agents/templates/domain-agent.md)" \
  --model haiku \
  "Analyze <question> using domain=<domain>. Check: <data sources>. Output: memory/<domain>/analysis-<date>-<topic>.md. Git commit before reporting."
```

### Pattern 2: Multi-Domain Synthesis
```bash
# Spawn in parallel
openclaw sessions spawn --label surf-check ...
openclaw sessions spawn --label health-check ...

# Main agent waits (push-based)
# When both complete → synthesize:
# "Surf conditions are good (agent 1), but your HRV is low (agent 2) → recommend rest day"
```

### Pattern 3: Research + Build
```bash
# Parallel spawn
openclaw sessions spawn --label research-<topic> ...
openclaw sessions spawn --label build-<feature> ...

# Builder can reference research findings
# Main synthesizes final output
```

### Pattern 4: Build + Audit
```bash
# Sequential (audit NEEDS build output)
openclaw sessions spawn --label build-feature ...
# Wait for completion
openclaw sessions spawn --label audit-feature ...
# Wait for audit → report to Manu
```

### Pattern 5: Batch Processing
```bash
# Process multiple items in parallel
for item in item1 item2 item3; do
  openclaw sessions spawn --label process-$item ...
done
# Wait for all → aggregate results
```

---

## 🚦 Agent Templates

See `agents/templates/`:
- `domain-agent.md` — Domain-specific analysis
- `research-agent.md` — Web research and data gathering
- `builder-agent.md` — Code/script creation
- `audit-agent.md` — Verification and testing

**Each template includes:**
- Role definition
- Working directory rules
- Output format
- Git commit requirements
- What NOT to touch

---

## 📊 Success Metrics

| Metric | Target | Current |
|--------|--------|---------|
| Main session always free | 100% | ✅ 100% |
| Parallel spawns per complex task | 2-3 | ✅ Yes |
| Subagent success rate | >90% | TBD |
| Average response time (with agents) | <5min | TBD |
| Max concurrent agents used | 5 | 3 (nightly) |
| Cost per day (on-demand agents) | <$0.50 | ~$0.15 (nightly only) |

---

## 🎯 Future Enhancements (Phase 4.2)

### Agent-to-Agent Communication
Currently: agents → filesystem → main → synthesis  
Future: agents suggest targets to each other

**Example:**
- Scripts agent finds slow pattern in multiple scripts
- Suggests to Skills agent: "document this anti-pattern"
- Skills agent updates AGENTS.md with guidance

### Agent Specialization Evolution
Agents learn from experiment log which changes work best, develop preferences.

### Adaptive Resource Allocation
Monitor success rates, assign more iterations to high-performing agents.

### Agent Command Center
Real-time dashboard showing:
- Active agents
- Task queue
- Success rates
- Resource usage
- Recent experiments

---

## 🔗 Related Documents

- `autoimprove/PARALLEL_SETUP.md` — Nightly autoimprove agents (Phase 2.3)
- `memory/2026-03-22-master-plan.md` — Overall vision (Karpathy-inspired)
- `memory/preferences.md` — Behavioral rules (parallelization, session-free main)
- `agents/templates/*.md` — Agent instruction templates

---

*"The goal is not to emulate a single PhD student, it's to emulate a research community of them."* — Andrej Karpathy

*Part of Master Plan Phase 4.2 (Multi-Agent Collaboration)*
