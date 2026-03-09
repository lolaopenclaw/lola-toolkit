#!/bin/bash
# =============================================================================
# eval.sh — Evaluate HEARTBEAT.md token efficiency
# =============================================================================
# Score = estimated token count (lower = better)
# Penalty for missing required elements
# =============================================================================

set -euo pipefail

TARGET="/home/mleon/.openclaw/workspace/HEARTBEAT.md"

if [ ! -f "$TARGET" ]; then
    echo "99999"
    exit 0
fi

# --- Token count estimate (chars / 4 is a rough approximation) ---
CHARS=$(wc -c < "$TARGET")
TOKEN_EST=$((CHARS / 4))

# --- Completeness validation ---
PENALTY=0

# Must have zero-notification policy
if ! grep -qi "zero.*notification\|silencio.*total\|HEARTBEAT_OK" "$TARGET"; then
    PENALTY=$((PENALTY + 5000))
fi

# Must have all 10 checks (or at least references to them)
REQUIRED_CHECKS=(
    "cron"
    "gateway"
    "Notion|Kanban|kanban"
    "Gmail|gmail|Email|email"
    "Memory|memory"
    "sandbox|critical-sandbox"
    "synthesis|Session|session"
    "Garmin|garmin|health"
    "Calendar|calendar"
    "Fail2Ban|fail2ban|Fail2ban"
)

MISSING=0
for check in "${REQUIRED_CHECKS[@]}"; do
    if ! grep -qiE "$check" "$TARGET"; then
        MISSING=$((MISSING + 1))
        PENALTY=$((PENALTY + 1000))
    fi
done

# Must have quiet hours
if ! grep -qiE "silencioso|23:00.*07:00|quiet.*hour" "$TARGET"; then
    PENALTY=$((PENALTY + 2000))
fi

# Must have heartbeat mejorado (progress reporting during tasks)
if ! grep -qiE "mejorado|progreso|30.*minuto|tarea.*larga" "$TARGET"; then
    PENALTY=$((PENALTY + 1000))
fi

# --- Final score ---
SCORE=$((TOKEN_EST + PENALTY))

# Debug info to stderr
>&2 echo "Chars: $CHARS | Token est: $TOKEN_EST | Missing checks: $MISSING | Penalty: $PENALTY | Score: $SCORE"

echo "$SCORE"
