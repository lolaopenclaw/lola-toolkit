# 🤖 Multi-Model Strategy para OpenClaw

**Última actualización:** 2026-03-24  
**Owner:** Lola (lolaopenclaw@gmail.com)  
**Objetivo:** Optimizar calidad/coste eligiendo el modelo correcto para cada tipo de tarea.

---

## 📊 Modelos Disponibles

### Claude (Anthropic)

#### **Opus 4.5** (`anthropic/claude-opus-4-5`)
- **Coste:** ~$15/M tokens input, ~$75/M tokens output
- **Fortalezas:** Razonamiento profundo, decisiones críticas, creatividad
- **Debilidades:** Muy caro, overkill para tareas simples
- **Uso:** Sesión principal (Manu → Lola), decisiones estratégicas

#### **Sonnet 4.5** (`anthropic/claude-sonnet-4-5`)
- **Coste:** ~$3/M tokens input, ~$15/M tokens output
- **Fortalezas:** Excelente equilibrio calidad/coste, coding, research, análisis
- **Debilidades:** Más caro que Haiku/Flash para tareas simples
- **Uso:** Subagents complejos, implementación, investigación

#### **Haiku 4.5** (`anthropic/claude-haiku-4-5`)
- **Coste:** ~$1/M tokens input, ~$5/M tokens output
- **Fortalezas:** Rápido, barato, suficiente para tareas rutinarias
- **Debilidades:** Menos capaz en razonamiento complejo
- **Uso:** Crons rutinarios, formateo, monitorización, verificación simple

### Google (Gemini)

#### **Flash 3** (`google/gemini-3-flash-preview`)
- **Coste:** ~$0.075/M tokens input, ~$0.30/M tokens output (13x más barato que Haiku)
- **Fortalezas:** Extremadamente barato, bueno para bulk tasks, verificación
- **Debilidades:** Menos capaz que Claude en razonamiento/coding
- **Uso:** Subagents simples, verificación, tareas repetitivas

---

## 🎯 Estrategia por Tipo de Tarea

| Tipo de Tarea | Modelo Recomendado | Coste Estimado | Razón |
|---------------|-------------------|----------------|-------|
| **Sesión principal** | Opus 4.5 | ~$0.50-2/sesión | Interacción humana requiere máxima calidad |
| **Deep research** | Sonnet 4.5 | ~$0.50-2 | Balance perfecto calidad/coste |
| **Coding/implementation** | Sonnet 4.5 | ~$0.30-1 | Excelente para desarrollo |
| **Subagent complejo** | Sonnet 4.5 | ~$0.20-0.80 | Requiere razonamiento sólido |
| **Subagent simple** | Flash 3 | ~$0.01-0.05 | Tareas bien definidas |
| **Verification/testing** | Flash 3 | ~$0.01-0.05 | Bajo coste, alta frecuencia |
| **Cron rutinario** | Haiku 4.5 | ~$0.01-0.03 | Fiable, económico |
| **Cron crítico** | Sonnet 4.5 | ~$0.05-0.15 | Seguridad/backup requieren calidad |
| **Formateo/resumen** | Haiku 4.5 | ~$0.01 | Tarea mecánica |
| **Bulk tasks** | Flash 3 | ~$0.001-0.01/item | Volumen alto |

---

## 🔄 Crons Actuales: Asignación de Modelos

### ✅ Bien Configurados (Haiku)

1. **🏠 Driving Mode Auto-Reset** — ✅ Haiku (implícito, por config default)
   - Tarea: Actualizar JSON simple
   - Razón: Mecánico, bajo riesgo

2. **🔄 Model Reset Nightly** — ✅ Haiku
   - Tarea: Verificar config, resetear si necesario
   - Razón: Rutinario, bajo coste

3. **🔄 System Updates Nightly** — ✅ Haiku
   - Tarea: Aplicar actualizaciones apt
   - Razón: Script automatizado, bajo riesgo

