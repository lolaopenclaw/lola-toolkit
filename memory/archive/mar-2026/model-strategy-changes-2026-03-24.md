# 🔧 Cambios Recomendados - Multi-Model Strategy

**Fecha:** 2026-03-24  
**Status:** PENDIENTE DE APLICAR

---

## 🎯 Resumen Ejecutivo

Tras analizar los 29 crons activos, se identificaron:

- ✅ **20 crons bien configurados** (Haiku/Sonnet apropiado)
- ⚠️ **6 crons que necesitan upgrade** (Haiku → Sonnet)
- 🔧 **3 autoimprove agents con timeout insuficiente**
- ❌ **1 cron duplicado** (config-drift-check)

**Impacto:**
- **Coste mensual:** +$11/mes (+15%)
- **Mejora en calidad:** Significativa (seguridad, análisis)
- **Reducción de errores:** Esperada (Google Sheets, healthchecks)

---

## 📋 Comandos a Ejecutar

### 1. Upgrade a Sonnet (Seguridad + Críticos)

```bash
# Healthchecks de seguridad → Sonnet (análisis crítico)
openclaw cron update healthcheck:fail2ban-alert \
  --model anthropic/claude-sonnet-4-5

openclaw cron update healthcheck:rkhunter-scan-weekly \
  --model anthropic/claude-sonnet-4-5

openclaw cron update healthcheck:lynis-scan-weekly \
  --model anthropic/claude-sonnet-4-5

openclaw cron update healthcheck:security-audit-weekly \
  --model anthropic/claude-sonnet-4-5

# Google Sheets → Sonnet (manejo errores API Python)
openclaw cron update "📊 Populate Google Sheets v2" \
  --model anthropic/claude-sonnet-4-5

# Garmin weekly → Sonnet (análisis + narrativa)
openclaw cron update "🏃 Resumen Semanal de Actividades Garmin" \
  --model anthropic/claude-sonnet-4-5
```

**Justificación:**
- **Seguridad:** Requiere análisis preciso, decisiones críticas
- **Google Sheets:** Debugging complejo de errores API
- **Garmin:** Narrativa de calidad para humano

---

### 2. Añadir Modelo Explícito (Sin Especificar)

```bash
# Backups → Haiku explícito (ya son mecánicos)
openclaw cron update "🗑️ Backup retention cleanup (lunes)" \
  --model anthropic/claude-haiku-4-5

openclaw cron update "📋 Backup validation (weekly)" \
  --model anthropic/claude-haiku-4-5

# Driving Mode Review → Haiku (búsqueda simple)
openclaw cron update "🚗 Driving Mode - Review for Improvements" \
  --model anthropic/claude-haiku-4-5

# Memory decay → Haiku (ya especificado pero confirmar)
# openclaw cron update memory-decay-weekly \
#   --model anthropic/claude-haiku-4-5

# Reclamación bus → Sonnet (interacción humana compleja)
openclaw cron update "Seguimiento reclamación bus Logroño (3 meses)" \
  --model anthropic/claude-sonnet-4-5
```

**Justificación:**
- **Explícito > implícito:** Evita sorpresas si cambia default
- **Reclamación bus:** Requiere análisis legal/comunicación

---

### 3. Aumentar Timeout (Autoimprove Agents)

```bash
# Autoimprove agents → 900s (15 min)
# Problema actual: Timeout a 600s con Haiku en 15 iteraciones
openclaw cron update "🔬 Autoimprove Scripts Agent" \
  --timeout 900

openclaw cron update "🔬 Autoimprove Skills Agent" \
  --timeout 900

openclaw cron update "🔬 Autoimprove Memory Agent" \
  --timeout 900
```

**Justificación:**
- **Actual:** 600s, todos fallan con timeout
- **Propuesto:** 900s (15 min) — 60s/iteración × 15 iteraciones
- **Modelo:** Mantener Haiku (coste vs iteraciones)

---

### 4. Eliminar Duplicado

