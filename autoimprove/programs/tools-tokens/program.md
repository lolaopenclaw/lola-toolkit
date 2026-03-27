# Program: TOOLS.md Token Efficiency

TARGET_FILE: /home/mleon/.openclaw/workspace/TOOLS.md
EVAL_COMMAND: bash /home/mleon/.openclaw/workspace/autoimprove/programs/tools-tokens/eval.sh
BASELINE_SCORE: auto
GOAL: Minimize tokens while keeping all tool references and critical info
CONSTRAINTS: Must preserve script names, skill names, and integration notes

## What to optimize

- Remove verbose explanations of what scripts do (file comments already document)
- Compress status emojis and metadata (e.g., "✅ Ready | ⏳ Pending" → "✅|⏳")
- Consolidate redundant sections
- Compress table formatting
- Remove "see X for details" when path is obvious

## What NOT to change

- Script names and paths
- Skill names
- Command syntax
- Critical flags/options
- Integration notes (env vars, accounts, etc.)
