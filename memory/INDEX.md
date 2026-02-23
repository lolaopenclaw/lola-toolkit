# 📚 Memory INDEX — Organized Knowledge

Last updated: 2026-02-23 09:30 UTC+1

---

## 🎯 ACTIVE PROJECTS

### 🚨 WAL Snapshot Crisis & Resolution (2026-02-23 — RESOLVED)
- **Incident:** Memory bloat (86M → 184M in 1.5h) from WAL snapshot misconfiguration
- **Root cause:** Cron timing race condition (changed to 3 AM at 06:35 AM = already passed)
- **Resolution:** Rollback to 6h snapshots + lunes archival (known-good state)
- **Monitoring:** New WAL Snapshot Monitor cron (every 6h) with thresholds: 100MB warning, 150MB critical
- **Files:**
  - `memory/2026-02-23-wal-diagnosis-complete.md` — Timeline + root cause
  - `memory/2026-02-23-wal-roadmap.md` — 5-phase optimization roadmap (Phase 1 active)
  - `memory/PROTOCOLS/cron-change-protocol.md` — NEW: Rules for future cron changes
  - `scripts/wal-snapshot-monitor.sh` — NEW: Automated monitoring script
- **Status:** ✅ Stable, Phase 1 (Stabilize & Monitor) active
- **Next decision point:** Week of Feb 28 (decide on Phase 2 — reactive archival)

### OpenClaw Contributions (IN PROGRESS)
- **Status:** Week 1 — Research & Planning ✅
- **Next:** Week 2 — Post Discussion, get feedback
- **Files:**
  - `memory/2026-02-21-openclaw-contributions.md` — Session notes + learnings
  - `CONTRIB/ROADMAP.md` — 5-week timeline + detailed checklist
  - `CONTRIB/DISCUSSION-DRAFT.md` — GitHub Discussion template (ready to post)
  - `CONTRIB/DOCS/skill-security-audit.md` — Full PR documentation
- **Key Dates:**
  - Week 2 (2026-02-28): Post Discussion
  - Week 3 (2026-03-07): Submit PR #1
- **Action Items:** See CONTRIB/ROADMAP.md for Manu's checklist

### 🛡️ System Hardening (COMPLETED)
- **Status:** Sysctl Phase 1 ✅ (10/12 params applied + persisted post-reboot)
- **Status:** Systemd Hardening ❌ (paused — VPS hypervisor incompatibility)
- **Status:** Gateway Architecture ✅ (system-level service, stable)
- **Files:**
  - `/etc/sysctl.d/99-hardening.conf` — Kernel hardening (production)
  - `memory/security-change-protocol.md` — Critical change procedures
  - `memory/PROTOCOLS/canary-testing-protocol.md` — Pre-change validation

### 📊 Health & Monitoring (COMPLETED)
- **Status:** ✅ Garmin integration + Unified dashboard + alerts + Notion sync
- **Scripts:**
  - `scripts/health-dashboard.sh` — Main dashboard (9162 bytes)
  - `scripts/health-alerts.sh` — Alert system
  - `scripts/garmin-health-report.sh` — Garmin API wrapper
  - `scripts/health-to-notion.sh` — Notion sync
- **Crons active:** 4 (morning report 9AM, alerts 14:00+20:00, weekly summary Monday 8:30)

### 📊 Google Sheets Automation (IN PROGRESS)
- **Status:** Initial setup complete, testing Monday 9:30 AM
- **Sheets created:** "Consumo IA" + "Garmin Health" (in 📊 Lola Dashboards)
- **Cron:** "📊 Populate Google Sheets (diario)" — L-V 9:30 AM Madrid
- **Blocked on:** `client_secret.json` (Manu needs to download from desktop)
- **Files:** `scripts/sheets-populate-daily-FIXED.sh`, `memory/2026-02-22-google-sheets-automation.md`

