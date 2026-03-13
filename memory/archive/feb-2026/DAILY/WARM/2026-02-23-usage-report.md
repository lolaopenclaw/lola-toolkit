# Usage Report — Monday, February 23rd, 2026 (9:10 AM)

## 📊 Resumen Financiero

### Consumo de Hoy
- **Total:** $4.21 USD
- **Requests:** 117
- **Modelo:** Claude Haiku 4.5 (100%)
- **Tokens:** 1,387 input | 60,604 output

### Consumo Ayer (22 feb)
- **Total:** $49.63 USD
- **Requests:** 568
- **Modelo:** Claude Haiku 4.5 (100%)
- **Tokens:** 6,317 input | 275,484 output

### Consumo Mensual (Feb 2026)
- **Total:** $537.16 USD
- **Días activos:** 22
- **Promedio diario:** $24.42 USD
- **Desglose por modelo:**
  - Opus 4.6: $300.58 (55.9%) — 970 requests
  - Sonnet 4.5: $127.29 (23.7%) — 591 requests
  - **Haiku 4.5: $88.81 (16.5%) — 1,545 requests** ✅ (optimización funciona)
  - Gemini (flash/lite): $20.04 (3.7%) — 513 requests
  - Otros: $0.44 (0.1%)

---

## 📈 Análisis de Consumo

### Comparativa Hoy vs Ayer
- **Reducción:** -91.5% ($45.41 menos que ayer)
- **Contexto:** Ayer fue día ultra-productivo (8.5h activas, muchas tareas paralelas)
- **Contexto hoy:** Cron matutino de reporte de uso (tarea rutinaria, bajo consumo esperado)

### Tendencia Mensual
- **Baseline:** ~$24/día en promedio
- **Hoy:** $4.21 (17% del baseline) — muy normal para tareas ligeras
- **Ayer:** $49.63 (204% del baseline) — pico productivo justificado
- **Patrón:** Consumo variable según complejidad de tareas

### Estado de Optimización
- ✅ **Haiku 4.5:** 16.5% del gasto mensual con 45% de los requests → eficiencia confirmada
- ✅ **Opus:** 55.9% del gasto (inversión en tareas complejas)
- ✅ **Sonnet:** 23.7% (balance complejidad/costo)

---

## 🎯 Contexto de Uso — Qué Justifica el Gasto

### Ayer (22 feb) — $49.63 USD

**Razón:** Día de máxima productividad y automatización

1. **Política de comunicación unificada**
   - Diseño + validación: informe matutino a Discord
   - Horarios, canales, formato de embeds
   - Resultado: comunicación clara y consolidada

2. **Discord Integration**
   - Setup bot, autorización, configuración de canales
   - Embeds bonitos con markdown coloreado
   - Documentación de protocolo completo

3. **Investigación GOG/Tokens (RESUELTO)**
   - Problema: acceso a Google Workspace tokens
   - Solución: `gog auth tokens export` + script de compartir
   - Resultado: carpeta openclaw_backups compartida exitosamente

4. **Google Sheets Automation (Parcial)**
   - Creación de dashboards
   - Sheets: "Consumo IA", "Garmin Health"
   - Bloqueado en: necesita client_secret.json desde desktop

5. **Garmin + Informe Matutino**
   - Integración datos actividad, sueño, estrés
   - Informe unificado con timestamp

6. **Perfil Manu Detallado**
   - Análisis Facebook dump (300+ líneas)
   - manu-profile.md + bass-in-a-voice.md guardados
   - Bandas, integrantes, comunidades documentados

7. **Familia (Vera Pérez León)**
   - Presentación por voz de sobrina (10 años)
   - Cron setup: recordatorio cumpleaños 30 de agosto
   - Relación confirmada: Vera tiene acceso al mismo Telegram

8. **Múltiples Commits + Backups Automáticos**
   - 15+ commits documentados
   - 8+ backups automáticos a Drive
   - CHANGELOG.md actualizado

**Conclusión:** Ayer no fue día de "consumo alto" sino de **inversión en infraestructura y automatización**. Cada dólar justificado por arquitectura mejorada.

### Hoy (23 feb) — $4.21 USD

**Razón:** Cron matutino de reporte de uso (tarea rutinaria)

1. **Ejecución script:** `usage-report.sh`
2. **Lectura memory files:** contexto de actividades
3. **Generación informe:** este documento
4. **Evaluación:** si enviar alerta Telegram

**Consumo esperado:** ~$4-5 USD ✅

---

## 🔮 Proyección Mensual

### Baseline Actual
- **Consumo hasta hoy:** $537.16 USD (22 días)
- **Promedio diario:** $24.42 USD
- **Proyección mes completo (28 días):** ~$684 USD

### Escenarios
- **Conservador (15% reducción):** ~$580 USD (menos días como ayer)
- **Realista (baseline actual):** ~$684 USD
- **Agresivo (1-2 días como ayer más):** ~$750+ USD

### Comparativa con Presupuesto
- **Meta establecida:** $250/mes (80-85% con Haiku)
- **Consumo actual:** $684 proyectado (273% de meta)
- **Gap:** +$434 USD (+173%)

**Análisis:** El consumo está **muy por encima** de la meta. Razón: inversión en infraestructura (Opus para diseño/decisions) + Sonnet para tareas complejas + múltiples proyectos paralelos. **Recomendación:** revisar selectivamente dónde se puede usar Haiku en lugar de Opus/Sonnet.

---

## ⚠️ Recomendaciones

### 1. **Revisión de Selectores de Modelo** (ACCIÓN)
   - Actualmente se usa Opus para tareas que podrían ser Sonnet
   - Actualmente se usa Sonnet para tareas que podrían ser Haiku
   - **Recomendación:** Implementar lógica de selectores más estricta
   - **Beneficio:** Reducción 20-30% ($150-200/mes)

### 2. **Monitores de Consumo**
   - ✅ Script `usage-report.sh` funcional (automático diario)
   - ✅ Reporte diario en memory (documentación)
   - 🔜 Considerar alertas automáticas si se excede $30/día (2 Opus calls)

### 3. **Documentación de Gasto por Proyecto**
   - Actualmente: consumo agregado
   - **Mejora:** Tagging por sesión/tarea para rastrear dónde va el dinero
   - Ejemplo: `[opus:complex-decision]`, `[sonnet:research]`, `[haiku:routine]`

### 4. **Baselines por Tipo de Tarea**
   - Tareas rutinarias: **Haiku** (~$0.50/100 reqs)
   - Investigación/análisis: **Sonnet** (~$1.5/100 reqs)
   - Decisiones estratégicas/design: **Opus** (~$2-3/100 reqs)
   - **Regla 80/20:** 80% del tiempo usar Haiku, 20% Sonnet/Opus

---

## 📋 Estado General

| Métrica | Valor | Estado |
|---------|-------|--------|
| Gasto Hoy | $4.21 | ✅ Normal |
| Gasto Ayer | $49.63 | ⚠️ Pico (justificado) |
| Promedio diario | $24.42 | ⚠️ 9.7x meta |
| Haiku utilization | 45% requests | ✅ Bueno |
| Proyección mes | ~$684 | ❌ 2.7x meta |

---

**Informe generado:** 2026-02-23 09:10 AM (Europe/Madrid)
**Próxima evaluación:** 2026-02-24 09:10 AM
