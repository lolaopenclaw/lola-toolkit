# Logging Implementation Guide

**Fecha:** 2026-03-24  
**Autora:** Lola (subagent)  
**Contexto:** Caso de uso 11 (YouTube "14 Use Cases") — Log Everything

---

## Visión General

Este documento describe nuestra estrategia de logging comprehensivo para OpenClaw, implementando el principio **"Log Everything"** para facilitar debugging, auditing, y mejora continua.

---

## Filosofía de Logging

### Principios Core

1. **Log everything:** Logs son baratos (1GB ~ 2 meses), debugging es caro
2. **Structured logging:** Formato consistente para facilitar parsing/analysis
3. **Multiple perspectives:** Different logs para diferentes propósitos
4. **Proactive review:** Analizar logs automáticamente, no solo cuando algo rompe
5. **One source of truth:** Cada evento se loggea exactamente una vez en su log apropiado

### Trade-offs

**Ventajas de logging agresivo:**
- Debugging más rápido (MTTR ↓)
- Auditing completo
- Pattern detection (problemas recurrentes)
- Historical analysis
- Compliance/security trails

**Desventajas:**
- Espacio en disco (mitigable con rotation/compression)
- Noise (mitigable con structured logging + filtering)
- Privacy concerns (mitigable con PII redaction)

**Verdict:** Ventajas >> Desventajas

---

## Arquitectura de Logging

### Diagrama del Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                    OpenClaw Logging System                   │
└─────────────────────────────────────────────────────────────┘
              │
              ├─── Daily Logs (memory/YYYY-MM-DD.md)
              │    • Cronológico, detallado
              │    • Todo lo que ocurre durante el día
              │    • Human-readable Markdown
              │
              ├─── Learnings Log (memory/learnings.md)
              │    • Temático, filtrado
              │    • Solo lo importante que aprendimos
              │    • Categorizado por tipo
              │
              ├─── Decisions Log (memory/decisions.md)
              │    • Decisiones técnicas importantes
              │    • Por qué elegimos X sobre Y
              │    • Histórico de trade-offs
              │
              ├─── Gateway Logs (journalctl)
              │    • OpenClaw Gateway daemon
              │    • System-level events
              │    • Errors/warnings del runtime
              │
              ├─── Cron Logs (scripts/logs/)
              │    • Output de cada cron job
              │    • Structured format (timestamp + name + level + msg)
              │    • Separate file per cron
              │
              ├─── API/Rate Limit Logs (memory/api-*.log)
              │    • Health checks de APIs externas
              │    • Rate limit tracking
              │    • Failover events
              │
              ├─── Subagent Transcripts (~/.openclaw/subagents/)
              │    • Transcript completo de cada subagent
              │    • Input/output, tokens, timing
              │    • Stored in runs/ directory
              │
              └─── Audit Trail (memory/audit.log)
                   • Security-sensitive operations
                   • File modifications, external actions
                   • Who did what when
```

---

## Tipos de Logs

### 1. Daily Logs (`memory/YYYY-MM-DD.md`)

**Propósito:** Registro cronológico de todo lo que ocurre durante el día.

**Formato:**
```markdown
# YYYY-MM-DD — Daily Log

## Section Name ✅/🔧/❌
- Bullet point with details
- Nested details
  - Sub-details

## Another Section
...
```

**Qué se loggea:**
- Tareas completadas
- Decisiones tomadas
- Problemas encontrados
- Conversaciones importantes
- Status updates de projects

**Cuándo se escribe:**
- A lo largo del día (cada sesión)
- Al final del día (summary)

**Rotación:** Diaria (un archivo por día)

**Retention:** Indefinida (archivos pequeños, ~10-50KB)

---

### 2. Learnings Log (`memory/learnings.md`)

**Propósito:** Registro temático de cosas importantes que aprendimos.

**Formato:**
```markdown
## Categoría

