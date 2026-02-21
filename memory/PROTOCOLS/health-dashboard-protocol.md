# 📊 Unified Health Dashboard Protocol

**Date:** 2026-02-21  
**Status:** ✅ Production-ready  
**Integration:** Garmin Connect + Weather + System Stats + Notion

---

## Overview

Unified dashboard que compila datos de salud, clima y sistema en:
- 📱 **HTML visual** — Interfaz bonita (colors, responsive)
- 📊 **JSON API** — Para integraciones automáticas
- 📋 **Notion sync** — Pushea datos a página Notion
- 🚨 **Alerts** — Notificaciones de métricas críticas

---

## Scripts

### 1. `health-dashboard.sh`
**Genera dashboard visual + JSON**

```bash
bash ~/.openclaw/workspace/scripts/health-dashboard.sh
```

**Output:**
- `~/.openclaw/workspace/reports/health-dashboard-YYYY-MM-DD.html` — Vista HTML
- `~/.cache/health-dashboard/dashboard-data.json` — Data JSON

**Incluye:**
- ❤️ **Garmin:** HR reposo, estrés, body battery, sueño, pasos
- 🌤️ **Weather:** Temperatura, humedad, viento, presión (Logroño)
- 🖥️ **Sistema:** Uptime, memoria, disco, gateway status
- 💡 **Recomendaciones:** Basadas en métricas actuales

---

### 2. `health-alerts.sh`
**Detecta métricas críticas y genera alertas**

```bash
bash ~/.openclaw/workspace/scripts/health-alerts.sh
```

**Output:** `~/.cache/health-dashboard/alerts.json`

**Alertas críticas:**
- **HR_HIGH:** HR reposo > 70 bpm
- **STRESS_HIGH:** Estrés > 60
- **BATTERY_CRITICAL:** Body Battery < 20%
- **SLEEP_LOW:** Sueño < 6 horas
- **MEMORY_HIGH:** Memoria > 80%
- **DISK_FULL:** Disco > 85%
- **GATEWAY_DOWN:** Port 18789 no listening

---

### 3. `health-to-notion.sh`
**Sincroniza datos a Notion**

```bash
NOTION_API_KEY="..." bash ~/.openclaw/workspace/scripts/health-to-notion.sh
```

**Precondiciones:**
- `NOTION_API_KEY` configurada
- `NOTION_HEALTH_PAGE_ID` (Notion page ID)

**Qué pushea:**
- Resumen diario de métricas
- Timestamp
- Alertas activas

---

## Cron Jobs

### Daily Dashboard
- **Hora:** 9:00 AM Madrid
- **Frecuencia:** Diario
- **Qué hace:** Genera dashboard + sincroniza Notion

```
0 9 * * * bash ~/.openclaw/workspace/scripts/health-dashboard.sh && bash ~/.openclaw/workspace/scripts/health-to-notion.sh
```

### Health Alerts
- **Hora:** 14:00, 20:00 Madrid
- **Frecuencia:** 2x diario
- **Qué hace:** Detecta métricas críticas + notifica

```
0 14,20 * * * bash ~/.openclaw/workspace/scripts/health-alerts.sh
```

---

## JSON Format

### Dashboard Data
```json
{
  "timestamp": "2026-02-21T20:34:00Z",
  "garmin": {
    "hr_resting": 58,
    "stress": 28,
    "body_battery": 37,
    "sleep_hours": 6.8,
    "steps": 866
  },
  "weather": {
    "temp_c": 12,
    "humidity": 65,
    "wind_kmh": 12,
    "pressure_hpa": 1013,
    "condition": "Cloudy"
  },
  "system": {
    "uptime": "1 day, 10h",
    "load": 0.15,
    "memory_used_gb": 7.2,
    "memory_total_gb": 15,
    "disk_used_gb": 29,
    "disk_total_gb": 464,
    "gateway_status": "running"
  }
}
```

### Alerts Data
```json
{
  "timestamp": "2026-02-21T20:34:00Z",
  "alert_count": 0,
  "alert_types": [],
  "metrics": { ... }
}
```

---

## Integration

### Notion Sync
Automático via cron. Requiere:
- `NOTION_API_KEY` env var
- Página Notion ID en `NOTION_HEALTH_PAGE_ID`

### HEARTBEAT Integration
El check #8 ya verifica health:
```bash
bash ~/.openclaw/workspace/scripts/garmin-health-report.sh --current
```

Ajusta comunicación basada en:
- Estrés alto → ofrecer pausas
- Sueño bajo → evitar tareas cognitivas
- Battery bajo → sugerir descanso
- HR elevado → preguntar si está bien

---

## Troubleshooting

### "jq: parse error"
- Garmin data no disponible
- Solución: `bash scripts/garmin-health-report.sh --current` manualmente

### "Notion sync failed"
- API key inválida
- Página ID incorrecta
- Solución: verificar `NOTION_API_KEY` y `NOTION_HEALTH_PAGE_ID`

### "Gateway down alert"
- Port 18789 no listening
- Solución: `sudo systemctl status openclaw-gateway.service`

---

## Future Enhancements

- [ ] Dashboard interactivo (gráficas de tendencias)
- [ ] Alertas por Telegram
- [ ] Histórico (últimos 30 días)
- [ ] Comparativas semana a semana
- [ ] Integración con Google Fit (si disponible)
- [ ] Predicción de body battery (ML)

---

**Updated:** 2026-02-21 21:35 Madrid
