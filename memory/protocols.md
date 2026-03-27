# PROTOCOLS.md — Backup, Security & Critical Changes

## 🔄 Backup & Recovery
**Full details:** `memory/backup-strategy.md`
- **Quick:** Cron 4:00 AM → Google Drive → Validator Lunes 5:30 AM
- **Recovery docs:** `RECOVERY.md`, `BOOTSTRAP.md`

## 🔐 Cambios Críticos de Seguridad
**REGLA: SIEMPRE avisar a Manu ANTES de cambios en SSH/firewall/port-forward/Fail2Ban**

**Protocolo A+B:**
1. **Backup automático** (verificar Drive OK)
2. **Health baseline** — `bash canary-test.sh start`
3. **Cambio controlado** — en una sesión SSH
4. **Validación automática** — `canary-test.sh test && validate`
5. **Rollback if needed** — `canary-test.sh rollback`

**Documentación:**
- `scripts/critical-change-checklist.md` — Checklist + Canary
- `memory/security-change-protocol.md` — Protocolo A+B detallado
- `scripts/canary-test.sh` — Script principal

## 🔒 Postura de Seguridad (Auditoría 2026-02-23)
- **Estado:** 🟢 BUENO (82% postura)
- **Controles OK:** UFW firewall, SSH key-only, root disabled, Fail2Ban activo
- **Issues:** PAM modules missing (pam_tally2.so) → instalar `libpam-cracklib`
- **Puertos:** 22/SSH (local+VNC), 25/SMTP (revisar si necesario)
- **SSH:** X11Forwarding=yes → desabilitar si no se usa

## ✅ Notion Ideas - Captura Automática
**Política (2026-02-20):** En reportes/análisis, detectar tareas → añadir a Notion Ideas automáticamente
- **Qué:** Tarea, beneficios, cuándo, complejidad, cómo, riesgos, recomendación
- **Aplica:** Informes seguridad, performance, logs, GitHub issues
- **No duplicar:** Verificar siempre contra Ideas existentes
- **Cleanup:** Lunes 7:00 AM (marcar como Hecho, documentar cuándo)

## 📋 Notion Configuration
- **Workspace:** Lola OpenClaw's Space (lolaopenclaw@gmail.com)
- **Tablero:** "Tablero de Tareas" (DB ID: `30c676c3-86c8-81ac-b2bd-cd2d8a5516f7`)
- **API:** Notion-Version 2022-06-28 (IMPORTANTE: no 2025-09-03)
- **Flujo:** Ideas → Pendiente → En progreso → Hecho → Archivado (>7 días)

## 🚨 Reinicios y Mantenimiento
**REGLA: Avisar ANTES de reiniciar (qué, por qué, duración estimada)**
- En caso urgente: reiniciar, luego reportar
- BOOT.md maneja post-boot reporting automático
- Nota archivo en `memory/CHANGES/` antes de cambios críticos
