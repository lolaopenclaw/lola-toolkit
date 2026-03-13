# 🔄 Backup Retention Policy — 2026-02-21

**Decisión:** Manu  
**Objetivo:** Mantener respaldo consistente sin colapsar Google Drive  
**Implementación:** Cron automático + monitoreo

---

## Regla Principal

**Guardar: Últimos 30 días de todos los backups**  
**Eliminar: Automáticamente después de 30 días**

---

## Backups Cubiertos

Aplica a TODO tipo de backup en `grive_lola:openclaw_backups/`:
- ✅ `openclaw-backup-YYYY-MM-DD.tar.gz` (diario 4:00 AM)
- ✅ `cleanup-backup-YYYY-MM-DD.tar.gz` (limpieza VPS)
- ✅ Cualquier otro backup futuro

---

## Timeline por Backup

| Evento | +0 días | +15 días | +30 días | +31 días |
|--------|---------|----------|----------|----------|
| Backup creado | ✅ | ✅ | ✅ | ❌ Eliminado |
| Disponible para recuperación | Sí | Sí | Sí | No |

---

## Automatización

### Cron: Lunes 5:30 AM (antes del informe matutino)

```bash
# Pseudocódigo
1. Lista todos los .tar.gz en openclaw_backups/
2. Para cada archivo:
   - Calcula edad: (HOY - fecha_creación)
   - Si edad > 30 días:
     a. Verifica que haya un backup más reciente
     b. Elimina el archivo antiguo
     c. Documenta en log
3. Genera resumen (cuántos eliminados, espacio liberado)
```

**Seguridad:**
- No elimina si es el ÚNICO backup
- Documentación antes de borrar
- Reporte de cambios disponible

---

## Capacidad Drive

### Proyección Mensual

**Backups típicos por mes:**
- 30 diarios: `openclaw-backup-*.tar.gz` (~4-5 GB/mes)
- 4-5 limpiezas: `cleanup-backup-*.tar.gz` (~2.5 GB × 5 = 12.5 GB/mes)
- **Total sin rotación:** 17.5 GB/mes = implosión

**Con rotación (30 días):**
- Máximo simultáneo: ~10 GB (2-3 backups vigentes)
- Nunca llena el Drive
- ✅ Sostenible

---

## Recuperación

**Si necesito restaurar:**
1. Compruebo que el backup está en Drive (vigente)
2. Bajo el `.tar.gz`
3. Ejecuto script restore
4. Restauración completa

**Si necesito recuperar algo >30 días antiguo:**
- NO está en Drive (ya eliminado)
- ❌ Recuperación imposible
- **Lección:** Hacer backup manual antes de cambios críticos

---

## Política Complementaria

- **Backup diario:** 4:00 AM automático (incluye TODO)
- **Backup puntual:** Antes de cambios críticos (SSH, firewall, etc.)
  - Manual: `bash ~/.openclaw/workspace/scripts/backup-memory.sh`
  - Se guarda en Drive con nombre especial
- **Limpieza de caché:** Genera backup comprimido (incluido en rotación 30 días)

---

## Monitoreo Semanal

**En próxima revisión de memoria (domingo 23:00):**
- Verificar que cron de limpieza funcione
- Reporte de espacios liberados
- Alertar si Drive se llena

---

## Excepciones

¿Cuándo NO aplicar 30 días?
- Backup ANTES de cambio crítico (SSH, firewall) → conservar hasta que cambio se estabilice
- Backup de hito importante (restauración completa verificada) → opcionalmente conservar más

**Decisión:** Manu decide caso por caso

---

**Implementación:** 2026-02-21  
**Próxima revisión:** 2026-03-21 (30 días después)
