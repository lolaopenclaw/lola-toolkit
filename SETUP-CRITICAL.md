# 🔧 SETUP-CRITICAL.md — Guía post-restauración completa

Qué hacer DESPUÉS de ejecutar `setup-critical-restore.sh`.

---

## Resumen: Qué se restaura automáticamente

✅ **Automático (setup-critical-restore.sh hace todo):**
- Workspace files (MEMORY.md, scripts, memory/)
- Git hooks (post-commit backup)
- OpenClaw service (systemd)
- Dependencias del sistema (verifica + avisa)
- Permisos de archivos
- Servicios de usuario (dbus)

❌ **MANUAL (necesita intervención):**
- API Keys (Anthropic, Notion)
- GOG credentials (si no está en keyring)
- Google Drive OAuth (si expiró)
- Algunas configuraciones específicas del usuario

---

## Paso 1: Ejecutar setup-critical-restore.sh

```bash
bash ~/.openclaw/workspace/scripts/setup-critical-restore.sh ~/openclaw-backup-YYYY-MM-DD.tar.gz
```

Esto hace automáticamente:
- ✅ Extrae backup
- ✅ Instala git hooks
- ✅ Instala OpenClaw service
- ✅ Verifica dependencias
- ✅ Corrige permisos
- ✅ Reinicia servicios
- ❌ No restaura API keys (seguridad)

---

## Paso 2: Restaurar API Keys (si necesario)

### 2a. ANTHROPIC_API_KEY

**Ubicación:** `~/.openclaw/.env`

**Verificar si funciona:**
```bash
cat ~/.openclaw/.env | grep ANTHROPIC_API_KEY
```

**Si está vacío o mal:**

1. Ve a https://console.anthropic.com
2. Login con tu cuenta
3. Copia tu API key
4. Edita `~/.openclaw/.env`:
   ```bash
   nano ~/.openclaw/.env
   ```
5. Busca/reemplaza:
   ```
   ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxx
   ```
6. Guarda (Ctrl+O, Enter, Ctrl+X)

**Test:**
```bash
source ~/.openclaw/.env
curl https://api.anthropic.com/v1/messages -H "x-api-key: $ANTHROPIC_API_KEY" 2>&1 | head -5
```

### 2b. NOTION_API_KEY

**Ubicación:** `~/.openclaw/.env`

**Verificar si funciona:**
```bash
cat ~/.openclaw/.env | grep NOTION_API_KEY
```

**Si está vacío o mal:**

1. Ve a https://www.notion.so/my-integrations
2. Login con lolaopenclaw@gmail.com
3. Selecciona integración "Lola OpenClaw"
4. Copia el "Internal Integration Token"
5. Edita `~/.openclaw/.env`:
   ```bash
   nano ~/.openclaw/.env
   ```
6. Reemplaza:
   ```
   NOTION_API_KEY=secret_xxxxxxxxxxxxx
   ```
7. Guarda

**Test:**
```bash
curl -s -X GET "https://api.notion.com/v1/users/me" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28"
```

### 2c. GOG (Google Workspace) Credentials

**Si GOG no funciona tras restaurar:**

```bash
# Opción 1: Si tienes el keyring backup
mkdir -p ~/.local/share/keyrings
cp ~/backups/keyrings/* ~/.local/share/keyrings/

# Opción 2: Reauth desde cero
gog auth add lolaopenclaw@gmail.com --services gmail,calendar,drive,contacts,docs,sheets
# Te abrirá navegador para OAuth
```

**Si falla:** Necesitas el `client_secret.json` del proyecto Google Cloud:
```bash
# Contactar a Manu o ver: console.cloud.google.com → optimal-courage-486312-c8
gog auth credentials ~/Downloads/client_secret.json
```

**Test:**
```bash
gog gmail search "is:unread" --max 1
```

### 2d. Google Drive (Rclone)

**Si Rclone no funciona:**

```bash
# Opción 1: Si tienes config backup
mkdir -p ~/.config/rclone
cp ~/backups/rclone.conf ~/.config/rclone/

# Opción 2: Reauth desde cero
rclone config
# → Nombre: grive_lola
# → Type: drive
# → Scope: full access
# → OAuth flow interactivo
```

