# TOOLS.md

Environment-specific config: cameras, SSH hosts, TTS prefs, speakers, device names.

---

## 🔧 Scripts Custom (~/workspace/scripts/)

### Arneses & Monitoring
- **api-health-checker.py** — Health + failover (Anthropic→Google)
- **rate-limit-monitor.py** — 6 APIs monitor
- **rate-limit-status** — ASCII dashboard
- **config-drift** — Drift detector
- **subagents-dashboard** — TUI dashboard
- **subagent-validator.py** — Output validator
- **validate-subagent-output** — Validator wrapper
- **gateway-health-check.sh** — Gateway health
- **pre-restart-validator.sh** — Pre-flight
- **security-scanner.py** — Security scan
- **runtime-governance.sh** — Loop/caps/limits
- **emergency-cost-stop.sh** — Emergency stop

### Garmin & Health
- **garmin-health-report.sh** — Daily report
- **garmin-activities-to-sheets.py** — ⚠️ DEPRECATED
- **garmin-activities-historical.py** — Historical export
- **garmin-json-export.sh** — JSON export
- **health-alerts.sh** — Metric alerts

### Finanzas
- **sheets-populate-v2.py** — ⚠️ DEPRECATED

### GitHub
- **pr-reviewer.sh** — Auto-review
- **monitor-github-24586-robust.sh** — Issue monitor

### Surf
- **surf-conditions.sh** — Zarautz/Mundaka

### Backups & Validation
- **backup-validator.sh**, **post-commit-backup.sh**, **restore.sh**, **verify.sh**

### Autoresearch
- **autoimprove-trigger.sh**, **track-autoresearch.sh**

### System
- **apt-security-check.sh**, **bootstrap.sh**, **usage-report.sh**, **calendar-tasks.sh**, **dashboard-api-server.js**

### TTS & Audio
- **google-tts.sh** — Google TTS
- **tts-venv/** — edge-tts, gtts-cli

### OpenSpec
- **openspec-helpers.sh** — TypeScript spec CLI

### Knowledge Base
- **ingest.sh**, **search.sh**, **embed.py**, **semantic-search.py**
- Doc: `memory/knowledge-base.md` | DB: `data/knowledge-base.db` (132 chunks)

### API Cost Tracking
- **usage-report.sh** — Session log cost aggregation
- **cost-alert.sh** — Thresholds: >$10 warn, >$25 critical
- Doc: `memory/api-cost-tracking.md`

### Notification Batching
- **notification-batcher.sh** — Priority queue (critical|high|medium|low)
- Queue: `data/notification-queue.jsonl`
- Doc: `memory/notification-batching.md` | Status: ✅|⏳cron

### Performance Tracking
- **performance-tracker.sh**, **performance-alert.sh**
- Metrics: latency (p50/p90/p99), by model, degradation
- Doc: `memory/performance-tracking.md`

### Session Log Rotation
- **session-log-rotation.sh** — Compress >7d, delete >30d
- Doc: `memory/session-log-rotation.md` | Status: ✅

**Ver lista completa:** `ls -1 scripts/` (30+ scripts)

---

## 🎯 Skills Locales (~/workspace/skills/)

### System Harnesses
- **api-health**, **rate-limit**, **config-drift**, **cron-validator**, **subagent-validator**

### Autoresearch
- **autoimprove** — Nightly loop (Karpathy)
- **proactive-agent** — Hal Stack, WAL

### Security & Ops
- **clawdbot-security-check**, **openclaw-checkpoint**, **verification-before-completion**

### Content & Media
- **video-frames**, **youtube-smart-transcript**, **truthcheck**

### Music & Home
- **sonoscli**

### GitHub
- **pr-review**

**Global skills:** `openclaw skills list` (40+)

---

## 📐 OpenSpec

Config: `openspec.config.ts` | Specs: `specs/` | Helper: `openspec-helpers.sh` | Doc: `memory/openspec-integration.md`

---

## 🔐 Accesos

### Google (gog)
- lolaopenclaw@gmail.com
- Env: GOG_KEYRING_BACKEND=file, GOG_KEYRING_PASSWORD, GOG_ACCOUNT
- ~/.openclaw/.env + ~/.bashrc

### Garmin
- Instinct 2S Solar Surf | OAuth: Manu_Lazarus | Doc: memory/garmin-integration.md

### GitHub
- lolaopenclaw | Repo: lola-toolkit | Policy: code ✅ | secrets ❌

### Finanzas
- github.com/lolaopenclaw/finanzas-personal (privado) | Markdown | Cada 15d | Sheets DEPRECATED

---

## 🌐 Infra

- **SSH:** Laptop ✅ (work hours) | VPS: lola-openclaw-vps.taild8eaf6.ts.net
- **Ports:** 18790 (Gateway), 8080 (UI), 3333 (Canvas), 5001 (API)
- **TTS:** Google 1.25x | scripts/tts-venv/ | Driving auto-reset 22:00
- **Telegram:** 6884477 | Quiet 00:00-07:00 | Reactions: MINIMAL

## 📅 Crons

Backup 4:00 | Reindex 4:30 | Security Lun 9:00 | Autoimprove 2:00 | API Health 30min/2h/daily | Rate Limit hourly

`openclaw cron list`
