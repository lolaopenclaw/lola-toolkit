# 2026-03-05 — LobsterBoard Custom Widgets (Session Synthesis)

**Duración:** ~2h de trabajo activo (14:00-16:50)

## 🎯 Logros

### ✅ 3 Widgets Custom Funcionales
- 💰 **Finanzas** — Google Sheets (ingresos, gastos, balance mes actual)
- ❤️ **Garmin** — Script de salud (HR, pasos, sueño, battery)
- 📅 **Calendar** — Google Calendar (próximos eventos)

### ✅ API Backend
- `api-custom.cjs` en puerto 5001 con `/api/{finanzas,garmin,calendar}`
- systemd service (`lobsterboard-api.service`) para auto-arranque
- Caching inteligente (1h/30min/15min según fuente)

### ✅ Plugin System (Perdura Actualizaciones)
- Carpeta `plugins/` con widgets individuales
- `server.cjs` inyecta plugins antes de `builder.js` (timing correcto)
- Auto-inyecta sección "🎨 Custom" en sidebar
- NO se toca en updates de LobsterBoard

## 🐛 Bugs Encontrados & Resueltos

| Bug | Causa | Fix |
|-----|-------|-----|
| Widgets no renderizaban | `p.properties.title` vs `p.title` | Usar `p.title` directamente |
| API devolvía `--` en systemd | PATH no incluía `/home/linuxbrew/.linuxbrew/bin/gog` | Cargar PATH en api-custom.cjs |
| Plugins no cargaban antes que builder.js | Inyección al final de `</body>` | Inyectar antes de `<script src="js/builder.js">` |
| Plugins escribían `window.WIDGETS` pero builder usaba `const WIDGETS` | Namespace conflict | Plugins usan `WIDGETS` global directamente |

## 📚 Lecciones Aprendidas

1. **LobsterBoard Property Access**: `generateHtml(props)` recibe propiedades aplanadas, no `props.properties.*`
2. **systemd + PATH**: Los servicios no heredan PATH de .bashrc; hay que especificar rutas completas
3. **Script injection timing**: Los scripts de extensión deben cargar ANTES del código que los usa
4. **Plugin survival**: Código custom en `plugins/` no se toca en updates (solo cambios core)

## 🗂️ Archivos Clave

```
/home/mleon/lobsterboard/
├── plugins/
│   ├── finanzas.js
│   ├── garmin.js
│   ├── calendar.js
│   └── loader.js (auto-inyecta sidebar)
├── api-custom.cjs (API backend con caching)
├── DEVELOPMENT.md (docs para futuros widgets)
└── .config/systemd/user/lobsterboard-api.service
```

## 🎨 Documentación Creada

- `DEVELOPMENT.md` — Custom widget dev guide (property access + escaping patterns)
- Comentarios en código

## ✨ Próximas Ideas

- [ ] Body Battery widget mejorado (gráfica mini)
- [ ] Gastos por categoría (pie chart)
- [ ] Alarmas inteligentes (HR elevado, poco sueño)
- [ ] Sincronización con Notion Ideas automática

## 🔗 Referencias

- git commits: ee2ffc3, b19586e, dfea50e (main branch)
- API responde en `http://127.0.0.1:5001/api/{finanzas,garmin,calendar}`
- systemd service: `systemctl --user status lobsterboard-api.service`
