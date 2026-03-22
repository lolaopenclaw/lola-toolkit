# Program: backup-memory.sh Speed Optimization

TARGET_FILE: /home/mleon/.openclaw/workspace/scripts/backup-memory.sh
EVAL_COMMAND: bash /home/mleon/.openclaw/workspace/autoimprove/programs/backup-speed/eval.sh
BASELINE_SCORE: auto
GOAL: Minimize execution time while maintaining backup integrity
CONSTRAINTS: Must preserve all error handling, must not use dangerous commands, must backup all required files

## What to optimize

- Parallelize independent operations
- Combine multiple tar/gzip operations
- Use more efficient compression algorithms
- Reduce redundant file operations
- Add functions for repeated logic

## What NOT to change

- Must keep error handling (set -e, error checks)
- Must backup all memory/ files
- Must preserve backup integrity
- No dangerous rm -rf patterns
