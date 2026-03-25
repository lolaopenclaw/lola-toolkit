# 📋 Inventario de Crons — 2026-03-24

**Total:** 29 crons activos  
**Estado:** 3 con errors (timeouts autoimprove), 2 duplicados detectados

---

## 🟢 Categoría: Mantenimiento Diario (Haiku)

| Nombre | Schedule | Modelo | Timeout | Estado | Coste/mes |
|--------|----------|--------|---------|--------|-----------|
| 🏠 Driving Mode Auto-Reset | 22:00 diario | (default) | - | ✅ OK | $0.30 |
| 🔄 Model Reset Nightly | 00:00 diario | Haiku | - | ✅ OK | $0.30 |
| 🔄 System Updates Nightly | 01:30 diario | Haiku | - | ✅ OK | $0.60 |
| 💾 Backup diario memoria | 04:00 diario | Haiku | - | ✅ OK | $0.60 |
| 🧠 Memory Search Reindex | 04:30 diario | Haiku | - | ✅ OK | $0.30 |
| 🌊 Surf Conditions Daily | 06:00 diario | Haiku | - | ✅ OK | $0.30 |

**Subtotal:** ~$2.40/mes

---

## 🔵 Categoría: Informes y Análisis (Sonnet)

| Nombre | Schedule | Modelo | Timeout | Estado | Coste/mes |
|--------|----------|--------|---------|--------|-----------|
| 📊 Populate Google Sheets v2 | 09:30 diario | **Haiku** ⚠️ | 120s | 🟡 Errores ocasionales | $0.90 |
| 📋 Informe Matutino | 10:00 diario | **Sonnet** ✅ | - | ✅ OK | $3.00 |
| 🏃 Resumen Semanal Garmin | 09:00 lunes | **(default)** ⚠️ | - | ✅ OK | $0.45 |

**Subtotal actual:** ~$4.35/mes  
**Subtotal propuesto:** ~$7.95/mes (+$3.60)

---

## 🔐 Categoría: Seguridad y Healthchecks

| Nombre | Schedule | Modelo | Timeout | Estado | Coste/mes |
|--------|----------|--------|---------|--------|-----------|
| healthcheck:fail2ban-alert | Cada 6h | **(default)** ⚠️ | - | ✅ OK | $1.20 |
| healthcheck:rkhunter-scan | 09:00 lunes | **Haiku** ⚠️ | - | ✅ OK | $0.15 |
| healthcheck:lynis-scan | 09:00 lunes | **Haiku** ⚠️ | - | ✅ OK | $0.15 |
| healthcheck:security-audit | 09:00 lunes | **Haiku** ⚠️ | - | 🔴 Error | $0.15 |

**Subtotal actual:** ~$1.65/mes  
**Subtotal propuesto:** ~$5.85/mes (+$4.20)

---

## 🔬 Categoría: Autoimprove (Haiku con timeouts largos)

| Nombre | Schedule | Modelo | Timeout | Estado | Coste/mes |
|--------|----------|--------|---------|--------|-----------|
| 🔬 Autoimprove Scripts | 03:00 diario | Haiku | **600s** ⚠️ | 🔴 Timeout | $1.50 |
| 🔬 Autoimprove Skills | 03:05 diario | Haiku | **600s** ⚠️ | 🔴 Timeout | $1.50 |
| 🔬 Autoimprove Memory | 03:10 diario | Haiku | **600s** ⚠️ | 🔴 Timeout | $1.50 |

**Problema:** 600s no suficiente para 15 iteraciones  
**Solución:** Aumentar a 900s (sin coste adicional)

**Subtotal:** ~$4.50/mes (sin cambio)

---

## 🗓️ Categoría: Tareas Semanales (Haiku/Sonnet)

| Nombre | Schedule | Modelo | Timeout | Estado | Coste/mes |
|--------|----------|--------|---------|--------|-----------|
| 🔔 OpenClaw release check | 10:00 lun/jue | Haiku | 60s | ✅ OK | $0.06 |
| 🧹 Cleanup audit semanal | 22:00 domingo | Haiku | 120s | ✅ OK | $0.15 |
| 🧠 Memory Guardian Pro | 23:00 domingo | Haiku | - | ✅ OK | $0.15 |
| memory-decay-weekly | 23:00 domingo | Haiku | 120s | ✅ OK | $0.15 |
| 🗑️ Backup retention cleanup | 05:30 lunes | **(default)** ⚠️ | 300s | ✅ OK | $0.30 |
| 📋 Backup validation | 05:30 lunes | **(default)** ⚠️ | 120s | ✅ OK | $0.15 |
| 🔧 Lola Toolkit Sync | 09:30 lunes | Haiku | - | ✅ OK | $0.15 |
| 🔬 Seguimiento Autoresearch | 10:00 lunes | Haiku | 60s | 🔴 Error | $0.15 |

