# 2026-02-21 — Usage Report Diario

## 💰 Resumen Financiero

| Período | Costo | Requests | Promedio/req |
|---------|-------|----------|--------------|
| **Hoy** | $1.81 | 68 | $0.027 |
| **Ayer** | $100.16 | 533 | $0.188 |
| **Mes** | $452.05 | 2,291 | $0.197 |

### Desglose Hoy
- **claude-haiku-4-5:** $1.81 (68 requests) — 100% del consumo
- **delivery-mirror:** $0.00 (5 requests) — sin costo

---

## 📊 Análisis de Consumo

### Comparativa con Tendencias

**Hoy vs Ayer:**
- ↓ 86% menos consumo que ayer ($1.81 vs $100.16)
- ↓ 87% menos requests (68 vs 533)
- **Razón:** Ayer fue día de hardening intensivo (Lynis, auditoría seguridad, recovery system)

**Hoy vs Promedio Mensual:**
- ↓ 91% menos que promedio diario ($1.81 vs $19.66/día)
- Dentro de rango esperado para fin de semana

### Patrón Observado

| Tipo día | Costo típico | Tendencia |
|----------|--------------|-----------|
| **Trabajo intensivo** (seg, dev) | $50-150 | Spike alto |
| **Trabajo normal** | $10-20 | Estable |
| **Fin de semana/mantenimiento** | $1-5 | Bajo |

---

## 🎯 Contexto de Uso (Hoy)

**Sábado 21 Feb, 9:01 AM UTC** (fin de semana)

Actividades esperadas para hoy:
- Lectura de memoria y repaso de contexto
- Posibles tareas de mantenimiento menor
- **Sin actividades de desarrollo o auditoría programadas**
- Crons de monitoreo en background (fail2ban, auditorías semanales aún no)

**Consumo justificado:** Bajo y normal. Solo sesión de heartbeat inicial.

---

## 📈 Proyección Mensual

### Escenario Actual (Feb 2026)

**Base:** $452.05 en 21 días (desde 1 Feb)
- Promedio diario: $21.53/día
- Proyectado mes completo (28 días): **~$602.84**

### Desglose Mensual Esperado
- **Opus:** 300.58 (66%) — trabajo estratégico, debugging, investigación
- **Sonnet:** 127.29 (28%) — análisis, auditoría, scripting
- **Haiku:** 3.70 (0.8%) — tareas ligeras, heartbeats
- **Gemini (flash/lite):** 20.08 (4.4%) — vision, imágenes

### Presupuesto
- Target mensual: ~$400-500 ✅ En rango
- Feb 2026: Proyectado $602.84 ⚠️ Ligeramente alto (causa: auditoría + hardening intensivo)
- Marzo: Esperar normalización a ~$400-500

---

## ✅ Recomendaciones

| Aspecto | Status | Acción |
|---------|--------|--------|
| **Consumo hoy** | ✅ Normal | Ninguna — sábado, uso ligero esperado |
| **Tendencia mes** | ⚠️ Alto | Monitorear en próximos días; esperar normalización |
| **Modelos** | ✅ OK | Haiku prevalece en tareas menores (correcto) |
| **Proyección** | ℹ️ Info | Feb >presupuesto por auditoría; normal para próximos meses |

### Próximo Check
- Domingo 22 Feb: Consumo esperado $1-5 (fin de semana)
- Lunes 24 Feb: Ejecutar informe semanal + auditorías rutinarias
- Seguimiento presupuesto: Martes 25 Feb

---

**Generado:** 2026-02-21 09:01 UTC  
**Script:** bash ~/.openclaw/workspace/scripts/usage-report.sh  
**Período de análisis:** Febrero 2026 (21 días hasta ahora)
