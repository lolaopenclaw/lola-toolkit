# Backup Validation Protocol

**Establecido:** 2026-02-21

## Qué es

Suite de validación automática que verifica la integridad de cada backup de OpenClaw antes de que sea necesario usarlo. Detecta corrupción proactivamente.

## Checks disponibles

| Check | Flag | Qué hace |
|-------|------|----------|
| **Checksum** | `--verify` | SHA256 del .tar.gz, compara con valor almacenado |
| **Size anomaly** | `--verify` | Alerta si el backup es sospechosamente pequeño |
| **Archive integrity** | `--verify` | `tar -tzf` para verificar que se puede leer |
| **Structure** | `--verify` | Verifica que archivos esperados están presentes |
| **Test restore** | `--test` | Extrae a /tmp, verifica permisos y legibilidad |
| **Auto-repair** | `--repair` | Intenta recuperar archivo corrupto (gzip recovery) |
| **Full** | `--full` | Ejecuta verify + test |

## Cuándo se ejecuta

1. **Post-backup (diario):** `backup-memory.sh` llama a `--verify` después de cada backup
2. **Semanal (lunes 5:30 AM):** Cron ejecuta `--status --full` con test restore completo

## Cómo interpretar reportes

- ✅ VALID — Backup OK, todos los checks pasaron
- ⚠️ VALID_WITH_WARNINGS — Backup funcional pero con observaciones (ej: sin checksum previo)
- ❌ INVALID — Backup corrupto o incompleto, requiere acción

## Qué hacer si falla

1. **Verificar el backup anterior** — `bash backup-validator.sh /tmp/openclaw-backup-YYYY-MM-DD.tar.gz --full`
2. **Si es corrupción de transferencia:** Re-descargar de Drive y re-validar
3. **Si es corrupción de origen:** El backup se creó mal → ejecutar backup manual inmediato
4. **Si --repair funciona:** Original se guarda como `.corrupt` para análisis
5. **Alertar a Manu** si no se puede resolver automáticamente

## Archivos

- **Script:** `scripts/backup-validator.sh`
- **Estado:** `memory/backup-validation-state.json`
- **Logs:** `memory/backup-validation-logs/`

## Cómo desactivar

- Quitar la línea de validación en `backup-memory.sh` (buscar "backup-validator")
- Desactivar cron job `backup-validation-weekly`
