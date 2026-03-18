# HEARTBEAT — Silent Checks

Zero-notification-if-OK. Quiet 23:00-07:00 Madrid.

Checks:
1. **Cron** errors>0 → alerta
2. **Gateway** unusual → alerta
3. **Kanban** critical → alerta
4. **Gmail** breach → alerta
5. **Memory** >15MB → alerta+limpiar
6. **Sandbox** pending → alerta
7. **Session synthesis** >10msgs
8. **Garmin health** critical only
9. **Calendar** urgent → alerta
10. **Fail2ban SSH** ≥10:crítica
11. **Workspace self-review** — Revisar commits ult. 4h, alerta si sospechoso
12. **PR review** — Alertar si PRs >24h sin review

13. **Autoimprove Nightly resumen** — Si existe `memory/{today}-autoimprove.md`, incluir resumen en el informe matutino. Solo reportar mejoras aplicadas, no intentos fallidos.

Heartbeat mejorado: Tarea→progreso("Paso N/M"), sino→HEARTBEAT_OK
