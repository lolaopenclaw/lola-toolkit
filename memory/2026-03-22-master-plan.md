# 🗺️ Master Plan — "Loopy Era" + Agent-First Architecture

**Fecha:** 2026-03-22
**Estado:** PROPUESTA — Pendiente aprobación de Manu
**Inspiración:** Karpathy No Priors Interview (Code Agents, AutoResearch, Loopy Era)

---

## 🎯 Visión

Transformar nuestro setup de "agente que hace tareas" a "sistema de agentes que se auto-mejoran y consumen datos para servir al humano". Tres pilares:

1. **Sistema estable y fiable** — Resolver problemas conocidos, reducir alucinaciones, mejorar contexto
2. **Auto-mejora continua** — Generalizar el patrón Karpathy a todo el stack
3. **Agent-first projects** — Surfing Coach y otros proyectos donde yo soy la interfaz, no una app

---

## 📋 Dependencias y Estado Actual

### ✅ Resuelto
- Gemini embeddings: DB indexada (714 chunks), quota se renueva mañana
- Crons: 3 jobs arreglados (best-effort-deliver)
- Autoimprove: racha de 6+ noches consecutivas

### ⏳ Pendiente
- Gemini quota: verificar mañana 09:30 (cron programado)
- Gmail auth (gog): necesita re-autenticación
- Memory >15MB: aceptar como nuevo baseline (32MB por Gemini 3072 dims)
- Gateway doctor warning: Telegram groupPolicy (cosmético, no crítico)

### 🔴 Problemas conocidos del LLM
- Alucinaciones (inventar datos, como lo del "1 de abril")
- Pérdida de contexto entre sesiones (compactación pierde detalles)
- Reiniciar gateway sin avisar (protocolo HITL no siempre respetado)
- Crons que fallan silenciosamente (delivery sin verificar)

---

## 🏗️ PLAN — 4 Fases

### FASE 1: Estabilidad y Fiabilidad (Semana 1: Mar 22-28)

**Objetivo:** Sistema robusto donde confiar antes de hacer cosas más complejas.

#### 1.1 Verificar Gemini embeddings completo
- **Cuándo:** Lunes 23 Mar, 09:30
- **Qué:** Confirmar quota renovada, probar búsqueda vectorial real
- **Métrica:** memory_search devuelve provider=gemini (no fallback)
- **Dependencia:** Ninguna

#### 1.2 Arreglar Gmail auth
- **Cuándo:** Lunes 23 Mar
- **Qué:** Re-autenticar gog CLI con OAuth
- **Métrica:** `gog gmail list --limit 1` funciona
- **Dependencia:** Necesita credenciales OAuth (posible intervención de Manu)

#### 1.3 Crear verification-checklist.md
- **Cuándo:** Lunes-martes
- **Qué:** Documentar TODOS los checks que debo hacer antes de afirmar algo
- **Contenido:**
  - Antes de decir "X se renueva el día Y" → verificar fuente
  - Antes de reiniciar servicios → avisar a Manu
  - Antes de afirmar datos → mostrar el comando que lo prueba
- **Métrica:** 0 alucinaciones en la semana siguiente

#### 1.4 Mejorar protocolo anti-alucinaciones
- **Cuándo:** Martes-miércoles
- **Qué:** Actualizar SOUL.md/AGENTS.md con reglas más estrictas:
  - "Si no estoy segura, digo 'no lo sé' en vez de inventar"
  - "Siempre cito la fuente del dato"
  - "Timestamps: solo de session_status, nunca estimados"
- **Métrica:** Reducción de correcciones de Manu

#### 1.5 Audit de crons
- **Cuándo:** Miércoles
- **Qué:** Revisar TODOS los cron jobs, verificar que cada uno:
  - Tiene canal de entrega configurado
  - Usa best-effort-deliver
  - Ha corrido exitosamente al menos 1 vez
- **Métrica:** 0 crons con error

---

