# 📊 Multi-Model Strategy — Resumen Ejecutivo

**Fecha:** 2026-03-24  
**Preparado por:** Lola  
**Para:** Manu  
**Documentos:** `model-strategy.md`, `model-strategy-changes-2026-03-24.md`, `model-selection-guide.md`

---

## 🎯 Qué es Esto

Una estrategia documentada para elegir el modelo correcto (Opus/Sonnet/Haiku/Flash) para cada tarea, optimizando **calidad vs coste**.

Ahora mismo no hay reglas claras → desperdicio de dinero o calidad insuficiente.

---

## 📋 Situación Actual

### Crons (29 activos)

- ✅ **20 bien configurados** (Haiku/Sonnet apropiado)
- ⚠️ **6 necesitan upgrade** Haiku → Sonnet (seguridad, análisis)
- 🔧 **3 con timeout insuficiente** (autoimprove agents)
- ❌ **1 duplicado** (config-drift-check)

### Problemas Detectados

1. **Seguridad infraprotegida:** fail2ban, rkhunter, lynis usan Haiku (análisis pobre)
2. **Google Sheets frágil:** Haiku no debuggea errores API bien → fallos frecuentes
3. **Autoimprove timeout:** 600s no bastan para 15 iteraciones
4. **Modelos implícitos:** Muchos crons sin modelo explícito → vulnerables a cambios default

---

## 💰 Impacto de Cambios Propuestos

### Coste Actual (Estimado)

- Crons: **~$16.50/mes**
- Subagents: **~$20-40/mes**
- Sesión principal: **~$30-60/mes**
- **TOTAL:** ~**$70-120/mes**

### Coste Post-Cambios

- Crons: **~$23.40/mes** (+$6.90)
- Resto: Sin cambio
- **TOTAL:** ~**$77-127/mes**

**INCREMENTO:** +$7-11/mes (+10-15%)

### Justificación

- **Seguridad crítica vale:** +$4.20/mes (fail2ban, rkhunter, lynis, security-audit)
- **Google Sheets vale:** +$1.80/mes (reduce debugging manual)
- **Garmin vale:** +$1.80/mes (mejor narrativa para ti)

---

## ✅ Recomendaciones

### Prioritarias (Hazlo Ya)

1. **Aumentar timeout autoimprove:** 600s → 900s (0 coste, arregla timeouts)
2. **Upgrade healthchecks seguridad:** Haiku → Sonnet (+$4.20/mes, crítico)
3. **Eliminar cron duplicado:** config-drift-check (limpieza)

### Importantes (Hazlo Pronto)

4. **Google Sheets → Sonnet:** +$1.80/mes (reduce fallos)
5. **Garmin weekly → Sonnet:** +$1.80/mes (mejor análisis)
6. **Explicitar modelos:** Añadir modelo a crons que usan default (0 coste, prevención)

### Opcionales (Considéralo)

7. **Reclamación bus → Sonnet:** +$0.06 one-time (cron único, junio)

---

## 📊 Plan de Implementación

### Fase 1: Validar (1 semana)

```bash
# Aplicar solo cambios críticos
- Timeouts autoimprove (900s)
- Healthchecks → Sonnet
```

**Objetivo:** Verificar mejora sin romper nada

### Fase 2: Completar (1 semana después)

```bash
# Si Fase 1 OK, aplicar resto
- Google Sheets → Sonnet
- Garmin → Sonnet
- Explicitar modelos Haiku
```

**Objetivo:** Optimización completa

### Fase 3: Monitorear (1 mes)

```bash
# Verificar métricas
- Autoimprove sin timeouts
- Google Sheets <2 errores/mes
- Coste dentro de +$15/mes
```

**Objetivo:** Confirmar éxito

---

## 🎓 Documentos Entregados

### 1. `memory/model-strategy.md` (12 KB)
**Qué es:** Estrategia completa, decision tree, casos de uso  
**Para quién:** Lola (referencia detallada)

### 2. `memory/model-strategy-changes-2026-03-24.md` (9 KB)
**Qué es:** Comandos específicos, análisis de cambios, rollback plan  
**Para quién:** Manu (para aprobar/ejecutar)

### 3. `memory/model-selection-guide.md` (7 KB)
**Qué es:** Guía rápida con decision tree y ejemplos  
**Para quién:** Lola/subagents (referencia diaria)

### 4. Este resumen (este archivo)
**Qué es:** TL;DR ejecutivo  
**Para quién:** Manu (para decidir rápido)

---

## ❓ Preguntas Frecuentes

### ¿Por qué no usar siempre Opus?
**R:** Opus cuesta 5× más que Sonnet, 15× más que Haiku. Para crons rutinarios, es desperdicio.

### ¿Por qué no usar siempre Haiku?
**R:** Haiku falla en análisis complejo. Seguridad y debugging requieren Sonnet.

### ¿Por qué no usar más Flash?
**R:** Flash es muy limitado para razonamiento. Solo vale para bulk tasks mecánicos.

### ¿Puedo confiar en Flash para verificación?
**R:** Depende. Links rotos: sí. Código complejo: no.

### ¿Cuánto cuesta añadir un cron nuevo?
**R:** Haiku: ~$0.30/mes. Sonnet: ~$1.80/mes. Opus: ~$9/mes.

### ¿Qué pasa si me paso de presupuesto?
**R:** Revisamos la estrategia, downgrades selectivos a Haiku/Flash.

---

## 🚦 Decisión Requerida

**Manu, elige:**

### ✅ Opción A: APROBAR TODO
- Aplicar las 3 fases
- Coste: +$7-11/mes
- Beneficio: Mejor seguridad, menos errores, mejor calidad

### 🟡 Opción B: SOLO PRIORITARIO
- Aplicar solo Fase 1 (timeouts + seguridad)
- Coste: +$4.20/mes
- Beneficio: Arregla lo crítico, pospone lo demás

### 🔴 Opción C: RECHAZAR
- No aplicar cambios
- Coste: $0
- Riesgo: Continúan timeouts, fallos de seguridad, errores Google Sheets

---

## 📅 Próximos Pasos (Si Apruebas)

1. **Tú:** Elige opción (A/B/C)
2. **Lola:** Aplica cambios según tu elección
3. **Ambos:** Revisamos resultados en 1 semana
4. **Lola:** Informe mensual con métricas (coste, errores, calidad)

---

## 💬 Feedback Esperado

**Dime:**
- ¿Qué opción eliges? (A/B/C)
- ¿Tienes dudas sobre algún cambio específico?
- ¿El presupuesto +$11/mes es aceptable?
- ¿Quieres ver algún análisis adicional?

---

**TL;DR:** Tenemos 29 crons, 6 necesitan mejor modelo (+$7/mes), 3 necesitan más tiempo (gratis). ¿Aplicamos?

---

**Archivos generados:**
- ✅ `memory/model-strategy.md`
- ✅ `memory/model-strategy-changes-2026-03-24.md`
- ✅ `memory/model-selection-guide.md`
- ✅ `memory/model-strategy-executive-summary.md` (este)

**Tiempo invertido:** ~40 min  
**Entregables completados:** 4/4
