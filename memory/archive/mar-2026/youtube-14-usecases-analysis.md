# Análisis: 14 Casos de Uso de OpenClaw

**Video:** https://youtu.be/M-3w1wEv0M0  
**Título:** "Do THIS with OpenClaw so you don't fall behind... (14 Use Cases)"  
**Fecha de análisis:** 2026-03-24  
**Analista:** Lola (subagent)

---

## Casos de Uso Identificados

### Caso 1: Telegram Threads (Hilos por Tema)
**Qué propone:** Crear grupos de Telegram con tópicos separados para cada tema (General, CRM, Knowledge Base, Cron Updates, etc.). Cada thread tiene su propia sesión y context window, evitando mezclar topics en una única conversación larga.

**Estado nuestro:** 🔧 **Podemos mejorar**

**Acción:** Actualmente usamos Telegram pero sin estructura de threads temáticos. Propongo:
- Crear grupo "OpenClaw Topics" con threads:
  - General
  - Finanzas & Tracking
  - Salud & Garmin
  - Música & Bass in a Voice
  - Crons & Monitoring
  - Desarrollo & Skills
  
**Prioridad:** **Alta**  
**Beneficio:** Mejor memoria contextual, evitar contaminar context windows, facilitar multi-tasking.

---

### Caso 2: Voice Memos (Mensajes de Voz)
**Qué propone:** Usar los voice memos nativos de Telegram (botón del micrófono) para interactuar con OpenClaw sin escribir, especialmente útil mientras conduces o tienes solo el móvil disponible.

**Estado nuestro:** ✅ **Ya lo tenemos**

**Acción:** Funcionalidad nativa de Telegram ya disponible. Manu ya la usa ocasionalmente. No requiere configuración adicional. La transcripción es automática.

**Prioridad:** **Skip** (ya implementado)

---

### Caso 3: Publishing con Here.now
**Qué propone:** Usar la plataforma here.now para publicar artifacts, websites, PDFs, HTML generados por el agente. Es agent-first, no requiere cuenta para publicaciones de 24h, permite ediciones rápidas.

**Estado nuestro:** 🆕 **Nuevo para nosotros**

**Acción:** Evaluar integración. Casos de uso potenciales:
- Publicar informes de finanzas temporales
- Compartir dashboards de salud/Garmin
- Prototipos rápidos de web para Bass in a Voice

**Prioridad:** **Baja**  
**Justificación:** Interesante, pero no tenemos necesidad frecuente de publicar artifacts públicos. Podríamos explorar en el futuro si surge la necesidad.

**Evaluación completa:** Ver `memory/here-now-evaluation.md` con análisis detallado, comparación con alternativas (GitHub Pages, Google Sites, Self-hosted), y casos de uso específicos. **Verdict:** Evaluar más tarde / Implementación baja prioridad. Útil para dashboards visuales (health/Garmin, monitoring remoto) pero no esencial para casos de uso actuales.

---

### Caso 4: Right Model for Right Job (Multi-model Strategy)
**Qué propone:** No usar un solo modelo para todo. Usar modelos especializados según la tarea:
- Main chat: Opus 4.6 / Sonnet 4.6
- Fallback: GPT 5.4
- Coding: Opus 4.6
- Video processing: Gemini 3.1 Pro
- Deep research: Gemini Deep Research Pro
- Embeddings: Nomic
- Local models: Quen 3.5

**Estado nuestro:** 🔧 **Podemos mejorar**

**Acción:** Actualmente usamos claude-sonnet-4-5 por defecto y gemini-3-flash-preview como default_model. Podemos:
- Asignar modelos específicos a threads (threads de coding → Opus/Sonnet, threads de Q&A → Flash)
- Configurar fallbacks más robustos
- Evaluar Gemini Deep Research para análisis profundos (finanzas, salud)

**Prioridad:** **Media**  
**Beneficio:** Reducir costos, optimizar velocidad, mejorar calidad por tarea.