### FASE 2: Auto-mejora Generalizada — "Karpathy Loop" (Semana 2: Mar 29 - Abr 4)

**Objetivo:** Llevar autoimprove de "1 agente, 10 iteraciones/noche" a "N agentes, 50+ iteraciones/noche, métricas reales".

#### 2.1 Métricas reales para scripts
- **Cuándo:** Lunes 29
- **Qué:** Actualizar eval.sh para cada programa:
  - `time` real de ejecución (no solo bytes)
  - Exit code (0 = ok, else = penalty)
  - Output validation (grep por errores conocidos)
- **Archivos:** `autoimprove/programs/*/eval.sh`
- **Métrica:** Cada eval.sh devuelve un número compuesto (tokens + tiempo + errores)

#### 2.2 Experiment log (JSONL)
- **Cuándo:** Lunes-martes 29-30
- **Qué:** Crear `autoimprove/experiment-log.jsonl`
  - Cada experimento registra: timestamp, target, change_description, score_before, score_after, kept/discarded
  - Karpathy dice: "el log importa más que el resultado"
- **Formato:**
  ```json
  {"ts": "2026-03-29T02:15:00Z", "target": "backup-memory.sh", "change": "parallelize tar+gzip", "before": 450, "after": 380, "kept": true}
  ```
- **Métrica:** Log crece cada noche, podemos analizar tendencias

#### 2.3 Autoimprove paralelo
- **Cuándo:** Miércoles 31
- **Qué:** En vez de 1 agente/noche, lanzar 3 en paralelo:
  - Agente 1: Scripts (eval = tiempo + errores)
  - Agente 2: Skills/prompts (eval = tokens + claridad)
  - Agente 3: Memory/config (eval = tamaño + cobertura)
- **Implementación:** 3 crons separados, cada uno con su propio target y eval
- **Coste estimado:** ~$0.15/noche (3x Haiku)
- **Métrica:** 3x más experimentos por noche

#### 2.4 Probar "loop gordo" en Lola Toolkit
- **Cuándo:** Jueves-viernes Abr 1-2
- **Qué:** Apuntar el loop a `lola-toolkit` repo completo
  - Target: todos los scripts del repo
  - Métrica: execution time + correctness + code quality
  - Dejar correr 48h (viernes noche → domingo mañana)
  - Objetivo: 100+ experimentos, 10+ mejoras
- **program.md específico:** Instrucciones claras, constraints estrictos
- **Métrica:** Número de mejoras encontradas, % speedup total

#### 2.5 Dashboard de autoimprove
- **Cuándo:** Sábado 3 Abr
- **Qué:** Script que genera resumen visual del experiment-log:
  - Total experimentos, % kept, tendencia de scores
  - Streak actual, best improvements
  - Se genera como parte del morning report
- **Formato:** Texto formateado o Canvas bajo demanda

---

### FASE 3: Agent-First Surfing Coach (Semana 3-4: Abr 5-18)

**Objetivo:** Primer proyecto donde yo soy la interfaz, no una app.

#### 3.1 Data pipelines (Semana 3)
- **Qué:** Conectores que me alimentan datos automáticamente:
  - **Oleaje:** API de Windguru o Surfline → cron diario 06:00 → `memory/surf/conditions-YYYY-MM-DD.md`
  - **Garmin:** Ya tenemos → métricas de actividad, sueño, HRV
  - **Calendario:** gog CLI → disponibilidad de Manu
  - **Sesiones:** Manu me manda nota/audio después de surfear → yo lo proceso y guardo
- **Métrica:** Datos llegando cada día sin intervención

#### 3.2 Knowledge base surf (Semana 3)
- **Qué:** Cargar en memory/ conocimiento de surf coaching:
  - Progresión de maniobras (popup → bottom turn → cutback → etc.)
  - Tabla de condiciones vs nivel (qué olas para qué nivel)
  - Errores comunes y correcciones
  - Ejercicios de fitness específicos para surf
