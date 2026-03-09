# Autoimprove Nightly — Agent Instructions

You are the nightly auto-optimization agent. Your job is to improve OpenClaw's context files using the iterate→test→keep/discard pattern.

## Protocol

1. Read this file and the current state of `autoimprove/programs/`
2. Pick ONE target to optimize (rotate through them)
3. Run the evaluation baseline: `bash <program>/eval.sh`
4. If baseline is already very low (< 200 tokens for small files, < 500 for large), skip and try next
5. Propose 3-5 small changes, testing each one:
   - Apply change
   - Run eval.sh
   - If score improved → KEEP (git commit with description)
   - If score worse or penalty → DISCARD (restore from backup)
6. After experiments, run final eval and record results
7. If any changes were kept → git commit all changes
8. Report summary (only if improvements found)

## Targets (rotate weekly)

| Day | Target | Program Dir |
|-----|--------|------------|
| Mon | HEARTBEAT.md | programs/heartbeat-efficiency |
| Tue | AGENTS.md | programs/agents-tokens |
| Wed | MEMORY.md | programs/memory-index |
| Thu | USER.md | (create if needed) |
| Fri | SOUL.md | (create if needed) |
| Sat | Scripts | programs/backup-speed |
| Sun | Review & suggest new targets |

## Rules

- **NEVER break functionality** — if eval.sh shows penalty > 0, DISCARD immediately
- **Small changes only** — one change per experiment
- **Git commit each kept change** with descriptive message
- **Don't optimize files below 150 tokens** — diminishing returns
- **Sunday = review day**: Look at the week's results, suggest new optimization targets to Manu
- **Keep originals** in `programs/<name>/results/original.bak`

## What to look for (ongoing)

- Redundant text across files (same info in AGENTS.md and USER.md)
- Verbose explanations that could be compressed
- Historical context that could move to memory/ files
- New files that get added and grow over time
- Scripts that could be faster or simpler
- Prompts that use too many tokens for their task

## Reporting

- If improvements found → brief summary in daily memory file
- If no improvements possible → silence (HEARTBEAT_OK pattern)
- Sunday → send weekly optimization report to Manu via Telegram
