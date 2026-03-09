TARGET_FILE: /home/mleon/.openclaw/workspace/HEARTBEAT.md
EVAL_COMMAND: bash /home/mleon/.openclaw/workspace/autoimprove/programs/heartbeat-efficiency/eval.sh
BASELINE_SCORE: auto
GOAL: Minimize token count of HEARTBEAT.md while maintaining ALL functionality (zero-notification-if-OK, all 10 checks, quiet hours, heartbeat mejorado section)
CONSTRAINTS: Must keep ALL 10 checks. Must keep zero-notification-if-OK policy. Must keep quiet hours rule. Must remain clearly readable. Must not lose any check logic or thresholds.

## Context

HEARTBEAT.md is read by the agent on every heartbeat (every 30 minutes).
It defines what to check and when to alert.
Current size: ~2.7KB, loaded into context every heartbeat.

Every token saved here saves tokens on EVERY heartbeat check (~48 times/day).

## What to try

- Remove redundant explanations (agent already knows what heartbeat means)
- Compress check descriptions to bullet points
- Remove markdown headers where not needed
- Use shorthand for thresholds (">15MB" instead of "Si >15 MB: alerta a Manu + ejecutar limpieza")
- Remove the "Resumen" section (duplicates the checks above)
- Combine similar checks
- Remove "Beneficio:" explanations
- Remove historical context (dates, decisions) that don't affect behavior
