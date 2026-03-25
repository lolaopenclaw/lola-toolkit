# Learnings Log

**Propósito:** Registro de cosas que aprendimos (errores que cometimos, soluciones que funcionaron, decisiones importantes). Este archivo nos ayuda a no repetir errores y a recordar por qué hicimos las cosas de cierta manera.

**Formato:** | Fecha | Categoría | Learning | Contexto |

---

## Índice por Categoría

- [Subagents](#subagents)
- [TUI/Dashboard](#tui-dashboard)
- [Arneses](#arneses)
- [Crons](#crons)
- [Gateway](#gateway)
- [Security](#security)
- [Logging](#logging)
- [Memory](#memory)

---

## Learnings

### Subagents

| Fecha | Learning | Contexto |
|-------|----------|----------|
| 2026-03-24 | `/stop` en Telegram mata TODOS los subagents en ejecución, no solo el que responde | Descubierto cuando Manu hizo `/stop` pensando que solo mataría un subagent específico. En realidad terminó 4 subagents (Finalizar Pre-flight, Testing Crons, Rate Limit, Config Drift) que estaban trabajando en paralelo. **Solución:** Usar comando más específico o advertir antes de usar /stop. |
| 2026-03-24 | Subagents matados prematuramente no pierden trabajo si ya escribieron sus scripts/archivos | Los 4 subagents originales (sonnet) fueron matados por `/stop` pero su trabajo (scripts Python de 16-25KB) ya estaba escrito en disco. Al relanzarlos (gemini-3-flash), solo tuvieron que verificar/testear lo existente. **Learning:** Flush output temprano, no acumular todo en memoria. |
| 2026-03-24 | Gemini 3 Flash es suficiente para tareas de verificación/testing de código ya escrito | Los 4 subagents relanzados (gemini-3-flash) completaron verificación y testing de scripts complejos (api-health-checker.py 25KB, cron-validator.py 19KB, etc.) sin problemas. **Implicación:** No siempre necesitamos Sonnet para todo. |
| 2026-03-24 | Detectar status de subagent (running/completed/stopped) requiere combinar runs.json + transcript analysis | `runs.json` solo distingue running vs ended. Para distinguir completed vs stopped hay que analizar transcripts: última entrada con role="custom" → completed, de lo contrario → stopped. **Implementado en:** `scripts/openclaw-subagents-tui-blessed/index.js` |
| 2026-03-24 | Task labels de subagents están en transcripts con marcador `[Subagent Task]:` | Descubierto al implementar TUI. El marcador aparece en primera entrada del transcript. **Uso:** Extraer con regex `/\[Subagent Task\]:\s*(.+?)(?:\n|$)/`. |
| 2026-03-24 | Token usage de subagents está en `message.usage` de cada entrada del transcript | Hay que acumular de todas las entradas del transcript. **Implementado en:** TUI dashboard con acumulación correcta. |

---

### TUI/Dashboard

| Fecha | Learning | Contexto |
|-------|----------|----------|
| 2026-03-24 | Blessed es mejor opción que Textual para TUIs en Node.js | Comparación Blessed vs Textual vs Ink: Blessed es framework maduro (2015), sin deps nativas, buena documentación, usado por proyectos populares. **Alternativas descartadas:** Textual (Python, requiere cambiar stack), Ink (React, overhead innecesario). |
| 2026-03-24 | Auto-refresh cada 5s es sweet spot para dashboards de subagents | Probado con intervalos de 2s, 5s, 10s. 2s es demasiado agresivo (flickering), 10s se siente lento. 5s es responsive sin ser molesto. |
| 2026-03-24 | Text color=white es mandatory para blessed en terminal con fondo oscuro | Descubierto al debuggear "invisible text": color=gray en terminal con fondo negro = invisible. **Solución:** Forzar white en todos los elementos de texto. |
| 2026-03-24 | Visual indicators en TUI deben ser consistentes: símbolo + color + keyword | Implementado: ● running (green), ✓ completed (blue), ⏹ stopped (yellow), ✗ failed (red). La combinación de símbolo + color + texto hace el status obvio incluso si el usuario tiene problemas de visión de color. |

---

### Arneses

| Fecha | Learning | Contexto |
|-------|----------|----------|
| 2026-03-24 | Arneses necesitan 3 capas: detection (barato/rápido) + diagnosis (profundo) + remediation (automático/manual) | Pattern descubierto al diseñar api-health, rate-limit, config-drift. Ejemplo: **Detection** (health check cada 30min), **Diagnosis** (analizar logs cuando falla), **Remediation** (failover a provider alternativo). |
| 2026-03-24 | Health checks deben probar round-trip completo, no solo ping | `api-health-checker.py` hace request real (text generation) para validar que el provider está 100% funcional, no solo respondiendo HTTP 200. Descubrimos que algunos providers responden 200 pero luego timeout en requests reales. |
| 2026-03-24 | Rate limit monitors deben trackear rolling windows, no solo current | `rate-limit-monitor.py` trackea 6 métricas por API (RPM, RPD, TPM, TPD, concurrent, context window). Usar sliding window de últimas 24h para predecir cuándo nos acercaremos a límites. |
| 2026-03-24 | Config drift es más común de lo esperado | Archivos de config (`.openclaw/.env`, `config.json`) tienden a divergir de la documentación porque se editan manualmente. **Solución:** `config-drift-detector.py` compara contra golden config snapshot. |

---

### Crons

| Fecha | Learning | Contexto |
|-------|----------|----------|
| 2026-03-24 | Crons nocturnos deben espaciarse para evitar resource contention | Implementado: Backup 4:00, Autoimprove 2:00 (3 agentes), Reindex 4:30. Si se superponen, compiten por LLM tokens y pueden causar rate limits. **Espaciado mínimo:** 30 min entre crons pesados. |
| 2026-03-24 | Cron validator necesita dry-run real, no solo syntax check | `cron-validator.py` ejecuta crons con `--dry-run` flag cuando esté disponible. Syntax check solo detecta errores de bash, no lógica ni dependencies. |
| 2026-03-24 | Log de crons debe ser structured (JSON o formato consistente) para facilitar parsing | Decidido después de intentar parsear logs inconsistentes. **Standard:** `[TIMESTAMP] [CRON_NAME] [LEVEL] Message`. Permite usar jq/awk para análisis. |

---

### Gateway

| Fecha | Learning | Contexto |
|-------|----------|----------|
| 2026-03-24 | Restart de Gateway es safe si se avisa antes | No hay pérdida de datos porque workspace es filesystem-based. Subagents en ejecución se pierden, pero su output escrito en disco persiste. **Best practice:** Advertir a Manu antes de restart. |
| 2026-03-24 | Gateway logs están en journalctl, no en workspace | `journalctl -u openclaw-gateway -n 100 --no-pager`. Importante recordar esto al debuggear issues del gateway. |

---

### Security

| Fecha | Learning | Contexto |
|-------|----------|----------|
| 2026-03-24 | Prompt injection defense requiere multi-layer approach | Research del caso de uso 10 (YouTube video). Necesitamos: (1) Text sanitation determinística, (2) Frontier scanner IA-based, (3) Outbound PII/secrets scanner, (4) Scoped permissions, (5) Approval system, (6) Runtime governance. Un solo layer no es suficiente. |
| 2026-03-24 | Secrets/tokens en código es el error más común en nuevos scripts | Detectado múltiples veces durante code review. **Solución:** Pre-commit hook que escanea con `git secrets` + `trufflehog`. |
| 2026-03-24 | Security no es solo prevenir intrusiones, también prevenir self-harm | Ejemplo: código que borra archivos críticos por error (`rm -rf` mal usado). Defense: whitelist de comandos permitidos, blacklist de destructivos. |

---

### Logging

| Fecha | Learning | Contexto |
|-------|----------|----------|
| 2026-03-24 | Logs baratos (1GB ~ 2 meses) hacen debugging infinitamente más fácil | Caso de uso 11 (YouTube video). Vale la pena loggear agresivamente. Ejemplo: subagent TUI invisible text debuggeado en minutos gracias a logs detallados. |
| 2026-03-24 | Daily logs necesitan complementarse con learnings log y decisions log | Daily log es cronológico y detallado. Learnings/decisions logs son temáticos y filtrados (solo lo importante). Ambos son necesarios. |
| 2026-03-24 | Log review matutino debe ser automático, no manual | Cron diario (propuesto 7:30 AM) que revisa logs de últimas 24h, identifica errores/warnings, propone fixes. Integrar en informe matutino 10 AM. |

---

### Memory

| Fecha | Learning | Contexto |
|-------|----------|----------|
| 2026-03-24 | Memory architecture cambios deben evaluarse contra impacto en archivos existentes | SOUL.md: "Conserve first. Before any structural change to memory architecture, assess impact on existing files, embeddings, autoimprove, and cron workflows." Añadir learnings.md y decisions.md es safe porque son aditivos, no modifican estructura existente. |
| 2026-03-24 | One source of truth: cada pieza de conocimiento tiene exactamente un canonical home | SOUL.md principle. Learnings van en learnings.md, no en daily logs ni MEMORY.md. Decisions van en decisions.md. Daily logs son cronológicos, no temáticos. |

---

## Cómo Usar Este Archivo

### Al Completar una Tarea
1. Pregúntate: **¿Qué aprendí que no sabía antes?**
2. Pregúntate: **¿Qué error cometí o casi cometo?**
3. Pregúntate: **¿Qué solución funcionó mejor de lo esperado?**
4. Si la respuesta es interesante → añadir entrada en categoría apropiada

### Al Empezar una Tarea Nueva
1. Buscar en este archivo por categoría o keyword
2. Revisar learnings relevantes
3. Aplicar conocimiento para evitar repetir errores

### Durante Code Review
- Verificar que el código no repite errores documentados aquí
- Añadir nuevos learnings descubiertos durante review

---

**Última actualización:** 2026-03-24  
**Próxima revisión:** Diaria (cada sesión matutina)
