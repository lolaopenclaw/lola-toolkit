# Notification Batching System

## Overview

Sistema de batching de notificaciones que reduce el ruido de cron jobs y tareas automatizadas agrupando mensajes por prioridad.

## Problema Resuelto

Antes: cada cron job enviaba su propio mensaje a Telegram individualmente, creando ruido especialmente cuando varios crons corrían cerca en el tiempo (2-5 AM, lunes por la mañana).

Ahora: los crons escriben a una cola y un digest periódico agrupa y envía las notificaciones por lotes.

---

## Arquitectura

### Cola de Mensajes
- **Archivo:** `data/notification-queue.jsonl`
- **Formato:** Un JSON por línea
- **Lock:** `data/notification-queue.lock` (flock para atomicidad)

Ejemplo de línea:
```json
{"timestamp": "2026-03-25T20:55:00Z", "source": "surf-conditions", "priority": "low", "message": "Olas de 1.2m en Zarautz"}
```

### Script Principal
`scripts/notification-batcher.sh`

Dos comandos principales:
1. **add** — Añade notificación a la cola
2. **flush** — Lee, agrupa, formatea y envía digest

---

## Niveles de Prioridad

| Priority | Comportamiento | Frecuencia de Flush | Ejemplo |
|----------|----------------|---------------------|---------|
| `critical` | Envío INMEDIATO (skip batching) | Instantáneo | Gateway caído, brecha de seguridad |
| `high` | Batch cada 1 hora | Hourly | Security audit findings, cost alert |
| `medium` | Batch cada 3 horas | 3-hourly | Backup status, autoimprove results |
| `low` | Batch solo en morning report | Daily (mañana) | Surf conditions, cleanup audit |

**Flush cascada:** Cuando flusheas un nivel, también se incluyen todos los niveles más bajos.
- `flush high` → incluye `high` + `medium` + `low`
- `flush medium` → incluye `medium` + `low`
- `flush low` → solo `low`
- `flush critical` → solo `critical` (pero estos ya se enviaron instantáneamente)

---

## Uso

### Añadir Notificación a Cola

```bash
bash scripts/notification-batcher.sh add <priority> <source> <message>
```

**Ejemplos:**
```bash
# Surf conditions (low priority)
bash scripts/notification-batcher.sh add low "surf-conditions" "Olas de 1.2m en Zarautz"

# Backup status (medium priority)
bash scripts/notification-batcher.sh add medium "backup" "Backup OK: 142 files, 2.3MB"

# Security finding (high priority)
bash scripts/notification-batcher.sh add high "security-audit" "Found 2 warnings in lynis scan"

# Critical alert (sends immediately)
bash scripts/notification-batcher.sh add critical "gateway" "Gateway health check failed"
```

### Flush Digest

```bash
bash scripts/notification-batcher.sh flush <priority-level> [--telegram-chat-id CHAT_ID]
```

**Ejemplos:**
```bash
# Flush medium + low (para cron cada 3h)
bash scripts/notification-batcher.sh flush medium

# Flush high + medium + low (para cron cada 1h)
bash scripts/notification-batcher.sh flush high --telegram-chat-id -1003768820594

# Flush solo low (para morning report)
bash scripts/notification-batcher.sh flush low
```

---

## Formato de Digest

### Critical (Inmediato)
```
🚨 Critical Alert

🔐 [gateway] Gateway health check failed
```

### High (1h)
```
📬 Digest (1h) — 3 notifications

💰 [cost-alert] Daily spend: $12.50 (warn threshold)
🔐 [security-audit] Found 2 warnings in lynis scan
⚡ [rate-limit] Anthropic: 80% of hourly limit
```

### Medium (3h)
```
📬 Digest (3h) — 5 notifications

🔐 [security-audit] Found 2 warnings in lynis scan
💾 [backup] Backup OK: 142 files, 2.3MB
🔬 [autoimprove] Scripts: 3 experiments, 1 kept
🧹 [cleanup] No issues found
🌊 [surf] Zarautz: 1.2m, viento offshore
```

### Low (Morning Report)
```
🌅 Morning Report — 2 notifications

🌊 [surf-conditions] Zarautz: 1.2m, viento offshore
🧹 [cleanup-audit] All files validated, no drift
```

