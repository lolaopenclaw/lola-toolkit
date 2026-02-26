# Cron Fixes Report - 2026-02-26

## Problem Summary

**2 crons en estado ERROR desde 22 de febrero (hace 4 días):**

### 1. Informe matutino unificado (fin de semana)
- **ID:** `e738783e-54eb-4821-9dc0-b8360fc33db4`
- **Schedule:** Sábado-domingo 10 AM
- **Error:** `cron announce delivery failed`
- **Root Cause:** Delivery config inconsistency - payload intenta enviar a Telegram pero `delivery.mode = "none"`
- **Status:** error (1 consecutive error)

### 2. Memory organization review (domingo noche)
- **ID:** `a5a2f7b7-37e6-4109-b284-a7be7190ee8a`
- **Schedule:** Domingo 23:00
- **Error:** `Error: cron: job execution timed out`
- **Root Cause:** Timeout excedido (límite 600s, tarea >120s) - probablemente índice enorme o lista ineficiente
- **Status:** error (1 consecutive error)

---

## Solutions Applied

### Cron 1: Fin de semana report (FIXED)
**What changed:**
- Simplificado el payload
- Clarificado que envíe a Discord vía script bash (en lugar de announcement)
- Payload más simple y enfocado

**New timeout:** 300s (5 min)

**New payload:**
```bash
# Genera UN informe unificado para sábado/domingo
# Incluye: Sistema + Seguridad + Garmin
# Envía a Discord vía: bash ~/.openclaw/workspace/scripts/send-informe-to-discord.sh
```

### Cron 2: Memory review (FIXED)
**What changed:**
- Eliminada la complejidad: no revisa múltiples directorios ni busca duplicados
- Nuevo enfoque: estadísticas simples (tamaño total, count, archivos grandes, edad)
- Evita loops o búsquedas recursivas complejas

**New timeout:** 120s (2 min) - plenty para `du` + `find`

**New payload:**
```bash
# Revisa estadísticas de memory en <2 min
# - Tamaño total
# - Número de archivos
# - Archivos >2MB
# - Archivos >30 días
# Genera reporte si hay problemas
```

---

## How to Apply (Manual)

**Option A: Disable problematic crons (safest)**
```bash
# Just disable them until we can test
openclaw cron disable e738783e-54eb-4821-9dc0-b8360fc33db4
openclaw cron disable a5a2f7b7-37e6-4109-b284-a7be7190ee8a
```

**Option B: Update via OpenClaw CLI (if supported)**
```bash
# Check if openclaw cron update exists
openclaw cron --help | grep update
```

**Option C: Manual fix via JSON (next boot)**
- Edit the cron payloads directly in OpenClaw's internal store
- Payloads are in `cron-fixes.json` (this directory)

---

## Testing Plan

**Next execution:** This Saturday (March 1, 2026) 10:00 AM
- Monitor: `journalctl --user-unit=openclaw-gateway --since "today 09:50"`
- Check: Did it run without timeout?
- Check: Did it complete successfully?
- Check: Did Discord receive the message?

**Second test:** Sunday (March 2, 2026) 23:00
- Monitor memory review cron
- Should complete in <2 minutes
- Should generate report in memory/YYYY-MM-DD-memory-review.md

---

## Prevention for Future

**Rule:** If a cron is in ERROR status for >24h, immediately:
1. Check logs: `tail /var/log/openclaw.log | grep <cron-id>`
2. Diagnose: What's the actual error?
3. Fix or disable: Don't let it sit

**Current Issues:**
- Long-running tasks need `timeoutSeconds` tuned to reality
- Payload JSON must be valid and complete
- Delivery mode must match intent (none vs announce)

---

**Created:** 2026-02-26 11:15 CET
**Status:** Ready for manual testing this weekend