```bash
# Hay 2 config-drift-check
# Revisar cuál mantener:
openclaw cron list --json | jq '.jobs[] | select(.name == "config-drift-check")'

# Eliminar el que NO tiene descripción completa
# (probablemente el que no tiene id "a3bd469e-f7cf-47cc-ab0b-1185e508a922")
openclaw cron delete config-drift-check  # confirmar cuál
```

**Justificación:**
- Duplicación innecesaria (mismo schedule: `0 2 * * *`)
- Posible conflicto de ejecución

---

## 📊 Tabla de Cambios Detallada

| Cron | Modelo Actual | Modelo Propuesto | Coste Δ | Razón |
|------|---------------|------------------|---------|-------|
| fail2ban-alert | (default) | Sonnet | +$0.06/día | Análisis seguridad crítico |
| rkhunter-scan | Haiku | Sonnet | +$0.06/día | Interpretación logs malware |
| lynis-scan | Haiku | Sonnet | +$0.06/día | Comparación compleja |
| security-audit | Haiku | Sonnet | +$0.06/día | Auditoría profunda |
| Google Sheets v2 | Haiku | Sonnet | +$0.06/día | Debugging API Python |
| Garmin weekly | (default) | Sonnet | +$0.06/día | Narrativa + análisis |
| Backup cleanup | (default) | Haiku | $0 | Explícito |
| Backup validation | (default) | Haiku | $0 | Explícito |
| Driving Mode Review | (default) | Haiku | $0 | Explícito |
| Reclamación bus | (default) | Sonnet | +$0.06 (once) | Interacción humana |
| Autoimprove Scripts | Haiku | Haiku | $0 | Solo timeout |
| Autoimprove Skills | Haiku | Haiku | $0 | Solo timeout |
| Autoimprove Memory | Haiku | Haiku | $0 | Solo timeout |

**TOTAL:** +$0.36/día × 30 días = **+$10.80/mes**

---

## ⚠️ Consideraciones Antes de Aplicar

### Riesgos

1. **Coste:** +15% mensual (~$11/mes)
2. **Timeouts autoimprove:** Si 900s no bastan, considerar:
   - Reducir iteraciones (15 → 10)
   - Dividir en múltiples crons (scripts, skills, memory)
   - Usar Sonnet (más rápido pero 5× más caro)

### Alternativas Consideradas

#### Google Sheets v2
- **Opción A (elegida):** Sonnet — Mejor debugging
- **Opción B:** Haiku + refactor script — Más complejo
- **Opción C:** Flash — Muy arriesgado para API crítica

#### Healthchecks de Seguridad
- **Opción A (elegida):** Sonnet — Análisis preciso
- **Opción B:** Haiku + alertas conservadoras — Más falsos positivos
- **Opción C:** Flash — Inaceptable para seguridad

---

## 🧪 Plan de Testing

### Fase 1: Validar Cambios Críticos (1 semana)

```bash
# Aplicar solo healthchecks de seguridad
openclaw cron update healthcheck:fail2ban-alert --model anthropic/claude-sonnet-4-5
openclaw cron update healthcheck:security-audit-weekly --model anthropic/claude-sonnet-4-5

# Esperar 1 semana, verificar:
# - ¿Mejora en detección de anomalías?
# - ¿Menos falsos positivos/negativos?
# - ¿Coste real vs estimado?
```

### Fase 2: Aplicar Resto (1 semana después)

```bash
# Si Fase 1 exitosa, aplicar resto de cambios
bash /path/to/script-with-all-updates.sh
```

### Fase 3: Monitorear (1 mes)

- Revisar `memory/token-usage-YYYY-MM.md` mensualmente
- Verificar que autoimprove agents completan sin timeout
- Evaluar calidad de informes de seguridad

---

## 📈 Métricas de Éxito

### Después de 1 mes:

