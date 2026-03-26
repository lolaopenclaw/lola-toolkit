#!/bin/bash
# backup-memory.sh — Complete workspace backup to Google Drive (4:00 AM daily)
# Includes: workspace, openclaw.json, .env, cron-db, GOG keyring, rclone config

set -euo pipefail
export GOG_KEYRING_BACKEND=file GOG_KEYRING_PASSWORD='ilJvN1bAcLhbuDbM3BnxABElpmVDHyA5eiV8UonEQCc=' GOG_ACCOUNT=lolaopenclaw@gmail.com
WORKSPACE="/home/mleon/.openclaw/workspace" OPENCLAW_DIR="/home/mleon/.openclaw" DRIVE_FOLDER="1G-OLpZKJ2zQXac0qaKxvaeglbRUuRxfD" BACKUP_DATE=$(date -u +%Y-%m-%d) BACKUP_DIR="/tmp/openclaw-backup-${BACKUP_DATE}"

echo "=== OpenClaw Memory Backup - ${BACKUP_DATE} ==="
mkdir -p "$BACKUP_DIR"/{gnupg,keyrings,gog-config,system-snapshot} 2>/dev/null || true

# Parallelize all copy operations
{ rsync -a "$WORKSPACE/memory/" "$BACKUP_DIR/memory/" 2>/dev/null || true; } &
{ rsync -a "$WORKSPACE/scripts/" "$BACKUP_DIR/scripts/" 2>/dev/null || true; } &
{ rsync -a "$WORKSPACE/skills/" "$BACKUP_DIR/skills/" 2>/dev/null || true; } &
{ for f in SOUL.md USER.md AGENTS.md IDENTITY.md TOOLS.md HEARTBEAT.md MEMORY.md RECOVERY.md BOOT.md cron-jobs.json; do [ -f "$WORKSPACE/$f" ] && cp "$WORKSPACE/$f" "$BACKUP_DIR/$f" 2>/dev/null; done; } &
{ cp "$OPENCLAW_DIR/openclaw.json" "$BACKUP_DIR/openclaw.json" 2>/dev/null || true; cp "$OPENCLAW_DIR/.env" "$BACKUP_DIR/dot-env" 2>/dev/null || true; [ -d "$HOME/.gnupg" ] && rsync -a "$HOME/.gnupg/" "$BACKUP_DIR/gnupg/" 2>/dev/null || true; [ -d "$HOME/.password-store" ] && rsync -a "$HOME/.password-store/" "$BACKUP_DIR/password-store/" 2>/dev/null || true; } &
{ for d in "$OPENCLAW_DIR/cron" "$OPENCLAW_DIR/data/cron"; do [ -d "$d" ] && cp -r "$d" "$BACKUP_DIR/cron-db" 2>/dev/null && break; done || true; [ -d "$HOME/.config/gog" ] && cp "$HOME/.config/gog/"* "$BACKUP_DIR/gog-config/" 2>/dev/null || true; [ -d "$HOME/.local/share/keyrings" ] && cp "$HOME/.local/share/keyrings/"* "$BACKUP_DIR/keyrings/" 2>/dev/null || true; [ -f "$HOME/.config/rclone/rclone.conf" ] && cp "$HOME/.config/rclone/rclone.conf" "$BACKUP_DIR/rclone.conf" 2>/dev/null || true; } &
{ openclaw --version > "$BACKUP_DIR/system-snapshot/openclaw-version.txt" 2>/dev/null || true; node --version > "$BACKUP_DIR/system-snapshot/node-version.txt" 2>/dev/null || true; cp "$WORKSPACE/scripts/restore.sh" "$BACKUP_DIR/restore.sh" 2>/dev/null || true; } &
wait
# Create archive and upload
BACKUP_FILE="/tmp/openclaw-backup-${BACKUP_DATE}.tar.gz"
tar c -C /tmp "openclaw-backup-${BACKUP_DATE}" | pigz -1 > "$BACKUP_FILE"
FILE_COUNT=$(find "$BACKUP_DIR" -type f | wc -l)
BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

# Delete duplicates and upload
gog drive list --parent "$DRIVE_FOLDER" --account "$GOG_ACCOUNT" --no-input 2>/dev/null | grep "openclaw-backup-${BACKUP_DATE}" | awk '{print $1}' | xargs -r -I {} gog drive delete {} --account "$GOG_ACCOUNT" --no-input 2>/dev/null || true

UPLOAD_OUTPUT=$(gog drive upload "$BACKUP_FILE" --parent "$DRIVE_FOLDER" --account "$GOG_ACCOUNT" --no-input 2>&1)
UPLOAD_EXIT=$?

if [ $UPLOAD_EXIT -ne 0 ]; then
  ERROR_MSG="OAuth/upload failed: $UPLOAD_OUTPUT"
  echo "ERROR: $ERROR_MSG" >&2
  mkdir -p "$WORKSPACE/memory"
  jq -n --arg date "$BACKUP_DATE" --arg error "$ERROR_MSG" --arg files "$FILE_COUNT" --arg size "$BACKUP_SIZE" \
    '{date: $date, status: "error", error: $error, files: $files, size: $size}' \
    > "$WORKSPACE/memory/last-backup.json"
  rm -rf "$BACKUP_DIR" "$BACKUP_FILE"
  exit 1
fi

rm -rf "$BACKUP_DIR" "$BACKUP_FILE"
mkdir -p "$WORKSPACE/memory"
jq -n --arg date "$BACKUP_DATE" --arg files "$FILE_COUNT" --arg size "$BACKUP_SIZE" \
  '{date: $date, status: "ok", files: $files, size: $size}' \
  > "$WORKSPACE/memory/last-backup.json"
echo "=== RESULT === date: ${BACKUP_DATE} | files: ${FILE_COUNT} | size: ${BACKUP_SIZE} | status: ok"
