#!/bin/bash
# Gemini Slow Reindex — embeds chunks one by one via API, inserts into SQLite
# Respects rate limits: 1 request per 3 seconds (~20 RPM, well under limits)
set -e

DB="$HOME/.openclaw/memory/main.sqlite"
BACKUP="$HOME/.openclaw/memory/main.sqlite.ollama-backup-v2"
LOG="/tmp/gemini-slow-reindex.log"
STATUS_FILE="/tmp/gemini-reindex-status.json"
MODEL="gemini-embedding-001"
DELAY=3  # seconds between API calls

source ~/.openclaw/.env 2>/dev/null

if [ -z "$GEMINI_API_KEY" ]; then
    echo "ERROR: GEMINI_API_KEY not found" | tee "$LOG"
    exit 1
fi

# Get chunks from the Ollama backup DB
TOTAL_CHUNKS=$(sqlite3 "$BACKUP" "SELECT COUNT(*) FROM chunks;")
TOTAL_FILES=$(sqlite3 "$BACKUP" "SELECT COUNT(DISTINCT path) FROM chunks;")
echo "$(date '+%H:%M:%S') — Starting slow reindex: $TOTAL_CHUNKS chunks from $TOTAL_FILES files" | tee "$LOG"

# Create fresh DB with schema from backup
rm -f "$DB" "$DB"-tmp-* 2>/dev/null
sqlite3 "$BACKUP" ".schema" | sqlite3 "$DB"

# Copy file metadata
sqlite3 "$BACKUP" ".dump files" | sqlite3 "$DB" 2>/dev/null || true
sqlite3 "$BACKUP" ".dump meta" | sqlite3 "$DB" 2>/dev/null || true

DONE=0
ERRORS=0
RATE_WAITS=0

# Process chunks one by one
sqlite3 -separator $'\t' "$BACKUP" "SELECT id, path, source, start_line, end_line, hash, text FROM chunks ORDER BY path, start_line;" | while IFS=$'\t' read -r id path source start_line end_line hash text; do
    DONE=$((DONE + 1))
    
    # Status update every 10 chunks
    if [ $((DONE % 10)) -eq 0 ] || [ $DONE -eq 1 ]; then
        PCT=$((DONE * 100 / TOTAL_CHUNKS))
        echo "$(date '+%H:%M:%S') — $DONE/$TOTAL_CHUNKS ($PCT%) — $path" | tee -a "$LOG"
        echo "{\"status\": \"running\", \"done\": $DONE, \"total\": $TOTAL_CHUNKS, \"errors\": $ERRORS, \"rate_waits\": $RATE_WAITS, \"time\": \"$(date -Iseconds)\"}" > "$STATUS_FILE"
    fi
    
    # Escape text for JSON
    JSON_TEXT=$(echo "$text" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")
    
    # Call Gemini API
    RETRIES=0
    MAX_RETRIES=5
    while [ $RETRIES -lt $MAX_RETRIES ]; do
        RESP=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:embedContent?key=${GEMINI_API_KEY}" \
            -H 'Content-Type: application/json' \
            -d "{\"model\":\"models/${MODEL}\",\"content\":{\"parts\":[{\"text\":${JSON_TEXT}}]}}" 2>/dev/null)
        
        # Check for error
        ERROR=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('error',{}).get('code',''))" 2>/dev/null)
        
        if [ "$ERROR" = "429" ]; then
            RATE_WAITS=$((RATE_WAITS + 1))
            WAIT=$((15 * (RETRIES + 1)))
            echo "$(date '+%H:%M:%S') — Rate limited, waiting ${WAIT}s (retry $((RETRIES+1)))" | tee -a "$LOG"
            sleep $WAIT
            RETRIES=$((RETRIES + 1))
            continue
        elif [ -n "$ERROR" ] && [ "$ERROR" != "" ]; then
            echo "$(date '+%H:%M:%S') — API error $ERROR for chunk $id" | tee -a "$LOG"
            ERRORS=$((ERRORS + 1))
            break
        fi
        
        # Extract embedding
        EMBEDDING=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); vals=d.get('embedding',{}).get('values',[]); print(json.dumps(vals))" 2>/dev/null)
        
        if [ "$EMBEDDING" = "[]" ] || [ -z "$EMBEDDING" ]; then
            echo "$(date '+%H:%M:%S') — Empty embedding for chunk $id" | tee -a "$LOG"
            ERRORS=$((ERRORS + 1))
            break
        fi
        
        # Insert into DB
        ESCAPED_TEXT=$(echo "$text" | sed "s/'/''/g")
        ESCAPED_PATH=$(echo "$path" | sed "s/'/''/g")
        NOW=$(date +%s)000
        
        sqlite3 "$DB" "INSERT OR REPLACE INTO chunks (id, path, source, start_line, end_line, hash, model, text, embedding, updated_at) VALUES ('$id', '$ESCAPED_PATH', '$source', $start_line, $end_line, '$hash', '$MODEL', '$ESCAPED_TEXT', '$EMBEDDING', $NOW);"
        
        # Also insert into FTS
        sqlite3 "$DB" "INSERT OR REPLACE INTO chunks_fts (rowid, text, id, path, source, model, start_line, end_line) VALUES ((SELECT rowid FROM chunks WHERE id='$id'), '$ESCAPED_TEXT', '$id', '$ESCAPED_PATH', '$source', '$MODEL', $start_line, $end_line);" 2>/dev/null || true
        
        break
    done
    
    # Rate limit: wait between requests
    sleep $DELAY
done

FINAL_CHUNKS=$(sqlite3 "$DB" "SELECT COUNT(*) FROM chunks;")
FINAL_FILES=$(sqlite3 "$DB" "SELECT COUNT(DISTINCT path) FROM chunks;")
echo "$(date '+%H:%M:%S') — ✅ COMPLETE: $FINAL_CHUNKS chunks from $FINAL_FILES files (errors: $ERRORS, rate_waits: $RATE_WAITS)" | tee -a "$LOG"
echo "{\"status\": \"complete\", \"chunks\": $FINAL_CHUNKS, \"files\": $FINAL_FILES, \"errors\": $ERRORS, \"rate_waits\": $RATE_WAITS, \"time\": \"$(date -Iseconds)\"}" > "$STATUS_FILE"
