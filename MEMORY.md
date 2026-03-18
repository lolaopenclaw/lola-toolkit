# MEMORY.md — Index

## 🔴 CORE → `memory/core.md`
Manu: Manuel León Mendiola | Email: manuelleonmendiola@gmail.com | Telegram: 6884477 (@RagnarBlackmade) | TZ: Europe/Madrid | VPS: Ubuntu 6.8.0, OpenClaw v2026.3.8 | Quiet: 00:00-07:00

## 🔧 TECHNICAL → `memory/technical.md`
- Ubuntu Pro: ESM-Infra + ESM-Apps + Livepatch
- Crons: 4AM backup, 9AM morning, Mon 6AM audit, Mon 8:30 Garmin
- Issues: #24586 FIXED, #33093 workaround (18793), #33103 IMPROVED
- **TTS:** Google 1.25x speed | Driving Mode ✅

## 🔐 SECURITY & AUDITS
→ `memory/security.md` | Audit: `memory/2026-03-16-security-audit-weekly.md`
- **Last Audit:** ✅ 0 CRITICAL | ⚠️ 4 warnings | HARDENED (DROP/SSH-key/AppArmor)
- **Alert:** ANTES de cambios SSH/firewall/servicios → Protocol A+B
- **Protocols:** HITL (`memory/hitl-protocol.md`) | Worktree (`memory/worktree-protocol.md` + script) | PR-Review (`memory/pr-review-protocol.md`, ~$0.05)

## 👤 Familia
- **Vera Pérez León** (sobrina): 10 años, cumpleaños 30 agosto (cron configurado)

## 🔑 Secretos & Seguridad
→ `memory/security.md` | Rotation: Q2 2026 | Key: gateway.bind=loopback when tailscale.mode=serve

## 💰 Finanzas
→ `memory/finanzas.md` | Sheet: `1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA`

## 🖥️ Dashboards & URLs
→ `memory/dashboards.md` | Remote: lola-openclaw-vps.taild8eaf6.ts.net | Local: 18790/8080/3333/5001

## 📅 Google Calendar
→ `memory/calendar.md` | Tool: gog CLI | Bidirectional: Lola ↔ Manu | Status: in development

## 🐙 GitHub — lolaopenclaw
- **Account:** lolaopenclaw (email: lolaopenclaw@gmail.com)
- **Auth:** `gh` CLI authenticated, scopes: gist, read:org, repo, workflow
- **Repos:**
  - `lola-toolkit` — Scripts, skills, protocols para gestión de agentes IA (public)
- **Policy:** Publicar todo lo útil que creemos. NUNCA tokens/keys/IPs/paths personales.

## 🔬 Autoresearch — Karpathy
→ `memory/autoresearch-karpathy.md` | Repo: github.com/karpathy/autoresearch | Pattern: iterate→test→keep/discard | Applied: autoimprove/
- **Autoimprove Nightly:** iterate→test→keep/discard. Circuit breaker 5 fallos. ~$0.50/noche. Cron ID: 08325b21

## 🔴 ARQUITECTURA DE CONFIABILIDAD
- Verificación AFTER every step (don't assume success)
- Slow execution, small steps, plan before changing
- Details: `memory/protocols.md`

## 📋 HEARTBEAT PREFERENCES
- **Quiet:** 00:00-07:00 Madrid (SILENT unless critical)
- **Post-quiet:** 07:00-10:00 (silent monitoring, no reports)
- **Morning:** 10:00+ Madrid (Discord, includes Autoimprove Nightly)
- **Autoimprove Resumen:** ONLY Discord morning report
