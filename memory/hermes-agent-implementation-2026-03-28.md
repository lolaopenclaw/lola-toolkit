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

**Phase 3 (research):** Full Hermes Agent review:
- Self-improving loop (how does it avoid context bloat?)
- Skill curation (how does it prune/evolve skills?)
- Migration path from OpenClaw (if valuable)

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
