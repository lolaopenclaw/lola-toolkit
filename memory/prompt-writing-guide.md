# Prompt Writing Guide — Practical Rules for OpenClaw

**Última actualización:** 2026-03-25  
**Basado en:** Best practices oficiales (Anthropic, Google, OpenAI)  
**Propósito:** Guía rápida para escribir prompts efectivos en crons y subagents

---

## 🎯 Quick Decision Tree

```
¿La tarea es rutinaria y mecánica?
├─ SÍ → Haiku (<200 palabras, bullet points, sin ejemplos)
└─ NO → ¿Requiere creatividad o análisis?
    ├─ SÍ → ¿Es decisión crítica y compleja?
    │   ├─ SÍ → Opus (contexto rico, reasoning profundo)
    │   └─ NO → Sonnet (balanced, estructura clara)
    └─ NO → ¿Es bulk/verificación masiva?
        ├─ SÍ → Flash (JSON estricto, muy directo)
        └─ NO → Sonnet (default seguro)
```

---

## 📚 Referencia a Best Practices

### Anthropic Claude
- **Archivo:** `memory/best-practices/anthropic-2026-03-24.md`
- **Modelos:** Opus 4, Sonnet 4-5, Haiku 4-5
- **Énfasis:** Clarity, examples, structured prompts (XML), avoid ALL CAPS

### Google Gemini
- **Archivo:** `memory/best-practices/google-2026-03-24.md`
- **Modelos:** Gemini 3, Gemini 3 Flash
- **Énfasis:** Direct instructions, XML/Markdown structure, explicit parameters, agentic workflows

### OpenAI GPT
- **Archivo:** `memory/best-practices/openai-2026-03-24.md`
- **Modelos:** GPT-4, GPT-5.4
- **Énfasis:** System messages, few-shot examples, structured output

---

## 🔑 Universal Rules (Todos los Modelos)

### 1. **Be Clear and Specific**
❌ "Genera un informe"  
✅ "Genera un informe de seguridad que incluya: estado de firewall, fail2ban bans, actualizaciones pendientes. Formato: Markdown con secciones."

### 2. **Define Expected Output**
❌ "Analiza los logs"  
✅ "Analiza los logs de las últimas 24h. Output: JSON con {errors: N, warnings: N, critical: [lista]}"

### 3. **Use Examples (Few-Shot) When Possible**
Anthropic y OpenAI enfatizan que **few-shot es mejor que zero-shot** para tareas con formato específico.

```markdown
## Ejemplo de formato esperado:
Input: "Error: connection timeout"
Output: {"severity": "medium", "action": "retry"}

Input: "CRITICAL: disk full"
Output: {"severity": "critical", "action": "alert"}

Ahora procesa: [tu input aquí]
```

### 4. **Separate Instructions from Data**
Google enfatiza esto para Gemini 3:

```xml
<instructions>
Analiza el siguiente texto y extrae nombres de personas.
</instructions>

<data>
[Texto a analizar aquí]
</data>
```

---

## 🦾 Model-Specific Rules

### Claude Haiku (<200 palabras, bullet points)

#### ✅ DO
- **Conciso:** Max 200 palabras, idealmente <150
- **Bullet points:** Lista numerada de pasos
- **Formato explícito:** "Output: JSON con {campo1, campo2}"
- **HEARTBEAT_OK:** Para crons silenciosos cuando no hay cambios

#### ❌ DON'T
- Explicaciones largas o contexto innecesario
- Múltiples ejemplos (1 ejemplo máximo)
- Lógica condicional compleja (mover a script)
- Prompts >300 palabras (pierde contexto)

#### 📝 Template Haiku (Cron)
```
[Acción principal en 1 frase]

Pasos:
1. [Acción específica]
2. [Verificación]
3. [Output]

Output: [Formato exacto]

Si no hay cambios: HEARTBEAT_OK
```

**Ejemplo Real:**
```
Ejecuta backup de memoria a Google Drive.

Pasos:
1. bash /path/to/backup-memory.sh
2. Verifica exit code
3. Guarda resultado en memory/last-backup.json

Output: {"date": "YYYY-MM-DD", "status": "ok|error", "size": "XXK"}

No envíes mensaje al usuario. El informe matutino lo recogerá.
```

---

### Claude Sonnet (Balanced, structure)

#### ✅ DO
- **Estructura clara:** Usar Markdown headers o XML tags
- **Contexto balanceado:** Suficiente para entender, no excesivo
- **Instrucciones paso a paso:** Numeradas o con bullets
- **Ejemplos when helpful:** 1-2 ejemplos para clarificar formato

#### ❌ DON'T
- ALL CAPS para énfasis (Anthropic desaconseja: "avoid using all caps")
- Prompts sin estructura (pared de texto)
- Repetir info que está en otros archivos del workspace

