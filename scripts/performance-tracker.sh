#!/bin/bash
# Performance Tracker — Analyze response latency and degradation from OpenClaw session logs
# Usage: bash scripts/performance-tracker.sh [--today|--yesterday|--week|--session FILE|--slow SECONDS|--summary|--degradation]

set -euo pipefail

SESSIONS_DIR="$HOME/.openclaw/agents/main/sessions"
SLOW_THRESHOLD=30
MODE=""
SESSION_FILE=""
TIMEZONE="Europe/Madrid"

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --today) MODE="today"; shift ;;
    --yesterday) MODE="yesterday"; shift ;;
    --week) MODE="week"; shift ;;
    --session) SESSION_FILE="$2"; shift 2 ;;
    --slow) SLOW_THRESHOLD="$2"; shift 2 ;;
    --summary) MODE="summary"; shift ;;
    --degradation) MODE="degradation"; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Default to today if no mode set
[[ -z "$MODE" ]] && MODE="today"

# Determine date range
case "$MODE" in
  today)
    START_DATE=$(TZ="$TIMEZONE" date +%Y-%m-%d)
    END_DATE="$START_DATE"
    ;;
  yesterday)
    START_DATE=$(TZ="$TIMEZONE" date -d "yesterday" +%Y-%m-%d)
    END_DATE="$START_DATE"
    ;;
  week)
    START_DATE=$(TZ="$TIMEZONE" date -d "7 days ago" +%Y-%m-%d)
    END_DATE=$(TZ="$TIMEZONE" date +%Y-%m-%d)
    ;;
  summary|degradation)
    START_DATE=$(TZ="$TIMEZONE" date -d "7 days ago" +%Y-%m-%d)
    END_DATE=$(TZ="$TIMEZONE" date +%Y-%m-%d)
    ;;
esac

# Build file list
if [[ -n "$SESSION_FILE" ]]; then
  FILES=("$SESSION_FILE")
else
  # Find sessions modified within date range
  START_TS=$(date -d "$START_DATE" +%s)
  END_TS=$(date -d "$END_DATE 23:59:59" +%s)
  
  FILES=()
  # Include both .jsonl and .jsonl.gz files
  while IFS= read -r file; do
    FILE_TS=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || echo 0)
    if [[ $FILE_TS -ge $START_TS && $FILE_TS -le $END_TS ]]; then
      FILES+=("$file")
    fi
  done < <(find "$SESSIONS_DIR" \( -name "*.jsonl" -o -name "*.jsonl.gz" \) -type f)
fi

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "No session files found for the specified period."
  exit 0
fi

# Extract metrics
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

extract_metrics() {
  local file="$1"
  local session_id=$(basename "$file" .jsonl.gz)
  session_id=$(basename "$session_id" .jsonl)
  
  # Determine if file is compressed
  local cat_cmd="cat"
  if [[ "$file" == *.gz ]]; then
    cat_cmd="zcat"
  fi
  
  # Process line by line to avoid control char issues
  local prev_ts=""
  local prev_role=""
  
  while IFS= read -r line; do
    # Skip non-message lines
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
      local input_tokens=$(echo "$line" | jq -r '.message.usage.input // 0')
      local output_tokens=$(echo "$line" | jq -r '.message.usage.output // 0')
      local cost=$(echo "$line" | jq -r '.message.usage.cost.total // 0')
      local tool_calls=$(echo "$line" | jq '[.message.content[]? | select(.type == "toolCall")] | length' 2>/dev/null || echo 0)
      
      # Calculate latency (strip milliseconds)
      local user_epoch=$(date -d "$(echo "$prev_ts" | sed 's/\.[0-9]*Z$/Z/')" +%s 2>/dev/null || echo 0)
      local asst_epoch=$(date -d "$(echo "$ts" | sed 's/\.[0-9]*Z$/Z/')" +%s 2>/dev/null || echo 0)
      local latency=$((asst_epoch - user_epoch))
      
      if [[ $latency -ge 0 ]]; then
        echo "$session_id|$prev_ts|$ts|$latency|$model|$input_tokens|$output_tokens|$cost|$tool_calls" >> "$TMPDIR/metrics.txt"
      fi
      
      prev_ts=""
      prev_role=""
    fi
  done < <($cat_cmd "$file" 2>/dev/null)
}

