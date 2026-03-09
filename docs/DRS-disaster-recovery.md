# 🔴 DRS — Disaster Recovery Strategy

**Última actualización:** 2026-03-09
**Proveedor Cloud:** IONOS Cloud
**RPO:** 24 horas (backup diario a las 4 AM)
**RTO:** 20-30 minutos (con backup disponible)

---

## 📋 Arquitectura de Backup Actual

### Capas de Protección

```
┌─────────────────────────────────────────────────────────┐
│  CAPA 1: Backup Custom (584K — diario 4AM)              │
│  ├── Workspace (SOUL, MEMORY, scripts, skills)          │
│  ├── Config (openclaw.json, .env)                       │
│  ├── Secrets (GPG keys, Pass store)                     │
│  ├── Cron DB (jobs.json)                                │
│  ├── GOG credentials (OAuth tokens)                     │
│  ├── Rclone config                                      │
│  ├── System snapshot (SSH, UFW, Fail2ban)               │
│  └── restore.sh (incluido en cada backup)               │
├─────────────────────────────────────────────────────────┤
│  CAPA 2: Backup Nativo OpenClaw (redundancia)           │
│  ├── openclaw backup create --no-include-workspace      │
│  ├── Incluye: config, auth, cron, sessions              │
│  ├── Verificado con manifest nativo                     │
│  └── Subido a Drive junto con Capa 1                    │
├─────────────────────────────────────────────────────────┤
│  CAPA 3: Git (workspace versionado)                     │
│  └── ~/.openclaw/workspace → git commits                │
├─────────────────────────────────────────────────────────┤
│  DESTINO: Google Drive (grive_lola:openclaw_backups/)   │
│  Validación: Semanal (backup-validator.sh)              │
│  Retención: 30 días (cleanup cron lunes 5:30 AM)       │
└─────────────────────────────────────────────────────────┘
```

### Crons de Backup

| Cron | Hora | Función |
|------|------|---------|
| Backup diario | 4:00 AM | Custom + nativo → Drive |
| Backup validation | Lunes 5:30 AM | Verificar integridad |
| Backup retention | Lunes 5:30 AM | Limpiar >30 días |

---

## 🚀 Procedimiento de Recovery

### Escenario 1: VPS Corrupta (mismo proveedor)
**RTO: 20 minutos**

```bash
# 1. Crear VPS nueva en IONOS (ver sección IONOS abajo)
# 2. Conectar por SSH
ssh mleon@<NUEVA_IP>

# 3. Descargar bootstrap.sh (desde backup o URL)
# Opción A: Si tienes acceso al backup
scp openclaw-backup-YYYY-MM-DD.tar.gz mleon@<NUEVA_IP>:~/

# Opción B: Si no tienes el backup local, bootstrap intentará descargarlo

# 4. Ejecutar bootstrap (incluye auto-restore)
bash bootstrap.sh [/path/to/backup.tar.gz]

# 5. Config manual (solo si tokens expiraron)
# Ver sección "Config Manual Post-Restore"

# 6. Arrancar OpenClaw
openclaw gateway install
openclaw gateway start
openclaw doctor

# 7. Verificar
bash ~/.openclaw/workspace/scripts/verify.sh
```

### Escenario 2: Migración a Otro Proveedor
**RTO: 30-45 minutos**

Mismo que Escenario 1, pero:
1. Crear VPS en el nuevo proveedor (Ubuntu 24.04 LTS)
2. Copiar SSH keys
3. Ejecutar bootstrap.sh
4. Actualizar DNS/Tailscale si aplica

### Escenario 3: Recovery Parcial (solo config)
**RTO: 5 minutos**

```bash
# Si solo necesitas restaurar config sin reinstalar
openclaw backup verify ~/backup.tar.gz   # Verificar integridad
tar xzf ~/backup.tar.gz                 # Extraer
bash restore.sh ~/backup.tar.gz         # Restaurar config
openclaw gateway restart                 # Aplicar
```

---

## 🏢 IONOS Cloud — Guía de Infraestructura

### Datos Actuales

- **Proveedor:** IONOS Cloud (ionos.es)
- **Tipo:** VPS (Virtual Private Server)
- **SO:** Ubuntu 24.04 LTS
- **Ubicación:** Europa (Alemania/España según disponibilidad)
- **Usuario:** mleon
- **Acceso:** SSH con keys (no password)

### Crear VPS Nueva en IONOS

#### Paso 1: Acceder al Panel
1. Login en https://my.ionos.es/ (o https://dcd.ionos.com/)
2. Ir a "Servidores & Cloud" → "Cloud Panel"

#### Paso 2: Crear Servidor
1. Click "Crear servidor" → "VPS Linux"
2. **Configuración recomendada:**
   - **SO:** Ubuntu 24.04 LTS
   - **RAM:** Mínimo 4GB (recomendado 8GB para OpenClaw)
   - **CPU:** 2+ vCPUs
   - **Disco:** 40GB+ SSD (actualmente usamos ~15%)
   - **Ubicación:** Misma región que el actual (latencia Tailscale)
3. **SSH Key:** Subir la clave pública de Manu
4. **Nombre:** `lola-openclaw-vps` (o similar)
5. Confirmar y crear

