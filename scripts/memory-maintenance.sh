#!/bin/bash
# Memory Maintenance Script (inspired by Signet pipeline)
# Runs weekly: deduplication, retention decay, stats

set -euo pipefail

# Check dependencies
for cmd in find date awk wc du; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ Missing required dependency: $cmd" >&2
        exit 1
    fi
done

MEMORY_DIR="${HOME:?}/.openclaw/workspace/memory"
if [ ! -d "$MEMORY_DIR" ]; then
    echo "❌ Memory directory not found: $MEMORY_DIR" >&2
    exit 1
fi
ARCHIVE_DIR="$MEMORY_DIR/archive"
ENTITIES="$MEMORY_DIR/entities.md"
TODAY=$(date +%Y-%m-%d)
CUTOFF_DATE=$(date -d "30 days ago" +%Y-%m-%d)

echo "=== Memory Maintenance - $TODAY ==="

# 1. Stats (parallelize)
echo
echo "📊 STATS:"
{ TOTAL_FILES=$(find "$MEMORY_DIR" -maxdepth 1 -name "*.md" -type f | wc -l); } &
{ TOTAL_SIZE=$(du -sh "$MEMORY_DIR" | awk '{print $1}'); } &
wait
echo "  Files: $TOTAL_FILES"
echo "  Size: $TOTAL_SIZE"

# 2. Find old files (>30 days, not core files) - optimized with single find
echo
echo "🗂️ FILES OLDER THAN 30 DAYS (candidates for archive):"
OLD_COUNT=0
while IFS= read -r f; do
    BASENAME=$(basename "$f")
    FILE_DATE=$(echo "$BASENAME" | grep -oP '^\d{4}-\d{2}-\d{2}')
    [ -z "$FILE_DATE" ] && continue
    if [[ "$FILE_DATE" < "$CUTOFF_DATE" ]]; then
        echo "  📁 $BASENAME (from $FILE_DATE)"
        OLD_COUNT=$((OLD_COUNT + 1))
    fi
done < <(find "$MEMORY_DIR" -maxdepth 1 -name "2026-*.md" -type f)
echo "  Total: $OLD_COUNT files eligible for archival"

# 3. Duplicate detection (files with very similar names on same day)
echo
echo "🔍 POTENTIAL DUPLICATES (same-day, similar names):"
find "$MEMORY_DIR" -maxdepth 1 -name "*.md" -type f -printf "%f\n" | \
    sort | uniq -d -w 10 | head -10

# 4. Size warnings
echo
echo "⚠️ LARGE FILES (>10KB):"
find "$MEMORY_DIR" -maxdepth 1 -name "*.md" -type f -size +10k -exec ls -lh {} \; | \
    awk '{print "  " $5 " " $NF}'

echo
echo "=== Maintenance Complete ==="
echo "Actions needed: review old files for archival, check duplicates"