4. **💾 Backup diario memoria** — ✅ Haiku
   - Tarea: Ejecutar script backup
   - Razón: Script automatizado, generación de reporte

5. **🧠 Memory Search Reindex** — ✅ Haiku
   - Tarea: Reindexar memoria
   - Razón: Tarea mecánica

6. **🌊 Surf Conditions Daily** — ✅ Haiku
   - Tarea: Ejecutar script surf
   - Razón: Script automatizado

7. **🧠 Memory Guardian Pro** — ✅ Haiku
   - Tarea: Limpieza automática
   - Razón: Script con lógica definida

8. **🧹 Cleanup audit semanal** — ✅ Haiku
   - Tarea: Auditoría de limpieza
   - Razón: Reporte automatizado

9. **🗑️ Backup retention cleanup** — ✅ (no especifica, usa default)
   - Tarea: Limpiar backups viejos
   - **RECOMENDACIÓN:** Añadir `"model": "anthropic/claude-haiku-4-5"` explícito

10. **📋 Backup validation** — ✅ (no especifica)
    - Tarea: Validar backups
    - **RECOMENDACIÓN:** Añadir `"model": "anthropic/claude-haiku-4-5"`

11. **🔧 Lola Toolkit Sync Check** — ✅ Haiku
    - Tarea: Comparar repos
    - Razón: Verificación automatizada

12. **🔬 Seguimiento Autoresearch** — ✅ Haiku
    - Tarea: Trackear cambios GitHub
    - Razón: Monitorización automatizada

13. **🔔 OpenClaw release check** — ✅ Haiku
    - Tarea: Comparar versiones
    - Razón: Verificación simple

14. **🚗 Driving Mode Review** — ✅ (no especifica)
    - Tarea: Buscar mejoras
    - **RECOMENDACIÓN:** Añadir `"model": "anthropic/claude-haiku-4-5"`

15. **security:rotate-gateway-token** — ✅ Haiku
    - Tarea: Rotar token automáticamente
    - Razón: Script con pasos definidos

### ⚠️ Requieren Modelo Más Potente (Sonnet)

16. **📊 Populate Google Sheets v2** — ⚠️ **Cambiar a Sonnet**
    - Actual: Haiku
    - Problema: Manejo de errores Python, integración API compleja
    - **RECOMENDACIÓN:** Usar Sonnet para mejor debugging

17. **📋 Informe Matutino** — ✅ **YA USA SONNET**
    - Razón: Síntesis compleja, múltiples fuentes, presentación a humano

18. **🏃 Resumen Semanal Actividades Garmin** — ⚠️ **Sin modelo especificado**
    - Tarea: Análisis semanal salud
    - **RECOMENDACIÓN:** Usar Sonnet (análisis + narrativa)

19. **healthcheck:rkhunter-scan-weekly** — ⚠️ **Cambiar a Sonnet**
    - Actual: Haiku
    - Problema: Análisis de seguridad, interpretación de logs
    - **RECOMENDACIÓN:** Sonnet para mejor análisis

20. **healthcheck:lynis-scan-weekly** — ⚠️ **Cambiar a Sonnet**
    - Actual: Haiku
    - Problema: Comparación compleja, decisiones de alerta
    - **RECOMENDACIÓN:** Sonnet para análisis preciso

21. **healthcheck:security-audit-weekly** — ⚠️ **Cambiar a Sonnet**
    - Actual: Haiku
    - Problema: Auditoría profunda, decisiones críticas
    - **RECOMENDACIÓN:** Sonnet para seguridad

22. **healthcheck:fail2ban-alert** — ⚠️ **Cambiar a Sonnet**
    - Actual: No especifica (usa default)
    - Problema: Análisis de seguridad, alertas críticas
    - **RECOMENDACIÓN:** Sonnet para decisiones de alerta

### 🔬 Autoimprove Agents (Especiales)

