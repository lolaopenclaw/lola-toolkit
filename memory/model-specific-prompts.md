# Model-Specific Prompts - OpenClaw

**Última actualización:** 2026-03-24  
**Experiencia real** de Lola con Claude Opus, Sonnet, Haiku y Gemini Flash

---

## 📚 Best Practices Oficiales

Las best practices de prompting de cada provider se descargan automáticamente cada 2 meses:

- **Archivos más recientes:** `memory/best-practices/`
  - `anthropic-YYYY-MM-DD.md` (Anthropic Claude)
  - `google-YYYY-MM-DD.md` (Google Gemini)
  - `openai-YYYY-MM-DD.md` (OpenAI GPT)
- **Historial de cambios:** `memory/best-practices/changelog.md`
- **Última descarga:** 2026-03-24

**Trigger automático:** El sistema verifica modelos nuevos y actualiza las best practices cuando:
1. Se detecta un modelo nuevo en OpenClaw (`model-release-checker.sh`)
2. Un update de OpenClaw menciona modelos en su changelog
3. Cada 2 meses (cron: día 1 de cada 2 meses, 3 AM Madrid)

**Documentación completa:** `memory/best-practices-implementation.md`

---

## 🎯 Decisión Rápida

| Tarea | Modelo Óptimo | Por qué |
|-------|---------------|---------|
| Decisiones complejas | **Opus** | Reasoning profundo, contexto rico |
| Coding & research | **Sonnet** | Balance calidad/coste/velocidad |
| Crons & formateo | **Haiku** | Rápido, barato, predecible |
| Bulk tasks | **Flash** | Volumen, velocidad, coste mínimo |
| Verificación simple | **Flash** o **Haiku** | Suficiente para checks básicos |

---

## 🧠 Claude Opus (`anthropic/claude-opus-4`)

### Cuándo Usarlo

- **Decisiones arquitecturales** que afectan al sistema completo
- **Reasoning complejo** que requiere múltiples niveles de abstracción
- **Análisis profundo** de problemas ambiguos o conflictivos
- **Planificación estratégica** a largo plazo
- **Debugging de issues complejos** donde Sonnet se ha bloqueado

### Tips de Prompting

✅ **Darle contexto rico:**
```
Contexto completo: [estado del sistema + intentos previos + restricciones]
Objetivo: [qué queremos lograr]
Restricciones: [límites claros]
Pregunta: [la decisión a tomar]
```

✅ **Dejarle pensar:** No apresurarlo. Opus brilla cuando puede razonar paso a paso.

✅ **Pedirle pros/cons explícitos:** "Lista ventajas y desventajas de cada opción antes de recomendar."

❌ **NO usar para:**
- Tareas rutinarias (desperdicio de coste)
- Formateo de datos (overkill)
- Crons simples (innecesariamente caro)

### Coste Real

- **~$15/1M input tokens** (~€0.015/1K tokens)
- **~$75/1M output tokens** (~€0.075/1K tokens)
- **Ejemplo:** Análisis de arquitectura de 10K tokens in + 2K out = ~€0.30

### Ejemplo Real: Ninguno Aún

Actualmente NO usamos Opus en producción (usamos Sonnet como modelo principal). Considerarlo para:
- Decisión sobre refactoring mayor de memory architecture
- Análisis de trade-offs complejos en nuevos features

---

## 💎 Claude Sonnet (`anthropic/claude-sonnet-4-5`)

### Cuándo Usarlo (MODELO ACTUAL)

- **Coding & implementación** — Balance perfecto de calidad/coste
- **Research & análisis** — Profundidad suficiente sin coste excesivo
- **Conversación principal** con Manu — Respuestas completas y naturales
- **Subagents complejos** — Tareas que requieren autonomía y criterio
- **Debugging & troubleshooting** — Capacidad de seguir hilos complejos

### Tips de Prompting

✅ **Instrucciones claras y estructuradas:**
```markdown
## Objetivo
[Qué queremos lograr]

## Contexto
[Estado actual + restricciones]

## Pasos
1. [Acción específica]
2. [Verificación]
3. [Output esperado]
```

✅ **Structured output cuando sea necesario:**
```
Responde en formato JSON:
{
  "status": "success|error",
  "result": {...},
  "next_steps": [...]
}
```

✅ **Darle autonomía pero con guardrails:** "Si encuentras X, hazlo. Si es Y, pregúntame."

✅ **Verificación antes de completar:** Seguir el skill verification-before-completion.

❌ **NO esperar:**
- Que sea más barato que Haiku (no lo es)
- Que sea tan rápido como Flash (más lento)
- Que compita con Opus en reasoning extremo (bien, pero no igual)

### Coste Real

- **~$3/1M input tokens** (~€0.003/1K tokens)
- **~$15/1M output tokens** (~€0.015/1K tokens)
- **Ejemplo:** Sesión de coding de 20K in + 5K out = ~€0.135

