# Subagent Task Templates

**Última actualización:** 2026-03-24

Plantillas reutilizables para tipos comunes de tareas. Copy-paste y adapta según necesites.

---

## 🔍 RESEARCH

### Uso:
Investigación extensa, comparación de tecnologías, análisis de best practices

### Template:

```markdown
**Objetivo:** Investigar [TEMA] para [PROPÓSITO]

**Contexto:**
- [Por qué necesitamos esta info]
- [Qué vamos a hacer con ella]
- [Restricciones técnicas (lenguaje, framework, etc.)]

**Qué investigar:**
1. [Aspecto 1: ej. "Algoritmos disponibles"]
2. [Aspecto 2: ej. "Performance comparisons"]
3. [Aspecto 3: ej. "Production gotchas"]
4. [Aspecto 4: ej. "Recommended libraries/tools"]

**Fuentes:**
- Documentación oficial
- Blog posts de empresas con scale similar
- GitHub repos populares
- Papers (si aplica)

**Entregables:**
1. `memory/[tema]-research.md` con:
   - Resumen ejecutivo (1 párrafo)
   - Comparación de opciones (tabla pros/cons)
   - Recomendación con justificación
   - Referencias/links

**Tiempo estimado:** 20-40 min

**Criterios de éxito:**
- Al leer el doc, podemos tomar decisión informada
- Pros/cons claros para cada opción
- Links funcionan
```

### Ejemplo completo:

```markdown
**Objetivo:** Investigar soluciones de job queuing para procesamiento async en OpenClaw

**Contexto:**
- Necesitamos procesar tareas pesadas sin bloquear el main agent
- Volumen: ~100-500 jobs/día
- Node.js runtime, Linux
- Debe sobrevivir restarts

**Qué investigar:**
1. Opciones: BullMQ, Bee-Queue, Agenda, pg-boss
2. Requisitos: Redis vs PostgreSQL, persistencia, retries, scheduling
3. Monitoring: cómo ver estado de queues, failed jobs
4. Integration: API complexity, TypeScript support

**Fuentes:**
- npm trending, GitHub stars
- Production case studies
- Comparativas de performance

**Entregables:**
1. `memory/job-queue-research.md` con comparación y recomendación

**Tiempo estimado:** 30-40 min

**Criterios de éxito:**
- Tabla comparativa de 4 opciones
- Recomendación clara con 3 razones
- Ejemplo de código para la opción recomendada
```

---

## 💻 IMPLEMENTACIÓN

### Uso:
Añadir features completas, crear nuevos módulos/skills, implementar fixes complejos

### Template:

```markdown
**Objetivo:** Implementar [FEATURE] en [MÓDULO/SKILL]

**Contexto:**
- Ubicación: [path al código]
- Tech stack: [lenguaje, frameworks, dependencias]
- Estado actual: [qué existe ya]
- [Decisiones de diseño ya tomadas]

**Qué implementar:**
1. [Componente/función 1]
   - Input/output esperado
   - Edge cases a manejar
2. [Componente/función 2]
3. [Tests]
4. [Documentación]

**Archivos a modificar/crear:**
- `[path/file1.js]` — [qué cambiar]
- `[path/file2.md]` — [qué actualizar]

**Entregables:**
1. Código funcional que pase tests existentes
2. Tests nuevos (≥[N] casos, cobertura ≥80%)
3. Documentación actualizada (README/SKILL.md)
4. Ejemplo de uso

**Restricciones:**
- [No romper compatibilidad con X]
- [Seguir estilo del código existente]
- [Límites de performance: <Xms]

**Tiempo estimado:** 25-50 min

**Criterios de éxito:**
- [ ] Tests pasan (`npm test` o equivalente)
- [ ] Feature funciona según spec
- [ ] Documentación incluye ejemplo funcional
- [ ] Código sigue style guide del proyecto
```

### Ejemplo completo:

```markdown
**Objetivo:** Implementar rate-limiting en gateway HTTP de OpenClaw

**Contexto:**
- Ubicación: `src/gateway/middleware/`
- Tech stack: Node.js, Express, Redis
- Estado actual: No hay rate-limiting, solo auth básica
- Decisión: Usar algoritmo sliding window, 100 req/min per user

**Qué implementar:**
1. Middleware `rateLimiter.js`:
   - Sliding window en Redis
   - Keys: `ratelimit:{userId}:{timestamp}`
   - Headers: RateLimit-Limit, RateLimit-Remaining, RateLimit-Reset
   - 429 con Retry-After cuando excede
2. Config en `config/rateLimit.js`:
   - Limits por role: anonymous=10/min, user=100/min, admin=1000/min
3. Tests en `tests/middleware/rateLimiter.test.js`:
   - Normal flow (dentro de límite)
   - Excede límite → 429
   - Reset después de window
   - Different users no interfieren

**Archivos a modificar/crear:**
- `src/gateway/middleware/rateLimiter.js` — nuevo
- `src/gateway/app.js` — añadir middleware
- `config/rateLimit.js` — nuevo
- `tests/middleware/rateLimiter.test.js` — nuevo
- `docs/gateway.md` — documentar rate-limiting

**Entregables:**
1. Middleware funcional con tests pasando
2. Config externalisada
3. Documentación con ejemplos de headers

**Restricciones:**
- Redis debe ser opcional (fallback a in-memory)
- No afectar latencia >5ms p99
- Backward compatible (feature flag si es necesario)

**Tiempo estimado:** 40-50 min

**Criterios de éxito:**
- [ ] `npm test` pasa
- [ ] Request limitado devuelve 429 con headers correctos
- [ ] Latency p99 <5ms overhead
- [ ] Docs incluyen curl examples
```

