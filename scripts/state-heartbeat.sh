#!/bin/bash

# 🫀 STATE HEARTBEAT — Mantener /var/lib/openclaw/state.json actualizado
# Ejecutado cada 30 segundos por heartbeat (o manualmente)
# Propósito: Registrar que OpenClaw está vivo para boot recovery

STATE_FILE="/var/lib/openclaw/state.json"
STATE_DIR="/var/lib/openclaw"

# Crear directorio si no existe
sudo mkdir -p "$STATE_DIR" 2>/dev/null || mkdir -p "$STATE_DIR"

# Timestamp actual
NOW=$(date +%s)

# Leer último update (si existe)
if [ -f "$STATE_FILE" ]; then
  LAST_UPDATE=$(jq -r '.last_update // 0' "$STATE_FILE" 2>/dev/null || echo 0)
  SHUTDOWN_INTENT=$(jq -r '.shutdown_intent // null' "$STATE_FILE" 2>/dev/null || echo "null")
else
  LAST_UPDATE="$NOW"
  SHUTDOWN_INTENT="null"
fi

# Escribir nuevo state
cat > "$STATE_FILE" << EOF
{
  "status": "running",
  "last_alive": $NOW,
  "last_update": $LAST_UPDATE,
  "shutdown_intent": $SHUTDOWN_INTENT,
  "gateway_pid": $(pgrep -f "openclaw-gateway" | head -1 || echo "null"),
  "timestamp_iso": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# Hacer readable por todos
chmod 644 "$STATE_FILE" 2>/dev/null

if [ $? -eq 0 ]; then
  echo "✅ State updated: last_alive=$NOW"
else
  echo "⚠️  Warning: Could not write state file"
  exit 1
fi
