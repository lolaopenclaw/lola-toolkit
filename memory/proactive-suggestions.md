# Proactive Suggestions Protocol

**Created:** 2026-03-13
**Status:** Active

## Cuándo sugerir Worktrees

Sugerir automáticamente git worktrees cuando:
- Se va a lanzar `gh-issues` con más de 1 issue en paralelo
- Se lanzan múltiples sub-agentes de coding sobre el mismo repositorio
- Cualquier tarea que implique branches paralelos en un mismo repo

Formato: "📌 Sugiero usar worktrees para esto — cada agente en su copia aislada. ¿Adelante?"

## Cuándo sugerir PR Review

Sugerir automáticamente review de PRs cuando:
- Un sub-agente acaba de abrir un PR
- Manu menciona que ha abierto/recibido un PR
- Hay PRs abiertas sin review en repos que monitorizamos
- Antes de mergear cualquier PR

Formato: "🔍 ¿Quieres que le pase el reviewer a esta PR antes de mergear?"

## Integración en Heartbeats

Durante cada heartbeat, además de los checks habituales:
1. Revisar commits recientes en el workspace (últimas horas)
2. Si hay commits significativos → self-review rápido
3. Si hay PRs abiertas en repos monitorizados → flag para review

## Repos monitorizados

(Añadir repos conforme se configuren)
- Workspace propio: siempre (self-review)
- Repos de Manu: cuando se configuren