#### 📝 Template Sonnet (Cron)
```markdown
## Tarea
[Descripción breve de qué hacer]

## Contexto
[Info relevante: archivos a leer, estado actual, restricciones]

## Pasos
1. [Paso 1]
2. [Paso 2]
3. [Paso 3]

## Output Esperado
[Formato + dónde guardarlo]

## Alertas
[Condiciones que requieren atención especial]

## Silent Mode
Si no hay cambios: HEARTBEAT_OK
```

**Ejemplo Real:**
```markdown
## Tarea
Auditoría de seguridad semanal del sistema

## Contexto
- Última auditoría: memory/2026-03-18-security-audit-weekly.md
- Baseline hardening: 78% (Lynis)

## Pasos
1. Ejecutar: openclaw security audit --deep
2. Revisar estado de firewall (ufw status)
3. Revisar fail2ban bans activos
4. Comparar hardening index con baseline

## Output Esperado
Exportar a: memory/YYYY-MM-DD-security-audit-weekly.md

Formato:
- Resumen ejecutivo (3-5 líneas)
- Hallazgos por categoría
- Recomendaciones (si aplica)

## Alertas
Si encuentras vulnerabilidades críticas:
- Marca como **URGENTE** en informe
- Añade entrada en memory/pending-actions.md

## Silent Mode
Si no hay hallazgos críticos: HEARTBEAT_OK
```

---

### Claude Opus (Deep reasoning, nuance)

#### ✅ DO
- **Contexto rico:** Provee toda la info relevante
- **Preguntas abiertas:** Deja que Opus razone
- **Pros/cons explícitos:** "Lista ventajas y desventajas antes de recomendar"
- **Confía en el modelo:** No sobre-especificar

#### ❌ DON'T
- Usarlo para tareas rutinarias (desperdicio)
- Apresurarlo con timeouts muy cortos
- Sobre-especificar formato (Opus es bueno infiriendo)

#### 📝 Template Opus (Decisión Compleja)
```markdown
## Contexto Completo
[Todo lo relevante: historia, intentos previos, estado actual]

## Objetivo
[Qué queremos lograr]

## Restricciones
[Límites técnicos, de tiempo, de coste, etc.]

## Pregunta
[La decisión a tomar]

Antes de responder, analiza:
1. Pros y contras de cada opción
2. Implicaciones a largo plazo
3. Riesgos y mitigaciones
```

**Ejemplo Real:**
```markdown
## Contexto Completo
Tenemos 3 autoimprove agents (scripts, skills, memory) corriendo con Haiku.
- Scripts agent: prompt de 2400 chars, pierde contexto ocasionalmente
- Skills agent: prompt de 2300 chars, similar issue
- Memory agent: prompt de 2800 chars, crítico (optimiza MEMORY.md)

Costes actuales: €0.05/noche (Haiku) = €1.50/mes
Si upgradeamos a Sonnet: €0.11/noche = €3.30/mes (+€1.80/mes)

## Objetivo
Decidir si vale la pena upgradear a Sonnet considerando:
- Mejora de calidad de optimización
- Coste adicional
- Impacto en otros costes (si autoimprove es más efectivo, ahorra tokens en otros lados)

## Restricciones
- Budget mensual de APIs: ~€50/mes actual
- Autoimprove corre cada noche (30 veces/mes)
- La calidad de MEMORY.md impacta TODAS las sesiones

## Pregunta
¿Deberíamos upgradear los 3 autoimprove agents a Sonnet?

Analiza:
1. Pros y contras del upgrade
2. ROI esperado (coste vs beneficio)
3. Alternativas (comprimir prompts vs upgrade modelo)
4. Recomendación final
```

---

### Gemini 3 Flash (Bulk, speed, cost)

#### ✅ DO (según Google best practices)
- **JSON explícito:** "Responde SOLO con JSON válido. No añadas texto antes ni después."
- **Instrucciones ultra-directas:** Sin contexto innecesario
- **Ejemplos concretos:** Flash aprende mejor de ejemplos que de descripciones
- **Temperatura default (1.0):** NO cambiar (Google advierte: puede causar loops)

#### ❌ DON'T
- Texto libre sin estructura (inconsistente)
- Tareas que requieren reasoning profundo
- Asumir contexto complejo (Flash es superficial)

#### 📝 Template Flash (Validación Masiva)
```
Tarea: Validar que cada entrada cumple el formato.

Formato esperado:
{"name": "string", "value": number, "status": "ok|error"}

Ejemplo válido:
{"name": "test", "value": 42, "status": "ok"}

Ejemplo inválido:
{"name": "test", "value": "forty-two", "status": "ok"}  // value debe ser number

Ahora valida esta lista:
[...lista de entradas...]

Responde SOLO con JSON:
{"valid": N, "invalid": M, "errors": ["entry_id: reason", ...]}
```

