# Auto-update + Log Review Implementation

**Fecha de implementación:** 2026-03-24
**Estado:** ✅ Completado y operacional

---

## Resumen

Dos nuevos crons de mantenimiento proactivo para OpenClaw:

1. **Auto-update OpenClaw** (21:30 Madrid) — Actualiza automáticamente OpenClaw a la última versión stable
2. **Log Review Matutino** (07:30 Madrid) — Revisa logs nocturnos y detecta problemas

---

## Cron 1: Auto-update OpenClaw

### Schedule
- **Horario:** 21:30 todos los días (Europe/Madrid)
- **Cron expression:** `30 21 * * *`
- **Target:** isolated session
- **ID:** `3a82af7d-4acf-4a0f-9772-46efc2895e46`

### Comportamiento

1. **Check de versión:**
   - Compara versión actual (`openclaw --version`) con la última disponible (`npm view openclaw version`)
   - Si no hay update → exit silencioso

2. **Safety checks:**
   - Verifica que no haya subagents corriendo
   - Si hay subagents activos → cancela update

3. **Si hay update disponible:**
   - Descarga changelog desde GitHub releases API
   - Guarda resumen en `memory/openclaw-updates.md`
   - Ejecuta: `npm i -g openclaw@latest`
   - Envía SIGUSR1 al gateway (restart automático)
   - Notifica a Telegram (silent) con changelog principal

4. **Notificación:**
   - Formato: `versión_anterior → versión_nueva`
   - Incluye extracto del changelog
   - Link a release completo en GitHub
   - Silent notification (no despierta)

### Script
`scripts/auto-update-openclaw.sh`

### Restricciones
- ✅ Solo versiones stable (no beta/pre-release)
- ✅ No actualiza si hay subagents running
- ✅ Timeout de 120 segundos
- ✅ Fuera de quiet hours (21:30 vs 00:00-07:00)

---

## Cron 2: Log Review Matutino

### Schedule
- **Horario:** 07:30 todos los días (Europe/Madrid)
- **Cron expression:** `30 7 * * *`
- **Target:** isolated session
- **ID:** `368b84ad-e8fb-4c4a-a141-5f03f4465c86`

### Comportamiento

1. **Lee logs de la noche:**
   - Período: 22:00 del día anterior → 07:30 del día actual
   - Fuente: `journalctl --user -u openclaw-gateway`

2. **Busca problemas:**
   - **Errors:** Líneas con "error" / "ERROR"
   - **Warnings:** Líneas con "warning" / "WARN"
   - **Crashes:** "crash", "segfault", "fatal", "SIGTERM", "SIGKILL"
   - **Reinicios inesperados:** Más de 1 start en el período
   - **Cron failures:** Checks específicos para autoimprove y backup

3. **Si detecta problemas:**
   - Guarda report en `memory/log-review-YYYY-MM-DD.md`
   - Notifica a Telegram con resumen:
     - Número de errores
     - Número de crashes
     - Reinicios inesperados
     - Problemas con crons
   - Link al archivo de detalles

4. **Si todo está OK:**
   - No hace nada (silent success)
   - No guarda archivo
   - No envía notificación

### Script
`scripts/log-review.sh`

### Restricciones
- ✅ Solo notifica si hay problemas (no spam)
- ✅ 07:30 es después de quiet hours (00:00-07:00)
- ✅ Timeout de 60 segundos
- ✅ Graceful degradation si systemd no está configurado

---

## Verificación

### Test manual

```bash
# Test auto-update
cd /home/mleon/.openclaw/workspace
bash scripts/auto-update-openclaw.sh

# Test log review
bash scripts/log-review.sh
```

### Verificar crons

```bash
openclaw cron list | grep -E "(Auto-update|Log Review)"
```

### Archivos clave

- **Scripts:** `scripts/auto-update-openclaw.sh`, `scripts/log-review.sh`
- **Memory:** `memory/openclaw-updates.md` (historial de updates)
- **Logs de problemas:** `memory/log-review-YYYY-MM-DD.md` (solo cuando hay issues)
- **Cron config:** `~/.openclaw/cron/jobs.json`

---

## Notas de implementación

### Primera ejecución (2026-03-24)
- Auto-update detectó nueva versión: `2026.3.23 → 2026.3.23-2`
- Update exitoso
- Changelog guardado en `memory/openclaw-updates.md`
- Gateway reiniciado correctamente

### Log review
- Script funciona correctamente
- No hay logs de systemd actualmente (gateway no corre como servicio)
- Degradación graceful: informa pero no falla

---

## Mejoras futuras

- [ ] Considerar notificar también cuando hay updates grandes (major/minor)
- [ ] Agregar threshold configurable para warnings (actualmente > 5)
- [ ] Integrar con health-dashboard para métricas
- [ ] Considerar backup automático antes de updates

---

_Implementado por: Lola (subagent)_
_Task ID: 90256ebf-5fcc-4f8f-9c9e-de8352963154_
