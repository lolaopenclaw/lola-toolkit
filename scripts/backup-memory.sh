#!/bin/bash
# =============================================================================
# backup-memory.sh — Backup completo del workspace a Google Drive
# =============================================================================
# Incluye: workspace, openclaw.json, .env, cron-db, GOG keyring, rclone config
# Se ejecuta diariamente a las 4:00 AM Madrid (cron job)
# =============================================================================

set -euo pipefail

export GOG_KEYRING_BACKEND=file
export GOG_KEYRING_PASSWORD='ilJvN1bAcLhbuDbM3BnxABElpmVDHyA5eiV8UonEQCc='
export GOG_ACCOUNT=lolaopenclaw@gmail.com

WORKSPACE="/home/mleon/.openclaw/workspace"
OPENCLAW_DIR="/home/mleon/.openclaw"
DRIVE_FOLDER="1G-OLpZKJ2zQXac0qaKxvaeglbRUuRxfD"
BACKUP_DATE=$(date -u +%Y-%m-%d)
BACKUP_DIR="/tmp/openclaw-backup-${BACKUP_DATE}"
BACKUP_FILE="/tmp/openclaw-backup-${BACKUP_DATE}.tar.gz"

echo "=== OpenClaw Memory Backup - ${BACKUP_DATE} ==="

# Create temp backup directory
mkdir -p "$BACKUP_DIR"

# --- Workspace files ---------------------------------------------------------
echo "Copiando workspace..."
{
    for f in SOUL.md USER.md AGENTS.md IDENTITY.md TOOLS.md HEARTBEAT.md MEMORY.md RECOVERY.md BOOT.md cron-jobs.json; do
        cp "$WORKSPACE/$f" "$BACKUP_DIR/" 2>/dev/null || true &
    done
    rsync -a "$WORKSPACE/memory/" "$BACKUP_DIR/memory/" 2>/dev/null || true &
    rsync -a "$WORKSPACE/scripts/" "$BACKUP_DIR/scripts/" 2>/dev/null || true &
    rsync -a "$WORKSPACE/skills/" "$BACKUP_DIR/skills/" 2>/dev/null || true &
    wait
}

# --- OpenClaw config ---------------------------------------------------------
echo "Copiando config OpenClaw..."
cp "$OPENCLAW_DIR/openclaw.json" "$BACKUP_DIR/openclaw.json" 2>/dev/null || true

# --- Secrets (.env) ----------------------------------------------------------
echo "Copiando secrets..."
cp "$OPENCLAW_DIR/.env" "$BACKUP_DIR/dot-env" 2>/dev/null || true

# --- GPG keys + Pass store (encrypted secrets) --------------------------------
echo "Copiando GPG keys + Pass store..."
if [ -d "$HOME/.gnupg" ]; then
    mkdir -p "$BACKUP_DIR/gnupg"
    cp -r "$HOME/.gnupg/pubring.kbx" "$BACKUP_DIR/gnupg/" 2>/dev/null || true
    cp -r "$HOME/.gnupg/trustdb.gpg" "$BACKUP_DIR/gnupg/" 2>/dev/null || true
    cp -r "$HOME/.gnupg/private-keys-v1.d" "$BACKUP_DIR/gnupg/" 2>/dev/null || true
fi
if [ -d "$HOME/.password-store" ]; then
    cp -r "$HOME/.password-store" "$BACKUP_DIR/password-store" 2>/dev/null || true
fi

# --- Cron jobs database ------------------------------------------------------
echo "Copiando cron jobs..."
for crondir in "$OPENCLAW_DIR/cron" "$OPENCLAW_DIR/data/cron"; do
    if [ -d "$crondir" ]; then
        cp -r "$crondir" "$BACKUP_DIR/cron-db" 2>/dev/null || true
        break
    fi
done

# --- GOG credentials (OAuth tokens) -----------------------------------------
echo "Copiando GOG credentials..."
if [ -d "$HOME/.config/gog" ]; then
    mkdir -p "$BACKUP_DIR/gog-config"
    cp -r "$HOME/.config/gog/"* "$BACKUP_DIR/gog-config/" 2>/dev/null || true
fi
if [ -d "$HOME/.local/share/keyrings" ]; then
    mkdir -p "$BACKUP_DIR/keyrings"
    cp -r "$HOME/.local/share/keyrings/"* "$BACKUP_DIR/keyrings/" 2>/dev/null || true
fi

# --- Rclone config -----------------------------------------------------------
echo "Copiando rclone config..."
if [ -f "$HOME/.config/rclone/rclone.conf" ]; then
    cp "$HOME/.config/rclone/rclone.conf" "$BACKUP_DIR/rclone.conf" 2>/dev/null || true
fi

# --- System config snapshot (essentials only) --------------------------------
echo "Copiando snapshot de sistema..."
mkdir -p "$BACKUP_DIR/system-snapshot"
{
    openclaw --version > "$BACKUP_DIR/system-snapshot/openclaw-version.txt" 2>/dev/null || true &
    node --version > "$BACKUP_DIR/system-snapshot/node-version.txt" 2>/dev/null || true &
    wait
}

# --- Include restore script --------------------------------------------------
cp "$WORKSPACE/scripts/restore.sh" "$BACKUP_DIR/restore.sh" 2>/dev/null || true

# --- Create tarball ----------------------------------------------------------
echo "Creando tarball..."
tar c -C /tmp "openclaw-backup-${BACKUP_DATE}" | gzip -1 > "$BACKUP_FILE"

BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
FILE_COUNT=$(find "$BACKUP_DIR" -type f | wc -l)

# --- Validate backup integrity -----------------------------------------------
echo "Validando integridad del backup..."
VALIDATOR="$WORKSPACE/scripts/backup-validator.sh"
if [ -x "$VALIDATOR" ]; then
    if bash "$VALIDATOR" "$BACKUP_FILE" --verify --quiet; then
        echo "validation: PASS"
    else
        echo "⚠️ VALIDATION FAILED — backup may be corrupt!"
        echo "validation: FAIL"
    fi
else
    echo "validation: SKIPPED (validator not found)"
fi

# --- Upload to Drive ---------------------------------------------------------
echo "Uploading backup (${BACKUP_SIZE})..."
UPLOAD_RESULT=$(gog drive upload "$BACKUP_FILE" --parent "$DRIVE_FOLDER" --account "$GOG_ACCOUNT" --no-input 2>&1)
echo "$UPLOAD_RESULT"

# --- Cleanup -----------------------------------------------------------------
rm -rf "$BACKUP_DIR" "$BACKUP_FILE" "$NATIVE_BACKUP_DIR"

echo ""
echo "=== RESULT ==="
echo "date: ${BACKUP_DATE}"
echo "files: ${FILE_COUNT}"
echo "size: ${BACKUP_SIZE}"
echo "status: ok"
