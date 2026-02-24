#!/bin/bash

# 🚀 BOOT.sh — Boot Recovery & Crash Detection
# Ejecutado automáticamente al arrancar la VPS
# Detecta crashes y recupera desde snapshots o Drive backup

set -e

STATE_FILE="/var/lib/openclaw/state.json"
RECOVERY_SCRIPT="/home/mleon/.openclaw/workspace/scripts/recover-from-snapshot.sh"
LOG_FILE="/home/mleon/.openclaw/workspace/memory/$(date +%Y-%m-%d)-boot.log"
GATEWAY_STATUS_URL="http://localhost:18789/health"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log function
log() {
  local msg="$1"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $msg" | tee -a "$LOG_FILE"
}

# Telegram notification
notify_telegram() {
  local msg="$1"
  # Usar openclaw message API si está disponible
  if command -v openclaw &>/dev/null; then
    openclaw message send --channel telegram --target 6884477 "$msg" 2>/dev/null || true
  fi
}

log "════════════════════════════════════════════"
log "🚀 BOOT SEQUENCE STARTED"
log "════════════════════════════════════════════"

# ═══════════════════════════════════════════════════════════
# PASO 1: Determinar tipo de boot
# ═══════════════════════════════════════════════════════════

if [ -f "$STATE_FILE" ]; then
  log "📋 State file found: $STATE_FILE"
  
  SHUTDOWN_INTENT=$(jq -r '.shutdown_intent // null' "$STATE_FILE" 2>/dev/null || echo "null")
  LAST_ALIVE=$(jq -r '.last_alive // 0' "$STATE_FILE" 2>/dev/null || echo 0)
  GATEWAY_PID=$(jq -r '.gateway_pid // null' "$STATE_FILE" 2>/dev/null || echo "null")
  
  log "  shutdown_intent: $SHUTDOWN_INTENT"
  log "  last_alive: $LAST_ALIVE ($(date -d @$LAST_ALIVE +'%Y-%m-%d %H:%M:%S'))"
  log "  gateway_pid: $GATEWAY_PID"
else
  log "📋 No state file found (cold boot or first run)"
  SHUTDOWN_INTENT="null"
  BOOT_TYPE="cold"
fi

# Determinar tipo de boot
if [ "$SHUTDOWN_INTENT" = "clean" ]; then
  log "✅ CLEAN SHUTDOWN detected (intentional reboot)"
  BOOT_TYPE="clean"
else
  log "⚠️  CRASH DETECTED or cold boot (no clean shutdown intent)"
  BOOT_TYPE="crash"
fi

# ═══════════════════════════════════════════════════════════
# PASO 2: Recuperar si fue crash
# ═══════════════════════════════════════════════════════════

if [ "$BOOT_TYPE" = "crash" ]; then
  log ""
  log "🔧 Starting recovery procedure..."
  
  if [ ! -f "$RECOVERY_SCRIPT" ]; then
    log "❌ Recovery script not found: $RECOVERY_SCRIPT"
    log "⚠️  Proceeding with clean boot (no recovery)"
  else
    # Ejecutar recuperación
    if bash "$RECOVERY_SCRIPT" >> "$LOG_FILE" 2>&1; then
      log "✅ Recovery script completed successfully"
      RECOVERY_SUCCESS=1
      
      # Leer qué se recuperó
      RECOVERY_SOURCE=$(grep -o "Recovery successful\|DRIVE BACKUP" "$LOG_FILE" | tail -1)
      notify_telegram "🚨 Crash recovery completed ✅
      Source: $RECOVERY_SOURCE
      Check logs: memory/$(date +%Y-%m-%d)-boot.log"
    else
      log "⚠️  Recovery script exited with error"
      RECOVERY_SUCCESS=0
      notify_telegram "⚠️  Crash detected but recovery failed
      Manual intervention may be needed
      Check logs: memory/$(date +%Y-%m-%d)-boot.log"
    fi
  fi
