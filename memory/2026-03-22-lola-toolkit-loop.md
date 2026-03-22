# Loop Gordo: lola-toolkit Autoresearch Setup

**Date:** 2026-03-22 14:25  
**Repository:** https://github.com/lolaopenclaw/lola-toolkit  
**Local path:** ~/lola-toolkit  
**Pattern:** Karpathy Autoresearch (measure → improve → measure → keep/discard)

---

## Repository Overview

- **Total scripts:** 17 shell scripts
- **Structure:**
  - `/scripts/` — 14 operational scripts (health checks, backups, reports, etc.)
  - `/skills/` — 3 skills with embedded scripts
  - `/protocols/` — 8 protocol markdown files

### Key Scripts
- `backup-memory.sh`, `backup-validator.sh`
- `garmin-health-report.sh`, `gateway-health-check.sh`
- `health-alerts.sh`, `health-dashboard.sh`
- `informe-matutino-auto.sh`, `memory-decay.sh`
- `post-commit-backup.sh`, `pr-reviewer.sh`
- `system-updates-nightly.sh`, `usage-report.sh`
- `weekly-audit.sh`, `worktree-manager.sh`

---

## Autoresearch Loop Setup

### Files Created

1. **program.md** — Defines the optimization goal, metrics, and constraints
   - Goal: Optimize shell scripts for reliability, speed, and code quality
   - Metric: Composite score = `(shellcheck_issues × 3) + (LOC × 1) + (antipatterns × 2) + (exec_ms × 0.5)`
   - Lower score = better

2. **eval.sh** — Scoring script
   - Analyzes all `.sh` files in repo
   - Counts shellcheck warnings/errors (weight: 3x)
   - Measures total lines of code (weight: 1x)
   - Detects anti-patterns (weight: 2x):
     - Missing `set -e`, `set -u`, or `set -o pipefail`
     - Unquoted variables
     - Pipelines without pipefail
   - Returns JSON with composite score

3. **run-loop.sh** — Main loop runner
   - Reads program.md for context
   - Establishes baseline score
   - Iterates N times (default 50):
     - Picks random script
     - Spawns subagent to make ONE improvement
     - Re-evaluates score
     - If improved → git commit
     - If worse → git reset --hard
   - Logs to `experiment-log.jsonl`
   - Options: `--dry-run`, `--max N`

---

## Baseline Metrics (2026-03-22 14:25)

```json
{
  "score": 2175.0,
  "shellcheck_issues": 45,
  "lines_of_code": 1928,
  "antipatterns": 56,
  "avg_exec_ms": 0,
  "scripts_analyzed": 17,
  "timestamp": "2026-03-22T14:25:08+01:00"
}
```

### Breakdown
- **Shellcheck issues:** 45 (contributing 135 to score)
- **Lines of code:** 1928 (contributing 1928 to score)
- **Anti-patterns:** 56 (contributing 112 to score)
- **Execution time:** Not yet implemented (0)

---

## Current State

✅ **Setup complete**  
✅ **Baseline established**  
✅ **Dependencies installed** (shellcheck, bc)  
✅ **Loop verified**  
⏸️ **Loop NOT started** (awaiting explicit permission)

---

## Next Steps (Manual)

To run the loop:

```bash
cd ~/lola-toolkit
./run-loop.sh                # 50 iterations
./run-loop.sh --max 100      # 100 iterations
./run-loop.sh --dry-run      # Test without changes
```

To check progress:
```bash
cd ~/lola-toolkit
tail -f experiment-log.jsonl
git log --oneline | head -20
```

---

## Important Notes

- ⚠️ Loop uses `claude --print` for subagent spawning (fallback to openclaw not implemented)
- ⚠️ All changes are committed locally to git
- ⚠️ **NO automatic push to GitHub** (manual push required)
- ✅ Changes are atomic — each experiment is one commit
- ✅ Failed experiments are reverted with `git reset --hard`

---

## Repository Status

Git status before loop:
- Repository cloned fresh from GitHub
- All autoresearch files added but NOT committed yet
- Ready to commit setup and start loop

---

_Setup completed by subagent phase2-loop-gordo_  
_Baseline score: 2175.0 — room for significant improvement!_
