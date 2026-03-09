#!/bin/bash
# eval.sh — Evaluate AGENTS.md token efficiency
set -euo pipefail

TARGET="/home/mleon/.openclaw/workspace/AGENTS.md"
CHARS=$(wc -c < "$TARGET")
TOKEN_EST=$((CHARS / 4))
PENALTY=0

# Must have all critical sections
REQUIRED=(
    "Every Session"
    "Memory|memory|MEMORY"
    "Safety|safety"
    "GitHub.*Safety|GitHub.*Publishing"
    "Verificación|verification"
    "External.*Internal|Safe to do"
    "Group Chat|group chat"
    "Model Selection|Cost.*Aware"
    "Heartbeat|heartbeat"
    "Time Estimation|time.*estimation"
    "Notion|notion.*Ideas"
    "Correcciones|corrección"
    "Reinicios|reinicio"
    "Cambios Críticos|critical.*change"
)

for pattern in "${REQUIRED[@]}"; do
    if ! grep -qiE "$pattern" "$TARGET"; then
        PENALTY=$((PENALTY + 500))
        >&2 echo "❌ Missing: $pattern"
    fi
done

SCORE=$((TOKEN_EST + PENALTY))
>&2 echo "Chars: $CHARS | Tokens: $TOKEN_EST | Penalty: $PENALTY | Score: $SCORE"
echo "$SCORE"
