# RECOVERY.md — Cómo restaurar a Lola

Si estás leyendo esto, probablemente tuviste que reinstalar OpenClaw o algo fue mal. Este archivo explica cómo volver a ponerme en marcha.

---

## ⏱️ Tiempo estimado: 20-30 minutos

## Escenarios

| Escenario | Qué hacer |
|-----------|-----------|
| VPS nueva (desde cero) | → Sección 0 + 1 + 2 + 3 + 4 + 5 |
| Reinstalar OpenClaw (misma VPS) | → Sección 2 + 3 + 4 + 5 |
| Restaurar workspace (OpenClaw ya funciona) | → Sección 2 + 5 |
| Solo verificar estado | → Sección 5 |

---

## 0. Prerequisitos (VPS nueva)

- Ubuntu 24.04 LTS fresh install
- Usuario `mleon` creado con acceso SSH (key-based)
- SSH keys ya copiadas (`ssh-copy-id mleon@<IP>`)
- Acceso al backup en Google Drive (carpeta `openclaw_backups`)

---

## 1. Bootstrap: De VPS vacía a sistema preparado

```bash
# Opción A: Si tienes el script localmente (desde backup o repo)
scp scripts/bootstrap.sh mleon@<IP>:~/
ssh mleon@<IP> bash bootstrap.sh

# Opción B: Si lo subes manualmente
# Copiar contenido de scripts/bootstrap.sh y ejecutar
```

**¿Qué hace bootstrap.sh?**
- ✅ Actualiza sistema operativo
- ✅ Instala paquetes (seguridad, utilidades, Chrome deps)
- ✅ Instala Google Chrome + chrome-shim
- ✅ Instala Homebrew + herramientas (ripgrep, yt-dlp, gog)
- ✅ Instala Node.js (NVM) + OpenClaw@2026.2.17
- ✅ Configura sudoers
- ✅ Aplica hardening SSH + UFW + fail2ban + core dumps + libpam-tmpdir + rkhunter + lynis
- ✅ Habilita linger (systemd user services)
- ✅ Configura estructura de directorios
- ✅ Configura variables de entorno
- ✅ Configura crontab del sistema (rclone sync)

---

## 2. Restaurar desde backup

### Obtener el backup

```bash
# Opción A: Descargar de Google Drive manualmente
# → drive.google.com → carpeta openclaw_backups → último .tar.gz

# Opción B: Si rclone ya está configurado
rclone copy grive_lola:openclaw_backups/ /tmp/backups/ --include '*.tar.gz' --max-age 3d
ls -la /tmp/backups/

# Opción C: Desde otra máquina con rclone/gog
rclone copy grive_lola:openclaw_backups/ . --include '*2026-02-20*'
scp openclaw-backup-*.tar.gz mleon@<IP>:~/
```

### Ejecutar restore

```bash
bash ~/.openclaw/workspace/scripts/restore.sh ~/openclaw-backup-YYYY-MM-DD.tar.gz
# Si el restore.sh no existe aún, extraer del backup:
tar xzf ~/openclaw-backup-*.tar.gz
bash openclaw-backup-*/restore.sh ~/openclaw-backup-*.tar.gz
```

**¿Qué restaura restore.sh?**
- ✅ `openclaw.json` → configuración completa (modelos, browser, channels, hooks)
- ✅ `.env` → API keys (Anthropic, ElevenLabs, Groq), credenciales GOG
- ✅ Cron jobs database → todos los cron jobs internos de OpenClaw
- ✅ Workspace completo → SOUL.md, MEMORY.md, memory/, scripts/, skills/
- ✅ Hace backup de seguridad del estado actual antes de sobreescribir

---

## 3. Configuración interactiva (⚠️ MANUAL)

Estos pasos **requieren intervención humana** (OAuth flows, API keys):

### 3a. API key de Anthropic
```bash
# Si el .env del backup tiene la key correcta, ya está
# Si necesitas nueva key:
# → console.anthropic.com → API Keys → Crear nueva
# → Añadir a ~/.openclaw/.env como primera línea del config
```

### 3b. OpenClaw onboard (primera vez)
```bash
openclaw onboard
# Seguir wizard interactivo
# Pegar API key de Anthropic cuando pida
```

### 3c. Rclone (backups a Google Drive)
```bash
rclone config
# Nombre: grive_lola
# Tipo: drive
# Scope: drive
# → Sigue el OAuth flow (abrirá URL para autorizar)
```

**Alternativa si hay backup con rclone.conf:**
```bash
# El backup incluye rclone.conf con refresh_token
cp ~/openclaw-backup-*/rclone.conf ~/.config/rclone/rclone.conf
# Verificar: rclone lsd grive_lola:
```

### 3d. GOG (Gmail/Calendar/Drive CLI)
```bash
# Credenciales OAuth (descargar desde Google Cloud Console)
# Proyecto: optimal-courage-486312-c8
gog auth credentials ~/.config/gog/credentials.json
gog auth add lolaopenclaw@gmail.com --services gmail,calendar,drive,contacts,docs,sheets
# → Sigue el OAuth flow
```

**Si hay backup con GOG config:**
```bash
# El backup incluye gog-config/ y keyrings/
mkdir -p ~/.config/gog ~/.local/share/keyrings
cp ~/openclaw-backup-*/gog-config/* ~/.config/gog/ 2>/dev/null || true
cp ~/openclaw-backup-*/keyrings/* ~/.local/share/keyrings/ 2>/dev/null || true
# Verificar: gog auth list
```

---

## 4. Arrancar OpenClaw

