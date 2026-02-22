# 🆘 RECOVERY.md — Recuperarse de fallos críticos

Instrucciones para restaurar OpenClaw desde backup en caso de fallo crítico.

---

## Paso 1: Obtener el backup

### Opción A: Backup diario más reciente
```bash
# Descargar de Google Drive (openclaw_backups/)
# Archivo: openclaw-backup-YYYY-MM-DD.tar.gz
ls ~/Downloads/openclaw-backup-*.tar.gz | sort | tail -1
```

### Opción B: Backup por commit específico
```bash
# Descargar de Google Drive (openclaw_backups/)
# Archivo: backup-{hash-commit}-{timestamp}.tar.gz
# Usado cuando necesitas recuperar un cambio específico
```

### Opción C: Backup local (backups-by-commit/)
```bash
ls ~/.openclaw/workspace/backups-by-commit/ | sort | tail -1
```

---

## Paso 2: Restaurar el workspace

```bash
# Extrae todo: config, scripts, memory, crons, secrets
bash ~/.openclaw/workspace/scripts/restore.sh ~/openclaw-backup-YYYY-MM-DD.tar.gz
```

**Qué se restaura:**
- ✅ MEMORY.md y memory/ (historial, notas)
- ✅ Scripts de backup y utilidades
- ✅ Configuración OpenClaw
- ✅ Secrets (rclone, GOG, API keys)
- ✅ Cron jobs
- ✅ Tablero Kanban (Notion settings)
- ✅ CHANGELOG.md (historial)

---

## ⚠️ Paso 3: CRÍTICO — Reinstalar git hooks

**Esto es OBLIGATORIO tras restaurar:**

```bash
bash ~/.openclaw/workspace/scripts/setup-git-hooks.sh
```

**Qué hace:**
- Reinstala el git hook `post-commit`
- Reactiva el sistema automático de backup
- Permite que futuros commits importantes generen backups automáticos

**Si OLVIDAS este paso:**
- El workspace estará restaurado y funcional
- PERO el sistema de backup automático post-commit NO funcionará
- Los commits futuros NO crearán backups automáticos
- Tendrás que hacerlo manualmente: `bash scripts/backup-memory.sh`

---

## Paso 4: Verificar integridad

```bash
# Comprobar que todo está OK
bash ~/.openclaw/workspace/scripts/verify.sh

# Comprobar git hooks
cat ~/.openclaw/workspace/.git/hooks/post-commit
# Deberías ver el script de backup

# Comprobar que el hook funciona
cd ~/.openclaw/workspace && git log -1 --oneline
# Último commit debe ser visible
```

---

## Paso 5: Arrancar OpenClaw

```bash
openclaw gateway status
openclaw gateway start  # si está caído
openclaw doctor
```

---

## Troubleshooting

### "El script `restore.sh` no existe"
Está en el tarball. Tras extraer:
```bash
tar xzf openclaw-backup-YYYY-MM-DD.tar.gz
cd openclaw-backup-YYYY-MM-DD/
bash restore.sh ~/openclaw-backup-YYYY-MM-DD.tar.gz
```

### "Git hooks no funcionan tras restaurar"
Ejecuta:
```bash
bash ~/.openclaw/workspace/scripts/setup-git-hooks.sh
```

### "CHANGELOG.md está vacío"
Es normal si restauraste desde muy atrás. Los commits posteriores la actualizarán automáticamente.

### "Algunos scripts no tienen permisos"
```bash
chmod +x ~/.openclaw/workspace/scripts/*.sh
```

### "Los cron jobs no aparecen"
Deberían restaurarse automáticamente. Si no:
```bash
cron list
# Si faltan, recrearlos manualmente o desde backup anterior
```

---

## Checklist post-recuperación

- [ ] `restore.sh` ejecutado correctamente
- [ ] `setup-git-hooks.sh` ejecutado (⚠️ OBLIGATORIO)
- [ ] `verify.sh` pasa todas las verificaciones
- [ ] `openclaw gateway` está corriendo
- [ ] Git hook funciona: haz un test commit
- [ ] Backups automáticos funcionan (verifica CHANGELOG.md)
- [ ] Todos los secretos/API keys funcionan
- [ ] Cron jobs visibles: `cron list`

---

## Preguntas frecuentes

**P: ¿Pierdo datos si restauro desde backup antiguo?**
R: Sí, los cambios posteriores al backup se pierden. Por eso mantenemos backups diarios + por commit.

**P: ¿Cuándo usar cada backup?**
- Backup diario: recuperación general después de un fallo
- Backup por commit: si necesitas un estado específico (ej: antes de un cambio problemático)

**P: ¿Debo restaurar en la misma máquina?**
R: Idealmente sí. Si cambias de máquina, asegúrate de:
- Copiar archivos privados (SSH keys, etc.)
- Ejecutar `setup-git-hooks.sh`
- Reconfigurar API keys si es necesario

**P: ¿El CHANGELOG.md se restaura?**
R: Sí, pero solo contiene cambios hasta el momento del backup. Los nuevos commits la actualizarán.

---

**Última actualización:** 2026-02-22
**Decisión:** Manu, 2026-02-22 08:15
**Sistema:** Backup diario + automático post-commit + manual on-demand
