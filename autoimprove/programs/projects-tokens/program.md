# Program: PROJECTS.md Token Efficiency

TARGET_FILE: /home/mleon/.openclaw/workspace/PROJECTS.md
EVAL_COMMAND: bash /home/mleon/.openclaw/workspace/autoimprove/programs/projects-tokens/eval.sh
BASELINE_SCORE: auto
GOAL: Minimize tokens while keeping all project metadata and status
CONSTRAINTS: Must preserve repo names, paths, states, dates, and critical notes

## What to optimize

- Remove verbose project descriptions
- Compress status emojis and metadata
- Consolidate redundant info
- Shorten notes while preserving key details

## What NOT to change

- Repo names and paths
- Project states and dates
- Cron IDs
- Critical links
