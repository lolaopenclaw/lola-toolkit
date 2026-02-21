#!/bin/bash

# WAL Snapshot — Crear punto de recuperación
# Comprime logs recientes en snapshot para recuperación rápida

set -e

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
WAL_DIR="${WORKSPACE}/memory/WAL"
SNAPSHOTS_DIR="${WAL_DIR}/snapshots"
LOGS_DIR="${WAL_DIR}/logs"
SNAPSHOT_NAME="snapshot-$(date +%Y%m%d-%H%M%S).tar.gz"
SNAPSHOT_PATH="${SNAPSHOTS_DIR}/${SNAPSHOT_NAME}"

mkdir -p "$SNAPSHOTS_DIR" "$LOGS_DIR"

echo "📸 Creating WAL snapshot: $SNAPSHOT_NAME"

# === CREATE SNAPSHOT ===
# Compress current logs + recent data
tar -czf "$SNAPSHOT_PATH" \
  -C "$WAL_DIR" logs/ \
  -C "$WORKSPACE" MEMORY.md SOUL.md IDENTITY.md TOOLS.md AGENTS.md \
  -C "$WORKSPACE/memory" INDEX.md \
  2>/dev/null || true

# === CLEANUP OLD SNAPSHOTS ===
# Keep only last 10 snapshots (rolling window)
cd "$SNAPSHOTS_DIR"
ls -t snapshot-*.tar.gz 2>/dev/null | tail -n +11 | while read old; do
    rm -f "$old"
    echo "  🗑️  Deleted old snapshot: $old"
done

# === ROTATE LOGS ===
# Move old logs to archive
if [ -f "$LOGS_DIR/2026-02-21.log" ]; then
    gzip -f "$LOGS_DIR/2026-02-21.log" 2>/dev/null && echo "  📦 Compressed 2026-02-21.log"
fi

# === SAVE SNAPSHOT METADATA ===
SNAPSHOT_META="${SNAPSHOTS_DIR}/.manifest"
cat >> "$SNAPSHOT_META" << EOF
$(date -Iseconds) | $SNAPSHOT_NAME | Files: $(tar -tzf "$SNAPSHOT_PATH" 2>/dev/null | wc -l)
EOF

echo "✅ Snapshot created: $SNAPSHOT_PATH"
echo "   Size: $(du -h "$SNAPSHOT_PATH" | cut -f1)"
echo "   Total snapshots: $(ls -1 snapshot-*.tar.gz 2>/dev/null | wc -l)"

exit 0