---

## 🏗️ Structuring Prompts (XML vs Markdown)

### Cuándo Usar XML (Anthropic prefiere esto)

```xml
<role>
You are a security auditor.
</role>

<task>
Analyze the following system logs for security issues.
</task>

<data>
[Logs aquí]
</data>

<output_format>
JSON con: {"critical": [], "warnings": [], "info": []}
</output_format>
```

**Ventajas:**
- Clara separación de secciones
- Anthropic modelos (Claude) procesanXML nativamente
- Fácil parsear si necesitas extraer secciones

### Cuándo Usar Markdown (Google prefiere esto para Gemini 3)

```markdown
# Identity
You are a financial analyst.

# Task
Analyze Q4 expenses and identify anomalies.

# Data
[Tabla de gastos]

# Output Format
- Total spent: $X
- Anomalies: [lista]
- Recommendations: [bullets]
```

**Ventajas:**
- Más legible para humanos
- Gemini 3 lo procesa bien (según best practices)
- Natural para documentos largos

### Regla General
- **Claude (Haiku, Sonnet, Opus):** Preferir **XML** para estructura
- **Gemini 3:** Preferir **Markdown**
- **Prompts cortos (<200 palabras):** Sin estructura necesaria (solo bullets)

---

## 🚫 Anti-Patterns (Errores Comunes)

### 1. ALL CAPS para Énfasis (Claude)
❌ "Formato EXACTO", "NO borres NADA", "IMPORTANTE"  
✅ "Formato específico", "No borres nada", usar **bold** o estructura

**Por qué:** Anthropic best practices: "Avoid using all caps for emphasis"

### 2. Prompts Muy Largos para Haiku
❌ Prompt de 2000+ caracteres para Haiku  
✅ Max 200 palabras (~800 chars) para Haiku, o upgrade a Sonnet

**Por qué:** Haiku pierde contexto en prompts densos

### 3. Lógica Condicional en Prompts
❌ "Si X > 10 entonces Y, si X < 5 entonces Z, si..."  
✅ Mover lógica a script, prompt solo formatea resultado

**Por qué:** Más confiable, reutilizable, testeable

### 4. Prompt Vacío o Vago
❌ "Genera un informe"  
✅ "Genera informe de actividades Garmin de la última semana. Incluye: pasos promedio, sueño, HR reposo. Formato: Markdown."

### 5. No Especificar Modelo en Crons
❌ Dejar que cron herede modelo por defecto (puede ser Opus)  
✅ Siempre especificar `"model": "haiku"` o `"model": "sonnet"`

**Por qué:** Ahorro de coste (Opus es 50x más caro que Haiku para tareas simples)

### 6. No Usar HEARTBEAT_OK
❌ Cron siempre envía mensaje, incluso si no hay novedades  
✅ "Si no hay cambios: responde HEARTBEAT_OK" (silent)

**Por qué:** Reduce ruido en Telegram, respeta quiet hours

---

## 🎛️ Parameters (Temperature, TopP, etc.)

### Temperature

| Valor | Uso | Ejemplo |
|-------|-----|---------|
| 0 | Determinista, siempre mismo output | Formateo, clasificación |
| 0.5 | Balance | Análisis con consistencia |
| 1.0 | Default, buena creatividad | Conversación, research |
| 1.5+ | Muy creativo/experimental | Brainstorming |

**Regla:** Para crons rutinarios, usar **temperature=0** o **0.5** (más predecible)

⚠️ **Gemini 3 Exception:** Google advierte que cambiar temperature <1.0 puede causar loops. Dejar en default (1.0) para Gemini 3.

### Max Output Tokens

- **Haiku crons:** 500-1000 tokens (suficiente para reportes breves)
- **Sonnet analysis:** 2000-4000 tokens
- **Opus deep reasoning:** 4000-8000 tokens

**Regla:** No configurar max tokens innecesariamente alto (desperdicio si no se usan)

---

## 📊 Practical Examples (By Use Case)

### Cron: Health Check (Haiku)
```
Revisa estado de fail2ban y alerta si actividad sospechosa.

Pasos:
1. sudo fail2ban-client status sshd
2. Cuenta IPs actualmente baneadas
3. Si ≥10 IPs → ALERTA ALTA
4. Si ≥5 IPs → ALERTA INFO

Output: "HEARTBEAT_OK" o "ALERTA [nivel]: [N] IPs baneadas"

Respetar quiet hours (00:00-07:00 Madrid): NO alertar excepto si ≥10 IPs.
```

**Por qué funciona:**
- Conciso (<100 palabras)
- Pasos claros
- Output definido
- Lógica simple (no condicionales complejos)

---

