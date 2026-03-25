# Ralph TUI - Investigación y Análisis para Dashboard OpenClaw Subagents

**Fecha:** 2026-03-24  
**Objetivo:** Evaluar viabilidad de adaptar Ralph TUI para dashboard de subagents OpenClaw  
**Tiempo investigación:** 45-60 min  
**Tiempo prototipo MVP:** 2-4h

---

## 1. ¿Qué es Ralph TUI?

**Repo:** https://github.com/syntax-syndicate/ralph-ai-tui

Ralph TUI es un **orquestador de agentes AI en loop autónomo** con interfaz terminal (TUI). 

### Propósito principal
- Conecta asistentes AI (Claude Code, OpenCode, Factory Droid) con task trackers
- Ejecuta tareas autónomamente en un loop: selecciona tarea → ejecuta agente → detecta completion → repite
- Tracking de progreso en tiempo real con dashboard visual

### Stack técnico
- **Runtime:** Bun (JavaScript)
- **Framework TUI:** OpenTUI (@opentui/react)
  - Basado en Zig nativo + bindings TypeScript
  - Reconciler React para terminal
  - Similar a Ink pero con core nativo de alto rendimiento
- **Lenguaje:** TypeScript/TSX
- **Templating:** Handlebars (prompts)
- **Config:** TOML + Zod schemas

---

## 2. Arquitectura Ralph TUI

```
ralph-tui/
├── src/
│   ├── cli.tsx              # Entry point CLI
│   ├── commands/            # Comandos CLI (run, resume, status, logs)
│   ├── config/              # Config loading + Zod validation
│   ├── engine/              # Loop de ejecución (iteration, eventos)
│   ├── interruption/        # Signal handling + graceful shutdown
│   ├── logs/                # Persistencia de logs de iteración
│   ├── plugins/
│   │   ├── agents/          # Agent plugins (claude, opencode)
│   │   │   └── tracing/     # Subagent tracing parser
│   │   └── trackers/        # Tracker plugins (beads, json)
│   ├── session/             # Session persistence + lock management
│   ├── templates/           # Prompt templates (Handlebars)
│   └── tui/                 # UI components (OpenTUI/React)
│       └── components/      # React components
│           ├── RunApp.tsx           # Componente principal ejecución
│           ├── ProgressDashboard.tsx # Dashboard de progreso
│           ├── LeftPanel.tsx        # Panel izquierdo (task list)
│           ├── RightPanel.tsx       # Panel derecho (detalles)
│           ├── SubagentTreePanel.tsx # Panel de subagents
│           ├── IterationHistoryView.tsx
│           └── ...
```

### Componentes clave TUI

#### RunApp.tsx
- **Propósito:** Componente raíz del dashboard de ejecución
- **Responsabilidades:**
  - Integración con `ExecutionEngine`
  - Gestión de estados (ready, running, paused, stopped, complete)
  - Keyboard shortcuts (s=start, p=pause, d=dashboard, i=history, u=subagents, q=quit)
  - Paneles izquierdo/derecho + overlays
  - Graceful interruption con diálogos de confirmación

#### ProgressDashboard.tsx
- **Datos mostrados:**
  - Status de ejecución (running, paused, complete, error)
  - Agente actual + modelo
  - Tracker + epic/project name
  - Task ID/title actual
  - Configuración sandbox (si activo)
- **Diseño:** Horizontal, info compacta con colores temáticos

#### SubagentTreePanel.tsx
- **Propósito:** Visualizar jerarquía de subagents en árbol
- **Features:**
  - Parse de tracing de subagents desde agent output
  - Árbol expandible/colapsable
  - Indicadores de estado (running, complete, error)
  - Estadísticas (profundidad, conteo)

---

## 3. OpenTUI Framework

**Repo:** https://github.com/anomalyco/opentui

### Características
- **Core nativo en Zig** (alto rendimiento)
- **Bindings TypeScript** con API imperativa
- **Reconciler React** (@opentui/react) y SolidJS (@opentui/solid)
- **Arquitectura basada en componentes** con layouts flexibles
- **Usado en producción:** OpenCode, terminal.shop

### Instalación
```bash
bun install @opentui/core
bun install @opentui/react
```

**Requisito:** Zig debe estar instalado en el sistema para build

### Hooks principales (React)
- `useKeyboard()` - Manejo de teclado
- `useTerminalDimensions()` - Dimensiones terminal
- `useRenderer()` - Rendering control