# Process all files
for file in "${FILES[@]}"; do
  extract_metrics "$file" &
done
wait

if [[ ! -f "$TMPDIR/metrics.txt" ]]; then
  echo "No metrics extracted."
  exit 0
fi

# Mode: summary
if [[ "$MODE" == "summary" ]]; then
  echo "📊 Performance Report — $(TZ="$TIMEZONE" date +"%Y-%m-%d")"
  echo ""
  
  # Overall latency stats
  echo "Response Latency:"
  awk -F'|' '{print $4}' "$TMPDIR/metrics.txt" | sort -n | awk '
    {
      sum += $1
      latencies[NR] = $1
    }
    END {
      avg = sum / NR
      p50 = latencies[int(NR * 0.5)]
      p90 = latencies[int(NR * 0.9)]
      p99 = latencies[int(NR * 0.99)]
      printf "  avg: %.1fs | p50: %.1fs | p90: %.1fs | p99: %.1fs\n", avg, p50, p90, p99
    }
  '
  echo ""
  
  # By model
  echo "By Model:"
  awk -F'|' '{model=$5; latency=$4; count[model]++; sum[model]+=latency} END {
    for (m in count) {
      printf "  %-15s avg %.1fs (%d messages)\n", m":", sum[m]/count[m], count[m]
    }
  }' "$TMPDIR/metrics.txt" | sort -k3 -nr
  echo ""
  
  # By hour
  echo "By Hour:"
  awk -F'|' '{
    ts = $3
    gsub(/.*T/, "", ts)
    gsub(/:.*/, "", ts)
    hour = int(ts)
    latency = $4
    count[hour]++
    sum[hour] += latency
  } END {
    for (h in count) {
      avg[h] = sum[h] / count[h]
    }
    # Find min and max
    min_avg = 999999
    max_avg = 0
    for (h in avg) {
      if (avg[h] < min_avg) { min_avg = avg[h]; min_hour = h }
      if (avg[h] > max_avg) { max_avg = avg[h]; max_hour = h }
    }
    printf "  %02d:00-%02d:00: avg %.1fs (most responsive)\n", min_hour, (min_hour+1)%24, min_avg
    printf "  %02d:00-%02d:00: avg %.1fs (slowest)\n", max_hour, (max_hour+1)%24, max_avg
  }' "$TMPDIR/metrics.txt"
  echo ""
  
  # Context size correlation
  echo "Context Size Correlation:"
  awk -F'|' '{
    tokens = $6
    latency = $4
    if (tokens < 10000) bucket = "<10K tokens"
    else if (tokens < 50000) bucket = "10-50K"
    else if (tokens < 100000) bucket = "50-100K"
    else bucket = ">100K"
    count[bucket]++
    sum[bucket] += latency
  } END {
    order[0] = "<10K tokens"
    order[1] = "10-50K"
    order[2] = "50-100K"
    order[3] = ">100K"
    for (i = 0; i < 4; i++) {
      b = order[i]
      if (count[b] > 0)
        printf "  %-15s avg %.1fs\n", b":", sum[b]/count[b]
    }
  }' "$TMPDIR/metrics.txt"
  echo ""
  
  # Degradation warning
  echo "Degradation:"
  DEGRADATION=$(awk -F'|' 'BEGIN {session=""; count=0; sum=0}
    {
      if ($1 != session) {
        if (count >= 50 && sum/count > 30) print session
        session = $1
        count = 0
        sum = 0
      }
      count++
      if (count > 50) sum += $4
    }
    END {
      if (count >= 50 && sum/(count-50) > 30) print session
    }' "$TMPDIR/metrics.txt" | wc -l)
  
  if [[ $DEGRADATION -gt 0 ]]; then
    echo "  ⚠️ Detected: $DEGRADATION session(s) averaging >30s after 50+ messages"
  else
    echo "  ✅ None detected"
  fi
  echo ""
  
  # Slow messages
  SLOW_COUNT=$(awk -F'|' -v threshold="$SLOW_THRESHOLD" '$4 > threshold {count++} END {print count+0}' "$TMPDIR/metrics.txt")
  
  echo "Slow Messages (>${SLOW_THRESHOLD}s): $SLOW_COUNT found"
  if [[ $SLOW_COUNT -gt 0 ]]; then
    awk -F'|' -v threshold="$SLOW_THRESHOLD" '$4 > threshold {print $0}' "$TMPDIR/metrics.txt" | \
      sort -t'|' -k4 -nr | head -5 | \
      awk -F'|' '{
        ts = $3
        gsub(/.*T/, "", ts)
        gsub(/\..*/, "", ts)
        printf "  - %s %s %.1fs (context: %dK tokens)\n", ts, $5, $4, $6/1000
      }'
  fi
  
  exit 0
