TARGET_FILE: /home/mleon/.openclaw/workspace/MEMORY.md
EVAL_COMMAND: bash /home/mleon/.openclaw/workspace/autoimprove/programs/memory-index/eval.sh
BASELINE_SCORE: auto
GOAL: Minimize token count while maintaining ALL operational data (URLs, ports, cron IDs, dashboard info, security protocols)
CONSTRAINTS: Must keep all URLs, port numbers, cron references, dashboard paths, and security lessons. Must remain a useful quick-reference index. Historical context and verbose explanations can be moved to dedicated memory files.

## Context

MEMORY.md is the long-term memory index. Loaded every main session (~2981 tokens).
It's an index that points to detailed files. Much of the content is verbose explanations
that could be compressed since the agent already knows the context from prior sessions.

## What to try

- Compress verbose sections into reference tables
- Remove explanatory text (keep facts only)
- Remove dates/timestamps that don't affect behavior
- Consolidate similar sections
- Use shorthand for known concepts
