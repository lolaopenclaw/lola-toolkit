#!/bin/bash
# cleanup-drive-backup.sh — Limpia carpetas basura de Drive
# Elimina: .git, node_modules, .cache, logs, temp, etc.

set -euo pipefail

# Check dependencies
if ! command -v rclone &>/dev/null; then
    echo "❌ Missing required dependency: rclone" >&2
    exit 1
fi

DRIVE_FOLDER="openclaw_backups"

echo "=== Limpiando Google Drive Backups ==="
echo "DRIVE_FOLDER: $DRIVE_FOLDER"

# Array de carpetas basura a eliminar
TRASH=(
    ".git"
    ".cache"
    ".vectordb"
    ".trash"
    "node_modules"
    "logs"
    "temp"
    ".pi"
    ".clawhub"
    "backups-by-commit"
    "canvas"
    ".openclaw/dist"
    ".openclaw/node_modules"
    "CONTRIB/node_modules"
)

for dir in "${TRASH[@]}"; do
    echo "Limpiando: $dir"
    rclone delete "grive_lola:$DRIVE_FOLDER/$dir" --fast-list --drive-acknowledge-abuse 2>&1 | tail -1 || true
done

echo ""
echo "=== Resultado final ==="
rclone size "grive_lola:$DRIVE_FOLDER" 2>&1

echo "✅ Limpieza completada"