23. **🔬 Autoimprove Scripts Agent** — ✅ Haiku (correcto)
    - Razón: Itera en cambios pequeños, 15 intentos
    - Problema actual: **TIMEOUT** (600s no bastan)
    - **RECOMENDACIÓN:** Mantener Haiku pero aumentar timeout a 900s

24. **🔬 Autoimprove Skills Agent** — ✅ Haiku (correcto)
    - Razón: Optimización de tokens, cambios mecánicos
    - Problema actual: **TIMEOUT**
    - **RECOMENDACIÓN:** Mantener Haiku, aumentar timeout a 900s

25. **🔬 Autoimprove Memory Agent** — ✅ Haiku (correcto)
    - Razón: Consolidación de memoria, cambios mecánicos
    - Problema actual: **TIMEOUT**
    - **RECOMENDACIÓN:** Mantener Haiku, aumentar timeout a 900s

### 🆕 Sin Modelo Asignado

26. **config-drift-check** (duplicado) — ⚠️ Usar Haiku
27. **memory-decay-weekly** — ✅ YA USA HAIKU

### ⏱️ Crons Con Timeout

28. **Seguimiento reclamación bus** — ⚠️ Sin modelo especificado
    - **RECOMENDACIÓN:** Usar Sonnet (interacción humana compleja)

---

## 🎬 Plan de Acción

### 1. Cambios Inmediatos (Modelo)

```bash
# Actualizar crons que necesitan Sonnet (seguridad crítica)
openclaw cron update healthcheck:fail2ban-alert --model anthropic/claude-sonnet-4-5
openclaw cron update healthcheck:rkhunter-scan-weekly --model anthropic/claude-sonnet-4-5
openclaw cron update healthcheck:lynis-scan-weekly --model anthropic/claude-sonnet-4-5
openclaw cron update healthcheck:security-audit-weekly --model anthropic/claude-sonnet-4-5

# Actualizar Google Sheets (requiere mejor manejo de errores)
openclaw cron update "📊 Populate Google Sheets v2" --model anthropic/claude-sonnet-4-5

# Añadir modelo explícito a crons sin especificar
openclaw cron update "🗑️ Backup retention cleanup (lunes)" --model anthropic/claude-haiku-4-5
openclaw cron update "📋 Backup validation (weekly)" --model anthropic/claude-haiku-4-5
openclaw cron update "🚗 Driving Mode - Review for Improvements" --model anthropic/claude-haiku-4-5
openclaw cron update "memory-decay-weekly" --model anthropic/claude-haiku-4-5  # confirmar
openclaw cron update "🏃 Resumen Semanal de Actividades Garmin" --model anthropic/claude-sonnet-4-5
openclaw cron update "Seguimiento reclamación bus Logroño (3 meses)" --model anthropic/claude-sonnet-4-5
```

### 2. Cambios Timeout (Autoimprove)

```bash
# Aumentar timeout de autoimprove agents
openclaw cron update "🔬 Autoimprove Scripts Agent" --timeout 900
openclaw cron update "🔬 Autoimprove Skills Agent" --timeout 900
openclaw cron update "🔬 Autoimprove Memory Agent" --timeout 900
```

### 3. Eliminar Duplicado

```bash
# Hay 2 config-drift-check, eliminar el que no tiene ID específico
openclaw cron delete config-drift-check  # revisar cuál
```

---

## 💰 Estimación de Impacto en Coste

### Coste Actual (Estimado)

- **Crons con Haiku:** 20 × ~$0.02/día = **~$0.40/día** = **$12/mes**
- **Informe Matutino (Sonnet):** 1 × ~$0.10/día = **~$0.10/día** = **$3/mes**
- **Autoimprove agents (Haiku, 3):** 3 × ~$0.05/día = **~$0.15/día** = **$4.50/mes**
- **Subagents (mix Sonnet/Flash):** Variable, ~**$20-40/mes**
- **Sesión principal (Opus):** Variable, ~**$30-60/mes**

**TOTAL ACTUAL:** ~**$70-120/mes**

### Coste Post-Cambios

