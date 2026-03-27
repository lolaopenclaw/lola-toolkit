# TOOLS.md

Environment-specific config: cameras, SSH hosts, TTS prefs, speakers, device names.

---

## 🔧 Scripts Custom (~/workspace/scripts/)

### High-Frequency (Top 15)
- **api-health-checker.py** — Health + failover (Anthropic→Google)
- **rate-limit-monitor.py** / **rate-limit-status** — 6 APIs monitor + dashboard
- **subagents-dashboard** — TUI dashboard
- **security-scanner.py** — Security scan
- **garmin-health-report.sh** — Daily report
- **surf-conditions.sh** — Zarautz/Mundaka
- **backup-validator.sh** / **restore.sh** — Backup validation
- **usage-report.sh** / **cost-alert.sh** — API cost tracking
- **notification-batcher.sh** — Priority queue (critical|high|medium|low)
- **performance-tracker.sh** — Latency metrics (p50/p90/p99)
- **google-tts.sh** — Google TTS (scripts/tts-venv/)

### By Category (40+ scripts)
- **Monitoring** (8): config-drift, gateway-health-check, pre-restart-validator, runtime-governance, etc.
- **Garmin/Health** (5): activities export, alerts, historical data
- **GitHub** (2): pr-reviewer, issue monitor
- **Backups** (4): post-commit, verify, validator
- **Knowledge Base** (4): ingest, search, embed, semantic-search → `memory/knowledge-base.md`
- **System** (6): apt-security-check, bootstrap, usage-report, calendar-tasks
- **Autoresearch** (2): autoimprove-trigger, track-autoresearch

**Full list:** `ls -1 scripts/` | **Docs:** See script headers or `memory/technical.md`

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

## 🔐 Access & Infrastructure

**Full details:** `memory/access-credentials.md`

**Quick reference:**
- **Google:** lolaopenclaw@gmail.com
- **GitHub:** lolaopenclaw | Policy: code ✅ secrets ❌
- **Garmin:** Instinct 2S Solar Surf (OAuth: Manu_Lazarus)
- **SSH:** Laptop (work hours) | VPS: lola-openclaw-vps.taild8eaf6.ts.net
- **Telegram:** 6884477 | Group: -1003768820594

## 📅 Crons

**Full schedule:** `memory/technical.md` | **Live status:** `openclaw cron list`