---

## 🧪 TESTING

### Uso:
Añadir tests a código legacy, aumentar cobertura, test suite completo de un módulo

### Template:

```markdown
**Objetivo:** Crear test suite completo para [MÓDULO/FUNCIÓN]

**Contexto:**
- Código a testear: `[path]`
- Framework de test: [Jest/Mocha/pytest/etc.]
- Cobertura actual: [X%] (o "sin tests")
- Objetivo cobertura: ≥[Y%]

**Qué testear:**
1. **Happy paths:**
   - [Caso normal 1]
   - [Caso normal 2]
2. **Edge cases:**
   - [Input vacío]
   - [Input muy grande]
   - [Input inválido]
3. **Error handling:**
   - [Qué pasa si falla X]
   - [Qué pasa si timeout]
4. **Integration:**
   - [Interacción con módulo Y]

**Entregables:**
1. `tests/[módulo].test.js` con ≥[N] casos
2. Fixtures/mocks en `tests/fixtures/` si necesario
3. Tests pasan y dan cobertura ≥[Y%]
4. README con instrucciones de cómo correr tests

**Tiempo estimado:** 20-40 min

**Criterios de éxito:**
- [ ] `npm test` pasa
- [ ] Cobertura ≥[Y%] verificada
- [ ] Cada test es legible (nombre describe qué verifica)
- [ ] No hay tests flaky (pasan consistentemente)
```

### Ejemplo completo:

```markdown
**Objetivo:** Crear test suite para parser de comandos del skill de Spotify

**Contexto:**
- Código: `skills/spotify-control/lib/parser.js`
- Framework: Jest
- Cobertura actual: 0% (sin tests)
- Objetivo: ≥85%

**Qué testear:**
1. **Happy paths:**
   - `/play Song Title` → {action: 'play', query: 'Song Title'}
   - `/pause` → {action: 'pause'}
   - `/volume 50` → {action: 'volume', level: 50}
2. **Edge cases:**
   - `/play` (sin título) → error
   - `/volume abc` (no numérico) → error
   - Comando desconocido → error
   - Espacios extra, case insensitive
3. **Integration:**
   - Parser → spotify_player CLI format

**Entregables:**
1. `tests/parser.test.js` con ≥12 casos
2. Tests pasan, cobertura ≥85%

**Tiempo estimado:** 30 min

**Criterios de éxito:**
- [ ] `npm test -- parser` pasa
- [ ] Cobertura lines ≥85%
- [ ] Cada error case devuelve mensaje útil
```

---

## 🔎 AUDITORÍA

### Uso:
Code review, security audit, búsqueda de bugs, análisis de quality

### Template:

```markdown
**Objetivo:** Auditar [ASPECTO] en [SCOPE]

**Contexto:**
- Qué auditar: [código/config/documentación/etc.]
- Ubicación: [paths]
- Enfoque: [security/performance/style/bugs/etc.]

**Qué buscar:**
1. [Anti-pattern 1: ej. "Secrets hardcoded"]
2. [Anti-pattern 2: ej. "SQL injection"]
3. [Anti-pattern 3: ej. "Memory leaks"]
4. [Best practice violations]

**Herramientas:**
- [Linter, static analyzer, etc.]
- `rg` para buscar patterns
- Manual review

**Entregables:**
1. `memory/audit-[tema]-[fecha].md` con:
   - Executive summary (cuántos issues, severidad)
   - Lista de findings (file:line, descripción, severity, fix suggestion)
   - Recomendaciones prioritizadas
2. (Opcional) PRs con fixes triviales

**Tiempo estimado:** 30-60 min

**Criterios de éxito:**
- Todos los archivos en scope revisados
- Issues categorizados por severidad (critical/high/medium/low)
- Cada finding tiene sugerencia de fix
```

### Ejemplo completo:

```markdown
**Objetivo:** Auditar security en todos los skills de OpenClaw

**Contexto:**
- Scope: `~/.openclaw/workspace/skills/*/`
- Enfoque: Secrets leakage, command injection, file access
- ~25 skills instalados

**Qué buscar:**
1. **Secrets:**
   - API keys hardcoded (grep `apiKey`, `api_key`, `token`)
   - Passwords en plain text
   - .env files commiteados
2. **Command injection:**
   - User input en `exec()` sin sanitización
   - `eval()` o equivalente
3. **File access:**
   - Paths sin validación
   - Directory traversal (`../`)
4. **Dependencies:**
   - `npm audit` en cada skill que tenga package.json

**Herramientas:**
- `rg -i "(api[_-]?key|password|secret)" skills/`
- `rg "exec\(.*\$\{" skills/`
- Manual review de scripts críticos

**Entregables:**
1. `memory/audit-skills-security-2026-03-24.md` con findings
2. Issues críticos notificados inmediatamente
3. (Opcional) PRs para fixes quick

**Tiempo estimado:** 45-60 min

**Criterios de éxito:**
- [ ] Todos los skills escaneados
- [ ] Findings con severity + file:line
- [ ] Al menos 3 recomendaciones priorizadas
```

---

## 🔄 MIGRACIÓN

### Uso:
Actualizar formato de archivos, refactor estructural, mover código entre módulos

### Template:

```markdown
**Objetivo:** Migrar [QUÉ] de [FORMATO/UBICACIÓN A] a [FORMATO/UBICACIÓN B]

**Contexto:**
- Items a migrar: [cuántos, dónde están]
- Razón de la migración: [por qué]
- Backward compatibility: [necesaria/no necesaria]

**Plan:**
1. **Pre-migration:**
   - Backup de [archivos originales] → [ubicación backup]
   - Validar que [prerequisitos]
2. **Migration:**
   - [Paso 1: ej. "Convertir formato"]
   - [Paso 2: ej. "Mover archivos"]
   - [Paso 3: ej. "Actualizar referencias"]
3. **Post-migration:**
   - Verificar que [criterio 1]
   - Verificar que [criterio 2]
   - Tests pasan

**Entregables:**
1. Archivos migrados en nueva ubicación/formato
2. `migration-report.md` con:
   - Cuántos items migrados exitosamente
   - Errores/warnings
   - Rollback instructions
3. (Si aplica) Script de migración reutilizable

**Rollback plan:**
- [Cómo deshacer si algo falla]

**Tiempo estimado:** [X-Y min]

**Criterios de éxito:**
- [ ] 100% de items migrados sin pérdida de datos
- [ ] Tests pasan post-migración
- [ ] Documentación actualizada con nueva estructura
```

### Ejemplo completo:

```markdown
**Objetivo:** Migrar todas las notas de memoria de formato plain text a front-matter YAML

**Contexto:**
- Items a migrar: ~50 archivos .md en `memory/`
- Razón: Estandarizar metadata (date, tags, category)
- Backward compatibility: No necesaria (solo lectura humana)

**Plan:**
1. **Pre-migration:**
   - Backup: `tar czf memory-backup-2026-03-24.tar.gz memory/`
   - Validar que todos los .md son UTF-8
2. **Migration:**
   - Script que añade front-matter:
     ```yaml
     ---
     created: [extract de filename o mtime]
     updated: [mtime]
     tags: []
     ---
     ```
   - Preservar contenido existente
   - Actualizar referencias rotas (si detectas)
3. **Post-migration:**
   - Verificar que ningún .md está corrupto
   - `rg "^---$" memory/` debe dar ~100 matches (50 files × 2)
   - Spot-check 5 archivos random

**Entregables:**
1. 50 archivos migrados con front-matter
2. `memory/migration-to-frontmatter-report.md` con count y errores
3. Script `scripts/add-frontmatter.sh` reutilizable

**Rollback plan:**
- Restore: `tar xzf memory-backup-2026-03-24.tar.gz`

**Tiempo estimado:** 25-35 min

**Criterios de éxito:**
- [ ] 50/50 archivos con front-matter válido
- [ ] Contenido intacto (diff body only, ignoring front-matter)
- [ ] Backup existe y es válido
- [ ] Report lista cualquier warning
```

---

## 🎨 CUSTOM TASKS

Para tareas que no encajan en templates: construye híbrido o crea tu propio template.

### Híbrido (Research + Implementation):

```markdown
**Parte 1 - Research (15 min):**
[Usar template RESEARCH]

**Parte 2 - Implementation (30 min):**
[Usar template IMPLEMENTACIÓN]
- Input: Resultado de la research (recomendación elegida)
```

### Template nuevo:

Si un tipo de tarea se repite >3 veces, crea template y añade aquí.

---

## 📋 CHECKLIST PRE-SPAWN

Antes de lanzar un subagent, verifica:

- [ ] Objetivo específico y alcanzable
- [ ] Entregables concretos (archivos, no "entender X")
- [ ] Tiempo estimado realista
- [ ] No requiere decisiones humanas mid-task
- [ ] Independiente (no necesita context de conversación)
- [ ] Criterios de éxito verificables

Si falta algo, refina el task description primero.

---

## 🔗 REFERENCIAS

- Delegation strategy completa: `memory/delegation-strategy.md`
- Dashboard: `subagents-dashboard`
- Logs: `subagents log <id>`

**Mantra:** Template bien elegido = subagent exitoso.
