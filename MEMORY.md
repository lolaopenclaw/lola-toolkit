# MEMORY.md — Index

## 🔴 CORE → `memory/core.md`
Manu: Manuel León Mendiola | Email: manuelleonmendiola@gmail.com | Telegram: 6884477 (@RagnarBlackmade) | TZ: Europe/Madrid | VPS: Ubuntu 6.8.0, OpenClaw v2026.3.8 | Quiet: 00:00-07:00

## 🔧 TECHNICAL → `memory/technical.md`
- Ubuntu Pro: ESM-Infra + ESM-Apps + Livepatch
- Crons: 4AM backup, 9AM morning, Mon 6AM audit, Mon 8:30 Garmin
- Issues: #24586 FIXED, #33093 workaround (18793), #33103 IMPROVED
- **TTS:** Google TTS + 1.25x speed (2026-03-13 10:44) | Driving Mode ✅ READY

## 🔐 PROTOCOLS
→ `memory/protocols.md`
- SIEMPRE avisar ANTES de cambios SSH/firewall/servicios
- Protocol A+B: Backup → Baseline → Change → Validate → Rollback if needed
- **HITL Protocol** → `memory/hitl-protocol.md` (2026-03-13): Explorar→Proponer→Implementar→Verificar con checkpoints de aprobación para tareas complejas
- **Worktree Protocol** → `memory/worktree-protocol.md` (2026-03-13): Git worktrees para sub-agentes paralelos sin conflictos. Script: `scripts/worktree-manager.sh`
- **PR Review Auto** → `memory/pr-review-protocol.md` (2026-03-13): Review automático de PRs con Sonnet. Skill: `skills/pr-review/`. Polling (no expone VPS). ~$0.05/review

## 👤 Familia
- **Vera Pérez León** (sobrina): 10 años, cumpleaños 30 agosto (cron configurado)

## 🔑 Secretos & Seguridad
→ `memory/security.md` | Secrets: `~/.openclaw/.env` | Rotation: Q2 2026 | Key lesson: gateway.bind=loopback when tailscale.mode=serve

## 💰 Finanzas
→ `memory/finanzas.md` | Sheet: `1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA` | CaixaBank (355) + Bankinter (29) | Dec 2025 - Mar 2026

## 🖥️ Dashboards & URLs
→ `memory/dashboards.md` | Remote: https://lola-openclaw-vps.taild8eaf6.ts.net | Local: 18790/8080/3333/5001 | Widgets: Finanzas/Salud/Calendar

## 📅 Google Calendar
→ `memory/calendar.md` | Tool: gog CLI | Bidirectional: Lola ↔ Manu | Status: in development

## 🐙 GitHub — lolaopenclaw
- **Account:** lolaopenclaw (email: lolaopenclaw@gmail.com)
- **Auth:** `gh` CLI authenticated, scopes: gist, read:org, repo, workflow
- **Repos:**
  - `lola-toolkit` — Scripts, skills, protocols para gestión de agentes IA (public)
- **Policy:** Publicar todo lo útil que creemos. NUNCA tokens/keys/IPs/paths personales.

## 🔬 Autoresearch — Karpathy
→ `memory/autoresearch-karpathy.md` | Repo: github.com/karpathy/autoresearch | Pattern: iterate→test→keep/discard | Applied: autoimprove/ | Cron: Mon 10AM
- **Autoimprove Nightly** → `skills/autoimprove/SKILL.md` (2026-03-13): 10 iteraciones/noche a las 02:00. Skills→Scripts→Memory→Self-review. Circuit breaker a 5 fallos. Haiku. ~$0.50/noche. Cron ID: 08325b21

## 🔴 ARQUITECTURA DE CONFIABILIDAD
- Verificación AFTER every step (don't assume success)
- Slow execution, small steps, plan before changing
- Details: `memory/protocols.md`

## 📋 HEARTBEAT PREFERENCES (2026-03-10)
- **Quiet hours:** 00:00-07:00 Madrid (SILENT unless critical)
- **Post-quiet:** 07:00-10:00 Madrid (monitor silently, no reports)
- **Matutino report:** 10:00+ Madrid (Discord, includes Autoimprove Nightly)
- **Autoimprove Nightly/Resumen:** ONLY in Discord morning report, NOT in regular heartbeats