**Test:**
```bash
rclone lsd grive_lola:
```

---

## Paso 3: Verificar servicios críticos

```bash
# OpenClaw gateway
openclaw gateway status

# Si está down:
openclaw gateway start

# Verificar todo
openclaw doctor

# Cron jobs
cron list | head -5

# SSH keys (para VPS)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""  # si falta
ssh-copy-id mleon@tu-vps-ip  # si falta

# Git
git config --global user.name "Lola"
git config --global user.email "lolaopenclaw@gmail.com"
```

---

## Paso 4: Verificar memory y backups

```bash
# Que MEMORY.md esté restaurado
cat ~/.openclaw/workspace/MEMORY.md | head -20

# Que CHANGELOG.md esté íntegro
cat ~/.openclaw/workspace/CHANGELOG.md | tail -10

# Que backups por commit funcionen (test)
cd ~/.openclaw/workspace
git log -1 --oneline  # Deberías ver últimos commits

# Que git hook funciona (test)
# Haz un commit dummy
echo "test" > /tmp/test.txt
git add /tmp/test.txt
git commit -m "🧪 Test de git hook"
# Deberías ver: "🔄 Commit importante detectado"
git reset HEAD~1 && rm /tmp/test.txt  # Revertir
```

---

## Paso 5: Verificar datos externos

```bash
# Notion database accesible
curl -s -X GET "https://api.notion.com/v1/databases/30c676c3-86c8-81ac-b2bd-cd2d8a5516f7" \
  -H "Authorization: Bearer $NOTION_API_KEY" \
  -H "Notion-Version: 2022-06-28" | jq '.title'

# Google Drive accesible
rclone ls grive_lola:openclaw_backups | head -3

# Garmin API (si lo usas)
bash ~/.openclaw/workspace/scripts/garmin-health-report.sh --current

# Gmail accesible
gog gmail search "is:unread" --max 1
```

---

## Paso 6: Ejecutar informe post-restauración

```bash
# Informe completo
bash ~/.openclaw/workspace/scripts/usage-report.sh
bash ~/.openclaw/workspace/scripts/backup-memory.sh
openclaw doctor
```

---

## 🚨 Checklist post-restauración

- [ ] `setup-critical-restore.sh` ejecutado exitosamente
- [ ] ANTHROPIC_API_KEY validado
- [ ] NOTION_API_KEY validado
- [ ] GOG credenciales funcionales (o reauth hecho)
- [ ] Rclone accede a Google Drive
- [ ] OpenClaw gateway corriendo
- [ ] Cron jobs visibles: `cron list`
- [ ] Git hooks funcionales (test commit dummy)
- [ ] Notion database accesible
- [ ] Memory + CHANGELOG íntegros
- [ ] Garmin API funcional (si aplica)
- [ ] Gmail accesible
- [ ] `openclaw doctor` pasa todas las verificaciones

---

## Troubleshooting

### "API key inválida"
- Verifica que NO hay espacios extras
- Verifica que es la versión correcta (no una key antigua)
- Intenta regenerar la key en la consola del proveedor

### "OpenClaw gateway no arranca"
```bash
openclaw gateway install
openclaw gateway start
journalctl --user -u openclaw-gateway -n 20
```

### "Git hooks no funcionan"
```bash
cat ~/.openclaw/workspace/.git/hooks/post-commit
chmod +x ~/.openclaw/workspace/.git/hooks/post-commit
bash ~/.openclaw/workspace/scripts/setup-git-hooks.sh
```

### "Permisos rotos"
```bash
sudo chown -R mleon:mleon ~/.openclaw
sudo chmod 700 ~/.openclaw
```

### "Cron jobs no aparecen"
Deberían restaurarse automáticamente. Si no:
```bash
cron list
# Si están vacíos, contactar a Manu para recrearlos
```

---

## ¿Algo más falló?

1. Verifica RECOVERY.md para contexto
2. Lee `openclaw doctor` output completo
3. Revisa logs: `journalctl --user -u openclaw-gateway -n 50`
4. Contactar a Manu con los logs

---

**Última actualización:** 2026-02-22
**Versión:** 1.0 (Completa)
**Decisión:** Manu, 2026-02-22 08:17
