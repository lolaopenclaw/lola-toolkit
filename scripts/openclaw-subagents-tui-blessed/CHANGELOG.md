# Changelog

All notable changes to OpenClaw Subagents Dashboard will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-24

### Added
- 🎉 Initial MVP release
- Dashboard de estadísticas globales (total subagents, activos, tokens)
- Lista de subagents con indicadores de actividad (● activo / ○ inactivo)
- Panel de detalles con breakdown completo de tokens
- Session ID corto para legibilidad (primeros 8 chars)
- Auto-refresh cada 3 segundos
- Keyboard shortcuts: ↑↓ navegación, r refresh, q quit
- Status bar con timestamp último refresh
- Colores contextuales (rojo si >80% uso de tokens)
- Timestamps formateados en español
- Soporte para navegación vi-style (j/k)
- Scrollbar en lista y panel de detalles
- Mouse support para selección
- Single-file implementation (350 LOC)
- Documentación completa (README.md)
- Script de instalación (install.sh)

### Technical Details
- **Framework:** blessed v0.1.81
- **Runtime:** Node.js (ES modules)
- **Data source:** `openclaw sessions --json` (polling)
- **No build step required**
- **Zero vulnerabilities** (npm audit)

### Documentation
- README.md - Documentación técnica
- CHANGELOG.md - Este archivo
- ../../../docs/ralph-tui-research.md - Investigación completa
- ../../../docs/subagents-dashboard-summary.md - Resumen ejecutivo
- ../../../docs/ralph-tui-lessons-learned.md - Lecciones aprendidas

## [Unreleased]

### Planned for v1.1 - Controles básicos
- [ ] Pausar/reanudar subagent (tecla `p`)
- [ ] Terminar subagent (tecla `k` con confirmación)
- [ ] Integración con OpenClaw control API
- [ ] Diálogo de confirmación para acciones destructivas
- [ ] Feedback visual de acciones (toast messages)

### Planned for v1.2 - Logs
- [ ] Panel de logs (toggle tecla `l`)
- [ ] Tail de logs del subagent seleccionado
- [ ] Search en logs (tecla `/`)
- [ ] Copy to clipboard (tecla `c`)
- [ ] Log level filtering

### Planned for v1.3 - Filtros y UX
- [ ] Filtrar por modelo (tecla `f`)
- [ ] Filtrar por provider
- [ ] Filtrar por actividad (solo activos)
- [ ] Ordenar por tokens / age (tecla `s`)
- [ ] Temas de color (tecla `t`)
- [ ] Configuración persistente

### Planned for v2.0 - Advanced
- [ ] Árbol jerárquico de subagents anidados
- [ ] Gráficos de uso de tokens (sparklines)
- [ ] Export a JSON/CSV (tecla `e`)
- [ ] Persistencia de selección entre sesiones
- [ ] Notificaciones (subagent completado, error)
- [ ] Panel de historial de subagents completados
- [ ] Métricas de performance (tiempo promedio, tokens/s)
- [ ] Dashboard personalizable (panels drag-drop)

### Ideas para Futuro
- [ ] Modo compact (less verbose para pantallas pequeñas)
- [ ] Soporte para múltiples agents (no solo main)
- [ ] WebSocket support para updates en tiempo real
- [ ] Integración con Prometheus/Grafana (métricas)
- [ ] Plugin system para extensiones customizadas
- [ ] API HTTP para control remoto

## Development Notes

### Version Numbering
- **Major (X.0.0):** Breaking changes, arquitectura completa
- **Minor (0.X.0):** Nuevas features, backward compatible
- **Patch (0.0.X):** Bug fixes, mejoras menores

### Release Process
1. Actualizar CHANGELOG.md
2. Bump version en package.json
3. Tag en git: `git tag v1.0.0`
4. Push tag: `git push origin v1.0.0`
5. Comunicar en Telegram

### Contributing
Ver [CONTRIBUTING.md] cuando exista.  
Por ahora: editar index.js y documentar cambios aquí.

---

**Mantenedora:** Lola (OpenClaw AI Assistant)  
**Usuario:** Manu (@RagnarBlackmade)  
**Repo:** (privado en workspace OpenClaw)
