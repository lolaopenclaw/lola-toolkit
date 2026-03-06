# 📊 Informe de Consumo Diario — 2026-03-06 (Viernes)

**Generado:** 2026-03-06 11:05 AM (Europe/Madrid)  
**Período de análisis:** 00:00-11:05 (primeras 11 horas del día)

---

## 💰 Resumen Financiero

### Hoy (2026-03-06)
- **Consumo:** €1.84
- **Requests:** 8
- **Principales modelos:** 
  - Claude Opus 4.6: €1.78 (96.5%) — 2 requests
  - Claude Haiku 4.5: €0.06 (3.5%) — 6 requests

### Ayer (2026-03-05)
- **Consumo:** €33.88
- **Requests:** 666
- **Principales modelos:**
  - Claude Haiku 4.5: €21.20 (62.7%) — 483 requests
  - Claude Opus 4.6: €12.68 (37.4%) — 169 requests

### Mes (2026-03)
- **Consumo acumulado:** €36.89
- **Número de días:** 6 días (parciales)
- **Promedio/día:** €6.15
- **Proyección mensual:** ~€184.50 (31 días)

---

## 📈 Análisis de Consumo

### Cambios Respecto a Ayer
| Métrica | Ayer | Hoy | Cambio |
|---------|------|-----|--------|
| Consumo | €33.88 | €1.84 | ↓ 94.6% |
| Requests | 666 | 8 | ↓ 98.8% |
| Haiku tokens | 161,647 | 1,364 | ↓ 99.2% |
| Opus tokens | 34,674 | 167 | ↓ 99.5% |

**Interpretación:** Actividad muy baja hoy (mañana temprana). Ayer fue día intenso con desarrollo de dashboards y widgets.

### Tendencia Semanal
```
Marzo:
01-02: (sin datos - fin de semana)
03:    ~€0 (poco contexto)
04:    ~€0 (poco contexto)
05:    €33.88 ⬆️ PICO (desarrollo LobsterBoard)
06:    €1.84 ↓ (mañana, actividad mínima)
```

---

## 🎯 Contexto de Uso

### Ayer (2026-03-05) — Dashboard & Widgets Intensivos
**Actividad:** 5h 19 min activos (08:22-13:41 Madrid)

**Por qué el consumo fue alto:**
1. **Debug Gateway Issues** → Múltiples reinstarts, diagnóstico, logs parsing
2. **Control UI Setup** → CORS troubleshooting, Tailscale configuration
3. **Dashboard API Development** → 3 endpoints creados (finanzas, salud, calendario)
4. **Widget Implementation** → LobsterBoard plugins custom, testing, refinement
5. **Google Calendar Integration** → Setup OAuth, calendar sharing, endpoint testing

**Modelo distribution:**
- **Haiku 62.7%:** Tareas iterativas, debugging, testing
- **Opus 37.4%:** Arquitectura, diseño de soluciones complejas

### Hoy (2026-03-06) — Mañana Ligera
**Actividad:** Minimal (cron jobs, reportes automáticos)
- 08:00-11:05: Poco uso — probablemente trabajando en otros proyectos
- Consumo de hoy es casi enteramente de:
  - Este informe de consumo (Opus: análisis data)
  - Heartbeat checks (Haiku: rutinas ligeras)

---

## 🚀 Proyección Mensual

**Escenario: Consumo moderado (pendiente limpieza de crons)**

### Basado en promedio actual (€6.15/día)
```
Consumo acumulado (6 días):  €36.89
Días restantes en marzo:     25 días
Proyección lineal:           €36.89 + (€6.15 × 25) = €190.64
```

### Basado en consumo sin picos (€2-3/día típico)
```
Si hoy es representativo (~€2/día):
Proyección conservadora: €36.89 + (€2.50 × 25) = €99.39
```

### Presupuesto recomendado
- **Target:** €100-120/mes (80% en Haiku, 20% en Opus)
- **Actual:** €36.89/6 días = €37/día en promedio
- **Status:** ⚠️ SOBRE TARGET (por picos de desarrollo)

---

## ⚙️ Contexto Técnico

### Modelos Usados

| Modelo | Costo | Uso | Recomendación |
|--------|-------|-----|---------------|
| Claude Haiku 4.5 | €0.80/M input, €4/M output | 👍 Default para rutinas | Mantener |
| Claude Opus 4.6 | €15/M input, €75/M output | ⚠️ Solo análisis complejos | Reducir uso |
| Delivery-mirror | €0 | Meta tracking | Ignorar |

**Tokens por modelo (mes):**
- Haiku: 6,761 input / 208,634 output (62.3% del cost)
- Opus: 199 input / 34,642 output (39.2% del cost)

---

## 🎯 Recomendaciones

### 🔴 CRÍTICA
1. **Limpiar reportes automáticos** (pendiente desde ayer)
   - Remover: `usage:report-daily`, `usage:report-weekly` 
   - Mantener solo: healthchecks críticos, backups, security
   - **Ahorro esperado:** ~€15-20/mes (reducir Haiku spam)

### 🟡 IMPORTANTE
2. **Revisión de cron jobs**
   ```bash
   # Ejecutar para ver qué crons consumen
   grep -r "claude\|gog\|garmin" ~/.openclaw/workspace/scripts/
   ```

3. **Caché en dashboard-api-server.js**
   - Actualmente parsea Google Sheets en cada request
   - Cambiar a caché 5 min para reducir llamadas Haiku

### 🟢 OPCIONAL
4. **Monitorear Opus usage**
   - Ayer: 37% del consumo por desarrollo
   - Hoy: 96% (probablemente este informe)
   - Pattern: OK cuando es diseño complejo; reducir uso casual

---

## 📋 Summary

| Métrica | Valor | Status |
|---------|-------|--------|
| Consumo hoy | €1.84 | ✅ Bajo (actividad mínima) |
| Consumo mes | €36.89 | ⚠️ Sobre presupuesto |
| Proyección | €190.64 | ⚠️ Necesita optimización |
| Recomendación | Limpiar crons | 🔴 URGENTE |
| Próximo review | 2026-03-07 09:00 AM | 📅 Diario |

**Nota:** Informe generado automáticamente por cron job. Se incluirá en informe matutino Discord.
