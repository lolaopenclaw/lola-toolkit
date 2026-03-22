#!/bin/bash
# Gemini Reindex — slow batches to avoid rate limit
# Runs openclaw memory index repeatedly, waiting between attempts
# Each attempt indexes some files before hitting rate limit

set -e

LOG="/tmp/gemini-reindex.log"
STATUS_FILE="/tmp/gemini-reindex-status.json"
MAX_ATTEMPTS=30
WAIT_SECONDS=120  # 2 min between attempts

echo "$(date '+%Y-%m-%d %H:%M:%S') — Gemini reindex starting" | tee "$LOG"

# Step 1: Ensure config is set to gemini
python3 -c "
import json
with open('/home/mleon/.openclaw/openclaw.json') as f:
    config = json.load(f)
ms = config.setdefault('agents', {}).setdefault('defaults', {}).setdefault('memorySearch', {})
ms['provider'] = 'gemini'
ms['model'] = 'gemini-embedding-001'
ms['fallback'] = 'ollama'
with open('/home/mleon/.openclaw/openclaw.json', 'w') as f:
    json.dump(config, f, indent=2)
print('Config set to gemini')
"

# Step 2: Iterative reindex
for attempt in $(seq 1 $MAX_ATTEMPTS); do
    # Check current status
    STATUS=$(openclaw memory status 2>/dev/null | grep "Indexed:" | head -1)
    INDEXED=$(echo "$STATUS" | grep -oP '\d+(?=/)')
    TOTAL=$(echo "$STATUS" | grep -oP '(?<=/)\d+(?= files)')
    CHUNKS=$(echo "$STATUS" | grep -oP '\d+(?= chunks)' | head -1)
    
    echo "$(date '+%H:%M:%S') — Attempt $attempt/$MAX_ATTEMPTS: $INDEXED/$TOTAL files, $CHUNKS chunks" | tee -a "$LOG"
    
    # Save status for watchdog
    echo "{\"attempt\": $attempt, \"indexed\": ${INDEXED:-0}, \"total\": ${TOTAL:-0}, \"chunks\": ${CHUNKS:-0}, \"time\": \"$(date -Iseconds)\"}" > "$STATUS_FILE"
    
    # Check if done
    if [ "${INDEXED:-0}" -ge "${TOTAL:-999}" ] && [ "${INDEXED:-0}" -gt 0 ]; then
        echo "$(date '+%H:%M:%S') — ✅ COMPLETE: $INDEXED/$TOTAL files, $CHUNKS chunks" | tee -a "$LOG"
        echo "{\"status\": \"complete\", \"indexed\": $INDEXED, \"total\": $TOTAL, \"chunks\": $CHUNKS, \"time\": \"$(date -Iseconds)\"}" > "$STATUS_FILE"
        exit 0
    fi
    
    # Run reindex (will index what it can before rate limit)
    echo "$(date '+%H:%M:%S') — Running openclaw memory index..." | tee -a "$LOG"
    timeout 120 openclaw memory index --force 2>&1 | tail -5 | tee -a "$LOG" || true
    
    # Check progress after attempt
    STATUS_AFTER=$(openclaw memory status 2>/dev/null | grep "Indexed:" | head -1)
    INDEXED_AFTER=$(echo "$STATUS_AFTER" | grep -oP '\d+(?=/)')
    echo "$(date '+%H:%M:%S') — After attempt: $INDEXED_AFTER files indexed" | tee -a "$LOG"
    
    if [ "${INDEXED_AFTER:-0}" -ge "${TOTAL:-999}" ] && [ "${INDEXED_AFTER:-0}" -gt 0 ]; then
        echo "$(date '+%H:%M:%S') — ✅ COMPLETE!" | tee -a "$LOG"
        echo "{\"status\": \"complete\", \"indexed\": $INDEXED_AFTER, \"total\": $TOTAL, \"chunks\": ${CHUNKS:-0}, \"time\": \"$(date -Iseconds)\"}" > "$STATUS_FILE"
        exit 0
    fi
    
    # Wait before next attempt
    if [ $attempt -lt $MAX_ATTEMPTS ]; then
        echo "$(date '+%H:%M:%S') — Waiting ${WAIT_SECONDS}s before next attempt..." | tee -a "$LOG"
        sleep $WAIT_SECONDS
    fi
done

echo "$(date '+%H:%M:%S') — ⚠️ Max attempts reached. Check status manually." | tee -a "$LOG"
echo "{\"status\": \"incomplete\", \"attempts\": $MAX_ATTEMPTS, \"time\": \"$(date -Iseconds)\"}" > "$STATUS_FILE"
exit 1
