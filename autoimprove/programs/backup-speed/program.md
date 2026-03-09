TARGET_FILE: /home/mleon/.openclaw/workspace/scripts/backup-memory.sh
EVAL_COMMAND: bash /home/mleon/.openclaw/workspace/autoimprove/programs/backup-speed/eval.sh
BASELINE_SCORE: auto
GOAL: Minimize total execution time (seconds) while maintaining backup completeness
CONSTRAINTS: Must include ALL current backup components. Must produce valid tar.gz. Must upload to Drive successfully. Must not break restore.sh compatibility.

## Context

backup-memory.sh creates a daily backup of the OpenClaw workspace, config, secrets, 
and system snapshot. It uploads to Google Drive. It runs every day at 4 AM.

Current size: ~584K compressed.
Current time: ~15-25 seconds.

## What to try

- Parallel file copies (background jobs + wait)
- Reduce redundant cp operations
- Use rsync instead of cp for incremental efficiency
- Optimize tar compression level (gzip -1 vs default -6)
- Skip unchanged files (checksum comparison)
- Combine multiple cp into a single rsync or tar
- Reduce the number of subshell invocations
- Batch the system snapshot commands
