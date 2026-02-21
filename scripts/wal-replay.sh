#!/bin/bash

# WAL Replay — Recuperar estado desde snapshot + logs
# Usado por BOOT.md para recuperación post-crash

set -e

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
WAL_DIR="${WORKSPACE}/memory/WAL"
SNAPSHOTS_DIR="${WAL_DIR}/snapshots"
RECOVERY_DIR="${WORKSPACE}/.recovery-$(date +%s)"

MODE="${1:-validate}"  # validate | replay | dry-run

echo "🔄 WAL Replay — Mode: $MODE"

case "$MODE" in
    validate)
        echo "✅ Validating WAL integrity..."
        bash "$WORKSPACE/scripts/wal-logger.sh" validate
        ;;
    
    dry-run)
        echo "🧪 Dry-run: Show what would be recovered (no changes)"
        LATEST=$(ls -t "$SNAPSHOTS_DIR"/snapshot-*.tar.gz 2>/dev/null | head -1)
        if [ -z "$LATEST" ]; then
            echo "❌ No snapshots found"
            exit 1
        fi
        echo "   Latest snapshot: $(basename "$LATEST")"
        echo "   Would recover to: $RECOVERY_DIR"
        tar -tzf "$LATEST" | head -10
        echo "   ... (and more files)"
        ;;
    
    replay)
        echo "🔄 REPLAY MODE: Recovering from latest snapshot..."
        LATEST=$(ls -t "$SNAPSHOTS_DIR"/snapshot-*.tar.gz 2>/dev/null | head -1)
        if [ -z "$LATEST" ]; then
            echo "❌ No snapshots found. Cannot replay."
            exit 1
        fi
        
        echo "   Snapshot: $(basename "$LATEST")"
        mkdir -p "$RECOVERY_DIR"
        
        # Extract snapshot
        tar -xzf "$LATEST" -C "$RECOVERY_DIR"
        echo "✅ Extracted to: $RECOVERY_DIR"
        
        # Verify extracted files
        if [ -f "$RECOVERY_DIR/MEMORY.md" ]; then
            echo "✅ MEMORY.md recovered"
        fi
        
        echo ""
        echo "📋 RECOVERY SUMMARY:"
        echo "   Files recovered: $(find "$RECOVERY_DIR" -type f | wc -l)"
        echo "   Size: $(du -sh "$RECOVERY_DIR" | cut -f1)"
        echo "   Location: $RECOVERY_DIR"
        echo ""
        echo "⚠️  Review recovery dir before applying:"
        echo "   cp -r $RECOVERY_DIR/* $WORKSPACE/"
        ;;
    
    *)
        echo "Usage: $0 [validate|dry-run|replay]"
        exit 1
        ;;
esac

exit 0