### Cron: Weekly Analysis (Sonnet)
```markdown
## Tarea
Análisis semanal de actividades Garmin

## Fuente de Datos
Lee archivos en: memory/garmin/daily/YYYY-MM-DD.md (últimos 7 días)

## Métricas a Analizar
1. Pasos promedio/día
2. Sueño promedio/noche (score + horas)
3. HR reposo promedio
4. Estrés promedio
5. Actividades registradas

## Comparación
Compara con semana anterior (si existe memory/garmin/weekly/YYYY-Wxx.md)

## Output
Guarda en: memory/garmin/weekly/YYYY-Wxx.md

Formato:
# Semana XX/YYYY

## Resumen
[3-5 líneas destacando lo más relevante]

## Métricas
- Pasos: X/día (↑/↓ Y% vs semana anterior)
- Sueño: X score, Y horas (↑/↓ vs anterior)
- HR reposo: X bpm
- Estrés: [bajo/medio/alto]

## Tendencias
[Patrones observados]

## Recomendaciones
[Accionables para esta semana]
```

**Por qué funciona:**
- Estructura clara (Markdown headers)
- Contexto suficiente (dónde leer datos)
- Output formato definido
- Apropiado para Sonnet (requiere análisis + síntesis)

---

### Subagent: Complex Decision (Opus)
```markdown
## Contexto
Necesitamos decidir si migrar la infraestructura de crons a un sistema más robusto.

Estado actual:
- 31 crons en jobs.json
- Algunos han fallado por memory/context issues
- Mantenimiento manual (editar JSON)

Opciones consideradas:
A. Mantener actual + mejorar prompts
B. Migrar a sistema de tasks (ej: Temporal, Celery)
C. Usar GitHub Actions + webhooks

Restricciones:
- Budget: no podemos añadir >€10/mes en infra
- Complejidad: Manu mantiene esto solo, debe ser simple
- No perder funcionalidad actual

## Objetivo
Recomendar la mejor opción considerando:
- Confiabilidad vs esfuerzo de migración
- Coste (setup + mensual)
- Mantenibilidad a largo plazo

## Pregunta
¿Qué opción recomiendas y por qué?

Analiza:
1. Pros/cons de cada opción
2. Esfuerzo de migración (horas estimadas)
3. Riesgos de cada enfoque
4. Recomendación final con justificación
```

**Por qué funciona:**
- Contexto completo (Opus necesita entender todo)
- Opciones claras a evaluar
- Restricciones explícitas
- Pregunta abierta que permite reasoning profundo

---

## ⚙️ Workflow: Iterating on Prompts

### 1. Start Simple
Escribe el prompt más simple que podría funcionar.

### 2. Test
Ejecuta y revisa output.

### 3. Identify Failures
- ¿Output incorrecto? → Añadir ejemplo o clarificar instrucción
- ¿Formato inconsistente? → Especificar formato más explícito
- ¿Contexto missing? → Añadir data necesaria

### 4. Iterate
No añadas complejidad innecesaria. Solo añade lo mínimo para arreglar el fallo.

### 5. Stabilize
Una vez funciona consistentemente 3-5 veces, está listo.

---

## 📐 Checklist: Before Deploying Prompt

- [ ] **Modelo asignado** (Haiku/Sonnet/Opus según tarea)
- [ ] **Longitud apropiada** (<200 palabras Haiku, <500 Sonnet)
- [ ] **Output format definido** (Markdown/JSON/texto)
- [ ] **Ejemplos incluidos** (si formato es específico)
- [ ] **Estructura clara** (XML/Markdown para prompts >200 palabras)
- [ ] **Silent mode** (HEARTBEAT_OK si no hay cambios)
- [ ] **Quiet hours respetado** (si es alerta)
- [ ] **No anti-patterns** (no ALL CAPS, no lógica compleja)

---

## 🔗 Referencias

- **Anthropic Best Practices:** `memory/best-practices/anthropic-2026-03-24.md`
- **Google Gemini Guide:** `memory/best-practices/google-2026-03-24.md`
- **OpenAI Prompting:** `memory/best-practices/openai-2026-03-24.md`
- **Model Decision Matrix:** `memory/model-specific-prompts.md`
- **Cron Prompt Audit:** `memory/prompt-audit-2026-03-25.md`

---

## 🎓 Quick Tips

1. **Less is more:** Empieza simple, añade complejidad solo si es necesario
2. **Examples > Explanations:** 1 ejemplo vale más que 3 párrafos de explicación
3. **Structure > Length:** Un prompt bien estructurado es más efectivo que uno largo
4. **Test early, test often:** No esperes a production para validar
5. **HEARTBEAT_OK is your friend:** Reduce ruido, respeta quiet hours

---

**Última actualización:** 2026-03-25  
**Mantenedor:** Lola  
**Revisar cada:** 3 meses o cuando haya cambios mayores en best practices
