# Harness Engineering - Revisión Semanal 2026-03-24

**Fecha:** 24 de marzo de 2026  
**Revisora:** Lola (Subagent)  
**Contexto:** Evaluación de mejoras adicionales después de implementar 4 arneses P0-P1 y empezar el P2

---

## 🎯 Resumen Ejecutivo

OpenClaw está **por delante de la curva** en harness engineering. Tenemos implementados sistemas que muchos equipos aún no han adoptado. El research reciente de la industria (marzo 2026) valida nuestro enfoque y revela oportunidades incrementales.

**Estado actual:** ✅ **Sólido**  
**Gaps identificados:** 🟡 **Pocos, mayormente optimizaciones**  
**Posición competitiva:** 🟢 **Avanzada**

---

## 📊 Estado Actual de Nuestros Arneses

### ✅ Implementados y Operacionales (P0-P1)

#### 1. Pre-flight Checks de APIs (P0)
**Estado:** ✅ Completo y testeado  
**Cron:** Cada 30 min (críticas), cada 2h (high), diario (medium)  
**Implementación:** `scripts/api-health-checker.py`, `skills/api-health/SKILL.md`

**Capacidades:**
- 6 APIs monitorizadas (Anthropic, Google, Telegram, GitHub, Garmin, Brave)
- Failover automático Anthropic → Google
- Alertas vía Telegram (respetando quiet hours)
- Logging rotativo + historial 7 días
- Latency tracking y schema validation

**Tests ejecutados:** ✅ Telegram (213ms), Google (141ms), todas operacionales

**Gap menor detectado:** Anthropic API key no configurada en `.env` (reporta "down" pero sistema funciona igual). Solución: añadir key si monitorización requerida.

---

#### 2. Rate Limit Monitoring (P1)
**Estado:** ✅ Completo y operacional  
**Cron:** Cada hora  
**Implementación:** `scripts/rate-limit-monitor.py`, `scripts/rate-limit-status`, `skills/rate-limit/SKILL.md`

**Capacidades:**
- Dashboard ASCII con colores ANSI
- 6 APIs trackeadas (Brave Search, Google Gemini/Sheets/Drive, OpenAI Whisper, Anthropic 429s)
- Thresholds: WARNING 80%, CRITICAL 95%
- Supresión de spam (6h cooldown)
- Métricas históricas en JSONL (últimos 30 días)

**Tests ejecutados:** ✅ Increment, reset, threshold detection funcionando

**Gap menor detectado:** Auto-increment no integrado en tool wrappers. Solución recomendada: hook en `web_search`, `gog sheets` para incrementar automáticamente.

---

#### 3. Config Drift Detection (P1)
**Estado:** ✅ Completo y testeado  
**Cron:** Diario 2 AM  
**Implementación:** `scripts/config-drift-detector.py`, `scripts/config-drift`, `skills/config-drift/SKILL.md`

**Capacidades:**
- 5 archivos críticos monitorizados (`openclaw.json`, `.env`, `cron/jobs.json`, `auth-profiles.json`, systemd service)
- SHA256 hashing + baselines
- Clasificación INFO/WARN/CRITICAL
- Rollback automático vía backups
- Approval/reject workflow

**Tests ejecutados:** ✅ Benign change (INFO), suspicious change (WARN), rollback workflow

**Gap menor detectado:** No integrado con pre-restart hook aún. Solución recomendada: añadir a `pre-restart-validator.sh`.

---

#### 4. Cron Validator (P0)
**Estado:** ✅ Completo con test suite  
**Uso:** Pre-deploy validación  
**Implementación:** `scripts/cron-validator.py`, `scripts/cron-add-safe`, `skills/cron-validator/SKILL.md`

**Capacidades:**
- Validación de schedule syntax (cron, ISO, intervalos)
- Script existence & permissions
- Dependency resolution (Python, Node, binaries)
- Environment variable cross-check
- Dry-run simulation para payloads
- Reportes JSON detallados

**Tests ejecutados:** ✅ Test suite completo (7/7 tests pass)

**Gap menor detectado:** No pre-commit hook todavía. Solución recomendada: integrar con Git hooks para validar automáticamente en commits de `cron/jobs.json`.

---

### 🚧 En Implementación (P2)

