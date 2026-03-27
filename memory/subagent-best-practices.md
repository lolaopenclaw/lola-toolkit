# Subagent Best Practices

**Última actualización:** 2026-03-27

Principios y estándares para spawning y diseño de generadores/evaluadores.

---

## ⏱️ TIMEOUT DEFAULTS

**Cambio crítico (2026-03-27):** Aumentados de 3-5 min a **10 min** para evitar falsos positivos.

### Configuración Estándar

```javascript
sessions_spawn({
  // GENERATORS
  runTimeoutSeconds: 600,  // 10 min default
  
  // EVALUATORS  
  runTimeoutSeconds: 600,  // 10 min default (antes 180-300)
})
```

### Cuándo Reducir

**SOLO reduce timeout si:**
- Tarea trivial verificable en <2 min (ej. "check file exists")
- Has probado que completa consistentemente en <X segundos
- Es quick-win task (syntax check, grep, ls)

**NUNCA uses <300s (5 min) para:**
- Evaluadores que deben leer múltiples archivos
- Generadores que escriben código/docs
- Tareas que requieren reflexión/análisis

### Rationale

El investigation report mostró:
- Evaluadores completaban exitosamente en 7-9 min
- 180-300s timeout → timeouts prematuros → feedback loop roto
- **Better to wait 10 min than to miss valid completions**

---

## 🛡️ RALPH WIGGUM CHECKS

**Principio:** Los generadores deben auto-validarse ANTES de reportar "completado".

### Mandatory Pre-Completion Checks

Todo generador DEBE incluir en su output final:

#### 1. Syntax Validation

```bash
# Bash scripts
bash -n script.sh

# Python
python3 -m py_compile script.py

# JSON/YAML
jq . config.json
yamllint file.yml
```

#### 2. Hardcoded Path Scan

```bash
# Buscar /home/mleon (debe ser relativo o usar $HOME)
grep -r "/home/mleon" .

# Buscar /home/ en general
grep -r "/home/" . | grep -v ".git"
```

#### 3. Basic Smoke Test

```bash
# Scripts
timeout 10s ./script.sh --help

# CLIs
timeout 5s command --version

# Módulos
timeout 10s node -e "require('./lib/module.js')"
```

### Output Format

El generador DEBE reportar:

```markdown
## Pre-Completion Validation

✅ Syntax valid (bash -n passed)
✅ No hardcoded paths (/home/ grep returned 0)
✅ Smoke test passed (--help returned 0)

**Ready for evaluation.**
```

### Beneficio

Evaluadores pueden **skip redundant checks** si generator ya las reportó:

```markdown
## EVALUATOR CHECKLIST

1. ~~Syntax valid~~ (generator confirmed) → SKIP
2. ~~Hardcoded paths~~ (generator confirmed) → SKIP
3. **Integration test:** Run with real data → RUN THIS
4. **Edge cases:** Empty input, large input → RUN THIS
```

**Result:** Evaluadores se enfocan en checks de alto nivel, no syntax básica.

---

## 📝 GENERATOR OUTPUT REQUIREMENTS

### Estructura Mínima

```markdown
## TASK: [Nombre]

[Qué hice, 1-2 líneas]

## Files Modified/Created

- `path/file1.js` — [qué cambió]
- `memory/doc.md` — [qué se añadió]

## Pre-Completion Validation

✅ [Check 1]
✅ [Check 2]
✅ [Check 3]

## Ready for Evaluation

[Instrucción explícita para evaluador: qué verificar]
Example: "Verifica que script corre sin errores con `./script.sh --test`"
```

### Anti-Patterns

❌ **NO:**
- "Creo que está listo" (da evidencia)
- Output sin file list (evaluador debe buscar)
- "Probablemente funciona" (corre smoke test)

✅ **SÍ:**
- Lista concreta de archivos
- Validación ejecutada con output
- Instrucción clara para evaluador

---

## 🎯 TASK DECOMPOSITION

### Tamaño Ideal

- **Single task:** 15-40 min
- **Si >40 min:** Descompón en subtasks secuenciales
- **Si <10 min:** Considera si necesitas subagent (puede ser tool call directo)

### Secuencial vs Paralelo

**Secuencial (spawn uno, espera resultado, spawn siguiente):**
- Research → Implementation
- Generator → Evaluator
- Backup → Migration → Verification

**Paralelo (spawn múltiples simultáneos):**
- Auditar skills A, B, C (independientes)
- Investigar 3 opciones distintas
- Test suites para módulos sin dependencias

### Ejemplo: Task Grande

❌ **MAL:**
```
"Implementa rate-limiting completo con tests, docs, y migración"
(80 min, demasiado grande)
```

✅ **BIEN:**
```
1. Generator: "Implementa middleware rate-limiting (30 min)"
2. Evaluator: "Verifica que middleware funciona (10 min)"
3. Generator: "Añade tests (25 min)"
4. Evaluator: "Verifica cobertura ≥80% (10 min)"
```

---

## 🔄 GENERATOR ↔ EVALUATOR FEEDBACK LOOP

### Flujo Ideal

```
1. Generator crea/modifica archivos
   ├─ Runs Ralph Wiggum checks
   └─ Reports "Ready for evaluation"

2. Evaluator verifica output
   ├─ Si PASS → Done
   └─ Si FAIL → Spawn nuevo generator con feedback específico

3. Generator v2 corrige issues
   └─ Reports fixes + re-validates
   
4. Evaluator re-verifica
   └─ PASS → Done
```

### Límite de Iteraciones

**Max 2 iterations** por default:
- Generator → Evaluator → Generator (fix) → Evaluator → **STOP**
- Si falla después de 2 iterations: **Escala a humano**

Evita loops infinitos.

---

## 🚨 CUANDO ESCALAR

No spawns subagent si:

- ❌ Requiere decisiones humanas mid-task
- ❌ Necesita context de conversación (usa main agent)
- ❌ Involucra acciones irreversibles sin confirmación (delete, deploy)
- ❌ Task es trivial (<5 min, mejor tool call directo)

Sí spawn si:

- ✅ Tarea bien definida, independiente, 15-50 min
- ✅ Entregables concretos (archivos, reports)
- ✅ Criterios de éxito verificables programáticamente
- ✅ No requiere input humano durante ejecución

---

## 📚 REFERENCIAS

- **Templates:** `memory/subagent-templates.md`
- **Evaluator prompts:** `memory/evaluator-prompt-template.md`
- **Dashboard:** `subagents-dashboard`
- **Investigation:** `memory/evaluator-timeout-investigation-2026-03-27.md`

---

**TL;DR:**

1. **10 min timeout** para generators y evaluators (600s)
2. **Ralph Wiggum checks** = syntax/paths/smoke test ANTES de reportar done
3. **Output claro** con file list + validation results
4. **Max 2 iterations** en feedback loop
5. **Escala a humano** si requiere decisiones o falla 2x
