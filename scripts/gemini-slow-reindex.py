#!/usr/bin/env python3
"""Gemini Slow Reindex — embeds chunks via API one by one, inserts into SQLite."""
import sqlite3
import json
import os
import time
import urllib.request
import sys

BACKUP_DB = os.path.expanduser("~/.openclaw/memory/main.sqlite.ollama-backup-v2")
TARGET_DB = os.path.expanduser("~/.openclaw/memory/main.sqlite")
API_KEY = os.environ.get("GEMINI_API_KEY", "")
MODEL = "gemini-embedding-001"
DELAY = 3  # seconds between API calls
STATUS_FILE = "/tmp/gemini-reindex-status.json"
LOG_FILE = "/tmp/gemini-slow-reindex.log"

def log(msg):
    ts = time.strftime("%H:%M:%S")
    line = f"{ts} — {msg}"
    print(line, flush=True)
    with open(LOG_FILE, "a") as f:
        f.write(line + "\n")

def embed(text):
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:embedContent?key={API_KEY}"
    payload = json.dumps({"model": f"models/{MODEL}", "content": {"parts": [{"text": text}]}}).encode()
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
    
    for retry in range(5):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read())
                vals = data.get("embedding", {}).get("values", [])
                if vals:
                    return vals
        except urllib.error.HTTPError as e:
            body = e.read().decode()
            if e.code == 429:
                wait = 15 * (retry + 1)
                log(f"Rate limited (429), waiting {wait}s (retry {retry+1})")
                time.sleep(wait)
                continue
            else:
                log(f"API error {e.code}: {body[:200]}")
                return None
        except Exception as e:
            log(f"Request error: {e}")
            return None
    return None

def save_status(status, done=0, total=0, errors=0, rate_waits=0):
    with open(STATUS_FILE, "w") as f:
        json.dump({"status": status, "done": done, "total": total, "errors": errors, "rate_waits": rate_waits, "time": time.strftime("%Y-%m-%dT%H:%M:%S%z")}, f)

def main():
    if not API_KEY:
        log("ERROR: GEMINI_API_KEY not set")
        sys.exit(1)
    
    # Open source DB (ollama backup)
    src = sqlite3.connect(BACKUP_DB)
    src.row_factory = sqlite3.Row
    
    # Get all chunks
    chunks = src.execute("SELECT id, path, source, start_line, end_line, hash, text FROM chunks ORDER BY path, start_line").fetchall()
    total = len(chunks)
    log(f"Starting slow reindex: {total} chunks")
    
    # Open target DB
    tgt = sqlite3.connect(TARGET_DB)
    
    done = 0
    errors = 0
    rate_waits = 0
    
    for chunk in chunks:
        done += 1
        
        if done % 10 == 0 or done == 1:
            pct = done * 100 // total
            log(f"{done}/{total} ({pct}%) — {chunk['path']}")
            save_status("running", done, total, errors, rate_waits)
        
        # Get embedding from Gemini
        vals = embed(chunk["text"])
        
        if vals is None:
            errors += 1
            continue
        
        embedding_json = json.dumps(vals)
        now = int(time.time() * 1000)
        
        # Insert chunk
        tgt.execute(
            "INSERT OR REPLACE INTO chunks (id, path, source, start_line, end_line, hash, model, text, embedding, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            (chunk["id"], chunk["path"], chunk["source"], chunk["start_line"], chunk["end_line"], chunk["hash"], MODEL, chunk["text"], embedding_json, now)
        )
        
        # Insert into FTS
        try:
            tgt.execute(
                "INSERT INTO chunks_fts (text, id, path, source, model, start_line, end_line) VALUES (?, ?, ?, ?, ?, ?, ?)",
                (chunk["text"], chunk["id"], chunk["path"], chunk["source"], MODEL, chunk["start_line"], chunk["end_line"])
            )
        except:
            pass
        
        # Commit every 50 chunks
        if done % 50 == 0:
            tgt.commit()
        
        time.sleep(DELAY)
    
    tgt.commit()
    tgt.close()
    src.close()
    
    final_chunks = sqlite3.connect(TARGET_DB).execute("SELECT COUNT(*) FROM chunks").fetchone()[0]
    log(f"✅ COMPLETE: {final_chunks}/{total} chunks (errors: {errors}, rate_waits: {rate_waits})")
    save_status("complete", final_chunks, total, errors, rate_waits)

if __name__ == "__main__":
    main()
