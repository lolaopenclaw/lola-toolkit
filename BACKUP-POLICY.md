# 💾 Política de Backups — Decisión Manu 2026-02-22

## Sistema híbrido: automático + manual

### 1. Backup diario automático (4:00 AM)
- **Cuándo:** Todos los días a las 4:00 AM Madrid
- **Qué:** Workspace completo (MEMORY.md, scripts, config, crons, secrets)
- **Dónde:** Google Drive (`openclaw_backups/`)
- **Nombre:** `openclaw-backup-YYYY-MM-DD.tar.gz`
- **Retención:** Máximo 30 días (rotación automática)

### 2. Backup automático post-commit (NUEVO)
- **Cuándo:** Automáticamente tras cada **commit importante**
- **Qué:** Snapshot del workspace en ese momento
- **Dónde:** Carpeta local `backups-by-commit/` + Google Drive
- **Nombre:** `backup-{hash-commit}-{timestamp}.tar.gz`
- **Detecta como "importante":**
  - Emojis: 🎯 📋 🔐 🤐 💾 📚 🛠️ ⚙️ 🔧 📢 🗺️ 📖 ✅ 🚀 🔄 💡 🧠 ⚡
  - Palabras: Implementar, Consolidar, Política, Crítico, Error, Seguridad, Decisión, Arquitectura, Fix

**Ejemplos detectados automáticamente:**
```
🎯 Implementar X
📋 Consolidar comunicación
🔐 Política de seguridad
🤐 Política de horario silencioso
💾 Backup automático post-commit
🚀 Nueva característica importante
```

### 3. Backup manual (on-demand)
- **Cuándo:** Cuando Manu lo pida
- **Comando:** `bash ~/.openclaw/workspace/scripts/backup-memory.sh`
- **Dónde:** Google Drive + local
- **Uso:** Cambios críticos sin emoji/patrón automático detectado

## CHANGELOG automático

**Archivo:** `CHANGELOG.md`

Se actualiza automáticamente con cada commit importante:
- Timestamp
- Mensaje del commit
- Hash del commit
- Link al backup asociado

**Manual:** Editable si necesitas documentar más contexto

## Recuperación

**Desde backup diario:**
```bash
bash ~/.openclaw/workspace/scripts/restore.sh ~/openclaw-backup-YYYY-MM-DD.tar.gz
```

**Desde backup por commit:**
```bash
bash ~/.openclaw/workspace/scripts/restore.sh ~/backups-by-commit/backup-{hash}.tar.gz
```

## Beneficios

✅ **Cambios importantes nunca se pierden**
✅ **Historial trazable** (CHANGELOG + commits)
✅ **Recuperación granular** (por fecha o por cambio específico)
✅ **Automático** (sin intervención manual, salvo lo importante)
✅ **Documentado** (cada backup tiene contexto)

## Próximos pasos (opcionales)

- [ ] Script de lista de backups: `list-backups.sh`
- [ ] Script de comparación: `diff-backups.sh backup1.tar.gz backup2.tar.gz`
- [ ] Alertas si backup falla