### Ventajas
- Alto rendimiento (core nativo)
- API similar a React para UI
- Soporte completo de layouts
- Buen ecosistema (ejemplos, skills)

### Desventajas
- Requiere Zig instalado
- Framework relativamente nuevo (adopción limitada)
- Documentación aún en desarrollo

---

## 4. Adaptación para OpenClaw Subagents

### 4.1 Requisitos del Dashboard

**Funcionalidad core:**
1. **Listar subagents activos** (desde OpenClaw sessions)
2. **Mostrar estado en tiempo real:**
   - sessionId, agentId, modelo
   - Tokens consumidos (input/output/total)
   - Estado (running, paused, complete, error)
   - Tiempo transcurrido
3. **Detalles de subagent:**
   - Task asignada
   - Output reciente (tail de logs)
   - Progreso (si aplica)
4. **Controles:**
   - Pausar/reanudar subagent
   - Terminar subagent
   - Ver logs completos
   - Refrescar estado

### 4.2 Fuente de datos

**OpenClaw sessions API:**
```bash
openclaw sessions --json
```

**Estructura sesión:**
```json
{
  "sessionId": "agent:main:subagent:UUID",
  "kind": "direct",
  "agentId": "main",
  "model": "anthropic/claude-sonnet-4-5",
  "inputTokens": 15652,
  "outputTokens": 3421,
  "totalTokens": 19073,
  "updatedAt": "2026-03-24T09:15:42.123Z",
  "contextTokens": 200000
}
```

**Desafío:** Las sesiones no tienen un campo `kind: "subagent"` directo. Se identifican por pattern `sessionId` que empieza con `"agent:main:subagent:"`.

### 4.3 Plan A: Adaptar Ralph TUI Components

**Reutilizar:**
- `RunApp.tsx` como base estructural (paneles, keyboard shortcuts)
- `ProgressDashboard.tsx` para mostrar stats globales
- `LeftPanel.tsx` para lista de subagents
- `RightPanel.tsx` para detalles de subagent seleccionado
- `SubagentTreePanel.tsx` (si hay jerarquía de subagents anidados)

**Modificar:**
1. **Data layer:** Reemplazar `ExecutionEngine` con polling a `openclaw sessions --json`
2. **Task → Subagent mapping:** Cambiar modelo de datos de TrackerTask a OpenClawSession
3. **Status mapping:** Adaptar estados de Ralph (ready, running, paused) a estados OpenClaw
4. **Output parsing:** Integrar con logs de OpenClaw (session store)

**Complejidad estimada:**
- **Ligera:** Si solo queremos vista read-only de sesiones activas (2-3h)
- **Media:** Si añadimos controles (pause/resume/kill) (4-6h)
- **Alta:** Si queremos integración profunda con tracing + logs streaming (8-12h)

### 4.4 Plan B: TUI Simplificado sin Ralph

**Alternativa:** Crear TUI desde cero con OpenTUI, sin reutilizar Ralph components.

**Ventajas:**
- Más simple, menos dependencias
- Control total sobre data flow
- Puede ser más ligero

**Desventajas:**
- Hay que implementar todo (paneles, keyboard, layouts)
- No reutilizamos trabajo existente de Ralph
- Más tiempo de desarrollo (6-8h mínimo)

**Decisión:** Plan B solo si Ralph es demasiado complejo de adaptar.

### 4.5 Plan C: Dashboard Web Simple (Fallback)

Si TUI resulta muy costoso, alternativa más rápida:

**Tech stack:**
- Node.js + Express
- Server-sent events (SSE) para updates en tiempo real
- HTML/CSS minimalista (sin framework frontend)
- Polling `openclaw sessions --json` cada 1-2 segundos

**Ventajas:**
- Muy rápido de implementar (1-2h)
- Accesible desde browser (más flexible)
- Fácil de compartir/deployar

**Desventajas:**
- No es TUI nativo (menos "cool factor")
- Requiere browser abierto
- Menos integrado con workflow terminal

---

## 5. Prototipo MVP - Scope Inicial

**Objetivo:** Dashboard read-only de subagents activos en <4h.

### Features MVP
1. ✅ **Lista de subagents activos**
   - sessionId, modelo, tokens
   - Tiempo transcurrido desde última actualización
   - Estado (activo si updated < 2 min)
2. ✅ **Dashboard de stats globales**
   - Total subagents activos
   - Total tokens consumidos
   - Promedio tokens por subagent
3. ✅ **Panel de detalles**
   - Seleccionar subagent → ver sessionId completo
   - Tokens breakdown (input/output/context)
   - updatedAt timestamp
