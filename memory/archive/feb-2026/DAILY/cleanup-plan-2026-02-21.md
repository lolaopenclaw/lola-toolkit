# 🧹 Plan de Limpieza — 21 febrero 2026

## Ejecución

### Fase 1: Backup (HOY 21 FEB)
✅ **Completado:**
- Comprimido: `cleanup-backup-2026-02-21.tar.gz` (2.5 GB)
- Ubicación: `/tmp/cleanup-backup-2026-02-21.tar.gz`
- Contenido:
  - `.cache/Homebrew/portable-ruby-*` (2.0 GB)
  - `.cache/google-chrome/` (1.0 GB)
  - `.cache/go-build/` (279 MB)
  - `.cache/uv/` (79 MB)
  - `.cache/pip/` (20 MB)
  - `.cache/fontconfig/`
  - `.cache/gstreamer-1.0/`
  - `.cache/google-chrome-gui/`
  - `google-chrome-stable_current_amd64.deb` (67 MB)
  - `.claude.json.backup.*` files
  
**Excluido (MANTENER):**
- `.cache/whisper/` — Necesario para speech-to-text

⏳ **En progreso:** Subiendo a Google Drive (`openclaw_backups`)

### Fase 2: Borra local (PENDIENTE TU CONFIRMACIÓN)
Una vez que confirmes, ejecutaré:
```bash
rm -rf /home/mleon/.cache/Homebrew/
rm -rf /home/mleon/.cache/google-chrome/
rm -rf /home/mleon/.cache/go-build/
rm -rf /home/mleon/.cache/uv/
rm -rf /home/mleon/.cache/pip/
rm -rf /home/mleon/.cache/fontconfig/
rm -rf /home/mleon/.cache/gstreamer-1.0/
rm -rf /home/mleon/.cache/google-chrome-gui/
rm /home/mleon/google-chrome-stable_current_amd64.deb
rm /home/mleon/.claude.json.backup.*
```

**Espacio liberado:** ~3.4 GB

### Fase 3: Tarea semanal automática
✅ **Cron creado:**
- **Cuándo:** Domingos 22:00 (Europe/Madrid)
- **Qué hace:** Auditoría automática (sin borrar nada)
- **Genera:** `/home/mleon/.openclaw/workspace/memory/YYYY-MM-DD-cleanup-audit.md`

✅ **Informe matutino actualizado:**
- **Cuándo:** Lunes 9:00 AM (entre semana)
- **Qué incluye:** Sección 4 con cleanup audit
- **Cómo funciona:**
  1. Lee el audit del domingo
  2. Pregunta: "🧹 ¿Quieres que borre esto sí/no?"
  3. Espera tu respuesta
  4. Si dices "sí" → lo borra automáticamente
  5. Si dices "no" → lo deja

✅ **Tarea en Notion:**
- ID: nueva (creada 2026-02-21)
- Estado: Fondo
- Frecuencia: Semanal
- Descripción: Cleanup audit automático

## Recuperación

Si necesitas recuperar algo:
1. **Archivo en Drive:** `openclaw_backups/cleanup-backup-2026-02-21.tar.gz`
2. **Comando de recuperación:**
   ```bash
   rclone copy "grive_lola:openclaw_backups/cleanup-backup-2026-02-21.tar.gz" /tmp/
   cd /home/mleon && tar -xzf /tmp/cleanup-backup-2026-02-21.tar.gz
   ```
3. **Después:** Puedes eliminar el backup de Drive cuando estés seguro

## Timeline
- **21 feb:** Backup → Drive (HOY)
- **22 feb:** Primer cleanup audit automático (domingo 22:00)
- **24 feb:** Primer reporte + pregunta (lunes 9:00)
- **23 mar:** ⏰ **RECORDATORIO: Borrar backup de Drive** (30 días después)
- **30+ días:** Backup disponible en Drive para recuperación

---
**Status:** ✅ Completado
- Local files borrados: 3.4 GB liberados
- Backup guardado: `cleanup-backup-2026-02-21.tar.gz` en `openclaw_backups/`
- Política: Borrar del Drive después de 30 días (2026-03-23)