fi

# Mode: degradation
if [[ "$MODE" == "degradation" ]]; then
  echo "📉 Degradation Analysis"
  echo ""
  
  # Group by session and analyze buckets
  awk -F'|' '
    {
      session = $1
      latency = $4
      sessions[session] = sessions[session] " " latency
      count[session]++
    }
    END {
      for (s in sessions) {
        if (count[s] < 10) continue
        
        split(sessions[s], latencies, " ")
        
        # Calculate buckets
        b1_sum = 0; b1_count = 0
        b2_sum = 0; b2_count = 0
        b3_sum = 0; b3_count = 0
        b4_sum = 0; b4_count = 0
        b5_sum = 0; b5_count = 0
        
        for (i = 2; i <= length(latencies); i++) {
          lat = latencies[i]
          if (i <= 10) { b1_sum += lat; b1_count++ }
          else if (i <= 20) { b2_sum += lat; b2_count++ }
          else if (i <= 30) { b3_sum += lat; b3_count++ }
          else if (i <= 50) { b4_sum += lat; b4_count++ }
          else { b5_sum += lat; b5_count++ }
        }
        
        if (b1_count > 0) {
          printf "Session: %s\n", s
          printf "  Messages 1-10:   avg %.1fs\n", b1_sum/b1_count
          
          if (b2_count > 0) {
            b2_avg = b2_sum/b2_count
            b1_avg = b1_sum/b1_count
            pct = (b2_avg - b1_avg) / b1_avg * 100
            printf "  Messages 11-20:  avg %.1fs (%+.0f%%)\n", b2_avg, pct
          }
          
          if (b3_count > 0) {
            b3_avg = b3_sum/b3_count
            b2_avg = b2_sum/b2_count
            pct = (b3_avg - b2_avg) / b2_avg * 100
            printf "  Messages 21-30:  avg %.1fs (%+.0f%%)\n", b3_avg, pct
          }
          
          if (b4_count > 0) {
            b4_avg = b4_sum/b4_count
            b3_avg = b3_sum/b3_count
            pct = (b4_avg - b3_avg) / b3_avg * 100
            printf "  Messages 31-50:  avg %.1fs (%+.0f%%)\n", b4_avg, pct
          }
          
          if (b5_count > 0) {
            b5_avg = b5_sum/b5_count
            b4_avg = b4_sum/b4_count
            pct = (b5_avg - b4_avg) / b4_avg * 100
            printf "  Messages 50+:    avg %.1fs (%+.0f%%)\n", b5_avg, pct
          }
          
          printf "\n"
        }
      }
    }
  ' "$TMPDIR/metrics.txt"
  
  exit 0
fi

# Default mode: show slow messages
echo "🐢 Slow Messages (>${SLOW_THRESHOLD}s)"
echo ""

awk -F'|' -v threshold="$SLOW_THRESHOLD" '$4 > threshold {print $0}' "$TMPDIR/metrics.txt" | \
  sort -t'|' -k4 -nr | \
  awk -F'|' '{
    gsub(/T/, " ", $3)
    gsub(/\..*/, "", $3)
    printf "Session: %s\n  Time: %s\n  Model: %s\n  Latency: %.1fs\n  Context: %dK tokens\n  Output: %d tokens\n  Tools: %d\n\n", 
      $1, $3, $5, $4, $6/1000, $7, $8
  }'