#### 5. Validador de Output de Subagentes
**Estado:** 🟡 En curso (diseño completo, implementación pendiente)  
**Complejidad:** Alta (3-5 días esfuerzo)  
**Diseño:** `memory/advanced-harness-research.md` secciones 1-2

**Propuesta de arquitectura:**
1. **Fase 1 (Structural):** Secrets, dangerous commands, syntax errors → Determinístico (< 500ms)
2. **Fase 2 (Semantic Review):** AI reviewer agent (Sonnet 4.5) → 2-5s
3. **Fase 3 (Human Threshold):** Auto-apply ≥8.5/10, flag 6-8.4/10, reject <6/10

**Decisión recomendada:** Pausar hasta tener pain point claro. Actualmente subagents no están causando fallos frecuentes que requieran validación IA-sobre-IA.

---

## 🔍 Gaps Identificados

### Gap #1: Auto-increment Rate Limits (MEDIUM)
**Problema:** Tool wrappers no incrementan contadores automáticamente  
**Impacto:** Rate limit tracking es manual/propenso a olvidos  
**Esfuerzo:** Bajo (2-4h)  
**Solución propuesta:**
```python
# En wrappers de tools
def web_search_wrapper(*args, **kwargs):
    result = web_search(*args, **kwargs)
    subprocess.run(["rate-limit-monitor.py", "increment", "brave_search", "1"])
    return result
```

**Prioridad:** P2 (quick win pero no crítico)

---

### Gap #2: Config Drift en Pre-restart (LOW)
**Problema:** Config drift detector no está integrado en `pre-restart-validator.sh`  
**Impacto:** Cambios sospechosos podrían pasar antes de restart  
**Esfuerzo:** Muy bajo (30 min)  
**Solución propuesta:**
```bash
# En scripts/pre-restart-validator.sh
echo "🔍 Checking config drift..."
if ! config-drift check; then
    echo "⚠️  Config drift detected - review before proceeding"
    exit 1
fi
```

**Prioridad:** P3 (nice to have, cron diario ya cubre)

---

### Gap #3: Cron Pre-commit Hook (MEDIUM)
**Problema:** Cambios en `cron/jobs.json` no se validan automáticamente antes de commit  
**Impacto:** Errors podrían llegar a producción  
**Esfuerzo:** Bajo (1-2h)  
**Solución propuesta:**
```bash
# .git/hooks/pre-commit
if git diff --cached --name-only | grep -q 'cron/jobs.json'; then
    echo "🔍 Validating cron changes..."
    cron-validator.py --validate-all || exit 1
fi
```

**Prioridad:** P2 (quick win, previene errores)

---

### Gap #4: Schema Validation de API Responses (LOW)
**Problema:** API health check solo valida conectividad, no estructura de response  
**Impacto:** Breaking changes en API schema podrían no detectarse hasta fallo en workflow  
**Esfuerzo:** Medio (4-6h)  
**Solución propuesta:**
```python
# En scripts/api-health-checker.py
ANTHROPIC_SCHEMA = {
    "type": "object",
    "required": ["id", "type", "role", "content", "model"],
    ...
}
jsonschema.validate(instance=response.json(), schema=ANTHROPIC_SCHEMA)
```

**Prioridad:** P4 (defer hasta tener incident real)

---

## 🆕 Patrones de la Industria (Marzo 2026)

### Hallazgo #1: "AI + Determinístico Hybrid" Validado Científicamente
**Fuente:** Medium (1 semana atrás) — "THE CI/CD OF CODE ITSELF"  
**Dato clave:** Estudio 2026 encontró que **LLM-only review atrapa 45% de errores**. **Combinando LLM + análisis determinístico sube a 94%**.

**Validación de nuestro approach:** ✅ Nuestros arneses ya usan este patrón  
- Cron validator: Structural checks (determinístico) + dry-run (simulación)
- API health: HTTP checks (determinístico) + latency patterns
- Config drift: SHA256 hashing (determinístico) + pattern matching

**Lección:** NO necesitamos validadores IA-puros. Combinar rules + IA cuando necesario.

---

### Hallazgo #2: AGENTS.md como Nuevo Estándar
**Fuente:** Harness.io blog (6 días atrás)  
**Concepto:** Archivo `AGENTS.md` versionado en repos para instruir agentes sobre convenciones del proyecto

