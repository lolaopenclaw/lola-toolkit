# Performance Tracking

Sistema de monitoreo de latencia y degradación de respuestas de OpenClaw basado en análisis de session logs.

## Componentes

### 1. `scripts/performance-tracker.sh`

Script principal de análisis. Extrae métricas de respuesta desde session logs JSONL.

**Métricas extraídas:**
- **Response latency:** Tiempo entre mensaje de usuario y respuesta del asistente (segundos)
- **Model used:** Modelo que generó la respuesta
- **Token load:** Input tokens (proxy para tamaño de contexto)
- **Output tokens:** Tokens generados
- **Cost:** Coste por mensaje
- **Tool calls:** Número de llamadas a herramientas

**Uso:**

```bash
# Resumen de hoy
bash scripts/performance-tracker.sh --today --summary

# Resumen de ayer
bash scripts/performance-tracker.sh --yesterday --summary

# Última semana
bash scripts/performance-tracker.sh --week --summary

# Análisis de degradación (última semana)
bash scripts/performance-tracker.sh --week --degradation

# Mensajes lentos de hoy (>30s)
bash scripts/performance-tracker.sh --today --slow 30

# Analizar sesión específica
bash scripts/performance-tracker.sh --session ~/.openclaw/agents/main/sessions/SESSION_ID.jsonl --summary
```

**Output (--summary):**

```
📊 Performance Report — 2026-03-26

Response Latency:
  avg: 9.4s | p50: 7.0s | p90: 19.0s | p99: 38.0s
  
By Model:
  claude-opus-4-6:        avg 13.0s (115 messages)
  claude-sonnet-4-5:      avg 10.0s (125 messages)
  claude-haiku-4-5:       avg 5.1s  (49 messages)
  gemini-3-flash-preview: avg 0.2s  (31 messages)

By Hour:
  18:00-19:00: avg 2.9s  (most responsive)
  06:00-07:00: avg 13.9s (slowest)

Context Size Correlation:
  <10K tokens:    avg 5.2s
  10-50K:         avg 12.1s
  50-100K:        avg 24.3s
  >100K:          avg 41.8s

Degradation:
  ✅ None detected

Slow Messages (>30s): 11 found
  - 19:51:47 claude-sonnet-4-5 82.0s (context: 0K tokens)
  - 06:23:08 claude-sonnet-4-5 56.0s (context: 0K tokens)
```

**Output (--degradation):**

```
📉 Degradation Analysis

Session: 4d07db51-5906-48c4-a02b-06bebe738760-topic-1
  Messages 1-10:   avg 4.6s
  Messages 11-20:  avg 13.1s (+188%)
  Messages 21-30:  avg 11.5s (-12%)
  Messages 31-50:  avg 18.4s (+60%)
  Messages 50+:    avg 14.2s (-23%)
```

### 2. `scripts/performance-alert.sh`

Health check rápido diseñado para cron. Valida si el rendimiento de hoy es aceptable.

**Reglas de alerta:**
- **CRITICAL (exit 2):** Cualquier mensaje > 120s
- **WARNING (exit 1):** >5 mensajes > 60s OR avg latency hoy > 2x avg semanal
- **OK (exit 0):** Todo normal

**Uso:**

```bash
bash scripts/performance-alert.sh
# Output: "PERF_OK (avg: 12.2s)" o "⚠️ WARNING: ..."
# Exit code: 0 = OK, 1 = WARNING, 2 = CRITICAL
```

**Integración con cron:**

```bash
# Añadir a crontab para check diario a las 20:00
openclaw cron add --label "perf-alert" --cron "0 20 * * *" --exec "bash scripts/performance-alert.sh && echo 'PERF_OK' || echo 'PERF_ALERT: Check required'"
```

## Data Source

Session JSONL files en: `~/.openclaw/agents/main/sessions/*.jsonl`

Cada línea es un objeto JSON con estructura:

```json
{
  "type": "message",
  "timestamp": "2026-03-26T12:15:18.103Z",
  "message": {
    "role": "assistant",
    "model": "claude-sonnet-4-5",
    "usage": {
      "input": 19257,
      "output": 340,
      "cost": {
        "total": 0.004641950000000001
      }
    },
    "content": [...]
  }
}
```

## Performance Optimization

**Scripts optimizados para:**
- Procesar 100+ archivos JSONL en <10s
- Manejar sesiones con miles de mensajes
- Evitar cargar contenido completo (solo metadata)
- Procesamiento paralelo de archivos

**Limitaciones conocidas:**
- Ignora mensajes sin `usage` data (algunos assistant messages no la tienen)
- Latencia calculada en segundos (no milisegundos)
- Date range basado en modification time del archivo, no timestamps internos

## Troubleshooting

**Problema:** "No metrics extracted"
- **Causa:** No hay mensajes user→assistant completos en el período
- **Solución:** Verificar que los archivos existen con `ls ~/.openclaw/agents/main/sessions/*.jsonl`

**Problema:** Latencias negativas o 0
- **Causa:** Timestamps mal formateados o fuera de orden
- **Solución:** Script filtra automáticamente latencias < 0

**Problema:** Script lento (>30s)
- **Causa:** Demasiados archivos o sesiones muy largas
- **Solución:** Usar `--today` o `--session` para reducir scope

## Future Improvements

Posibles mejoras (no implementadas):
- [ ] Correlación latencia ↔ hora del día (peak usage times)
- [ ] Detección de anomalías (spikes inexplicables)
- [ ] Export a CSV/JSON para análisis externo
- [ ] Dashboard web (integración con `dashboard-api-server.js`)
- [ ] Rate limit correlation (latencia cuando cerca del límite)
- [ ] Multi-agent support (comparar main vs subagents)

## Related

- **API Cost Tracking:** `memory/api-cost-tracking.md`
- **Rate Limit Monitoring:** `scripts/rate-limit-monitor.py`
- **Session Logs:** `skills/session-logs/SKILL.md`