---

### Caso 5: Thread-specific Models
**Qué propone:** Asignar modelos específicos a threads específicos de Telegram. Por ejemplo, thread de Q&A simple usa modelo rápido/barato, thread de coding usa Frontier model.

**Estado nuestro:** 🆕 **Nuevo para nosotros**

**Acción:** Una vez implementado Caso 1 (Telegram Threads), configurar:
- Thread "General" → Sonnet 4.5
- Thread "Desarrollo & Skills" → Opus 4.6 o Sonnet 4.5
- Thread "Finanzas & Tracking" → Flash (rápido/barato)
- Thread "Música" → Flash
- Thread "Crons & Monitoring" → Flash

**Prioridad:** **Media** (dependiente de Caso 1)

---

### Caso 6: Fine-tuning Local Models (Email Labeling Example)
**Qué propone:** Sistema autónomo que:
1. Extrae use cases del stack de OpenClaw
2. Identifica cuáles se pueden fine-tunear a modelo local pequeño
3. Reemplaza Frontier model con modelo local fine-tuneado (ejemplo: email labeling con Quen 3.5 9B)

**Estado nuestro:** ❌ **No aplica**

**Acción:** Ninguna por ahora.

**Prioridad:** **Skip**  
**Justificación:** Muy avanzado, requiere infraestructura de training, no tenemos use cases de volumen suficiente para justificar el esfuerzo. Nuestro volumen de email/tareas es moderado, no necesitamos optimización extrema de costos aún.

---

### Caso 7: Delegate to Subagents (Agresivamente)
**Qué propone:** Delegar tareas a subagents de forma agresiva para evitar bloquear el main agent:
- Todo trabajo de coding → subagent (cursor agent CLI, claude code)
- Búsquedas, API calls, multi-step tasks
- Data processing
- File operations complejas
- Calendar/email operations
- Knowledge base ingestion
- **Regla:** Si toma >10 segundos, delegar

NO delegar: Conversación simple, clarifying questions, quick file reads.

**Estado nuestro:** 🔧 **Podemos mejorar**

**Acción:** Ya usamos subagents, pero podemos ser más agresivos:
- Actualizar `memory/subagent-policy.md` con regla de 10 segundos
- Entrenar al main agent a delegar más rápido
- Considerar usar cursor agent CLI para tareas de coding (actualmente usamos Claude Code principalmente)

**Prioridad:** **Alta**  
**Beneficio:** Main agent más responsive, mejor paralelización, menos bloqueos.

---

### Caso 8: Model-specific Prompts (Multiple Prompt Files)
**Qué propone:** Mantener múltiples versiones de archivos de prompt optimizados por modelo:
- `SOUL.md` (para Claude/Opus)
- `gpt/SOUL.md` (para GPT 5.4)

Cada modelo lee de su versión optimizada. Usar cron nocturno para mantener sincronización de contenido mientras respetando best practices por modelo.

**Estado nuestro:** 🆕 **Nuevo para nosotros**

**Acción:** Implementar estructura:
- Mantener prompts principales en root (optimizados para Claude/Sonnet)
- Crear directorio `gpt/` con versiones optimizadas para GPT
- Crear cron diario (3:30 AM) que:
  - Descarga best practices de Anthropic y OpenAI
  - Compara archivos root vs gpt/
  - Sincroniza contenido
  - Optimiza según best practices

**Prioridad:** **Media**  
**Justificación:** Interesante optimización, pero requiere tiempo de setup. Podríamos empezar con archivos clave (SOUL, AGENTS, MEMORY) y expandir.

---

### Caso 9: Cron Jobs Extensively
**Qué propone:** Usar crons para tareas programadas, especialmente por la noche para:
- Evitar interferir con uso diurno
- Distribuir carga a lo largo de ventana de rolling quota
- Ejemplo de crons: health checks, documentation drift, prompt quality checker, config consistency, daily backup, HubSpot/Asana syncs, PII/secrets reviewer

