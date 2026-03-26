#!/bin/bash
# runtime-governance.sh - Runtime governance system for cost & loop protection
# Designed to run every 30 minutes via cron

set -euo pipefail

# Configuration
SESSIONS_DIR="$HOME/.openclaw/agents/main/sessions"
DATA_DIR="$HOME/.openclaw/workspace/data"
SCRIPT_DIR="$HOME/.openclaw/workspace/scripts"

# Thresholds
DAILY_WARNING=25
DAILY_HIGH=50
DAILY_CRITICAL=100
SESSION_MSG_THRESHOLD=200
TOTAL_CALLS_THRESHOLD=2000
LOOP_TOOL_THRESHOLD=10
LOOP_ERROR_THRESHOLD=5

# Status tracking
STATUS="GOVERNANCE_OK"
ALERTS=()

# Helper: Add alert
add_alert() {
  ALERTS+=("$1")
  if [[ "$2" == "CRITICAL" ]]; then
    STATUS="🚨 CRITICAL"
  elif [[ "$2" == "HIGH" ]] && [[ "$STATUS" != "🚨 CRITICAL" ]]; then
    STATUS="⚠️ WARNING"
  elif [[ "$2" == "WARNING" ]] && [[ "$STATUS" == "GOVERNANCE_OK" ]]; then
    STATUS="⚠️ WARNING"
  fi
}

# 1. Spending Check
check_spending() {
  # Get today's spend
  local today_result
  today_result=$(bash "$SCRIPT_DIR/usage-report.sh" --today 2>/dev/null || echo '{"total_cost": 0}')
  local today_cost
  today_cost=$(echo "$today_result" | jq -r '.total_cost // 0')
  
  # Get week average
  local week_result
  week_result=$(bash "$SCRIPT_DIR/usage-report.sh" --week 2>/dev/null || echo '{"total_cost": 0}')
  local week_cost
  week_cost=$(echo "$week_result" | jq -r '.total_cost // 0')
  local avg_daily
  avg_daily=$(echo "scale=2; $week_cost / 7" | bc -l 2>/dev/null || echo "0")
  
  # Check thresholds
  if (( $(echo "$today_cost >= $DAILY_CRITICAL" | bc -l 2>/dev/null || echo 0) )); then
    add_alert "💰 CRITICAL: Today's spend is \$$today_cost (threshold: \$$DAILY_CRITICAL). Consider emergency stop." "CRITICAL"
  elif (( $(echo "$today_cost >= $DAILY_HIGH" | bc -l 2>/dev/null || echo 0) )); then
    add_alert "💰 HIGH: Today's spend is \$$today_cost (threshold: \$$DAILY_HIGH)" "HIGH"
  elif (( $(echo "$today_cost >= $DAILY_WARNING" | bc -l 2>/dev/null || echo 0) )); then
    add_alert "💰 WARNING: Today's spend is \$$today_cost (threshold: \$$DAILY_WARNING)" "WARNING"
  fi
  
  # Check anomaly (>2x average)
  if (( $(echo "$avg_daily > 0 && $today_cost > ($avg_daily * 2)" | bc -l 2>/dev/null || echo 0) )); then
    add_alert "📈 ANOMALY: Today's spend (\$$today_cost) is >2x the 7-day average (\$$avg_daily/day)" "HIGH"
  fi
  
  echo "💰 Spending: \$$today_cost today (avg \$$avg_daily/day)"
}

