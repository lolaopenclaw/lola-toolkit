# PR Review Automático — Protocolo

**Created:** 2026-03-13
**Status:** Active
**Skill:** `skills/pr-review/SKILL.md`
**Scanner:** `scripts/pr-reviewer.sh`
**Model default:** Sonnet

## Cómo funciona

1. Un cron (o invocación manual con `/pr-review`) consulta GitHub por PRs abiertas
2. Filtra las que ya fueron revisadas (tracking por SHA del último commit)
3. Para cada PR pendiente: descarga el diff, lanza un sub-agente Sonnet
4. El sub-agente analiza seguridad, correctitud, calidad y estilo
5. Publica el review como comentario en el PR de GitHub
6. Marca la PR como revisada (no se revisa dos veces el mismo commit)
7. Si hay nuevos commits → se re-revisa automáticamente

## Qué revisa (por prioridad)

1. **🔴 Seguridad** — secrets, injection, XSS, eval, datos sensibles en logs
2. **🟡 Correctitud** — errores de lógica, null handling, edge cases, race conditions
3. **🔵 Calidad** — código muerto, duplicación, tests faltantes
4. **Estilo** — solo si impacta legibilidad significativamente

## Seguridad del enfoque

- **Cero superficie de ataque nueva** — la VPS consulta a GitHub, no al revés
- **Token reutilizado** — usa el mismo GH_TOKEN que gh-issues
- **Idempotente** — safe to re-run, no duplica reviews

## Configuración por repo

Para activar en un repo, solo necesitas:
1. Que el GH_TOKEN tenga acceso al repo
2. Configurar un cron: `/pr-review owner/repo --notify {channel}`

## Costes estimados

- ~$0.05 por review con Sonnet (diff <50KB)
- Un repo con 5 PRs/día ≈ $7.50/mes
