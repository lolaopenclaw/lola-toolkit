#!/bin/bash
# =============================================================================
# eval.sh — Evaluate SOUL.md token efficiency & quality
# =============================================================================
# Score = estimated token count (lower = better)
# Penalty for missing required elements
# =============================================================================

set -euo pipefail

TARGET="/home/mleon/.openclaw/workspace/SOUL.md"

if [ ! -f "$TARGET" ]; then
    echo "99999"
    exit 0
fi

# --- Token count estimate (chars / 4 is a rough approximation) ---
CHARS=$(wc -c < "$TARGET")
TOKEN_EST=$((CHARS / 4))

# --- Completeness validation ---
PENALTY=0

# Must have Core Truths section
if ! grep -qi "Core Truth" "$TARGET"; then
    PENALTY=$((PENALTY + 2000))
fi

# Must have at least 4 core principles
TRUTH_COUNT=$(grep -c "^\-\*\*" "$TARGET" || true)
if [ "$TRUTH_COUNT" -lt 4 ]; then
    PENALTY=$((PENALTY + 1000))
fi

# Must have Boundaries section
if ! grep -qi "Boundaries" "$TARGET"; then
    PENALTY=$((PENALTY + 1500))
fi

# Must have Vibe section
if ! grep -qi "Vibe" "$TARGET"; then
    PENALTY=$((PENALTY + 1000))
fi

# Must have Continuity section
if ! grep -qi "Continuity" "$TARGET"; then
    PENALTY=$((PENALTY + 1000))
fi

# Must mention "memory" or "session" (continuity)
if ! grep -qiE "session|memory|read" "$TARGET"; then
    PENALTY=$((PENALTY + 500))
fi

# --- Final score ---
SCORE=$((TOKEN_EST + PENALTY))

# Debug info to stderr
>&2 echo "Chars: $CHARS | Token est: $TOKEN_EST | Penalty: $PENALTY | Score: $SCORE"

echo "$SCORE"