**Evaluación para OpenClaw:** ✅ **Ya lo tenemos**  
Nuestros archivos equivalentes:
- `AGENTS.md` → Instrucciones de sesión
- `SOUL.md` → Personalidad y principios
- `MEMORY.md` → Contexto persistente
- Skills en `skills/*/SKILL.md` → Knowledge modules

**Acción:** Ninguna necesaria. Estamos alineados con el estándar emergente.

---

### Hallazgo #3: Everything Claude Code (ECC) — Continuous Learning System
**Fuente:** Big Hat Group blog (6 días atrás)  
**Descripción:** Sistema de 84k+ stars con **learning layer dinámico**:
- PreToolUse/PostToolUse hooks observan cada interacción
- Extraen "Instincts" (micro-patterns con confidence score 0.3-0.9)
- Cuando 3+ instincts relacionados → agregados a Skill reutilizable
- Teams pueden importar/exportar instinct libraries

**Evaluación para OpenClaw:**
🟡 **Interesante pero no urgente**

**Pros:**
- Self-improving system (aprende de errores pasados)
- Transferible entre team members
- Compatible cross-harness (Claude Code, Codex, Cursor)

**Cons:**
- Requiere infraestructura adicional (hook system robusto)
- Risk de pattern overfitting
- Complejidad de confidence scoring

**Recomendación:** Monitorear pero no implementar aún. Nuestro sistema de skills estáticos + memory manual es suficiente para escala actual. Considerar si:
- Equipo crece a 3+ agentes activos simultáneos
- Subagents empiezan a cometer errores repetidos
- Pain point claro de "agente no aprende de fallos previos"

---

### Hallazgo #4: AgentShield — Security Scanning para Agentes
**Fuente:** Big Hat Group + ECC integration  
**Descripción:** 1,282 tests + 102 security rules específicas para agentic AI:
- Prompt injection
- Tool misuse
- Privilege escalation via agent delegation
- Data exfiltration via context windows

**Evaluación para OpenClaw:** 🟢 **Worth evaluating**

**Gap actual:** No tenemos security scanning específico para agentes (solo validación estructural en arneses).

**Propuesta:**
1. Evaluar AgentShield (open source o commercial?)
2. Probar en sandbox con subagents existentes
3. Si útil, integrar como pre-deploy check (similar a cron-validator)

**Prioridad:** P3 (importante pero no urgente — no tenemos incidents de seguridad actuales)

---

### Hallazgo #5: LangChain DeepAgents — Filesystem-based Working Memory
**Fuente:** Medium (1 semana atrás) — LangChain Deep Agents  
**Descripción:**
- Filesystem como external memory para agents
- Offload intermediate results → reduce context pollution
- Progressive skill disclosure (load skills on-demand)

**Evaluación para OpenClaw:** ✅ **Parcialmente implementado**

Nuestro equivalente:
- `memory/` directory → persistent storage
- Daily notes `memory/YYYY-MM-DD.md` → working memory
- Skills en `skills/` → progressive disclosure

**Gap menor:** No tenemos offloading automático de intermediate results en subagents.

**Propuesta (future):**
```bash
# En subagent workflows largos
# Auto-save intermediate state cada N steps
echo "Checkpoint: Completado paso 3/10" > memory/subagent-${id}-checkpoint.txt
```

**Prioridad:** P4 (nice to have, no pain point actual)

---

### Hallazgo #6: "Harness Engineering is the New Discipline"
**Fuente:** Múltiples (Karpathy analysis, Softmax Data, Analytics Vidhya)  
**Consenso emergente:**
- Prompt engineering → Tool engineering → **Harness engineering**
- Unit of work: entire feature (bug → fix → review → merge)
- Human role: environment designer (no micromanager)

**Evaluación para OpenClaw:** ✅ **Ya estamos aquí**

Evidencia:
- Subagents con autonomía completa (spawned tasks)
- Arneses que validan sin intervención humana
- Manu diseña environment (AGENTS.md, SOUL.md), no microgestiona cada tarea

**Lección:** Mantener este enfoque. NO regresar a prompts intervencionistas.

---

## 📈 Propuestas de Mejora Priorizadas

### Quick Wins (Esta Semana)

#### QW1: Cron Pre-commit Hook (1-2h)
**Problema:** Errores en `cron/jobs.json` no se atrapan antes de commit  
**Solución:** Git hook que ejecuta `cron-validator.py`  
**ROI:** Alto — previene broken crons en producción  
**Esfuerzo:** 1-2h  
**Owner:** Main agent o Manu