- [ ] **Autoimprove agents:** 0 timeouts (actualmente: 3/3)
- [ ] **Google Sheets:** <2 errores/mes (actualmente: ~5/mes)
- [ ] **Healthchecks seguridad:** >90% precisión en alertas
- [ ] **Coste:** Dentro de +$15/mes (+20% margen)
- [ ] **Satisfacción Manu:** Mejora en calidad de informes

---

## 🔄 Rollback Plan

Si algo sale mal:

```bash
# Revertir a Haiku
openclaw cron update <CRON_NAME> --model anthropic/claude-haiku-4-5

# Restaurar timeout original
openclaw cron update <CRON_NAME> --timeout 600

# Revisar logs
openclaw cron logs <CRON_NAME> --tail 50
```

---

## 📝 Notas de Implementación

### Orden Recomendado

1. **Primero:** Timeouts autoimprove (bajo riesgo, alta necesidad)
2. **Segundo:** Healthchecks seguridad (críticos, testear separado)
3. **Tercero:** Google Sheets + Garmin (menos críticos)
4. **Cuarto:** Explicitar modelos (bajo impacto)
5. **Último:** Eliminar duplicado (verificar bien antes)

### Script de Aplicación

```bash
#!/bin/bash
# apply-model-strategy-2026-03-24.sh

set -e

echo "🔧 Aplicando Multi-Model Strategy..."

# 1. Timeouts
echo "⏱️  Aumentando timeouts autoimprove..."
openclaw cron update "🔬 Autoimprove Scripts Agent" --timeout 900
openclaw cron update "🔬 Autoimprove Skills Agent" --timeout 900
openclaw cron update "🔬 Autoimprove Memory Agent" --timeout 900

# 2. Healthchecks → Sonnet
echo "🔐 Upgrade healthchecks a Sonnet..."
openclaw cron update healthcheck:fail2ban-alert --model anthropic/claude-sonnet-4-5
openclaw cron update healthcheck:rkhunter-scan-weekly --model anthropic/claude-sonnet-4-5
openclaw cron update healthcheck:lynis-scan-weekly --model anthropic/claude-sonnet-4-5
openclaw cron update healthcheck:security-audit-weekly --model anthropic/claude-sonnet-4-5

# 3. Google Sheets + Garmin → Sonnet
echo "📊 Upgrade Google Sheets y Garmin a Sonnet..."
openclaw cron update "📊 Populate Google Sheets v2" --model anthropic/claude-sonnet-4-5
openclaw cron update "🏃 Resumen Semanal de Actividades Garmin" --model anthropic/claude-sonnet-4-5

# 4. Explicitar Haiku
echo "🏷️  Explicitando modelos Haiku..."
openclaw cron update "🗑️ Backup retention cleanup (lunes)" --model anthropic/claude-haiku-4-5
openclaw cron update "📋 Backup validation (weekly)" --model anthropic/claude-haiku-4-5
openclaw cron update "🚗 Driving Mode - Review for Improvements" --model anthropic/claude-haiku-4-5

# 5. Reclamación bus → Sonnet
echo "🚌 Upgrade reclamación bus a Sonnet..."
openclaw cron update "Seguimiento reclamación bus Logroño (3 meses)" --model anthropic/claude-sonnet-4-5

echo "✅ Cambios aplicados. Verificar con: openclaw cron list"
echo "📊 Monitorear coste: openclaw usage --month $(date +%Y-%m)"
```

---

## ✅ Checklist de Aplicación

- [ ] **Backup actual:** `openclaw cron list --json > crons-backup-2026-03-24.json`
- [ ] **Revisar presupuesto:** Confirmar +$11/mes es aceptable
- [ ] **Aplicar Fase 1:** Healthchecks + timeouts
- [ ] **Esperar 1 semana**
- [ ] **Evaluar resultados:** Logs, coste, calidad
- [ ] **Aplicar Fase 2:** Resto de cambios
- [ ] **Documentar en MEMORY.md:** Link a este archivo
- [ ] **Añadir recordatorio mensual:** Revisar métricas

---

**Próximos pasos:** Presentar a Manu para aprobación.