| Fecha | Learning | Contexto |
|-------|----------|----------|
| YYYY-MM-DD | Qué aprendimos | Por qué es relevante |
```

**Qué se loggea:**
- Errores que cometimos y cómo los solucionamos
- Soluciones que funcionaron mejor de lo esperado
- Patterns que descubrimos
- Best practices que adoptamos

**Cuándo se escribe:**
- Al completar una tarea (si hubo learnings)
- Durante retrospectivas
- Cuando descubrimos algo no obvio

**Rotación:** No rota (archivo único)

**Retention:** Indefinida

---

### 3. Decisions Log (`memory/decisions.md`)

**Propósito:** Registro de decisiones técnicas importantes.

**Formato:**
```markdown
## Categoría

| Fecha | Decisión | Razón | Alternativas Descartadas |
|-------|----------|-------|--------------------------|
| YYYY-MM-DD | Qué decidimos | Por qué | Alt 1: ... Alt 2: ... |
```

**Qué se loggea:**
- Decisiones de arquitectura
- Elección de tecnologías
- Trade-offs importantes
- Cambios de dirección

**Cuándo se escribe:**
- Después de tomar decisión técnica importante
- Durante code review (si se descubre decisión implícita no documentada)

**Rotación:** No rota (archivo único)

**Retention:** Indefinida

---

### 4. Gateway Logs (journalctl)

**Propósito:** Logs del OpenClaw Gateway daemon (system-level).

**Formato:** Standard systemd journal

**Qué se loggea:**
- Gateway start/stop
- HTTP requests
- Errors/warnings del runtime
- Plugin loading
- Connection events

**Acceso:**
```bash
# Ver últimos 100 logs
journalctl -u openclaw-gateway -n 100 --no-pager

# Tail en real-time
journalctl -u openclaw-gateway -f

# Solo errores
journalctl -u openclaw-gateway -p err

