#!/bin/bash

# 🛑 CLEAN SHUTDOWN — Marcar shutdown intencional en state.json
# Ejecutado ANTES de apagar la VPS o rebootear
# Permite boot recovery distinguir shutdown intencional de crash

STATE_FILE="/var/lib/openclaw/state.json"
STATE_DIR="/var/lib/openclaw"

# Crear directorio si no existe
sudo mkdir -p "$STATE_DIR" 2>/dev/null || mkdir -p "$STATE_DIR"

NOW=$(date +%s)

echo "🛑 Marking clean shutdown..."

# Escribir estado de shutdown limpio
cat > "$STATE_FILE" << EOF
{
  "status": "stopping",
  "last_alive": $NOW,
  "last_update": $NOW,
  "shutdown_intent": "clean",
  "gateway_pid": null,
  "timestamp_iso": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

chmod 644 "$STATE_FILE" 2>/dev/null

echo "✅ Clean shutdown marked"
echo "ℹ️  Waiting 2 seconds before shutdown..."
sleep 2

echo "🔴 Stopping OpenClaw gateway..."
sudo systemctl stop openclaw-gateway 2>/dev/null || true

echo "✅ Shutdown complete"
