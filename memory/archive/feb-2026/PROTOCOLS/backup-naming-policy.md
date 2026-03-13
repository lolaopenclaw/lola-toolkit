# 📝 Backup Naming Policy — 2026-02-21

**Objetivo:** Diferenciar backups automáticos de manuales  
**Implementación:** Convención de nombres en Drive

---

## Nomenclatura

### Backups Automáticos (Diarios)

**Formato:** `openclaw-backup-YYYY-MM-DD.tar.gz`

Ejecutados por cron:
- **Hora:** 4:00 AM Madrid (diariamente)
- **Contenido:** TODO (workspace, config, secrets, cron-db, GOG, rclone)
- **Ubicación:** `grive_lola:openclaw_backups/`

**Ejemplo:**
- `openclaw-backup-2026-02-21.tar.gz` → Backup automático del 21 feb

---

### Backups Manuales (Puntuales)

**Formato:** `manual-openclaw-backup-YYYY-MM-DD[-N].tar.gz`

Ejecutados bajo demanda (Manu pide: "haz un backup"):
- **Hora:** Cualquier momento (ejecutado manualmente)
- **Contenido:** TODO (igual que automáticos)
- **Ubicación:** `grive_lola:openclaw_backups/`
- **Sufijo:** Si hay múltiples en el mismo día, agregar `-1`, `-2`, etc.

**Ejemplos:**
- `manual-openclaw-backup-2026-02-21.tar.gz` → Manual del 21 feb (primera)
- `manual-openclaw-backup-2026-02-21-1.tar.gz` → Segunda manual del 21 feb
- `manual-openclaw-backup-2026-02-21-2.tar.gz` → Tercera manual del 21 feb

---

## Cómo Ejecutar Manual Backup

### Comando
```bash
bash ~/.openclaw/workspace/scripts/backup-memory.sh --manual
```

(Script debe actualizarse para aceptar flag `--manual`)

### Manual Actual (sin flag)
```bash
# Ejecuta backup normal
bash ~/.openclaw/workspace/scripts/backup-memory.sh

# Luego renombrar en Drive
rclone copy \
  "grive_lola:openclaw_backups/openclaw-backup-YYYY-MM-DD.tar.gz" \
  "grive_lola:openclaw_backups/manual-openclaw-backup-YYYY-MM-DD.tar.gz"
```

---

## Beneficios

✅ **Claridad:** De un vistazo sé si es automático o manual  
✅ **Tracking:** Puedo ver cuándo fue solicitado manualmente  
✅ **Recuperación:** Fácil encontrar backup "antes del cambio X"

---

## Política de Retención

Ambos tipos se rigen por **"Últimos 30 días"**:
- Backups automáticos: 30 días máximo
- Backups manuales: 30 días máximo
- **Excepción:** Manu puede pedir conservar uno más tiempo (comunicar)

---

## Futuro: Mejorar Script

**TODO:** Actualizar `backup-memory.sh` para aceptar:
```bash
# Automático (sin args, por cron)
bash backup-memory.sh

# Manual (ejecutado por demanda)
bash backup-memory.sh --manual
```

Script cambiaría nombre de salida automáticamente.

---

**Implementación:** 2026-02-21  
**Primer backup manual:** 2026-02-21 11:30 (ejecutado por Manu)
