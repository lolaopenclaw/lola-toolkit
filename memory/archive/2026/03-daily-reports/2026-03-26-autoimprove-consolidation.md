# Autoimprove Consolidation — 2026-03-26

## Summary

Consolidated 3 separate autoimprove crons into 1 unified script with `--target` flag.

## What Changed

### Before
- **3 separate crons** running at different times:
  - `dcae7b06` — Autoimprove Scripts (3:00 AM)
  - `8d65b575` — Autoimprove Skills (3:05 AM)
  - `881d2943` — Autoimprove Memory (3:10 AM)

### After
- **1 unified cron** at 3:00 AM:
  - `f55e48da` — 🔬 Autoimprove Nightly (unified)
- **1 unified script**: `scripts/autoimprove-unified.sh`
  - Accepts `--target scripts|skills|memory|all` (default: all)
  - Runs sequentially: scripts → skills → memory
  - Supports `--dry-run` for testing
  - Logs to `memory/autoimprove-log-YYYY-MM-DD.md`

## Technical Details

### Script Features
```bash
# Usage examples
bash scripts/autoimprove-unified.sh --target all           # Run all three
bash scripts/autoimprove-unified.sh --target scripts       # Only scripts
bash scripts/autoimprove-unified.sh --dry-run              # Preview mode
bash scripts/autoimprove-unified.sh --max-iterations 10    # Custom limit
```

**What it does:**
1. **Scripts optimization** — `backup-memory.sh` and other shell scripts
   - Metrics: execution time, error handling, code quality
   - Uses: `autoimprove/programs/backup-speed/eval.sh`

2. **Skills optimization** — `HEARTBEAT.md`, `AGENTS.md`, skill files
   - Metrics: token count, clarity, actionability
   - Uses: `wc -w` approximation (words * 0.75)

3. **Memory optimization** — `MEMORY.md` and memory files
   - Metrics: token count, index coverage, duplication
   - Checks: orphaned references, entry count

**Safety features:**
- All experiments logged to `autoimprove/experiment-log.jsonl`
- Core identity files (SOUL.md, USER.md, IDENTITY.md) never modified
- Failed experiments automatically reverted
- Syntax validation before applying changes

### Cron Configuration

**New unified cron:**
- **ID:** `f55e48da-f6b2-4f56-aecc-0c8ec67a8197`
- **Name:** 🔬 Autoimprove Nightly (unified)
- **Schedule:** 3:00 AM Madrid (every day)
- **Model:** Sonnet 4
- **Target:** isolated session
- **Delivery:** Telegram announce to main topic

**Old crons (now DISABLED, kept as backup):**
- `dcae7b06` — Scripts Agent (disabled, not deleted)
- `8d65b575` — Skills Agent (disabled, not deleted)
- `881d2943` — Memory Agent (disabled, not deleted)

## Benefits

1. **Simpler orchestration** — One script to maintain instead of three
2. **Sequential execution** — No timing dependencies, runs in order
3. **Better logging** — Unified log format across all targets
4. **Easier testing** — `--dry-run` flag for safe previews
5. **Flexible targeting** — Can run individual targets or all at once
6. **Preserved logic** — Does EXACTLY what the 3 separate crons did

## Validation

✅ Syntax check passed: `bash -n scripts/autoimprove-unified.sh`
✅ Shellcheck passed (1 minor warning about unused variable)
✅ Dry-run test successful for all targets
✅ Help output verified
✅ New cron created and scheduled
✅ Old crons disabled (not deleted)

## Rollback Plan

If issues arise, the old crons can be re-enabled:
```bash
openclaw cron enable dcae7b06-e6fb-40d4-88bc-9bc618feb70d
openclaw cron enable 8d65b575-5023-4160-bbc3-45ac449f17d3
openclaw cron enable 881d2943-dc39-4bf4-b1cf-6344ff6bbf53
openclaw cron disable f55e48da-f6b2-4f56-aecc-0c8ec67a8197
```

## Next Steps

- Monitor first run tonight (2026-03-27 03:00 AM Madrid)
- Check `memory/autoimprove-log-YYYY-MM-DD.md` for results
- If successful after 1 week, can delete old disabled crons
- Consider adding `--parallel` flag if sequential execution is too slow

## Files Created

- `scripts/autoimprove-unified.sh` — Main script (11KB, 262 lines)
- `memory/2026-03-26-autoimprove-consolidation.md` — This document

## References

- Original Karpathy pattern: `memory/autoresearch-karpathy.md`
- Autoimprove skill: `skills/autoimprove/SKILL.md`
- Experiment logs: `autoimprove/experiment-log.jsonl`

---

**Status:** ✅ Complete and ready for production
**Assigned subagent:** gen-autoimprove-unified
**Date:** 2026-03-26 14:18
