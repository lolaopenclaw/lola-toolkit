# Autoresearch Program: lola-toolkit Shell Script Optimization

## Goal
Optimize all shell scripts in the lola-toolkit repository for maximum reliability, speed, and code quality.

## Metric
Composite score (lower is better) based on:
- **Shellcheck warnings/errors** (weight: 3x) — Critical for reliability
- **Total lines of code** (weight: 1x) — Prefer conciseness
- **Anti-patterns detected** (weight: 2x) — Unquoted vars, missing set -e, etc.
- **Execution time** (weight: 0.5x) — For scripts with benchmarks

**Formula:**
```
score = (shellcheck_issues * 3) + (total_loc * 1) + (antipatterns * 2) + (avg_exec_ms * 0.5)
```

## Constraints
1. **Never break existing functionality** — All scripts must continue to work
2. **One change per experiment** — Single logical improvement at a time
3. **Git commit each kept change** — Atomic improvements only
4. **Max experiment time: 2 minutes** — Fast iterations
5. **Preserve script interfaces** — Command-line args and output format stay stable

## What Can Be Modified
- Any `.sh` file in the repository
- Code structure, error handling, quotes, pipelines
- Comments and documentation within scripts

## What Cannot Be Modified
- `program.md` (this file)
- `eval.sh` (scoring script)
- `run-loop.sh` (loop runner)
- `experiment-log.jsonl` (log file)
- Non-shell files (protocols, SKILL.md, etc.)

## Improvement Strategies
- Add proper error handling (`set -euo pipefail`)
- Quote all variables to prevent word splitting
- Use shellcheck recommendations
- Remove unused code
- Simplify complex pipelines
- Add better comments for clarity
- Optimize slow operations
- Use builtins over external commands when possible

## Success Criteria
An experiment is considered successful if:
- Score improves (decreases)
- All existing functionality still works
- No new shellcheck warnings introduced
