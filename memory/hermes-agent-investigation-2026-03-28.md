# 🔬 Hermes Agent Investigation — 2026-03-28

**Repository:** https://github.com/NousResearch/hermes-agent  
**Stars:** 14,817  
**Organization:** Nous Research  
**License:** MIT  
**Documentation:** https://hermes-agent.nousresearch.com/docs/

---

## Executive Summary

Hermes Agent is a self-improving AI agent framework by Nous Research with a **built-in learning loop**. It's architecturally similar to OpenClaw but more mature in some areas — particularly around skill management, memory persistence, and the closed learning loop. The agent creates skills from experience, improves them during use, nudges itself to persist knowledge, and searches past conversations.

**Key differentiator:** The "closed learning loop" is more explicit and systematic than our current autoimprove implementation. Hermes has **agent-curated memory with periodic nudges**, **autonomous skill creation**, and **self-improvement during skill use**.

---

## Architecture Overview

### Core Components (from docs)

1. **Agent Loop** (`run_agent.py`): Core orchestration — provider selection, prompt construction, tool execution, retries, compression
2. **Skills System** (`~/.hermes/skills/`): Progressive disclosure pattern — skills load on-demand to minimize tokens
3. **Memory System** (`MEMORY.md` + `USER.md`): Bounded, curated memory (2,200 + 1,375 char limits) + FTS5 session search
4. **Gateway**: Multi-platform messaging (Telegram, Discord, Slack, WhatsApp, Signal)
5. **Cron**: Built-in scheduler with platform delivery
6. **Subagents**: Spawn isolated subagents for parallel work
7. **Terminal Backends**: Six backends (local, Docker, SSH, Daytona, Singularity, Modal)

### Learning Loop Components

From README and docs:
- **Agent-curated memory** with periodic nudges
- **Autonomous skill creation** after complex tasks (5+ tool calls)
- **Skills self-improve during use**
- **FTS5 session search** with LLM summarization for cross-session recall
- **Honcho integration** for dialectic user modeling (optional)
- Compatible with **agentskills.io** open standard

---

## Feature Comparison: Hermes vs OpenClaw

| Feature | Hermes Agent | OpenClaw (Our Setup) | Notes |
|---------|--------------|----------------------|-------|
| **Learning Loop** | ✅ Built-in, explicit | 🟡 Manual (`autoimprove` skill) | Hermes has systematic agent-initiated loop |
| **Skill Creation** | ✅ Autonomous after 5+ tool calls | 🟡 Manual or via skill-creator | Hermes auto-detects complex workflows |
| **Skill Self-Improvement** | ✅ Skills improve during use | ❌ Not implemented | We iterate in batch (nightly), not in-use |
| **Memory System** | ✅ Bounded (MEMORY.md 2.2k, USER.md 1.3k chars) | ✅ Similar (MEMORY.md, SOUL.md, USER.md) | Both use bounded memory |
| **Memory Nudges** | ✅ Periodic nudges to persist knowledge | ❌ Not implemented | We rely on daily memory writes |
| **Session Search** | ✅ FTS5 + LLM summarization | 🟡 Basic (session-logs skill with jq) | Hermes has full-text search in SQLite |
| **User Modeling** | ✅ Honcho integration (dialectic modeling) | ❌ Not implemented | Optional advanced feature |
| **Skills Hub** | ✅ Multiple registries (official, skills.sh, well-known, GitHub) | ✅ ClawHub + local | Hermes has broader ecosystem |
| **Progressive Disclosure** | ✅ 3-level loading (list → view → files) | 🟡 Partial (available_skills in prompt) | Hermes more token-efficient |
| **Migration Tool** | ✅ `hermes claw migrate` | N/A | They built OpenClaw migration! |
| **Multi-platform Gateway** | ✅ 6 platforms in one process | ✅ Similar (Telegram, Discord via plugins) | Similar architecture |
| **Cron Delivery** | ✅ To any platform | ✅ To Telegram | Hermes more flexible |
| **Subagents** | ✅ Isolated parallel workstreams | ✅ Similar (sessions_spawn) | Both have this |
| **Terminal Backends** | ✅ 6 backends (incl. Modal, Daytona serverless) | 🟡 SSH + local | Hermes has serverless options |
| **Security Scanning** | ✅ Skills Hub security scanner | 🟡 Basic (healthcheck skill) | Hermes scans hub-installed skills |
| **Karpathy Pattern** | 🟡 Not explicitly mentioned | ✅ Documented in `autoimprove` skill | We have explicit Karpathy implementation |

