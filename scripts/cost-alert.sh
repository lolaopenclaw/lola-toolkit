#!/bin/bash
# cost-alert.sh - Alert on high API costs
# Designed to be run from cron for daily cost monitoring

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USAGE_REPORT="$SCRIPT_DIR/usage-report.sh"

# Thresholds
WARN_THRESHOLD=10
CRITICAL_THRESHOLD=25

# Validate usage-report.sh exists
if [[ ! -x "$USAGE_REPORT" ]]; then
  echo "❌ usage-report.sh not found or not executable: $USAGE_REPORT"
  exit 2
fi

# Get today's costs
REPORT=$(bash "$USAGE_REPORT" --today --by-model 2>/dev/null)

if [[ -z "$REPORT" ]]; then
  echo "❌ Failed to get cost report"
  exit 2
fi

# Extract total cost
TOTAL_COST=$(echo "$REPORT" | jq -r '.total_cost // 0')

# Use bc for floating point comparison (or fallback to integer cents)
compare_cost() {
  local cost="$1"
  local threshold="$2"
  
  if command -v bc >/dev/null 2>&1; then
    result=$(echo "$cost > $threshold" | bc -l)
    [[ "$result" -eq 1 ]]
  else
    # Fallback: multiply by 100 for cents comparison
    cost_cents=$(printf "%.0f" "$(echo "$cost * 100" | bc 2>/dev/null || echo 0)")
    threshold_cents=$(printf "%.0f" "$(echo "$threshold * 100" | bc 2>/dev/null || echo 0)")
    [[ "$cost_cents" -gt "$threshold_cents" ]]
  fi
}

# Check thresholds
if compare_cost "$TOTAL_COST" "$CRITICAL_THRESHOLD"; then
  echo "🚨 CRITICAL: Today's API costs are \$$TOTAL_COST (threshold: \$$CRITICAL_THRESHOLD)"
  echo ""
  echo "Breakdown by model:"
  echo "$REPORT" | jq -r '.by_model[] | "  • \(.model): $\(.cost) (\(.requests) requests)"'
  echo ""
  echo "Consider:"
  echo "  - Switch to cheaper models for routine tasks"
  echo "  - Review active cron jobs"
  echo "  - Check for runaway subagent loops"
  exit 1
  
elif compare_cost "$TOTAL_COST" "$WARN_THRESHOLD"; then
  echo "⚠️  WARNING: Today's API costs are \$$TOTAL_COST (threshold: \$$WARN_THRESHOLD)"
  echo ""
  echo "Breakdown by model:"
  echo "$REPORT" | jq -r '.by_model[] | "  • \(.model): $\(.cost) (\(.requests) requests)"'
  echo ""
  echo "Monitor for further increases."
  exit 0
  
else
  echo "✅ COST_OK: Today's spend is \$$TOTAL_COST (under \$$WARN_THRESHOLD threshold)"
  echo ""
  echo "Top models:"
  echo "$REPORT" | jq -r '.by_model[0:3][] | "  • \(.model): $\(.cost)"'
  exit 0
fi
