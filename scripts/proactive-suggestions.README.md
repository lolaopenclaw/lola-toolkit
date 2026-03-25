# Proactive Suggestions - Quick Start

Sistema de sugerencias proactivas para heartbeat de OpenClaw.

## 📋 Archivos

- **`proactive-suggestions.sh`** — Script principal (ejecutable)
- **`test-proactive-suggestions.sh`** — Script de testing
- **`memory/proactive-rules.md`** — Reglas configurables
- **`memory/proactive-implementation.md`** — Documentación técnica completa

## 🚀 Uso Básico

```bash
# Generar sugerencias
cd ~/.openclaw/workspace
./scripts/proactive-suggestions.sh

# Testing
./scripts/test-proactive-suggestions.sh
```

## 🎯 Categorías de Sugerencias

1. **🌦️ Weather** — Lluvia, viento, temperatura extrema
2. **📅 Calendar** — Reuniones próximas, días ocupados
3. **😴 Health** — Sueño, body battery, estrés (Garmin)
4. **💰 Finance** — Gastos diarios/semanales
5. **⏰ Pending Actions** — Items urgentes sin resolver
6. **🔧 System** — Backups, subagentes, rate limits

## ⚙️ Configuración

### Reglas (thresholds)

Editar `memory/proactive-rules.md`:

- Rain threshold: >5mm/h
- Sleep low: <6h
- Daily expense: >€100
- Pending items: >10
- etc.

### Horarios

Editables en el script:

- **Weather:** 8:00-10:00 (solo morning)
- **Calendar:** 9:00-21:00 (work hours)
- **Health:** 8:00-9:00 (solo morning)
- **System:** 22:00-23:00 (solo nocturno)

### Quiet Hours

**23:00-07:00 Madrid** — No genera sugerencias

### Max Suggestions

**3 por día** — Configurable en script (`MAX_SUGGESTIONS=3`)

## 🔄 Deduplicación

- State file: `memory/.proactive-suggestions-today.json`
- Reset automático cada día a las 00:00
- No repite la misma sugerencia 2 veces en el mismo día

## 📊 Métricas

- Archivo: `memory/.proactive-metrics.jsonl`
- Formato: JSONL (una línea por sugerencia)

```bash
# Ver últimas 10 sugerencias
tail -10 memory/.proactive-metrics.jsonl | jq

# Count por categoría
jq -s 'group_by(.type) | map({type: .[0].type, count: length})' memory/.proactive-metrics.jsonl
```

## 🧪 Testing

```bash
# Test completo con mock data
./scripts/test-proactive-suggestions.sh

# Test manual
echo '{"today":{"total":150}}' > memory/.finance-daily.json
./scripts/proactive-suggestions.sh
```

## 🔌 Integración

### Con Morning Briefing

```bash
# En morning-briefing.sh
suggestions=$("$WORKSPACE/scripts/proactive-suggestions.sh" 2>/dev/null)
if [[ -n "$suggestions" ]]; then
    echo "## 💡 Sugerencias Proactivas"
    echo "$suggestions"
fi
```

### Con Cron (standalone)

```bash
# crontab -e
0 8 * * * cd ~/.openclaw/workspace && ./scripts/proactive-suggestions.sh | telegram-send --stdin
```

## 🐛 Troubleshooting

### No suggestions generated

1. Check quiet hours (23:00-07:00)
2. Check state file count: `jq .count memory/.proactive-suggestions-today.json`
3. Check time windows (weather solo 8-10, etc.)
4. Run with debug: `bash -x scripts/proactive-suggestions.sh`

### Reset state

```bash
rm memory/.proactive-suggestions-today.json
```

### Check data sources

```bash
# Weather
cat memory/.weather-cache.json | jq

# Health
cat memory/.garmin-last-sync.json | jq

# Finance
cat memory/.finance-daily.json | jq
```

## 📚 Docs Completas

Ver `memory/proactive-implementation.md` para:

- Arquitectura detallada
- Flow diagrams
- Extensibilidad
- Roadmap
- Métricas y mejora continua

## ✅ Status

- [x] Script funcional
- [x] 6 categorías implementadas
- [x] Deduplicación
- [x] State management
- [x] Metrics tracking
- [x] Testing script
- [x] Docs completas
- [ ] Integración con morning briefing (pendiente)
- [ ] Testing con data real
- [ ] Cron deployment

---

**Created:** 2026-03-24  
**Owner:** Lola (lolaopenclaw@gmail.com)
