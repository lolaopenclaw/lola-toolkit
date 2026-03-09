#!/bin/bash
set -euo pipefail
TARGET="/home/mleon/.openclaw/workspace/MEMORY.md"
CHARS=$(wc -c < "$TARGET")
TOKEN_EST=$((CHARS / 4))
PENALTY=0

# Must keep critical operational data
REQUIRED=(
    "VPS|Ubuntu"
    "OpenClaw.*v20|openclaw.*v20"
    "Tailscale|tailscale"
    "Dashboard|dashboard|LobsterBoard"
    "Backup|backup"
    "Puerto|port|18790"
    "Cron|cron"
    "GitHub|github"
    "Finanzas|finanzas|Sheet"
    "Garmin|garmin"
    "memory/core|memory/technical|memory/protocols"
    "Secretos|secrets|token"
    "Calendar|calendar"
    "ARQUITECTURA|confiabilidad|verificación"
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
