# Proactive Suggestions - Implementation Docs

**Created:** 2026-03-24  
**Status:** ✅ Implemented  
**Purpose:** Documentación técnica del sistema de sugerencias proactivas

---

## 📋 OVERVIEW

Sistema de sugerencias proactivas que extiende el heartbeat silencioso de OpenClaw con recomendaciones contextuales basadas en:

- 🌦️ **Weather** — Condiciones meteorológicas (Logroño)
- 📅 **Calendar** — Eventos próximos y conflictos
- 😴 **Health** — Métricas Garmin (sueño, body battery, estrés)
- 💰 **Finance** — Gastos diarios/semanales
- ⏰ **Pending Actions** — Items urgentes sin resolver
- 🔧 **System** — Backups, subagentes, rate limits

**Filosofía:** Informar sin saturar. Máximo 3 sugerencias/día, no repetir, respetar quiet hours.

---

## 🗂️ ARCHIVOS

### Core Files

| Archivo | Propósito | Owner |
|---------|-----------|-------|
| `scripts/proactive-suggestions.sh` | Generador principal | Sistema |
| `memory/proactive-rules.md` | Reglas configurables | Usuario (Manu) |
| `memory/proactive-implementation.md` | Esta doc | Sistema |
| `memory/.proactive-suggestions-today.json` | Estado diario (cache) | Sistema |
| `memory/.proactive-metrics.jsonl` | Métricas históricas | Sistema |

### Archivos existentes reutilizados

| Archivo | Usado para |
|---------|-----------|
| `memory/pending-actions.md` | Source de pending actions |
| `memory/.garmin-last-sync.json` | Health data (Garmin) |
| `memory/.weather-cache.json` | Weather data (cache 4h) |
| `memory/.finance-daily.json` | Finance data |

---

## 🛠️ ARQUITECTURA

### Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│  Heartbeat Matutino (8:00)                              │
│  - Morning briefing trigger                             │
└────────────────┬────────────────────────────────────────┘
                 │
                 v
┌─────────────────────────────────────────────────────────┐
│  proactive-suggestions.sh                               │
│  1. Init state (reset si nuevo día)                     │
│  2. Check quiet hours (23:00-07:00)                     │
│  3. Run checkers en orden de prioridad                  │
│  4. Respetar MAX_SUGGESTIONS=3                          │
└────────────────┬────────────────────────────────────────┘
                 │
                 v
┌──────────────────────────────────────┬─────────────────┐
│  Individual Checkers                 │                 │
├──────────────────────────────────────┤                 │
│  • check_weather()                   │                 │
│  • check_calendar()                  │  Each checks:  │
│  • check_health()                    │  - was_sent?   │
│  • check_finance()                   │  - threshold?  │
│  • check_pending_actions()           │  - cache?      │
│  • check_system()                    │                 │
└──────────────────┬───────────────────┴─────────────────┘
                   │
                   v
┌─────────────────────────────────────────────────────────┐
│  Output                                                 │
│  - STDOUT: suggestions (one per line)                   │
│  - State file: updated with sent suggestions            │
│  - Metrics file: JSONL append                           │
└─────────────────────────────────────────────────────────┘
                   │
                   v
