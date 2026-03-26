#!/bin/bash
set -euo pipefail

# 🛡️ Unified Healthcheck Script
# Consolidates 6 separate health/security crons into 1 dashboard
# 
# Usage: bash scripts/healthcheck-unified.sh [--target security|system|config|all] [--quick]
#   --quick: only fail2ban + config-drift (~30 seconds)
#   --target all: everything (~2-3 minutes)
#   --target security: security checks only
#   --target system: system checks only
#   --target config: config checks only

REPORT_DIR="$HOME/.openclaw/workspace/memory/healthcheck"
DATE=$(date +%Y-%m-%d)
DATETIME=$(date +"%Y-%m-%d %H:%M:%S")
REPORT_FILE="$REPORT_DIR/$DATE.md"

# Parse arguments
TARGET="all"
QUICK_MODE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --target)
      TARGET="$2"
      shift 2
      ;;
    --quick)
      QUICK_MODE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--target security|system|config|all] [--quick]"
      exit 1
      ;;
  esac
done

# Quick mode overrides target
if [ "$QUICK_MODE" = true ]; then
  TARGET="quick"
fi

# Create report directory
mkdir -p "$REPORT_DIR"

# Initialize report
cat > "$REPORT_FILE" << EOF
# 🛡️ Healthcheck Report — $DATE

Generated: $DATETIME
Mode: $([ "$QUICK_MODE" = true ] && echo "QUICK" || echo "$TARGET")

---

EOF

# Status tracking
ISSUES_FOUND=false

# ===========================
# SECURITY CHECKS
# ===========================
if [[ "$TARGET" == "all" || "$TARGET" == "security" ]]; then
  echo "## Security" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  
  # 1. fail2ban status
  echo "### SSH Intrusion Attempts (fail2ban)" >> "$REPORT_FILE"
  if command -v fail2ban-client &> /dev/null; then
    BANNED_COUNT=$(sudo fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $NF}' || echo "0")
    TOTAL_BANNED=$(sudo fail2ban-client status sshd 2>/dev/null | grep "Total banned" | awk '{print $NF}' || echo "0")
    TOTAL_FAILED=$(sudo fail2ban-client status sshd 2>/dev/null | grep "Currently failed" | awk '{print $NF}' || echo "0")
    
    echo "- **Currently banned IPs:** $BANNED_COUNT" >> "$REPORT_FILE"
    echo "- **Total banned (lifetime):** $TOTAL_BANNED" >> "$REPORT_FILE"
    echo "- **Current failed attempts:** $TOTAL_FAILED" >> "$REPORT_FILE"
    
    if [ "$BANNED_COUNT" -ge 10 ]; then
      echo "- **⚠️ ALERT HIGH:** ≥10 IPs currently banned" >> "$REPORT_FILE"
      ISSUES_FOUND=true
    elif [ "$BANNED_COUNT" -ge 5 ]; then
      echo "- **ℹ️ INFO:** $BANNED_COUNT IPs banned (monitoring)" >> "$REPORT_FILE"
    else
      echo "- **✅ Status:** Normal activity" >> "$REPORT_FILE"
    fi
  else
    echo "- **⚠️ fail2ban not installed**" >> "$REPORT_FILE"
    ISSUES_FOUND=true
  fi
  echo "" >> "$REPORT_FILE"
  
  # 2. rkhunter scan (weekly only)
  if [[ "$TARGET" == "all" ]]; then
    echo "### Rootkit Detection (rkhunter)" >> "$REPORT_FILE"
    if command -v rkhunter &> /dev/null; then
      # Run scan silently
      sudo rkhunter --check --skip-keypress --report-warnings-only > /tmp/rkhunter-output.txt 2>&1 || true
      
      # Count only serious warnings (exclude "file properties changed" which are common)
      SERIOUS_WARNINGS=$(grep -iE "(rootkit|trojan|suspicious|malware)" /tmp/rkhunter-output.txt | wc -l || echo "0")
      PROPERTY_WARNINGS=$(grep -i "properties have changed" /tmp/rkhunter-output.txt | wc -l || echo "0")
      
      if [ "$SERIOUS_WARNINGS" -gt 0 ]; then
        echo "- **⚠️ SERIOUS WARNINGS:** $SERIOUS_WARNINGS" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        grep -iE "(rootkit|trojan|suspicious|malware)" /tmp/rkhunter-output.txt | head -10 >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        ISSUES_FOUND=true
      elif [ "$PROPERTY_WARNINGS" -gt 0 ]; then
        echo "- **ℹ️ File property changes:** $PROPERTY_WARNINGS (normal after updates)" >> "$REPORT_FILE"
        echo "- **✅ Status:** CLEAN (no rootkits detected)" >> "$REPORT_FILE"
      else
        echo "- **✅ Status:** CLEAN (no rootkits detected)" >> "$REPORT_FILE"
      fi
      
      rm -f /tmp/rkhunter-output.txt
    else
      echo "- **⚠️ rkhunter not installed**" >> "$REPORT_FILE"
      ISSUES_FOUND=true
    fi
    echo "" >> "$REPORT_FILE"
    
    # 3. lynis scan (weekly only)
    echo "### System Hardening Audit (lynis)" >> "$REPORT_FILE"
    if command -v lynis &> /dev/null; then
      # Run audit
      sudo lynis audit system --quick --quiet > /dev/null 2>&1 || true
      
      if [ -f /var/log/lynis-report.dat ]; then
        HARDENING=$(grep "hardening_index=" /var/log/lynis-report.dat | cut -d'=' -f2 || echo "N/A")
        WARNINGS=$(grep -c "warning\[\]=" /var/log/lynis-report.dat || echo "0")
        SUGGESTIONS=$(grep -c "suggestion\[\]=" /var/log/lynis-report.dat || echo "0")
        
        echo "- **Hardening Index:** $HARDENING/100" >> "$REPORT_FILE"
        echo "- **Warnings:** $WARNINGS" >> "$REPORT_FILE"
        echo "- **Suggestions:** $SUGGESTIONS" >> "$REPORT_FILE"
        
        # Compare with baseline if exists
        BASELINE_FILE="$HOME/.openclaw/workspace/memory/2026-02-20-lynis-initial-scan.md"
        if [ -f "$BASELINE_FILE" ]; then
          BASELINE_HARDENING=$(grep "Hardening:" "$BASELINE_FILE" | grep -oE '[0-9]+' | head -1 || echo "0")
          if [ -n "$HARDENING" ] && [ "$HARDENING" != "N/A" ] && [ -n "$BASELINE_HARDENING" ]; then
            DELTA=$((HARDENING - BASELINE_HARDENING))
            if [ $DELTA -lt -5 ]; then
              echo "- **⚠️ ALERT:** Hardening dropped by ${DELTA#-} points vs baseline" >> "$REPORT_FILE"
              ISSUES_FOUND=true
            else
              echo "- **Change vs baseline:** ${DELTA:+"+"}$DELTA points" >> "$REPORT_FILE"
            fi
          fi
        fi
        
        if [ "$WARNINGS" -gt 0 ]; then
          echo "- **⚠️ Review warnings in /var/log/lynis-report.dat**" >> "$REPORT_FILE"
        else
          echo "- **✅ Status:** No warnings" >> "$REPORT_FILE"
        fi
      else
        echo "- **⚠️ lynis report not found**" >> "$REPORT_FILE"
        ISSUES_FOUND=true
      fi
    else
      echo "- **⚠️ lynis not installed**" >> "$REPORT_FILE"
      ISSUES_FOUND=true
    fi
    echo "" >> "$REPORT_FILE"
  fi
  
  echo "" >> "$REPORT_FILE"
