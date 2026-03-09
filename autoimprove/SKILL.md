---
name: autoimprove
description: Auto-optimize files using iterate→test→keep/discard loop (inspired by Karpathy's autoresearch)
---

# Autoimprove

Auto-optimization framework. Iteratively improves a target file by proposing changes, evaluating with an objective metric, and keeping only improvements.

## Quick Start

```bash
# Initialize a program
bash autoimprove/runner.sh autoimprove/programs/<name>

# Then follow the agent-loop.md instructions
```

## Creating a New Program

1. Create directory: `autoimprove/programs/<name>/`
2. Create `program.md`:
   ```
   TARGET_FILE: /path/to/file
   EVAL_COMMAND: bash /path/to/eval.sh
   BASELINE_SCORE: auto
   GOAL: What to optimize (minimize score)
   CONSTRAINTS: What must NOT break
   ```
3. Create `eval.sh`: Script that outputs a single number (lower = better). Add penalties for missing required elements.

## Agent Protocol

1. Run `runner.sh` to get context
2. Read target file
3. Propose ONE change
4. Apply it
5. Run eval.sh → get score
6. If score < best → KEEP (update best, save backup)
7. If score >= best → DISCARD (restore from backup)
8. Record in results.tsv
9. Repeat

## Existing Programs

| Program | Target | Metric | Status |
|---------|--------|--------|--------|
| heartbeat-efficiency | HEARTBEAT.md | tokens | ✅ 792→255 (67.8% ↓) |
| agents-tokens | AGENTS.md | tokens | ✅ 4088→1020 (75% ↓) |
| backup-speed | backup-memory.sh | seconds | 🔧 Ready to run |
