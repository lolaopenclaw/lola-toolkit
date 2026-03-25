# PRD Maintenance Protocol

**Archivo:** `PRD.md` (workspace root)
**Creado:** 2026-03-25
**Propósito:** Documentar todas las features del sistema para presentaciones y referencia

## Regla

Cada vez que se añada, modifique o elimine una feature del sistema (nuevo script, skill, cron, integración, etc.), actualizar PRD.md en el mismo commit.

## Trigger de actualización
- Nuevo script/skill creado
- Nuevo cron job añadido
- Integración nueva (API, servicio externo)
- Feature eliminada o deprecada
- Cambio significativo en arquitectura

## Quién actualiza
- Lola: automáticamente al hacer cambios
- Autoimprove: puede sugerir actualizaciones si detecta drift entre PRD y realidad
