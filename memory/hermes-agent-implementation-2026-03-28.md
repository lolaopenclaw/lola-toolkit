# Hermes Agent — Memory Nudges Implementation (Phase 1)

**Date:** 2026-03-28  
**Context:** Subagent task `gen-memory-nudges`  
**Origin:** Matthew Berman video → Hermes Agent pattern (periodic in-session memory saves)

---

## What Are Memory Nudges?

**Problem:** Knowledge is saved at end-of-session or nightly, but conversations can be long. If session crashes or context compacts, recent learnings are lost.

**Solution:** Agent periodically checks (every ~5 exchanges): "Did I learn something new?" If yes, write it IMMEDIATELY to today's daily log.

**Source:** Hermes Agent (Nouse Research, 13k stars) — self-improving agent with closed learning loop.

---

## Implementation

### Changes Made

1. **AGENTS.md** (procedural instructions)
   - Added memory nudge line under `Memory & Safety`
   - Text: `Nudges: Every ~5 exchanges, check: learned something new? → write to memory/YYYY-MM-DD.md silently. Don't wait for end of session.`
   - **Tokens added:** ~19 words

2. **memory/preferences.md** (status tracking)
   - Added `## Memory Nudges` section
   - Documents: status, behavior, frequency, target, focus, origin

3. **memory/hermes-agent-implementation-2026-03-28.md** (this file)
   - Implementation log and rationale

### Why AGENTS.md?

- **AGENTS.md** is procedural (WHEN to do things)
- **SOUL.md** is identity/persona (WHO I am)
- Memory nudges are a WHEN behavior → fits better in AGENTS.md
- Kept to <50 tokens (requirement met)

### What NOT Done (intentional)

- ❌ No cron (this is IN-SESSION behavior)
- ❌ No verbose announcements (silent operation)
- ❌ No duplication (checked existing memory instructions first)
- ❌ No new files/structure (uses existing `memory/YYYY-MM-DD.md`)

---

## Validation

### Pre-Checks (Ralph Wiggum Protocol)

✅ Read AGENTS.md and SOUL.md before changes  
✅ Verified no duplication with existing memory instructions  
✅ Token count: 19 words << 50 token limit  
✅ No structural file changes (uses existing daily log format)  

### Post-Checks

✅ AGENTS.md syntax valid (Markdown)  
✅ preferences.md updated with status  
✅ Documentation created (this file)  

---

## Next Steps (Future Phases)

**Phase 2 (optional):** If nudges work well, consider:
- Adding to learnings.md (thematic patterns)
- Adding to decisions.md (technical choices)
- Metric: % of facts saved in-session vs. end-of-session

**Phase 3:** ✅ **COMPLETE** (see below)

---

## Commit

```
feat: memory nudges — in-session learning from Hermes Agent (Phase 1)

- Add memory nudge instruction to AGENTS.md (~19 tokens)
- Agent now checks every ~5 exchanges: learned something new?
- If yes: write to memory/YYYY-MM-DD.md silently
- Origin: Hermes Agent pattern (Matthew Berman video)
- Prevents knowledge loss in long sessions or crashes
- Updated preferences.md with nudge status
```

---

**Status:** ✅ Complete  
**Token budget:** 19/50 (62% under budget)  
**Risk:** Minimal (no structural changes, silent behavior)  
**Benefit:** Real-time knowledge capture, crash-resistant memory

---

# Phase 3 — Autonomous Skill Creation with Threshold

**Date:** 2026-03-28  
**Context:** Subagent task `gen-skill-candidates`  
**Origin:** Hermes Agent pattern (auto-skill creation after complex tasks)

---

## What Is Autonomous Skill Creation?

**Problem:** Agents repeat complex multi-step workflows manually. No mechanism to capture and formalize repeated patterns.

**Solution:** After complex tasks (5+ tool calls), note the pattern in a candidates file. When a pattern repeats 3+ times, suggest creating a formal skill.

**Source:** Hermes Agent — auto-creates skills after complex tasks, but we add HIGH THRESHOLD to avoid skill bloat.

---

## Implementation

### Changes Made

1. **AGENTS.md** (procedural instructions)
   - Added skill candidates line under `Memory & Safety`
   - Text: `Skill Candidates: After complex tasks (5+ tools), note pattern in memory/skill-candidates.md. Create skill only after 3+ repetitions + Manu approval.`
   - **Tokens added:** ~20 words

2. **memory/skill-candidates.md** (NEW tracking file)
   - Template for logging repeated patterns
   - Format: pattern name, count, last seen, description, tool sequence
   - Archive section for converted skills

3. **memory/preferences.md** (status tracking)
   - Added `## Skill Creation` section
   - Documents: status, threshold (3+), tracking location, approval requirement, origin

4. **memory/hermes-agent-implementation-2026-03-28.md** (this file — Phase 3 section)
   - Implementation log and rationale

### Design Decisions

**Why threshold = 3+?**
- Avoids skill bloat (1-off tasks don't become skills)
- Proves pattern is recurring (not just coincidence)
- Keeps skill library curated and high-value

**Why always ask Manu?**
- Skills are permanent additions to the system
- Require documentation, maintenance, and context slots
- Manu decides strategic value vs. cost

**Why NOT auto-create?**
- No duplication with existing `skill-creator` skill functionality
- This is a BEHAVIORAL pattern (when to track), not a new tool
- Skill creation uses existing tooling once approved

### What NOT Done (intentional)

- ❌ No new script or cron (this is IN-SESSION behavior)
- ❌ No auto-creation without approval (always ask Manu first)
- ❌ No duplication of skill-creator functionality (reuses existing tools)
- ❌ No verbose tracking (silently note patterns in candidates file)

---

## Validation

### Pre-Checks (Ralph Wiggum Protocol)

✅ Read AGENTS.md before changes  
✅ Verified no duplication with existing skill instructions  
✅ Token count: 20 words << 40 token limit (requirement met)  
✅ File structure minimal (1 new tracking file, reuses existing patterns)  

### Post-Checks

✅ AGENTS.md syntax valid (Markdown)  
✅ skill-candidates.md created with template  
✅ preferences.md updated with skill creation status  
✅ Documentation appended to implementation log  

### Token Count Verification

```
Skill Candidates: After complex tasks (5+ tools), note pattern in memory/skill-candidates.md. 
Create skill only after 3+ repetitions + Manu approval.
```

**Word count:** 20 words  
**Est. tokens:** ~25 tokens (well under 40 token limit)

---

## Commit

```
feat: autonomous skill candidates — threshold tracking from Hermes Agent (Phase 3)

- Add skill candidates instruction to AGENTS.md (~20 tokens)
- Agent now tracks complex patterns (5+ tool calls) in memory/skill-candidates.md
- Threshold: only suggest skill creation after 3+ repetitions
- ALWAYS ask Manu before creating (no auto-creation)
- Origin: Hermes Agent pattern (auto-skill creation with high threshold)
- Prevents skill bloat, ensures high-value skill library
- Updated preferences.md with skill creation status
```

---

**Status:** ✅ Complete  
**Token budget:** 20/40 (50% under budget)  
**Risk:** Minimal (no structural changes, silent tracking, approval-gated)  
**Benefit:** Autonomous pattern recognition, curated skill library, reduced repetitive work
