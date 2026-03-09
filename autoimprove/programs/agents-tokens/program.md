TARGET_FILE: /home/mleon/.openclaw/workspace/AGENTS.md
EVAL_COMMAND: bash /home/mleon/.openclaw/workspace/autoimprove/programs/agents-tokens/eval.sh
BASELINE_SCORE: auto
GOAL: Minimize token count while maintaining ALL behavioral rules and protocols
CONSTRAINTS: Must keep ALL protocols (security, verification, GitHub safety, memory management, heartbeat, model selection, group chat, time estimation). Must remain clearly actionable. Must not lose any decision or lesson learned.

## Context

AGENTS.md is loaded into context on EVERY session start. It's the largest context file (4088 tokens).
Contains: session startup protocol, memory management, safety rules, communication preferences,
model selection, heartbeat behavior, and many learned lessons/protocols.

## What to try

- Move historical context/dates to memory files (don't need them in every session)
- Compress protocol descriptions (agent already knows the patterns)
- Remove duplicate information (things also in SOUL.md, USER.md, etc.)
- Convert verbose explanations to concise rules
- Remove examples where the rule is clear without them
- Group related rules instead of separate sections