```bash
# Instalar servicio systemd
openclaw gateway install
openclaw gateway start

# Habilitar hooks
openclaw hooks enable boot-md

# Verificar
systemctl --user status openclaw-gateway
openclaw doctor --non-interactive
```

### Telegram
- El bot token está en `openclaw.json` → se restaura automáticamente del backup
- Si necesitas nuevo bot: → @BotFather → /newbot → actualizar token en config

### Cron jobs
- Se restauran automáticamente del backup (`cron-db/`)
- Verificar: `openclaw cron list`
- Si faltan, pedirle a Lola que los recree desde `cron-jobs.json`

---

## 5. Verificación final

```bash
# Script automático de verificación
bash ~/.openclaw/workspace/scripts/verify.sh
```

### Checklist manual

**Sistema:**
- [ ] `openclaw --version` → 2026.2.17
- [ ] `systemctl --user status openclaw-gateway` → active (running)
- [ ] `openclaw doctor` → sin errores críticos
- [ ] `loginctl show-user mleon | grep Linger` → Linger=yes

**Seguridad:**
- [ ] `sudo ufw status` → active
- [ ] `sudo fail2ban-client status sshd` → activo
- [ ] `grep PermitRootLogin /etc/ssh/sshd_config` → no
- [ ] `rkhunter --version` → instalado
- [ ] `lynis --version` → instalado

**Conectividad:**
- [ ] `rclone lsd grive_lola:` → lista carpetas
- [ ] `gog auth list` → lolaopenclaw@gmail.com
- [ ] Telegram: enviar mensaje, recibir respuesta
- [ ] `openclaw cron list` → 7 jobs habilitados

**Workspace:**
- [ ] `ls ~/.openclaw/workspace/SOUL.md` → existe
- [ ] `ls ~/.openclaw/workspace/MEMORY.md` → existe
- [ ] `ls ~/.openclaw/workspace/memory/` → archivos diarios

---

## Archivos del backup

| Archivo/Dir | Qué contiene | Sensible |
|------------|-------------|----------|
| `openclaw.json` | Config completa (modelos, browser, channels, gateway token, Telegram bot token) | ⚠️ Sí |
| `dot-env` | API keys (Anthropic, ElevenLabs, Groq), credenciales GOG | 🔴 Sí |
| `cron-db/` | Base de datos interna de cron jobs | No |
| `gog-config/` | OAuth credentials y tokens de GOG | 🔴 Sí |
| `keyrings/` | Keyring file-based (GOG passwords) | 🔴 Sí |
| `rclone.conf` | Config rclone con refresh token de Google Drive | 🔴 Sí |
| `system-snapshot/` | Snapshot de config del sistema (referencia) | No |
| `SOUL.md, USER.md, etc.` | Identidad, personalidad, memoria | No |
| `memory/` | Notas diarias, auditorías, perfil | No |
| `scripts/` | Scripts de backup, restore, hardening, verify | No |
| `skills/` | Skills instaladas (sonoscli) | No |

---

## Secrets y API Keys

| Secret | Ubicación | Cómo obtener nueva |
|--------|-----------|-------------------|
| Anthropic API key | `.env` / `openclaw.json` | console.anthropic.com |
| ElevenLabs API key | `.env` | elevenlabs.io/account |
| Groq API key | `.env` | console.groq.com |
| Telegram bot token | `openclaw.json` | @BotFather |
| GOG OAuth tokens | `~/.config/gog/` | `gog auth add` (requiere browser) |
| Rclone refresh token | `~/.config/rclone/rclone.conf` | `rclone config` (requiere browser) |
| GOG keyring password | `.env` + `.bashrc` | Generar nueva: `openssl rand -base64 32` |
| Gateway token | `openclaw.json` (gateway.auth) | Auto-generado por `openclaw gateway install` |
| Notion API key | Variable de entorno (inyectada por OpenClaw) | notion.so/my-integrations |

---

## Cron jobs activos (referencia)

| Job | Horario | Modelo | Delivery |
|-----|---------|--------|----------|
| Backup diario | 4:00 Madrid | Haiku | none (silencioso) |
| Informe matutino | 9:00 Madrid | Haiku | Telegram → Manu |
| Tareas fondo semanales | 5:00 Madrid (lunes) | Haiku | Telegram → Manu |
| Auditoría seguridad | 5:00 UTC (lunes) | Haiku | last channel |
| Fail2ban alert | Cada 6h | Haiku | last channel |
| Lynis scan | 6:00 UTC (lunes) | Haiku | last channel |
| rkhunter scan | 6:00 UTC (lunes) | Haiku | last channel |

---

## Dependencias del sistema

```bash
# APT packages
ufw fail2ban lynis rkhunter libpam-tmpdir unattended-upgrades
curl wget git build-essential jq htop tmux trash-cli rclone
fonts-liberation libnss3 libatk-bridge2.0-0 libdrm2 libxkbcommon0
libxcomposite1 libxdamage1 libxrandr2 libgbm1 libasound2t64
libpango-1.0-0 libcairo2

# Google Chrome (via apt repo)
google-chrome-stable

# Homebrew packages
ripgrep yt-dlp steipete/tap/gogcli

# npm global
openclaw@2026.2.17

# Shims/wrappers
/usr/local/bin/chrome-shim
```

---

## Contacto
- **Humano:** Manu (Manuel León) — Telegram @RagnarBlackmade
- **Mi email:** lolaopenclaw@gmail.com
- **Google Cloud proyecto:** optimal-courage-486312-c8

---
Si eres mi versión futura: hola 👋 Lee SOUL.md primero, luego USER.md, luego memory/. Todo lo que necesitas saber sobre quién eres y a quién ayudas está ahí.
