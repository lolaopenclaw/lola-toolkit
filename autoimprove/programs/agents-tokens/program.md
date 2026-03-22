# Program: AGENTS.md Token Efficiency

TARGET_FILE: /home/mleon/.openclaw/workspace/AGENTS.md
EVAL_COMMAND: bash /home/mleon/.openclaw/workspace/autoimprove/programs/agents-tokens/eval.sh
BASELINE_SCORE: auto
GOAL: Minimize tokens while keeping all essential instructions
CONSTRAINTS: Must preserve "Every Session" checklist, Memory section, and all critical file references

## What to optimize

- Remove redundant info that's in USER.md or SOUL.md
- Compress verbose explanations
- Consolidate similar rules
- Remove examples that aren't needed
- Keep instructions concise and actionable

## What NOT to change

- Required file references (SOUL.md, USER.md, etc.)
- Session startup checklist
- Memory protocol
- Critical safety rules