---

## Emojis por Source

El script mapea automáticamente sources a emojis:

| Source | Emoji | Source | Emoji |
|--------|-------|--------|-------|
| security-audit | 🔐 | backup | 💾 |
| autoimprove | 🔬 | cleanup | 🧹 |
| surf / surf-conditions | 🌊 | health | 💊 |
| cost-alert | 💰 | api-health | 🏥 |
| rate-limit | ⚡ | config-drift | ⚙️ |
| github | 🐙 | pr-review | 👀 |

Sources desconocidos usan 📌 por defecto.

---

## Integración con Cron

### Recomendado (NO implementado aún)

```bash
# Flush high cada hora
0 * * * * bash /home/mleon/.openclaw/workspace/scripts/notification-batcher.sh flush high --telegram-chat-id -1003768820594

# Flush medium cada 3 horas
0 */3 * * * bash /home/mleon/.openclaw/workspace/scripts/notification-batcher.sh flush medium --telegram-chat-id -1003768820594

# Morning report (low) a las 8:00
0 8 * * * bash /home/mleon/.openclaw/workspace/scripts/notification-batcher.sh flush low --telegram-chat-id -1003768820594
```

### Migración de Cron Jobs Existentes

**Antes:**
```bash
#!/usr/bin/env bash
result=$(check_something)
telegram-send "$result"
```

**Después:**
```bash
#!/usr/bin/env bash
result=$(check_something)
bash scripts/notification-batcher.sh add medium "source-name" "$result"
```

Ajusta la prioridad según la urgencia del mensaje.

---

## Seguridad y Atomicidad

- **flock:** Bloqueos de archivo para evitar condiciones de carrera
- **JSON Lines:** Formato JSONL (un JSON por línea) para append atómico
- **Lock file:** `data/notification-queue.lock` usado por flock
- **Rotación segura:** El flush reescribe la cola con solo los mensajes no procesados

---

## Testing

### Automated Test Suite
```bash
bash scripts/test-notification-batcher.sh
```

### Manual Tests

#### Test 1: Añadir varios mensajes
```bash
bash scripts/notification-batcher.sh add low "test-source" "Test message 1"
bash scripts/notification-batcher.sh add medium "test-source" "Test message 2"
bash scripts/notification-batcher.sh add high "test-source" "Test message 3"
```

#### Test 2: Inspeccionar cola
```bash
cat data/notification-queue.jsonl | jq .
```

#### Test 3: Flush sin enviar a Telegram
```bash
bash scripts/notification-batcher.sh flush medium
```

#### Test 4: Flush con envío a Telegram
```bash
bash scripts/notification-batcher.sh flush medium --telegram-chat-id -1003768820594
```

#### Test 5: Critical auto-flush
```bash
bash scripts/notification-batcher.sh add critical "test" "This should send immediately"
```

---

## Variables de Entorno

- `OPENCLAW_WORKSPACE` — Ruta al workspace (default: `$HOME/.openclaw/workspace`)
- `TELEGRAM_CHAT_ID` — Chat ID por defecto para flush (puede sobrescribirse con `--telegram-chat-id`)

---

## Dependencias

- `bash` (4.0+)
- `jq` (para manipulación JSON)
- `flock` (incluido en util-linux)
- `openclaw message` o `telegram-send` (para envío a Telegram)

---

## Estado Actual

✅ Script implementado (`scripts/notification-batcher.sh`)
✅ Documentación creada (`memory/notification-batching.md`)
✅ TOOLS.md actualizado
✅ Suite de tests creada (`scripts/test-notification-batcher.sh`)
✅ Todos los tests pasan
✅ **Cron jobs de flush ACTIVOS** (2026-03-26)
⏳ Migración de cron jobs existentes pendiente

---

## Cron Jobs de Flush (ACTIVOS)

### High Priority Flush (Hourly)
- **ID:** `81e5e438-48f5-4642-95f0-480655422664`
- **Name:** 📬 Notification Flush (hourly/high)
- **Schedule:** `50 * * * *` (every hour at :50)
- **Model:** haiku
- **Target:** Telegram -1003768820594:25
- **Next run:** Every hour at :50

