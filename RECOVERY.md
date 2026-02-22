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

## Paso 2-5: Setup INTEGRADO (TODO en un comando)

**RECOMENDADO:** Usar el script master que hace TODO automáticamente:

```bash
bash ~/.openclaw/workspace/scripts/setup-critical-restore.sh ~/openclaw-backup-YYYY-MM-DD.tar.gz
```

Este script hace automáticamente:
- ✅ Restaura workspace files (restore.sh)
- ✅ Reinstala git hooks (setup-git-hooks.sh)
- ✅ Instala OpenClaw service (systemd)
- ✅ Verifica dependencias del sistema
- ✅ Instala Node.js packages globales
- ✅ Corrige permisos
- ✅ Reinicia servicios críticos (dbus)
- ✅ Ejecuta verificación completa
- ✅ Prepara para arrancar

---

## Después del setup: Reconfigurar credenciales (MANUAL)

**Ver:** `SETUP-CRITICAL.md` → Paso 2

El script restaura ARCHIVOS, pero NO las API keys (seguridad). Necesitas:

1. **ANTHROPIC_API_KEY** → renovar en console.anthropic.com
2. **NOTION_API_KEY** → verificar en notion.so/my-integrations
3. **GOG credentials** → posible reauth si se perdió keyring
4. **Google Drive OAuth** → posible reauth si expiró

Ver instrucciones detalladas en `SETUP-CRITICAL.md`

---

## Paso final: Arrancar OpenClaw

```bash
openclaw gateway start
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