# 2. Loop Detection (from gateway logs)
check_loops() {
  local loops_detected=false
  
  # Read last 100 lines of gateway logs
  if ! systemctl --user is-active --quiet openclaw-gateway 2>/dev/null; then
    echo "🔄 Loops: Gateway not running (skipping loop detection)"
    return
  fi
  
  local logs
  logs=$(journalctl --user -u openclaw-gateway --no-pager -n 100 --since "5 minutes ago" 2>/dev/null || echo "")
  
  if [[ -z "$logs" ]]; then
    echo "🔄 Loops: No recent logs available"
    return
  fi
  
  # Pattern 1: Same tool called >10 times in 5 minutes
  local tool_counts
  tool_counts=$(echo "$logs" | grep -oP 'tool:\s*\K\w+' 2>/dev/null | sort | uniq -c | sort -rn || echo "")
  if [[ -n "$tool_counts" ]]; then
    while read -r count tool; do
      if [[ "$count" -gt "$LOOP_TOOL_THRESHOLD" ]]; then
        add_alert "🔄 LOOP: Tool '$tool' called $count times in 5 minutes (threshold: $LOOP_TOOL_THRESHOLD)" "HIGH"
        loops_detected=true
      fi
    done <<< "$tool_counts"
  fi
  
  # Pattern 2: Same error message repeated >5 times
  local error_counts
  error_counts=$(echo "$logs" | grep -i "error" | sort | uniq -c | sort -rn | head -5 || echo "")
  if [[ -n "$error_counts" ]]; then
    while read -r count error_line; do
      if [[ "$count" -gt "$LOOP_ERROR_THRESHOLD" ]]; then
        local error_preview
        error_preview=$(echo "$error_line" | head -c 80)
        add_alert "🔄 LOOP: Error repeated $count times: ${error_preview}..." "HIGH"
        loops_detected=true
      fi
    done <<< "$error_counts"
  fi
  
  if $loops_detected; then
    echo "🔄 Loops: ⚠️ Potential loops detected (see alerts above)"
  else
    echo "🔄 Loops: None detected"
  fi
}

# 3. Session Rate Limiting Check
check_session_volume() {
  local today
  today=$(date +%Y-%m-%d)
  local total_calls=0
  local max_session_msgs=0
  local max_session_name=""
  local max_session_cost=0
  
  # Analyze today's JSONL files
  for file in "$SESSIONS_DIR"/*.jsonl; do
    [ -f "$file" ] || continue
    
    local session_name
    session_name=$(basename "$file" .jsonl)
    
    # Count messages from today
    local msg_count
    msg_count=$(jq -c "select(.timestamp | startswith(\"$today\"))" "$file" 2>/dev/null | wc -l || echo 0)
    total_calls=$((total_calls + msg_count))
    
    # Track session with most messages
    if [[ "$msg_count" -gt "$max_session_msgs" ]]; then
      max_session_msgs=$msg_count
      max_session_name=$session_name
      
      # Get cost for this session today
      max_session_cost=$(jq -s --arg today "$today" \
        'map(select(.timestamp | startswith($today)) | select(.message.usage.cost.total != null) | .message.usage.cost.total) | add // 0' \
        "$file" 2>/dev/null || echo 0)
    fi
    
    # Check per-session threshold
    if [[ "$msg_count" -gt "$SESSION_MSG_THRESHOLD" ]]; then
      add_alert "📊 HIGH VOLUME: Session '$session_name' has $msg_count messages today (threshold: $SESSION_MSG_THRESHOLD)" "HIGH"
    fi
  done
  
  # Check total volume
  if [[ "$total_calls" -gt "$TOTAL_CALLS_THRESHOLD" ]]; then
    add_alert "📊 HIGH VOLUME: Total $total_calls API calls today (threshold: $TOTAL_CALLS_THRESHOLD)" "WARNING"
  fi
  
  echo "📊 Volume: $total_calls API calls today (avg ~$(( total_calls / 24 ))/hour)"
  
  if [[ "$max_session_msgs" -gt 0 ]]; then
    echo "🔥 Sessions: Top consumer: $max_session_name ($max_session_msgs msgs, \$$max_session_cost)"
  else
    echo "🔥 Sessions: No active sessions today"
  fi
}

# Main execution
main() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M')
  
  echo "🛡️ Runtime Governance Check — $timestamp"
  echo ""
  
  # Run checks
  check_spending
  check_loops
  check_session_volume
  
  echo ""
  
  # Print alerts if any
  if [[ "${#ALERTS[@]}" -gt 0 ]]; then
    echo "⚠️ ALERTS:"
    for alert in "${ALERTS[@]}"; do
      echo "  • $alert"
    done
    echo ""
  fi
  
  # Final status
  echo "Status: $STATUS"
  
  # Log to file for history
  mkdir -p "$DATA_DIR"
  {
    echo "[$timestamp] $STATUS"
    if [[ "${#ALERTS[@]}" -gt 0 ]]; then
      for alert in "${ALERTS[@]}"; do
        echo "  $alert"
      done
    fi
  } >> "$DATA_DIR/runtime-governance.log"
  
  # Exit code: 0 for OK/WARNING, 1 for CRITICAL
  if [[ "$STATUS" == "🚨 CRITICAL" ]]; then
    exit 1
  fi
  
  exit 0
}

# Run
main
