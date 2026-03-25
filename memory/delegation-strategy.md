# Delegation Strategy - Cuándo Delegar a Subagents

**Última actualización:** 2026-03-24

---

## Filosofía

**Delega agresivamente.** Los subagents liberan tu contexto y permiten paralelización. Hasta 5 en paralelo. Monitoring vía `subagents-dashboard`.

---

## ✅ CUÁNDO DELEGAR

### Criterios principales:

1. **Duración >5 minutos** — Tarea que requiere múltiples pasos o investigación
2. **Independiente** — No necesita contexto de la conversación actual con el usuario
3. **No requiere interacción** — Puede completarse sin decisiones humanas en medio
4. **Paralelizable** — Puede ejecutarse mientras haces otras cosas o lanzas más subagents

### Casos ideales:

- **Research extenso:** "Investiga las 10 mejores prácticas de X"
- **Implementaciones completas:** "Añade feature Y con tests"
- **Auditorías:** "Revisa toda la codebase buscando Z"
- **Migraciones:** "Migra todos los archivos de formato A a B"
- **Testing exhaustivo:** "Prueba todos los casos edge de esta función"
- **Documentación completa:** "Documenta todo el módulo X"
- **Análisis de datos:** "Analiza estos logs y extrae patrones"
- **Múltiples tareas independientes:** Lanzar 3-5 subagents en paralelo

---

## ❌ CUÁNDO NO DELEGAR

### Casos donde es más eficiente hacerlo directamente:

1. **Tarea trivial (<2 min)** — Leer un archivo, hacer un edit simple
2. **Requiere contexto conversacional** — Usuario está esperando respuesta inmediata basada en lo que acaba de decir
3. **Necesita decisiones humanas** — Hay opciones a elegir en medio del proceso
4. **Iterativo con usuario** — El usuario va a dar feedback paso a paso
5. **Muy acoplado a tu sesión actual** — Dependes del resultado inmediato para continuar

### Ejemplos:

❌ "Lee `SOUL.md` y dime el tone"  
✅ Simplemente: `read SOUL.md`

❌ "Busca en memoria si hemos hablado de X" (para responder al usuario ahora)  
✅ Usa `rg` directamente

❌ "Crea un subagent para escribir un email" (requiere revisión humana)  
✅ Redacta el draft tú misma y muéstraselo a Manu

---

## 📝 CÓMO ESCRIBIR BUENOS TASK DESCRIPTIONS

### Template básico:

```
**Objetivo:** [Acción específica + resultado esperado]

**Contexto:**
- [Info relevante sobre el sistema/proyecto]
- [Estado actual]
- [Restricciones o consideraciones]

**Qué implementar:**
1. [Paso/deliverable 1]
2. [Paso/deliverable 2]
3. [Paso/deliverable 3]

**Entregables:**
1. [Archivo/resultado específico 1]
2. [Archivo/resultado específico 2]

**Tiempo estimado:** [X-Y min]
```

### ✅ BUENOS ejemplos:

**Ejemplo 1 - Research:**
```
Objetivo: Investigar mejores prácticas de rate-limiting en APIs REST

Contexto:
- Vamos a implementar rate-limiting en nuestro gateway
- Tenemos hasta 5k req/s
- Usuarios autenticados vs anónimos

Qué investigar:
1. Algoritmos: token bucket, leaky bucket, sliding window
2. Headers estándar (RateLimit-*, Retry-After)
3. Redis vs in-memory para contadores
4. Cómo manejar burst traffic

Entregables:
1. memory/rate-limiting-research.md con resumen de cada approach
2. Recomendación con pros/cons para nuestro caso

Tiempo estimado: 20-30 min
```

**Ejemplo 2 - Implementación:**
```
Objetivo: Añadir comando /status a skill de Spotify con cobertura de tests

Contexto:
- Skill existente: ~/.openclaw/workspace/skills/spotify-control/
- Ya tenemos /play, /pause, /next
- Usamos spotify_player CLI

Qué implementar:
1. Añadir /status que muestre: canción actual, artista, playlist, tiempo
2. Tests unitarios para el parser de output
3. Actualizar SKILL.md con el nuevo comando + ejemplo

Entregables:
1. script status.sh funcional
2. tests/test-status.sh con ≥3 casos
3. SKILL.md actualizado

Tiempo estimado: 25-35 min
```