┌─────────────────────────────────────────────────────────┐
│  Morning Briefing / Telegram                            │
│  - Integra output en informe matutino                   │
│  - Envía vía Telegram a Manu                            │
└─────────────────────────────────────────────────────────┘
```

---

## 🧩 COMPONENTES

### 1. State Management

**Archivo:** `memory/.proactive-suggestions-today.json`

**Estructura:**
```json
{
  "date": "2026-03-24",
  "suggestions_sent": [
    {
      "type": "weather",
      "key": "rain-logrono",
      "timestamp": "2026-03-24T08:15:00+0100"
    },
    {
      "type": "health",
      "key": "sleep-low-6h",
      "timestamp": "2026-03-24T08:15:00+0100"
    }
  ],
  "count": 2
}
```

**Lifecycle:**
- **Creado:** Primer run del día o si no existe
- **Reset:** Automático cada día a las 00:00
- **Updated:** Cada vez que se envía una sugerencia

**Funciones:**
- `init_state()` — Inicializa o resetea si nuevo día
- `was_sent_today(type, key)` — Check deduplicación
- `record_suggestion(type, key, message)` — Registra envío
- `get_count()` — Cuenta actual de sugerencias del día

### 2. Individual Checkers

Cada checker sigue el mismo patrón:

```bash
check_CATEGORY() {
    # 1. Check if MAX_SUGGESTIONS reached
    local count=$(get_count)
    [[ $count -ge $MAX_SUGGESTIONS ]] && return
    
    # 2. Check time window (if applicable)
    [[ $HOUR -lt X || $HOUR -gt Y ]] && return
    
    # 3. Get data (from cache/API/file)
    local data=$(...)
    
    # 4. Evaluate conditions
    if [[ condition ]]; then
        # 5. Check deduplication
        if ! was_sent_today "category" "key"; then
            # 6. Output suggestion
            echo "emoji Message text"
            # 7. Record
            record_suggestion "category" "key" "metadata"
        fi
    fi
}
```

**Checkers implementados:**

| Checker | Time Window | Priority | Data Source |
|---------|-------------|----------|-------------|
| `check_weather()` | 8:00-10:00 | 3 | wttr.in API |
| `check_calendar()` | 9:00-21:00 | 5 | gog CLI |
| `check_health()` | 8:00-9:00 | 4 | Garmin cache |
| `check_finance()` | Anytime | 3 | Finance cache |
| `check_pending_actions()` | Anytime | 4 | pending-actions.md |
| `check_system()` | 22:00-23:00 | 2 | System checks |

### 3. Deduplication

**Mecanismo:**
- Cada sugerencia tiene un `type` y un `key` único
- Antes de enviar, se chequea `was_sent_today(type, key)`
- Si ya se envió hoy → skip silencioso

**Ejemplos de keys:**

| Type | Key | Trigger |
|------|-----|---------|
| weather | rain-logrono | Rain detected |
| weather | wind-strong | Strong wind |
| calendar | meeting-[id] | Upcoming event |
| health | sleep-low | Sleep <6h |
| finance | daily-high | Expense >€100 |
| pending | urgent-old | Urgent items >3d |

### 4. Quiet Hours

**Horario:** 23:00-07:00 Madrid

**Implementación:**
```bash
is_quiet_hours() {
    local hour=$1
    [[ $hour -ge 23 || $hour -lt 7 ]]
}
```

**Behavior:**
- Durante quiet hours: el script termina inmediatamente
- No genera sugerencias
- No escribe en state file

### 5. Metrics

**Archivo:** `memory/.proactive-metrics.jsonl`

**Formato:** JSONL (una línea por sugerencia)

**Ejemplo:**
```json
{"timestamp":"2026-03-24T08:15:00+0100","type":"weather","key":"rain-logrono","message":"Rain detected: 7mm"}
{"timestamp":"2026-03-24T08:15:00+0100","type":"health","key":"sleep-low","message":"Sleep: 5.5h"}
```

**Uso:**
- Análisis histórico
- Debugging
- Optimización de thresholds

**Queries útiles:**
```bash
# Count por tipo
jq -s 'group_by(.type) | map({type: .[0].type, count: length})' memory/.proactive-metrics.jsonl

# Last 10 suggestions
tail -10 memory/.proactive-metrics.jsonl | jq

# Suggestions hoy
jq --arg date "$(date +%Y-%m-%d)" 'select(.timestamp | startswith($date))' memory/.proactive-metrics.jsonl
```

---

## 🔌 INTEGRACIÓN

### Con Morning Briefing

El script está diseñado para integrarse con el morning briefing (que otro subagent está desarrollando):

**Opción 1: Inline en briefing script**
```bash
#!/usr/bin/env bash
# morning-briefing.sh

echo "## 🌅 Morning Briefing - $(date +%Y-%m-%d)"
echo ""

# ... otras secciones ...