---

#### QW2: Config Drift en Pre-restart (30 min)
**Problema:** Config drift no integrado en restart validation  
**Solución:** Añadir `config-drift check` a `pre-restart-validator.sh`  
**ROI:** Medio — redundante con cron diario pero añade safety layer  
**Esfuerzo:** 30 min  
**Owner:** Main agent

---

#### QW3: Rate Limit Auto-increment Hooks (2-4h)
**Problema:** Tracking manual, propenso a olvidos  
**Solución:** Wrapper functions en tool calls  
**ROI:** Medio — mejora accuracy de rate limit monitoring  
**Esfuerzo:** 2-4h  
**Owner:** Main agent (modificar wrappers existentes)

---

### Inversiones (Próximas 2 Semanas)

#### INV1: API Schema Validation (4-6h)
**Problema:** Breaking changes en API schemas no detectados  
**Solución:** Añadir JSON schema validation a `api-health-checker.py`  
**ROI:** Medio-bajo — nice to have, no pain point actual  
**Esfuerzo:** 4-6h  
**Owner:** Subagent (future)  
**Prioridad:** P4 (defer hasta incident real)

---

#### INV2: AgentShield Security Scanning (1 día research + 1 día integration)
**Problema:** No security scanning específico para agentes  
**Solución:** Evaluar e integrar AgentShield  
**ROI:** Alto si previene un security incident  
**Esfuerzo:** 2 días (research + PoC)  
**Owner:** Manu + subagent  
**Prioridad:** P3 (importante pero no urgente)

---

#### INV3: Validador de Output de Subagentes — Fase 1 (2-3 días)
**Problema:** Subagents podrían generar output peligroso (secrets, destructive commands)  
**Solución:** Structural validation (secrets scanner, dangerous command detector, syntax check)  
**ROI:** Alto si subagents se vuelven más autónomos  
**Esfuerzo:** 2-3 días (solo Fase 1 determinística)  
**Owner:** Subagent  
**Prioridad:** P2 (esperar a pain point claro)

**Decisión:** NO empezar aún. Esperar a tener:
- 3+ incidents de subagent output problemático, O
- Plan de aumentar autonomía de subagents significativamente

---

### Defer (Sin Timeline)

#### DEF1: Continuous Learning System (ECC-style)
**Razón:** Complejidad alta, ROI incierto para escala actual  
**Revisar cuando:** Equipo crece a 3+ agentes activos o errores repetidos evidentes

---

#### DEF2: Log Anomaly Detection
**Razón:** Logs manejables manualmente  
**Revisar cuando:** Logs crecen 10x en volumen

---

#### DEF3: Sandbox Escape Detection
**Razón:** Esfuerzo muy alto, ROI bajo sin kernel-level hooks  
**Alternativa:** Docker si realmente necesario

---

## 🏆 Nuevos Patrones/Tools de la Industria a Adoptar

### Adoptar (Short-term)

#### 1. Git Pre-commit Hooks para Validation
**Patrón:** Validar configs antes de commit, no después  
**Herramienta:** Standard Git hooks  
**Aplicación OpenClaw:** `cron/jobs.json` validation, `openclaw.json` lint  
**Esfuerzo:** Bajo  
**ROI:** Alto

---

#### 2. AGENTS.md Versionado
**Patrón:** Instrucciones de agent en version control, reviewables  
**Herramienta:** Standard Markdown + Git  
**Aplicación OpenClaw:** ✅ Ya implementado (`AGENTS.md`, `SOUL.md`)  
**Acción:** Mantener actualizado, no permitir que quede stale

---

### Evaluar (Medium-term)

#### 3. AgentShield o Similar
**Patrón:** Security scanning específico para agentic AI  
**Herramienta:** AgentShield (verificar licencia/pricing)  
**Aplicación OpenClaw:** Pre-deploy checks, runtime monitoring  
**Esfuerzo:** Medio (1-2 días evaluation)  
**ROI:** Alto si previene incident

---

#### 4. Progressive Skill Disclosure
**Patrón:** Load skills on-demand, no upfront  
**Herramienta:** Custom (filesystem-based)  
**Aplicación OpenClaw:** Cargar solo skills relevantes por contexto  
**Esfuerzo:** Medio-alto (require arquitectura changes)  
**ROI:** Medio (reduce token usage)  
**Decisión:** Evaluar si token costs se vuelven problema

