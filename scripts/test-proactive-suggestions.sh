#!/usr/bin/env bash
# test-proactive-suggestions.sh - Test script for proactive suggestions
# Created: 2026-03-24

set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
MEMORY="$WORKSPACE/memory"

echo "🧪 Testing Proactive Suggestions System"
echo "========================================"
echo ""

# Cleanup previous test
echo "1. Cleaning up previous test state..."
rm -f "$MEMORY/.proactive-suggestions-today.json"
rm -f "$MEMORY/.weather-cache.json"
rm -f "$MEMORY/.garmin-last-sync.json"
rm -f "$MEMORY/.finance-daily.json"
echo "   ✓ Done"
echo ""

# Create mock data
echo "2. Creating mock data..."

# Weather - rain
echo '{"current_condition":[{"temp_C":"15","precipMM":"10","windspeedKmph":"25"}]}' > "$MEMORY/.weather-cache.json"
echo "   ✓ Weather mock (rain + normal temp + normal wind)"

# Health - low sleep
echo '{"sleep":{"hours":5.5},"body_battery":25,"stress":75}' > "$MEMORY/.garmin-last-sync.json"
echo "   ✓ Health mock (low sleep + low battery + high stress)"

# Finance - high spending
echo '{"today":{"total":150},"last_update":"2026-03-01"}' > "$MEMORY/.finance-daily.json"
echo "   ✓ Finance mock (€150 today + old statement)"

echo ""

# Reset time to morning (mock HOUR variable)
echo "3. Testing morning run (8 AM)..."
echo "   This should trigger: weather, health, finance suggestions"
echo ""

# Note: We can't easily mock HOUR without editing the script
# So we'll test by running the script and checking output

cd "$WORKSPACE"
OUTPUT=$(./scripts/proactive-suggestions.sh 2>&1 || true)

echo "$OUTPUT"
echo ""

# Check state file
echo "4. Checking state file..."
if [[ -f "$MEMORY/.proactive-suggestions-today.json" ]]; then
    echo "   ✓ State file created"
    jq . "$MEMORY/.proactive-suggestions-today.json"
else
    echo "   ✗ State file NOT created"
fi
echo ""

# Check metrics
echo "5. Checking metrics..."
if [[ -f "$MEMORY/.proactive-metrics.jsonl" ]]; then
    echo "   ✓ Metrics file exists"
    echo "   Last 3 entries:"
    tail -3 "$MEMORY/.proactive-metrics.jsonl" | jq .
else
    echo "   ✗ Metrics file NOT created"
fi
echo ""

# Test deduplication
echo "6. Testing deduplication (running again)..."
OUTPUT2=$(./scripts/proactive-suggestions.sh 2>&1 || true)
echo "$OUTPUT2"
echo ""

# Count should be same
COUNT1=$(echo "$OUTPUT" | grep -c "^[[:space:]]*[🌦📅😴💰⏰🔧]" || true)
COUNT2=$(echo "$OUTPUT2" | grep -c "^[[:space:]]*[🌦📅😴💰⏰🔧]" || true)

if [[ $COUNT2 -eq 0 ]]; then
    echo "   ✓ Deduplication working (no new suggestions on second run)"
else
    echo "   ⚠️  Deduplication may have issues (got $COUNT2 suggestions on second run)"
fi
echo ""

# Cleanup
echo "7. Cleanup mock data? (y/n)"
read -r -n 1 REPLY
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f "$MEMORY/.weather-cache.json"
    rm -f "$MEMORY/.garmin-last-sync.json"
    rm -f "$MEMORY/.finance-daily.json"
    echo "   ✓ Mock data cleaned up"
    echo "   Note: State file (.proactive-suggestions-today.json) and metrics kept for inspection"
else
    echo "   → Mock data kept for manual inspection"
fi

echo ""
echo "✅ Test complete!"
echo ""
echo "💡 To manually reset state for next test:"
echo "   rm $MEMORY/.proactive-suggestions-today.json"
