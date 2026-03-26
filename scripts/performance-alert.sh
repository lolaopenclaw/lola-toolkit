#!/bin/bash
# Performance Alert — Quick performance check for cron
# Exits with status 0 if OK, 1 if WARNING, 2 if CRITICAL
# Usage: bash scripts/performance-alert.sh

set -euo pipefail

SESSIONS_DIR="$HOME/.openclaw/agents/main/sessions"
TIMEZONE="Europe/Madrid"

# Date ranges
TODAY=$(TZ="$TIMEZONE" date +%Y-%m-%d)
WEEK_AGO=$(TZ="$TIMEZONE" date -d "7 days ago" +%Y-%m-%d)

# Temp storage
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Extract metrics function
extract_metrics() {
  local file="$1"
  local session_id=$(basename "$file" .jsonl)
  
  local prev_ts=""
  local prev_role=""
  
  while IFS= read -r line; do
    if ! echo "$line" | jq -e '.type == "message" and .message.role != null' &>/dev/null; then
      continue
    fi
    
    local role=$(echo "$line" | jq -r '.message.role')
    local ts=$(echo "$line" | jq -r '.timestamp')
    
    if [[ "$role" == "user" ]]; then
      prev_ts="$ts"
      prev_role="user"
    elif [[ "$role" == "assistant" && "$prev_role" == "user" && -n "$prev_ts" ]]; then
      local model=$(echo "$line" | jq -r '.message.model // "unknown"')
      
      local user_epoch=$(date -d "$(echo "$prev_ts" | sed 's/\.[0-9]*Z$/Z/')" +%s 2>/dev/null || echo 0)
      local asst_epoch=$(date -d "$(echo "$ts" | sed 's/\.[0-9]*Z$/Z/')" +%s 2>/dev/null || echo 0)
      local latency=$((asst_epoch - user_epoch))
      
      if [[ $latency -ge 0 ]]; then
        echo "$latency|$model|$ts" >> "$TMPDIR/today.txt"
      fi
      
      prev_ts=""
      prev_role=""
    fi
  done < "$file"
}

# Find files for today
TODAY_TS=$(date -d "$TODAY" +%s)
TODAY_END_TS=$(date -d "$TODAY 23:59:59" +%s)

while IFS= read -r file; do
  FILE_TS=$(stat -c %Y "$file")
  if [[ $FILE_TS -ge $TODAY_TS && $FILE_TS -le $TODAY_END_TS ]]; then
    extract_metrics "$file" &
  fi
done < <(find "$SESSIONS_DIR" -name "*.jsonl" -type f 2>/dev/null)
wait

if [[ ! -f "$TMPDIR/today.txt" ]]; then
  echo "PERF_OK (no data today)"
  exit 0
fi

# Check 1: Any message > 120s → CRITICAL
CRITICAL_COUNT=$(awk -F'|' '$1 > 120 {count++} END {print count+0}' "$TMPDIR/today.txt")
if [[ $CRITICAL_COUNT -gt 0 ]]; then
  echo "⚠️ CRITICAL: $CRITICAL_COUNT message(s) took >120s today"
  awk -F'|' '$1 > 120 {print $0}' "$TMPDIR/today.txt" | sort -t'|' -k1 -nr | head -5 | \
    awk -F'|' '{
      ts = $3
      gsub(/.*T/, "", ts)
      gsub(/\..*/, "", ts)
      printf "  - %s %s %ds\n", ts, $2, $1
    }'
  exit 2
fi

# Check 2: >5 messages > 60s → HIGH
HIGH_COUNT=$(awk -F'|' '$1 > 60 {count++} END {print count+0}' "$TMPDIR/today.txt")
if [[ $HIGH_COUNT -gt 5 ]]; then
  echo "⚠️ WARNING: $HIGH_COUNT messages took >60s today (threshold: 5)"
  exit 1
fi

# Check 3: Avg latency today > 2x weekly average → WARNING
TODAY_AVG=$(awk -F'|' '{sum+=$1; count++} END {if (count>0) print sum/count; else print 0}' "$TMPDIR/today.txt")

# Extract week metrics
rm -f "$TMPDIR/today.txt"
WEEK_TS=$(date -d "$WEEK_AGO" +%s)

while IFS= read -r file; do
  FILE_TS=$(stat -c %Y "$file")
  if [[ $FILE_TS -ge $WEEK_TS && $FILE_TS -le $TODAY_END_TS ]]; then
    extract_metrics "$file" &
  fi
done < <(find "$SESSIONS_DIR" -name "*.jsonl" -type f 2>/dev/null)
wait

if [[ -f "$TMPDIR/today.txt" ]]; then
  WEEK_AVG=$(awk -F'|' '{sum+=$1; count++} END {if (count>0) print sum/count; else print 0}' "$TMPDIR/today.txt")
  THRESHOLD=$(echo "$WEEK_AVG * 2" | bc -l)
  
  if (( $(echo "$TODAY_AVG > $THRESHOLD" | bc -l) )); then
    printf "⚠️ WARNING: Today's avg latency (%.1fs) > 2x weekly avg (%.1fs)\n" "$TODAY_AVG" "$WEEK_AVG"
    exit 1
  fi
fi

printf "PERF_OK (avg: %.1fs)\n" "$TODAY_AVG"
exit 0