---

### Monitorear (Long-term)

#### 5. Continuous Learning Systems
**Patrón:** Agent aprende de interacciones pasadas, extrae patterns  
**Herramienta:** ECC instinct system o custom  
**Aplicación OpenClaw:** Auto-improve skills based on usage  
**Esfuerzo:** Alto (infra compleja)  
**ROI:** Incierto para escala actual  
**Decisión:** Monitorear evolución, no adoptar aún

---

## 🎯 Recomendación Final

### TL;DR
**OpenClaw está en excelente posición de harness engineering. Los 4 arneses implementados son sólidos y cubren los pain points críticos. Las mejoras propuestas son incrementales, no transformacionales.**

---

### Prioridades para Esta Semana

**Hacer:**
1. ✅ **Cron pre-commit hook** (1-2h) — Quick win, previene broken crons
2. ✅ **Config drift en pre-restart** (30 min) — Safety layer adicional
3. ⚠️ **Rate limit auto-increment** (2-4h) — Opcional, mejora tracking

**Total esfuerzo:** 4-6.5h (menos de 1 día)

---

### Prioridades para Próximas 2 Semanas

**Evaluar:**
1. **AgentShield** (1 día research) — Security gap importante
2. **API schema validation** (4-6h) — Nice to have, no urgente

**NO hacer aún:**
- Validador de output de subagentes (esperar pain point)
- Continuous learning system (complejidad > ROI actual)
- Log anomaly detection (no necesario aún)

---

### Postura Estratégica

**"Perfect is the enemy of good."**

Nuestros arneses actuales son **suficientes** para las operaciones actuales. Las mejoras propuestas son **incrementales** y deben implementarse **solo cuando pain point es claro**.

**Riesgo de over-engineering:** Añadir más arneses sin pain points → complejidad sin ROI.

**Approach recomendado:**
1. Mantener los 4 arneses actuales bien mantenidos
2. Implementar quick wins (pre-commit hooks, config drift integration)
3. Monitorear incidents reales para priorizar próximas inversiones
4. Evaluar AgentShield como único gap de seguridad significativo

**Principio guía:** **"Fail safe, not safe from failure"**  
Los sistemas van a fallar. Diseñar para recovery, no para prevención absoluta.

---

## 📚 Referencias

### Research Interno
- `memory/advanced-harness-research.md` — Investigación completa (24 Mar 2026)
- `memory/api-health-implementation.md` — Pre-flight checks
- `memory/rate-limit-implementation.md` — Rate monitoring
- `memory/config-drift-implementation.md` — Config drift
- `memory/cron-validator-implementation.md` — Cron testing

### Industria (Marzo 2026)
- Geeky Gadgets: "Andrej Karpathy Explains Why AI Agent Skills Fail" (2 días)
- Medium: "LangChain Deep Agents: Harness and Context Engineering" (1 semana)
- Big Hat Group: "Everything Claude Code: The Agent Harness Your Team Is Missing" (6 días)
- Harness.io: "The Agent-Native Repo: Why AGENTS.MD is the New Standard" (6 días)
- Medium: "THE CI/CD OF CODE ITSELF" (1 semana) — **Dato clave: LLM-only 45% vs hybrid 94%**
- ArXiv: "Skilled AI Agents for Embedded and IoT Systems Development" (4 días)

### Herramientas Externas
- **Everything Claude Code (ECC):** 84k stars, continuous learning system
- **AgentShield:** 1,282 tests, 102 security rules para agentic AI
- **LangChain DeepAgents:** Filesystem-based working memory

---

## 🔄 Próxima Revisión

**Frecuencia recomendada:** Semanal (lunes AM)

**Triggers para revisión ad-hoc:**
- Incident de seguridad relacionado con agents
- 3+ fallos de subagent en 1 semana
- Cambio significativo en arquitectura de OpenClaw
- Nueva herramienta de harness engineering con >10k stars

**Métricas a trackear:**
- Incidentes atrapados por arneses vs missed
- False positives por arnés
- Tiempo ahorrado vs debugging post-facto
- Token costs (para evaluar progressive skill disclosure)

---

**Fin del informe**

**Tiempo de investigación:** ~40 minutos (incluye research, web search, evaluación)  
**Fecha de generación:** 2026-03-24 15:21 GMT+1  
**Próxima acción:** Presentar a Manu para aprobación de quick wins