**Estado nuestro:** ✅ **Ya lo tenemos**

**Acción:** Ya tenemos crons bien establecidos:
- Backup 4AM
- Autoimprove 3AM (3 agentes)
- Informe matutino 10AM
- Health checks cada 30min
- Rate limits cada hora
- Config drift diario 2AM

Podemos añadir:
- Prompt quality checker (diario 3:15 AM)
- PII/secrets reviewer (diario 3:45 AM)

**Prioridad:** **Baja** (ya tenemos sistema robusto, mejoras menores)

---

### Caso 10: Security Hardening (Multi-layer Defense)
**Qué propone:** Sistema de seguridad multi-capa:

**Layer 1: Text Sanitation** (determinístico)
- Detectar patrones comunes de prompt injection ("forget previous instructions", caracteres no estándar, etc.)

**Layer 2: Frontier Scanner** (no-determinístico)
- Usar mejor modelo disponible (Opus 4.6 / GPT 5.4) para revisar texto entrante
- Calcular risk score
- Cuarentenar si peligroso

**Layer 3: Outbound Review**
- Revisar todo lo que sale buscando secrets, PII
- Redactar agresivamente

**Layer 4: Scoped Permissions**
- Solo dar permisos exactos necesarios (ejemplo: leer email pero no enviar, leer Box pero no borrar)

**Layer 5: Approval System**
- Acciones destructivas requieren aprobación humana

**Layer 6: Runtime Governance & Wallet Draining Protection**
- Rate limits en LLM calls
- Spending caps
- Loop detection

**Estado nuestro:** 🔧 **Podemos mejorar significativamente**

**Acción:** Actualmente tenemos:
- Arnés: API health checker, rate limit monitor, config drift detector
- Cron: health checks cada 30min

Nos falta:
- Text sanitation (prompt injection defense)
- Frontier scanner para contenido entrante
- Outbound PII/secrets scanner
- Scoped permissions granulares
- Runtime governance & spending caps

**Implementar:**
1. Crear `memory/security-hardening-plan.md` basado en este caso de uso
2. Implementar text sanitation script (Python) como skill
3. Configurar frontier scanner como harness
4. Añadir PII/secrets scanner outbound (ya propuesto en Caso 9)
5. Documentar permisos actuales y scope-down donde sea posible
6. Implementar runtime governance (spending caps, loop detection)

**Prioridad:** **Alta**  
**Justificación:** Seguridad es crítica, especialmente con acceso a email, Google Workspace, finanzas.

---

### Caso 11: Log Everything
**Qué propone:** Mantener logs comprehensivos de todo lo que ocurre en el sistema:
- Logs baratos (1GB para 2 meses)
- Debugging más fácil: "look at logs, find what happened, propose fix"
- Cron matutino: revisar logs de la noche anterior, identificar errores/warnings, proponer fixes

**Estado nuestro:** 🔧 **Podemos mejorar**

**Acción:** OpenClaw ya tiene logging nativo en `.openclaw/logs/`, pero podemos:
- Añadir cron matutino (7:30 AM) que revise logs de las últimas 24h
- Identificar patrones de errores
- Proponer fixes automáticamente
- Añadir a informe matutino (10 AM)

**Prioridad:** **Media**  
**Beneficio:** Debugging proactivo, menos sorpresas, maintenance preventivo.

---

### Caso 12: Check OpenClaw Updates Frequently
**Qué propone:** Cron nocturno (9 PM) que:
- Verifica updates de OpenClaw
- Descarga changelog
- Genera summary de cambios y cómo usarlos
- Auto-update y restart

**Estado nuestro:** 🆕 **Nuevo para nosotros**

**Acción:** Implementar cron diario (21:30):
```bash
openclaw gateway status
# check for updates
# if available: download changelog, summarize, update, restart
```

