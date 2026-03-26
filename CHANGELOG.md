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

- **2026-02-22 09:03:34** | 🧠 Refinar Garmin Health Report: actividad de AYER + sueño de HOY | `db6718f` | [`backup-db6718f`](backups-by-commit/backup-db6718f*.tar.gz)

- **2026-02-22 12:02:45** | 🎯 Discord fino — informes completos con embeds | `83e5a54` | [`backup-83e5a54`](backups-by-commit/backup-83e5a54*.tar.gz)

- **2026-02-22 12:14:48** | 🎯 Resolver GOG/tokens + automatizar compartir Drive folders | `1bda599` | [`backup-1bda599`](backups-by-commit/backup-1bda599*.tar.gz)

- **2026-02-24 13:47:54** | 🔐 Security hardening: PAM modules fixed, X11Forwarding disabled | `20c4c93` | [`backup-20c4c93`](backups-by-commit/backup-20c4c93*.tar.gz)

- **2026-02-24 14:14:00** | 🚀 Auto-recovery system: Crash detection + snapshot recovery + Drive fallback | `c345508` | [`backup-c345508`](backups-by-commit/backup-c345508*.tar.gz)

- **2026-02-25 15:25:43** | fix: backup validator checksum mismatch on same-day re-runs | `13f76ec` | [`backup-13f76ec`](backups-by-commit/backup-13f76ec*.tar.gz)

- **2026-02-26 11:21:22** | Fix: Reescritura de 2 crons con error (fin de semana + memory review) - timeout y delivery issues | `983a870` | [`backup-983a870`](backups-by-commit/backup-983a870*.tar.gz)

- **2026-02-27 17:12:51** | fix: informe matutino @ 10 AM daily, populate sheets daily | `bd6e037` | [`backup-bd6e037`](backups-by-commit/backup-bd6e037*.tar.gz)

- **2026-03-06 21:10:55** | memory: document duplicate gateway fix + lobsterboard proxy fix (2026-03-06 evening) | `4dc53b9` | [`backup-4dc53b9`](backups-by-commit/backup-4dc53b9*.tar.gz)

- **2026-03-06 22:05:54** | cleanup: remove 5 obsolete crons, fix relay token, proxy LobsterBoard APIs | `1d69d7d` | [`backup-1d69d7d`](backups-by-commit/backup-1d69d7d*.tar.gz)

- **2026-03-09 10:24:26** | 🔧 Fix Failing Crons: Robust Versions Created (2026-03-09) | `c670da6` | [`backup-c670da6`](backups-by-commit/backup-c670da6*.tar.gz)

- **2026-03-09 10:28:11** | 📋 Session Summary: OpenClaw v2026.3.8 Testing + Cron Fixes (2026-03-09) | `4b32521` | [`backup-4b32521`](backups-by-commit/backup-4b32521*.tar.gz)

- **2026-03-09 10:31:46** | 📋 Política GitHub Issues: NO monitoreo pasivo (2026-03-09 10:31) | `fd351ed` | [`backup-fd351ed`](backups-by-commit/backup-fd351ed*.tar.gz)

- **2026-03-09 10:34:33** | 📋 Cron Verification Checklist: Próximo Lunes 2026-03-10 (2026-03-09 10:34) | `f0797b0` | [`backup-f0797b0`](backups-by-commit/backup-f0797b0*.tar.gz)

- **2026-03-20 02:02:24** | autoimprove: improve post-commit-backup.sh error handling + dependency checks | `de1ada3` | [`backup-de1ada3`](backups-by-commit/backup-de1ada3*.tar.gz)

- **2026-03-20 10:53:28** | fix: memory reindex cron delivery channel (telegram explicit + best-effort) | `a1a451a` | [`backup-a1a451a`](backups-by-commit/backup-a1a451a*.tar.gz)

- **2026-03-20 11:43:52** | fix: correct coach names (Rafa=técnica, Jorge=físico) | `3298cf5` | [`backup-3298cf5`](backups-by-commit/backup-3298cf5*.tar.gz)

- **2026-03-21 10:13:41** | fix: add token usage to morning report + proactive notifications preference | `0b85007` | [`backup-0b85007`](backups-by-commit/backup-0b85007*.tar.gz)

- **2026-03-22 02:01:17** | autoimprove: harden generate-morning-report.sh — set -euo pipefail, dep checks, fix encoding | `7e1ffe7` | [`backup-7e1ffe7`](backups-by-commit/backup-7e1ffe7*.tar.gz)

- **2026-03-22 09:15:20** | fix: cron delivery + autoimprove reporting instructions | `d7dd7ab` | [`backup-d7dd7ab`](backups-by-commit/backup-d7dd7ab*.tar.gz)

- **2026-03-22 11:27:20** | feat: Gemini embeddings migration complete (714 chunks, 0 errors) | `46dfc96` | [`backup-46dfc96`](backups-by-commit/backup-46dfc96*.tar.gz)

- **2026-03-22 12:16:11** | chore: Sunday morning session - embeddings migration, cron fixes, cleanup | `1bee17f` | [`backup-1bee17f`](backups-by-commit/backup-1bee17f*.tar.gz)

- **2026-03-22 13:01:51** | fix: TTS voice AbrilNeural→ElviraNeural, install edge-tts CLI, nocturnal systems review pref | `5c6eae5` | [`backup-5c6eae5`](backups-by-commit/backup-5c6eae5*.tar.gz)

- **2026-03-22 13:13:49** | fix: 25 cron jobs remediados - best-effort-deliver + telegram channel + to 6884477 | `8994a1e` | [`backup-8994a1e`](backups-by-commit/backup-8994a1e*.tar.gz)

- **2026-03-26 13:46:49** | fix: token usage in morning report now shows real costs | `b258592` | [`backup-b258592`](backups-by-commit/backup-b258592*.tar.gz)

- **2026-03-26 15:50:26** | fix: session-log-rotation subshell variable bug | `b3207c3` | [`backup-b3207c3`](backups-by-commit/backup-b3207c3*.tar.gz)

- **2026-03-26 15:55:04** | fix: session-log-rotation counters + archive garmin duplicate | `7947b52` | [`backup-7947b52`](backups-by-commit/backup-7947b52*.tar.gz)

- **2026-03-26 15:56:53** | fix: backup strategy — honest RTOs, OAuth alert, remove DB from git | `4d61fed` | [`backup-4d61fed`](backups-by-commit/backup-4d61fed*.tar.gz)

- **2026-03-26 16:10:25** | fix: healthcheck — counter bugs, visible failures | `6b676ca` | [`backup-6b676ca`](backups-by-commit/backup-6b676ca*.tar.gz)

