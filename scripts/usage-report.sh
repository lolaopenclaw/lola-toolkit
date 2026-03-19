#!/bin/bash
# Usage report: aggregates model costs from session JSONL files
# Outputs JSON with monthly totals by model, yesterday's delta, and today's usage

set -euo pipefail

SESSIONS_DIR="$HOME/.openclaw/agents/main/sessions"

# Validate dependencies
for cmd in jq date; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "❌ Required: $cmd"; exit 1; }
done

# Validate directory exists
[ -d "$SESSIONS_DIR" ] || { echo "❌ SESSIONS_DIR not found: $SESSIONS_DIR"; exit 1; }

CURRENT_MONTH=$(date -u +%Y-%m)
YESTERDAY=$(date -u -d "yesterday" +%Y-%m-%d)
TODAY=$(date -u +%Y-%m-%d)

cat "$SESSIONS_DIR"/*.jsonl 2>/dev/null | \
  jq -c 'select(.message.usage.cost.total != null and (.timestamp | startswith("'"$CURRENT_MONTH"'"))) | {
    date: (.timestamp | split("T")[0]),
    model: .message.model,
    cost: .message.usage.cost.total,
    input: .message.usage.input,
    output: .message.usage.output
  }' 2>/dev/null | \
  jq -s '
    # Monthly totals by model
    (group_by(.model) | map({
      model: .[0].model,
      total_cost: (map(.cost) | add | . * 10000 | round / 10000),
      total_input: (map(.input) | add),
      total_output: (map(.output) | add),
      requests: length
    }) | sort_by(-.total_cost)) as $monthly |

    # Yesterday totals by model
    ([.[] | select(.date == "'"$YESTERDAY"'")] | group_by(.model) | map({
      model: .[0].model,
      cost: (map(.cost) | add | . * 10000 | round / 10000),
      input: (map(.input) | add),
      output: (map(.output) | add),
      requests: length
    }) | sort_by(-.cost)) as $yesterday |

    # Today totals by model
    ([.[] | select(.date == "'"$TODAY"'")] | group_by(.model) | map({
      model: .[0].model,
      cost: (map(.cost) | add | . * 10000 | round / 10000),
      input: (map(.input) | add),
      output: (map(.output) | add),
      requests: length
    }) | sort_by(-.cost)) as $today |

    # Grand totals
    {
      month: "'"$CURRENT_MONTH"'",
      yesterday: "'"$YESTERDAY"'",
      today: "'"$TODAY"'",
      monthly_total_cost: ($monthly | map(.total_cost) | add | . * 10000 | round / 10000),
      yesterday_total_cost: ($yesterday | map(.cost) | add // 0 | . * 10000 | round / 10000),
      today_total_cost: ($today | map(.cost) | add // 0 | . * 10000 | round / 10000),
      by_model_monthly: $monthly,
      by_model_yesterday: $yesterday,
      by_model_today: $today
    }
  ' 2>/dev/null
