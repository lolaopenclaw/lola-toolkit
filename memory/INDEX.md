# 📚 Memory INDEX — Organized Knowledge

Last updated: 2026-03-28 (Consolidation: 108 orphans → archive, MEMORY.md expanded)

---

## 🎯 ACTIVE PROJECTS

### OpenClaw Contributions (IN PROGRESS)
- **Status:** Week 2 — Community engagement (waiting for feedback)
- **Files:**
  - `CONTRIB/ROADMAP.md` — 5-week timeline + checklist
  - `CONTRIB/DISCUSSION-DRAFT.md` — GitHub Discussion template
  - `CONTRIB/DOCS/skill-security-audit.md` — Full PR documentation
- **Discussions LIVE:**
  - Skill Security Audit — https://github.com/openclaw/openclaw/discussions/23394
  - Critical Update Framework
  - Memory Guardian — https://github.com/openclaw/openclaw/discussions/23395

### 🛡️ System Hardening (ONGOING)
- **Sysctl:** ✅ 10/12 params applied + persisted
- **SSH:** ✅ Key-only auth, X11Forwarding disabled (2026-02-24)
- **PAM:** ✅ Deprecated pam_tally2 cleaned (2026-02-24)
- **Fail2Ban:** ✅ Active, monitoring every 6h
- **Files:** `memory/security-change-protocol.md`, `memory/2026-02-24-security-hardening.md`

### 📊 Google Sheets Automation
- **Status:** Working — L-V 9:30 AM auto-populates
- **Sheets:** "Consumo IA" + "Garmin Health" in 📊 Lola Dashboards

### 📊 Health & Monitoring
- **Status:** ✅ Garmin integration + alerts active
- **Crons:** Morning report 9AM, alerts 14:00+20:00, weekly Monday 8:30

### 👨‍👧 Family Tracking
- **Vera Pérez León:** 10 years, birthday August 30 (cron reminder)

---

## 💾 BACKUP STRATEGY

```
Workspace (~768KB markdown)
    ↓
Git commits (continuous)
    ↓
Backup diario a Drive (4:00 AM, rclone)
    ↓
Retención: 30 días en Drive
    ↓
Recuperación: restore.sh
```

**Sin snapshots.** WAL se probó (21-23 feb) y se descartó: overkill para ~1MB de markdown.

---

## 📝 PROTOCOLS & PROCEDURES
- `memory/protocols.md` — Backup, Security, Notion automation rules
- `memory/hitl-protocol.md` — Human-in-the-loop for complex/risky tasks
- `memory/verification-protocol.md` — Evidence-before-assertions discipline
- `memory/driving-mode-state.json` — TTS audio mode state tracking
- `memory/time-tracking-protocol.md` — Real timestamps, no guesses

## 🔧 SCRIPTS (in /scripts)
- `skill-security-audit.sh` — Security audit for ClawHub skills ⭐
- `health-dashboard.sh` — Unified health metrics dashboard
- `garmin-health-report.sh` — Garmin API integration
- `memory-guardian.sh` — Auto-cleanup + bloat detection
- `backup-memory.sh` — Drive backup (cron 4:00 AM)
- `backup-validator.sh` — Backup validation + test restore
- `tier-rotation.sh` — Memory tier management
- `usage-report.sh` — API cost tracking

## 🧠 MEMORY MANAGEMENT
- **Daily logs:** `memory/2026-03-*.md` (raw session notes)
- **Consolidated:** `memory/MEMORY.md` (curated long-term wisdom, main session only)
- **Permanent:** `memory/*-protocol.md`, `memory/manu-profile.md`, `memory/preferences.md`
- **Archive:** Old daily logs >30 days → `memory/archive/` (auto-cleanup by scripts)

---

## 📊 INFRASTRUCTURE

- **VPS:** Ubuntu 24.04 LTS, 16GB RAM, 8 cores
- **OpenClaw:** v2026.2.22-2, Port 18789
- **Default model:** Haiku 4.5 (changed 2026-02-24, was Opus)
- **Backup:** Google Drive, 30 days retention, daily 4:00 AM
- **Memory:** 844K (tiered HOT/WARM/COLD) — Feb 28 review: healthy, no bloat
- **Crons:** 22 active tasks (see TAREAS-AUTOMATICAS-LISTADO.md)

---

## 🔐 LECCIONES CLAVE
1. WAL/snapshots overkill para workspace pequeño → rclone+git suficiente
2. Cron timing: scheduling for time already passed = silent fail
3. SSH `AllowTcpForwarding no` rompe VNC → mantener `yes`
4. pam_tally2 deprecated en Ubuntu 24.04 → comentar en PAM config
5. Default model Opus quema presupuesto → usar Haiku, upgrade manual cuando necesario
6. Informes de cron pueden alucinar datos si leen docs obsoletos → limpiar siempre

---

**Last Review:** 2026-03-21 — Nightly autoimprove cycle (iteration 6 consecutive). Active improvements:
- Skills: HITL + PR-review + worktree protocols (decision tables, quick-start, troubleshooting)
- Scripts: Garmin-json-export, health-dashboard-auto, deliver-pending-reports (robustness, deps checks)
- Memory: Clean and healthy, no archiving needed
- Workspace: 6+ streak, 29+ total improvements, ~1MB markdown + skills. All critical crons active.
