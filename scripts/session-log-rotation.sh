#!/bin/bash
set -euo pipefail

# Session Log Rotation
# - Compress logs older than 7 days (gzip)
# - Delete logs older than 30 days
# - Report what was done

SESSIONS_DIR="$HOME/.openclaw/agents/main/sessions"
COMPRESS_DAYS=7
DELETE_DAYS=30
DRY_RUN=false

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Rotate OpenClaw session logs to save disk space.

OPTIONS:
  --dry-run         Show what would be done without doing it
  -h, --help        Show this help

BEHAVIOR:
  - Compress .jsonl files older than $COMPRESS_DAYS days → .jsonl.gz
  - Delete .jsonl.gz files older than $DELETE_DAYS days
  - Skip today's and yesterday's logs (actively written to)

LOCATION: $SESSIONS_DIR
EOF
  exit 0
}

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) show_help ;;
    *) echo "❌ Unknown option: $1 (try --help)" >&2; exit 1 ;;
  esac
done

# Validate dependencies
for cmd in find gzip stat date; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "❌ Required: $cmd" >&2; exit 1; }
done

# Validate directory
if [[ ! -d "$SESSIONS_DIR" ]]; then
  echo "❌ Sessions directory not found: $SESSIONS_DIR" >&2
  exit 1
fi

# Calculate cutoff timestamps
NOW=$(date +%s)
COMPRESS_CUTOFF=$((NOW - COMPRESS_DAYS * 86400))
DELETE_CUTOFF=$((NOW - DELETE_DAYS * 86400))
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)

# Counters
COMPRESSED_COUNT=0
DELETED_COUNT=0
SPACE_BEFORE=0
SPACE_AFTER=0

# Track files to compress
TO_COMPRESS=()
TO_DELETE=()

# Find .jsonl files to compress
while IFS= read -r file; do
  # Get file modification time
  FILE_MTIME=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || echo 0)
  
  # Skip if modified within last $COMPRESS_DAYS days
  [[ $FILE_MTIME -ge $COMPRESS_CUTOFF ]] && continue
  
  # Extract date from filename or file content
  BASENAME=$(basename "$file" .jsonl)
  
  # Skip today's and yesterday's logs explicitly by filename pattern
  if [[ "$BASENAME" == *"$TODAY"* ]] || [[ "$BASENAME" == *"$YESTERDAY"* ]]; then
    continue
  fi
  
  TO_COMPRESS+=("$file")
done < <(find "$SESSIONS_DIR" -maxdepth 1 -name "*.jsonl" -type f)

# Find .jsonl.gz files to delete
while IFS= read -r file; do
  FILE_MTIME=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || echo 0)
  
  # Only delete if older than $DELETE_DAYS days
  [[ $FILE_MTIME -lt $DELETE_CUTOFF ]] && TO_DELETE+=("$file")
done < <(find "$SESSIONS_DIR" -maxdepth 1 -name "*.jsonl.gz" -type f)

# Execute or report
if [[ ${#TO_COMPRESS[@]} -gt 0 ]]; then
  for file in "${TO_COMPRESS[@]}"; do
    if $DRY_RUN; then
      echo "[DRY-RUN] Would compress: $(basename "$file")"
    else
      SIZE_BEFORE=$(stat -c %s "$file" 2>/dev/null || stat -f %z "$file" 2>/dev/null || echo 0)
      SPACE_BEFORE=$((SPACE_BEFORE + SIZE_BEFORE))
      
      gzip -9 "$file"
      ((COMPRESSED_COUNT++)) || true
      
      # Measure compressed size
      SIZE_AFTER=$(stat -c %s "$file.gz" 2>/dev/null || stat -f %z "$file.gz" 2>/dev/null || echo 0)
      SPACE_AFTER=$((SPACE_AFTER + SIZE_AFTER))
    fi
  done
fi

if [[ ${#TO_DELETE[@]} -gt 0 ]]; then
  for file in "${TO_DELETE[@]}"; do
    if $DRY_RUN; then
      echo "[DRY-RUN] Would delete: $(basename "$file")"
    else
      rm -f "$file"
      ((DELETED_COUNT++)) || true
    fi
  done
fi

# Calculate space freed (with better precision for small values)
if ! $DRY_RUN && [[ $COMPRESSED_COUNT -gt 0 ]]; then
  SPACE_FREED=$((SPACE_BEFORE - SPACE_AFTER))
  # Use KB for values <10MB to show meaningful numbers
  if [[ $SPACE_FREED -lt 10485760 ]]; then
    SPACE_FREED_KB=$((SPACE_FREED / 1024))
    SPACE_FREED_DISPLAY="${SPACE_FREED_KB}KB"
  else
    SPACE_FREED_MB=$((SPACE_FREED / 1024 / 1024))
    SPACE_FREED_DISPLAY="${SPACE_FREED_MB}MB"
  fi
else
  SPACE_FREED_DISPLAY="0KB"
fi

# Report
if $DRY_RUN; then
  echo ""
  echo "📊 Dry Run Summary:"
  echo "  - Would compress: ${#TO_COMPRESS[@]} files"
  echo "  - Would delete: ${#TO_DELETE[@]} files"
else
  if [[ $COMPRESSED_COUNT -eq 0 && $DELETED_COUNT -eq 0 ]]; then
    echo "LOG_ROTATION_OK"
  else
    echo "✅ Session Log Rotation Complete"
    echo "  - Compressed: $COMPRESSED_COUNT files"
    echo "  - Deleted: $DELETED_COUNT files"
    echo "  - Space freed: ${SPACE_FREED_DISPLAY}"
  fi
fi

exit 0