### Medium Priority Flush (3-Hourly)
- **ID:** `529c7e09-940c-4b95-ae75-f0de2e84e41b`
- **Name:** 📬 Notification Flush (3h/medium)
- **Schedule:** `55 */3 * * *` (every 3 hours at :55)
- **Model:** haiku
- **Target:** Telegram -1003768820594:25
- **Next run:** Every 3 hours at :55

### Low Priority Flush (Morning)
- **ID:** `5d16bb07-0f7b-4d2d-a1dd-db9d0e92e2a3`
- **Name:** 📬 Notification Flush (morning/low)
- **Schedule:** `45 9 * * *` @ Europe/Madrid (9:45 AM daily)
- **Model:** haiku
- **Target:** Telegram -1003768820594:25
- **Next run:** Daily at 9:45 AM Madrid time

---

## Cron Jobs Candidatos para Migración

Estos cron jobs actualmente envían notificaciones directamente a Telegram y deberían migrarse al sistema de batching:

### High Priority (hourly flush)
- **`fdf38b8f-6d68-4798-84ea-1e2a24c61e75`** — healthcheck:security-audit (Lun 9:30)
- **`51d7437f-d216-4d03-bd37-6f00ce17967c`** — 💰 Daily Cost Alert (8 PM daily)
- Rate limit monitors (si existen)

### Medium Priority (3-hourly flush)
- **`c8522805-6bc4-451e-887b-69866ddf5b95`** — healthcheck:fail2ban-check (every 6h)
- **`78d3556f-a203-455d-b718-b9ac7c183dbc`** — healthcheck:rkhunter-check (Lun 9:10)
- **`edc0db6e-a1b3-4837-858a-68f859300614`** — healthcheck:lynis-scan (Lun 9:20)
- **`08325b21-b11d-4b15-b065-cbbc8d6b4bdb`** — 🔬 Autoresearch (si reporta)
- Backup validators/status checks

### Low Priority (morning flush)
- **`07256dbe-2161-4eb2-af22-059834407d54`** — 🧹 Cleanup audit semaphore (Domingo 10 PM)
- **`6982dc7e-1aa8-428c-9d5a-ac3a0c2cb411`** — memory-decay-weekly (Domingo 11 PM)
- **`a2cb9eec-19ab-45f8-ab18-7b1a979fec93`** — 🧠 Memory Guardian Pruner (Domingo 11 PM)
- **`f5d72c76-301e-47df-a25d-9062e4d1d019`** — 📋 Markdown Drift Checker (Lunes 5 AM)
- Surf conditions reports
- Weekly/monthly summaries

### Do NOT Migrate
- **`cb5d3743-2d8b-480b-ac64-ef030a689cf0`** — 📋 Informe Matutino (stay as-is, master digest)
- **`7a7086e5-5a3c-41ad-880b-64a25a927aae`** — 🏠 Driving Mode Auto-reset (system state, not notification)
- **`3a82af7d-4acf-4a0f-9772-46efc2895e46`** — 🔄 Auto-update OpenClaw (interactive, not reportable)
- **`ed1d9b11-5ba1-44ed-8f8b-0b359ddcd45e`** — 🔄 System Updates Nightly (system maintenance)
- Emergency/critical alerts that must arrive instantly

---

## Cómo Migrar un Cron Job

### Paso 1: Identificar el payload actual

```bash
# Ver configuración del cron
openclaw cron list | grep <cron-name-or-id>
```

### Paso 2: Determinar prioridad

- **critical** → Necesita respuesta inmediata (alertas de seguridad, fallas de gateway)
- **high** → Requiere atención en 1 hora (cost alerts, security findings)
- **medium** → Informativo, puede esperar 3h (backup status, health checks)
- **low** → FYI, puede esperar hasta la mañana (cleanup results, weekly summaries)

### Paso 3: Modificar el payload del cron

**Antes:**
```
Run security audit and report findings to Telegram.
```

**Después:**
```
Run security audit. If findings are critical, use priority 'critical'. Otherwise write to queue:
bash /home/mleon/.openclaw/workspace/scripts/notification-batcher.sh add high "security-audit" "<summary>"
Respond HEARTBEAT_OK if no critical issues.
```

### Paso 4: Actualizar el cron

```bash
openclaw cron edit <cron-id> --message "<new-payload>"
```

