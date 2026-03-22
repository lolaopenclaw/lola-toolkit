# Program: MEMORY.md Index Efficiency

TARGET_FILE: /home/mleon/.openclaw/workspace/MEMORY.md
EVAL_COMMAND: bash /home/mleon/.openclaw/workspace/autoimprove/programs/memory-index/eval.sh
BASELINE_SCORE: auto
GOAL: Minimize tokens while maintaining comprehensive index coverage
CONSTRAINTS: Must keep all critical memory references, no duplicate topics, entries should be concise

## What to optimize

- Remove duplicate topic entries
- Archive very old references to dated memory files
- Make entries more concise (< 500 chars per entry average)
- Consolidate related topics
- Remove obsolete references

## What NOT to change

- Critical system knowledge
- Recent important events/decisions
- Links to active projects
- Key preferences and patterns