#### Paso 3: Primer Acceso
```bash
# Obtener IP del panel de IONOS
ssh root@<NUEVA_IP>

# Crear usuario mleon
adduser mleon
usermod -aG sudo mleon

# Copiar SSH keys
mkdir -p /home/mleon/.ssh
cp ~/.ssh/authorized_keys /home/mleon/.ssh/
chown -R mleon:mleon /home/mleon/.ssh
chmod 700 /home/mleon/.ssh
chmod 600 /home/mleon/.ssh/authorized_keys

# Salir y reconectar como mleon
exit
ssh mleon@<NUEVA_IP>
```

#### Paso 4: Bootstrap
```bash
# Subir bootstrap.sh y backup
scp scripts/bootstrap.sh mleon@<NUEVA_IP>:~/
scp openclaw-backup-YYYY-MM-DD.tar.gz mleon@<NUEVA_IP>:~/

# Ejecutar
bash bootstrap.sh ~/openclaw-backup-*.tar.gz
```

#### Paso 5: Tailscale
```bash
# Instalar Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Autenticar con URL que aparece
# Esto restaura el acceso remoto vía Tailscale
```

### IONOS — Consideraciones

| Aspecto | Detalle |
|---------|---------|
| **Facturación** | Mensual, se puede escalar |
| **Snapshots** | IONOS ofrece snapshots de servidor (complementario) |
| **Firewall** | Tenemos UFW + IONOS tiene firewall externo |
| **Backups IONOS** | Opcional (pagado) — nosotros usamos Drive |
| **API** | IONOS tiene API REST (para automatizar en futuro) |
| **CLI** | `ionosctl` existe pero no lo usamos aún |

### IONOS API (para futuro IaaS)
```bash
# Si algún día queremos automatizar la creación de VPS:
pip install ionoscloud
# O usar ionosctl CLI
# Documentación: https://docs.ionos.com/cloud/managed-services/api
```

---

## 🔐 Config Manual Post-Restore

Estos pasos solo son necesarios si los tokens han expirado:

### 1. API Key Anthropic
```bash
# Si la del backup sigue válida → nada que hacer
# Si expiró → console.anthropic.com → API Keys → nueva key
nano ~/.openclaw/.env  # Actualizar ANTHROPIC_API_KEY
```

### 2. Rclone (Google Drive)
```bash
# Si el backup incluyó rclone.conf → verificar:
rclone lsd grive_lola:  # ¿Funciona?

# Si no → reconfigurar:
rclone config
# Nombre: grive_lola → Type: drive → Scope: drive → OAuth flow
```

### 3. GOG (Gmail/Drive CLI)
```bash
# Si OAuth tokens expiraron:
gog auth credentials ~/.config/gog/credentials.json
gog auth add lolaopenclaw@gmail.com --services gmail,calendar,drive,contacts,docs,sheets
```

### 4. GPG + Pass
```bash
# Si GPG key no se restauró:
gpg --list-keys  # ¿Aparece Lola OpenClaw?
pass ls           # ¿Funciona?

# Si no → regenerar:
gpg --batch --gen-key /tmp/gpg-params
pass init "lolaopenclaw@gmail.com"
```

### 5. Tailscale
```bash
sudo tailscale up  # Re-autenticar si es necesario
```

---

## 📊 Verificación Post-Recovery

```bash
bash ~/.openclaw/workspace/scripts/verify.sh
```

El script verifica:
- [ ] OpenClaw instalado y versión correcta
- [ ] Gateway arranca sin errores
- [ ] Telegram conecta
- [ ] Discord conecta
- [ ] Cron jobs cargados
- [ ] Backup script funciona
- [ ] GOG autentica
- [ ] Rclone conecta a Drive
- [ ] UFW activo
- [ ] Fail2ban corriendo
- [ ] SSH hardened

---

## 📌 Checklist de Mantenimiento

### Semanal
- [ ] Verificar que backups llegan a Drive
- [ ] Verificar retención (>30 días eliminados)
- [ ] Revisar que verify.sh pasa

### Mensual
- [ ] Probar restore en directorio temporal (dry-run)
- [ ] Verificar que bootstrap.sh sigue compatible con Ubuntu actual
- [ ] Actualizar versiones en documentación si hay upgrades

### Trimestral
- [ ] Rotar tokens (gateway, APIs)
- [ ] Verificar que IONOS no ha cambiado su interfaz
- [ ] Test completo de DRS (crear VPS temporal, restaurar, verificar, eliminar)

---

## 🔗 Referencias

- **Scripts:** `~/.openclaw/workspace/scripts/`
  - `backup-memory.sh` — Backup diario
  - `restore.sh` — Restauración
  - `bootstrap.sh` — VPS desde cero
  - `verify.sh` — Verificación post-recovery
  - `backup-validator.sh` — Validación de integridad
- **Guía rápida:** `BOOTSTRAP.md` (en workspace)
- **IONOS Panel:** https://my.ionos.es/
- **IONOS API Docs:** https://docs.ionos.com/cloud/
- **Tailscale Admin:** https://login.tailscale.com/admin/machines
