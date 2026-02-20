# BOOT.md — Arranque del Gateway

El gateway acaba de arrancar (o reiniciar). Haz lo siguiente:

1. Comprueba el estado del sistema:
   - `uptime` para saber cuánto lleva encendida la VPS
   - `journalctl --user -u openclaw-gateway --since "10 minutes ago" --no-pager -q` para ver si hubo crash
   - `last reboot | head -3` para ver reboots recientes
2. Envía UN mensaje por Telegram a Manu (chat ID: 6884477) con:
   - Hora actual (UTC y Madrid)
   - Motivo probable: reboot de VPS, crash del gateway, reinicio manual, o desconocido
   - Tiempo de caída aproximado (si se puede estimar)
3. No hagas nada más. No leas memoria ni ejecutes otras tareas.