fi

# ===========================
# SYSTEM CHECKS
# ===========================
if [[ "$TARGET" == "all" || "$TARGET" == "system" ]]; then
  echo "## System" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  
  # 1. Disk usage
  echo "### Disk Usage" >> "$REPORT_FILE"
  DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
  DISK_AVAIL=$(df -h / | tail -1 | awk '{print $4}')
  echo "- **Root partition:** ${DISK_USAGE}% used (${DISK_AVAIL} available)" >> "$REPORT_FILE"
  
  if [ "$DISK_USAGE" -ge 90 ]; then
    echo "- **⚠️ ALERT CRITICAL:** Disk usage ≥90%!" >> "$REPORT_FILE"
    ISSUES_FOUND=true
  elif [ "$DISK_USAGE" -ge 80 ]; then
    echo "- **⚠️ WARNING:** Disk usage ≥80%" >> "$REPORT_FILE"
    ISSUES_FOUND=true
  else
    echo "- **✅ Status:** Normal" >> "$REPORT_FILE"
  fi
  echo "" >> "$REPORT_FILE"
  
  # 2. Memory usage
  echo "### Memory Usage" >> "$REPORT_FILE"
  MEM_TOTAL=$(free -h | grep "Mem:" | awk '{print $2}')
  MEM_USED=$(free -h | grep "Mem:" | awk '{print $3}')
  MEM_PERCENT=$(free | grep "Mem:" | awk '{printf "%.0f", $3/$2 * 100}')
  echo "- **Memory:** ${MEM_USED} / ${MEM_TOTAL} (${MEM_PERCENT}% used)" >> "$REPORT_FILE"
  
  if [ "$MEM_PERCENT" -ge 90 ]; then
    echo "- **⚠️ ALERT:** High memory usage (≥90%)" >> "$REPORT_FILE"
    ISSUES_FOUND=true
  else
    echo "- **✅ Status:** Normal" >> "$REPORT_FILE"
  fi
  echo "" >> "$REPORT_FILE"
  
  # 3. Load average
  echo "### Load Average" >> "$REPORT_FILE"
  LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//')
  LOAD_1MIN=$(echo "$LOAD_AVG" | awk -F',' '{print $1}' | sed 's/^[ \t]*//')
  CPU_CORES=$(nproc)
  echo "- **Load average:** $LOAD_AVG" >> "$REPORT_FILE"
  echo "- **CPU cores:** $CPU_CORES" >> "$REPORT_FILE"
  
  # Check if 1-min load exceeds CPU cores (high load)
  if (( $(echo "$LOAD_1MIN > $CPU_CORES" | bc -l) )); then
    echo "- **⚠️ WARNING:** 1-min load ($LOAD_1MIN) exceeds CPU cores ($CPU_CORES)" >> "$REPORT_FILE"
    ISSUES_FOUND=true
  else
    echo "- **✅ Status:** Normal" >> "$REPORT_FILE"
  fi
  echo "" >> "$REPORT_FILE"
  
  # 4. Pending updates
  echo "### System Updates" >> "$REPORT_FILE"
  if command -v apt &> /dev/null; then
    sudo apt update -qq 2>/dev/null || true
    TOTAL_UPDATES=$(apt list --upgradable 2>/dev/null | grep -v "Listing" | grep -v "^$" | wc -l || echo "0")
    SECURITY_UPDATES=$(apt list --upgradable 2>/dev/null | grep -i security | grep -v "^$" | wc -l || echo "0")
    
    echo "- **Total pending updates:** $TOTAL_UPDATES" >> "$REPORT_FILE"
    echo "- **Security updates:** $SECURITY_UPDATES" >> "$REPORT_FILE"
    
    if [ "$SECURITY_UPDATES" -gt 0 ]; then
      echo "- **⚠️ ACTION REQUIRED:** Security updates available" >> "$REPORT_FILE"
      ISSUES_FOUND=true
    elif [ "$TOTAL_UPDATES" -gt 20 ]; then
      echo "- **ℹ️ INFO:** Consider running system updates" >> "$REPORT_FILE"
    else
      echo "- **✅ Status:** Up to date" >> "$REPORT_FILE"
    fi
  else
    echo "- **ℹ️ apt not available (non-Debian system)**" >> "$REPORT_FILE"
  fi
  echo "" >> "$REPORT_FILE"
  
  echo "" >> "$REPORT_FILE"