### ❌ MALOS ejemplos:

❌ **Demasiado vago:**
```
"Mejora el skill de GitHub"
```
→ ¿Qué significa "mejora"? ¿Qué aspecto? ¿Qué deliverable?

❌ **Requiere decisiones humanas:**
```
"Investiga si deberíamos usar Redis o PostgreSQL y elige el mejor"
```
→ La decisión final debe ser de Manu, no del subagent

❌ **Sin contexto:**
```
"Implementa autenticación OAuth"
```
→ ¿Para qué servicio? ¿Qué provider? ¿Dónde en el código?

❌ **Sin entregables claros:**
```
"Lee sobre WebSockets y aprende cómo funcionan"
```
→ ¿Qué hace el subagent con ese conocimiento? Especifica el output esperado

---

## 🚨 MANEJO DE SUBAGENTS QUE FALLAN

### Monitoreo:

```bash
# Dashboard TUI (recomendado)
subagents-dashboard

# CLI status
subagents list
subagents status <id>
subagents log <id>
```

### Problemas comunes:

#### 1. **Subagent colgado (>10 min sin output)**

```bash
# Revisar logs
subagents log <id> | tail -50

# Si está en loop o bloqueado
subagents kill <id>

# Relanzar con task description mejorada
```

**Fix:** Añade timeouts explícitos o rompe la tarea en pasos más pequeños

#### 2. **Subagent termina sin deliverables**

**Síntomas:** Exit code 0 pero archivos no creados

**Causas:**
- Task description ambigua
- Subagent interpretó mal el objetivo
- Error silencioso que no checkeó

**Fix:** 
- Haz los deliverables más explícitos
- Añade checkpoints: "Antes de terminar, verifica que existan X, Y, Z"

#### 3. **Subagent devuelve info pero no persiste**

**Ejemplo:** Research completo en el mensaje final pero no guardó memory/X.md

**Fix:** En task description, enfatiza:
```
CRÍTICO: Toda la información debe quedar guardada en memory/X.md.
No me devuelvas solo texto, crea el archivo.
```

#### 4. **Rate limits o API errors**

**Síntomas:** Fallos con `429 Too Many Requests` o timeouts

**Fix:**
- Añade delays entre requests
- Reduce el scope (menos items a procesar)
- Usa caching cuando sea posible

---

## 🎯 ESTRATEGIAS AVANZADAS

### Delegación en cascada:

Un subagent puede spawnar otros subagents (depth 2). Úsalo para:
- Coordinator + workers pattern
- Pipeline de procesamiento multi-etapa

**Ejemplo:** Skill-analyzer que spawna sub-auditors para cada aspecto

### Paralelización masiva:

```bash
# Lanzar 5 subagents en paralelo (límite actual)
# Cada uno procesa 1/5 del trabajo
```

**Casos ideales:**
- Procesar 500 archivos → 5 subagents × 100 archivos
- Testear 15 skills → 5 batches de 3 skills
- Research multi-dominio → 5 temas paralelos

### Checkpoint + retry:

Para tareas largas (>30 min):
1. Diseña con checkpoints intermedios
2. Si falla a mitad, puede resumir desde último checkpoint
3. Guarda estado en `memory/task-X-checkpoint.json`

---

## 📊 MÉTRICAS DE ÉXITO

**Rastrea en `memory/subagent-metrics.md`:**
- Total spawned: ~20 (hoy)
- Success rate: aim for >85%
- Avg duration
- Most common failure modes

**Improve continuously:**
- Refina templates basado en qué funciona
- Documenta anti-patterns
- Celebra los wins

---

## TL;DR

- **>5 min + independiente + sin decisiones humanas = DELEGAR**
- **Dashboard:** `subagents-dashboard`
- **Task descriptions:** Objetivo claro + contexto + entregables específicos + tiempo
- **Fallos:** Log, learn, iterate
- **Max 5 paralelos:** Úsalos bien

**Meta:** Tú orchestras, subagents ejecutan. Escala tu impacto 5x.
