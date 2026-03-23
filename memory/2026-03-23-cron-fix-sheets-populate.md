# Fix: Cron Job sheets-populate-v2.py

**Fecha:** 2026-03-23 10:14 CET
**Acción:** Desactivación de cron job roto
**Estado:** ✅ Resuelto

## Problema

El cron job "📊 Populate Google Sheets v2" (ID: `6344d609-2bfd-4295-8471-373125381779`) estaba ejecutándose diariamente a las 09:30 pero fallaba porque referenciaba un script que no existía en la ruta esperada:

```bash
python3 /home/mleon/.openclaw/workspace/scripts/sheets-populate-v2.py
```

El cron venía generando errores desde hace varios días, reportando que el script no existía.

## Investigación

1. **Revisé el listado de crons:** Identifiqué el cron job problemático
2. **Busqué el script:** Confirmé que `scripts/sheets-populate-v2.py` no existía en su ubicación esperada
3. **Encontré el script archivado:** El script existe pero fue movido intencionalmente a `scripts/archive/sheets-populate-v2.py` (19KB, fecha 2026-02-23)

## Decisión

Dado que el script fue **archivado intencionalmente** (movido a `archive/`), la acción correcta fue **desactivar el cron job** en lugar de restaurar el script.

## Acción Tomada

```bash
openclaw cron disable 6344d609-2bfd-4295-8471-373125381779
```

El cron job ahora está desactivado (`enabled: false`) pero preservado en el sistema por si se necesita reactivar en el futuro.

## Scripts Relacionados Disponibles

Estos scripts SÍ existen y están activos:
- `garmin-activities-to-sheets.py` — Sincroniza actividades Garmin a Google Sheets
- Otros scripts de integración con Google Sheets en `scripts/`

## Contexto del Cron

El cron ejecutaba dos tareas:
1. **Consumo IA (hoy):** Poblaba datos de uso de IA en Google Sheets
2. **Garmin Health (ayer):** Poblaba datos de salud de Garmin en Google Sheets

Si estas funcionalidades se necesitan de nuevo, habría que:
1. Restaurar el script desde `archive/` a `scripts/`
2. Reactivar el cron: `openclaw cron enable 6344d609-2bfd-4295-8471-373125381779`

## Actualización de Memoria

✅ Marcado como completado en `memory/pending-actions.md` con fecha 2026-03-23