**Subtotal:** ~$1.26/mes

---

## 🔧 Categoría: Config & Monitoring

| Nombre | Schedule | Modelo | Timeout | Estado | Coste/mes |
|--------|----------|--------|---------|--------|-----------|
| config-drift-check | 02:00 diario | (system) | - | ✅ OK | $0.30 |
| config-drift-check (dup) ❌ | 02:00 diario | (default) | - | ⚠️ DUPLICADO | $0.30 |

**Problema:** 2 crons idénticos  
**Solución:** Eliminar duplicado

**Subtotal:** ~$0.30/mes (tras eliminar dup)

---

## 🔁 Categoría: Tareas Periódicas (Trimestral/Mensual)

| Nombre | Schedule | Modelo | Timeout | Estado | Coste/mes |
|--------|----------|--------|---------|--------|-----------|
| 🚗 Driving Mode Review | 09:00 día 8 cada mes | **(default)** ⚠️ | - | - | $0.03 |
| security:rotate-gateway-token | 10:00 día 25 cada 3 meses | Haiku | - | - | $0.01 |
| Seguimiento reclamación bus | Una vez (24/06/2026) | **(default)** ⚠️ | - | - | $0.01 |

**Subtotal:** ~$0.05/mes (amortizado)

---

## 📊 Resumen por Estado

| Estado | Cantidad | Acción |
|--------|----------|--------|
| ✅ OK | 20 | Ninguna |
| 🟡 Mejorable | 6 | Upgrade modelo |
| 🔴 Error/Timeout | 3 | Aumentar timeout |
| ⚠️ Duplicado | 1 | Eliminar |
| 🔧 Sin modelo explícito | 8 | Explicitar |

---

## 💰 Resumen de Costes

### Actual

| Categoría | Coste/mes |
|-----------|-----------|
| Mantenimiento diario | $2.40 |
| Informes | $4.35 |
| Seguridad | $1.65 |
| Autoimprove | $4.50 |
| Semanales | $1.26 |
| Config | $0.60 |
| Periódicos | $0.05 |
| **TOTAL** | **~$14.81/mes** |

### Propuesto (Post-Strategy)

| Categoría | Coste/mes | Δ |
|-----------|-----------|---|
| Mantenimiento diario | $2.40 | $0 |
| Informes | $7.95 | **+$3.60** |
| Seguridad | $5.85 | **+$4.20** |
| Autoimprove | $4.50 | $0 |
| Semanales | $1.26 | $0 |
| Config | $0.30 | -$0.30 (eliminar dup) |
| Periódicos | $0.05 | $0 |
| **TOTAL** | **~$22.31/mes** | **+$7.50** |

**Incremento:** +50% (pero desde base muy baja)

---

## 🎯 Top 5 Cambios Prioritarios

1. **🔧 Aumentar timeout autoimprove** (600s → 900s)
   - Impacto: Alto (arregla 3 crons que fallan)
   - Coste: $0
   - Riesgo: Bajo

2. **🔐 Upgrade healthchecks seguridad** (Haiku → Sonnet)
   - Impacto: Alto (mejor análisis crítico)
   - Coste: +$4.20/mes
   - Riesgo: Bajo

3. **📊 Upgrade Google Sheets** (Haiku → Sonnet)
   - Impacto: Medio (reduce errores API)
   - Coste: +$1.80/mes
   - Riesgo: Bajo

4. **❌ Eliminar config-drift-check duplicado**
   - Impacto: Bajo (limpieza)
   - Coste: -$0.30/mes
   - Riesgo: Bajo

5. **🏷️ Explicitar modelos** (default → Haiku/Sonnet)
   - Impacto: Medio (prevención)
   - Coste: $0
   - Riesgo: Muy bajo

---

## 📋 Checklist de Implementación

- [ ] **Backup:** `openclaw cron list --json > crons-backup.json`
- [ ] **Fase 1:** Aplicar cambios prioritarios (1-2)
- [ ] **Testing:** Esperar 1 semana, revisar logs
- [ ] **Fase 2:** Aplicar resto de cambios (3-5)
- [ ] **Monitoreo:** Verificar coste real vs estimado
- [ ] **Documentar:** Actualizar `MEMORY.md` con resultados

---

## 🔄 Revisión Pendiente

**Crons que requieren atención manual:**

1. **🔬 Seguimiento Autoresearch Karpathy**
   - Falla con "Message failed"
   - Revisar por qué el delivery falla

2. **healthcheck:security-audit-weekly**
   - `consecutiveErrors: 2`
   - Revisar causa de fallos

3. **config-drift-check (duplicado)**
   - Decidir cuál mantener
   - Verificar que no rompe workflow

---

**Última actualización:** 2026-03-24  
**Próxima revisión:** 2026-04-24 (post-implementación)