fi

# ===========================
# CONFIG CHECKS
# ===========================
if [[ "$TARGET" == "all" || "$TARGET" == "config" || "$TARGET" == "quick" ]]; then
  echo "## Configuration" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  
  echo "### Config Drift Detection" >> "$REPORT_FILE"
  
  # Check if config-drift script exists
  if [ -f "$HOME/.openclaw/workspace/scripts/config-drift" ]; then
    # Run config-drift check
    DRIFT_OUTPUT=$(bash "$HOME/.openclaw/workspace/scripts/config-drift" check 2>&1 || true)
    
    if echo "$DRIFT_OUTPUT" | grep -q "DRIFT DETECTED"; then
      CHANGES_COUNT=$(echo "$DRIFT_OUTPUT" | grep -c "CHANGED:" || echo "0")
      echo "- **⚠️ DRIFT DETECTED:** $CHANGES_COUNT configuration changes" >> "$REPORT_FILE"
      echo "\`\`\`" >> "$REPORT_FILE"
      echo "$DRIFT_OUTPUT" | grep -E "(CHANGED|ADDED|REMOVED)" | head -10 >> "$REPORT_FILE"
      echo "\`\`\`" >> "$REPORT_FILE"
      ISSUES_FOUND=true
    else
      echo "- **✅ Status:** CLEAN (no configuration drift)" >> "$REPORT_FILE"
    fi
  else
    echo "- **ℹ️ config-drift script not found**" >> "$REPORT_FILE"
  fi
  
  echo "" >> "$REPORT_FILE"
fi

# ===========================
# FINAL STATUS
# ===========================
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
if [ "$ISSUES_FOUND" = true ]; then
  echo "**Status:** ⚠️ **ISSUES FOUND** — Review required" >> "$REPORT_FILE"
  EXIT_STATUS=1
else
  echo "**Status:** ✅ **HEALTHCHECK_OK** — All systems normal" >> "$REPORT_FILE"
  EXIT_STATUS=0
fi

# Output report path and summary
echo ""
echo "📄 Report saved to: $REPORT_FILE"
echo ""
if [ "$ISSUES_FOUND" = true ]; then
  echo "⚠️ ISSUES FOUND - Review the report"
  # Print summary of issues
  grep -E "⚠️|ALERT|WARNING" "$REPORT_FILE" | head -10
else
  echo "✅ HEALTHCHECK_OK - All systems normal"
fi

exit $EXIT_STATUS
