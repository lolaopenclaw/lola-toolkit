# Decisions Log

**Propósito:** Registro de decisiones técnicas importantes. Este archivo documenta por qué elegimos una opción sobre otra, para que futuras decisiones similares puedan consultarlo.

**Formato:** | Fecha | Decisión | Razón | Alternativas Descartadas |

---

## Índice por Categoría

- [Arquitectura](#arquitectura)
- [Tecnología/Stack](#tecnología-stack)
- [Arneses](#arneses)
- [Seguridad](#seguridad)
- [Crons](#crons)
- [Modelos](#modelos)
- [Memory/Logging](#memory-logging)
- [Infraestructura](#infraestructura)

---

## Decisiones

### Arquitectura

| Fecha | Decisión | Razón | Alternativas Descartadas |
|-------|----------|-------|--------------------------|
| 2026-03-24 | Implementar arneses como scripts Python standalone + skills wrapper | Separación de concerns: script contiene lógica, skill contiene docs/invocación. Permite: (1) ejecutar script directamente para testing, (2) skill wrapper para integración con OpenClaw, (3) reusabilidad del script en otros contextos. | **Alt 1:** Todo en skill (mezclado) → más difícil de testear. **Alt 2:** Solo script sin skill → no integrado con OpenClaw. |
| 2026-03-24 | Usar filesystem-based workspace en lugar de database | OpenClaw workspace es `.openclaw/workspace/` con archivos MD/JSON/scripts. **Ventajas:** (1) Git-friendly, (2) humano-legible, (3) fácil backup, (4) no requiere DB engine, (5) inspección directa con `cat`/`grep`. | **Alt 1:** SQLite → overhead, no humano-legible. **Alt 2:** MongoDB → requiere daemon, overkill. **Alt 3:** Redis → volátil, requiere persistence config. |
| 2026-03-24 | Subagents depth 1/1 (no nested subagents) | Simplicidad. Nested subagents añaden complejidad de tracking, errores cascada, debugging difícil. Depth 1 es suficiente para 99% de casos. | **Alt 1:** Permitir depth arbitrario → complejidad exponencial. **Alt 2:** No subagents → main agent bloqueado durante tasks largas. |

---

### Tecnología/Stack

| Fecha | Decisión | Razón | Alternativas Descartadas |
|-------|----------|-------|--------------------------|
| 2026-03-24 | Usar blessed para TUIs en Node.js | Framework maduro (2015), sin deps nativas, buena documentación, usado por proyectos populares (e.g., yeoman, slap), rica widget library (box, list, table, form, scrollbar), layout flexible. | **Alt 1:** Textual (Python) → requiere cambiar stack, menos integrado con OpenClaw (Node.js). **Alt 2:** Ink (React) → overhead innecesario, abstracción pesada para TUIs. **Alt 3:** Escribir raw ANSI → reinventar la rueda. |
| 2026-03-24 | Python para arneses/monitoring scripts | Ventajas: (1) excelente stdlib (json, datetime, subprocess, logging), (2) rich ecosystem (requests, psutil, jinja2), (3) scripting rápido, (4) legible. Scripts como api-health-checker.py (25KB), cron-validator.py (19KB) son mantenibles. | **Alt 1:** Bash → límite en 100-200 LOC antes de volverse unmaintainable. **Alt 2:** Node.js → async overhead para scripts síncronos. **Alt 3:** Go → compilation step, overkill para scripts. |
| 2026-03-24 | Edge-TTS (Python) como TTS provider para modo conducción | **Ventajas:** (1) Gratis, (2) sin API key, (3) voces de alta calidad (Microsoft Azure backend), (4) rápido (<500ms latency), (5) funciona offline después de cache, (6) 1.25x speed configurable. | **Alt 1:** Google Cloud TTS → requiere API key + billing. **Alt 2:** AWS Polly → ídem. **Alt 3:** Festival/espeak → calidad baja. **Alt 4:** OpenAI TTS → caro para uso frecuente. |
| 2026-03-24 | Telegram como primary interface | **Ventajas:** (1) mobile-first (Manu usa más móvil que laptop), (2) voice memos nativos, (3) file sharing easy, (4) inline buttons, (5) always-on (push notifications), (6) historia persistente. | **Alt 1:** Discord → más features pero overkill, Manu no lo usa diario. **Alt 2:** Slack → corporativo, Manu no lo usa. **Alt 3:** CLI only → no mobile. |

---

### Arneses

| Fecha | Decisión | Razón | Alternativas Descartadas |
|-------|----------|-------|--------------------------|
| 2026-03-24 | API health checks cada 30min (detection), 2h (deep check), daily (report) | **Detection 30min:** Catch failures rápido (MTTR <30min). **Deep check 2h:** Validación completa sin spam. **Daily report:** Resumen para Manu. Balance entre responsiveness y noise. | **Alt 1:** Solo daily → MTTR demasiado alto. **Alt 2:** Cada 5min → spam, rate limit risk. **Alt 3:** Solo on-demand → reactive, no proactive. |
| 2026-03-24 | Failover automático Anthropic→Google en health checks | Si Anthropic falla health check, auto-switch a Google (gemini). Main agent puede continuar trabajando. **Importante:** Notificar a Manu del failover. | **Alt 1:** Manual failover → requiere intervención humana, downtime. **Alt 2:** No failover → single point of failure. **Alt 3:** Round-robin → peor latencia/calidad que stick-to-primary. |
| 2026-03-24 | Rate limit monitor trackea rolling window 24h | Permite predecir cuándo nos acercaremos a límites. Ejemplo: si llevamos 800K tokens en 20h, proyectamos 960K en 24h → advertir antes de hit limit. | **Alt 1:** Track solo current → no predice problemas futuros. **Alt 2:** Track 1h window → demasiado corto, muchos providers tienen límites diarios. |
| 2026-03-24 | Config drift detector usa golden config snapshot | `config-golden-snapshot.json` captura config conocida-buena. Detector compara contra snapshot y reporta diffs. | **Alt 1:** Git diff → requiere commits frecuentes. **Alt 2:** Hardcoded expectations → frágil, requiere update manual. **Alt 3:** No drift detection → config diverge silenciosamente. |

---

### Seguridad

| Fecha | Decisión | Razón | Alternativas Descartadas |
|-------|----------|-------|--------------------------|
| 2026-03-24 | Multi-layer security (6 capas) en lugar de single layer | Caso de uso 10 (YouTube video). Layers: (1) Text sanitation, (2) Frontier scanner, (3) Outbound PII scanner, (4) Scoped permissions, (5) Approval system, (6) Runtime governance. Defense in depth: si una capa falla, otras compensan. | **Alt 1:** Solo blacklist palabras → fácil bypass. **Alt 2:** Solo AI scanner → puede ser engañado. **Alt 3:** Solo approval manual → friction alto, no escala. |
| 2026-03-24 | Secrets scanner pre-commit usando git-secrets + trufflehog | **Git-secrets:** Rápido, patterns conocidos (AWS keys, etc.). **Trufflehog:** Entropy detection, catch secrets custom. Combinación cubre más casos. | **Alt 1:** Solo manual review → humanos cometen errores. **Alt 2:** Solo git-secrets → miss secrets custom. **Alt 3:** Post-commit scanning → too late, ya está en history. |
| 2026-03-24 | Whitelist + blacklist para comandos en subagent validator | **Whitelist:** Comandos safe (ls, cat, grep, jq, git status). **Blacklist:** Comandos peligrosos (rm -rf, dd, mkfs, format, >\/dev). Approach dual: permite explícitamente lo safe, bloquea explícitamente lo peligroso. | **Alt 1:** Solo whitelist → muy restrictivo, bloquea use cases legítimos. **Alt 2:** Solo blacklist → fácil bypass (e.g., echo "rm -rf" \| sh). |

---

### Crons

| Fecha | Decisión | Razón | Alternativas Descartadas |
|-------|----------|-------|--------------------------|
| 2026-03-24 | Espaciado mínimo 30min entre crons pesados | Evita resource contention (LLM tokens, CPU, memoria). Configuración actual: Backup 4:00, Reindex 4:30, Autoimprove 2:00. | **Alt 1:** Ejecutar todos en paralelo → compete por tokens, risk de rate limits. **Alt 2:** Ejecutar secuencialmente → demora total muy larga (2h+). **Alt 3:** No espaciar → resource starvation. |
| 2026-03-24 | Cron logs con formato structured (timestamp + cron_name + level + message) | Facilita parsing con jq/awk. Ejemplo: `[2026-03-24T04:00:00Z] [backup] [INFO] Starting backup...`. **Beneficio:** Análisis automático, alerting, metrics. | **Alt 1:** Free-form logs → difícil parsear. **Alt 2:** Solo JSON → no humano-legible. **Alt 3:** No structured logs → debugging manual tedioso. |
| 2026-03-24 | Informe matutino a las 10 AM (no 8 AM) | Timing basado en: (1) Manu despierta ~9 AM, (2) crons nocturnos completan antes de 7 AM, (3) log review cron a 7:30 AM, (4) informe a 10 AM da tiempo a procesar logs. | **Alt 1:** 8 AM → demasiado temprano, Manu puede estar durmiendo. **Alt 2:** 12 PM → muy tarde, pierde mañana. |

---

### Modelos

| Fecha | Decisión | Razón | Alternativas Descartadas |
|-------|----------|-------|--------------------------|
| 2026-03-24 | Claude Sonnet 4.5 como modelo primary, Gemini 3 Flash como default_model | **Sonnet:** Mejor calidad, largo context (200K), bueno para tareas complejas. **Flash:** Rápido, barato, suficiente para tareas simples (Q&A, verificación). | **Alt 1:** Solo Sonnet → caro para todo. **Alt 2:** Solo Flash → calidad insuficiente para tareas complejas. **Alt 3:** GPT-4 → más caro que Sonnet, menos context. |
| 2026-03-24 | Gemini 3 Flash suficiente para subagents de verificación/testing | Descubierto empíricamente: 4 subagents (gemini-3-flash) completaron verificación de scripts complejos (16-25KB Python) sin problemas. **Saving:** ~5x cheaper que Sonnet. | **Alt 1:** Siempre usar Sonnet → desperdicia tokens/money en tareas simples. **Alt 2:** Downgrade a modelos más pequeños → risk de calidad. |
| 2026-03-24 | No implementar fine-tuning local por ahora (Caso de uso 6) | **Razones:** (1) No tenemos volumen suficiente para justificar esfuerzo, (2) requiere infraestructura de training, (3) Frontier models evolucionan rápido (fine-tuned model puede quedar obsoleto), (4) casos de uso actuales no requieren optimización extrema. | **Alt 1:** Fine-tune email labeling → overkill, volumen bajo. **Alt 2:** Fine-tune code generation → Frontier models ya son excelentes. |

---

### Memory/Logging

| Fecha | Decisión | Razón | Alternativas Descartadas |
|-------|----------|-------|--------------------------|
| 2026-03-24 | Tres tipos de logs: daily (cronológico), learnings (temático filtrado), decisions (técnico) | **Daily:** Todo lo que ocurre, orden cronológico. **Learnings:** Solo lo importante, categorizado, para no repetir errores. **Decisions:** Decisiones técnicas con context, para consultar en futuro. Cada uno tiene propósito diferente. | **Alt 1:** Solo daily log → difícil encontrar patterns, aprende lento. **Alt 2:** Solo learnings/decisions → pierde detalles cronológicos. **Alt 3:** Mix todo en un archivo → confuso, difícil navegar. |
| 2026-03-24 | Format de learnings: tabla con fecha, categoría, learning, contexto | Compacto, scannable, fácil de buscar por categoría o keyword. Markdown table renderiza bien en terminal y GitHub. | **Alt 1:** Prosa libre → difícil escanear. **Alt 2:** JSON → no humano-legible. **Alt 3:** YAML → indentación frágil. |
| 2026-03-24 | Format de decisions: tabla con fecha, decisión, razón, alternativas descartadas | Documenta no solo qué decidimos, sino **por qué** y **qué más consideramos**. Critical para entender trade-offs en futuro. | **Alt 1:** Solo decisión sin razón → falta context. **Alt 2:** Solo decisión+razón sin alternativas → no se entiende trade-offs. |

---

### Infraestructura

| Fecha | Decisión | Razón | Alternativas Descartadas |
|-------|----------|-------|--------------------------|
| 2026-03-24 | VPS + laptop en lugar de solo VPS o solo laptop | **VPS:** Always-on, crons nocturnos, high uptime. **Laptop:** Dev work, SSH durante horario laboral. Híbrido permite: (1) crons run incluso si laptop off, (2) dev work con editor local, (3) failover si laptop no disponible. | **Alt 1:** Solo VPS → dev work incómodo sin editor local. **Alt 2:** Solo laptop → no always-on, crons nocturnos no corren. |
| 2026-03-24 | Backup diario 4 AM en lugar de real-time backup | **Ventajas:** (1) menos overhead, (2) point-in-time recovery claro, (3) scheduling predecible. **Suficiente:** Max data loss = 24h, aceptable dado que trabajo crítico se commitea a git. | **Alt 1:** Real-time backup (e.g., cada commit) → overhead alto. **Alt 2:** Weekly backup → data loss risk demasiado alto. **Alt 3:** No backup → inaceptable. |
| 2026-03-24 | Quiet hours 00:00-07:00 Madrid (sin mensajes excepto emergencias) | Respetar sueño de Manu. **Excepción:** Emergencias críticas (gateway down, security breach). Crons nocturnos logean silenciosamente, informe matutino a 10 AM. | **Alt 1:** Sin quiet hours → spam nocturno. **Alt 2:** Quiet 00:00-09:00 → pierde ventana matutina útil. |

---

## Cómo Usar Este Archivo

### Al Tomar una Decisión Técnica
1. **Antes de decidir:** Buscar en este archivo si ya tomamos decisión similar
2. **Al decidir:** Documentar decisión con razón y alternativas
3. **Formato:**
   ```
   | YYYY-MM-DD | Decisión clara y concisa | Por qué elegimos esto | Alt 1: ... Alt 2: ... |
   ```

### Durante Code Review
- Verificar que el código sigue decisiones documentadas
- Si code review revela que decisión fue incorrecta → actualizar este archivo con nueva decisión + learning

### Al Onboarding Nuevo Colaborador
- Leer este archivo para entender trade-offs históricos
- Evita "¿por qué no usamos X?" cuando X ya fue considerado y descartado

---

## Template para Nueva Decisión

```markdown
| YYYY-MM-DD | [Decisión: qué elegimos] | [Razón: por qué elegimos esto, beneficios] | **Alt 1:** [Alternativa descartada] → [por qué no]. **Alt 2:** [Otra alternativa] → [por qué no]. |
```

---

**Última actualización:** 2026-03-24  
**Próxima revisión:** Diaria (cada sesión matutina)
