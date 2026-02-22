# CHANGELOG — Historia de cambios importantes

Registro automático de commits importantes con backups asociados.
Sistema híbrido: detecta patrones automáticos + soporte para backup manual.

**Patrón detectado automáticamente:**
- Emojis: 🎯 📋 🔐 🤐 💾 📚 🛠️ ⚙️ 🔧 📢 🗺️ 📖 ✅ 🚀 🔄 💡 🧠 ⚡
- Palabras clave: Implementar, Consolidar, Política, Crítico, Error, Seguridad, Decisión, Arquitectura, Fix, Nueva política, etc.

**Formato:**
`timestamp | mensaje | hash | backup`

---

## Febrero 2026

### 2026-02-22

#### 127e282 — Consolidar comunicación
- **Timestamp:** 2026-02-22 08:09 (aproximado)
- **Commit:** 📋 Consolidar comunicación: un único informe matutino
- **Cambios:** 
  - Todos los reportes parciales integrados en dos informes matutino
  - Lunes-viernes 9 AM + Sábado-domingo 10 AM
  - Cero notificaciones rutinarias
  - Excepciones críticas solo
  - Desactivados 10+ crons de reportes parciales
- **Archivo:** COMMUNICATION-POLICY.md

#### 391951f — Política de horario silencioso
- **Timestamp:** 2026-02-22 07:57 (aproximado)
- **Commit:** 🤐 Implementar política de horario silencioso (00:00-07:00 Madrid)
- **Cambios:**
  - SILENT-HOURS-POLICY.md creado
  - `memory/pending-reports/` para almacenamiento nocturno
  - Cron 8:55 AM para entrega de reportes pendientes
  - HEARTBEAT.md actualizado
  - Backup automático post-commit implementado
- **Archivo:** SILENT-HOURS-POLICY.md

---

## Sistema de backups por commit

**Carpeta:** `backups-by-commit/`
**Nombre:** `backup-{hash-commit}-{timestamp}.tar.gz`
**Trigger:** Detecta commits importantes automáticamente

**Backup manual:**
```bash
bash ~/.openclaw/workspace/scripts/backup-memory.sh
```

Este CHANGELOG se actualiza automáticamente con cada commit importante.
- **2026-02-22 08:12:23** | 💾 Implementar sistema de backup automático post-commit + CHANGELOG | `edb8c88` | [`backup-edb8c88`](backups-by-commit/backup-edb8c88*.tar.gz)

- **2026-02-22 08:15:54** | 📖 Documentar recuperación post-fallo crítico + setup-git-hooks | `717aa3c` | [`backup-717aa3c`](backups-by-commit/backup-717aa3c*.tar.gz)

- **2026-02-22 08:18:26** | 🆘 Automatización COMPLETA de restauración post-fallo crítico | `348e024` | [`backup-348e024`](backups-by-commit/backup-348e024*.tar.gz)

- **2026-02-22 08:26:35** | 📚 Preparar 2 propuestas OpenClaw en paralelo: Critical Update + Memory Guardian | `0f12cdc` | [`backup-0f12cdc`](backups-by-commit/backup-0f12cdc*.tar.gz)

- **2026-02-22 09:02:36** | 🧠 Corregir Garmin Health Report: mostrar datos de AYER en informe matutino | `7e072aa` | [`backup-7e072aa`](backups-by-commit/backup-7e072aa*.tar.gz)

