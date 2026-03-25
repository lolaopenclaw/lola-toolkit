# API Cost Tracking

**Sistema de monitorización de costes API para OpenClaw**

## Cómo Funciona

OpenClaw registra automáticamente el uso de API en archivos JSONL:
- **Ubicación:** `~/.openclaw/agents/main/sessions/*.jsonl`
- **Datos:** Cada mensaje incluye modelo, tokens (input/output), y coste total
- **Modelos:** Claude Opus/Sonnet/Haiku, Gemini, delivery-mirror (sin coste)

Los scripts de cost tracking leen estos JSONL y agregan costes por periodo/modelo/sesión.

---

## Scripts Disponibles

### 1. `usage-report.sh` - Reporte de Costes

```bash
# Uso mensual (default)
bash scripts/usage-report.sh

# Uso de hoy
bash scripts/usage-report.sh --today

# Uso de ayer
bash scripts/usage-report.sh --yesterday

# Últimos 7 días
bash scripts/usage-report.sh --week

# Con desglose por modelo
bash scripts/usage-report.sh --today --by-model

# Con desglose por sesión/cron
bash scripts/usage-report.sh --month --by-session

# Alerta si hoy supera umbral
bash scripts/usage-report.sh --today --alert 25
```

**Flags:**
- `--today` → Sólo hoy
- `--yesterday` → Sólo ayer
- `--week` → Últimos 7 días
- `--month` → Mes actual (default)
- `--by-model` → Desglose por modelo
- `--by-session` → Desglose por sesión (top 20)
- `--alert AMOUNT` → Exit code 1 si el gasto diario supera AMOUNT

**Output:** JSON con `total_cost`, `total_requests`, `by_model[]`, etc.

---

### 2. `cost-alert.sh` - Alertas Automáticas

```bash
bash scripts/cost-alert.sh
```

**Umbrales:**
- **< $10:** ✅ COST_OK
- **$10-25:** ⚠️  WARNING
- **> $25:** 🚨 CRITICAL (exit code 1)

**Pensado para cron:**
```bash
# Alerta diaria a las 20:00
0 20 * * * cd ~/.openclaw/workspace && bash scripts/cost-alert.sh
```

**Output:**
- Si OK: mensaje breve + top 3 modelos
- Si WARNING/CRITICAL: desglose completo + recomendaciones

---

## Costes por Modelo (Referencia)

| Modelo | Input/1K | Output/1K | Uso Recomendado |
|--------|----------|-----------|-----------------|
| **claude-opus-4-6** | $15 | $75 | Tareas complejas, razonamiento profundo, decisiones importantes |
| **claude-sonnet-4-5** | $3 | $15 | Tareas estándar, la mayoría de interacciones |
| **claude-haiku-4-5** | $0.25 | $1.25 | Tareas simples, chats breves, validaciones |
| **gemini-3-flash-preview** | ~$0 | ~$0 | Búsquedas, tasks baratas (failover) |

**Coste Real de Hoy (2026-03-25):**
- Opus: $36.15 (398 requests) ← 72% del gasto
- Sonnet: $12.45 (289 requests)
- Haiku: $1.25 (196 requests)

---

## Optimización de Costes

### 🎯 Tips Principales

1. **Usa el modelo apropiado:**
   - Haiku para validaciones, checks rápidos, comandos simples
   - Sonnet para interacción normal
   - Opus sólo para decisiones complejas o razonamiento profundo

2. **Revisa cron jobs:**
   ```bash
   openclaw cron list
   ```
   - ¿Hay jobs corriendo Opus que podrían usar Sonnet/Haiku?
   - ¿Algún job corriendo más frecuente de lo necesario?

3. **Monitoriza subagentes:**
   - Los subagentes pueden generar bucles costosos
   - Usa `--by-session` para detectar sesiones con gasto anómalo
   - Limita depth/timeout en spawns

4. **Revisa el uso diario:**
   ```bash
   bash scripts/usage-report.sh --today --by-model
   ```
   - Si Opus domina (>70%), considera cambiar default model
   - Si hay picos, revisa qué pasó ese día

5. **Configura alertas:**
   - Añade `cost-alert.sh` a cron diario
   - Ajusta umbrales según tu presupuesto

---

## Alertas Recomendadas

### Cron Diario (20:00)
```bash
0 20 * * * cd ~/.openclaw/workspace && bash scripts/cost-alert.sh
```

### Alerta Custom (Slack/Telegram)
```bash
#!/bin/bash
ALERT=$(bash scripts/cost-alert.sh)
EXIT_CODE=$?

if [[ $EXIT_CODE -eq 1 ]]; then
  # Enviar a Telegram/Slack
  echo "$ALERT" | your-notification-tool
fi
```

---

## Troubleshooting

### "No se encuentran archivos JSONL"
- Verifica que `~/.openclaw/agents/main/sessions/` exista
- Comprueba que haya archivos `.jsonl` recientes

### "Costes en 0"
- Algunos modelos (Gemini) pueden reportar coste 0
- Revisa que los JSONL tengan campo `.message.usage.cost.total`

### "bc: command not found"
- Instala: `sudo apt install bc`
- Los scripts tienen fallback a comparación entera (cents)

---

## Integración con Autoimprove

El loop de autoimprove puede usar estos scripts para:
- Detectar modelos infrautilizados
- Sugerir cambios de modelo en cron jobs costosos
- Alertar si el gasto mensual crece sin mejora de valor

Ver: `skills/autoimprove/SKILL.md`

---

---

## Testing

Para verificar que todo funciona:

```bash
# Test básico de todas las flags
bash scripts/usage-report.sh --today
bash scripts/usage-report.sh --yesterday
bash scripts/usage-report.sh --week
bash scripts/usage-report.sh --month

# Test con breakdowns
bash scripts/usage-report.sh --today --by-model
bash scripts/usage-report.sh --week --by-session

# Test de alertas
bash scripts/cost-alert.sh
```

**Estado:** ✅ Probado y funcionando (2026-03-25)

---

**Actualizado:** 2026-03-25  
**Autor:** Lola (subagent api-cost-tracker)  
**Tested:** All flags working, session tracking verified
