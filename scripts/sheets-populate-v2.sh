#!/bin/bash
# ============================================================================
# sheets-populate-v2.sh — Cron wrapper for Google Sheets Population
# ============================================================================
#
# This is a thin wrapper around sheets-populate-v2.py for cron usage.
#
# LOGIC:
#   - Consumo IA: Uses TODAY's date (usage report generated at 9:10 AM)
#   - Garmin Health: Uses YESTERDAY's date (complete day of activity data)
#     + today's sleep data (automatically fetched by the Python script)
#
# CRON: Daily 9:30 AM Madrid (after usage report at 9:10 AM)
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="${SCRIPT_DIR}/sheets-populate-v2.py"
LOG_DIR="${HOME}/.openclaw/workspace/logs"
LOG_FILE="${LOG_DIR}/sheets-populate-$(date +%Y-%m-%d).log"

# Load environment
source "${HOME}/.openclaw/.env" 2>/dev/null || true
export GOG_KEYRING_BACKEND="${GOG_KEYRING_BACKEND:-file}"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)

echo "============================================================" | tee -a "$LOG_FILE"
echo "📊 Sheets Population Cron — $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
echo "============================================================" | tee -a "$LOG_FILE"

# 1. Consumo IA — today's data
echo "" | tee -a "$LOG_FILE"
echo "📈 Running Consumo IA for $TODAY..." | tee -a "$LOG_FILE"
python3 "$PYTHON_SCRIPT" --consumo-only --date "$TODAY" 2>&1 | tee -a "$LOG_FILE"

# 2. Garmin Health — yesterday's activity data + today's sleep
echo "" | tee -a "$LOG_FILE"
echo "💓 Running Garmin Health for $YESTERDAY..." | tee -a "$LOG_FILE"
python3 "$PYTHON_SCRIPT" --garmin-only --date "$YESTERDAY" 2>&1 | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
echo "✅ Cron completed at $(date '+%H:%M:%S')" | tee -a "$LOG_FILE"

# Clean old logs (keep 14 days)
find "$LOG_DIR" -name "sheets-populate-*.log" -mtime +14 -delete 2>/dev/null || true