# Desde hoy
journalctl -u openclaw-gateway --since today
```

**Rotación:** Automática (systemd journal rotation)

**Retention:** 1 mes (configurable en `/etc/systemd/journald.conf`)

---

### 5. Cron Logs (`scripts/logs/`)

**Propósito:** Output de cada cron job.

**Formato:** Structured text
```
[TIMESTAMP] [CRON_NAME] [LEVEL] Message
```

**Ejemplo:**
```
[2026-03-24T04:00:00Z] [backup] [INFO] Starting backup...
[2026-03-24T04:00:15Z] [backup] [INFO] Backed up 45 files (2.3MB)
[2026-03-24T04:00:15Z] [backup] [SUCCESS] Backup completed
```

**Qué se loggea:**
- Start/end de cada cron
- Pasos importantes durante ejecución
- Errores/warnings
- Stats (files processed, time taken, etc.)

**Estructura de archivos:**
```
scripts/logs/
├── backup.log
├── autoimprove.log
├── api-health.log
├── rate-limit.log
├── config-drift.log
└── reindex.log
```

**Rotación:** Semanal (logrotate)

**Retention:** 4 semanas

**Configuración logrotate:**
```
/home/mleon/.openclaw/workspace/scripts/logs/*.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
}
```

---

### 6. API/Rate Limit Logs (`memory/api-*.log`)

**Propósito:** Tracking de health checks y rate limits de APIs externas.

**Formato:** JSON Lines (uno JSON object por línea)

**Ejemplo (`memory/api-health.log`):**
```json
{"timestamp":"2026-03-24T10:30:00Z","provider":"anthropic","status":"healthy","latency_ms":245,"tokens":156}
{"timestamp":"2026-03-24T11:00:00Z","provider":"anthropic","status":"failed","error":"timeout","failover":"google"}
```

**Ejemplo (`memory/rate-limit.log`):**
```json
{"timestamp":"2026-03-24T10:30:00Z","provider":"anthropic","metric":"TPM","current":45000,"limit":80000,"pct":56.25}
{"timestamp":"2026-03-24T10:30:00Z","provider":"google","metric":"RPM","current":12,"limit":60,"pct":20.0}
```

**Qué se loggea:**
- Health check results (cada 30min)
- Rate limit status (cada hora)
- Failover events
- API errors

**Rotación:** Mensual

**Retention:** 3 meses

---

### 7. Subagent Transcripts (`~/.openclaw/subagents/`)

**Propósito:** Transcript completo de cada subagent (automático, OpenClaw built-in).

**Formato:** JSON (OpenClaw proprietary format)

**Qué se loggea:**
- Prompt inicial
- Cada message del subagent
- Tool calls
- Token usage
- Timing

**Estructura:**
```
~/.openclaw/subagents/
├── runs.json                  # Index de todos los runs
└── 3ace6e45-.../              # Directorio por subagent
    └── transcript.json        # Transcript completo
```

**Acceso:**
```bash
# Leer transcript
cat ~/.openclaw/subagents/3ace6e45-.../transcript.json | jq

# Extraer task
jq -r '.messages[0].content' transcript.json | grep -A1 "Subagent Task"

# Extraer tokens
jq '[.messages[].usage.totalTokens] | add' transcript.json
```

**Rotación:** Manual (limpiar runs viejos con `openclaw subagents prune`)

**Retention:** 30 días (después de completion)

---

### 8. Audit Trail (`memory/audit.log`)

**Propósito:** Logging de operaciones security-sensitive.

**Formato:** JSON Lines

**Ejemplo:**
```json
{"timestamp":"2026-03-24T10:30:00Z","actor":"lola","action":"file_delete","target":"memory/old-file.md","approved_by":"manu"}
{"timestamp":"2026-03-24T11:00:00Z","actor":"lola","action":"external_message","target":"telegram:6884477","content_hash":"abc123"}
{"timestamp":"2026-03-24T11:30:00Z","actor":"lola","action":"api_key_rotation","target":"anthropic","reason":"scheduled"}
```

**Qué se loggea:**
- File deletions (fuera de tmp/)
- External messages (email, Telegram a terceros)
- API key rotations
- Config changes (críticas)
- Gateway restarts (manual)

**Rotación:** Nunca (audit trail debe ser inmutable)

**Retention:** Indefinida

**Security:** Read-only después de write (chmod 444)

---

## Logging Workflow

### Durante Operación Normal

```
1. Event occurs (ej. completar tarea, cron run, API call)
   ↓
2. Log to appropriate log:
   - Daily log (siempre)
   - Learnings log (si hay learning)
   - Decisions log (si hay decisión técnica)
   - Cron log (si es cron job)
   - API log (si es API call)
   - Audit log (si es security-sensitive)
   ↓
3. Structured format:
   - Timestamp
   - Event type
   - Details
   - Result/status
```

### Durante Debugging

```
1. Problema reportado
   ↓
2. Check daily log (¿cuándo ocurrió?)
   ↓
3. Check relevant specialized log:
   - Gateway log (si es runtime issue)
   - Cron log (si es cron-related)
   - API log (si es API failure)
   - Subagent transcript (si es subagent issue)
   ↓
4. Reproduce issue (si necesario)
   ↓
5. Fix issue
   ↓
6. Log learning + decision
```

### Durante Retrospective/Review

```
Daily (matutino):
1. Log review cron (7:30 AM) revisa logs de últimas 24h
2. Identifica errors/warnings
3. Propone fixes
4. Genera summary para informe matutino (10 AM)

Weekly:
1. Revisar learnings log
2. Identificar patterns
3. Actualizar best practices

Monthly:
1. Revisar decisions log
2. Validar decisiones (¿fueron correctas?)
3. Actualizar si necesario
```

---

## Herramientas de Análisis

### Cron: Log Review Automático

**Script:** `scripts/log-review.sh`  
**Schedule:** Diario 7:30 AM  
**Propósito:** Revisar logs de últimas 24h automáticamente

**Qué hace:**
1. Escanear todos los logs (cron logs, API logs, gateway)
2. Extraer errors y warnings
3. Agrupar por tipo
4. Generar summary con:
   - Count de errors por tipo
   - Patrones recurrentes
   - Proposed fixes
5. Añadir a informe matutino (10 AM)

**Output:**
```markdown
## Log Review (últimas 24h)

### Errors (3)
- api-health: Anthropic timeout (2x) → Proposed: increase timeout from 10s to 15s
- cron: backup failed (1x) → Proposed: check disk space

### Warnings (5)
- rate-limit: Approaching TPM limit (85%) → Proposed: use Flash for simple tasks
- config-drift: .env differs from snapshot → Proposed: review and update

### Patterns
- Anthropic timeouts occur 2-3x per day around 10-11 AM (high traffic time?)
```

---

### Manual: jq Queries

**Buscar errores en API log:**
```bash
cat memory/api-health.log | jq 'select(.status=="failed")'
```

**Rate limit por provider:**
```bash
cat memory/rate-limit.log | jq 'select(.provider=="anthropic") | .pct' | tail -10
```

**Cron failures en últimos 7 días:**
```bash
grep ERROR scripts/logs/*.log | grep -A2 "$(date -d '7 days ago' +%Y-%m-%d)"
```

---

### Dashboard: TUI o Web

**Opción 1: TUI (blessed)**
- Similar a `subagents-dashboard`
- Muestra logs en real-time
- Filtros por level/type/time

**Opción 2: Web (here.now)**
- HTML dashboard generado por cron
- Publicado a here.now (o self-hosted)
- Accesible remotamente

---

## Best Practices

### 1. Structured Logging

**✅ Good:**
```
[2026-03-24T10:30:00Z] [backup] [ERROR] Failed to backup file: /path/to/file.md (reason: permission denied)
```

**❌ Bad:**
```
Error occurred
```

**Formato standard:**
```
[TIMESTAMP] [COMPONENT] [LEVEL] Message (key1: value1, key2: value2)
```

---

### 2. Log Levels

| Level | When to Use | Example |
|-------|-------------|---------|
| **DEBUG** | Development only | `[DEBUG] Variable x = 42` |
| **INFO** | Normal operation | `[INFO] Backup completed (45 files)` |
| **WARN** | Potential problem | `[WARN] Rate limit at 85%` |
| **ERROR** | Recoverable error | `[ERROR] API timeout, retrying...` |
| **CRITICAL** | System failure | `[CRITICAL] Gateway crashed` |

---

### 3. PII Redaction

**Antes de loggear:**
- Redactar API keys: `sk-...abc123` → `sk-...XXX`
- Redactar emails: `user@example.com` → `u***@example.com`
- Redactar nombres: `Manuel León` → `M***`

**Regex patterns:**
```bash
# API keys
s/sk-[a-zA-Z0-9]{40}/sk-XXX/g
s/Bearer [a-zA-Z0-9]+/Bearer XXX/g

# Emails
s/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/***@***/g
```

**Implementar en:** Pre-log hook (antes de escribir a archivo)

---

### 4. Log Rotation

**Configurar logrotate para todos los logs:**
```
/home/mleon/.openclaw/workspace/scripts/logs/*.log {
    size 10M
    rotate 4
    compress
    missingok
    notifempty
    create 0644 mleon mleon
}

/home/mleon/.openclaw/workspace/memory/*.log {
    monthly
    rotate 3
    compress
}
```

**Excepciones:**
- `audit.log` — NEVER rotate (immutable audit trail)
- `learnings.md` — NEVER rotate (single file)
- `decisions.md` — NEVER rotate (single file)

---

### 5. Error Handling

**Logging debe ser fail-safe:**
```python
import logging

try:
    # Log to file
    logger.info("Starting task...")
except Exception as e:
    # Fallback: log to stderr
    print(f"[ERROR] Failed to log: {e}", file=sys.stderr)
```

**Nunca:** Let logging failure crash the application

---

## Checklist de Implementación

### Fase 1: Core Logs ✅ DONE
- [x] Daily logs (memory/YYYY-MM-DD.md)
- [x] Gateway logs (journalctl)
- [x] Cron logs (basic, ya existen)
- [x] Subagent transcripts (OpenClaw built-in)

### Fase 2: Specialized Logs ✅ DONE
- [x] Learnings log (memory/learnings.md) — **Implementado hoy**
- [x] Decisions log (memory/decisions.md) — **Implementado hoy**
- [x] API health log (memory/api-health.log) — **Ya existe (api-health-checker.py)**
- [x] Rate limit log (memory/rate-limit.log) — **Ya existe (rate-limit-monitor.py)**

### Fase 3: Audit Trail 🔧 TODO
- [ ] Crear memory/audit.log
- [ ] Implementar audit hooks:
  - File deletions
  - External messages
  - API key rotations
  - Config changes
- [ ] Make audit.log immutable (append-only)

### Fase 4: Automated Review 🔧 TODO
- [ ] Crear scripts/log-review.sh
- [ ] Configurar cron diario (7:30 AM)
- [ ] Integrar con informe matutino (10 AM)
- [ ] Testing (dry-run, verificar output)

### Fase 5: Rotation & Retention ✅ DONE
- [x] Configurar logrotate para cron logs — **Ya existe**
- [x] Configurar retention para subagent transcripts (30 días) — **OpenClaw built-in**
- [ ] Configurar rotation para API logs (mensual)

### Fase 6: Tools & Dashboard 🔧 TODO
- [ ] Decidir: TUI vs Web dashboard
- [ ] Implementar dashboard básico
- [ ] Testing con datos reales

---

## Métricas de Éxito

**Cómo sabemos que logging está funcionando:**

1. **MTTR ↓** (Mean Time To Repair)
   - Antes: 1-2 horas para debuggear issue
   - Después: 10-20 minutos (porque logs tienen toda la info)

2. **Problemas recurrentes ↓**
   - Learnings log previene repetir errores
   - Decisions log previene re-litigar decisiones

3. **Proactive fixes ↑**
   - Log review automático detecta problemas antes de que Manu los reporte

4. **Audit coverage ↑**
   - Todas las operaciones security-sensitive están en audit log

5. **Developer velocity ↑**
   - Menos tiempo debuggeando
   - Más tiempo implementando features

---

## Próximos Pasos

### Inmediato (Hoy)
- [x] Crear learnings.md con entradas de hoy
- [x] Crear decisions.md con decisiones de hoy
- [x] Documentar logging strategy (este archivo)

### Corto Plazo (Esta Semana)
- [ ] Implementar audit.log + hooks
- [ ] Crear scripts/log-review.sh
- [ ] Configurar cron de log review (7:30 AM)
- [ ] Testing de automated log review

### Medio Plazo (Próximas 2 Semanas)
- [ ] Implementar dashboard (TUI o Web)
- [ ] Configurar rotation para API logs
- [ ] Review de learnings/decisions logs (verificar que se usan)

### Largo Plazo (Próximo Mes)
- [ ] Análisis de patterns en logs (ML?)
- [ ] Alerting automático (Telegram) para errors críticos
- [ ] Integration con monitoring tools (Grafana?)

---

## Referencias

- **Caso de uso 11:** YouTube "14 Use Cases" video
- **SOUL.md:** Memory integrity principles
- **AGENTS.md:** Session workflow (read memory files every session)
- **Advanced harness research:** `memory/advanced-harness-research.md`

---

**Documento creado:** 2026-03-24  
**Última actualización:** 2026-03-24  
**Próxima revisión:** Weekly (cada lunes)