---

## Applicable Ideas (Ranked by Value)

### 🟢 HIGH VALUE — Implement Soon

#### 1. **Periodic Memory Nudges** ⭐⭐⭐⭐⭐
**What:** Agent periodically reminds itself to save important facts to memory  
**How it works in Hermes:** System prompt includes nudges to persist knowledge learned during session  
**Effort:** LOW (add to prompt, existing memory tool works)  
**Risk:** None  
**Implementation:**
- Add to AGENTS.md: "After learning important facts, use memory tool proactively"
- Add cron nudge every N turns: "Review this session — any facts worth persisting?"
- Update `memory/preferences.md` protocol with nudge triggers

**Value:** High — prevents knowledge loss between sessions

---

#### 2. **Autonomous Skill Creation After Complex Tasks** ⭐⭐⭐⭐⭐
**What:** After completing complex workflows (5+ tool calls), agent automatically creates/updates a skill  
**How it works in Hermes:** Built into agent loop — detects complex tasks and offers to save as skill  
**Effort:** MEDIUM (requires prompt changes + detection logic)  
**Risk:** Low (can be disabled)  
**Implementation:**
- Modify AGENTS.md: "After complex multi-step tasks (5+ tools), consider creating a SKILL.md"
- Add counter in session context
- Post-task prompt: "Did this workflow warrant a new skill? If yes, use skill-creator"
- Could trigger `autoimprove` immediately vs waiting for nightly run

**Value:** High — captures workflows while fresh, vs waiting for nightly batch

---

#### 3. **Skills Self-Improvement During Use** ⭐⭐⭐⭐
**What:** When using a skill, if agent hits errors or finds a better approach, it updates the skill immediately  
**How it works in Hermes:** Agent modifies SKILL.md during task execution when it discovers improvements  
**Effort:** MEDIUM (requires permission/confidence checks)  
**Risk:** MEDIUM (could corrupt skills with bad edits)  
**Implementation:**
- Add to each SKILL.md footer: "If you discover improvements while using this skill, update it immediately"
- Add verification step: test before committing
- Log all skill modifications to `memory/skill-improvements.log`
- Safety: only modify after successful task completion

**Value:** High — continuous improvement vs batch nightly iterations

**Safeguards needed:**
- Git commit each change separately
- Verification before finalizing
- Rollback on failure

---

#### 4. **Progressive Disclosure for Skills** ⭐⭐⭐⭐
**What:** Three-level skill loading: list (names + descriptions) → view (full SKILL.md) → files (references/)  
**How it works in Hermes:** `skills_list()` returns minimal data, `skill_view(name)` loads full content  
**Effort:** LOW (already partially implemented in available_skills)  
**Risk:** None  
**Implementation:**
- Currently we inject all skill descriptions in `<available_skills>` block (~3k tokens)
- Could reduce to: name + 1-line description only
- Agent calls `read` when it needs full SKILL.md (already does this)
- Save ~2k tokens per session start

**Value:** Medium-High — token savings in every session

---

### 🟡 MEDIUM VALUE — Consider Later