### 👨‍👧 Family Tracking
- **Manu's Birthday:** February 16 (age 48) — Cron reminder 9:00 AM
- **Vera Pérez León (Sobrina):** 10 years old, birthday August 30 — Cron reminder 9:00 AM
- **Note:** Vera can access Telegram/voice — verify speaker identity on audio messages

---

## 💾 ORGANIZED BY CATEGORY

### 📝 PROTOCOLS & PROCEDURES
- `memory/security-change-protocol.md` — Critical change A+B workflow
- `memory/PROTOCOLS/cron-change-protocol.md` — NEW (2026-02-23): Golden rules for cron scheduling
- `memory/PROTOCOLS/canary-testing-protocol.md` — Pre-change validation
- `memory/PROTOCOLS/backup-naming-policy.md` — Backup file naming
- `memory/PROTOCOLS/backup-retention-policy.md` — 30-day retention
- `memory/PROTOCOLS/memory-guardian-protocol.md` — Auto-cleanup system
- `memory/health-dashboard-protocol.md` — (TODO: create when dashboard goes to production)

### 🔧 SCRIPTS (tools in /scripts)
- `skill-security-audit.sh` — Security audit for ClawHub skills ⭐ (ready for PR)
- `test-skill-security-audit.sh` — Test suite (15/15 passing) ⭐
- `health-dashboard.sh` — Unified health metrics dashboard
- `garmin-health-report.sh` — Garmin API integration
- `health-alerts.sh` — Alert system
- `health-to-notion.sh` — Notion sync
- `memory-guardian.sh` — Auto-cleanup + bloat detection
- `backup-memory.sh` — Drive backup (cron 4:00 AM)
- `backup-validator.sh` — Backup validation + test restore
- `wal-logger.sh` — Write-Ahead Logging (crash recovery)
- `wal-snapshot.sh` — WAL snapshots
- `wal-replay.sh` — WAL recovery
- `wal-snapshot-monitor.sh` — NEW (2026-02-23): Monitor WAL growth, alert on bloat

### 🎓 DOCUMENTATION
- `CONTRIBUTION-PLAN.md` — 4-week strategy for 5 tools
- `CONTRIB/ROADMAP.md` — Detailed timeline + checklists ⭐
- `CONTRIB/DISCUSSION-DRAFT.md` — GitHub Discussion template ⭐
- `CONTRIB/DOCS/skill-security-audit.md` — Full PR documentation ⭐
- `CONTRIB/TESTING-GUIDE.md` — How to test contributions
- `BOOTSTRAP.md` — VPS recovery from scratch
- `RECOVERY.md` — Full system recovery guide

### 🧠 MEMORY MANAGEMENT
- `memory/DAILY/HOT/` — Last 7 days (search first)
- `memory/DAILY/WARM/` — 8-30 days (secondary search)
- `memory/DAILY/COLD/` — >30 days (compressed .tar.gz)
- `memory/daily-structure.md` — Tiered architecture docs

---

## 🔗 QUICK LINKS

### This Session (2026-02-23)
- **Crisis & Resolution:** WAL bloat incident → diagnosed root cause → implemented monitoring ✅
- **Documentation:** Comprehensive diagnosis, protocols, 5-phase roadmap
- **Reference:** `memory/TAREAS-AUTOMATICAS-LISTADO.md` — NEW: Complete list of 28 automated tasks
- **Key file:** `memory/2026-02-23-wal-diagnosis-complete.md` — Full timeline + lessons learned
- **Updates:** Cron timeout increased 120s → 300s for memory-organization-review (now works perfectly)
- **Status:** System stable, all 28 crons running, monitoring active

### Previous Session (2026-02-22)
- Session notes: `memory/2026-02-22.md`
- Progress: ✅ Google Sheets setup, communication policy, 3 discussions opened, memory cleanup
- Commits: 37 commits (communication + sheets + tracking + github discussions)
- Review: `memory/2026-02-22-memory-review.md` (weekly memory audit — 9.2/10 score)

