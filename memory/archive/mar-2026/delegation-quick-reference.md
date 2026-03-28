# Delegation Quick Reference Card

**One-pager:** Cuándo delegar, cuándo no, templates rápidos.

---

## ⚡ DECISION TREE

```
┌─ Tarea toma >5 min?
│
├─ NO → HAZ TÚ MISMA
│
└─ SÍ ─┬─ Necesita decisiones humanas?
       │
       ├─ SÍ → HAZ TÚ MISMA (o draft + pedir aprobación)
       │
       └─ NO ─┬─ Necesita contexto conversacional?
              │
              ├─ SÍ → HAZ TÚ MISMA
              │
              └─ NO → 🚀 DELEGAR A SUBAGENT
```

---

## 📝 TEMPLATES RÁPIDOS

### Research (20-40 min):
```bash
sessions_spawn --task "Research [TEMA] para [PROPÓSITO].
Context: [3 bullets].
Investiga: 1) [aspecto], 2) [aspecto], 3) [aspecto].
Deliverable: memory/[tema]-research.md con resumen + recomendación."
```

### Implementación (25-50 min):
```bash
sessions_spawn --task "Implementar [FEATURE] en [path].
Context: [tech stack], [estado actual].
Deliverables: 1) código funcional, 2) tests ≥80%, 3) docs actualizadas.
Criterios: tests pasan, ejemplo funcional en docs."
```

### Testing (20-40 min):
```bash
sessions_spawn --task "Crear test suite para [path/file].
Framework: [Jest/etc], cobertura objetivo ≥85%.
Casos: happy paths, edge cases, errors.
Deliverable: tests/[file].test.js pasando con cobertura ≥85%."
```

### Auditoría (30-60 min):
```bash
sessions_spawn --task "Auditar [aspecto] en [scope].
Buscar: 1) [anti-pattern], 2) [anti-pattern], 3) [anti-pattern].
Herramientas: rg, [linter], manual review.
Deliverable: memory/audit-[tema]-[date].md con findings + severity + fixes."
```

### Migración (variable):
```bash
sessions_spawn --task "Migrar [QUÉ] de [A] a [B].
Plan: 1) backup, 2) migrate [N] items, 3) verify.
Deliverable: archivos migrados + migration-report.md + rollback instructions.
Criterio: 100% migrados sin pérdida de datos."
```

---

## 🚨 ANTI-PATTERNS

❌ "Investiga X y dime qué encontraste"  
✅ "Investiga X y guarda resumen en memory/X-research.md"

❌ "Ayúdame a entender Y"  
✅ Read/search directamente, O "Analiza Y y documenta en memory/Y-analysis.md"

❌ Delegar tarea de 2 min  
✅ Hacerla directamente

❌ Delegar algo que requiere aprobación humana mid-task  
✅ Hacer draft → mostrar a Manu → implementar

---

## 📊 MONITORING

```bash
# Dashboard TUI (recomendado)
subagents-dashboard

# CLI
subagents list              # Ver todos
subagents status <id>       # Estado de uno
subagents log <id>          # Logs
subagents kill <id>         # Terminar si colgado
```

---

## ⏱️ TIEMPO ESTIMADO

| Tipo          | Típico    | Máx recomendado |
|---------------|-----------|-----------------|
| Research      | 20-40 min | 60 min          |
| Implementación| 25-50 min | 90 min          |
| Testing       | 20-40 min | 60 min          |
| Auditoría     | 30-60 min | 90 min          |
| Migración     | Variable  | 120 min         |

**Si >90 min:** Considera romper en sub-tasks o añadir checkpoints.

---

## ✅ CHECKLIST PRE-SPAWN

- [ ] Objetivo claro y específico
- [ ] Entregables concretos (archivos)
- [ ] Sin decisiones humanas mid-task
- [ ] Independiente del contexto conversacional
- [ ] Tiempo estimado realista
- [ ] Criterios de éxito verificables

---

## 🎯 OBJETIVOS

- **Success rate:** >85%
- **Paralelización:** Usar 3-5 slots cuando posible
- **Respuesta rápida:** Delegar → responder a usuario → background work

---

**Full docs:**  
- Strategy: `memory/delegation-strategy.md`  
- Templates: `memory/subagent-templates.md`  
- AGENTS.md suggestions: `memory/agents-delegation-suggestions.md`