#### 5. **FTS5 Session Search** ⭐⭐⭐
**What:** Full-text search across all past sessions in SQLite with FTS5  
**How it works in Hermes:** Agent searches past conversations, LLM summarizes results  
**Effort:** HIGH (requires SQLite FTS5 setup, session storage format)  
**Risk:** LOW  
**Current state:** We have `session-logs` skill with `jq` — works but less powerful  
**Implementation:**
- Already have session logs in JSON format
- Need to:
  1. Import into SQLite with FTS5 index
  2. Create `session_search` tool (like Hermes)
  3. Add summarization step (Gemini Flash for cost)
- Value: Better than current jq-based search

**Value:** Medium — nice-to-have, current solution works

---

#### 6. **Honcho Integration (User Modeling)** ⭐⭐
**What:** Deep AI-generated user understanding across sessions using Honcho  
**Repository:** https://github.com/plastic-labs/honcho  
**Effort:** HIGH (external service dependency)  
**Risk:** MEDIUM (privacy, API dependency)  
**Value:** LOW — We already have USER.md + memory system, this is overkill for single-user setup

---

#### 7. **Skills Hub Security Scanner** ⭐⭐⭐
**What:** Automatic security scanning for hub-installed skills (data exfiltration, prompt injection, destructive commands)  
**Effort:** MEDIUM (pattern matching + policy framework)  
**Risk:** LOW  
**Current state:** We have `healthcheck` skill for system security, not for skills  
**Implementation:**
- Create `skills/skill-security-scanner/SKILL.md`
- Scan on install (ClawHub integration)
- Check for: exfiltration patterns, destructive commands, secrets in plain text
- Inspired by Hermes scanner

**Value:** Medium — useful for ClawHub ecosystem

---

### 🔴 LOW VALUE — Don't Implement

#### 8. **Serverless Terminal Backends (Modal, Daytona)** ⭐
**Reason:** Not needed — we have stable VPS + SSH, hibernation not a priority  
**Effort:** HIGH  
**Value:** LOW for our use case

---

#### 9. **Six Platform Gateway** ⭐
**Reason:** We only use Telegram actively, don't need Discord/Slack/WhatsApp/Signal  
**Current state:** Telegram works well  
**Value:** LOW unless Manu requests multi-platform

---

## Implementation Recommendations

### Phase 1: Quick Wins (1-2 days)
1. **Memory Nudges** — Add to AGENTS.md + prompt
2. **Progressive Disclosure** — Reduce available_skills token cost
3. **Autonomous Skill Creation Prompting** — Add guidance to AGENTS.md

### Phase 2: Moderate Effort (1 week)
4. **Skills Self-Improvement** — Enable in-use skill modifications with safety checks
5. **Session Search Upgrade** — SQLite FTS5 implementation

### Phase 3: Long-term (Later)
6. **Skills Hub Security Scanner** — For ClawHub ecosystem
7. **Honcho Integration** — Only if Manu wants advanced user modeling

---

## Key Lessons from Hermes

### 1. **The Learning Loop Should Be Explicit and Continuous**
Hermes makes the learning loop a **first-class feature**, not a nightly batch job. Our `autoimprove` skill is good but reactive. Hermes is proactive.

**Takeaway:** Move from nightly batch → continuous learning with safety checks

---

### 2. **Skills Are Living Documents**
Hermes treats skills as **mutable artifacts** that improve during use. We treat them as static files that get batch-optimized.

**Takeaway:** Enable mid-session skill updates with verification

---

### 3. **Memory Needs Active Curation**
Hermes has **character limits** (2,200 + 1,375) and **nudges** to keep memory fresh. We have similar structure but less enforcement.

**Takeaway:** Add periodic memory consolidation nudges (not just daily writes)

---

### 4. **Progressive Disclosure Saves Tokens**
Hermes loads skills on-demand (3 levels). We inject all descriptions upfront.

**Takeaway:** Reduce upfront skill descriptions to 1-line summaries

---