- **Crons Haiku:** 15 × ~$0.02/día = **$9/mes**
- **Crons Sonnet (seguridad+críticos):** 6 × ~$0.08/día = **~$14.40/mes**
- **Informe Matutino:** **$3/mes** (sin cambio)
- **Autoimprove (Haiku):** **$4.50/mes** (sin cambio)
- **Subagents:** **$20-40/mes** (sin cambio)
- **Sesión principal:** **$30-60/mes** (sin cambio)

**TOTAL POST-CAMBIOS:** ~**$81-131/mes**

**INCREMENTO:** ~**$11/mes** (+15%)

### Justificación del Incremento

- **Seguridad crítica** (fail2ban, rkhunter, lynis, security-audit): Vale la pena Sonnet
- **Google Sheets:** Reduce errores y debugging manual (ahorro de tiempo > coste)
- **Garmin weekly:** Mejor narrativa y análisis

---

## 🚀 Guía para Futuros Subagents

### Decision Tree

```
¿La tarea requiere razonamiento complejo o decisiones críticas?
├─ SÍ → ¿Es crítica para seguridad/datos?
│   ├─ SÍ → SONNET 4.5
│   └─ NO → ¿Interacción directa con humano?
│       ├─ SÍ → SONNET 4.5
│       └─ NO → FLASH 3 (si budget es crítico) o SONNET 4.5
└─ NO → ¿Es tarea bien definida/mecánica?
    ├─ SÍ → ¿Alto volumen?
    │   ├─ SÍ → FLASH 3
    │   └─ NO → HAIKU 4.5
    └─ NO → SONNET 4.5 (default conservador)
```

### Ejemplos Prácticos

#### Usar **Opus** 🟣
- Sesión principal Manu → Lola
- Decisiones estratégicas importantes
- Creatividad (música, contenido para redes)

#### Usar **Sonnet** 🔵
- Implementar feature completo
- Research profundo (surf spots, tecnología)
- Análisis de seguridad
- Informe matutino
- Debugging código complejo
- Análisis de datos Garmin

#### Usar **Haiku** 🟢
- Cron de backup rutinario
- Limpiar archivos temporales
- Verificar estado de servicios
- Formatear datos simples
- Memory Guardian (lógica definida)

#### Usar **Flash** 🟡
- Verificar 100 links de surf spots
- Extraer datos de múltiples PDFs
- Comparar archivos para duplicados
- Subagent que solo ejecuta comandos pre-definidos

---

## 📋 Checklist de Configuración

Cuando creas un nuevo cron/subagent:

- [ ] ¿La tarea es crítica? → Considera Sonnet
- [ ] ¿Requiere razonamiento? → No uses Flash
- [ ] ¿Es alto volumen? → Considera Flash
- [ ] ¿Es rutinario/mecánico? → Haiku es suficiente
- [ ] ¿Timeout actual es suficiente? (min 300s para Autoimprove)
- [ ] ¿El modelo está **explícitamente** especificado en el payload?
- [ ] ¿El coste mensual estimado es razonable? (<$5/mes por cron)

---

## 🔄 Revisión Periódica

**Frecuencia:** Mensual (añadir a informe mensual)

**Preguntas:**
1. ¿Algún cron está fallando repetidamente? → Revisar si necesita modelo más potente
2. ¿Algún cron Sonnet es muy simple? → Downgrade a Haiku
3. ¿Hay nuevos modelos disponibles? → Evaluar integración
4. ¿El coste mensual está dentro de presupuesto? → Ajustar estrategia

---

## 📚 Referencias

- [OpenClaw Model Configuration](https://docs.openclaw.ai/models)
- [Anthropic Pricing](https://www.anthropic.com/pricing)
- [Google Gemini Pricing](https://ai.google.dev/pricing)
- `memory/token-usage-YYYY-MM.md` — Tracking mensual de consumo
- `memory/model-strategy-changelog.md` — Historial de cambios a esta estrategia

---

**Próxima revisión:** 2026-04-24
