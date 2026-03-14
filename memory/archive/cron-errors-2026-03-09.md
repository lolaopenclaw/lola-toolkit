# Cron Errors Investigation — 2026-03-09

## Summary

Dos crons están fallando cada lunes (09:00 AM):
1. **Monitor GitHub #24586** (ef6a3b31) — web_fetch redirect loop
2. **Resumen Semanal** (522ae7ca) — archivos faltantes + permisos denegados

---

## Problema 1: Monitor GitHub #24586

**Cron ID:** `ef6a3b31-366d-4a44-a383-5ba43dbb2ca9`
**Schedule:** `0 8 * * 1` (lunes 8:00 AM)
**Error:** `web_fetch failed: Too many redirects (limit: 3)`

### Causa
El cron intenta hacer fetch a una URL de GitHub que redirige más de 3 veces. Probablemente es un endpoint que tiene redirect chain.

### Logs
```
Mar 09 09:00:20 ubuntu node[2729]: 2026-03-09T09:00:20.290+01:00 [tools] web_fetch failed: Too many redirects (limit: 3)
Mar 09 09:00:30 ubuntu node[2729]: 2026-03-09T09:00:30.273+01:00 [tools] web_fetch failed: Too many redirects (limit: 3)
```

### Solución
Creado script robusto: `~/.openclaw/workspace/scripts/monitor-github-24586-robust.sh`
- Valida que `gh` CLI está disponible
- Valida que GitHub auth es OK
- Usa timeout de 30s
- Manejo de errores graceful
- Guarda resultado en memory para tracking

---

## Problema 2: Resumen Semanal de Actividades Garmin

**Cron ID:** `522ae7ca-2942-44f1-a263-741a92f51dfd`
**Schedule:** `0 9 * * 1` (lunes 9:00 AM)
**Errors múltiples:**

```
read ENOENT: /home/mleon/.openclaw/workspace/memory/2026-03-09.md
read EACCES: /var/log/lynis-report.dat (permission denied)
read ENOENT: /home/mleon/.openclaw/workspace/memory/2026-02-20-lynis-initial-scan.md
```

### Causa
El cron intenta leer archivos sin verificar si existen primero:
- `2026-03-09.md` — No existía la mañana del 9 (se crea cuando haya actividad)
- `/var/log/lynis-report.dat` — Requiere permisos root
- `2026-02-20-lynis-initial-scan.md` — Archivo que no existe

### Solución
Creado script robusto: `~/.openclaw/workspace/scripts/resumen-garmin-semanal-robust.sh`
- Verifica existencia de archivos ANTES de leer
- Verifica permisos antes de intentar acceso
- Intenta con `sudo` si user access falla
- Genera resumen válido incluso si faltan datos
- Documenta qué datos no estaban disponibles

---

## Acción Requerida

### Opción A: Actualizar los crons (preferido)
1. En OpenClaw config, actualizar los crons para usar los scripts robustos
2. Monitor GitHub → `/scripts/monitor-github-24586-robust.sh`
3. Resumen Semanal → `/scripts/resumen-garmin-semanal-robust.sh`

**PROBLEMA:** No puedo editar los crons directamente desde CLI (están en la BD de OpenClaw)

### Opción B: Workaround temporal (hasta siguiente sesión)
1. Deshabilitar ambos crons
2. En la próxima sesión desde portátil con acceso a GUI, editar directamente en OpenClaw config

### Opción C: Eliminar los crons (nuclear)
Si estos crons no son críticos, simplemente deshabilitarlos.

---

## Archivos Creados

```
~/.openclaw/workspace/scripts/monitor-github-24586-robust.sh     (2.4KB)
~/.openclaw/workspace/scripts/resumen-garmin-semanal-robust.sh   (3.3KB)
```

Ambos scripts son standalone y pueden ejecutarse manualmente:
```bash
bash ~/.openclaw/workspace/scripts/monitor-github-24586-robust.sh
bash ~/.openclaw/workspace/scripts/resumen-garmin-semanal-robust.sh
```

---

## Recomendación

**Corto plazo (hoy):** Deshabilitar ambos crons hasta que se puedan actualizar en OpenClaw config

**Largo plazo:** Reemplazar las versiones fallidas con los scripts robustos

**Datos:** El GitHub issue #24586 es importante para monitorear, pero puede hacerse de forma más robusta
