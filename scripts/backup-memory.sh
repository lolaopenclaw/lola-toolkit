#!/bin/bash
# =============================================================================
# backup-memory.sh — Backup completo del workspace a Google Drive
# =============================================================================
# Incluye: workspace, openclaw.json, .env, cron-db, GOG keyring, rclone config
# Se ejecuta diariamente a las 4:00 AM (cron job)
# =============================================================================

set -euo pipefail

# Configure these according to your setup
export GOG_KEYRING_BACKEND=file
export GOG_KEYRING_PASSWORD='YOUR_GOG_KEYRING_PASSWORD'
export GOG_ACCOUNT='YOUR_EMAIL@gmail.com'

WORKSPACE="$HOME/.openclaw/workspace"
OPENCLAW_DIR="$HOME/.openclaw"
DRIVE_FOLDER="YOUR_GOOGLE_DRIVE_FOLDER_ID"
BACKUP_DATE=$(date -u +%Y-%m-%d)
BACKUP_DIR="/tmp/openclaw-backup-${BACKUP_DATE}"
BACKUP_FILE="/tmp/openclaw-backup-${BACKUP_DATE}.tar.gz"

# Helper functions for safe file operations
safe_copy() { cp "$1" "$2" 2>/dev/null || true; }
safe_sync() { rsync -a "$1" "$2" 2>/dev/null || true; }

echo "=== OpenClaw Memory Backup - ${BACKUP_DATE} ==="
mkdir -p "$BACKUP_DIR" "$BACKUP_DIR/gnupg" "$BACKUP_DIR/keyrings" "$BACKUP_DIR/gog-config" "$BACKUP_DIR/system-snapshot" 2>/dev/null || true

echo "Copiando workspace..."
{
    for f in SOUL.md USER.md AGENTS.md IDENTITY.md TOOLS.md HEARTBEAT.md MEMORY.md RECOVERY.md BOOT.md cron-jobs.json; do
        safe_copy "$WORKSPACE/$f" "$BACKUP_DIR/" &
    done
    safe_sync "$WORKSPACE/memory/" "$BACKUP_DIR/memory/" &
    safe_sync "$WORKSPACE/scripts/" "$BACKUP_DIR/scripts/" &
    safe_sync "$WORKSPACE/skills/" "$BACKUP_DIR/skills/" &
    wait
}

# --- OpenClaw config + Secrets + GPG + Pass store ----
echo "Copiando config, secrets y credenciales..."
{
    safe_copy "$OPENCLAW_DIR/openclaw.json" "$BACKUP_DIR/openclaw.json" &
    safe_copy "$OPENCLAW_DIR/.env" "$BACKUP_DIR/dot-env" &
    [ -d "$HOME/.gnupg" ] && safe_copy "$HOME/.gnupg/pubring.kbx" "$BACKUP_DIR/gnupg/" &
    [ -d "$HOME/.gnupg" ] && safe_copy "$HOME/.gnupg/trustdb.gpg" "$BACKUP_DIR/gnupg/" &
    [ -d "$HOME/.gnupg" ] && safe_copy "$HOME/.gnupg/private-keys-v1.d" "$BACKUP_DIR/gnupg/" &
    [ -d "$HOME/.password-store" ] && safe_copy "$HOME/.password-store" "$BACKUP_DIR/password-store" &
    wait
}

# --- Cron jobs + GOG + Rclone -----------------------------------------------
echo "Copiando configuraciones..."
{
    for crondir in "$OPENCLAW_DIR/cron" "$OPENCLAW_DIR/data/cron"; do
        if [ -d "$crondir" ]; then
            safe_copy "$crondir" "$BACKUP_DIR/cron-db" &
            break
        fi
    done
    if [ -d "$HOME/.config/gog" ]; then
        safe_copy "$HOME/.config/gog/"* "$BACKUP_DIR/gog-config/" &
    fi
    if [ -d "$HOME/.local/share/keyrings" ]; then
        safe_copy "$HOME/.local/share/keyrings/"* "$BACKUP_DIR/keyrings/" &
    fi
    if [ -f "$HOME/.config/rclone/rclone.conf" ]; then
        safe_copy "$HOME/.config/rclone/rclone.conf" "$BACKUP_DIR/rclone.conf" &
    fi
    wait
} 2>/dev/null || true

# --- System config snapshot (essentials only) --------------------------------
echo "Copiando snapshot de sistema..."
{
    openclaw --version > "$BACKUP_DIR/system-snapshot/openclaw-version.txt" 2>/dev/null || true &
    node --version > "$BACKUP_DIR/system-snapshot/node-version.txt" 2>/dev/null || true &
    safe_copy "$WORKSPACE/scripts/restore.sh" "$BACKUP_DIR/restore.sh" &
    wait
}

# --- Compress & Upload -------------------------------------------------------
echo "Comprimiendo..."
tar -czf "$BACKUP_FILE" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")"
rm -rf "$BACKUP_DIR"

echo "Subiendo a Google Drive..."
gog drive upload "$BACKUP_FILE" --parent "$DRIVE_FOLDER" --overwrite

# Clean up
rm -f "$BACKUP_FILE"

echo "✅ Backup completado: $(basename "$BACKUP_FILE")"
echo "   Ubicación: Google Drive folder $DRIVE_FOLDER"
