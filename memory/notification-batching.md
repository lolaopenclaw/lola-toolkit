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
⏳ Cron jobs de flush pendientes (se crearán después)
⏳ Migración de cron jobs existentes pendiente

---

## Próximos Pasos

1. **Crear cron jobs de flush:**
   - Hourly flush (high)
   - 3-hourly flush (medium)
   - Morning report (low, 8:00 AM)

2. **Migrar cron jobs existentes:**
   - Identificar todos los crons que envían a Telegram directamente
   - Reemplazar `telegram-send` / `openclaw message send` con `notification-batcher.sh add`
   - Asignar prioridades adecuadas

3. **Monitoreo:**
   - Verificar que los digests se envían correctamente
   - Ajustar frecuencias si hay demasiado/poco ruido

---

*Creado: 2026-03-25*
*Última actualización: 2026-03-25*
