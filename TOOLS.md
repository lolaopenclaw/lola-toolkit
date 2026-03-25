# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

---

## 🔧 Scripts Custom (~/workspace/scripts/)

### Arneses & Monitoring
- **api-health-checker.py** — Health checks + failover automático (Anthropic→Google)
- **rate-limit-monitor.py** — Monitor de rate limits (6 APIs)
- **rate-limit-status** — Dashboard ASCII de rate limits
- **config-drift** — Detector de drift en configuración
- **subagents-dashboard** — TUI dashboard de subagentes (tiempo real)
- **subagent-validator.py** — Validador de outputs de subagentes
- **validate-subagent-output** — Wrapper del validador
- **gateway-health-check.sh** — Health check del gateway
- **pre-restart-validator.sh** — Pre-flight antes de restart
- **security-scanner.py** — Scanner de seguridad

### Garmin & Health
- **garmin-health-report.sh** — Reporte diario de salud
- **garmin-activities-to-sheets.py** — Sync Garmin → Google Sheets ⚠️ DEPRECADO (migrado a Markdown)
- **garmin-activities-historical.py** — Exportación histórica
- **garmin-json-export.sh** — Exportación a JSON
- **health-alerts.sh** — Alertas de métricas de salud

### Finanzas
- **sheets-populate-v2.py** — Actualización de finanzas en Sheets ⚠️ DEPRECADO (migrado a Markdown)

### GitHub
- **pr-reviewer.sh** — Auto-review de PRs
- **monitor-github-24586-robust.sh** — Monitor de issue específico

### Surf
- **surf-conditions.sh** — Condiciones de surf Zarautz/Mundaka

### Backups & Validation
- **backup-validator.sh** — Validador de backups
- **post-commit-backup.sh** — Backup post-commit
- **restore.sh** — Restore de backups
- **verify.sh** — Verificación general

### Autoresearch
- **autoimprove-trigger.sh** — Trigger de autoimprove
- **track-autoresearch.sh** — Tracking de autoresearch

### System
- **apt-security-check.sh** — Security check de paquetes
- **bootstrap.sh** — Bootstrap del sistema
- **usage-report.sh** — Reporte de uso
- **calendar-tasks.sh** — Tareas de calendario
- **dashboard-api-server.js** — API server para dashboards

