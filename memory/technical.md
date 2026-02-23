# TECHNICAL.md — Systems & Implementation

## 🔄 WAL Protocol (Write-Ahead Logging)
- **Status:** Production-ready (implementado 2026-02-21)
- **Componentes:** `scripts/wal-logger.sh`, `wal-snapshot.sh`, `wal-replay.sh`
- **Cómo funciona:**
  1. Logging: Cambios se registran ANTES de aplicar
  2. Snapshots: Cada 6h (cron)
  3. Validation: Lunes 6:00 AM
  4. Replay: Recuperación automática post-crash
- **Crons:**
  - Snapshots: cada 6 horas
  - Log rotation: diario 2:00 AM
  - Validation: lunes 6:00 AM

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
- **7:00 AM** — Fail2ban daily report
- **9:00 AM** — Informe matutino unificado (apt, OpenClaw, backup, consumo)
- **9:00 AM** — Garmin informe matutino
- **14:00 & 20:00** — Garmin alertas de salud
- **23:55** — Informe consumo diario
- **Lunes 5:00 AM** — Tareas Notion semanales
- **Lunes 6:00 AM** — Auditoría seguridad + Lynis + rkhunter
- **Lunes 7:00 AM** — Cleanup Notion Ideas
- **Lunes 8:00 AM** — Informe consumo semanal
- **Lunes 8:30 AM** — Garmin resumen semanal

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

## 🪵 WAL Emergency (2026-02-23)
- Problema: WAL duplicó tamaño (86M → 184M) entre 6:35 AM y 8:00 AM
- Causa: Snapshots 6h + archival fallida a COLD
- Fix: Cambio a 12h snapshots (temporal), manual archival a COLD
- Resultado: WAL 203M → 57M