4. ✅ **Keyboard shortcuts**
   - `↑↓` navegar lista
   - `Enter` ver detalles
   - `r` refrescar
   - `q` quit

### Features NO incluidas en MVP
- ❌ Control de subagents (pause/resume/kill)
- ❌ Streaming de logs en tiempo real
- ❌ Árbol jerárquico de subagents anidados
- ❌ Gráficos de uso de tokens
- ❌ Persistencia de estado

### Timeline MVP
- **Setup + investigación OpenTUI:** 30 min
- **Implementar data layer (polling sessions):** 45 min
- **UI components (lista + dashboard):** 90 min
- **Keyboard + navegación:** 30 min
- **Testing + bugs:** 45 min
- **TOTAL:** ~3.5h

---

## 6. Decisión: ¿Seguir adelante?

### ✅ PROS - Plan A (Adaptar Ralph)
- Components bien diseñados y probados
- OpenTUI es framework sólido
- Reutilizamos jerarquía de paneles + layouts
- Base para expansión futura (controles, tracing)

### ⚠️ CONTRAS - Plan A
- Requiere instalar Zig (dependencia adicional)
- Curva aprendizaje OpenTUI (aunque similar a React)
- Overhead de adaptar modelo de datos Ralph → OpenClaw
- Ralph TUI está optimizado para autonomous loops, no para monitoring pasivo

### Alternativa si Plan A no vale la pena
**Plan C (Dashboard web)** es mucho más rápido y cumple el objetivo de visibilidad.

---

## 7. Recomendación Final

### ⚡ Recomendación: **Plan A (MVP simplificado)**

**Razones:**
1. **Viabilidad técnica confirmada:** OpenTUI funciona, Ralph TUI tiene buenos patterns
2. **Tiempo razonable:** 3-4h para MVP read-only es aceptable
3. **Valor a largo plazo:** Si funciona, podemos expandir features (controles, logs streaming)
4. **Coolness factor:** TUI nativo es más satisfactorio que web UI

**Condiciones para abortar:**
- Si tras 1h de implementación no tenemos polling + lista básica → pasar a Plan C
- Si OpenTUI da problemas de build/Zig → pasar a Plan C
- Si adaptación de components toma >6h → pasar a Plan C

**Siguiente paso:** Empezar prototipo MVP (3-4h)

---

## 8. Notas Implementación

### Dependencias
```bash
cd /home/mleon/.openclaw/workspace/scripts
mkdir openclaw-subagents-tui
cd openclaw-subagents-tui
bun init -y
bun add @opentui/core @opentui/react react
```

### Estructura inicial
```
openclaw-subagents-tui/
├── package.json
├── tsconfig.json
├── src/
│   ├── cli.tsx              # Entry point
│   ├── data/
│   │   └── sessions.ts      # OpenClaw sessions polling
│   ├── components/
│   │   ├── App.tsx          # Componente raíz
│   │   ├── SubagentList.tsx # Lista de subagents
│   │   ├── Dashboard.tsx    # Stats globales
│   │   └── DetailPanel.tsx  # Detalles de subagent
│   └── types.ts             # TypeScript types
```

### Data fetching
```typescript
// data/sessions.ts
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export interface SubagentSession {
  sessionId: string;
  agentId: string;
  model: string;
  inputTokens: number;
  outputTokens: number;
  totalTokens: number;
  contextTokens: number;
  updatedAt: string;
  ageMs: number;
}

export async function fetchSubagentSessions(): Promise<SubagentSession[]> {
  const { stdout } = await execAsync('openclaw sessions --json');
  const data = JSON.parse(stdout);
  
  return data.sessions
    .filter((s: any) => s.sessionId.startsWith('agent:main:subagent:'))
    .map((s: any) => ({
      sessionId: s.sessionId,
      agentId: s.agentId,
      model: s.model,
      inputTokens: s.inputTokens,
      outputTokens: s.outputTokens,
      totalTokens: s.totalTokens,
      contextTokens: s.contextTokens,
      updatedAt: s.updatedAt,
      ageMs: s.ageMs,
    }));
}
```

---

## 9. Resultado Prototipo MVP

### ✅ Estado: COMPLETADO

**Tiempo total:** ~2.5h (45 min investigación + 1h 45 min prototipo)

### Decisión Técnica Final: blessed > OpenTUI

**Razón del cambio:**
- OpenTUI dio error de build con archivos `.scm` (tree-sitter grammar files)
- Requería Zig instalado (dependencia adicional no disponible)
- Curva de aprendizaje más alta de lo esperado

