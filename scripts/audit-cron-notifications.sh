#!/bin/bash
# audit-cron-notifications.sh
# Audita configuración de notificaciones en scripts y crons
# Verifica: quiet hours, routing correcto, targets hardcoded

set -euo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
REPORT_FILE="$WORKSPACE/memory/cron-notifications-audit-$(date +%Y%m%d-%H%M%S).md"

# ANSI colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
print_header() { echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${CYAN}$1${NC}"; echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }
print_section() { echo -e "${BLUE}$1${NC}"; }
print_file() { echo -e "📄 ${BLUE}$1${NC}"; }
print_issue() { echo -e "${RED}⚠️  $1${NC}"; }
print_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_ok() { echo -e "${GREEN}✅ $1${NC}"; }

echo ""
print_header "🔍 CRON NOTIFICATIONS AUDIT"
echo ""

# Generate report header
cat > "$REPORT_FILE" << HEADER
# Cron Notifications Audit Report

**Date:** $(date +%Y-%m-%d\ %H:%M:%S)
**Scope:** All scripts + cron jobs

---

## Executive Summary

This audit checks:
1. ✅ Quiet hours compliance (00:00-07:00 Madrid)
2. ✅ Correct routing (topics vs personal chat)
3. ✅ Hardcoded targets (should use topics, not 6884477)
4. ✅ NO_REPLY handling
5. ✅ Message send patterns

---

## Detailed Findings

HEADER

# Counters
TOTAL_SCRIPTS=0
ISSUES=0
CRITICAL_ISSUES=0

##############################################################################
# PART 1: SCAN ALL SCRIPTS FOR NOTIFICATION PATTERNS
##############################################################################

print_section "📂 Part 1: Scanning Scripts"
echo ""

cat >> "$REPORT_FILE" << 'SCRIPTHEADER'
### Scripts Analysis

SCRIPTHEADER

# Find all shell scripts
find "$WORKSPACE/scripts" -name "*.sh" -type f 2>/dev/null | sort | while IFS= read -r script; do
    BASENAME=$(basename "$script")
    TOTAL_SCRIPTS=$((TOTAL_SCRIPTS + 1))
    
    print_header ""
    print_file "$BASENAME"
    
    # Write to report
    cat >> "$REPORT_FILE" << SCRIPTHEAD

#### \`$BASENAME\`

SCRIPTHEAD
    
    HAS_ISSUES=false
    SCRIPT_ISSUES=()
    
    # Check 1: Hardcoded personal chat (6884477)
    if grep -q "6884477" "$script" 2>/dev/null; then
        HAS_ISSUES=true
        ISSUES=$((ISSUES + 1))
        echo -e "   ${RED}❌ Hardcoded personal chat target (6884477)${NC}"
        SCRIPT_ISSUES+=("hardcoded_personal")
        
        # Show exact lines
        grep -n "6884477" "$script" | head -3 | while IFS=: read -r line_num line_content; do
            echo -e "      ${YELLOW}Line $line_num:${NC} ${line_content:0:80}"
        done
        
        echo "- ❌ **Hardcoded personal chat target (\`6884477\`)**" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        grep -n "6884477" "$script" | head -3 >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
    else
        echo -e "   ${GREEN}✅ No hardcoded personal chat${NC}"
        echo "- ✅ No hardcoded personal chat target" >> "$REPORT_FILE"
    fi
    
    # Check 2: Telegram message send calls
    TELEGRAM_CALLS=$(grep -n "openclaw message send\|message.*--target\|telegram.*send" "$script" 2>/dev/null || true)
    if [ -n "$TELEGRAM_CALLS" ]; then
        echo -e "   ${YELLOW}📤 Telegram message send calls found:${NC}"
        
        echo "$TELEGRAM_CALLS" | while IFS=: read -r line_num line_content; do
            echo "      Line $line_num"
            
            # Check if uses topic
            if echo "$line_content" | grep -q "\-\-topic"; then
                echo -e "         ${GREEN}✅ Uses topic routing${NC}"
            else
                echo -e "         ${YELLOW}⚠️  No topic routing (direct target)${NC}"
                if [ "$HAS_ISSUES" = false ]; then
                    HAS_ISSUES=true
                    ISSUES=$((ISSUES + 1))
                fi
            fi
        done
        
        echo "- 📤 **Telegram message calls:**" >> "$REPORT_FILE"
        echo "\`\`\`bash" >> "$REPORT_FILE"
        echo "$TELEGRAM_CALLS" | head -5 >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
    fi
    
    # Check 3: Quiet hours awareness
    if grep -qE "(quiet.*hour|QUIET|00:00.*07:00|check.*hour|HOUR.*\=)" "$script" 2>/dev/null; then
        echo -e "   ${GREEN}✅ Has quiet hours logic${NC}"
        echo "- ✅ Has quiet hours awareness" >> "$REPORT_FILE"
    else
        # Only flag as issue if it sends Telegram messages
        if [ -n "$TELEGRAM_CALLS" ]; then
            echo -e "   ${YELLOW}⚠️  No quiet hours check (but sends messages)${NC}"
            echo "- ⚠️ No quiet hours check (sends messages without time check)" >> "$REPORT_FILE"
            if [ "$HAS_ISSUES" = false ]; then
                HAS_ISSUES=true
                ISSUES=$((ISSUES + 1))
            fi
        else
            echo -e "   ${GREEN}✅ Silent script (no notifications)${NC}"
            echo "- ✅ Silent script (no notifications)" >> "$REPORT_FILE"
        fi
    fi
    
    # Check 4: NO_REPLY usage
    if grep -q "NO_REPLY" "$script" 2>/dev/null; then
        echo -e "   ${BLUE}ℹ️  Uses NO_REPLY${NC}"
        echo "- ℹ️ Uses \`NO_REPLY\` mechanism" >> "$REPORT_FILE"
    fi
    
    # Check 5: Identify likely night scripts by name
    IS_NIGHT_SCRIPT=false
    if echo "$BASENAME" | grep -qE "(nightly|night|02|03|04|01am|backup|autoimprove|security-review)"; then
        IS_NIGHT_SCRIPT=true
        echo -e "   ${YELLOW}🌙 Likely night script (by name)${NC}"
        echo "- 🌙 **Likely night script** (by name pattern)" >> "$REPORT_FILE"
        
        # If night script + hardcoded personal + no quiet hours = CRITICAL
        if [[ " ${SCRIPT_ISSUES[*]} " =~ " hardcoded_personal " ]] && ! grep -qE "(quiet.*hour|QUIET)" "$script" 2>/dev/null; then
            CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
            echo -e "   ${RED}🚨 CRITICAL: Night script + personal chat + no quiet hours check${NC}"
            echo "- 🚨 **CRITICAL:** Night script with personal chat target and no quiet hours check" >> "$REPORT_FILE"
        fi
    fi
    
    echo ""
done

##############################################################################
# PART 2: LIST CRON JOBS AND THEIR SCHEDULES
##############################################################################

echo ""
echo -e "${BLUE}📅 Part 2: Cron Jobs Schedule Analysis${NC}"
echo ""

cat >> "$REPORT_FILE" << 'CRONHEAD'

---

### Cron Jobs Schedule

CRONHEAD

CRON_OUTPUT=$(openclaw cron list 2>/dev/null || echo "")

if [ -z "$CRON_OUTPUT" ]; then
    echo -e "${RED}❌ Could not fetch cron list${NC}"
    echo "**Error:** Could not fetch cron list from \`openclaw cron list\`" >> "$REPORT_FILE"
else
    echo "$CRON_OUTPUT" | tail -n +2 | while IFS= read -r line; do
        [ -z "$line" ] && continue
        
        # Extract ID and schedule (columns 1 and 3)
        CRON_ID=$(echo "$line" | awk '{print $1}')
        CRON_SCHEDULE=$(echo "$line" | awk '{for(i=3;i<=NF;i++) if ($i ~ /cron|every/) {for(j=i;j<=i+6;j++) printf "%s ", $j; break}}')
        
        # Clean up schedule (remove "..." and extra spaces)
        CRON_SCHEDULE=$(echo "$CRON_SCHEDULE" | sed 's/\.\.\..*//g' | xargs)
        
        # Determine if night cron (00:00-06:59)
        IS_NIGHT=false
        if echo "$CRON_SCHEDULE" | grep -qE "cron [0-6] [0-6] \*|cron [0-9]+ [0-6] \*"; then
            IS_NIGHT=true
        fi
        
        # Extract hour from schedule
        HOUR=""
        if echo "$CRON_SCHEDULE" | grep -qE "cron [0-9]+ [0-9]+"; then
            HOUR=$(echo "$CRON_SCHEDULE" | grep -oE "cron [0-9]+ [0-9]+" | awk '{print $3}')
        fi
        
        # Print summary
        if [ "$IS_NIGHT" = true ]; then
            echo -e "   ${YELLOW}🌙 ID: ${CRON_ID:0:8}... | Schedule: $CRON_SCHEDULE${NC}"
            echo "- 🌙 \`${CRON_ID}\` — **NIGHT CRON** (\`$CRON_SCHEDULE\`)" >> "$REPORT_FILE"
        else
            echo -e "   ✅ ID: ${CRON_ID:0:8}... | Schedule: $CRON_SCHEDULE"
            echo "- ✅ \`${CRON_ID}\` — Day cron (\`$CRON_SCHEDULE\`)" >> "$REPORT_FILE"
        fi
    done
fi

##############################################################################
# PART 3: SPECIFIC HIGH-RISK SCRIPTS DEEP DIVE
##############################################################################

echo ""
echo -e "${BLUE}🎯 Part 3: High-Risk Scripts Deep Dive${NC}"
echo ""

cat >> "$REPORT_FILE" << 'HIGHRISK'

---

### High-Risk Scripts (Detailed Review)

Scripts that are known to run at night or send critical notifications:

HIGHRISK

HIGH_RISK_SCRIPTS=(
    "nightly-security-review.sh"
    "system-updates-nightly.sh"
    "backup-memory.sh"
    "autoimprove-trigger.sh"
    "log-review-matutino.sh"
    "morning-briefing.sh"
)

for script_name in "${HIGH_RISK_SCRIPTS[@]}"; do
    SCRIPT_PATH="$WORKSPACE/scripts/$script_name"
    
    if [ ! -f "$SCRIPT_PATH" ]; then
        echo -e "   ${YELLOW}⚠️  $script_name: Not found${NC}"
        echo "- ⚠️ \`$script_name\`: **Not found** (may have been renamed or removed)" >> "$REPORT_FILE"
        continue
    fi
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "🔍 ${BLUE}$script_name${NC}"
    
    cat >> "$REPORT_FILE" << SCRIPTDEEP

#### \`$script_name\`

SCRIPTDEEP
    
    # Check for personal chat target
    PERSONAL_CHAT=$(grep -n "6884477" "$SCRIPT_PATH" || true)
    if [ -n "$PERSONAL_CHAT" ]; then
        echo -e "   ${RED}❌ FOUND: Hardcoded personal chat (6884477)${NC}"
        echo "$PERSONAL_CHAT" | head -3 | while IFS=: read -r lnum lcontent; do
            echo -e "      Line $lnum: ${YELLOW}${lcontent:0:80}${NC}"
        done
        echo "- ❌ **Hardcoded personal chat:**" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        echo "$PERSONAL_CHAT" | head -3 >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        
        CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
    else
        echo -e "   ${GREEN}✅ No personal chat target${NC}"
        echo "- ✅ No personal chat target" >> "$REPORT_FILE"
    fi
    
    # Check for quiet hours logic
    QUIET_LOGIC=$(grep -n -E "(quiet|QUIET|00:00.*07:00)" "$SCRIPT_PATH" || true)
    if [ -n "$QUIET_LOGIC" ]; then
        echo -e "   ${GREEN}✅ Has quiet hours logic${NC}"
        echo "- ✅ Has quiet hours logic:" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        echo "$QUIET_LOGIC" | head -2 >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
    else
        echo -e "   ${RED}❌ NO quiet hours check${NC}"
        echo "- ❌ **NO quiet hours check**" >> "$REPORT_FILE"
    fi
    
    # Check for topic routing
    TOPIC_ROUTING=$(grep -n "\-\-topic" "$SCRIPT_PATH" || true)
    if [ -n "$TOPIC_ROUTING" ]; then
        echo -e "   ${GREEN}✅ Uses topic routing${NC}"
        echo "- ✅ Uses topic routing" >> "$REPORT_FILE"
    else
        echo -e "   ${YELLOW}⚠️  No topic routing found${NC}"
        echo "- ⚠️ No topic routing found" >> "$REPORT_FILE"
    fi
    
    echo ""
done

##############################################################################
# SUMMARY
##############################################################################

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 AUDIT SUMMARY${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Total scripts scanned: $TOTAL_SCRIPTS"
echo "Total issues: $ISSUES"
echo -e "${RED}Critical issues: $CRITICAL_ISSUES${NC}"
echo ""

cat >> "$REPORT_FILE" << SUMMARY

---

## Summary

| Metric | Count |
|--------|-------|
| Total scripts scanned | $TOTAL_SCRIPTS |
| Total issues | $ISSUES |
| **Critical issues** | **$CRITICAL_ISSUES** |

---

## Recommendations

### 🔴 Priority 1: Fix Critical Issues

SUMMARY

# List critical scripts
if [ "$CRITICAL_ISSUES" -gt 0 ]; then
    echo -e "${RED}🔴 Critical scripts requiring immediate fixes:${NC}" | tee -a "$REPORT_FILE"
    
    for script_name in "${HIGH_RISK_SCRIPTS[@]}"; do
        SCRIPT_PATH="$WORKSPACE/scripts/$script_name"
        [ ! -f "$SCRIPT_PATH" ] && continue
        
        if grep -q "6884477" "$SCRIPT_PATH" 2>/dev/null && ! grep -qE "(quiet|QUIET)" "$SCRIPT_PATH" 2>/dev/null; then
            echo "   - $script_name" | tee -a "$REPORT_FILE"
        fi
    done
    
    echo "" | tee -a "$REPORT_FILE"
    echo "**Action:** Replace \`--target 6884477\` with \`--target \"-1003768820594\" --topic <ID>\`" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
else
    echo -e "${GREEN}✅ No critical issues found${NC}" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << 'RECS'
### 🟡 Priority 2: Add Quiet Hours Checks

All scripts that send notifications during night hours (00:00-07:00) should check quiet hours:

```bash
# Check quiet hours (00:00-07:00 Madrid)
HOUR=$(TZ=Europe/Madrid date +%H)
if [ "$HOUR" -ge 0 ] && [ "$HOUR" -lt 7 ]; then
    # Only notify if CRITICAL
    [ "$SEVERITY" != "CRITICAL" ] && exit 0
fi
```

### 🟢 Priority 3: Standardize Topic Routing

All notification scripts should use topic routing:

| Script Type | Topic ID | Topic Name |
|-------------|----------|------------|
| Security findings | 29 | 🛡️ Seguridad & Audits |
| System updates | 25 | 🔧 Sistema & Logs |
| Backup/cron errors | 25 | 🔧 Sistema & Logs |
| Health/Garmin | 28 | 🏃 Salud & Garmin |
| Finance | 26 | 💰 Finanzas |
| Daily reports | 24 | 📊 Reportes Diarios |

**Example:**
```bash
openclaw message send \
    --channel telegram \
    --target "-1003768820594" \
    --topic 29 \
    --message "🚨 Security finding: ..."
```

---

## Next Steps

1. ✅ Apply fixes to critical scripts (replace personal chat with topic routing)
2. ✅ Add quiet hours checks to all night scripts
3. ✅ Create night notification protocol document
4. ✅ Update AGENTS.md to reference protocol
5. ✅ Re-run this audit after fixes

---

**Audit completed:** $(date +%Y-%m-%d\ %H:%M:%S)

RECS

echo ""
if [ "$CRITICAL_ISSUES" -gt 0 ]; then
    echo -e "${RED}🚨 $CRITICAL_ISSUES CRITICAL issues require immediate action${NC}"
elif [ "$ISSUES" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  $ISSUES issues found (no critical)${NC}"
else
    echo -e "${GREEN}✅ No issues found — all scripts configured correctly${NC}"
fi

echo ""
echo -e "📄 Full report saved: ${CYAN}$REPORT_FILE${NC}"
echo ""

exit 0
