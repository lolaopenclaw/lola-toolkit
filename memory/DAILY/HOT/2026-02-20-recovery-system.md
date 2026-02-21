# Sistema de Recuperación — Diseño e Implementación

**Fecha:** 2026-02-20  
**Estado:** Implementado y verificado

## Análisis

### Qué se puede automatizar completamente
1. ✅ Actualización del sistema operativo
2. ✅ Instalación de paquetes (apt, brew, npm)
3. ✅ Google Chrome + chrome-shim
4. ✅ Node.js (NVM) + OpenClaw (versión fija)
5. ✅ SSH hardening (PermitRootLogin, PasswordAuth, TcpForwarding)
6. ✅ Firewall UFW (deny incoming, allow outgoing, SSH)
7. ✅ Fail2ban (jail.local)
8. ✅ Core dumps deshabilitados
9. ✅ libpam-tmpdir
10. ✅ rkhunter + lynis
11. ✅ Unattended-upgrades
12. ✅ Sudoers config
13. ✅ Linger para systemd
14. ✅ Estructura de directorios
15. ✅ Variables de entorno
16. ✅ Restauración de workspace desde backup
17. ✅ Restauración de openclaw.json, .env, cron-db
18. ✅ Crontab del sistema (rclone sync)
19. ✅ Verificación post-recovery

### Qué requiere intervención manual
1. ⚠️ **API key de Anthropic** — Si la del backup expiró, hay que generar nueva
2. ⚠️ **OpenClaw onboard** — Wizard interactivo (primera vez)
3. ⚠️ **Rclone OAuth** — Si el refresh token expiró, requiere browser
4. ⚠️ **GOG OAuth** — Si los tokens expiraron, requiere browser
5. ⚠️ **SSH keys** — El usuario debe copiar sus keys a la VPS nueva
6. ⚠️ **Telegram bot token** — Si se necesita nuevo bot

### Lo que se preserva del backup (automático)
- Tokens de Rclone (refresh_token) → suelen durar meses
- GOG OAuth tokens + keyring → si no expiraron, funcionan
- API keys (Anthropic, ElevenLabs, Groq) → si no se revocaron
- Telegram bot token → no expira
- Toda la config de OpenClaw
- Todos los cron jobs
- Todo el workspace (identidad, memoria, scripts, skills)

### Puntos críticos de fallo
1. **Backup corrupto o ausente** → Sin backup, hay que reconfigurar todo manualmente
2. **API keys revocadas** → Requiere generar nuevas (Anthropic, GOG OAuth)
3. **Homebrew tarda mucho** → La primera instalación puede llevar 5-10 min
4. **Chrome no instala en ARM** → Los scripts asumen x86_64
5. **Versión de OpenClaw pinned** → Si la 2026.2.17 deja de estar en npm, actualizar el script

### Orden de ejecución
```
1. bootstrap.sh   → Instala todo el software y aplica seguridad
2. restore.sh     → Restaura workspace, config, secrets, crons
3. (manual)       → Verificar/actualizar API keys y OAuth tokens
4. (manual)       → openclaw gateway install && start
5. verify.sh      → Confirmar que todo funciona
```

## Arquitectura de Scripts

### scripts/bootstrap.sh (14.6KB)
- **Función:** Llevar VPS vacía a estado preparado
- **12 pasos:** apt update, packages, Chrome, brew, Node/OpenClaw, sudoers, hardening, linger, dirs, env, crontab, resumen
- **Idempotente:** Cada paso detecta si ya se ejecutó
- **Tiempo:** ~10-15 min (primera vez), ~1 min (re-ejecución)

### scripts/restore.sh (8KB)
- **Función:** Restaurar desde backup tarball
- **7 pasos:** extraer, backup seguridad, openclaw.json, .env, cron-db, workspace, limpieza
- **Idempotente:** Hace backup de seguridad antes de sobreescribir
- **Tiempo:** ~1-2 min

### scripts/hardening.sh (7.6KB)
- **Función:** Aplicar todos los hardenings de seguridad
- **7 checks:** SSH, UFW, fail2ban, core dumps, libpam-tmpdir, rkhunter, lynis
- **Idempotente:** Detecta qué ya está aplicado
- **Nota:** Ya incluido en bootstrap.sh, pero útil como script independiente

### scripts/verify.sh (9.3KB)
- **Función:** Verificar estado post-recovery
- **47 checks:** sistema, seguridad, software, config, workspace, crons, conectividad
- **Solo lectura:** No modifica nada

### scripts/backup-memory.sh (5KB)
- **Función:** Backup diario a Google Drive
- **Incluye:** workspace, openclaw.json, .env, cron-db, GOG config, keyrings, rclone.conf, system snapshot
- **Mejora:** Ahora incluye GOG config, keyrings y rclone.conf (antes no se incluían)

## Estructura del Backup

```
openclaw-backup-YYYY-MM-DD/
├── openclaw.json          # Config OpenClaw completa
├── dot-env                # API keys y credenciales
├── cron-db/               # Base de datos de cron jobs
│   ├── jobs.json
│   └── runs/
├── gog-config/            # OAuth credentials GOG  [NUEVO]
│   ├── credentials.json
│   └── keyring/
├── keyrings/              # Keyring file-based      [NUEVO]
│   ├── Default_keyring.keyring
│   └── default
├── rclone.conf            # Config rclone           [NUEVO]
├── system-snapshot/       # Referencia de sistema    [NUEVO]
│   ├── sshd_config.txt
│   ├── ufw-status.txt
│   ├── limits.conf.txt
│   ├── security-packages.txt
│   ├── crontab.txt
│   ├── openclaw-version.txt
│   └── node-version.txt
├── restore.sh             # Script de restauración
├── SOUL.md
├── USER.md
├── AGENTS.md
├── IDENTITY.md
├── TOOLS.md
├── HEARTBEAT.md
├── MEMORY.md
├── RECOVERY.md
├── BOOT.md
├── cron-jobs.json
├── memory/
│   ├── YYYY-MM-DD.md
│   ├── preferences.md
│   └── ...
├── scripts/
│   ├── backup-memory.sh
│   ├── bootstrap.sh
│   ├── restore.sh
│   ├── hardening.sh
│   ├── verify.sh
│   └── usage-report.sh
└── skills/
    └── sonoscli/
```

## Verificación

Script verify.sh ejecutado en sistema actual: **47 pass, 0 fail, 0 warnings**

## Plan de Implementación

### Hecho ahora ✅
- [x] bootstrap.sh creado y probado
- [x] restore.sh mejorado (GOG, keyrings, rclone)
- [x] hardening.sh creado (independiente de bootstrap)
- [x] verify.sh creado y probado (47/47 checks pasan)
- [x] backup-memory.sh mejorado (incluye GOG config, keyrings, rclone.conf, system snapshot)
- [x] RECOVERY.md reescrito completamente
- [x] BOOTSTRAP.md creado

### Para próxima sesión
- [ ] Forzar backup manual para incluir nuevos archivos: `bash scripts/backup-memory.sh`
- [ ] Considerar snapshot de VPS para testing (si el proveedor lo permite)
- [ ] Actualizar MEMORY.md con referencia al sistema de recovery
- [ ] Considerar subir bootstrap.sh a un gist público (sin secrets) para acceso fácil

### Mantenimiento continuo
- Si cambia la versión de OpenClaw → actualizar OPENCLAW_VERSION en bootstrap.sh
- Si se añaden nuevas herramientas → añadir a bootstrap.sh
- Si cambian configs de seguridad → actualizar hardening.sh
- El backup diario ya incluye todos los scripts actualizados
