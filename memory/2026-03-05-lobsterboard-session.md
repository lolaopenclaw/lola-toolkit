# 2026-03-05 — LobsterBoard Custom Widgets Implementation

## Sesión: ~2 horas (13:00-14:50 Madrid)

### 🎯 Objetivo
Crear 3 widgets custom para LobsterBoard (Finanzas, Garmin, Calendar) con datos reales y que sobrevivan actualizaciones del framework.

### 🐛 Problema encontrado y resuelto
**Bug de rendering:** `p.properties.title` → `p.title`
- LobsterBoard pasa propiedades APLANADAS a `generateHtml()`, no anidadas
- Documentado en DEVELOPMENT.md para futuros widgets

### ✅ Solución arquitectónica
**Plugin system** (`plugins/` directory):
1. Cada widget en su archivo: `plugins/finanzas.js`, `plugins/garmin.js`, `plugins/calendar.js`
2. `plugins/loader.js` inyecta sección "🎨 Custom" en sidebar dinámicamente
3. `server.cjs` carga plugins ANTES de `builder.js` (timing crítico)
4. Plugins NO se tocan en updates de LobsterBoard → persisten

### 🔧 Backend
**`api-custom.cjs`** (puerto 5001):
- `/api/finanzas` → Google Sheets (mes actual)
- `/api/garmin` → health-report.sh (HR, pasos, sueño)
- `/api/calendar` → Google Calendar events
- Caching inteligente (1h/30min/15min según criticidad)
- **systemd service** para auto-arranque (fixed PATH + env vars)

### 📊 Datos en vivo
- 💰 Finanzas: €242,31 ingresos, €-1.571,58 gastos, balance €-1.329,27
- 📅 Calendario: evento "Lola-cosa" a las 14:00
- ❤️ Garmin: HR 67 bpm, 172 pasos, 7.5h sueño

### 📚 Documentación
- DEVELOPMENT.md → guía de custom widgets (property access + escaping patterns)
- Commits: 3 PRs cubriendo bug fix, plugin system, API backend

### 🚀 Próximos pasos (opcionales)
- Arreglar hueco visual en dashboard (layout adjustment)
- Mejorar Body Battery data (--current no devuelve ese valor)
- Crear más plugins en el futuro (usa `plugins/` como template)

### 🔑 Lecciones aprendidas
1. **Timing de scripts es crítico** — plugins deben cargar antes que builder.js
2. **WIDGETS vs window.WIDGETS** — usar const global, no window object
3. **systemd service PATH** — necesita incluir brew paths para gog, scripts
4. **Escaping en JS generado** — evitar inline styles, usar CSS classes
