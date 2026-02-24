# BOOT.md — Arranque y Recuperación del Gateway

El gateway acaba de arrancar (o reiniciar). Sigue este protocolo:

---

## 1️⃣ Detectar Tipo de Arranque

```bash
STATE_FILE="/var/lib/openclaw/state.json"

if [ -f "$STATE_FILE" ]; then
  SHUTDOWN_INTENT=$(jq -r '.shutdown_intent // null' "$STATE_FILE" 2>/dev/null)
else
  SHUTDOWN_INTENT="null"
fi

if [ "$SHUTDOWN_INTENT" = "clean" ]; then
  # Fue shutdown INTENCIONAL (sudo reboot)
  BOOT_TYPE="clean"
else
  # Fue CRASH o arranque de frio
  BOOT_TYPE="crash"
fi
```

---

## 2️⃣ Si fue CRASH → Recuperar desde Snapshot

Si `BOOT_TYPE = "crash"`:

```bash
echo "🚨 Crash detected, attempting recovery..."

bash /home/mleon/.openclaw/workspace/scripts/recover-from-snapshot.sh

# recover-from-snapshot.sh:
# 1. Intenta snapshot 1, 2, 3 (en orden)
# 2. Valida SHA256 de cada uno
# 3. Si todos fallan → restaura desde Drive backup
# 4. Reporta a Telegram resultado
```

**Flujo de recuperación:**
```
CRASH
  ↓
[Boot] Lee state.json
  ↓
shutdown_intent ≠ "clean"
  ↓
Restaurar desde snapshot
  ├─ Snapshot 1 (más reciente)
  │   └─ SHA256 OK? → Restaurar y exit
  │       └─ SHA256 fail? → Siguiente
  ├─ Snapshot 2
  │   └─ SHA256 OK? → Restaurar y exit
  │       └─ SHA256 fail? → Siguiente
  ├─ Snapshot 3
  │   └─ SHA256 OK? → Restaurar y exit
  │       └─ SHA256 fail? → Siguiente
  └─ Todos fallan?
      └─ Drive backup (fallback)
        └─ Restaurar desde backup más reciente
        └─ Reportar a Telegram
```

---

## 3️⃣ Si fue SHUTDOWN LIMPIO → Boot Normal

Si `BOOT_TYPE = "clean"`:

```bash
echo "✅ Clean shutdown detected, booting normally"

# Limpiar flag de shutdown
rm -f "$STATE_FILE"

# Boot normal
systemctl start openclaw-gateway
```

---

## 4️⃣ Reportar a Telegram

**Siempre reportar (crash o clean):**

```bash
if [ "$BOOT_TYPE" = "crash" ]; then
  message="🚨 Crash detected and recovered from snapshot
  ✅ Recovered from: [snapshot o Drive]
  ⏰ State from: [timestamp]
  
  Check memory/2026-02-24-recovery.log for details"
else
  message="✅ Clean reboot completed
  ⏰ Time: $(date +'%H:%M Madrid')
  🟢 Gateway: ready"
fi

# Enviar a Telegram (via openclaw API o script)
```

---

## 5️⃣ Iniciar Gateway

```bash
systemctl start openclaw-gateway

# Esperar a que arraque
sleep 5

# Validar
curl -s http://localhost:18789/health

if [ $? -eq 0 ]; then
  echo "✅ Gateway is running"
else
  echo "⚠️  Gateway didn't respond, checking logs..."
  journalctl -u openclaw-gateway -n 20
fi
```

---

## 📝 Procedimiento Paso a Paso (para BOOT.md hook)

```bash
#!/bin/bash
# Este script se ejecuta automáticamente al boot

set -e

STATE_FILE="/var/lib/openclaw/state.json"
LOG_FILE="/home/mleon/.openclaw/workspace/memory/$(date +%Y-%m-%d)-boot.log"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Boot sequence started" >> "$LOG_FILE"

# 1. Determinar tipo de boot
if [ -f "$STATE_FILE" ]; then
  SHUTDOWN_INTENT=$(jq -r '.shutdown_intent // null' "$STATE_FILE" 2>/dev/null || echo "null")
else
  SHUTDOWN_INTENT="null"
fi

if [ "$SHUTDOWN_INTENT" = "clean" ]; then
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] Clean shutdown detected" >> "$LOG_FILE"
  BOOT_TYPE="clean"
else
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] Crash detected" >> "$LOG_FILE"
  BOOT_TYPE="crash"
fi

# 2. Recuperar si fue crash
if [ "$BOOT_TYPE" = "crash" ]; then
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] Attempting recovery from snapshot..." >> "$LOG_FILE"
  
  bash /home/mleon/.openclaw/workspace/scripts/recover-from-snapshot.sh >> "$LOG_FILE" 2>&1
  
  RECOVERY_STATUS=$?
  if [ $RECOVERY_STATUS -eq 0 ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ Recovery successful" >> "$LOG_FILE"
  else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  Recovery failed (exit code: $RECOVERY_STATUS)" >> "$LOG_FILE"
  fi
fi

# 3. Limpiar flag
rm -f "$STATE_FILE" 2>/dev/null || true

# 4. Iniciar gateway
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Starting gateway..." >> "$LOG_FILE"
systemctl start openclaw-gateway

sleep 3

# 5. Validar
if curl -s http://localhost:18789/health >/dev/null 2>&1; then
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ Gateway is running" >> "$LOG_FILE"
  
  # Reportar a Telegram (via openclaw hooks)
  if [ "$BOOT_TYPE" = "crash" ]; then
    openclaw-send-message "🚨 Crash recovery completed" "telegram:6884477"
  fi
else
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ Gateway failed to start" >> "$LOG_FILE"
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Boot sequence complete" >> "$LOG_FILE"
```

---

## 🔧 Configuración Necesaria

### Hook en systemd

```bash
# /etc/systemd/system/openclaw-boot-recovery.service

[Unit]
Description=OpenClaw Boot Recovery
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/home/mleon/.openclaw/workspace/BOOT.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

---

## 📊 Estado Después de Boot

Después de completar este proceso:

- ✅ Estado recuperado (si fue crash)
- ✅ Gateway iniciado
- ✅ Telegram notificado
- ✅ Logs registrados en memory/YYYY-MM-DD-boot.log

---

## 🆘 Troubleshooting

**Gateway no arranca después de recovery:**
```bash
journalctl -u openclaw-gateway -n 30 --no-pager

# Si hay errores:
# 1. Revisar si snapshot se restauró correctamente
# 2. Validar integridad de archivos en workspace
# 3. Ejecutar manual restore desde Drive backup
```

**State file corrupto:**
```bash
# Simplemente borrarlo (será recreado)
rm /var/lib/openclaw/state.json

# Boot asumirá crash (seguro)
# Si fue reboot intencional, simplemente arrancará
```

---

## 🚀 Flujo Completo Resumen

```
VPS Arranca
    ↓
BOOT.md Hook se ejecuta
    ↓
¿Hay state.json con shutdown_intent="clean"?
    ├─ SÍ (reboot intencional)
    │   └─ Boot normal, sin recuperación
    └─ NO (crash)
        └─ recover-from-snapshot.sh
            ├─ Snapshot 1,2,3 válidos? → Restaurar
            └─ Todos corruptos? → Drive backup
            ↓
            ✅ Workspace restaurado
    ↓
Iniciar gateway
    ↓
Reportar a Telegram
    ↓
✅ Listo
```

---

**Versión:** 1.0  
**Creado:** 2026-02-24  
**Estado:** Ready for implementation
