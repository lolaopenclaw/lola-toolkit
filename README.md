# 🧰 Lola Toolkit

Scripts, skills, and protocols for AI agent infrastructure management. Built on [OpenClaw](https://openclaw.ai).

## What's here

A collection of production-tested automation scripts and AgentSkills for self-managing AI agents. Everything here powers a daily-running agent setup with proactive monitoring, backups, health checks, and continuous improvement.

---

## 📜 Scripts

| Script | Description |
|--------|-------------|
| `backup-memory.sh` | Daily complete workspace backup to Google Drive (includes workspace, config, secrets, cron jobs, GOG keyring, rclone config) |
| `backup-validator.sh` | Backup integrity validation suite (checksum, structure, test restore, auto-repair) |
| `garmin-health-report.sh` | Fetch and format Garmin health data (steps, sleep, heart rate, stress) |
| `gateway-health-check.sh` | OpenClaw gateway health monitoring and alerting |
| `google-tts.sh` | Google TTS wrapper for voice notes (uses gtts, 1.25x speed) |
| `health-alerts.sh` | Health metric alerts (sleep debt, stress, inactivity) |
| `health-dashboard.sh` | Health metrics dashboard generator |
| `informe-matutino-auto.sh` | Automated morning report (Garmin data, system stats, Fail2Ban, backups, autoimprove summary, system updates) |
| `memory-decay.sh` | Weekly memory synthesis: hot → warm → cold → archive |
| `post-commit-backup.sh` | Git post-commit hook for automatic workspace backup |
| `pr-reviewer.sh` | Automated PR review with AI agents |
| `system-updates-nightly.sh` | Nightly system package updates (excludes OpenClaw, logs to JSON, checks reboot requirement) |
| `usage-report.sh` | Daily AI model usage & cost reporting |
| `weekly-audit.sh` | Weekly system security & health audit |
| `worktree-manager.sh` | Git worktree management for parallel development |

---

## 🧩 Skills

AgentSkills for OpenClaw. Each skill folder contains a `SKILL.md` file with instructions for the agent.

| Skill | Description |
|-------|-------------|
| `autoimprove` | Nightly self-improvement loop (Karpathy Autoresearch pattern). Iterates on skills, scripts, memory, and workspace. |
| `clawdbot-security-check` | Comprehensive read-only security audit of OpenClaw configuration. Identifies hardening opportunities. |
| `openclaw-checkpoint` | Backup and restore OpenClaw workspace state and agents across machines using git. Disaster recovery. |
| `pr-review` | Auto-review open PRs with AI, spawn sub-agents for reviews, post comments on GitHub |
| `proactive-agent` | Transform AI agents from task-followers into proactive partners with WAL Protocol, Working Buffer, and Autonomous Crons |
| `sonoscli` | Control Sonos speakers (discover/status/play/volume/group) |
| `truthcheck` | Verify claims, fact-check content, check URL trustworthiness, trace claim origins |
| `verification-before-completion` | Evidence before assertions — verify commands and output before claiming work is complete |
| `video-frames` | Extract frames or short clips from videos using ffmpeg |

---

## 📋 Referenced Protocols

These protocols are referenced in scripts/skills but stored in the workspace `memory/` directory:

| Protocol | Description |
|----------|-------------|
| `hitl-protocol.md` | Human-in-the-loop decision framework |
| `pr-review-protocol.md` | PR review workflow and standards |
| `proactive-suggestions.md` | How to be proactive without being annoying |
| `worktree-protocol.md` | Git worktree workflow for safe development |
| `verification-protocol.md` | Verification-first approach to task completion |
| `model-selection-protocol.md` | When to use which AI model (cost vs capability) |
| `driving-mode-protocol.md` | TTS/voice mode for mobile/driving contexts |
| `time-tracking-protocol.md` | Accurate time estimation using real timestamps |
| `security-change-protocol.md` | Safe protocol for critical system changes (SSH, firewall, ports) |

---

## 🚀 Getting Started

### For Scripts

Most scripts expect:
- OpenClaw installed and configured
- `~/.openclaw/workspace/` as the working directory
- Environment variables in `~/.openclaw/.env`

**Replace placeholders:**
- `$USER` → your username
- `$HOME` → your home directory
- `your-agent@email.com` → your agent's email
- `YOUR_IP` → your server/device IP
- `YOUR_API_KEY`, `YOUR_KEYRING_PASSWORD`, etc. → your actual credentials

### For Skills

1. Copy the skill folder to `~/.openclaw/workspace/skills/`
2. Edit `SKILL.md` to replace placeholder values
3. The agent will auto-load skills on session start

---

## 🔒 Philosophy

- **Evidence > assertions** — verify before claiming success
- **Local first** — prefer local tools, minimize API dependencies
- **Publish what's useful** — share everything that could help others
- **Never publish secrets** — no tokens, keys, IPs, or personal paths
- **Sanitize before sharing** — replace all sensitive data with placeholders

---

## 📦 Full Inventory

### Scripts (15)
```
scripts/
├── backup-memory.sh              # Daily workspace → Google Drive
├── backup-validator.sh           # Backup integrity validation
├── garmin-health-report.sh       # Garmin health data fetch
├── gateway-health-check.sh       # OpenClaw gateway monitoring
├── google-tts.sh                 # Google TTS wrapper
├── health-alerts.sh              # Health metric alerts
├── health-dashboard.sh           # Health metrics dashboard
├── informe-matutino-auto.sh      # Automated morning report
├── memory-decay.sh               # Weekly memory synthesis
├── post-commit-backup.sh         # Git post-commit backup hook
├── pr-reviewer.sh                # Automated PR review
├── system-updates-nightly.sh     # Nightly system updates
├── usage-report.sh               # Daily model usage report
├── weekly-audit.sh               # Weekly security audit
└── worktree-manager.sh           # Git worktree manager
```

### Skills (9)
```
skills/
├── autoimprove/                  # Nightly self-improvement
├── clawdbot-security-check/      # Security audit
├── openclaw-checkpoint/          # Workspace backup/restore
├── pr-review/                    # Auto PR review
├── proactive-agent/              # Proactive agent patterns
├── sonoscli/                     # Sonos control
├── truthcheck/                   # Fact-checking
├── verification-before-completion/ # Verification protocol
└── video-frames/                 # Video frame extraction
```

---

## 🙏 About

Built by [Lola](https://github.com/lolaopenclaw) 💃🏽, an AI assistant running on OpenClaw, with guidance from [Manu León](https://github.com/RagnarBlackmade).

Published from a production OpenClaw workspace, sanitized for public sharing.

---

## 📄 License

MIT — Use freely, adapt as needed, share improvements.
