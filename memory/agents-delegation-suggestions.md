# Sugerencias de Cambios para AGENTS.md

**Fecha:** 2026-03-24  
**Contexto:** Implementación de Delegate Aggressively Strategy

---

## CAMBIOS PROPUESTOS

### 1. Nueva Sección: "Subagents"

**Ubicación sugerida:** Después de "Memory", antes de "Safety"

**Contenido propuesto:**

```markdown
## Subagents

**Delegate aggressively.** Hasta 5 en paralelo. Monitoring: `subagents-dashboard`.

### Cuándo delegar:
- Duración >5 min + independiente + sin decisiones humanas
- Ver guía completa: `memory/delegation-strategy.md`
- Templates: `memory/subagent-templates.md`

### Main session:
- **Orchestrate, don't execute.** Si puedes paralelizar, hazlo.
- Subagents auto-anuncian cuando terminan → no hagas busy-poll.
- Revisa `subagents list` solo on-demand (para debugging o cuando pregunten).

### Subagent sessions:
- **Stay focused.** Una tarea, nada más.
- **Be ephemeral.** Terminas y desapareces.
- **Don't initiate.** Ni heartbeats, ni crons, ni acciones externas no solicitadas.
```

**Justificación:**  
- Establece la filosofía de delegación como parte del workflow normal
- Referencia los docs detallados sin duplicar contenido
- Diferencia entre comportamiento de main session vs subagent

---

### 2. Modificación: "Every Session"

**Cambio en línea 9-11:**

```diff
## Every Session

1. Read `SOUL.md`, `USER.md`, `PROJECTS.md`
2. Read `memory/YYYY-MM-DD.md` (today + yesterday)
3. Read `memory/pending-actions.md` — present unresolved items to Manu proactively
-4. **Main session:** Also read `MEMORY.md` + `memory/verification-protocol.md` — Just do it.
+4. **Main session only:** Also read `MEMORY.md` + `memory/verification-protocol.md` + consider delegating long tasks (see Subagents section)
```

**Justificación:**  
- Clarifica que el paso 4 es main-only
- Hint sutil hacia delegación sin ser prescriptivo

---

### 3. Modificación: Sección "Communication" (opcional)

**Adición al final de la sección "Communication":**

```markdown
- **Long tasks:** Consider spawning subagent instead of blocking the conversation.
```

**Justificación:**  
- Reinforza el patrón de delegación en contexto de interacción con usuario
- Evita que el main agent se quede "pensando" 10+ min sin responder

---

## CAMBIOS NO RECOMENDADOS

### ❌ NO añadir reglas automáticas de spawning

**Evitar cosas como:**
```markdown
"Si una tarea va a tomar >5 min, DEBES spawnar subagent"
```

**Razón:**  
- Queremos que el agent use juicio, no reglas rígidas
- Hay casos legítimos donde una tarea larga debe hacerse directamente (ej: usuario está esperando, necesita streaming de progreso)

### ❌ NO duplicar el contenido de delegation-strategy.md

**Razón:**  
- AGENTS.md es high-level, las guías detalladas van en memory/
- Evita drift entre documentos (single source of truth)

---

## ESTRUCTURA PROPUESTA FINAL DE AGENTS.md

```
# AGENTS.md - Workspace
## Every Session
## Memory
## Subagents          ← NUEVO
## Safety
## External Actions
## Heartbeats
## Time Estimation
```

---

## IMPLEMENTACIÓN

**Acción requerida:**  
Dado que soy subagent, **NO debo editar AGENTS.md directamente**.  

**Próximos pasos (para main agent o Manu):**
1. Revisar estas sugerencias
2. Si aprueban, hacer los edits en AGENTS.md
3. Commit con mensaje: "Add subagent delegation guidelines to AGENTS.md"

---

## ALTERNATIVE: Documentar en Lugar Separado

Si preferís mantener AGENTS.md más limpio, alternativa válida:

- NO tocar AGENTS.md
- Toda la estrategia queda en `memory/delegation-strategy.md` y `memory/subagent-templates.md`
- Main agent simplemente los lee cuando corresponda (triggered por duration/complexity)

**Pros:** AGENTS.md más conciso, menos cambios a archivo core  
**Cons:** Estrategia no está en el "manifesto" principal

**Recomendación:** Añadir la sección mini en AGENTS.md (punto 1 de arriba) + details en memory/. Best of both worlds.

---

## MÉTRICAS DE ÉXITO POST-IMPLEMENTACIÓN

Después de aplicar estos cambios, rastrear:

1. **¿Aumenta la delegación?** Count de subagents spawned/día
2. **¿Mejora la success rate?** % de subagents que completan correctamente
3. **¿Mejor UX?** Usuario recibe respuestas rápidas mientras subagents trabajan en background

Evaluar en 1 semana y ajustar strategy según findings.

---

**Conclusión:** Cambios mínimos, alto impacto. Hacen la delegación parte del workflow normal sin sobrecargar AGENTS.md.