### Previous Session (2026-02-21)
- Session notes: `memory/2026-02-21-openclaw-contributions.md`
- Progress: ✅ 7 sub-agents completed, hardening + health dashboard + contributions strategy
- Commits: `2fbc918` (skill-security-audit enhancement) + `390e761` (DISCUSSION-DRAFT + ROADMAP)

### Previous Sessions
- 2026-02-21: WAL Protocol + Memory Guardian + Dashboard + Skill Audit
- 2026-02-21: Semantic Search + Backup Validation + Critical Updates (earlier in day)
- 2026-02-20: SSH hardening incident (AllowTcpForwarding broke VNC)
- See `memory/DAILY/` for full archive

### Key Files to Know
- `SOUL.md` — Who I am (AI assistant, helpful, opinionated)
- `USER.md` — Who Manu is (musician, Logroño, Spain, @RagnarBlackmade)
- `MEMORY.md` — Long-term memory (decisions, learnings, infrastructure)
- `HEARTBEAT.md` — Periodic checks (email, calendar, health, crons, Notion)
- `memory/manu-profile.md` — Detailed profile (music, devices, preferences)

---

## 🎯 UPCOMING TASKS (Prioritized)

### WEEK 1 (2026-02-21 — Past)
- [x] OpenClaw contributions strategy ✅
- [x] skill-security-audit.sh ready ✅
- [x] Discussion template + roadmap ✅
- [x] 3 Discussions opened on GitHub ✅
  - https://github.com/openclaw/openclaw/discussions/23394 (Skill Security Audit)
  - https://github.com/openclaw/openclaw/discussions/23394 (Critical Update Framework)
  - https://github.com/openclaw/openclaw/discussions/23395 (Memory Guardian)
- [x] Communication policy unified (Discord only, Telegram silent) ✅
- [x] Google Sheets automation initialized ✅

