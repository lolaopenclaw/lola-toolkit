# BOOTSTRAP.md — Primera vez en VPS nueva

## Guía rápida de recuperación (para Manu)

**Tiempo total estimado: 20-30 minutos**

---

### Paso 0: Prerequisitos ✋

1. VPS con Ubuntu 24.04 LTS
2. Usuario `mleon` creado
3. SSH keys copiadas: `ssh-copy-id mleon@<IP>`
4. Backup descargado de Google Drive (carpeta `openclaw_backups`)

---

### Paso 1: Bootstrap automático (~10 min)

```bash
# Subir bootstrap.sh a la VPS (desde backup o desde aquí)
scp scripts/bootstrap.sh mleon@<IP>:~/

# Conectar y ejecutar
ssh mleon@<IP>
bash bootstrap.sh
```

Esto instala TODO: sistema, Chrome, Node, OpenClaw, Homebrew, seguridad.

---

### Paso 2: Restaurar backup (~2 min)

```bash
# Subir el backup
scp openclaw-backup-YYYY-MM-DD.tar.gz mleon@<IP>:~/

# En la VPS:
bash ~/.openclaw/workspace/scripts/restore.sh ~/openclaw-backup-*.tar.gz
```

Si restore.sh aún no existe (porque el workspace estaba vacío):
```bash
tar xzf ~/openclaw-backup-*.tar.gz
bash openclaw-backup-*/restore.sh ~/openclaw-backup-*.tar.gz
```

---

### Paso 3: Config manual (~10 min) ⚠️

**3a. API key de Anthropic:**
```bash
# Si la del backup sigue siendo válida, ya está.
# Si no: console.anthropic.com → API Keys → nueva key
# Editar: nano ~/.openclaw/.env (o a través de openclaw config)
```

**3b. Rclone (para backups):**
```bash
# Si el backup incluyó rclone.conf:
mkdir -p ~/.config/rclone
cp ~/openclaw-backup-*/rclone.conf ~/.config/rclone/
rclone lsd grive_lola:  # Verificar

# Si no funciona, reconfigurar:
rclone config
# → Nombre: grive_lola → Type: drive → Scope: drive → OAuth flow
```

**3c. GOG (Gmail/Drive):**
```bash
# Si el backup incluyó gog-config/ y keyrings/:
mkdir -p ~/.config/gog ~/.local/share/keyrings
cp ~/openclaw-backup-*/gog-config/* ~/.config/gog/
cp ~/openclaw-backup-*/keyrings/* ~/.local/share/keyrings/
gog auth list  # Verificar

# Si no funciona:
gog auth credentials ~/.config/gog/credentials.json
gog auth add lolaopenclaw@gmail.com --services gmail,calendar,drive,contacts,docs,sheets
```

---

### Paso 4: Arrancar (~2 min)

```bash
openclaw gateway install
openclaw gateway start
openclaw hooks enable boot-md
openclaw doctor
```

---

### Paso 5: Verificar (~1 min)

```bash
bash ~/.openclaw/workspace/scripts/verify.sh
```

Si todo verde → ¡Listo! 🎉

---

### Troubleshooting

**"Gateway no arranca":**
```bash
journalctl --user -u openclaw-gateway --no-pager -n 20
sudo loginctl enable-linger mleon
openclaw gateway install
openclaw gateway start
```

**"Chrome no funciona":**
```bash
google-chrome --version  # ¿Instalado?
cat /usr/local/bin/chrome-shim  # ¿Shim correcto?
/usr/local/bin/chrome-shim --dump-dom https://example.com  # Test
```

**"GOG no autentica":**
```bash
# Las credenciales OAuth expiran. Necesitas:
# 1. El client_secret.json del proyecto Google Cloud (optimal-courage-486312-c8)
# 2. Ir a console.cloud.google.com → Credentials → descargar JSON
# 3. gog auth credentials <JSON>
# 4. gog auth add lolaopenclaw@gmail.com --services gmail,calendar,drive,contacts,docs,sheets
```

**"Cron jobs no aparecen":**
```bash
# Si cron-db se restauró correctamente, deberían estar.
# Si no, pedirle a Lola que los recree:
# "Recrea los cron jobs desde cron-jobs.json"
```

---

### Orden de operaciones (resumen visual)

```
VPS nueva (Ubuntu 24.04)
    │
    ├─→ bootstrap.sh ─────────── Sistema + OpenClaw + Seguridad
    │
    ├─→ Subir backup ─────────── Descargar de Drive
    │
    ├─→ restore.sh ───────────── Workspace + Config + Secrets + Crons
    │
    ├─→ Config manual ─────────── API keys + rclone + GOG
    │   (solo si tokens expiraron)
    │
    ├─→ openclaw gateway start ── Arrancar
    │
    └─→ verify.sh ────────────── Confirmar todo OK ✅
```

---

*Este archivo existe para la primera vez. Una vez que Lola arranque y se reconozca, puede borrarlo según AGENTS.md.*
