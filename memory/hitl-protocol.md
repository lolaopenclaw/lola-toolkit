# HITL Protocol — Human In The Loop

**Created:** 2026-03-13
**Status:** Active

## Cuándo se activa

El protocolo HITL se activa cuando una tarea cumple **cualquiera** de estas condiciones:

1. **Toca código en producción** (servicios activos, configs del sistema, crons críticos)
2. **Implica más de ~20 minutos de trabajo** estimado
3. **Afecta a múltiples archivos/sistemas** (cambios transversales)
4. **Tiene consecuencias difíciles de revertir** (migraciones, deploys, borrados)
5. **Involucra decisiones de diseño/arquitectura** (hay más de un camino razonable)
6. **Sub-agentes en paralelo** (antes de lanzar múltiples agentes)

## Cuándo NO se activa

- Tareas simples y directas ("pon una cron", "lee este archivo", "busca X")
- Correcciones menores o ediciones puntuales
- Consultas/análisis/opiniones (como las de hoy sobre repos)
- Cuando Manu dice explícitamente "hazlo directamente" o "sin paradas"

## Fases

### Fase 1: EXPLORAR
Analizo el contexto: qué hay, qué afecta, qué riesgos veo.
→ Presento resumen breve a Manu.
→ **Checkpoint:** ¿Sigo?

### Fase 2: PROPONER
Presento el plan concreto: qué voy a hacer, en qué orden, qué archivos toco.
Si hay alternativas razonables, las presento con pros/contras.
→ **Checkpoint:** ¿Este enfoque o prefieres otro?

### Fase 3: IMPLEMENTAR
Ejecuto el plan aprobado. Si encuentro algo inesperado que cambia el plan, paro y aviso.

### Fase 4: VERIFICAR
Ejecuto verificación (tests, checks, confirmación visual).
Presento resultado con evidencia.
→ **Checkpoint final:** ¿Todo OK?

## Formato de checkpoint

Breve, no ceremonioso. Ejemplo:

```
📋 Plan: Modificar auth/login.ts, añadir middleware OAuth Google, 
actualizar 3 tests existentes, añadir 2 nuevos.
Estimado: ~15 min. Riesgo: bajo (no toca producción).
¿Adelante?
```

## Override

Manu puede saltar fases en cualquier momento con:
- "Hazlo directamente" → Skip a Fase 3
- "Confío, dale" → Skip a Fase 3
- "Para" → Abort

## Notas

- No ser pesado con los checkpoints en tareas obvias
- El objetivo es AHORRAR tiempo (pillar errores de rumbo temprano), no AÑADIR burocracia
- Si dudo entre activar HITL o no → NO activar (errar del lado de la agilidad)
