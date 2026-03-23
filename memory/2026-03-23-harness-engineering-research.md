# Harness Engineering & AI-Supervised QA: Research Report

**Date:** 2026-03-23  
**Investigadora:** Lola (subagent)  
**Objetivo:** Investigación profunda sobre "Harness Engineering" y patrones de validación supervisada por IA  

---

## Resumen Ejecutivo

**Harness Engineering** es una disciplina emergente (2025-2026) que está transformando la ingeniería de software con IA. No se trata de mejorar el modelo, sino de construir el **ecosistema que rodea al modelo** para que pueda trabajar de forma fiable, supervisada y productiva a largo plazo.

La metáfora del arnés de escalada (harness) es precisa: como un arnés que te sostiene si caes mientras escalas, el harness engineering crea **redes de seguridad, validación y feedback loops** que permiten que los agentes IA trabajen de forma autónoma mientras están constantemente supervisados y validados.

**Key findings:**
- OpenAI construyó 1 millón de líneas de código con **zero código escrito a mano** usando harness engineering
- LangChain saltó del puesto 30 al Top 5 en benchmarks **sin cambiar el modelo, solo el harness**
- Stripe produce +1000 PRs/semana con agentes Minions usando un harness robusto
- Anthropic lidera con Constitutional AI (IA supervisando IA) y Claude Agent SDK
- El harness es más importante que el modelo: "the harness is the moat"

---

## 1. ¿Qué es Harness Engineering?

### Definición Formal

> **Harness Engineering** es el diseño e implementación de sistemas que:
> - **Restringen** lo que un agente IA puede hacer (arquitectura, límites, dependencias)
> - **Informan** al agente sobre qué debe hacer (context engineering, documentación)
> - **Verifican** que lo hizo correctamente (testing, linting, CI validation)
> - **Corrigen** al agente cuando se equivoca (feedback loops, self-repair)