### TTS & Audio
- **google-tts.sh** — TTS con Google
- **tts-venv/** — Venv de Python para TTS (edge-tts, gtts-cli)

### OpenSpec
- **openspec-helpers.sh** — CLI para validar/listar/crear specs TypeScript

### Knowledge Base
- **knowledge-base-ingest.sh** — Ingest content (articles, YouTube, PDFs) into SQLite knowledge base
- **knowledge-base-search.sh** — Full-text search with FTS5 (supports --list and --tag filters)
- **Docs:** `memory/knowledge-base.md`
- **Database:** `data/knowledge-base.db`

### API Cost Tracking
- **usage-report.sh** — Aggregate API costs from session logs
- **cost-alert.sh** — Alert on high daily spend (>$10 warn, >$25 critical)
- **Docs:** `memory/api-cost-tracking.md`
- **Usage:**
  - `bash scripts/usage-report.sh --today --by-model` → Today's costs by model
  - `bash scripts/usage-report.sh --week` → Last 7 days
  - `bash scripts/cost-alert.sh` → Check thresholds, exit 1 if critical
- **Session logs:** `~/.openclaw/agents/main/sessions/*.jsonl`

**Ver lista completa:** `ls -1 scripts/` (30+ scripts)

---

## 🎯 Skills Locales (~/workspace/skills/)

### Arneses de Sistema
- **api-health** — Pre-flight checks de APIs
- **rate-limit** — Monitor de rate limits
- **config-drift** — Detector de drift
- **cron-validator** — Validador de cron jobs
- **subagent-validator** — Validador de outputs de subagentes

### Autoresearch & Mejora
- **autoimprove** — Karpathy autoresearch loop (nightly)
- **proactive-agent** — Hal Stack, WAL protocol, autonomous crons

### Security & Ops
- **clawdbot-security-check** — Self-audit de seguridad
- **openclaw-checkpoint** — Backup/restore de workspace
- **verification-before-completion** — Verificación pre-completar tasks

### Content & Media
- **video-frames** — Extracción de frames de vídeo (ffmpeg)
- **youtube-smart-transcript** — Transcripción inteligente de YouTube
- **truthcheck** — Fact-checking y verificación de claims

### Music & Home
- **sonoscli** — Control de Sonos

### GitHub
- **pr-review** — Auto-review de PRs

**Skills globales npm:** `openclaw skills list` (38+ más: 1password, blogwatcher, blucli, camsnap, clawhub, coding-agent, eightctl, gemini, gh-issues, gifgrep, github, gog, healthcheck, himalaya, mcporter, nano-pdf, node-connect, obsidian, openai-whisper, openhue, oracle, ordercli, sag, session-logs, skill-creator, songsee, spotify-player, tmux, wacli, weather)

---

## 📐 OpenSpec

- **Config:** `openspec.config.ts`
- **Specs:** `specs/` (TypeScript)
- **Helper:** `bash scripts/openspec-helpers.sh [validate|list|add]`
- **Docs:** `memory/openspec-integration.md`
- **Purpose:** Spec-Driven Development para scripts/skills (práctica para el curro)

---

## 🔐 Accesos & Cuentas

### Google Workspace (gog)
- **Account:** lolaopenclaw@gmail.com
- **Services:** Gmail, Calendar, Drive, Contacts, Docs, Sheets
- **Env vars:** GOG_KEYRING_BACKEND=file, GOG_KEYRING_PASSWORD, GOG_ACCOUNT
- **Set in:** ~/.openclaw/.env y ~/.bashrc

### Garmin
- **Device:** Instinct 2S Solar Surf
- **OAuth:** Manu_Lazarus
- **Integration:** memory/garmin-integration.md

### GitHub
- **Main:** lolaopenclaw
- **Public repo:** lola-toolkit (scripts/skills/protocols)
- **Policy:** código ✅ | secrets/keys/IPs ❌

### Finanzas
- **Repo:** github.com/lolaopenclaw/finanzas-personal (privado)
- **Formato:** Markdown (migrado desde Google Sheets 2026-03-24)
- **Cadencia:** Cada 15 días (Manu pasa extractos bancarios)
- **Google Sheets:** ❌ DEPRECADO (cron deshabilitado 2026-03-25)

---

## 🌐 Infraestructura

### SSH
- **Laptop:** SSH ✅ (horario de trabajo — ver memory/work-schedule.md)
- **VPS:** lola-openclaw-vps.taild8eaf6.ts.net

### Ports
- **18790:** OpenClaw Gateway
- **8080:** Dashboard / Control UI
- **3333:** Canvas
- **5001:** API

### TTS
- **Provider:** Google TTS (PRIMARY, 1.25x speed)
- **Venv:** scripts/tts-venv/
- **Driving mode:** auto-reset 22:00 (state: memory/driving-mode-state.json)

### Telegram
- **Chat ID:** 6884477
- **Quiet hours:** 00:00-07:00 Madrid
- **Reactions:** MINIMAL (1 cada 5-10 mensajes)

---

## 📅 Crons Importantes

| Task | ID | Schedule | Status |
|------|------|----------|--------|
| Backup | - | 4:00 AM | ✅ |
| Reindex | - | 4:30 AM | ✅ |
| Security Audit | fdf38b8f | Lun 9:00 | ✅ |
| Autoimprove | 08325b21 | 2:00 AM | ✅ |
| API Health | - | 30min/2h/daily | ✅ |
| Rate Limit | - | Hourly | ✅ |

**Ver todos:** `openclaw cron list`

---

Add whatever helps you do your job. This is your cheat sheet.
