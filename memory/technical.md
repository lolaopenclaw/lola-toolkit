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
- **Lunes 23:30** — Tier rotation *(descartado 2026-03-04: overkill para workspace pequeño)*
- **Domingo 22:00** — Cleanup audit
- **Domingo 23:00** — Memory organization + Guardian

## 📋 Reportes Matutinos — Actualizaciones (2026-03-04)

**Confirmado por Manu (12:11):**

**❌ Obsoleto (febrero):**
- WAL cleanup (3:00 AM)
- Memory tiers rotation reporting
- "Rotación automática memory tiers" en tareas automáticas

**✅ Vigente:**
- SISTEMA (uptime, disco, RAM, carga, actualizaciones)
- SEGURIDAD (Fail2Ban, alertas, auditoría próxima)
- BACKUP & ALMACENAMIENTO
- TAREAS AUTOMÁTICAS (versión actualizada)
- HOY (qué pasa hoy específicamente)
- PRÓXIMOS HITOS
- RESUMEN (estado general green/red)

**🆕 Posibles adiciones:**
- Garmin health reporting (si toca)
- Notion sync (si hay cambios)
- Stats consumo APIs (si es relevante)

*Mejoras al script matutino: hacerlas cuando Manu lo solicite*

## 🛡️ Ubuntu Pro (VPS Security)
- **Registro:** 2026-02-26 (cuenta: manuelleonmendiola@gmail.com)
- **Suscripción:** Ubuntu Pro - free personal subscription
- **Servicios activos:**
  - ✅ ESM-Infra — Parches de seguridad kernel/sistema hasta 2034
  - ✅ ESM-Apps — Parches de seguridad para aplicaciones extra
  - ✅ Livepatch — Parches críticos sin reinicio (¡gold!)
- **Disponibles (no activados):** FIPS-updates, Landscape, USG, realtime-kernel
- **Impacto:** Actualizaciones automáticas de seguridad + estabilidad crítica

## 🔐 Security Status (Último Check: 2026-03-02)

**Estado del sistema: ✅ SEGURO**
- Vulnerabilidades críticas: 0
- Puertos expuestos: 0 (todo localhost + Tailscale)
- SSH hardened: ✅ (root disabled, key-only, X11 off)
- Fail2ban: ✅ (3 jails activos, 0 intentos en 24h)
- Unattended-upgrades: ✅ (automático)
- OpenClaw: 2 warnings (no críticos, intencionales)

**Recomendaciones pendientes (baja prioridad):**
- Instalar UFW (confort, no necesario)
- Actualizar OpenClaw 2026.3.1 (cuando sea convenient)

**Detalles:** → `memory/2026-03-02-security-audit-weekly.md`

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