Fuente: [OpenAI Harness Engineering](https://openai.com/index/harness-engineering/), [Martin Fowler](https://martinfowler.com/articles/exploring-gen-ai/harness-engineering.html)

### La Metáfora del Caballo

El término viene del arnés de caballos (reins, saddle, bit):
- **El caballo** = El modelo IA (poderoso, rápido, pero no sabe hacia dónde ir)
- **El arnés** = La infraestructura (restricciones, guardrails, feedback)
- **El jinete** = El ingeniero humano (dirección, no ejecución)

Sin arnés, un agente IA es como un caballo pura sangre en campo abierto: rápido, impresionante, y **completamente inútil** para hacer trabajo real.

### Diferencia con Conceptos Relacionados

| Concepto | Alcance | Enfoque |
|----------|---------|---------|
| **Prompt Engineering** | Una sola interacción | Crafting del prompt |
| **Context Engineering** | Ventana de contexto del modelo | Qué información ve el modelo |
| **Harness Engineering** | Sistema completo del agente | Entorno, restricciones, feedback, lifecycle |
| **Agent Engineering** | Arquitectura del agente | Diseño interno y routing |
| **Platform Engineering** | Infraestructura | Deployment, scaling, ops |

El harness opera **por encima de todos estos niveles**, orquestando el sistema completo.

---

## 2. Los Tres Pilares del Harness Engineering

Según la investigación de OpenAI, un harness efectivo se construye sobre tres pilares:

### 2.1 Context Engineering

**Definición:** Asegurar que el agente tenga la información correcta en el momento correcto.

**Componentes:**

**Contexto Estático:**
- Documentación local del repositorio (arquitectura, APIs, guías de estilo)
- Archivos `AGENTS.md` o `CLAUDE.md` con reglas específicas del proyecto
- Design docs enlazados y validados por linters

**Contexto Dinámico:**
- Datos de observabilidad (logs, métricas, traces) accesibles a agentes
- Mapeo de estructura de directorios al inicio del agente
- Estado de CI/CD pipeline y resultados de tests

**Regla crítica:** Desde la perspectiva del agente, **lo que no está en el contexto no existe**. El conocimiento en Google Docs, Slack o cabezas de personas es **invisible** al sistema.

### 2.2 Architectural Constraints (Restricciones Arquitectónicas)

**Concepto clave:** En lugar de decirle al agente "escribe buen código", **se fuerza mecánicamente** qué es "buen código".

**Ejemplo - OpenAI:**
```
Dependency layering:
Types → Config → Repo → Service → Runtime → UI

Cada capa solo puede importar de capas a su izquierda.
```

**Enforcement tools:**
- **Deterministic linters** — Reglas custom que flagean violaciones automáticamente
- **LLM-based auditors** — Agentes que revisan código de otros agentes
- **Structural tests** — Como ArchUnit, pero para código generado por IA
- **Pre-commit hooks** — Checks automatizados antes de cualquier commit

**Paradoja clave:** Restringir el espacio de soluciones hace que los agentes sean **más productivos, no menos**. Cuando un agente puede generar cualquier cosa, pierde tokens explorando callejones sin salida. Con boundaries claras, converge más rápido en soluciones correctas.

### 2.3 Entropy Management ("Garbage Collection")

**Problema:** Con el tiempo, las codebases generadas por IA acumulan entropía:
- Documentación diverge de la realidad
- Convenciones de naming se desvían
- Código muerto se acumula
- Dependencias circulares o innecesarias

**Solución:** Agentes de limpieza periódica:
- **Documentation consistency agents** — Verifican que docs coinciden con código actual
- **Constraint violation scanners** — Encuentran código que se escapó de checks previos
- **Pattern enforcement agents** — Identifican y arreglan desviaciones de patrones establecidos
- **Dependency auditors** — Rastrean y resuelven dependencias circulares/innecesarias

Estos agentes corren en **schedules** (diario, semanal, o por eventos específicos), manteniendo la codebase saludable.

---

## 3. Casos de Estudio: Harness Engineering en Producción

### 3.1 OpenAI: Zero Human Code

**Proyecto:** 1 millón+ líneas de código, 5 meses de desarrollo, 3 ingenieros  
**Regla:** **Zero líneas escritas a mano** (por diseño)

**El rol del ingeniero cambió:**

| Tradicional | Harness Engineering |
|-------------|---------------------|
| Escribir código | Nunca |
| Diseñar arquitectura | Parte del trabajo → **Trabajo principal** |
| Escribir documentación | Afterthought → **Infraestructura crítica** |
| Revisar PRs | Code review → **Review de output de agentes + efectividad del harness** |
| Debugging | Leer código → **Analizar patrones de comportamiento del agente** |
| Testing | Escribir tests → **Diseñar estrategias de test que los agentes ejecutan** |

**Throughput:** 3.5 PRs por ingeniero por día (y subiendo conforme el equipo crecía)

**Lección clave:** La bottleneck nunca fue la habilidad del agente para escribir código, sino **la falta de estructura, herramientas y mecanismos de feedback** alrededor.

### 3.2 Stripe: Minions at Scale

**Números:** +1000 PRs merged por semana

**Workflow:**
1. Developer publica task en Slack
2. Minion escribe el código
3. Minion pasa CI
4. Minion abre PR
5. Human revisa y mergea

**Sin interacción humana entre paso 1 y 5.**

**Harness key components:**
- **Devboxes pre-warmed:** Entornos de desarrollo aislados (sandbox, sin prod ni internet)
- **Toolshed:** +400 herramientas internas via MCP servers
- **CI integration:** Tight integration, el agente no puede abrir PR sin pasar tests

**Insight:** Los agentes necesitan el **mismo contexto y tooling** que ingenieros humanos, no una integración afterthought.

### 3.3 LangChain: DeepAgents

**Resultado:** Saltó del puesto 30 al Top 5 en Terminal Bench 2.0 (52.8% → 66.5%)  
**Cambio:** **Solo el harness, mismo modelo**

**Mejoras implementadas:**

| Cambio | Qué hicieron | Impacto |
|--------|--------------|---------|
| Self-verification loop | Checklist middleware pre-completion | Atrapó errores antes de submission |
| Context engineering | Mapeo de directorios al startup | Agente entendió codebase desde el inicio |
| Loop detection | Rastreo de edits repetidos en archivos | Previno "doom loops" |
| Reasoning sandwich | High reasoning para plan/verification, medium para implementation | Mejor calidad dentro de time budgets |

**Arquitectura:** Middleware composable en capas

```
Agent Request
 → LocalContextMiddleware (maps codebase)
 → LoopDetectionMiddleware (prevents repetition)
 → ReasoningSandwichMiddleware (optimizes compute)
 → PreCompletionChecklistMiddleware (enforces verification)
 → Agent Response
```

Cada capa añade una capability **sin modificar la lógica core del agente**. Harness testeable y evolucionable.

### 3.4 Anthropic: Claude Agent SDK

**Claude Agent SDK** = "general-purpose agent harness"

**Características:**
- Context management automático (compaction de historial)
- Tool use capabilities built-in
- Mantiene `claude-progress.txt` log para handoff entre sesiones

**Patrón para long-running agents:**
- **Initializer agent** (primera sesión): Setup de entorno, `init.sh`, feature list, git commit inicial
- **Coding agent** (sesiones subsecuentes): Progreso incremental, deja structured updates

**Problema resuelto:** Agentes que trabajan en proyectos que exceden su context window mantienen continuidad mediante:
- Feature list JSON (200+ features marcadas failing/passing)
- `claude-progress.txt` (log de qué se hizo)
- Git history
- Testing end-to-end con browser automation (Puppeteer MCP)

---

## 4. Constitutional AI: IA Supervisando IA (Anthropic)

### Concepto

**Constitutional AI** = En lugar de depender de feedback humano constante, se le da al modelo un conjunto de **principios core** (una "constitución") para seguir.

**Ejemplo de principios:**
- "Be helpful"
- "Don't be harmful"
- "Be honest"

Luego, **se usa otro IA para supervisar y corregir** al primer IA basándose en esos principios → proceso de **alineación auto-correctivo y escalable**.

### Proceso (dos fases)

**1. Supervised Learning Phase:**
- Sample del modelo inicial
- Genera **self-critiques y revisiones**
- Finetune el modelo original en respuestas revisadas

**2. Reinforcement Learning Phase (RLAIF - RL from AI Feedback):**
- Sample del modelo finetuneado
- Un modelo evalúa cuál de dos samples es mejor
- Entrena un preference model con este dataset de "AI preferences"
- Entrena con RL usando el preference model como reward signal

**Resultado:** IA harmless pero no evasiva. Responde a queries dañinas **explicando sus objeciones**.

**Ventajas:**
- Controla comportamiento IA con **far fewer human labels**
- Usa chain-of-thought reasoning para mejorar transparencia de decisiones
- Escalable: un supervisor débil (humano) puede supervisar un sistema más fuerte (superinteligencia)

### Mecánicas de Supervisión

**AI Debate:**
- Dos IA argumentan posiciones opuestas
- Humano juzga el debate (más fácil que juzgar respuesta directa)
- Permite identificar flaws incluso cuando el tema excede expertise humano

**Weak-to-Strong Generalization:**
- Desafío central: ¿puede un supervisor "débil" (humano) entrenar/controlar efectivamente una IA "más fuerte"?
- Research en técnicas para **amplificar sabiduría humana limitada** y guiar sistemas con inteligencia ilimitada

---

## 5. Model Context Protocol (MCP): Estándar para Harnesses

### ¿Qué es MCP?

**MCP** = Protocolo abierto para conectar sistemas IA con fuentes de datos.

**Problema que resuelve:**
- Cada nueva fuente de datos requería custom implementation
- Sistemas IA aislados, atrapados detrás de silos de información
- Integraciones fragmentadas difíciles de escalar

**Solución:**
- **Estándar universal** para conectar IA con datos
- Reemplaza integraciones fragmentadas con **un solo protocolo**
- Conexiones bidireccionales seguras entre data sources y AI tools

### Arquitectura MCP

**Dos roles:**
1. **MCP Servers** — Exponen datos a través de MCP
2. **MCP Clients** — Aplicaciones IA que conectan a estos servers

**Componentes oficiales (Anthropic):**
- [Specification & SDKs](https://github.com/modelcontextprotocol)
- Local MCP server support en Claude Desktop apps
- [Repositorio open-source](https://github.com/modelcontextprotocol/servers) de MCP servers

**MCP servers pre-built:**
- Google Drive, Slack, GitHub, Git, Postgres, Puppeteer
- API Lab MCP (testing lab), APIWeaver (dynamic MCP server creation)

### MCP en Testing & Validation

**Use cases:**
- **Security testing:** Validate auth, authorization, input sanitization, rate limiting
- **Performance testing:** Behavior bajo load, timeout handling, resource cleanup
- **Error handling:** Report errores via MCP protocol, clean up resources
- **Testing platforms integration:** Applitools, Playwright, Selenium automation via MCP

**Ventaja:** Permite que agentes IA accedan a **herramientas de validación estandarizadas** sin custom integrations.

---

## 6. Herramientas y Frameworks Prácticos

### 6.1 GitHub Actions / CI/CD para Validación IA

**Patrón emergente:** Pre-commit hooks y CI pipelines que usan IA para validación

**Ejemplos:**
- **Pre-commit hooks** con linters custom (generados por Codex)
- **Structural tests** que validan arquitectura antes de merge
- **CI validation** con LLM-based auditors que revisan PRs
- **GitHub Actions** que corren agentes de testing end-to-end

**Implementación típica:**
```yaml
# .github/workflows/ai-validation.yml
on: [pull_request]
jobs:
  ai-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: AI Code Review
        run: |
          # Run LLM-based architectural review
          python harness/ai_reviewer.py --pr ${{ github.event.number }}
      - name: Structural Tests
        run: |
          # Validate dependency layers
          python harness/structural_tests.py
```

### 6.2 AGENTS.md Convention

**Qué es:** README para AI agents, archivo Markdown en la raíz del repo.

**Contenido típico:**
- Build steps
- Testing commands
- Coding conventions
- Architectural constraints
- Common pitfalls

**Uso crítico:** Se actualiza **cada vez que el agente se equivoca**. No es doc estática, es **feedback loop activo**.

**Ejemplo (Ghostty terminal emulator):**
Cada línea en `AGENTS.md` corresponde a un fallo pasado del agente que ahora está prevenido.

**Best practice (Greg Brockman, OpenAI):**
> "Create and maintain an AGENTS.md for any project you work on; update the AGENTS.md whenever the agent does something wrong or struggles with a task."

### 6.3 Agent Orchestration Patterns

**Patrón común:** Attended vs Unattended Parallelization

**Attended (Peter Steinberger, OpenClaw):**
- 5-10 agentes simultáneos
- Switching activo entre sesiones
- Humano revisa frecuentemente
- Más control, catch early

**Unattended (Stripe Minions):**
- Developer posta task, se va
- Agente maneja todo hasta PR
- Humano solo re-entra en review stage
- Requiere harness **muy maduro**

**Tradeoff:** Control vs Scale

### 6.4 Modular Harness Design

**Paper académico:** "General Modular Harness for LLM Agents in Multi-Turn Gaming Environments" (ICML 2025)

**Componentes modulares:**
- **Perception module:** Convierte visual game screens a texto para el modelo
- **Memory module:** Almacena trajectories y reflections
- **Reasoning module:** Integra todo en decision-making del modelo

**Resultado:** El modelo con harness **consistentemente superó** al mismo modelo sin harness en todos los juegos testeados.

**Ventaja de modularidad:**
- Cada módulo puede habilitarse/deshabilitarse para ver su efecto
- Extender capabilities del agente sistemáticamente
- Test individual de componentes

---

## 7. Implementación: Framework de 3 Niveles

### Level 1: Basic Harness (Single Developer)

**Para:** Claude Code, Cursor, Codex individual projects

**Setup:**
- `CLAUDE.md` o `.cursorrules` con project conventions
- Pre-commit hooks para linting y formatting
- Test suite que el agente puede correr para self-verify
- Clear directory structure con consistent naming

**Tiempo:** 1-2 horas  
**Impacto:** Previene los errores más comunes del agente

### Level 2: Team Harness (Small Team 3-10 devs)

**Añade a Level 1:**
- `AGENTS.md` con team-wide conventions
- Architectural constraints enforced por CI
- Shared prompt templates para tareas comunes
- Documentation-as-code validated por linters
- Code review checklists específicos para PRs generados por agentes

**Tiempo:** 1-2 días  
**Impacto:** Comportamiento de agente consistente across team

### Level 3: Production Harness (Engineering Organization)

**Añade a Level 2:**
- Custom middleware layers (loop detection, reasoning optimization)
- Observability integration (agentes leen logs y metrics)
- Entropy management agents en scheduled runs
- Harness versioning y A/B testing
- Agent performance monitoring dashboards
- Escalation policies para cuando agentes se quedan stuck

**Tiempo:** 1-2 semanas  
**Impacto:** Agentes operan como contributors autónomos

---

## 8. Errores Comunes en Harness Engineering

### 1. Over-Engineering the Control Flow

**Error:** Control flow demasiado complejo que rompe con el próximo model update.

**Por qué es malo:** Models mejoran rápidamente. Capabilities que requerían pipelines complejos en 2024 ahora se manejan con un solo prompt.

**Solución:** Build harness "rippable" — deberías poder remover lógica "smart" cuando el modelo se vuelve smart enough.

### 2. Treating the Harness as Static

**Error:** Harness fijo que no evoluciona con el modelo.

**Por qué es malo:** Cuando un nuevo modelo mejora reasoning, tu middleware de optimización de reasoning puede volverse contraproducente.

**Solución:** Review y update componentes del harness con cada major model update.

### 3. Ignoring the Documentation Layer

**Error:** `AGENTS.md` vago o inexistente.

**Por qué es malo:** Si tu documentación es vaga, tu output del agente será vago.

**Solución:** Invierte en documentación precisa, machine-readable que sirva como ground truth del agente.

### 4. No Feedback Loop

**Error:** Harness sin feedback = jaula, no guía.

**Por qué es malo:** El agente necesita saber cuando tiene éxito y cuando falla.

**Solución:** Build in:
- Self-verification steps antes de task completion
- Test execution como parte del agent workflow
- Metrics en success rates por task type

### 5. Human-Only Documentation

**Error:** Decisiones arquitectónicas en cabezas de personas o Confluence pages inaccesibles al agente.

**Por qué es malo:** Gap en el harness. Lo que el agente necesita **debe estar en el repositorio**.

**Solución:** Todo knowledge crítico in-repo, accessible al agente.

---

## 9. Aplicación a OpenClaw: Recomendaciones Prácticas

### 9.1 Pre-Restart Validation Agent

**Problema:** Reiniciar OpenClaw puede romper configuración o workflows en curso.

**Solución con harness engineering:**

**Componentes:**
1. **Pre-restart checklist agent:**
   - Valida que no hay cron jobs en mid-execution
   - Verifica que configs críticos no tienen syntax errors
   - Comprueba que hay backup reciente disponible
   - Ejecuta smoke tests básicos de funcionalidad core

2. **Rollback mechanism:**
   - Git checkpoint automático pre-restart
   - Configuración previous guardada en `/memory/last-known-good/`
   - Script de rollback one-command

**Implementación:**
```bash
# Pre-restart validation
openclaw validate --pre-restart
  ├─ Check cron jobs (none running)
  ├─ Validate config syntax
  ├─ Verify memory files integrity
  ├─ Create checkpoint
  └─ Run smoke tests

# If validation passes:
openclaw restart --with-checkpoint

# If restart fails:
openclaw rollback --to-checkpoint
```

### 9.2 Config Change Validator

**Problema:** Cambios en `.openclaw/config.json` o `SOUL.md` pueden introducir bugs sutiles.

**Solución con harness engineering:**

**Validator agent con tres fases:**

**1. Structural validation:**
- JSON schema validation
- Required fields check
- Type checking

**2. Semantic validation:**
- Plugin dependencies resolved
- Gateway URLs reachable
- API keys válidos (no-op call)

**3. Behavioral simulation:**
- Dry-run del config en sandbox
- Simula session lifecycle
- Verifica que no hay breaking changes

**Trigger:** Pre-commit hook + GitHub Action

**Output:** Report en `memory/config-validations/YYYY-MM-DD-HH-MM.json`

### 9.3 Subagent Output Review

**Problema:** Subagents pueden completar con output no verificado.

**Solución con harness engineering:**

**Review harness pattern:**

```python
# Subagent completion handler
def on_subagent_complete(subagent_id, output):
    # 1. Structural review
    if not validate_output_format(output):
        flag_for_human_review(subagent_id, "format_invalid")
        return
    
    # 2. AI reviewer agent
    review_result = reviewer_agent.evaluate(
        output=output,
        criteria=["completeness", "accuracy", "safety"]
    )
    
    # 3. Threshold check
    if review_result.score < 0.8:
        flag_for_human_review(subagent_id, review_result.issues)
        return
    
    # 4. Auto-apply with log
    apply_output(output)
    log_to_memory(subagent_id, review_result)
```

**Criterios de review:**
- **Completeness:** ¿Cumplió con todos los puntos del task?
- **Accuracy:** ¿La información es correcta y verificable?
- **Safety:** ¿Hay cambios que podrían romper el sistema?
- **Style:** ¿Sigue convenciones establecidas?

### 9.4 Automated Testing de Cron Job Changes

**Problema:** Cron jobs editados pueden fallar silenciosamente hasta su próxima ejecución.

**Solución con harness engineering:**

**Test harness para cron jobs:**

**1. Syntax validation:**
```bash
# Validate cron schedule syntax
cron-validator "0 */6 * * *"  # OK
cron-validator "0 99 * * *"   # ERROR: invalid hour
```

**2. Dry-run execution:**
```bash
# Run cron job in test mode
openclaw cron run --job heartbeat --dry-run
  → Simulates execution
  → Reports what would happen
  → No side effects
```

**3. Dependency check:**
```bash
# Check all dependencies available
openclaw cron check --job heartbeat
  ├─ Tool: gog ✓
  ├─ Tool: wacli ✓
  ├─ API: weather ✓
  └─ Memory file: work-schedule.md ✓
```

**4. Historical pattern validation:**
```bash
# Compare against historical successful runs
openclaw cron validate --job heartbeat --against-history
  → Schedule: OK (matches previous)
  → Command: CHANGED (review needed)
  → Dependencies: OK
```

**Integration:** Pre-commit hook + notification en Telegram si change significativo.

---

## 10. Recursos Clave & Papers

### Papers Académicos

1. **"Constitutional AI: Harmlessness from AI Feedback"** (Anthropic, 2022)
   - Introducción a RLAIF y self-critique
   - https://www.anthropic.com/research/constitutional-ai-harmlessness-from-ai-feedback

2. **"General Modular Harness for LLM Agents in Multi-Turn Gaming Environments"** (ICML 2025)
   - Prueba empírica de efectividad de harnesses
   - Arquitectura modular (perception, memory, reasoning)

### Artículos Técnicos

1. **"Harness Engineering: The Complete Guide"** (NxCode, March 2026)
   - OpenAI 1M lines proof point
   - Three pillars framework
   - https://www.nxcode.io/resources/news/harness-engineering-complete-guide-ai-agent-codex-2026

2. **"Effective Harnesses for Long-Running Agents"** (Anthropic Engineering)
   - Initializer/coding agent pattern
   - Feature list management
   - https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents

3. **"The Emerging Harness Engineering Playbook"** (Ignorance.ai, March 2026)
   - Synthesis de prácticas convergentes
   - Attended vs unattended parallelization
   - https://www.ignorance.ai/p/the-emerging-harness-engineering

4. **"What is AI Harness Engineering?"** (Medium/Be Open, March 2026)
   - Context desde perspectiva de seguridad y control
   - https://medium.com/be-open/what-is-ai-harness-engineering

5. **"What is an Agent Harness?"** (Parallel.ai, Dec 2025)
   - Definición comprehensiva
   - FAQ y clarifications
   - https://parallel.ai/articles/what-is-an-agent-harness

### Frameworks & Tools

1. **Anthropic Claude Agent SDK**
   - General-purpose agent harness
   - https://platform.claude.com/docs/en/agent-sdk/overview

2. **LangChain DeepAgents**
   - Agent harness con batteries included
   - https://github.com/langchain-ai/deepagents

3. **Model Context Protocol (MCP)**
   - Standard para data source integration
   - https://modelcontextprotocol.io
   - https://github.com/modelcontextprotocol

4. **OpenAI Agents SDK**
   - MCP integration oficial
   - https://openai.github.io/openai-agents-python/mcp/

### Thought Leaders

1. **Greg Brockman** (OpenAI) — Thread original sobre harness engineering
2. **Mitchell Hashimoto** (Terraform, Ghostty creator) — Coined "harness engineering"
3. **Javier Garzas** (ES) — Menciona harness como red de seguridad (escalada)
4. **Martin Fowler** — "Tooling and practices to keep AI agents in check"
5. **Peter Steinberger** (OpenClaw creator) — 6,600 commits/month, 5-10 agents paralelos

### Comunidad Española

**Nota:** No encontré menciones directas de Javier Garzas usando específicamente el término "Harness Engineering" en búsquedas web. Es posible que:
- Lo haya mencionado en talks/podcasts no indexados
- Use el concepto sin usar ese término exacto
- La referencia venga de comunicación privada

**Concepto relacionado en ES:** "Ingeniería de restricciones" o "arquitectura de seguridad para IA" podrían ser traducciones o conceptos paralelos.

---

## 11. Conclusiones & Next Steps para OpenClaw

### Lecciones Clave

1. **El modelo es commodity; el harness es moat**
   - Mejoras dramáticas sin cambiar el modelo
   - Inversión en harness > inversión en model tuning

2. **Restricciones mejoran productividad**
   - Paradoja: menos libertad = convergencia más rápida
   - Clear boundaries = menos tokens desperdiciados

3. **Documentation is infrastructure**
   - `AGENTS.md` no es nice-to-have, es critical
   - Update on every agent mistake

4. **Feedback loops over control**
   - Self-verification > human micro-management
   - Testing built into workflow, no afterthought

5. **Incremental progress beats one-shot attempts**
   - Feature-by-feature approach
   - Clean state at end of each session

### Implementación Inmediata (Quick Wins)

**Esta semana:**
1. ✅ **Crear `AGENTS.md`** en workspace raíz con:
   - OpenClaw conventions
   - Common pitfalls
   - Tool usage patterns
   - Memory file structure

2. ✅ **Pre-commit hooks básicos:**
   - JSON syntax validation
   - YAML linting
   - Check for secrets/tokens

3. ✅ **Config validator script:**
   - Dry-run test de config changes
   - Schema validation

**Próximas 2 semanas:**
4. **Subagent review harness:**
   - AI reviewer para output de subagents
   - Threshold-based auto-apply vs human review

5. **Cron job testing framework:**
   - Dry-run capability
   - Dependency checker
   - Historical pattern validation

**Próximo mes:**
6. **Entropy management agent:**
   - Weekly scan de memory files inconsistencies
   - Documentation drift detection
   - Auto-cleanup PRs

7. **Observability integration:**
   - Session logs accessible a agentes
   - Performance metrics dashboard
   - Error pattern detection

### Investigación Continua

**Áreas emergentes a seguir:**
- Multi-agent architectures (specialist agents vs general-purpose)
- Harness versioning y A/B testing
- Brownfield harness retrofitting (applying to legacy codebases)
- Cross-provider harness design (model-agnostic)
- Formal verification methods para AI systems

---

## Referencias Completas

1. OpenAI. "Harness Engineering." https://openai.com/index/harness-engineering/ (2026)
2. Fowler, M. "Harness Engineering." https://martinfowler.com/articles/exploring-gen-ai/harness-engineering.html (2026)
3. Anthropic. "Constitutional AI: Harmlessness from AI Feedback." https://www.anthropic.com/research/constitutional-ai-harmlessness-from-ai-feedback (2022)
4. Anthropic. "Effective Harnesses for Long-Running Agents." https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents (2026)
5. Anthropic. "Introducing the Model Context Protocol." https://www.anthropic.com/news/model-context-protocol (2025)
6. NxCode. "Harness Engineering: The Complete Guide." https://www.nxcode.io/resources/news/harness-engineering-complete-guide-ai-agent-codex-2026 (March 2026)
7. Ignorance.ai. "The Emerging Harness Engineering Playbook." https://www.ignorance.ai/p/the-emerging-harness-engineering (March 2026)
8. Parallel.ai. "What is an Agent Harness?" https://parallel.ai/articles/what-is-an-agent-harness (Dec 2025)
9. Mohit Sewak. "What is AI Harness Engineering?" Medium/Be Open. https://medium.com/be-open/what-is-ai-harness-engineering (March 2026)
10. LangChain. "Agent Frameworks, Runtimes, and Harnesses." https://blog.langchain.com/agent-frameworks-runtimes-and-harnesses-oh-my/ (2025)
11. Model Context Protocol. Official Specification. https://modelcontextprotocol.io (2025)

---

**Documento preparado por:** Lola (subagent, OpenClaw)  
**Para:** Manu (Manuel León Mendiola)  
**Fecha:** 2026-03-23 19:18 GMT+1  
**Sesión:** agent:main:subagent:8d9f6ffa-7add-41b1-9d5d-bebebd05937d