else
  log "✅ Clean boot, skipping recovery"
  RECOVERY_SUCCESS=0
fi

# ═══════════════════════════════════════════════════════════
# PASO 3: Limpiar state file
# ═══════════════════════════════════════════════════════════

log ""
log "🧹 Cleaning up..."

rm -f "$STATE_FILE" 2>/dev/null || true
log "  State file cleared"

# ═══════════════════════════════════════════════════════════
# PASO 4: Iniciar gateway
# ═══════════════════════════════════════════════════════════

log ""
log "🚀 Starting OpenClaw gateway..."

if systemctl start openclaw-gateway 2>&1 | tee -a "$LOG_FILE"; then
  log "  systemctl start: OK"
else
  log "  ⚠️  systemctl start command exited with error (may be normal if already running)"
fi

# Esperar a que gateway esté listo
log "⏳ Waiting for gateway to be ready..."
MAX_WAIT=30
WAIT_COUNT=0

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
  if curl -s "$GATEWAY_STATUS_URL" >/dev/null 2>&1; then
    log "✅ Gateway is responding"
    GATEWAY_UP=1
    break
  fi
  
  WAIT_COUNT=$((WAIT_COUNT + 1))
  sleep 1
done

if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
  log "⚠️  Gateway did not respond after ${MAX_WAIT}s"
  log "    Checking systemd status..."
  systemctl status openclaw-gateway --no-pager >> "$LOG_FILE" 2>&1 || true
  GATEWAY_UP=0
else
  log "  Gateway ready after ${WAIT_COUNT}s"
  GATEWAY_UP=1
fi

# ═══════════════════════════════════════════════════════════
# PASO 5: Actualizar state con boot exitoso
# ═══════════════════════════════════════════════════════════

log ""
log "📝 Registering boot in state.json..."

NOW=$(date +%s)

cat > "$STATE_FILE" << EOF
{
  "status": "running",
  "last_alive": $NOW,
  "last_update": $NOW,
  "shutdown_intent": null,
  "gateway_pid": $(pgrep -f "openclaw-gateway" | head -1 || echo "null"),
  "last_boot": $NOW,
  "boot_type": "$BOOT_TYPE",
  "boot_recovery": $RECOVERY_SUCCESS,
  "timestamp_iso": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

chmod 644 "$STATE_FILE"
log "  State file created"

# ═══════════════════════════════════════════════════════════
# RESUMEN
# ═══════════════════════════════════════════════════════════

log ""
log "════════════════════════════════════════════"

if [ $GATEWAY_UP -eq 1 ]; then
  log "✅ BOOT SEQUENCE COMPLETE"
  log "   Boot type: $BOOT_TYPE"
  log "   Recovery: $([ $RECOVERY_SUCCESS -eq 1 ] && echo 'YES ✅' || echo 'NO')"
  log "   Gateway: UP & RUNNING 🟢"
  
  if [ "$BOOT_TYPE" = "clean" ]; then
    notify_telegram "✅ Clean reboot completed
    🟢 Gateway: ready
    ⏰ $(date +'%H:%M Madrid')"
  fi
else
  log "⚠️  BOOT SEQUENCE COMPLETE WITH WARNINGS"
  log "   Boot type: $BOOT_TYPE"
  log "   Recovery: $([ $RECOVERY_SUCCESS -eq 1 ] && echo 'YES ✅' || echo 'FAILED ❌')"
  log "   Gateway: NOT RESPONDING ⚠️"
  log ""
  log "📋 Check logs: $LOG_FILE"
  log "🔍 systemd logs: journalctl -u openclaw-gateway -n 50"
  
  notify_telegram "⚠️  Boot completed but gateway not responding
  Check logs: memory/$(date +%Y-%m-%d)-boot.log
  systemd: journalctl -u openclaw-gateway"
fi

log "════════════════════════════════════════════"
log ""

# Exit status
[ $GATEWAY_UP -eq 1 ] && exit 0 || exit 1
