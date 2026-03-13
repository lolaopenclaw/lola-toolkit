# HEARTBEAT — Silent Checks

Zero-notification-if-OK. Quiet 23:00-07:00 Madrid.

Checks (silencio=OK, alerta=fallo):
1. **Cron** errors>0 → alerta
2. **Gateway** unusual → alerta
3. **Kanban** critical → alerta
4. **Gmail** breach → alerta
5. **Memory** >15MB → alerta+limpiar
6. **Sandbox** pending → alerta
7. **Session synthesis** >10msgs
8. **Garmin health** critical only
9. **Calendar** urgent → alerta
10. **Fail2ban SSH** ≥10:crítica, 5-10:matutino
11. **Workspace self-review** — `git log --oneline --since="4 hours ago"` en workspace. Si hay commits significativos, revisar diff rápido (seguridad, errores). Solo alertar si hay algo preocupante.
12. **PR review pendiente** — Comprobar PRs abiertas sin review en repos monitorizados (ver `memory/proactive-suggestions.md`). Alertar si hay PRs >24h sin review.

13. **Autoimprove Nightly resumen** — Si existe `memory/{today}-autoimprove.md`, incluir resumen en el informe matutino. Solo reportar mejoras aplicadas, no intentos fallidos.

Heartbeat mejorado: Tarea→progreso("Paso N/M"), sino→HEARTBEAT_OK