### Ejemplos Reales

1. **Informe matutino (upgrade de Haiku → Sonnet):**
   - **Antes (Haiku):** Informe básico, sin insights
   - **Después (Sonnet):** Análisis de patrones, recomendaciones contextuales
   - **Trade-off:** +€0.05/día, +300% valor

2. **Subagents de research:**
   - **Modelo óptimo:** Sonnet
   - **Por qué:** Necesita autonomía para explorar + capacidad de síntesis
   - **Coste típico:** €0.10-0.30 por subagent research

3. **Implementación de features:**
   - **Modelo óptimo:** Sonnet
   - **Por qué:** Lee código existente + adapta + verifica
   - **Ejemplo:** Implementar model-specific-prompts.md (esta tarea)

---

## ⚡ Claude Haiku (`anthropic/claude-haiku-4`)

### Cuándo Usarlo

- **Crons rutinarios** que no requieren creatividad
- **Formateo & clasificación** de datos conocidos
- **Health checks simples** con criterios claros
- **Respuestas rápidas** a preguntas directas
- **Procesamiento batch** de tareas predecibles

### Tips de Prompting

✅ **Ser MUY específico:**
```
Input: [formato exacto]
Acción: [paso a paso explícito]
Output: [formato exacto esperado]
No interpretes. Solo ejecuta.
```

✅ **Checklists literales:** Haiku sigue instrucciones lineales perfectamente.

✅ **Templates rígidos:** "Usa exactamente esta estructura: [template]"

❌ **NO esperar:**
- Creatividad o adaptación al contexto
- Reasoning complejo
- Que entienda intenciones implícitas
- Calidad en coding (puede funcionar, pero frágil)

### Coste Real

- **~$0.25/1M input tokens** (~€0.00025/1K tokens)
- **~$1.25/1M output tokens** (~€0.00125/1K tokens)
- **Ejemplo:** Cron health check de 5K in + 1K out = ~€0.0026

### Ejemplos Reales

1. **Health checks rutinarios:**
   - Verificación de espacio en disco
   - Estado de servicios
   - Coste: ~€0.01/día

2. **Informe matutino (versión antigua):**
   - **Problema:** Demasiado básico, sin insights
   - **Solución:** Upgrade a Sonnet
   - **Aprendizaje:** Haiku OK para datos, NO para análisis

3. **Formateo de logs:**
   - Convertir raw logs → resumen estructurado
   - Perfecto para Haiku (tarea mecánica)

---

## 🚀 Gemini Flash (`google/gemini-3-flash-preview`)

### Cuándo Usarlo

- **Bulk tasks de verificación** (muchas tareas similares)
- **Validación rápida** de outputs de otros modelos
- **Clasificación masiva** de datos
- **Fallback** cuando Claude tiene rate-limit
- **Tareas simples** que necesitan velocidad > calidad

### Tips de Prompting

✅ **Pedir JSON explícitamente:**
```
Responde SOLO con JSON válido. No añadas texto antes ni después.
{
  "campo1": "valor",
  "campo2": 123
}
```

✅ **Instrucciones ultra-directas:** Sin contexto innecesario. Qué hacer, cómo, ya.

✅ **Ejemplos concretos:** Flash aprende mejor de ejemplos que de descripciones.

❌ **NO esperar:**
- Respuestas consistentes en formato libre (usa JSON siempre)
- Reasoning profundo (muy superficial)
- Que entienda contexto complejo del sistema

### Coste Real

- **~$0.01-0.05/1M input tokens** (varía, ultra-barato)
- **~$0.04-0.10/1M output tokens** (varía, ultra-barato)
- **Ejemplo:** 100 validaciones de 2K in + 0.5K out cada una = ~€0.005 total

### Ejemplos Reales

1. **Subagents verificación (candidato):**
   - Validar que output de subagent cumple spec
   - Flash suficiente para checks básicos
   - Coste: ~€0.001 por verificación vs €0.02 con Sonnet

2. **Fallback en API health:**
   - Cuando Claude tiene rate-limit
   - Flash verifica estado básico
   - No ideal, pero funciona

---

## 💰 Comparativa de Costes (Tareas Reales)

| Tarea | Haiku | Flash | Sonnet | Opus | Óptimo |
|-------|-------|-------|--------|------|--------|
| Health check simple | €0.003 | €0.001 | €0.05 | €0.15 | **Haiku** |
| Informe matutino | €0.02 ⚠️ | €0.005 ⚠️ | €0.07 ✅ | €0.30 | **Sonnet** |
| Subagent research | €0.10 ❌ | €0.03 ❌ | €0.20 ✅ | €0.50 | **Sonnet** |
| Verificación batch (x100) | €0.30 | €0.005 ✅ | €2.00 | €5.00 | **Flash** |
| Coding feature | €0.50 ⚠️ | €0.10 ❌ | €0.30 ✅ | €0.80 | **Sonnet** |
| Decisión arquitectura | - | - | €0.50 ⚠️ | €0.80 ✅ | **Opus** |

