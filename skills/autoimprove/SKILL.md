---
name: autoimprove
description: "Nightly self-improvement loop (Karpathy Autoresearch pattern). Iterates on skills, scripts, memory, and workspace. Usage: /autoimprove [--max 10] [--target skills|scripts|memory|all] [--dry-run]"
user-invocable: true
---

# autoimprove — Nightly Self-Improvement Loop

Applies the Karpathy Autoresearch pattern (iterate → test → keep/discard) to your own infrastructure. Each iteration picks one target, proposes an improvement, measures the result, and keeps or reverts.

---

## Phase 1 — Parse Arguments & Initialize

### CLI Flags

| Flag | Default | Description |
|------|---------|-------------|
| --max | 10 | Max iterations this run |
| --target | all | Focus area: skills, scripts, memory, or all (rotates) |
| --dry-run | false | Analyze and propose only, don't apply |
| --circuit-breaker | 5 | Stop after N consecutive failures to improve |

### Improvement Log

Create/read: `$HOME/.openclaw/workspace/memory/autoimprove-log.json`

```json
{
  "runs": [
    {"date": "2026-03-14", "iterations": 10, "improvements": 3, "reverts": 6, "circuit_break": false, "details": [...]}
  ],
  "total_improvements": 0,
  "streak": 0
}
```

Use log to avoid re-trying failed experiments from past 7 days.

## Phase 3 — Iteration Loop

For each iteration (up to --max), rotate through targets:

```
Iteration 1  → SKILL optimization
Iteration 2  → SKILL optimization
Iteration 3  → SKILL optimization
Iteration 4  → SCRIPT optimization
Iteration 5  → SCRIPT optimization
Iteration 6  → SCRIPT optimization
Iteration 7  → MEMORY consolidation
Iteration 8  → MEMORY consolidation
Iteration 9  → MEMORY consolidation
Iteration 10 → SELF-REVIEW
```

### Circuit Breaker
Track consecutive failures. If `--circuit-breaker` consecutive iterations produce no improvement, stop early and log: "Circuit breaker triggered after N failures."

---

## Target: SKILLS (iterations 1-3)

### Pick target
Select a SKILL.md or protocol from:
- `$HOME/.openclaw/workspace/skills/*/SKILL.md`
- `$HOME/.openclaw/workspace/memory/*-protocol.md`

**Selection priority:**
1. Files not improved in >14 days (check git log)
2. Largest files (more room for optimization)
3. Files with known issues (referenced in autoimprove-log.json)

Skip files improved in the last 3 days (avoid churn).

### Measure BEFORE
- Token count: `wc -c <file>` (proxy for tokens)
- Structure score: count of clear sections, actionable instructions, examples
- Redundancy: grep for repeated phrases/concepts

### Propose improvement
Analyze the file and propose ONE of:
- **Clarity:** Rewrite ambiguous instructions to be more precise
- **Token efficiency:** Remove redundant text, consolidate repeated concepts
- **Completeness:** Add missing edge cases, error handling instructions
- **Structure:** Better organize sections for agent consumption

### Apply
Edit the file with the proposed improvement.

### Measure AFTER
- Same metrics as BEFORE
- **Key metric:** Token count should decrease OR structure score should increase
- If both metrics are worse → REVERT

### Decide
- **Improved** (tokens decreased ≥5% OR structure clearly better) → `git add <file> && git commit -m "autoimprove: optimize <filename> — <what changed>"`
- **No improvement or worse** → `git checkout -- <file>`
- Log the result either way

---

## Target: SCRIPTS (iterations 4-6)

### Pick target
Select an active script from `$HOME/.openclaw/workspace/scripts/*.sh` (not archive/).

**Selection priority:**
1. Scripts not improved in >14 days
2. Scripts with known errors in cron logs
3. Largest scripts (more room for optimization)

### Measure BEFORE
Run a dry-run or syntax check:
```bash
bash -n <script>  # Syntax check
wc -l <script>    # Line count
```

For scripts with measurable output (e.g., weekly-audit.sh), capture timing:
```bash
time bash <script> --analyze 2>&1 | tail -5
```

### Propose improvement
ONE of:
- **Robustness:** Add error handling, set -euo pipefail, check dependencies
- **Performance:** Optimize slow operations (find → fd, grep → ripgrep if available)
- **Readability:** Better comments, clearer variable names
- **DRY:** Extract repeated patterns into functions
- **Security:** Fix potential issues (unquoted variables, temp file races)

### Apply + Measure AFTER
- Syntax must still pass: `bash -n <script>`
- If the script is safe to run (non-destructive), run it and compare output
- Line count should not increase >20% (avoid bloat)

### Decide
Same as Skills: improved → commit, worse → revert.

---

## Target: MEMORY (iterations 7-9)

### Pick target
Select memory files from `$HOME/.openclaw/workspace/memory/`:

**Selection priority:**
1. Oldest daily files (>7 days, not yet archived)
2. Largest files (>10KB — candidates for splitting)
3. Files with overlapping content (dedup candidates)

### Operations
ONE of:
- **Consolidate:** Merge info from old daily files into MEMORY.md, then archive the daily
- **Dedup:** Find duplicate info across files, consolidate into one source of truth
- **Archive:** Move files >30 days old to archive/
- **Trim:** Remove outdated info (resolved issues, completed tasks, expired data)

### Measure
- Total memory size before/after
- File count before/after
- Key info preserved (spot-check: critical facts still findable)

### Decide
- Size decreased AND key info preserved → commit
- Key info lost → revert immediately

---

## Target: SELF-REVIEW (iteration 10)

### What to review
```bash
git log --oneline --since="24 hours ago" $HOME/.openclaw/workspace/
```

### Check for
- Commits with potential issues (large diffs, sensitive data patterns)
- Uncommitted changes that should be committed or discarded
- Files growing unexpectedly (compare with previous day's sizes)
- Cron errors in the last 24h

### Output
No file changes. Just log findings for the morning report.

---

## Phase 4 — Summary

After all iterations (or circuit break), generate summary:

```markdown
## 🔬 Autoimprove — {date}

**Iterations:** {completed}/{max}
**Improvements:** {kept} kept, {reverted} reverted
**Circuit breaker:** {yes/no}

### Changes kept:
- `skills/pr-review/SKILL.md` — Reduced token count 12% (removed redundant constraints)
- `scripts/weekly-audit.sh` — Added error handling for missing dirs
- `memory/2026-03-10.md` → archived (info consolidated to MEMORY.md)

### Attempted but reverted:
- `memory/hitl-protocol.md` — Proposed simplification lost important edge cases

### Self-review findings:
- No issues found in last 24h commits
```

Save summary to: `$HOME/.openclaw/workspace/memory/{date}-autoimprove.md`

Update the log file with run stats.

This summary is included in the next morning's informe matutino.

---

## Safety Constraints

1. **NEVER modify:** SOUL.md, IDENTITY.md, USER.md, AGENTS.md, BOOTSTRAP.md (core identity)
2. **NEVER delete** files — only archive (move to archive/)
3. **Always revert** if unsure — conservative by default
4. **Git commit each improvement** separately (easy to revert individually)
5. **No external actions** — no messages, no API calls, no network changes
6. **Time limit:** 5 minutes per iteration max. If stuck, skip and log.
7. **Don't re-try** experiments that failed in the last 7 days (check log)