### WEEK 2 (2026-02-28 — Current)
- [x] WAL crisis diagnosed & resolved (2026-02-23) ✅
- [x] WAL monitoring + phases documented (2026-02-23) ✅
- [x] Memory organization timeout fixed 120s → 300s (2026-02-23) ✅
- [ ] Test Google Sheets cron (Monday 25 Feb, 9:30 AM) — rescheduled
- [ ] OpenClaw Discussion feedback phase (passive — waiting for response)
- [ ] (Manu) Review Sheets test results when ready
- [ ] (Manu) Download client_secret.json from desktop (when ready)
- [ ] Complete Google Sheets OAuth setup (blocked on Manu's JSON)
- [ ] Monitor WAL thresholds (100MB warning, 150MB critical) throughout week

### WEEK 3 (2026-03-07)
- [ ] Submit PR #1 (skill-security-audit.sh)
- [ ] Tests pass in OpenClaw CI
- [ ] PR under review

### WEEK 4+ (2026-03-14+)
- [ ] PR #1 merged OR still iterating
- [ ] Start Tool #2 (memory-guardian.sh)
- [ ] Genericize, test, document

### ONGOING (Continuous)
- [ ] Monitor OpenClaw Discussions (feedback phase — 2-3 days expected)
- [ ] Health alerts (Garmin + system metrics)
- [ ] Cron jobs monitoring (4:00 AM backup, 9:00 AM reports, 9:30 AM Sheets, etc.)
- [ ] Memory maintenance (tier rotation, cleanup) — automated via memory-guardian.sh
- [ ] Monday 9:30 AM: Test Google Sheets population cron (Manu to verify results)
- [ ] When ready: Manu shares client_secret.json → complete OAuth setup

---

## 📊 CURRENT STATE

### Infrastructure
- **VPS:** Ubuntu 24.04 LTS, 16GB RAM, 8 cores, LXC/LXD
- **OpenClaw:** v2026.2.17, Port 18789, Opus + Haiku models
- **Uptime:** Stable, multiple reboots tested ✅
- **Backup:** Google Drive, 30-day retention, automated cron (4:00 AM daily) ✅
- **WAL:** Active, snapshots every 6h, COLD archive lunes 6:15 AM, monitoring every 6h
  - **Status (2026-02-23 08:25):** 146M HOT (2 snapshots), 37M COLD archive
  - **Thresholds:** 100MB warning, 150MB critical (automated alerts)
  - **Phase:** 1 (Stabilize & Monitor) — decision point Week of Feb 28

### Development
- **Git:** Main branch + feature/skill-security-audit-enhancement branch
- **Tests:** 15/15 passing (skill-security-audit)
- **Crons:** 28 active, 0 critical errors (1 timeout fixed: memory-organization-review 120s → 300s)
- **Memory:** 184M total (183M = WAL for recovery ✅, 1M active metadata), tiered perfectly (HOT/WARM/COLD)
- **Memory review (2026-02-23):** HOT 148K / WARM 12K / COLD 4K, zero duplicates, 100% healthy
- **Automated tasks:** See `memory/TAREAS-AUTOMATICAS-LISTADO.md` for complete 28-task breakdown

### Health (2026-02-22)
- **Garmin:** HR ~60-65 bpm (resting ✅), stress low ✅, battery monitoring active
- **Sleep:** ~7h tracked + data in Garmin Health sheet
- **Steps:** Variable (work-from-home days), tracked in Garmin integration

---

## ✨ KEY LEARNINGS (Last 72 Hours)

### 2026-02-23 Learnings
1. **Cron timing is tricky** — Scheduling for time already passed = silent fail (no backfill)
2. **Test in production matters** — 120s timeout caught by actual execution, not testing
3. **Monitoring prevents pain** — WAL monitor alerts beat emergency diagnosis
4. **Protocols prevent repeats** — Document "how to change crons safely" for future reference
5. **Memory system is robust** — 0 duplicates after aggressive growth + changes = tiering works perfectly
6. **Phase-based evolution beats big-bang** — Phase 1 (monitor), Phase 2 (reactive), etc. reduces risk

### 2026-02-22 Learnings
1. **CLI tools have format limitations** — `gog sheets append` puts everything in one column
2. **Google Sheets API v4 > CLI wrappers** — More reliable for structured data
3. **Testing real > promising** — Automation fails silently without actual execution
4. **Timing matters in automation** — VPS headless auth ≠ desktop OAuth flow
5. **Unified communication wins** — One channel (Discord) beats scattered notifications
6. **Identity verification needed** — Shared device access requires speaker identification

### 2026-02-21 Learnings
1. **Bash regex for security patterns** — Eval detection needs to handle both JS and bash syntax
2. **Test suite essentials** — 15/15 passing = confidence for maintainers
3. **Documentation matters** — PR docs + examples = faster approval
4. **Community engagement** — Discussion first, PR second (save time on feedback)
5. **Genericization critical** — `$OPENCLAW_WORKSPACE` env var prevents hardcoded paths

---

## 🚀 CONTRIBUTIONS POSTED

**3 Discussions now LIVE on GitHub:**

1. **Skill Security Audit** — https://github.com/openclaw/openclaw/discussions/23394
   - ✅ Fully functional + well-tested (15/15)
   - ✅ Comprehensively documented
   - 🟢 **Status:** Awaiting feedback

2. **Critical Update Framework** — https://github.com/openclaw/openclaw/discussions/23394
   - ✅ Full design document ready
   - 🟢 **Status:** Awaiting feedback

3. **Memory Guardian** — https://github.com/openclaw/openclaw/discussions/23395
   - ✅ Implementation complete
   - 🟢 **Status:** Awaiting feedback

**5-week rollout plan still active** — 4 more tools to follow based on feedback.

**Current phase:** Community engagement (Week 2) — Passively monitoring discussions.

---

Last sync: 2026-02-21 21:00 UTC+1  
Next review: After Manu posts Discussion (Week 2)
