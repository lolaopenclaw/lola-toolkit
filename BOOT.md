# BOOT.md — Arranque del Gateway

El gateway acaba de arrancar (o reiniciar). Haz lo siguiente:

1. Comprueba el estado del sistema:
   - `uptime` para saber cuánto lleva encendida la VPS
   - `journalctl --user -u openclaw-gateway --since "10 minutes ago" --no-pager -q` para ver si hubo crash
   - `last reboot | head -3` para ver reboots recientes

2. **NUEVO: Recuperación WAL (Write-Ahead Log)**
   - Ejecuta: `bash ~/.openclaw/workspace/scripts/wal-logger.sh validate`
   - Si hay errores de integridad: `bash ~/.openclaw/workspace/scripts/wal-logger.sh replay --dry-run`
   - Si logs están OK: continuar normalmente
   - Si logs están corrupted: restaurar desde último snapshot + replay

3. Envía UN mensaje por Telegram a Manu (chat ID: 6884477) con:
   - Hora actual (UTC y Madrid)
   - Motivo probable: reboot de VPS, crash del gateway, reinicio manual, o desconocido
   - Tiempo de caída aproximado (si se puede estimar)
   - **Status WAL:** ✅ OK / ⚠️ Recovered / ❌ Error (si aplica)

4. No hagas nada más. No leas memoria ni ejecutes otras tareas.
