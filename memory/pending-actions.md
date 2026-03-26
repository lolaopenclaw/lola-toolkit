# Pending Actions — Master Plan

**Last updated:** 2026-03-26  
**Review:** Every morning, Lola presents what's next.

---

## ✅ Completed (2026-03-25 / 2026-03-26)

- ✅ Knowledge Base con RAG (scripts, SQLite, FTS5, tested)
- ✅ Prompt Optimization (audit 31 crons, guide, model assignments)
- ✅ Markdown Drift Checker (script + cron weekly)
- ✅ API Cost Tracker (usage-report enhanced + cost-alert + cron daily)
- ✅ Notification Batching (script ready, pending cron integration)
- ✅ Wallet Draining Defense (runtime-governance + emergency-stop)
- ✅ PRD.md (English, 30 features, synced with reality)
- ✅ Adversarial Evaluation Protocol (formalized, 3-layer pipeline)
- ✅ First adversarial audit (4 auditors, all fixes applied)
- ✅ OpenSpec integration (specs/, TypeScript)
- ✅ GitHub push (lola-toolkit, clean history)
- ✅ Opus permanent (cron reset deleted)
- ✅ Security: secrets scrubbed from 19 files, perms fixed
- ✅ Scripts: error handling added to 12 scripts, hardcoded paths fixed
- ✅ Crons: race condition fixed, schedules staggered, delivery errors fixed

---

## 🔴 Phase: Consolidation (This week / next week)

Goal: Simplify, deduplicate, and harden what we have. No new features.

### 1. Consolidate Autoimprove (3 crons → 1)
- **Current:** 3 separate crons (scripts/skills/memory) at 3:00, 3:05, 3:10 AM
- **Target:** 1 script with `--target scripts|skills|memory|all`
- **Why:** Simpler, easier to maintain, one log to check
- **Effort:** 2-3h

### 2. Consolidate Healthcheck Crons (6 → 1 dashboard)
- **Current:** fail2ban, rkhunter, lynis, security-audit, nightly-security-review, config-drift — all separate
- **Target:** 1 unified healthcheck script that runs all checks and produces 1 report
- **Why:** Less cron sprawl, less notification noise, 1 report to read
- **Effort:** 3-4h

### 3. Clean Up Duplicate Scripts
- **Morning report:** `generate-morning-report.sh` vs `informe-matutino-auto.sh` — pick one
- **Garmin:** `garmin-health-report.sh` vs `health-dashboard.sh` vs `health-alerts.sh` — clarify roles or merge
- **Cron delivery fix:** `fix-cron-delivery.sh` vs `fix-cron-delivery.py` — delete one
- **Effort:** 1-2h

### 4. Session Log Rotation
- **Current:** 148 logs, 60MB, no cleanup
- **Target:** Weekly cron: compress logs >7 days, delete >30 days
- **Effort:** 30min

### 5. Notification Batching — Activate Crons
- **Current:** Script ready, no cron integration
- **Target:** Create flush crons (hourly for high, 3-hourly for medium, morning for low)
- **Migrate:** Key crons to use batcher instead of direct Telegram
- **Effort:** 1-2h

### 6. Simplify Backup Strategy
- **Current:** Custom backup + OpenClaw native + Git (triple)
- **Target:** Pick 1 backup method + Git. Eliminate redundancy.
- **Effort:** 1-2h

---

## 🟡 Backlog (After consolidation)

### Knowledge Base Phase 2
- Activate vector embeddings in chunks table
- Semantic search (not just FTS5 keyword)
- Estimated: Q2 2026

### OpenSpec — Revisit for Work
- Manu will revisit when clearer on how team uses it
- Reference: Gentleman AI SDD pipeline (video in KB)

### Disaster Recovery Test
- Spin up test VPS, run restore.sh, measure real RTO
- Update DRS with actual numbers (currently claims 20min, reality ~2-4h)

### Cost Optimization Deep Dive
- Target: reduce from ~$500/month to ~$200/month
- A/B test Haiku vs Sonnet for routine cron tasks
- Implement daily budget hard cap ($20/day)

### Visual Dashboard
- Real implementation of localhost:3333 dashboard
- Widgets: costs, crons, memory, health

---

## 🔄 Scheduled Reviews

### Re-Audit Adversarial — April 14, 2026
- Full system audit with adversarial evaluators (same 4 areas)
- Compare scores vs today's baseline (2.35/5)
- Cron reminder set for this date

---

## ❌ Descartadas
- CRM Personal
- Meeting Prep matutino
- Sesiones sin expiración
- Food Journal
- Video/Content Pipeline
- X/Twitter management

---

### 🔴 Mensajes perdidos durante procesamiento — 2026-03-26

**Problema:** Cuando Lola está procesando (ejecutando scripts, pensando), los audios/mensajes de Manu se pierden. Manu tiene que reenviar.

**Impacto:** ALTO — fricción en canal principal de comunicación, especialmente en driving mode.

**Causas posibles:**
- Gateway restarts durante procesamiento
- Compactación de contexto descarta mensajes queued
- Timeout en cola de mensajes entrantes

**Acción:** Investigar y resolver. Relacionado con sesión de rendimiento programada en General.

**Set:** 2026-03-26 (Manu's explicit feedback)