**Prioridad:** **Alta**  
**Justificación:** OpenClaw evoluciona rápido, updates frecuentes de seguridad y features. Estar al día es crítico.

---

### Caso 13: Use Subscription over API (Cost Optimization)
**Qué propone:** Usar subscripciones de Anthropic/OpenAI en lugar de API directa:
- Anthropic: Usar Agents SDK (permitido por TOS)
- OpenAI: Usar Codeex OAuth

Subscripciones son significativamente más baratas que API directa.

**Estado nuestro:** 🔧 **Podemos verificar**

**Acción:** Verificar configuración actual:
- ¿Estamos usando Agents SDK de Anthropic?
- ¿Estamos usando Codeex OAuth de OpenAI?
- Revisar `.openclaw/.env` y confirmar

Si no, migrar a subscriptions.

**Prioridad:** **Alta** (cost optimization)

---

### Caso 14: Document Everything + Logging + Backup + Testing (4 Pillars)
**Qué propone:** Los 4 pilares de vibe coding robusto:

**1. Logging** (ya cubierto en Caso 11)

**2. Documentation**
- Documentar todo en MD files
- PRD (Product Requirements Document)
- Use Cases & Workflows
- Workspace file organization
- Model-specific prompting guides (Opus, GPT)
- Security best practices
- Prompt injection defense guide
- `learnings.md` (para no repetir errores)
- Cron diario: detectar documentation gaps, comparar con código/commits, actualizar docs

**3. Backup**
- Git: Version control del código, commits frecuentes, push a GitHub
- Box/Cloud storage: Backups de databases, imágenes, PDFs, archivos no versionados en git

**4. Testing**
- Escribir tests para todo el código
- Tests automáticos que validen funcionalidad

**Estado nuestro:** 🔧 **Podemos mejorar**

**Acción actual:**
- ✅ Documentation: SOUL.md, AGENTS.md, MEMORY.md, IDENTITY.md, USER.md, TOOLS.md, pending-actions.md, daily logs, skill-specific docs
- ✅ Backup: Cron diario 4AM (git + filesystem)
- 🔧 Testing: No tenemos tests automáticos
- 🔧 Documentation gaps: No tenemos cron que revise gaps

**Implementar:**
1. PRD.md (Product Requirements Document) para documentar features actual
2. `memory/use-cases-workflows.md` (detalle de workflows)
3. `memory/workspace-organization.md` (estructura de archivos)
4. `memory/learnings.md` (errores comunes a evitar)
5. Cron diario (2:30 AM) para detectar documentation gaps
6. Evaluar testing: ¿Qué podemos testear? Skills críticos, harnesses, crons

**Prioridad:** **Alta** (foundation para reliability)

---

### BONUS: Build OpenClaw Externally (Cursor/Windsurf/Claude Code)
**Qué propone:** No construir OpenClaw desde Telegram. Usar herramienta externa especializada en vibe coding:
- Cursor (preferencia del autor)
- Windsurf
- Claude Code
- Sublime Text

Telegram no está optimizado para iterar sobre código. Usar sistema externo para build, Telegram para uso.

**Estado nuestro:** ✅ **Ya lo hacemos**

**Acción:** Ya usamos approach correcto. Para desarrollo de skills, scripts, configuración usamos:
- Editor local (VS Code / Vim)
- SSH a VPS
- Claude Code como coding agent
- Telegram para interacción diaria

**Prioridad:** **Skip** (ya implementado)

---

## Resumen Ejecutivo

### Estadísticas
- ✅ **Ya tenemos:** 3 casos (Voice Memos, Crons, Build Externally)
- 🔧 **Podemos mejorar:** 7 casos (Telegram Threads, Multi-model Strategy, Thread-specific Models, Delegate Aggressively, Security Hardening, Log Everything, Subscription vs API, Documentation/Backup/Testing)
- 🆕 **Nuevos para nosotros:** 3 casos (Here.now, Model-specific Prompts, Check Updates)
- ❌ **No aplica / Skip:** 1 caso (Fine-tuning Local Models)

