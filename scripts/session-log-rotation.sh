#!/bin/bash
set -euo pipefail

SESSIONS_DIR="${HOME}/.openclaw/agents/main/sessions"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

compressed=0
deleted=0
freed=0

# Compress JSONL files older than 7 days
find "$SESSIONS_DIR" -name "*.jsonl" -mtime +7 -type f | while read -r f; do
  if $DRY_RUN; then
    echo "[DRY-RUN] Would compress: $(basename "$f")"
  else
    gzip "$f"
    ((compressed++))
  fi
done

# Delete gzipped files older than 30 days
find "$SESSIONS_DIR" -name "*.jsonl.gz" -mtime +30 -type f | while read -r f; do
  size=$(stat -c%s "$f" 2>/dev/null || echo 0)
  if $DRY_RUN; then
    echo "[DRY-RUN] Would delete: $(basename "$f") ($(numfmt --to=iec "$size"))"
  else
    rm "$f"
    ((deleted++))
    freed=$((freed + size))
  fi
done

echo "Compressed: $compressed files"
echo "Deleted: $deleted files" 
echo "Space freed: $(numfmt --to=iec $freed 2>/dev/null || echo "${freed}B")"