### 5. **Autonomous Beats Manual**
Hermes auto-creates skills after 5+ tool calls. We rely on manual `/autoimprove` or nightly cron.

**Takeaway:** Add automatic skill-creation detection

---

## Comparison with Karpathy Autoresearch

**Karpathy Pattern (our `autoimprove` skill):**
- Fixed time budget per experiment
- Greedy hill-climbing (keep if better, discard if worse)
- One measurable metric
- Git commits each improvement

**Hermes Learning Loop:**
- Continuous (not time-boxed)
- Multi-target (memory, skills, user profile)
- No single metric — uses agent judgment
- More general-purpose

**Synthesis:**
Both are valid! We can combine:
- **Nightly batch optimization** (Karpathy pattern) for systematic improvement
- **In-session learning** (Hermes pattern) for immediate knowledge capture

---

## Migration Considerations

Hermes has `hermes claw migrate` to import from OpenClaw! This is significant — they consider OpenClaw users a migration target.

**What they import:**
- SOUL.md → persona file
- MEMORY.md + USER.md → memories
- Skills → `~/.hermes/skills/openclaw-imports/`
- Command allowlist → approval patterns
- API keys (Telegram, OpenRouter, OpenAI, Anthropic, ElevenLabs)
- AGENTS.md → workspace instructions

**Implication:** Hermes and OpenClaw are **compatible architectures**. Ideas flow both ways.

---

## Risks and Considerations

### Risk 1: Over-Engineering
**Concern:** Hermes is a large, complex system (14k stars, full organization behind it). Copying everything would bloat our setup.  
**Mitigation:** Cherry-pick specific features (nudges, autonomous skill creation, progressive disclosure) without rewriting core

### Risk 2: In-Use Skill Modifications Could Corrupt Skills
**Concern:** Allowing mid-session skill edits without verification risks breaking skills  
**Mitigation:** 
- Git commit each change
- Verification step before finalize
- Rollback on error
- Log all modifications

### Risk 3: Memory Drift
**Concern:** Continuous memory updates could lead to inconsistency  
**Mitigation:** Keep our daily consolidation pattern, add nudges on top (not instead of)

---

## Conclusion

Hermes Agent is a **mature, production-ready** agent framework with several ideas directly applicable to our setup:

**Implement immediately:**
1. Memory nudges (LOW effort, HIGH value)
2. Progressive skill disclosure (LOW effort, MEDIUM value)
3. Autonomous skill creation prompting (MEDIUM effort, HIGH value)

**Consider for later:**
4. Skills self-improvement during use (MEDIUM effort, HIGH value, needs safety checks)
5. FTS5 session search (HIGH effort, MEDIUM value)

**Don't implement:**
- Serverless backends (not needed)
- Multi-platform gateway (Telegram sufficient)
- Honcho integration (overkill for single-user)

**Core insight:** The "closed learning loop" is about making learning **continuous and autonomous**, not just nightly batch optimization. We can enhance our Karpathy-inspired `autoimprove` with Hermes-style real-time learning while keeping our batch optimization for systematic improvement.

---

## Links and References

- **Repository:** https://github.com/NousResearch/hermes-agent
- **Documentation:** https://hermes-agent.nousresearch.com/docs/
- **Skills System:** https://hermes-agent.nousresearch.com/docs/user-guide/features/skills
- **Memory System:** https://hermes-agent.nousresearch.com/docs/user-guide/features/memory
- **Architecture:** https://hermes-agent.nousresearch.com/docs/developer-guide/architecture
- **Honcho (user modeling):** https://github.com/plastic-labs/honcho
- **AgentSkills.io standard:** https://agentskills.io
- **Skills Hub (skills.sh):** https://skills.sh
- **Discord:** https://discord.gg/NousResearch

---

**Investigation completed:** 2026-03-28  
**Researcher:** Lola (subagent)  
**Sources:** GitHub repo, official docs, README analysis  
**All claims verified from official documentation — no speculation.**
