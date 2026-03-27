#!/bin/bash
set -uo pipefail

MODE="${1:---quick}"  # --quick (daily) or --full (weekly)
REPORT=""
ISSUES=0

add_section() {
  local title="$1" content="$2" 
  REPORT+=$'\n'"## $title"$'\n'"$content"$'\n'
}

# Parallelize independent checks
{ f2b=$(sudo fail2ban-client status sshd 2>&1) || f2b="⚠️ fail2ban check FAILED"; } &
{ drift=$(python3 scripts/config-drift-detector.py check 2>&1 | tail -5) || drift="⚠️ config-drift check FAILED"; } &
{ disk=$(df -h / | tail -1 | awk '{print "Disk: "$5" used"}'); } &
{ mem=$(free -h | grep Mem | awk '{print "Memory: "$3"/"$2}'); } &
{ updates=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || true); } &
wait

# 1. Fail2ban
if [[ "$f2b" != *"fail2ban check FAILED"* ]]; then
  f2b=$(echo "$f2b" | grep -E "Currently banned|Total banned")
  [[ "$f2b" == *"Currently banned: 0"* ]] || ISSUES=$((ISSUES + 1))
else
  ISSUES=$((ISSUES+1))
fi
add_section "SSH Security" "$f2b"

# 2. Config drift
[[ "$drift" == *"no drift"* || "$drift" == *"CLEAN"* || "$drift" == *"config-drift check FAILED"* ]] || ISSUES=$((ISSUES + 1))
[[ "$drift" == *"config-drift check FAILED"* ]] && ISSUES=$((ISSUES+1))
add_section "Config Drift" "$drift"

# 3. System basics
disk_pct=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
[[ "$disk_pct" -lt 85 ]] || ISSUES=$((ISSUES + 1))
add_section "System" "$disk"$'\n'"$mem"$'\n'"Updates pending: $updates"

if [[ "$MODE" == "--full" ]]; then
  # 4. Security scanner (weekly only)
  { scanner=$(python3 scripts/security-scanner.py 2>&1 | tail -20) || scanner="⚠️ security-scanner FAILED"; } &
  # 5. Rkhunter (weekly only)  
  { rkhunter=$(sudo rkhunter --check --skip-keypress --report-warnings-only 2>&1 | head -20) || rkhunter="⚠️ rkhunter check FAILED"; } &
  wait
  
  [[ "$scanner" == *"FINDINGS"* || "$scanner" == *"warning"* || "$scanner" == *"error"* ]] && ISSUES=$((ISSUES + 1))
  [[ "$scanner" == *"security-scanner FAILED"* ]] && ISSUES=$((ISSUES+1))
  add_section "Security Scan" "$scanner"
  
  rkhunter_warnings=$(echo "$rkhunter" | grep -v "rkhunter check FAILED" | grep -E "Warning|Found" || true)
  [[ -z "$rkhunter_warnings" ]] || ISSUES=$((ISSUES + 1))
  [[ "$rkhunter" == *"rkhunter check FAILED"* ]] && ISSUES=$((ISSUES+1))
  add_section "Rootkit Scan" "$rkhunter"
fi

# Save report
mkdir -p memory/healthcheck
echo "$REPORT" > "memory/healthcheck/$(date +%Y-%m-%d).md"

# Output
if [[ $ISSUES -eq 0 ]]; then
  echo "HEALTHCHECK_OK"
else
  echo "$REPORT"
fi
