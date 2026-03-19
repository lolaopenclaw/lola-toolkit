#!/bin/bash

# USER.md Token Efficiency Evaluator
# Measures: token count, clarity, and functional completeness

USER_FILE="/home/mleon/.openclaw/workspace/USER.md"

if [ ! -f "$USER_FILE" ]; then
  echo "❌ USER.md not found"
  exit 1
fi

# Count tokens (rough: ~4 chars per token)
TOKEN_COUNT=$(wc -c < "$USER_FILE")
ESTIMATED_TOKENS=$((TOKEN_COUNT / 4))

# Count key fields (must have at least these)
REQUIRED_FIELDS=("Name:" "Location:" "Timezone:" "Telegram:")
FOUND_FIELDS=0

for field in "${REQUIRED_FIELDS[@]}"; do
  if grep -q "$field" "$USER_FILE"; then
    ((FOUND_FIELDS++))
  fi
done

# Calculate penalty (if missing required fields)
PENALTY=0
if [ $FOUND_FIELDS -lt ${#REQUIRED_FIELDS[@]} ]; then
  PENALTY=$((PENALTY + 100 * (${#REQUIRED_FIELDS[@]} - FOUND_FIELDS)))
fi

# Final score
SCORE=$((ESTIMATED_TOKENS + PENALTY))

echo "=== USER.md Token Efficiency Report ==="
echo "Tokens: $ESTIMATED_TOKENS"
echo "Required Fields Found: $FOUND_FIELDS/${#REQUIRED_FIELDS[@]}"
echo "Penalty: $PENALTY"
echo "Score: $SCORE"
