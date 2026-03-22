#!/bin/bash
# spawn-agents.sh
# 
# Multi-Agent Orchestration Helper
# 
# Purpose: Documents common agent spawning patterns and provides monitoring commands.
#          Lola can reference this for multi-agent workflows.
#
# Usage: bash scripts/spawn-agents.sh <pattern> [args...]
#
# Patterns:
#   help                  - Show this help
#   examples             - Show example spawns
#   monitor              - Monitor active agents
#   stats                - Show agent statistics
#
# Author: Builder Agent (Multi-Agent Architecture Setup)
# Created: 2026-03-22

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="/home/mleon/.openclaw/workspace"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Help
show_help() {
    cat << 'EOF'
🤝 Multi-Agent Orchestration Helper

PATTERNS:

1. Single Domain Analysis
   openclaw sessions spawn \
     --label surf-analysis \
     --instructions "$(cat agents/templates/domain-agent.md)" \
     --model haiku \
     "Analyze surf conditions for this weekend. Domain: surf. 
      Check: memory/surf/conditions-*.md, Garmin data, calendar. 
      Output: memory/surf/analysis-$(date +%Y-%m-%d)-weekend.md"

2. Multi-Domain (Parallel)
   # Spawn both in parallel, then synthesize
   openclaw sessions spawn --label surf-check --model haiku --instructions "..." "..."
   openclaw sessions spawn --label health-check --model haiku --instructions "..." "..."
   # Results auto-announce to main agent

3. Research + Build (Parallel)
   openclaw sessions spawn --label research-apis --model haiku --instructions "..." "..."
   openclaw sessions spawn --label build-pipeline --model sonnet --instructions "..." "..."

4. Build + Audit (Sequential)
   # Build first
   openclaw sessions spawn --label build-feature --model sonnet --instructions "..." "..."
   # Wait for completion (auto-announce)
   # Then audit
   openclaw sessions spawn --label audit-feature --model haiku --instructions "..." "..."

MONITORING:

  bash scripts/spawn-agents.sh monitor     # Active agents
  bash scripts/spawn-agents.sh stats       # Statistics

BEST PRACTICES:

✅ Always prefer parallel over sequential
✅ Main session stays free (never do heavy work)
✅ Max 5 concurrent agents (VPS limit)
✅ Use appropriate model (Haiku for most, Sonnet for complex)
✅ Push-based completion (don't poll)

EOF
}

# Show examples
show_examples() {
    cat << 'EOF'
📚 AGENT SPAWNING EXAMPLES

═══════════════════════════════════════════════════════════════

1️⃣  SURF ANALYSIS (Domain Agent)

openclaw sessions spawn \
  --label surf-weekend-check \
  --instructions "$(cat agents/templates/domain-agent.md)" \
  --model haiku \
  "Domain: surf
   Task: Should Manu surf this weekend?
   Check: memory/surf/conditions-2026-03-22.md (and latest), Garmin fatigue, calendar
   Output: memory/surf/analysis-2026-03-22-weekend.md
   Git commit before reporting."

═══════════════════════════════════════════════════════════════

2️⃣  HEALTH CHECK (Domain Agent)

openclaw sessions spawn \
  --label health-recovery-check \
  --instructions "$(cat agents/templates/domain-agent.md)" \
  --model haiku \
  "Domain: health
   Task: Is Manu ready for intense training today?
   Check: Garmin HRV, sleep, recent activity load, stress
   Output: memory/health/analysis-2026-03-22-training-readiness.md
   Git commit before reporting."

═══════════════════════════════════════════════════════════════

3️⃣  RESEARCH TASK (Research Agent)

openclaw sessions spawn \
  --label research-surf-coaching \
  --instructions "$(cat agents/templates/research-agent.md)" \
  --model haiku \
  "Research surf coaching methodologies.
   Find: progression frameworks, common mistakes, corrective exercises
   Create knowledge base in memory/surf/coaching/
   Cite all sources with URLs + access date.
   Git commit before reporting."

═══════════════════════════════════════════════════════════════

4️⃣  BUILD SCRIPT (Builder Agent)

openclaw sessions spawn \
  --label build-surf-pipeline \
  --instructions "$(cat agents/templates/builder-agent.md)" \
  --model sonnet \
  "Build daily surf data pipeline:
   - Fetch Windguru API for Logroño surf spots
   - Parse conditions (wave height, wind, tide)
   - Save to memory/surf/conditions-YYYY-MM-DD.md
   - Include cron setup (daily 06:00)
   - Error handling + logging
   - Test before committing.
   Git commit when ready."

═══════════════════════════════════════════════════════════════

5️⃣  AUDIT CRON JOBS (Audit Agent)

openclaw sessions spawn \
  --label audit-crons \
  --instructions "$(cat agents/templates/audit-agent.md)" \
  --model haiku \
  "Audit all cron jobs.
   Check:
   - Delivery configured
   - best-effort-deliver used
   - Ran successfully at least once
   - No errors in last 7 days
   - Schedules correct
   Report: memory/audits/crons-2026-03-22.md
   Git commit findings."

═══════════════════════════════════════════════════════════════

6️⃣  MULTI-DOMAIN (Surf + Health Parallel)

# Spawn both in parallel
openclaw sessions spawn \
  --label surf-conditions \
  --instructions "$(cat agents/templates/domain-agent.md)" \
  --model haiku \
  "Domain: surf. Analyze conditions for weekend."

openclaw sessions spawn \
  --label health-recovery \
  --instructions "$(cat agents/templates/domain-agent.md)" \
  --model haiku \
  "Domain: health. Check recovery status (HRV, sleep, fatigue)."

# Main agent waits (push-based), then synthesizes:
# "Surf conditions good, but recovery poor → recommend rest day"

═══════════════════════════════════════════════════════════════

7️⃣  BATCH PROCESSING (Multiple Items in Parallel)

# Process multiple independent tasks
for topic in "progression" "equipment" "safety"; do
    openclaw sessions spawn \
      --label "research-surf-${topic}" \
      --instructions "$(cat agents/templates/research-agent.md)" \
      --model haiku \
      "Research surf ${topic}. Save to memory/surf/coaching/${topic}.md"
done

# All run in parallel, results auto-announce when each completes

═══════════════════════════════════════════════════════════════

EOF
}

# Monitor active agents
monitor_agents() {
    echo -e "${BLUE}📊 Active Agents${NC}\n"
    
    # List all sessions
    openclaw sessions list
    
    echo -e "\n${BLUE}💾 Resource Usage${NC}"
    echo "Memory:"
    free -h | grep Mem
    
    echo -e "\nCPU:"
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "Usage: " 100 - $1"%"}'
    
    echo -e "\n${BLUE}📈 Recent Experiment Log${NC}"
    if [ -f "${WORKSPACE}/autoimprove/experiment-log.jsonl" ]; then
        tail -5 "${WORKSPACE}/autoimprove/experiment-log.jsonl" | jq -r '.ts + " | " + .agent + " | " + .target + " | kept=" + (.kept|tostring)'
    else
        echo "No experiment log found"
    fi
}

