#!/bin/bash
set -o pipefail

MODE="${1:---quick}"  # --quick (daily) or --full (weekly)
REPORT=""
ISSUES=0

add_section() {
  local title="$1" content="$2" 
  REPORT+=$'\n'"## $title"$'\n'"$content"$'\n'
}

# 1. Fail2ban (SSH Security)
f2b_status=$(sudo fail2ban-client status sshd 2>&1 || echo "⚠️ fail2ban unavailable")
if [[ "$f2b_status" == *"Currently banned: 0"* ]]; then
  add_section "SSH Security" "✅ Fail2ban active, no bans"
else
  add_section "SSH Security" "$f2b_status"
  ISSUES=$((ISSUES + 1))
fi

# 2. System basics
disk_info=$(df -h / | tail -1)
disk_pct=$(echo "$disk_info" | awk '{print $5}' | tr -d '%')
disk_used=$(echo "$disk_info" | awk '{print $5}')
mem_info=$(free -h | grep Mem | awk '{print "RAM: "$3"/"$2}')
updates=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || echo "0")

if [[ "$disk_pct" -lt 85 ]]; then
  add_section "System" "Disk: $disk_used | $mem_info | Updates: $updates pending"
else
  add_section "System" "⚠️ Disk: $disk_used (HIGH) | $mem_info | Updates: $updates pending"
  ISSUES=$((ISSUES + 1))
fi

# 3. Gateway process check
if pgrep -f "gateway" > /dev/null 2>&1; then
  add_section "Gateway" "✅ Running"
else
  add_section "Gateway" "⚠️ Not running"
  ISSUES=$((ISSUES + 1))
fi

if [[ "$MODE" == "--full" ]]; then
  # 4. Network connectivity
  if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    add_section "Network" "✅ Online"
  else
    add_section "Network" "⚠️ Offline or unreachable"
    ISSUES=$((ISSUES + 1))
  fi
fi

# Save report
mkdir -p memory/healthcheck
echo "$REPORT" > "memory/healthcheck/$(date +%Y-%m-%d).md"

# Output
if [[ $ISSUES -eq 0 ]]; then
  echo "HEALTHCHECK_OK"
  exit 0
else
  echo "$REPORT"
  exit 1
fi
