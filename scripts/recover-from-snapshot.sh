#!/bin/bash

# 📸 RECOVER FROM SNAPSHOT — Restaurar estado desde snapshot más reciente
# Ejecutado durante boot si se detecta crash
# Intenta snapshots en orden: 1, 2, 3 → si todos fallan, Drive backup

set -e

SNAPSHOT_DIR="/home/mleon/.openclaw/workspace/memory/WAL/snapshots"
COLD_DIR="/home/mleon/.openclaw/workspace/memory/WAL/COLD"
BACKUP_SCRIPT="/home/mleon/.openclaw/workspace/scripts/backup-memory.sh"
WAL_LOG="$SNAPSHOT_DIR/wal.log"

echo "=========================================="
echo "📸 CRASH DETECTED - RECOVERY PROCEDURE"
echo "=========================================="

# Función para restaurar desde snapshot
restore_snapshot() {
  local snapshot="$1"
  local snap_name=$(basename "$snapshot")
  
  echo ""
  echo "📦 Attempting restore from: $snap_name"
  
  # Validar SHA256
  if [ ! -f "$WAL_LOG" ]; then
    echo "⚠️  No WAL log found, skipping SHA256 validation"
    VALID=1
  else
    expected_sha=$(grep "$snap_name" "$WAL_LOG" 2>/dev/null | tail -1 | awk '{print $NF}')
    
    if [ -z "$expected_sha" ]; then
      echo "⚠️  No SHA256 in log for this snapshot, skipping validation"
      VALID=1
    else
      actual_sha=$(sha256sum "$snapshot" | awk '{print $1}')
      
      if [ "$expected_sha" = "$actual_sha" ]; then
        echo "✅ SHA256 valid"
        VALID=1
      else
        echo "❌ SHA256 mismatch (expected: $expected_sha, got: $actual_sha)"
        VALID=0
      fi
    fi
  fi
  
  if [ $VALID -eq 0 ]; then
    return 1
  fi
  
  # Descomprimir
  echo "📂 Decompressing..."
  
  if [[ "$snapshot" == *.tar.zst ]]; then
    tar --zstd -xf "$snapshot" -C ~/ 2>&1 | head -5
  elif [[ "$snapshot" == *.tar.gz ]]; then
    tar xzf "$snapshot" -C ~/ 2>&1 | head -5
  else
    echo "❌ Unknown compression format"
    return 1
  fi
  
  echo "✅ Restored from $snap_name"
  return 0
}

# 1. Intentar snapshots en orden (1, 2, 3)
if [ -d "$SNAPSHOT_DIR" ]; then
  echo ""
  echo "🔍 Searching for valid snapshots..."
  
  snapshot_count=0
  for snapshot in $(ls -t "$SNAPSHOT_DIR"/snapshot-*.tar.* 2>/dev/null); do
    snapshot_count=$((snapshot_count + 1))
    
    if [ $snapshot_count -gt 3 ]; then
      break
    fi
    
    echo "  [$snapshot_count/3] $(basename $snapshot)"
    
    if restore_snapshot "$snapshot"; then
      echo ""
      echo "=========================================="
      echo "✅ RECOVERY SUCCESSFUL FROM SNAPSHOT #$snapshot_count"
      echo "=========================================="
      
      # Log the recovery
      echo "[$(date +'%Y-%m-%d %H:%M:%S')] Recovery from snapshot: $(basename $snapshot)" >> "$WAL_LOG"
      
      exit 0
    fi
  done
  
  echo ""
  echo "❌ All snapshots failed or corrupt"
else
  echo "⚠️  Snapshot directory not found"
fi

# 2. Si todos los snapshots fallan, intentar Drive backup
echo ""
echo "🔽 Attempting recovery from Drive backup..."
echo "   (This will take longer...)"

if [ ! -f "$BACKUP_SCRIPT" ]; then
  echo "❌ Backup script not found: $BACKUP_SCRIPT"
  echo "   Manual recovery required"
  exit 1
fi

# Intenta restaurar backup más reciente
echo "⏳ Downloading latest backup from Drive..."

# Busca en Drive el backup más reciente
BACKUP_FILE=$(/home/mleon/.openclaw/workspace/scripts/backup-memory.sh list-latest 2>/dev/null || echo "")

if [ -z "$BACKUP_FILE" ]; then
  echo "❌ No backups found in Drive"
  echo "   Manual recovery required"
  exit 1
fi

echo "📥 Restoring from: $BACKUP_FILE"

bash "$BACKUP_SCRIPT" restore-file "$BACKUP_FILE" 2>&1 | tail -10

echo ""
echo "=========================================="
echo "✅ RECOVERY SUCCESSFUL FROM DRIVE BACKUP"
echo "=========================================="
echo "ℹ️  Restored to state from: $(date -d @$(stat -c %Y $BACKUP_FILE) +'%Y-%m-%d %H:%M:%S')"
exit 0
