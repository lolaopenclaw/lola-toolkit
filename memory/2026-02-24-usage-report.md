# 💰 Informe de Consumo Diario — 2026-02-24

**Generado:** 24 de febrero de 2026 a las 9:10 AM

---

## 📊 Resumen Financiero

| Período | Coste Total | Requests | Promedio/Request |
|---------|-------------|----------|------------------|
| **Hoy** (24 feb) | **$19.70 USD** | 145 | $0.136 |
| **Ayer** (23 feb) | **$64.24 USD** | 757 | $0.085 |
| **Mes** (feb 2026) | **$616.89 USD** | 4,663 | $0.132 |

---

## 🔍 Análisis de Consumo

### Comparación Diaria

- **Reducción del 69.3%** vs. ayer ($19.70 vs. $64.24)
- **Requests reducidos 80.8%** (145 vs. 757)
- **Coste promedio por request aumentó 60%** ($0.136 vs. $0.085)

**Razón:** Uso de modelos más caros (Opus) en sesiones más cortas.

### Desglose por Modelo (Hoy)

| Modelo | Coste | % del Total | Requests | Tokens Out |
|--------|-------|-------------|----------|------------|
| **claude-opus-4-6** | $19.48 | 98.9% | 114 | 24,462 |
| claude-haiku-4-5 | $0.17 | 0.9% | 22 | 9,991 |
| claude-sonnet-4-5 | $0.06 | 0.3% | 1 | 185 |

**Observación:** Opus representa casi todo el consumo de hoy (98.9%), con un promedio de $0.171 por request.

### Tendencia Mensual

**Top 3 Modelos (Febrero):**
1. **Opus 4-6:** $343.82 (55.7%) — 1,212 requests
2. **Sonnet 4-5:** $127.35 (20.6%) — 592 requests
3. **Haiku 4-5:** $125.24 (20.3%) — 2,042 requests

**Promedio diario (24 días):** $25.70 USD/día

---

## 🎯 Contexto de Uso (24 feb)

### Actividades Registradas

**09:00 AM — Informe Matutino (Cron)**
- Generación automática de informe del sistema
- Envío a Discord (2 partes)
- Verificación de Fail2Ban, backups, uptime
- **Consumo estimado:** ~$0.50 USD (Haiku/Sonnet para generación)

**09:10 AM — Reporte de Consumo (Cron)**
- Este informe (actualmente ejecutándose)
- Análisis de JSON, generación de informe estructurado
- **Consumo estimado:** ~$0.20 USD (Haiku)

**Resto del día (114 requests de Opus):**
- No hay registro detallado en memory/2026-02-24.md
- **Hipótesis:** Sesiones interactivas con Manu (análisis, debugging, o desarrollo)
- **Coste principal:** $19.48 USD en Opus

---

## 📈 Proyección Mensual

**Basado en tendencia actual:**
- Promedio diario: $25.70 USD
- Días restantes en febrero: 4 días
- **Proyección fin de mes:** $616.89 + ($25.70 × 4) = **$719.69 USD**

**Comparación con objetivo:**
- Si el objetivo es ~$750/mes → **En línea** ✅
- Si el objetivo es <$500/mes → **Exceso de $219** ⚠️

---

## 💡 Recomendaciones

### 1. Optimización de Modelo
- **Opus domina el coste** (55.7% del mes)
- Evaluar si todas las 114 requests de hoy requerían Opus
- Sugerir usar Sonnet para tareas intermedias (balance coste/calidad)

### 2. Documentación de Sesiones
- No hay registro detallado en memory/ de las actividades de hoy
- **Acción:** Mejorar logging de sesiones interactivas para trazabilidad

### 3. Monitoreo de Crons
- Los crons automatizados son eficientes (~$0.70 USD/día)
- Mantener uso de Haiku/Sonnet para tareas programadas

### 4. Análisis Semanal
- Revisar cada lunes el consumo de la semana anterior
- Identificar picos y ajustar modelos según necesidad

---

## 📋 Acciones Pendientes

- [ ] Revisar logs de sesiones del 24 feb para identificar uso de Opus
- [ ] Documentar decisión de modelo en memory/ cuando se use Opus
- [ ] Considerar añadir presupuesto diario de alerta ($30 USD?)

---

**Informe generado automáticamente por cron:report-daily**