# Sugerencias proactivas
if [[ -x "$WORKSPACE/scripts/proactive-suggestions.sh" ]]; then
    suggestions=$("$WORKSPACE/scripts/proactive-suggestions.sh" 2>/dev/null)
    if [[ -n "$suggestions" ]]; then
        echo "## 💡 Sugerencias Proactivas"
        echo ""
        echo "$suggestions"
        echo ""
    fi
fi

# ... más secciones ...
```

**Opción 2: Standalone con Telegram**
```bash
# Cron: 8:00 AM
0 8 * * * /home/mleon/.openclaw/workspace/scripts/proactive-suggestions.sh | telegram-send --stdin
```

### Con Heartbeat

El heartbeat actual (`HEARTBEAT.md`) es silencioso (solo alerta si hay problema).

**NO modificamos HEARTBEAT.md** — las sugerencias proactivas son un canal paralelo.

**Posible integración futura:**
- Heartbeat ejecuta `proactive-suggestions.sh` en ciertos horarios
- Output se envía si hay sugerencias
- Sigue siendo silencioso si no hay nada

---

## 📊 DATA SOURCES

### Weather (wttr.in)

**API:** `https://wttr.in/Logrono?format=j1`

**Cache:** 4h (`memory/.weather-cache.json`)

**Fields usados:**
- `current_condition[0].temp_C` — Temperatura
- `current_condition[0].precipMM` — Precipitación
- `current_condition[0].windspeedKmph` — Viento

**Thresholds:**
- Rain: >5mm/h
- Wind: >40km/h
- Temp: >35°C o <5°C

### Calendar (gog)

**CLI:** `gog calendar list --today --json`

**Fields usados:**
- `[].summary` — Título del evento
- `[].start` — Timestamp de inicio
- `length` — Número de eventos

**Thresholds:**
- Upcoming: <30 min
- Busy day: >5 eventos

**Nota:** Requiere `gog` configurado con OAuth (ver `TOOLS.md`)

### Health (Garmin)

**Source:** `memory/.garmin-last-sync.json`

**Fields usados:**
- `sleep.hours` — Horas de sueño
- `body_battery` — Body battery %
- `stress` — Nivel de estrés

**Thresholds:**
- Sleep critical: <4h
- Sleep low: <6h
- Body battery low: <30%
- Stress high: >70

**Actualización:** Via `scripts/garmin-health-report.sh` (cron diario)

### Finance

**Source:** `memory/.finance-daily.json`

**Fields usados:**
- `today.total` — Gasto del día
- `last_update` — Fecha último extracto

**Thresholds:**
- Daily high: >€100
- Statement pending: >15 días

**Actualización:** Via `scripts/sheets-populate-v2.py` (cada 15 días con Manu)

**Nota:** NUNCA detallar qué se compró, solo totales

### Pending Actions

**Source:** `memory/pending-actions.md`

**Format:** Markdown con checkboxes

```markdown
- [ ] **urgent** Task description
- [ ] Normal task
- [x] Completed task
```

**Parsing:** `grep -E '^\- \[ \].*\*\*urgent\*\*'`

**Thresholds:**
- Urgent old: >0 items
- Many items: >10 total

### System

**Sources:**
- Backups: `$WORKSPACE/.backups/*.tar.gz`
- Subagents: `openclaw sessions list --json`
- Rate limits: `scripts/rate-limit-monitor.py`

**Thresholds:**
- Backup old: >7 días
- Many subagents: >5 activos
- Rate limit: >80%

---

## 🧪 TESTING

### Manual Test

```bash
# Run script
cd /home/mleon/.openclaw/workspace
./scripts/proactive-suggestions.sh

# Check state
jq . memory/.proactive-suggestions-today.json

# Check metrics
tail -5 memory/.proactive-metrics.jsonl | jq
```

### Reset State (for testing)

```bash
# Delete state file (will reset on next run)
rm memory/.proactive-suggestions-today.json

# Or manually reset to yesterday
echo '{"date":"2026-03-23","suggestions_sent":[],"count":0}' > memory/.proactive-suggestions-today.json
```

### Mock Data

**Weather:**
```bash
# Force rain condition
echo '{"current_condition":[{"temp_C":"15","precipMM":"10","windspeedKmph":"25"}]}' > memory/.weather-cache.json
```

