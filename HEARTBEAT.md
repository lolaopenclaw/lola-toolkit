# HEARTBEAT.md — Comprobaciones Internas (Silencioso)

**NUEVA POLÍTICA (2026-02-23 09:30):** Zero-notification-if-OK

**Regla simple:**
- ✅ TODO OK → SILENCIO total (no enviar nada a Telegram)
- ❌ PROBLEMA → Alerta inmediata a Telegram

**Por defecto:** `HEARTBEAT_OK` (silencio absoluto). Solo problemas critican rompen el silencio.

Ver: `COMMUNICATION-POLICY.md` para detalles completos.

---

## Comprobaciones periódicas (sin reportar a menos que falle)

### 1. Estado de cron jobs
- Revisa si algún cron ha fallado: `cron list` → `consecutiveErrors > 0`
- Si falló: alerta a Telegram con qué falló y opciones
- Si OK: silencio

### 2. Estado del gateway
- Si error inusual en logs: alerta a Telegram
- Si OK: silencio

### 3. Tablero Kanban (Notion)
- Verifica tareas en "Pendiente" internamente
- **NO reportes estado** salvo en informe matutino
- Si hay bloqueos críticos: alerta ahora
- Si completas una tarea: actualiza en Notion (sin mensaje a Manu)

### 4. Email (Gmail)
- Revisa emails nuevos: `gog gmail search "is:unread" --max 5`
- Si hay algo crítico (breach, urgencia): alerta ahora
- Si OK: silencio

### 5. Memory size
- Ejecutar: `du -sh ~/.openclaw/workspace/memory/`
- Si >15 MB: alerta a Manu + ejecutar limpieza
- Si OK: silencio

### 6. Critical sandbox
- Check: `ls /tmp/critical-sandbox/ 2>/dev/null`
- Si hay cambios pendientes: alerta
- Si OK: silencio

### 7. Session synthesis (Signet-inspired)
- Si hubo sesión larga (>10 mensajes) desde el último heartbeat:
  - Extraer decisiones, cambios, y aprendizajes clave
  - Guardar en `memory/YYYY-MM-DD-session-synthesis.md`
  - Actualizar `memory/entities.md` si hay nuevas personas/proyectos/herramientas
- Si no hubo sesión significativa: silencio

### 8. Garmin health context
- Run: `bash ~/.openclaw/workspace/scripts/garmin-health-report.sh --current`
- **NO reportes normales** — solo factor en comunicación
- Si alerta crítica (HR muy elevado, sueño muy malo): avisa

### 9. Google Calendar tasks
- Ejecuta: `bash ~/.openclaw/workspace/scripts/calendar-tasks.sh check`
- Si hay tareas para HOY: incluir en informe matutino o avisar si es urgente
- Si hay tareas para MAÑANA: mencionar como preview
- Si "OK: No pending tasks": silencio

### 10. Fail2Ban status
- Ejecuta: `sudo fail2ban-client status sshd`
- Si <5 IPs baneadas: silencio
- Si 5-10 IPs: guardar para informe matutino
- Si ≥10 IPs: alerta CRÍTICA ahora

---

## Resumen

**Regla simple:**
- ✅ Todos los chequeos se hacen internamente
- ❌ Ningún reporte rutinario a Telegram
- 🚨 Problemas críticos: alerta inmediata
- 📋 Informe completo: una vez al día por la mañana (9-10 AM)

## 🔄 Heartbeat Mejorado (Decisión 2026-02-22 14:13)

**Cada 30 minutos (durante tareas largas):**
- ✅ Si estoy en tarea: reportar progreso específico
- ✅ Si no hay tareas: silencio (HEARTBEAT_OK)
- ⛔ Horario silencioso 23:00-07:00 Madrid: NUNCA reportar

**Ejemplo:**
- 14:30: "Paso 6/8: Rellenando Garmin en Sheets..."
- 15:00: "Paso 7/8: Creando gráficas..."
- 15:30: "Completado: Sheets lista, compartiendo..."

Beneficio: Manu sabe que estoy trabajando sin andar preguntando.