- **Fuente:** Web scraping de recursos de coaching + libros
- **Formato:** memory/surf/ con archivos .md indexados

#### 3.3 Interfaz conversacional (Semana 4)
- **Qué:** Manu me pregunta, yo respondo con contexto completo:
  - "¿Cómo están las olas este finde?" → cruzo oleaje + calendario + fatiga Garmin
  - "¿Qué debería practicar?" → miro progresión + últimas sesiones + condiciones
  - "Hazme un plan de entrenamiento" → genero plan semanal personalizado
- **Output:** Texto, audio (driving mode), o Canvas con visualizaciones
- **Métrica:** Manu encuentra útiles las respuestas (feedback directo)

#### 3.4 Loop de auto-mejora del coach
- **Cuándo:** Semana 4
- **Qué:** Aplicar el Karpathy Loop al propio coaching:
  - program.md: "mejora las recomendaciones de surf"
  - Métrica: ¿Manu siguió la recomendación? ¿Fue útil? (feedback loop)
  - El agente itera sobre la base de conocimiento y las recomendaciones
- **Esto es lo diferencial:** El coach se mejora solo con el tiempo

---

### FASE 4: Consolidación y Escalado (Abr 19+)

#### 4.1 Aplicar patrón agent-first a otros proyectos
- Finanzas: yo proceso el sheet, tú preguntas
- Salud: Garmin + sueño + actividad → yo analizo, tú preguntas
- Música (Bass in a Voice): gestión, repertorio, calendario

#### 4.2 Multi-agent collaboration
- Agentes especializados que colaboran (como la "research community" de Karpathy)
- Agente surf, agente finanzas, agente salud → yo como orquestadora

#### 4.3 AIPM Framework
- Documentar lo aprendido como framework reproducible
- Publicar en lola-toolkit como guía para otros
- Manu como caso de estudio de transición PO → AIPM

---

## 📊 Métricas Globales

| Métrica | Actual | Objetivo Fase 1 | Objetivo Fase 2 | Objetivo Fase 4 |
|---------|--------|-----------------|-----------------|-----------------|
| Cron errors/semana | ~3 | 0 | 0 | 0 |
| Alucinaciones/semana | ~2-3 | <1 | 0 | 0 |
| Experimentos/noche | ~10 | 10 | 50+ | 100+ |
| Mejoras/semana | ~5 | 5 | 15+ | 20+ |
| Data pipelines activos | 1 (Garmin) | 1 | 1 | 4+ (surf, finanzas, salud, música) |
| Coste nightly | ~$0.05 | $0.05 | $0.15 | $0.30 |

---

## ⚡ Principios

1. **Estabilidad primero** — No construir sobre arena. Fase 1 es no-negociable.
2. **Medir todo** — Si no tiene métrica, no se puede mejorar.
3. **Loops > tareas** — Cada mejora debe ser un loop, no un one-shot.
4. **Agent-first** — Yo consumo datos, tú preguntas. No al revés.
5. **Pequeño → grande** — Empezar con scripts, escalar a proyectos.
6. **AIPM mindset** — Manu define qué es "mejor", yo ejecuto los 500 rounds.

---

## 🔗 Relación con Karpathy

| Concepto Karpathy | Nuestra implementación |
|---|---|
| program.md | autoimprove/nightly.md + programs/*.md |
| train.py (el archivo mutable) | Scripts, skills, memory files |
| prepare.py (eval inmutable) | autoimprove/programs/*/eval.sh |
| 700 experiments / 2 days | Objetivo: 100+ exp/semana (Fase 2) |
| tmux grid of agents | 3 crons paralelos (Fase 2.3) |
| Agent Command Center | autoimprove dashboard (Fase 2.5) |
| "Emulate a research community" | Multi-agent (Fase 4.2) |
| Vibe coding → Agentic engineering | PO → AIPM (Fase 4.3) |

---

*Este plan es un documento vivo. Se revisa semanalmente los domingos.*
*Próxima revisión: 2026-03-29*
