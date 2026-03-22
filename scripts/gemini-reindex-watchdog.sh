#!/bin/bash
set -e
# Watchdog for gemini-slow-reindex.py
STATUS_FILE="/tmp/gemini-reindex-status.json"
if [ ! -f "$STATUS_FILE" ]; then echo "No reindex in progress"; exit 0; fi
python3 -c "
import json, os
with open('$STATUS_FILE') as f: d = json.load(f)
s = d.get('status','?')
done = d.get('done',0)
total = d.get('total',0)
errs = d.get('errors',0)
pct = (done*100//total) if total > 0 else 0
running = os.popen('pgrep -f gemini-slow-reindex.py').read().strip()
if s == 'complete':
    print(f'✅ COMPLETE: {done}/{total} chunks ({errs} errors)')
elif running:
    print(f'🔄 RUNNING: {done}/{total} ({pct}%) — {errs} errors (PID: {running})')
else:
    print(f'⚠️ STOPPED: {done}/{total} ({pct}%) — process not running')
"