### Paso 5: Verificar en próxima ejecución

- Comprobar que el mensaje se añade a la cola (`cat data/notification-queue.jsonl`)
- Confirmar que aparece en el próximo digest flush
- Validar que el formato es correcto

---

## Ejemplo de Migración: Security Audit

**Antes (enviaba directamente):**
```
Payload: Run weekly security audit (lynis, rkhunter, fail2ban). 
Report findings to Telegram channel.
Delivery: announce to telegram -1003768820594
```

**Después (escribe a cola):**
```
Payload: Run weekly security audit (lynis, rkhunter, fail2ban). 
Write results to queue:
bash scripts/notification-batcher.sh add high "security-audit" "<findings-summary>"
Respond HEARTBEAT_OK.
Delivery: no-deliver (se enviará con hourly flush)
```

**Comando de actualización:**
```bash
openclaw cron edit fdf38b8f-6d68-4798-84ea-1e2a24c61e75 \
  --message "Run weekly security audit. Write results: bash scripts/notification-batcher.sh add high 'security-audit' '<summary>'. Respond HEARTBEAT_OK." \
  --no-deliver
```

---

## Próximos Pasos

1. ✅ **Cron jobs de flush creados** (2026-03-26)
2. ✅ **Migrar cron jobs uno por uno** (2026-03-26 — COMPLETADO)
   - ✅ Baja prioridad (low) — 5 crons migrados
   - ✅ Media prioridad (medium) — 7 crons migrados
   - ✅ Alta prioridad (high) — 2 crons migrados
3. ⏳ **Monitoreo (1-2 semanas):**
   - Verificar que los digests se envían correctamente
   - Ajustar frecuencias si hay demasiado/poco ruido
   - Verificar que no se pierden notificaciones importantes

---

## Migración Completada (2026-03-26)

### ✅ LOW Priority (morning flush — 9:45 AM)
1. **c780fe5d** — 🗑️ Session Log Rotation (weekly)
2. **7926a522** — 🌊 Surf Conditions Daily
3. **f5d72c76** — 📋 Markdown Drift Check (weekly)
4. **a2cb9eec** — 🧠 Memory Guardian Pro (domingo noche)
5. **07256dbe** — 🧹 Cleanup audit semanal (domingo noche)

### ✅ MEDIUM Priority (3-hourly flush — XX:55)
6. **e763c896** — 📋 Backup validation (weekly)
7. **e5ebcbf4** — 🗑️ Backup retention cleanup (lunes)
8. **ae60d161** — 🔬 Autoimprove Scripts Agent
9. **f22e5eaf** — 🔬 Autoimprove Skills Agent
10. **5645185b** — 🔬 Autoimprove Memory Agent
11. **ad5285c3** — 🔧 Lola Toolkit Sync Check
12. **4de42cb2** — 🔬 Seguimiento Autoresearch Karpathy

### ✅ HIGH Priority (hourly flush — XX:50)
13. **51d7437f** — 💰 Daily Cost Alert
14. **c8522805** — healthcheck:fail2ban-alert (currently disabled)

### ⚠️ NOT MIGRATED (by design)
- **cb5d3743** — 📋 Informe Matutino (main morning report — stays direct)
- **7a7086e5** — 🏠 Driving Mode Auto-reset (system state, no notification)
- **3a82af7d** — 🔄 Auto-update OpenClaw (interactive)
- **ed1d9b11** — 🔄 System Updates Nightly (silent)
- **ad742767** — Backup diario (silent, writes to last-backup.json)
- **53577b95** — 🧠 Memory Search Reindex (silent)
- **376288ed** — 🛡️ Healthcheck Daily (unified cron — keep direct for now)
- **bf115ea1** — 🛡️ Healthcheck Weekly (unified cron — keep direct for now)

### 📊 Migration Stats
- **Total migrated:** 14 crons
- **Low priority:** 5 crons
- **Medium priority:** 7 crons
- **High priority:** 2 crons
- **Intentionally skipped:** 8 crons (system/silent/master reports)

All migrated crons now write to the notification queue instead of announcing directly. They will be included in the next scheduled digest flush for their priority level.

---

*Creado: 2026-03-25*
*Última actualización: 2026-03-26 — Migration COMPLETED: 14 crons migrated to batching system*
