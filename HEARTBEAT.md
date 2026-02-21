# HEARTBEAT.md

## Comprobaciones periódicas

### 1. Estado de cron jobs
Revisa si algún cron ha fallado desde la última comprobación:
- Usa `cron list` y comprueba si hay `consecutiveErrors > 0` o `lastStatus: "error"`
- Si alguno ha fallado, avisa a Manu por Telegram con: qué falló, por qué, y opciones para solucionarlo

### 2. Estado del gateway
- Si detectas algo inusual (errores en logs, servicio degradado), avisa a Manu

### 3. Tablero Kanban (Notion)
- Consulta el tablero: `POST /databases/30c676c3-86c8-81ac-b2bd-cd2d8a5516f7/query` con `Notion-Version: 2022-06-28`
- Filtra tareas en estado "Pendiente" (no archivadas)
- Si hay tareas pendientes y tienes hueco: coge UNA, muévela a "En progreso", trabaja en ella con **Haiku** (spawn sub-agent con model haiku), y cuando termines muévela a "Hecho"
- Añade comentario en cada cambio de estado con timestamp
- NO toques tareas en "Ideas" — esas solo se mueven a Pendiente cuando Manu lo aprueba
- Si completas una tarea, avisa a Manu por Telegram con un resumen breve

### 4. Email (Gmail)
- Revisa emails nuevos: `gog gmail search "is:unread" --max 5`
- Si hay algo relevante (comparticiones de Drive, notificaciones de Notion, mensajes importantes), avisa a Manu
- No avisar de spam o newsletters

### 5. Archivado automático de tareas
- **Tareas en "Hecho":** Consulta las que tienen Archivado=false y Actualizado hace >7 días. Marca Archivado=true y añade comentario "📦 Archivada automáticamente — $(date +%d\ %b)"
- **Tareas en "Descartado":** Consulta las que tienen Archivado=false. Márcalas Archivado=true inmediatamente (sin esperar 7 días)
- Query para Hecho: `curl -s -X POST "https://api.notion.com/v1/databases/30c676c3-86c8-81ac-b2bd-cd2d8a5516f7/query" -H "Authorization: Bearer $NOTION_API_KEY" -H "Notion-Version: 2022-06-28" -H "Content-Type: application/json" -d '{"filter":{"and":[{"property":"Estado","select":{"equals":"Hecho"}},{"property":"Archivado","checkbox":{"equals":false}}]}}'`
- Query para Descartado: `curl -s -X POST "https://api.notion.com/v1/databases/30c676c3-86c8-81ac-b2bd-cd2d8a5516f7/query" -H "Authorization: Bearer $NOTION_API_KEY" -H "Notion-Version: 2022-06-28" -H "Content-Type: application/json" -d '{"filter":{"and":[{"property":"Estado","select":{"equals":"Descartado"}},{"property":"Archivado","checkbox":{"equals":false}}]}}'`

### 6. Entregas pendientes
- Si un cron con delivery=announce terminó OK pero Manu no recibió el mensaje (por reinicio del gateway u otro motivo), reenvíalo manualmente con `message send`
- Tras cada reinicio del gateway, comprueba si había crons o entregas pendientes

### 6. Memory Bloat Check
- Ejecutar: `du -sh ~/.openclaw/workspace/memory/`
- Si >10 MB: avisar a Manu y sugerir `bash scripts/memory-guardian.sh --analyze`
- Si >15 MB: ejecutar `bash scripts/memory-guardian.sh --dry-run --clean` y reportar

### 7. Backup Validation Status
- Revisa `memory/backup-validation-state.json`
- Si `lastStatus` es "INVALID": alertar a Manu inmediatamente
- Si no hay validaciones en >7 días: ejecutar `bash scripts/backup-validator.sh --status`
- Solo alertar si hay problemas

### Reglas
- SÉ PROACTIVA: no esperes a que Manu diga que algo falló. Verifica, detecta y avisa tú primero
- Solo avisar si hay algo que reportar. Si todo está bien, HEARTBEAT_OK
- Horario silencioso: 23:00-08:00 Madrid (no avisar salvo urgencias)
- No repetir alertas ya enviadas (si ya avisaste de un fallo y no se ha arreglado, no vuelvas a avisar)