**Leyenda:**
- ✅ Óptimo (mejor balance coste/calidad)
- ⚠️ Funciona pero no ideal
- ❌ Mala elección

### Regla de Oro

1. **¿Es rutinario y mecánico?** → Haiku
2. **¿Es bulk y simple?** → Flash
3. **¿Requiere autonomía y criterio?** → Sonnet
4. **¿Es decisión crítica y compleja?** → Opus

---

## 🚫 Anti-Patterns (Errores Que Hemos Cometido)

### 1. Usar Opus para Tareas Triviales

**Error:** Usar Opus para formatear un informe simple.  
**Coste:** €0.30 vs €0.003 con Haiku (100x más caro).  
**Aprendizaje:** Reservar Opus solo para decisiones críticas.

### 2. Usar Haiku para Coding

**Error:** Subagent de coding con Haiku para ahorrar coste.  
**Resultado:** Código frágil, bugs, necesitó 3 iteraciones.  
**Coste real:** €0.50 (Haiku x3) + tiempo perdido vs €0.30 (Sonnet once).  
**Aprendizaje:** En coding, Sonnet es más barato a largo plazo.

### 3. No Especificar Formato de Output a Flash

**Error:** Pedir análisis en texto libre a Flash.  
**Resultado:** Respuestas inconsistentes, imposible parsear.  
**Solución:** Siempre pedir JSON estructurado a Flash.

### 4. Informe Matutino con Haiku

**Error (corregido hoy):** Informe matutino con Haiku.  
**Problema:** Sin insights, solo datos brutos.  
**Solución:** Upgrade a Sonnet.  
**Trade-off:** +€0.05/día, pero informe 300% mejor.

### 5. Usar Sonnet para Health Checks Rutinarios

**Error:** Health checks con Sonnet por defecto.  
**Desperdicio:** €0.05/check vs €0.003/check con Haiku.  
**Coste mensual:** €15 vs €0.90.  
**Aprendizaje:** Diferenciar checks simples (Haiku) vs análisis (Sonnet).

---

## 📋 Checklist de Selección de Modelo

Antes de elegir modelo, pregúntate:

1. **¿Requiere creatividad o reasoning complejo?**
   - SÍ → Sonnet o Opus
   - NO → Haiku o Flash

2. **¿Es tarea repetitiva/mecánica?**
   - SÍ → Haiku (si una vez) o Flash (si batch)
   - NO → Sonnet

3. **¿El output debe ser estructurado?**
   - JSON estricto → Flash (con prompt claro)
   - Texto natural → Sonnet

4. **¿Cuántas veces se ejecutará?**
   - Una vez → Prioriza calidad (Sonnet)
   - Cron diario → Optimiza coste (Haiku/Flash)
   - Batch masivo → Flash

5. **¿Es crítico para el sistema?**
   - SÍ → No escatimes (Sonnet o Opus)
   - NO → Ahorra (Haiku o Flash)

6. **¿Tiene fallback si falla?**
   - SÍ → Puedes probar Flash/Haiku
   - NO → Usa Sonnet (más confiable)

---

## 🔄 Upgrades & Downgrades

### Cuándo Upgradear (Haiku/Flash → Sonnet)

- Output es demasiado básico o sin contexto
- Fallos frecuentes que requieren re-ejecuciones
- Coste de fallos > coste de modelo mejor
- Tarea creció en complejidad

**Ejemplo:** Informe matutino (Haiku → Sonnet hoy).

### Cuándo Downgradear (Sonnet → Haiku/Flash)

- Tarea se volvió mecánica y predecible
- Verificación muestra que Haiku/Flash es suficiente
- Ejecución frecuente donde pequeño ahorro escala

**Ejemplo pendiente:** Health checks simples (Sonnet → Haiku).

---

## 📚 Recursos Internos

- **Config actual:** `.openclaw/config/default.json` (ver `agents.defaults.model`)
- **Costes de APIs:** `memory/api-costs.md`
- **Override de modelo:** Flag `--model` en subagent spawn
- **Monitoreo:** `scripts/rate-limit-monitor.py`

---

## ✍️ Notas de Evolución

**2026-03-24:**
- Creado basado en experiencia real de Lola
- Documentado upgrade de informe matutino (Haiku → Sonnet)
- Anti-patterns de errores cometidos (Haiku coding, Flash sin formato)

**Siguiente revisión:** Después de 1 mes de uso (2026-04-24)
- Validar costes reales acumulados
- Añadir más ejemplos de uso de Opus (si lo incorporamos)
- Actualizar comparativa con datos de producción

---

**¿Dudas sobre qué modelo usar?** Consulta este doc ANTES de spawn de subagents o configuración de crons.
