# OpenClaw Subagents TUI Dashboard

Terminal UI dashboard para monitorear subagents activos de OpenClaw en tiempo real.

![Dashboard Preview](preview.png)

## 🚀 Quick Start

```bash
# Desde el directorio workspace/scripts
./subagents-dashboard

# O directamente desde el directorio del dashboard
cd openclaw-subagents-tui-blessed
node index.js
```

## 📋 Features

### ✅ Implementadas (MVP v1.0)

- **Dashboard de estadísticas globales**
  - Total de subagents activos
  - Subagents activos en los últimos 2 minutos
  - Total de tokens consumidos
  - Promedio de tokens por subagent

- **Lista de subagents**
  - Indicador visual de actividad (● activo / ○ inactivo)
  - Session ID corto (primeros 8 caracteres UUID)
  - Modelo usado (nombre corto)
  - Tokens totales consumidos
  - Tiempo transcurrido desde última actualización

- **Panel de detalles**
  - Session ID completo
  - Agent ID
  - Modelo y provider
  - Desglose de tokens (input/output/total/límite/uso %)
  - Timestamp última actualización
  - Edad de la sesión

- **Auto-refresh**
  - Polling cada 3 segundos
  - Indicador de refresh en status bar

- **Keyboard shortcuts**
  - `↑↓` / `j/k` - Navegar lista
  - `r` - Refrescar manualmente
  - `q` / `Ctrl+C` - Salir

### ❌ NO Implementadas (futuras expansiones)

- Control de subagents (pause/resume/kill)
- Streaming de logs en tiempo real
- Árbol jerárquico de subagents anidados
- Gráficos de uso de tokens
- Persistencia de estado entre sesiones
- Filtros y búsqueda
- Export de datos

## 🏗️ Arquitectura

### Stack Técnico

- **Runtime:** Node.js (ES modules)
- **TUI Framework:** blessed v0.1.81
- **Data Source:** `openclaw sessions --json` (polling)
- **No dependencies** aparte de blessed

### Estructura

```
openclaw-subagents-tui-blessed/
├── index.js          # Aplicación completa (all-in-one)
├── package.json      # Dependencies
└── README.md         # Esta documentación
```

**Decisión de diseño:** Todo en un solo archivo (`index.js`) para simplicidad.  
Código dividido en secciones lógicas:

1. **Data Layer** - Fetching y procesamiento de sesiones
2. **UI Setup** - Configuración de componentes blessed
3. **State Management** - Actualización de estado y UI
4. **Event Handlers** - Keyboard y eventos
5. **Initialize** - Entry point

## 📊 Fuente de Datos

### OpenClaw Sessions API

```bash
openclaw sessions --json
```

**Estructura sesión:**
```json
{
  "sessionId": "agent:main:subagent:UUID",
  "agentId": "main",
  "kind": "direct",
  "model": "anthropic/claude-sonnet-4-5",
  "modelProvider": "anthropic",
  "inputTokens": 15652,
  "outputTokens": 3421,
  "totalTokens": 19073,
  "contextTokens": 200000,
  "updatedAt": "2026-03-24T09:15:42.123Z",
  "ageMs": 125340
}
```

### Identificación de Subagents

**Criterio:** Session ID contiene `:subagent:`

```javascript
sessions.filter(s => s.sessionId.includes(':subagent:'))
```

**Pattern:** `agent:main:subagent:UUID`

### Definición de "Activo"

**Activo:** `ageMs < 120000` (< 2 minutos desde última actualización)

## 🔧 Desarrollo

### Modificar UI

Editar `index.js`, secciones:

- **Layout:** Buscar `blessed.box()` / `blessed.list()`
- **Contenido:** Buscar funciones `update*()`
- **Estilos:** Buscar `style:` en componentes

### Cambiar frecuencia de refresh

Buscar `setInterval` y modificar:

```javascript
setInterval(async () => {
  if (!loading) {
    await loadSessions();
  }
}, 3000); // <-- cambiar aquí (en ms)
```

### Añadir keyboard shortcut

Buscar sección "Event Handlers" y añadir:

```javascript
screen.key(['x'], () => {
  // Tu acción aquí
});
```

## 🐛 Troubleshooting

### Dashboard muestra "No active subagents found"

**Causas posibles:**
1. No hay subagents corriendo actualmente
2. `openclaw sessions` no devuelve datos
3. Subagents tienen pattern de sessionId diferente

**Debug:**
```bash
# Verificar sesiones directamente
openclaw sessions --json | jq '.sessions[] | select(.sessionId | contains("subagent"))'
```

### Dashboard se congela o no refresca

**Solución:** Presiona `r` para refrescar manualmente o reinicia el dashboard.

### Error "command not found: openclaw"

**Solución:** Asegúrate de que OpenClaw está instalado y en PATH:
```bash
which openclaw
# Si no encuentra, instalar o añadir al PATH
```

## 📈 Comparación con Ralph TUI

### Ralph TUI (original)
- **Propósito:** Orquestador autónomo de agentes AI
- **Features:** Control de ejecución, task tracking, subagent tracing
- **Stack:** Bun + OpenTUI (React) + Zig
- **Complejidad:** Alta (framework complejo, build nativo)

### Este Dashboard (blessed)
- **Propósito:** Monitoreo pasivo de subagents OpenClaw
- **Features:** Vista read-only, stats, auto-refresh
- **Stack:** Node.js + blessed
- **Complejidad:** Baja (single file, JS puro, sin build)

**Trade-offs:**
- ✅ Más simple y rápido de implementar
- ✅ Menos dependencias (solo blessed)
- ✅ No requiere build step
- ❌ No reutiliza components de Ralph TUI
- ❌ UI menos sofisticada que React-based TUI

## 🚧 Roadmap (Posibles Expansiones)

### Versión 1.1 - Controles básicos
- [ ] Pausar/reanudar subagent (`p`)
- [ ] Terminar subagent (`k`)
- [ ] Confirmación antes de kill

### Versión 1.2 - Logs
- [ ] Panel de logs (toggle con `l`)
- [ ] Tail de logs de subagent seleccionado
- [ ] Search en logs

### Versión 1.3 - Filtros
- [ ] Filtrar por modelo (`/`)
- [ ] Filtrar por age (solo activos, etc.)
- [ ] Ordenar por tokens

### Versión 2.0 - Advanced
- [ ] Árbol jerárquico de subagents anidados
- [ ] Gráficos de uso de tokens (sparklines)
- [ ] Export a JSON/CSV
- [ ] Persistencia de selección
- [ ] Temas de color

## 📝 Changelog

### v1.0 (2026-03-24)
- ✨ Initial MVP release
- Dashboard de stats globales
- Lista de subagents con navegación
- Panel de detalles
- Auto-refresh cada 3s
- Keyboard shortcuts básicos

## 📄 License

MIT

---

**Creado para:** OpenClaw  
**Fecha:** 2026-03-24  
**Tiempo desarrollo:** ~2.5h (investigación + prototipo)
