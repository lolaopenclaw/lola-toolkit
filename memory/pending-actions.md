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

### ✅ 3. Clean Up Duplicate Scripts (DONE 2026-03-26)
- ✅ **Morning report:** No duplicate (`generate-morning-report.sh` never existed)
- ✅ **Garmin:** All 3 scripts serve distinct purposes (documented in `scripts/archive/CONSOLIDATION-DECISIONS.md`)
  - `garmin-health-report.sh` → Core data fetcher (used by cron + morning report)
  - `health-dashboard.sh` → HTML dashboard generator
  - `health-alerts.sh` → Threshold monitoring / JSON alerts
- ✅ **Cron delivery fix:** Both archived to `scripts/archive/` (one-time fixes, completed 2026-03-25)
- ✅ **Commit:** `7078ed1` — "consolidate: archive one-time cron-delivery fix scripts, document Garmin script roles"

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

### OpenSpec — ⚠️ POSIBLE CANCELACIÓN
- Manu usando Claude Code directamente en el curro, avanzando bien
- Dudas sobre si tiene sentido integrar OpenSpec en el sistema de Lola
- **Status:** En evaluación — puede que se cancele y se limpie todo lo hecho
- Reference: Gentleman AI SDD pipeline (video in KB)

### Disaster Recovery Test
- Spin up test VPS, run restore.sh, measure real RTO
- Update DRS with actual numbers (currently claims 20min, reality ~2-4h)

### Cost Optimization Deep Dive
- Target: reduce from ~$500/month to ~$200/month
- A/B test Haiku vs Sonnet for routine cron tasks
- Implement daily budget hard cap ($20/day)



### Surf Coach — Seguir avanzando
- Proyecto a medias, seguir desarrollando cuando podamos
- Condiciones, coaching, tracking de sesiones

### Finanzas — Seguir avanzando
- Proyecto a medias, migración Markdown completa
- Seguir mejorando categorización, informes mensuales

### Hermes Agent — Implementar Ideas (investigación COMPLETA)
- ✅ Investigación completada 2026-03-28
- **Fase 1:** Memory Nudges (⭐⭐⭐⭐⭐, LOW effort) ← EN CURSO
- **Fase 2:** Progressive Skill Disclosure (⭐⭐⭐⭐, LOW effort) ← PRIORIZADO (reduce carga antes de añadir skills)
- **Fase 3:** Autonomous Skill Creation (⭐⭐⭐⭐⭐, MEDIUM effort, umbral alto: 3+ repeticiones)
- **Fase 4:** Skills Self-Improvement (⭐⭐⭐⭐, MEDIUM effort, needs safety)
- Source: https://github.com/NousResearch/hermes-agent
- Report: memory/hermes-agent-investigation-2026-03-28.md

### Evaluar Lobster Board + Dashboard existente
- ¿Quitar? ¿Mantener? Evaluar si aportan valor o son ruido

### ClawFlows + Lobster — Investigación COMPLETA
- **Report:** memory/clawflows-deep-research-2026-03-29.md (884 líneas)
- **HIGH:** Install ClawFlows + enable calendar, bills, repos workflows (1.5h)
- **HIGH:** Contribute surf workflow to community (2h)
- **MEDIUM:** Migrate 3 deterministic crons to Lobster (healthcheck, backup, surf) — 0 tokens (6-8h)
- **MEDIUM:** Add approval gates to destructive ops (3h)
- **LOW:** Build custom workflows for community (API health, backup integrity) (4-6h)

### Context Optimization Audit
- **Phase 1:** ✅ COMPLETE (8.6% reduction, 1,370 tokens saved)
- **Phase 2:** Weekly session reset (Mon 4AM, sessions >1000 msgs archived)
  - Would recover remaining ~9% + eliminate session bloat (3674 lines current)
  - **Status:** Backlog (idea anotada, valorar más adelante)

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
- Visual Dashboard (localhost:3333) — Descartado 2026-03-28, "otro dashboard más, no le veo utilidad"
- Lobster Board — En evaluación para descarte

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


---

### 🧹 Eliminar Telegram Outbound Watchdog cuando se arregle el bug — 2026-03-28

**Cron:** `🔧 Telegram Outbound Watchdog` (b97f6cea, cada 15 min)
**Workaround para:** Bug "Outbound not configured for channel: telegram" — mensajes se quedan atascados, watchdog reinicia gateway.
**Issues relacionados:** GitHub openclaw/openclaw #54931 y similares (WebSocket/outbound bugs)

**Acción cuando OpenClaw publique fix:**
1. Verificar que la nueva versión soluciona el problema (monitorizar 24-48h tras update)
2. Si no hay más mensajes atascados → eliminar watchdog:
   ```
   openclaw cron rm b97f6cea-0a6a-450a-9d74-d8d1683f5dae
   ```
3. Eliminar script asociado si existe
4. Actualizar memory/technical.md

**Trigger:** Revisar en cada auto-update de OpenClaw si el changelog menciona fix para outbound/telegram/WebSocket

**Set:** 2026-03-28 (Manu's explicit request — no dejar workarounds pululando)


---

### 🔴 Auto-update necesita rollback automático — 2026-03-29

**Incidente:** Auto-update 21:30 actualizó a v2026.3.28, nueva versión rechazó config TTS → crash loop ~30 min hasta que Manu intervino manualmente con `openclaw doctor --fix`.

**Causa:** Breaking change en schema TTS (keys `elevenlabs`, `openai`, `edge` eliminadas de `messages.tts`).

**Acción:** Mejorar cron de auto-update para:
1. Backup config ANTES de actualizar
2. Tras update, verificar que gateway arranca (health check 30s)
3. Si no arranca → rollback automático (restaurar config + versión anterior)
4. Si arranca → verificar que Telegram responde
5. Notificar resultado

**Prioridad:** ALTA (evitar que Manu tenga que intervenir manualmente otra vez)

**Set:** 2026-03-29 (incidente real)

