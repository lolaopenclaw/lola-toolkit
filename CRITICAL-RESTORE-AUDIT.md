# 🔍 CRITICAL-RESTORE-AUDIT — Qué falta para restauración COMPLETA

Auditoría de qué se necesita restaurar en caso de fallo crítico (COMPLETO).

---

## ✅ YA DOCUMENTADO

- [x] Workspace files (MEMORY.md, scripts, etc.) → restore.sh
- [x] Git hooks (post-commit) → setup-git-hooks.sh
- [x] OpenClaw config → incluido en backup
- [x] Cron jobs → incluido en backup
- [x] Secrets basadas en archivo (rclone.conf, gog-config) → incluido en backup

---

## ❌ FALTA: Sistema y servicios

### 1. OpenClaw Gateway Service (systemd)
**Problema:** Si OpenClaw se instala como systemd service, no viene en el backup
**Ubicación:** `/etc/systemd/user/` o `/etc/systemd/system/`
**Solución:**
```bash
openclaw gateway install  # reinstala el service
```
**Documentar:** En setup script

### 2. Node.js Global Packages
**Problema:** `npm install -g openclaw` puede no estar si falla la máquina
**Solución:**
```bash
npm install -g openclaw@latest
```
**Documentar:** En setup script

### 3. Dependencias del sistema
**Críticas:**
- `python3` (para Whisper, Lynis, etc.)
- `lynis` (security audit)
- `rkhunter` (malware scan)
- `fail2ban` (firewall)
- `google-chrome` (browser)
- `git` (para OpenClaw)

**Documentar:** Script de verificación

### 4. API Keys / Credenciales que NO están en el backup

**API Keys CRÍTICAS (no están en tarball por seguridad):**
- `ANTHROPIC_API_KEY` → en `~/.openclaw/.env`
- `NOTION_API_KEY` → en `~/.openclaw/.env`
- `GOG_KEYRING_PASSWORD` → variable de entorno
- Google Drive API creds → necesita reauth

**Solución:** Documentar dónde obtenerlas + cómo reconfigurar

### 5. Permisos de archivos
**Problema:** Si restauras como otro usuario, permisos pueden romperse
**Solución:**
```bash
sudo chown -R mleon:mleon ~/.openclaw
chmod 700 ~/.openclaw
chmod 600 ~/.openclaw/.env
```

### 6. Secrets en keyring (GOG)
**Problema:** Las credenciales de GOG pueden estar en `~/.local/share/keyrings/`
**Ubicación:** `~/.local/share/keyrings/` (puede no estar en backup)
**Solución:** GOG reauth si no se restauró

### 7. Configuración de VNC (si lo usa Manu)
**Archivos:**
- `~/.vnc/xstartup`
- `~/.vnc/passwd`
**Solución:** Incluir en backup o documentar reconfiguración

### 8. D-Bus / sesión de usuario
**Problema:** D-Bus puede estar corrupto post-crash
**Solución:**
```bash
systemctl --user restart dbus
```

---

## 📋 Plan de acción

Crear tres cosas:

### 1. `setup-critical-restore.sh` (NUEVO)
Script master que ejecuta TODOS los pasos:
```bash
bash setup-critical-restore.sh
```

Qué hace:
- Restaura workspace (restore.sh)
- Reinstala git hooks (setup-git-hooks.sh)
- Instala OpenClaw service (openclaw gateway install)
- Instala dependencias del sistema
- Verifica API keys + guía reconfig
- Verifica permisos
- Reinicia servicios críticos
- Ejecuta verify.sh

### 2. `SETUP-CRITICAL.md` (NUEVO)
Documentación completa de:
- Qué se restaura automáticamente
- Qué NECESITA reconfiguración manual
- Dónde obtener cada API key
- Cómo reconfig GOG, Notion, etc.
- Checklist final

### 3. Actualizar `RECOVERY.md`
- Referenciar SETUP-CRITICAL.md
- Usar setup-critical-restore.sh en lugar de pasos individuales

---

## 📊 Matriz de cobertura

| Componente | Automático? | En Backup? | Requiere Reauth? | Doc? |
|-----------|-----------|-----------|-----------------|------|
| Workspace | ✅ (restore.sh) | ✅ | ❌ | ✅ |
| Git hooks | ✅ (setup-git-hooks.sh) | ❌ | ❌ | ✅ |
| Crons | ✅ | ✅ | ❌ | ✅ |
| OpenClaw service | ❌ | ❌ | ❌ | ❌ FALTA |
| Node.js packages | ❌ | ❌ | ❌ | ❌ FALTA |
| System deps | ❌ | ❌ | ❌ | ❌ FALTA |
| ANTHROPIC_API_KEY | ❌ | ❌ | ✅ | ❌ FALTA |
| NOTION_API_KEY | ❌ | ❌ | ✅ | ❌ FALTA |
| GOG credentials | ❌ | ❌ | ✅ | ❌ FALTA |
| Permisos | ❌ | ❌ | ❌ | ❌ FALTA |
| VNC config | ❌ | ❓ | ❌ | ❌ FALTA |
| D-Bus | ❌ | ❌ | ❌ | ❌ FALTA |

---

**Recomendación:** Implementar `setup-critical-restore.sh` + `SETUP-CRITICAL.md`