### Top 3 Acciones Recomendadas

#### 1. 🔐 **Security Hardening (Caso 10)** — Prioridad ALTA
**Por qué:** Tenemos acceso a datos sensibles (email, Google Workspace, finanzas, Garmin health data). Implementar defense multi-capa es crítico.

**Pasos inmediatos:**
- Crear `memory/security-hardening-plan.md`
- Implementar text sanitation (prompt injection defense)
- Configurar frontier scanner para contenido entrante
- Añadir PII/secrets scanner outbound
- Implementar runtime governance (spending caps, loop detection)
- Documentar y scope-down permisos granulares

**Tiempo estimado:** 3-4 horas  
**Impacto:** Crítico

---

#### 2. 📱 **Telegram Threads por Tema (Caso 1)** — Prioridad ALTA
**Por qué:** Mejor gestión de context windows, memoria más efectiva, facilitar multi-tasking. Foundation para otros casos de uso (Thread-specific Models).

**Pasos inmediatos:**
- Crear grupo Telegram "OpenClaw Topics"
- Configurar threads: General, Finanzas, Salud, Música, Crons, Desarrollo
- Migrar conversaciones activas a threads apropiados
- Actualizar `AGENTS.md` con guidelines de uso por thread

**Tiempo estimado:** 1 hora  
**Impacto:** Alto (mejora UX y memoria)

---

#### 3. 🔄 **Auto-update OpenClaw + Log Review Matutino (Casos 11 + 12)** — Prioridad ALTA
**Por qué:** Maintenance proactivo. OpenClaw evoluciona rápido, estar al día en security/features es crítico. Log review matutino previene problemas recurrentes.

**Pasos inmediatos:**
- Cron 21:30: Check OpenClaw updates, summarize, auto-update
- Cron 7:30: Review logs últimas 24h, identificar errores, proponer fixes
- Integrar resultados en informe matutino (10 AM)

**Tiempo estimado:** 2 horas  
**Impacto:** Alto (reliability, security, proactive debugging)

---

### Mejoras de Prioridad Media (Para Siguiente Fase)

4. **Multi-model Strategy & Thread-specific Models (Casos 4 + 5)** — Optimización de costos/velocidad
5. **Delegate Aggressively (Caso 7)** — Mejor paralelización, main agent más responsive
6. **Model-specific Prompts (Caso 8)** — Optimización de calidad por modelo
7. **Documentation Pillars (Caso 14)** — PRD, learnings.md, cron de documentation gaps, testing framework

---

### Notas Finales

**Fortalezas actuales de nuestro setup:**
- Crons bien establecidos (backup, autoimprove, health checks, rate limits, config drift)
- Dashboard TUI (subagents-dashboard)
- Memoria estructurada (SOUL, MEMORY, daily logs, pending actions)
- Multi-canal (Telegram + Discord)
- Modo conducción con TTS
- Skills diversificados (youtube-smart-transcript, spotify, weather, github, gog, himalaya)
- Arneses existentes (API health, rate limit monitor, config drift, cron validator, subagent validator)

**Gaps principales:**
- Security hardening (no tenemos prompt injection defense, PII scanner, runtime governance)
- Telegram sin estructura de threads
- Logging sin review proactivo
- No tenemos auto-update de OpenClaw
- Documentation sin PRD ni learnings.md
- No verificamos si usamos subscriptions vs API

**Tiempo estimado implementación Top 3:** 6-7 horas  
**ROI:** Altísimo — Security, UX, Reliability

---

**Análisis completado:** 2026-03-24 20:40 GMT+1  
**Próximo paso:** Revisar con Manu, priorizar implementación, crear tareas en `memory/pending-actions.md`
