# AIPM Framework: AI Product Management

**From Product Owner to AI Product Manager**

*A practical framework for managing AI agents as your development team*

---

## Table of Contents

1. [Introduction](#introduction)
2. [From PO to AIPM](#from-po-to-aipm)
3. [Core AIPM Principles](#core-aipm-principles)
4. [The AIPM Toolkit](#the-aipm-toolkit)
5. [Workflows](#workflows)
6. [Case Studies](#case-studies)
7. [Anti-Patterns](#anti-patterns)
8. [The AIPM Checklist](#the-aipm-checklist)
9. [Getting Started](#getting-started)

---

## Introduction

The shift from traditional software development to AI-augmented development isn't just a tooling change—it's a fundamental transformation in how we think about building products. This framework documents the evolution from **Product Owner (PO)** to **AI Product Manager (AIPM)**, based on real-world experience managing AI agents as a development team.

**Core insight:** A PO defines value for a human team. An AIPM defines "better" for agents and lets them run the loops.

This isn't theoretical. This framework emerged from hundreds of hours of practical work with AI agents, inspired by Andrej Karpathy's autoresearch pattern and refined through real projects.

---

## From PO to AIPM

### Traditional Product Owner

A traditional PO works with human developers:

- **Writes user stories** — Detailed specifications in JIRA/Linear
- **Prioritizes backlog** — Decides what gets built when
- **Manages sprints** — 2-week cycles, planning, retros
- **Reviews PRs** — Approves code before merge
- **Defines acceptance criteria** — "Done" means human-verified

**The rhythm:** Sprint planning → Daily standups → Sprint review → Retrospective → Repeat

### AI Product Manager

An AIPM works with AI agents:

- **Writes program.md files** — Mission briefs, not specifications
- **Defines metrics** — What "better" means numerically
- **Orchestrates loops** — Continuous improvement cycles, not sprints
- **Reviews experiment logs** — Data-driven progress tracking
- **Defines stopping criteria** — Automated success verification

**The rhythm:** Define objective → Launch loop → Monitor metrics → Adjust constraints → Scale successes

### Key Shifts

| From (PO) | To (AIPM) | Why |
|-----------|-----------|-----|
| User stories | program.md files | Agents need objectives, not tasks |
| Sprint planning | Loop definition | Agents work 24/7, not in 2-week cycles |
| PR reviews | Experiment logs | Measure outcomes, not code style |
| Acceptance criteria | Automated evaluation | Human verification doesn't scale |
| Team meetings | Metric dashboards | Async-first, data-driven |
| Sequential tasks | Parallel agents | Maximize throughput, not utilization |
| "Ship it!" | "Run 500 rounds" | Let the agent find the optimum |

**The fundamental difference:** With human teams, you manage *activities*. With AI agents, you manage *outcomes*.

---

## Core AIPM Principles

### 1. Define "Better" with a Number

**Principle:** If you can't measure it, you can't improve it.

Every project needs a clear, automated metric:
- **Performance:** Execution time, response latency, throughput
- **Quality:** Error rate, test coverage, code complexity
- **Efficiency:** Token usage, API calls, resource consumption
- **Accuracy:** Validation score, user satisfaction, correctness

**Bad metric:** "Make the code better"  
**Good metric:** "Reduce execution time below 2 seconds while maintaining 100% test pass rate"

**Example:**
```bash
# eval.sh for a script optimization
time ./script.sh > /dev/null 2>&1
errors=$(./script.sh 2>&1 | grep -c ERROR)
score=$(($(date +%s%N | cut -b1-13) + errors * 1000))
echo $score
```

### 2. Make Evaluation Automatic

**Principle:** The metric must be computable without human intervention.

Create an `eval.sh` (or equivalent) that:
- Takes current state as input
- Returns a single number
- Runs in bounded time (<5 minutes ideal)
- Is deterministic (same input → same output)
- Can run thousands of times

**The golden rule:** If your eval requires human judgment, it's not ready for autonomous loops.

### 3. One File, One Metric, One Loop

**The Karpathy Pattern:**
- **One immutable file** — `eval.sh` (evaluation logic)
- **One mutable file** — The code/config the agent modifies
- **One metric** — Single number to optimize
- **One loop** — Iterate until stopping criteria

**Why this works:**
- Agents stay focused (no scope creep)
- Progress is measurable (clear signal)
- Failures are bounded (worst case = no improvement)
- Success is transferable (pattern repeats)

**Avoid:** Multiple agents modifying the same file, changing the metric mid-loop, or mixing objectives.

### 4. Agent-First Architecture

**Principle:** The agent IS the interface, not just a tool.

**Traditional:** Build an app → Add AI features → Users interact with UI  
**Agent-first:** Build data pipelines → Agent consumes data → Users interact with agent

**Example:**
- ❌ Build a surf forecast app with AI chatbot
- ✅ Pipeline surf data to agent → User asks agent "Should I surf today?"

**Benefits:**
- No UI to maintain
- Personalized by default (agent knows user context)
- Evolves through conversation
- Extensible without code changes

**When to choose agent-first:**
- High variability in user needs
- Context-heavy decisions
- Continuous personalization
- Exploratory use cases

**When to build an app:**
- Standardized workflows
- Visual/spatial interfaces required
- Real-time collaboration
- Non-conversational interactions

### 5. Parallel Over Sequential

**Principle:** Maximize throughput by running independent tasks concurrently.

**Traditional development:**
```
Task A (2 days) → Task B (2 days) → Task C (2 days) = 6 days
```

**AIPM approach:**
```
Task A (Agent 1, 2 days)
Task B (Agent 2, 2 days)  } = 2 days
Task C (Agent 3, 2 days)
```

**Key constraint:** Only serialize when there's a true dependency.

**Dependencies that force sequencing:**
- Human approval/input
- Data availability (waiting for external source)
- Stability verification (need to confirm before proceeding)

**Everything else:** Parallelize.

**Practical limits:**
- Monitor system load (CPU, memory, API quotas)
- Start with 2-3 agents, scale based on results
- Cost awareness (each agent = API calls)

### 6. Speed Over Ceremony

**Principle:** Move at the speed of dependencies, not the speed of process.

**Eliminate:**
- Sprint planning (just start)
- Daily standups (metrics are the standup)
- Estimation poker (agents don't estimate, they execute)
- Velocity tracking (irrelevant when agents work 24/7)

**Keep:**
- Clear objectives (what are we optimizing?)
- Progress tracking (experiment logs)
- Retrospectives (what did we learn from the data?)
- Human oversight (critical decisions still human-owned)

**Phase by dependencies:**
```
Phase 1: Foundation (no dependencies → start immediately)
Phase 2: Integration (depends on Phase 1 completion → start when ready)
Phase 3: Optimization (depends on data from Phase 2 → start when data arrives)
```

### 7. Verify Before Claiming

**Principle:** Evidence > Assertions

**The rule:** Never claim success without showing the evidence.

**Before saying "Fixed":**
```bash
# Run the verification command
$ ./test.sh
All tests passed (15/15)

# Show the evidence
$ git diff --stat
script.sh | 12 +++++-------
1 file changed, 5 insertions(+), 7 deletions(-)
```

**This prevents:**
- Hallucinated fixes (agent thinks it worked but didn't)
- Incomplete solutions (passes some tests, fails others)
- Configuration drift (works locally, fails in production)

**Verification checklist:**
- [ ] Command ran successfully (exit code 0)
- [ ] Output shows expected results
- [ ] Edge cases tested
- [ ] No regressions introduced

### 8. Sparse but Critical Human Contribution

**Principle:** The human defines direction, the agent executes iteration.

**What humans do best:**
- Define what "better" means (the metric)
- Set constraints (what must NOT change)
- Make value judgments (is this useful?)
- Course-correct when agents drift
- Synthesize insights from experiment logs

**What agents do best:**
- Explore the solution space (500 experiments)
- Execute repetitive refinement
- Work 24/7 without fatigue
- Maintain consistency
- Scale to multiple projects simultaneously

**The Karpathy insight:**
> "I didn't touch anything. brb sauna" — Andrej Karpathy

**The goal:** Human intervenes sparsely but critically, not continuously but superficially.

---

## The AIPM Toolkit

### program.md — Mission Brief

**Purpose:** Single-source-of-truth for what the agent should achieve.

**Structure:**
```markdown
# Objective
Clear statement of the goal (1-2 sentences)

# Metric
How success is measured (specific number)

# Constraints
What must NOT change (immutable boundaries)

# Mutable Files
What the agent can modify (explicit list)

# Stopping Criteria
When to stop iterating (max rounds, target metric, time limit)

# Context
Background knowledge needed to succeed

# Examples
Concrete instances of good/bad solutions
```

**Example:**
```markdown
# Objective
Optimize the backup script to complete in under 60 seconds

# Metric
Execution time in milliseconds (lower is better)
Target: <60000ms

# Constraints
- Must preserve all existing functionality
- No data loss tolerated
- Exit code 0 on success
- Compatible with cron execution

# Mutable Files
- scripts/backup.sh

# Stopping Criteria
- Target metric achieved, OR
- 100 experiments completed, OR
- No improvement in 20 consecutive rounds

# Context
Currently takes ~180 seconds due to sequential tar+gzip.
Consider parallelization, compression levels, or incremental backups.

# Examples
Good: Parallel tar + gzip, reduced compression to -6
Bad: Skipping files, removing verification, background jobs without completion checks
```

### eval.sh — Automated Scoring

**Purpose:** Programmatic evaluation of current state.

**Requirements:**
- Executable script (chmod +x)
- Returns numeric score via stdout
- Lower score = better (convention, can be inverted)
- Runs in <5 minutes
- Idempotent (same state → same score)

**Template:**
```bash
#!/bin/bash
set -euo pipefail

# Configuration
TARGET_FILE="./script.sh"
PENALTY_PER_ERROR=1000

# Measure performance
start=$(date +%s%N)
$TARGET_FILE > /dev/null 2>&1
end=$(date +%s%N)
runtime_ms=$(( (end - start) / 1000000 ))

# Measure correctness
errors=$($TARGET_FILE 2>&1 | grep -c ERROR || true)

# Composite score
score=$((runtime_ms + errors * PENALTY_PER_ERROR))

echo $score
```

**Advanced patterns:**
- **Multi-dimensional:** Combine time + quality + resource usage
- **Weighted:** Different penalties for different failure types
- **Thresholds:** Hard failures (infinite score) vs soft degradation

### experiment-log.jsonl — Iteration History

**Purpose:** Record every attempt for analysis and learning.

**Format:** JSON Lines (one JSON object per line)

**Schema:**
```json
{
  "timestamp": "2026-03-22T14:30:00Z",
  "target": "backup.sh",
  "change_description": "Parallelized tar and gzip operations",
  "score_before": 180450,
  "score_after": 58320,
  "improvement": 122130,
  "improvement_pct": 67.7,
  "kept": true,
  "git_commit": "a3f8d92",
  "agent_id": "optimize-1"
}
```

**Why JSONL:**
- Append-only (no file corruption risk)
- Streamable (analyze while running)
- Tooling-friendly (jq, pandas, etc.)
- Human-readable (debuggable)

**Usage:**
```bash
# Total experiments
wc -l experiment-log.jsonl

# Success rate
jq -r '.kept' experiment-log.jsonl | grep true | wc -l

# Best improvement
jq -r '.improvement' experiment-log.jsonl | sort -n | tail -1

# Trend over time
jq -r '[.timestamp, .score_after] | @tsv' experiment-log.jsonl
```

**Karpathy insight:**
> "The log matters more than the result" — Andrej Karpathy

Why? Because the log shows:
- What strategies were tried
- What worked and what didn't
- Rate of improvement over time
- When diminishing returns set in

### dashboard — Progress Visualization

**Purpose:** Make experiment logs human-scannable.

**Essential metrics:**
- Total experiments run
- Success rate (% improvements kept)
- Current score vs starting score
- Best improvement found
- Recent trend (improving/plateauing/regressing)
- Current streak (consecutive improvements/failures)

**Output format:** Text (for terminal/chat) or Canvas (for visual inspection)

**Example text dashboard:**
```
╔══════════════════════════════════════════╗
║  Autoimprove Dashboard                   ║
║  Target: backup.sh                       ║
╠══════════════════════════════════════════╣
║  Experiments:        45                  ║
║  Kept:              12 (26.7%)           ║
║  Rejected:          33 (73.3%)           ║
╠══════════════════════════════════════════╣
║  Starting score:     180,450 ms          ║
║  Current score:       58,320 ms          ║
║  Improvement:        122,130 ms (67.7%)  ║
║  Best single:         35,200 ms          ║
╠══════════════════════════════════════════╣
║  Streak:             3 improvements      ║
║  Last 10:            ✓✗✗✓✓✓✗✗✗✗         ║
║  Trend:              ↗ Improving         ║
╚══════════════════════════════════════════╝
```

**Implementation:** Shell script that reads experiment-log.jsonl and formats output.

### agent-instructions.md — Domain-Specific Behavior

**Purpose:** Configure agent behavior for specific project types.

**Use cases:**
- Agent-first projects (agent is the interface)
- Domain-specific constraints (medical, financial, safety-critical)
- Tone/style requirements (user-facing vs internal)
- Integration requirements (external APIs, data formats)

**Example:**
```markdown
# Agent Instructions: Surf Coach

## Role
You are a surfing coach with expertise in ocean conditions, 
technique progression, and fitness.

## Data Sources
- Surf conditions: memory/surf/conditions-YYYY-MM-DD.md (daily)
- User activity: Garmin API (sleep, HRV, workout history)
- Past sessions: memory/surf/sessions/ (user-reported feedback)
- Calendar: Google Calendar (availability)

## Response Patterns
When asked about conditions:
1. Check forecast for target date
2. Cross-reference with user's skill level
3. Consider recovery state (HRV, sleep quality)
4. Recommend go/no-go with reasoning

When asked about technique:
1. Review recent session notes
2. Identify progression level (popup → bottom turn → cutback → aerial)
3. Suggest specific drills based on current level
4. Provide video references if available

## Constraints
- Never recommend surfing in dangerous conditions
- Always account for user's fatigue/recovery state
- Personalize based on actual session history, not assumptions

## Tone
Encouraging but realistic. Technical when asked, 
conversational by default.
```

### memory/ — Persistent Knowledge Base

**Purpose:** Agent's long-term knowledge storage.

**Structure:**
```
memory/
├── YYYY-MM-DD.md          # Daily logs
├── preferences.md          # User preferences
├── project-name/          # Project-specific knowledge
│   ├── context.md
│   ├── decisions.md
│   └── data/
├── domain/                # Domain knowledge
│   ├── surf/
│   ├── finance/
│   └── health/
└── experiment-logs/       # Iteration histories
    └── project-name.jsonl
```

**Key principles:**
- **Append-only daily logs** — Never delete history
- **Structured knowledge** — Organized by domain/project
- **Searchable** — Use embeddings or full-text search
- **Agent-maintained** — Agent updates after each session

**Integration with loops:**
- Agents read memory/ for context
- Agents write learnings to memory/
- Memory informs future iterations

---

## Workflows

### Nightly Optimization Loop

**Pattern:** Continuous improvement while you sleep.

**Setup:**
```bash
# Cron: Daily at 02:00
0 2 * * * /path/to/autoimprove.sh
```

**Process:**
1. Agent reads program.md for target
2. Agent runs eval.sh to get baseline score
3. Agent proposes modification to mutable file
4. Agent runs eval.sh to measure new score
5. If improved: commit + log success
6. If worse: revert + log failure
7. Repeat until stopping criteria
8. Generate summary report

**Stopping criteria:**
- Target metric achieved
- Max iterations (e.g., 50 experiments)
- Max time (e.g., 4 hours)
- No improvement in N consecutive rounds (e.g., 20)

**Result:** Wake up to 10-50 improvements tested, best ones applied.

**Cost:** ~$0.05-0.15/night with efficient models (Haiku-class)

**Scaling:** Run 3+ parallel loops for different targets (scripts, docs, configs)

### On-Demand Research

**Pattern:** Spawn agents for deep investigation.

**Use cases:**
- "Research best practices for X"
- "Find the root cause of this error"
- "Compare approaches A vs B"
- "Summarize literature on topic Y"

**Process:**
```bash
# Main agent delegates to subagent
spawn research-agent with task="Find root cause of cron failure"

# Research agent:
1. Reads relevant logs
2. Searches documentation
3. Tests hypotheses
4. Compiles findings
5. Returns structured report

# Main agent:
Receives report, takes action based on findings
```

**Why separate agent:**
- Keeps main session free for user interaction
- Isolated context (doesn't pollute main thread)
- Can use more expensive models if needed
- Parallelizable (multiple research tasks)

**Duration:** Minutes to hours, depending on scope

### Agent-First Project Setup

**Pattern:** Build projects where the agent is the primary interface.

**Steps:**

**1. Identify the domain**
- What decisions will users ask the agent to make?
- What data is needed to make those decisions?

**2. Build data pipelines**
- Automate data collection (APIs, scraping, webhooks)
- Store in agent-accessible format (memory/, database)
- Schedule regular updates (cron, event-driven)

**3. Create knowledge base**
- Domain-specific facts (rules, best practices)
- User preferences (stored in memory/preferences.md)
- Historical context (past decisions, outcomes)

**4. Define agent instructions**
- Response patterns for common queries
- Decision-making frameworks
- Constraints and safety rules

**5. Test with real queries**
- User asks questions
- Agent synthesizes data + knowledge
- Iterative refinement of responses

**6. Add improvement loop**
- Track which responses were helpful
- Agent self-improves based on feedback
- Update knowledge base with learnings

**Example: Surf Coach**
- **Data:** Forecast API, Garmin API, calendar, session notes
- **Knowledge:** Technique progression, safety rules, fitness guidance
- **Interface:** User asks "Should I surf tomorrow?" → Agent synthesizes answer
- **Loop:** Agent learns user's preferences, improves recommendations over time

### Multi-Agent Orchestration

**Pattern:** Parallel agents working on related tasks.

**Use cases:**
- Large codebases (1 agent per module)
- Multi-domain projects (1 agent per domain)
- Resource-intensive tasks (distribute load)

**Architecture:**

**Coordinator agent (main):**
- Spawns specialist agents
- Aggregates results
- Resolves conflicts
- Reports to user

**Specialist agents:**
- Domain/task-focused
- Independent operation
- Report back to coordinator

**Example: Codebase optimization**
```
Coordinator
├── Agent A: Optimize backend (performance metrics)
├── Agent B: Optimize frontend (bundle size)
└── Agent C: Optimize database (query time)

Each agent:
- Reads its target files
- Runs its specific eval.sh
- Iterates independently
- Reports improvements

Coordinator:
- Launches all 3 agents
- Monitors progress
- Aggregates final report
```

**Complexity:** Ensure agents don't conflict (separate files or merge strategy)

### The "Loop Gordo"

**Pattern:** Intensive 48-hour optimization run.

**When to use:**
- Major release preparation
- Performance crisis
- Research sprints
- Proof-of-concept validation

**Setup:**
- High iteration limit (200-500 experiments)
- Multiple parallel agents
- Extended time budget (48 hours)
- Richer metrics (multi-dimensional)

**Process:**
```
Friday 18:00: Launch loop gordo
├── Agent 1: Performance optimization
├── Agent 2: Code quality
├── Agent 3: Documentation
└── Agent 4: Test coverage

Saturday-Sunday: Agents iterate

Monday 09:00: Review results
```

**Expected outcome:**
- 100-300+ total experiments
- 20-50+ improvements found
- Significant metric gains
- Learnings for future iterations

**Cost:** ~$2-5 for 48h with efficient models

**Risk mitigation:**
- All changes in feature branches
- Human review before merge
- Rollback plan ready
- Monitor system resources

---

## Case Studies

### Case 1: Autoimprove — From Manual to Autonomous

**Challenge:** Manually optimizing scripts was slow and inconsistent.

**Before:**
- Human identifies script to optimize
- Human modifies code
- Human tests manually
- Human decides if improvement is worth keeping
- ~1-2 improvements per week

**After:**
- program.md defines optimization targets
- eval.sh measures execution time + correctness
- Agent iterates nightly (3 parallel agents)
- Experiment log tracks all attempts
- ~15+ improvements per week

**Results:**
- **45+ experiments per night** (vs 0)
- **3 parallel agents** (scripts, skills, memory)
- **Automated quality gates** (no manual testing)
- **Continuous improvement** (every night, not when human has time)

**Key learning:** The bottleneck was human attention, not optimization opportunity.

### Case 2: Lola Toolkit — Measurement-Driven Refinement

**Challenge:** Improve a CLI toolkit without clear success criteria.

**Approach:**
- Defined composite metric: execution time + code quality + error rate
- Created eval.sh: runs toolkit commands, measures performance, runs shellcheck
- Agent iterated 25 times over one week
- Each iteration logged to experiment-log.jsonl

**Results:**
- **5.2% quality improvement** (composite score)
- **73% shellcheck reduction** (code quality errors)
- **25 iterations** in one week (vs 3-4 manual iterations previously)
- **Data-driven decisions** (not gut feel)

**Key learning:** Even small, consistent improvements compound significantly.

### Case 3: Surfing Coach — Agent IS the Interface

**Challenge:** Build a surfing coach without building an app.

**Traditional approach:**
- Build UI for forecast display
- Add calendar integration
- Create technique library
- Implement recommendation engine
- Months of development

**Agent-first approach:**
- **Week 1:** Set up data pipelines (forecast API, Garmin, calendar)
- **Week 2:** Populate knowledge base (technique guides, safety rules)
- **Week 3:** Define agent instructions (response patterns)
- **Week 4:** Test with real queries, refine responses

**Result:**
- **Zero UI code** (agent is the interface)
- **4 weeks vs 4+ months** (traditional app development)
- **Personalized by default** (agent has full user context)
- **Continuously improving** (agent learns from interactions)

**User interaction:**
```
User: "Should I surf tomorrow morning?"

Agent: 
"Conditions look good for your level—2-3ft clean waves at 7AM. 
Your HRV is high (good recovery), and you have no calendar 
conflicts until 11AM. I'd recommend going.

Focus on bottom turns (your last session note mentioned working 
on this). Swell direction is west, so the south break will be 
cleaner."
```

**Key learning:** Many "app" problems are actually "context + synthesis" problems—perfect for agents.

### Case 4: Cron Remediation — 11% to 100% in One Run

**Challenge:** Cron jobs were failing silently. Manual audit found 11% compliance.

**Approach:**
- Spawned subagent with task: "Fix all cron jobs"
- Agent audited all crons
- Agent identified failures (missing channels, bad configs)
- Agent applied fixes
- Agent verified each fix

**Results:**
- **11% → 100% compliance** in one run
- **0 human intervention** during execution
- **Complete verification** (agent tested each fix)
- **Documentation auto-generated** (what changed and why)

**Key insight:** Agent didn't just fix—it verified. Evidence before claiming success.

**What made this work:**
- Clear metric (cron success rate)
- Automated verification (test each cron)
- Isolated task (didn't block main session)
- Complete context (agent had access to all configs)

---

## Anti-Patterns

### 1. Treating Agents Like Junior Devs

**Symptom:** Micromanaging every step, reviewing every line of code.

**Why it fails:**
- Negates the speed advantage of agents
- Reintroduces human bottleneck
- Prevents agents from exploring solution space
- Expensive (your time + API calls)

**Better approach:**
- Define the objective clearly
- Set automated quality gates
- Let agent explore
- Review outcomes, not process

**When to intervene:**
- Agent is stuck in a loop
- Repeated failures suggest wrong objective
- Approaching resource limits (cost, time)

### 2. No Metric = No Improvement

**Symptom:** "Make it better" without defining "better."

**Why it fails:**
- Agent has no signal to optimize against
- Human judgment required for every iteration
- No way to measure progress
- Can't tell when to stop

**Better approach:**
- Define numeric success criteria upfront
- If metric can't be automated, task isn't ready for loops
- Start with simple metric, refine over time

**Example:**
- ❌ "Improve the documentation"
- ✅ "Reduce onboarding time from 60min to 30min (measured via test users)"

### 3. Sprint-Based Thinking

**Symptom:** "We'll do this in Sprint 5" when there's no actual dependency.

**Why it fails:**
- Artificial delays (agents don't need weekend breaks)
- Underutilizes agent capacity
- Cargo-culting human team processes

**Better approach:**
- Work starts when dependencies are met
- No sprints—just dependency-ordered phases
- Agents work continuously, not in 2-week bursts

**Ask:** "What's actually blocking us?" Not "What sprint are we in?"

### 4. App-First When Agent-First Is Better

**Symptom:** Building a UI for a problem that's fundamentally conversational.

**Why it fails:**
- Months of UI development for something that could be a chat
- Rigid interface (hard to change)
- Generic (can't personalize easily)
- High maintenance burden

**Better approach:**
- Ask: "Is this primarily about context synthesis and decision-making?"
- If yes: Agent-first
- If no (e.g., visual design, collaboration, real-time interaction): App

**Example:**
- ✅ App: Figma (spatial, visual, collaborative)
- ✅ Agent: Financial advisor (context-heavy, personalized, decision support)

### 5. Not Verifying Agent Output

**Symptom:** Agent says "Done!" and you merge without checking.

**Why it fails:**
- Agents hallucinate (especially under pressure to succeed)
- Partial solutions (passes some tests, fails others)
- Unintended side effects (broke something else)

**Better approach:**
- **Always verify** before claiming success
- **Run the tests** (don't just trust agent's report)
- **Show the evidence** (command output, test results)
- **Check for regressions** (did we break anything else?)

**Protocol:**
1. Agent proposes solution
2. Agent runs verification
3. Agent shows evidence
4. Human confirms
5. Merge

### 6. Blocking Main Session with Heavy Work

**Symptom:** Main agent is busy for hours, can't respond to user.

**Why it fails:**
- User can't give feedback or course-correct
- Defeats the purpose of interactive agents
- If agent goes off-track, hours wasted

**Better approach:**
- **Heavy tasks → Subagents**
- **Main session → Communication channel**
- **Parallel work → Multiple subagents**

**Rule:** If it takes >5 minutes, spawn a subagent.

---

## The AIPM Checklist

Before starting any project, answer these questions:

### 1. What is "better"?

**Define the metric:**
- [ ] Can be measured automatically
- [ ] Returns a single number
- [ ] Lower (or higher) is clearly better
- [ ] Meaningful to the business/user

**Examples:**
- ✅ "Response time under 200ms"
- ✅ "Test coverage above 80%"
- ✅ "User satisfaction score >4.5/5"
- ❌ "Feels faster"
- ❌ "Better code quality"

### 2. Can it be measured automatically?

**Automation requirements:**
- [ ] No human judgment required
- [ ] Runs in bounded time (<5 min ideal)
- [ ] Repeatable (same input → same output)
- [ ] Can run thousands of times

**If NO:**
- Consider: Is this task ready for autonomous loops?
- Alternative: Human-in-the-loop evaluation
- Or: Reframe the metric to be automatable

### 3. What can the agent change?

**Define mutable scope:**
- [ ] Specific files/directories
- [ ] Configuration values
- [ ] Code within certain modules
- [ ] Documentation sections

**What stays fixed:**
- [ ] External dependencies
- [ ] Data formats (backward compatibility)
- [ ] Security constraints
- [ ] Resource limits

**Example:**
```
Mutable:
- src/optimization/*.py
- config/performance.json

Immutable:
- src/api/*.py (public interface)
- tests/ (can add, not remove)
- requirements.txt (no version changes)
```

### 4. What must stay fixed?

**Define constraints:**
- [ ] Functional requirements (must preserve)
- [ ] Performance requirements (must not regress)
- [ ] Security requirements (must maintain)
- [ ] Compatibility requirements (must support)

**Example:**
```
Constraints:
- All existing tests must pass
- API response time <500ms
- No new dependencies
- Backward compatible with v1.x
```

### 5. How do I verify results?

**Verification strategy:**
- [ ] Automated tests exist or can be created
- [ ] Manual verification steps documented
- [ ] Regression detection (before/after comparison)
- [ ] Evidence collection (logs, metrics, screenshots)

**Verification checklist:**
```
Before claiming success:
- [ ] Run automated tests
- [ ] Check performance benchmarks
- [ ] Verify no regressions
- [ ] Review experiment log
- [ ] Human spot-check (if needed)
```

### 6. Who is the interface — app or agent?

**Decision framework:**

**Choose AGENT if:**
- [ ] Highly personalized (context-dependent)
- [ ] Primarily conversational
- [ ] Exploratory use case
- [ ] Frequent requirement changes
- [ ] Small user base (<1000)

**Choose APP if:**
- [ ] Standardized workflow
- [ ] Visual/spatial interface needed
- [ ] Real-time collaboration
- [ ] High-scale (>10k users)
- [ ] Offline support required

**Choose HYBRID if:**
- [ ] Both structured and exploratory flows
- [ ] App for core workflow, agent for exceptions
- [ ] Agent for power users, app for casual users

---

## Getting Started

### Step 1: Pick a Small Target

**Good first projects:**
- Optimize a slow script (clear metric: execution time)
- Improve test coverage (metric: % coverage)
- Reduce error logs (metric: error count)
- Enhance documentation (metric: onboarding time)

**Avoid for first project:**
- Multi-team coordination
- User-facing features
- Critical infrastructure
- Undefined success criteria

### Step 2: Define Your Metric

**Write it down:**
```
Objective: [One sentence goal]
Metric: [How success is measured]
Target: [Specific number to achieve]
```

**Example:**
```
Objective: Speed up backup script
Metric: Total execution time in seconds
Target: Under 60 seconds (currently ~180)
```

### Step 3: Create eval.sh

**Start simple:**
```bash
#!/bin/bash
# Measure execution time of backup script
start=$(date +%s)
./backup.sh > /dev/null 2>&1
end=$(date +%s)
runtime=$((end - start))
echo $runtime
```

**Test it:**
```bash
$ ./eval.sh
180
$ ./eval.sh
182
$ ./eval.sh
179
```

**Improve it:**
- Add error detection
- Check output validity
- Combine multiple metrics

### Step 4: Write program.md

**Template:**
```markdown
# Objective
[Clear goal statement]

# Metric
[What eval.sh measures]

# Constraints
- [What must not change]
- [What must be preserved]

# Mutable Files
- [Specific files agent can modify]

# Stopping Criteria
- [When to stop iterating]
```

**Be specific:** Vague instructions → unpredictable results.

### Step 5: Run Your First Loop

**Manual first:**
1. Run eval.sh → note baseline
2. Make a change
3. Run eval.sh → compare
4. Keep if better, revert if worse
5. Log the attempt
6. Repeat 5-10 times

**Automate next:**
- Wrap the loop in a script
- Agent makes the changes
- Experiment log captures attempts
- Review results after 10-20 iterations

### Step 6: Analyze and Iterate

**Look at the experiment log:**
- What worked? (high success rate)
- What didn't? (repeated failures)
- Patterns in successful changes?
- Diminishing returns? (plateau)

**Refine:**
- Adjust program.md (clearer instructions)
- Improve eval.sh (better signal)
- Expand/narrow mutable scope
- Update constraints based on learnings

### Step 7: Scale

**Once you have one working loop:**
- Add more targets (parallel loops)
- Longer runs (nightly automation)
- Richer metrics (multi-dimensional)
- Bigger scope (full projects)

**Remember:** Start small, prove the pattern, then scale.

---

## Conclusion

The shift from PO to AIPM isn't just about new tools—it's a fundamental change in how we think about building products.

**Traditional development:**
- Human writes code
- Human tests code
- Human deploys code
- Repeat

**AIPM development:**
- Human defines "better"
- Agent explores solutions
- Agent self-evaluates
- Agent iterates continuously
- Human reviews outcomes

**The key insight:** Your job isn't to write the code—it's to define the objective clearly enough that an agent can optimize toward it.

**This unlocks:**
- **Speed:** 24/7 iteration, not 9-5
- **Scale:** Parallel agents, not sequential humans
- **Quality:** Hundreds of experiments, not dozens
- **Learning:** Every iteration captured and analyzable

**The AIPM's job:**
- Define what "better" means
- Make it measurable
- Set the constraints
- Review the results
- Adjust the objective

**Let the agents do the 500 rounds.**

---

## Further Reading

- **Karpathy's Autoresearch:** https://github.com/karpathy/autoresearch
- **Karpathy on No Priors:** Search "Karpathy No Priors interview" for the full context
- **Lola Toolkit:** (Your own implementation as a case study)

---

## License

This framework is shared under MIT License. Use, adapt, and share freely.

---

## Acknowledgments

This framework emerged from real-world practice managing AI agents as a development team. Special thanks to Andrej Karpathy for articulating the autoresearch pattern that crystallized many of these ideas.

**Version:** 1.0  
**Last Updated:** 2026-03-22  
**Maintainer:** Lola (AI Product Manager)

---

*"A PO defines value for humans. An AIPM defines 'better' for agents and lets them run the loops."*