**Health:**
```bash
# Force low sleep
echo '{"sleep":{"hours":5.5},"body_battery":25,"stress":75}' > memory/.garmin-last-sync.json
```

**Finance:**
```bash
# Force high spending
echo '{"today":{"total":150},"last_update":"2026-03-01"}' > memory/.finance-daily.json
```

### Expected Output

Con mock data arriba:

```
🌧️ Hoy llueve en Logroño (10mm), quizás no es día de surf
😴 Dormiste poco anoche (5.5h), tómatelo con calma
💰 Llevas €150 gastados hoy
```

(Máximo 3, según `MAX_SUGGESTIONS`)

---

## 🔧 CONFIGURACIÓN

### Thresholds

Editables en `memory/proactive-rules.md`:

| Category | Threshold | Editable en |
|----------|-----------|-------------|
| Weather | Rain >5mm | `proactive-rules.md` |
| Calendar | Events >5 | `proactive-rules.md` |
| Health | Sleep <6h | `proactive-rules.md` |
| Finance | Daily >€100 | `proactive-rules.md` |

**Para cambiar:** Editar `proactive-rules.md` + actualizar script si es necesario.

### Time Windows

Editables en script (`proactive-suggestions.sh`):

```bash
# Weather: solo morning
[[ $HOUR -lt 8 || $HOUR -gt 10 ]] && return

# Calendar: work hours
[[ $HOUR -lt 9 || $HOUR -gt 21 ]] && return

# Health: solo morning
[[ $HOUR -lt 8 || $HOUR -gt 9 ]] && return

# System: solo nocturno
[[ $HOUR -lt 22 || $HOUR -gt 23 ]] && return
```

### Max Suggestions

Editable en script:

```bash
MAX_SUGGESTIONS=3  # Cambiar aquí
```

---

## 📈 MÉTRICAS Y MEJORA CONTINUA

### KPIs

1. **Suggestions sent per day** — Promedio y distribución
2. **Suggestions by category** — Qué categorías son más activas
3. **False positives** — Sugerencias no útiles (requiere feedback manual)
4. **Timing accuracy** — ¿Llegaron en el momento correcto?

### Queries útiles

```bash
# Promedio diario (últimos 7 días)
jq -s 'group_by(.timestamp[0:10]) | map({date: .[0].timestamp[0:10], count: length})' \
    memory/.proactive-metrics.jsonl | tail -7

# Por categoría (últimos 30 días)
jq -s --arg since "$(date -d '30 days ago' +%Y-%m-%d)" \
    'map(select(.timestamp >= $since)) | group_by(.type) | map({type: .[0].type, count: length})' \
    memory/.proactive-metrics.jsonl
```

### Feedback Loop

**Manual (por ahora):**
- Manu indica qué sugerencias fueron útiles / no útiles
- Ajustamos thresholds en `proactive-rules.md`
- Actualizamos script si es necesario

**Futuro (con Telegram reactions):**
- 👍 = útil → decrease threshold (más sensible)
- 👎 = no útil → increase threshold (menos sensible)
- Automático via Telegram Bot API

---

## 🚀 DEPLOYMENT

### Checklist

- [x] Script creado: `scripts/proactive-suggestions.sh`
- [x] Permisos ejecutables: `chmod +x`
- [x] Reglas documentadas: `memory/proactive-rules.md`
- [x] Docs implementación: `memory/proactive-implementation.md`
- [ ] Integración con morning briefing (pendiente otro subagent)
- [ ] Testing con data real
- [ ] Cron job (si standalone)

### Cron Setup (opcional)

Si se usa standalone (sin morning briefing):

```bash
# Edit cron
crontab -e

# Add line:
0 8 * * * cd /home/mleon/.openclaw/workspace && ./scripts/proactive-suggestions.sh | telegram-send --stdin 2>&1 | logger -t proactive-suggestions
```

### Logs

**Stdout:** Sugerencias (una por línea)  
**Stderr:** Logs de debug  
**Metrics:** `memory/.proactive-metrics.jsonl`

