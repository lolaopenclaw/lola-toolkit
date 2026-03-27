#!/bin/bash
set -uo pipefail
# Session Log Rotation
# Compress logs >7 days, delete >30 days
# Usage: bash scripts/session-log-rotation.sh [--dry-run]

SESSIONS_DIR="${HOME}/.openclaw/agents/main/sessions"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

compressed=0
deleted=0
freed=0

# Compress JSONL files older than 7 days (skip today/yesterday)
if $DRY_RUN; then
  find "$SESSIONS_DIR" -name "*.jsonl" -mtime +7 -type f 2>/dev/null | while read -r f; do
    echo "[DRY-RUN] Would compress: $(basename "$f")"
    compressed=$((compressed + 1))
  done
else
  compressed=$(find "$SESSIONS_DIR" -name "*.jsonl" -mtime +7 -type f 2>/dev/null | xargs -r -P 4 -I {} sh -c 'gzip -9 "{}" && echo 1' | wc -l)
fi

# Delete gzipped files older than 30 days
while IFS= read -r f; do
  size=$(stat -c%s "$f" 2>/dev/null || echo 0)
  if $DRY_RUN; then
    echo "[DRY-RUN] Would delete: $(basename "$f") ($(numfmt --to=iec "$size" 2>/dev/null || echo "${size}B"))"
  else
    rm "$f"
  fi
  deleted=$((deleted + 1))
  freed=$((freed + size))
done < <(find "$SESSIONS_DIR" -name "*.jsonl.gz" -mtime +30 -type f 2>/dev/null)

if [[ $compressed -eq 0 && $deleted -eq 0 ]]; then
  echo "LOG_ROTATION_OK"
else
  echo "Compressed: $compressed files"
  echo "Deleted: $deleted files"
  echo "Space freed: $(numfmt --to=iec $freed 2>/dev/null || echo "${freed}B")"
fi
