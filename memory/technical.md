# TECHNICAL.md — Systems & Implementation

## 💾 Backup Strategy
- **Método:** Backup diario a Google Drive via rclone (`backup-memory.sh`)
- **Frecuencia:** 4:00 AM diario (cron)
- **Retención:** 30 días en Drive
- **Contenido:** Workspace completo (~768KB)
- **Recuperación:** `restore.sh` desde backup descargado
- **Nota:** WAL/snapshots se probaron (21-23 feb) pero se descartaron — overkill para ~1MB de markdown. Backups via rclone+git son suficientes.

## 🧠 Memory Management (Tiered Architecture)
- **HOT:** Últimos 7 días (memory/DAILY/HOT/)
- **WARM:** 8-30 días (memory/DAILY/WARM/)
- **COLD:** >30 días (.tar.gz comprimido, memory/DAILY/COLD/)
- **Rotation:** Lunes 23:30 (cron `tier-rotation.sh`)
- **Guardian:** Domingos 23:00 (`memory-guardian.sh`)
  - Detecta bloat, limpia backups viejos
  - Comprime archivos >30 días
  - Busca duplicados
  - Preserva CORE/, PROTOCOLS/, DAILY/HOT/

## 📋 Cron Jobs Activos
- **4:00 AM** — Backup a Google Drive (`backup-memory.sh`)
- **9:00 AM (L-V)** — Informe matutino unificado
- **9:10 AM (L-V)** — Informe consumo diario
- **9:30 AM (L-V)** — Populate Google Sheets
- **10:00 AM (S-D)** — Informe matutino fin de semana
- **14:00 & 20:00** — Garmin alertas de salud
- **Cada 6h** — Fail2Ban check
- **Lunes 5:30 AM** — Backup cleanup + validation
- **Lunes 9:00 AM** — Auditorías semanales (seguridad, Lynis, rkhunter, Notion, usage, tareas fondo)
- **Lunes 23:30** — Tier rotation
- **Domingo 22:00** — Cleanup audit
- **Domingo 23:00** — Memory organization + Guardian

## 🔐 Lecciones Técnicas Aprendidas
1. D-Bus SecretService no funciona en VPS headless → usar keyring file-based
2. Gemini API keys pueden revocarse → tener fallback local
3. Chrome en VPS necesita chrome-shim wrapper
4. Usar IDs oficiales de Anthropic (claude-haiku-4-5, no claude-haiku-3.5)
5. claude-3-5-haiku deprecated (19 feb 2026) → migrado a claude-haiku-4-5
6. Notion API 2025-09-03 rota → usar `Notion-Version: 2022-06-28`
7. Hardening SSH: `AllowTcpForwarding no` rompe VNC → necesario `AllowTcpForwarding yes`
8. XFCE en VNC necesita D-Bus: `dbus-launch` en ~/.vnc/xstartup
9. Memoria modular previene overflow: Dividir memory/YYYY-MM-DD.md cuando pase de ~4KB
10. Timezone VPS en UTC causaba confusiones → cambiar a Europe/Madrid
11. WAL/snapshots son overkill para workspace pequeño (~1MB markdown) → rclone+git suficiente