**View logs:**
```bash
journalctl -t proactive-suggestions
```

---

## 🐛 TROUBLESHOOTING

### No suggestions generated

**Causas posibles:**
1. Quiet hours (23:00-07:00)
2. MAX_SUGGESTIONS ya alcanzado hoy
3. Todas las sugerencias ya enviadas hoy (dedup)
4. Ninguna condición cumple thresholds
5. Data sources no disponibles

**Debug:**
```bash
# Check state
jq . memory/.proactive-suggestions-today.json

# Check time
date +"%H"  # Si 23-07 → quiet hours

# Run con debug
bash -x scripts/proactive-suggestions.sh 2>&1 | less
```

### Suggestions repetidas

**Causa:** State file no se está actualizando correctamente

**Fix:**
```bash
# Check permisos
ls -la memory/.proactive-suggestions-today.json

# Manual cleanup
rm memory/.proactive-suggestions-today.json
```

### Data sources not available

**Weather:**
```bash
curl -s "wttr.in/Logrono?format=j1" | jq .
```

**Calendar:**
```bash
gog calendar list --today --json
```

**Health:**
```bash
ls -la memory/.garmin-last-sync.json
jq . memory/.garmin-last-sync.json
```

### Script fails

**Check dependencies:**
```bash
# Required
command -v jq
command -v bc
command -v curl

# Optional
command -v gog
command -v openclaw
```

---

## 📚 REFERENCIAS

### Documentos relacionados

- `HEARTBEAT.md` — Heartbeat silencioso (13 checks)
- `memory/proactive-rules.md` — Reglas configurables
- `memory/youtube-resources-analysis.md` — Análisis original que inspiró esto
- `TOOLS.md` — Setup de skills (gog, weather, etc.)
- `memory/work-schedule.md` — Work hours de Manu
- `memory/garmin-integration.md` — Integración Garmin

### Skills usados

- `weather` — wttr.in / Open-Meteo
- `gog` — Google Calendar
- Garmin scripts — `scripts/garmin-health-report.sh`

### Inspired by

- **"A Practical Guide to OpenClaw"** — Heartbeat proactivo
- **"25 OpenClaw Use Cases eBook"** — Morning briefing (30+ min saved)
- **Karpathy Autoresearch** — Proactive agent patterns

---

## 🔮 ROADMAP

### Phase 1: MVP (✅ Completado)

- [x] Script funcional
- [x] Deduplication
- [x] 6 categorías básicas
- [x] State management
- [x] Docs completas

### Phase 2: Integration

- [ ] Integración con morning briefing
- [ ] Testing con data real
- [ ] Ajuste de thresholds
- [ ] Cron deployment

### Phase 3: Enhancement

- [ ] Surf conditions check (Zarautz/Mundaka via `scripts/surf-conditions.sh`)
- [ ] Smart home suggestions (Sonos, Hue, etc.)
- [ ] GitHub PR reminders (via `gh-issues` skill)
- [ ] Cost tracking suggestions (API usage, rate limits)

### Phase 4: Intelligence

- [ ] Machine learning de thresholds (ajuste automático)
- [ ] Telegram reactions como feedback loop
- [ ] Contextual timing (enviar en el mejor momento)
- [ ] Cross-category patterns (si X + Y → sugerir Z)

---

## ✅ CONCLUSIÓN

Sistema completo y funcional de sugerencias proactivas que:

1. ✅ **No modifica HEARTBEAT.md** (mantiene checks silenciosos)
2. ✅ **Respeta restricciones** (max 3/día, no spam, quiet hours)
3. ✅ **Deduplicación** (state file diario)
4. ✅ **Extensible** (fácil añadir nuevas categorías)
5. ✅ **Documentado** (reglas + implementación)
6. ✅ **Testeable** (mock data, manual testing)
7. ✅ **Integrable** (morning briefing, cron, Telegram)

**Listo para deployment** una vez que el morning briefing esté implementado (otro subagent).

---

**Última actualización:** 2026-03-24  
**Owner:** Lola (lolaopenclaw@gmail.com)  
**Status:** ✅ Implementation complete, pending integration