**Alternativa elegida:** `blessed` (librería TUI madura y estable)
- Instalación limpia sin dependencias nativas
- API simple y directa
- Single-file implementation posible
- Ampliamente usada en proyectos production

### Implementación Final

**Ubicación:** `/home/mleon/.openclaw/workspace/scripts/openclaw-subagents-tui-blessed/`

**Archivos:**
- `index.js` - Aplicación completa (8.3KB, all-in-one)
- `package.json` - Solo dependencia: blessed@0.1.81
- `README.md` - Documentación completa

**Wrapper script:** `/home/mleon/.openclaw/workspace/scripts/subagents-dashboard`

### Features Implementadas ✅

1. **Dashboard de stats globales**
   - Total subagents, activos (<2 min), total tokens, avg tokens
   - Layout horizontal con colores temáticos

2. **Lista de subagents (panel izquierdo)**
   - Indicadores visuales (● activo / ○ inactivo)
   - Session ID corto (8 chars)
   - Modelo, tokens, age
   - Navegación con ↑↓

3. **Panel de detalles (panel derecho)**
   - Session ID completo
   - Desglose completo de tokens con % de uso
   - Timestamps formateados
   - Colores contextuales (rojo si >80% tokens)

4. **Auto-refresh**
   - Polling cada 3 segundos
   - Status bar con timestamp

5. **Keyboard shortcuts**
   - `↑↓` / `j/k` - Navegar
   - `r` - Refresh manual
   - `q` / `Ctrl+C` - Quit

### Testing Manual

```bash
# Lanzar dashboard
cd /home/mleon/.openclaw/workspace/scripts
./subagents-dashboard
```

**Resultado:** ✅ TUI funciona correctamente
- UI se renderiza sin errores
- Componentes blessed funcionan (box, list, scrollbar)
- Polling a `openclaw sessions --json` exitoso
- Navegación con teclado operativa

### Limitaciones Conocidas

**No implementadas (por diseño MVP):**
- ❌ Control de subagents (pause/resume/kill)
- ❌ Streaming de logs
- ❌ Árbol jerárquico (subagents anidados)
- ❌ Gráficos de tokens
- ❌ Filtros/búsqueda

**Razón:** Scope MVP era solo vista read-only para validar viabilidad.

### Comparación Plans

| Criterio | Plan A (Ralph TUI) | Plan B (TUI simple) | **Plan B' (blessed)** | Plan C (Web) |
|----------|-------------------|-------------------|---------------------|--------------|
| Tiempo   | 3-4h (estimado)   | 6-8h (estimado)   | **2.5h (real)**     | 1-2h         |
| Complejidad | Alta | Media | **Baja** | Media |
| Build | Requiere Zig | Depende framework | **No build** | Requiere bundler |
| Deps | OpenTUI + React | A definir | **Solo blessed** | Express + frontend |
| Reutilización | Alta | Baja | **Baja** | N/A |
| Coolness | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | **⭐⭐⭐⭐** | ⭐⭐ |

**Ganador:** Plan B' (blessed) - Mejor balance tiempo/features/simplicidad

### Conclusión

✅ **Prototipo MVP exitoso**

**Viabilidad confirmada:**
- TUI nativo es factible para monitoring de subagents
- blessed es framework adecuado (simple, estable, sin deps nativas)
- Tiempo de desarrollo razonable (2.5h para MVP completo)

**Valor entregado:**
- Dashboard funcional para monitoreo en tiempo real
- Base sólida para expansión futura
- Documentación completa

**Próximos pasos sugeridos:**
1. Testing con subagents reales corriendo
2. Feedback de Manu sobre UX
3. Decisión sobre features v1.1 (controles, logs)

**Recomendación:** ✅ **Vale la pena continuar desarrollo**

Si se necesitan features avanzadas (controles, logs streaming), considerar:
- Añadir controles básicos a versión blessed (v1.1)
- O evaluar alternativa web (Plan C) para features complejas

---

**Estado:** ✅ Investigación completa + Prototipo MVP entregado  
**Tiempo total:** 2.5h  
**Entregables:**
- `/home/mleon/.openclaw/workspace/docs/ralph-tui-research.md` (este documento)
- `/home/mleon/.openclaw/workspace/scripts/openclaw-subagents-tui-blessed/` (código)
- `/home/mleon/.openclaw/workspace/scripts/subagents-dashboard` (wrapper script)