# Show statistics
show_stats() {
    echo -e "${BLUE}📊 Agent Statistics${NC}\n"
    
    # Count experiments by agent (last 7 days)
    if [ -f "${WORKSPACE}/autoimprove/experiment-log.jsonl" ]; then
        echo "Experiments (last 7 days):"
        jq -r 'select(.ts >= (now - 7*86400 | strftime("%Y-%m-%dT%H:%M:%SZ"))) | .agent' \
            "${WORKSPACE}/autoimprove/experiment-log.jsonl" 2>/dev/null | sort | uniq -c | sort -rn || echo "No recent experiments"
        
        echo -e "\nSuccess rate (last 7 days):"
        total=$(jq -r 'select(.ts >= (now - 7*86400 | strftime("%Y-%m-%dT%H:%M:%SZ")))' \
            "${WORKSPACE}/autoimprove/experiment-log.jsonl" 2>/dev/null | wc -l)
        kept=$(jq -r 'select(.ts >= (now - 7*86400 | strftime("%Y-%m-%dT%H:%M:%SZ")) and .kept == true)' \
            "${WORKSPACE}/autoimprove/experiment-log.jsonl" 2>/dev/null | wc -l)
        
        if [ "$total" -gt 0 ]; then
            rate=$(awk "BEGIN {printf \"%.1f\", ($kept/$total)*100}")
            echo "  Total: $total"
            echo "  Kept: $kept"
            echo "  Rate: ${rate}%"
        else
            echo "  No experiments in last 7 days"
        fi
    else
        echo "No experiment log found"
    fi
    
    echo -e "\n${BLUE}🔄 Nightly Autoimprove Agents${NC}"
    openclaw cron list | grep -i autoimprove || echo "No autoimprove crons found"
    
    echo -e "\n${BLUE}📁 Recent Analyses${NC}"
    echo "Domain analyses (last 7 days):"
    find "${WORKSPACE}/memory" -name "analysis-*.md" -mtime -7 -type f 2>/dev/null | head -10 || echo "None found"
    
    echo -e "\n${BLUE}🔍 Recent Audits${NC}"
    find "${WORKSPACE}/memory/audits" -name "*.md" -mtime -7 -type f 2>/dev/null | head -10 || echo "None found"
}

# Main
case "${1:-help}" in
    help)
        show_help
        ;;
    examples)
        show_examples
        ;;
    monitor)
        monitor_agents
        ;;
    stats)
        show_stats
        ;;
    *)
        echo -e "${RED}Unknown pattern: $1${NC}"
        echo "Run: bash scripts/spawn-agents.sh help"
        exit 1
        ;;
esac
