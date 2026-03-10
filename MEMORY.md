# MEMORY.md — Index

**Modular structure:** Content split by topic. Use `memory_search` for queries.

---

## 🔴 CORE
→ `memory/core.md`
- **Manu:** Manuel León Mendiola, manuelleonmendiola@gmail.com
- **Telegram:** 6884477 (@RagnarBlackmade) | **TZ:** Europe/Madrid
- **VPS:** Ubuntu 6.8.0, OpenClaw **v2026.3.8** | **Quiet hours:** 00:00-07:00

## 🔧 TECHNICAL
→ `memory/technical.md`
- **Ubuntu Pro:** ✅ ESM-Infra + ESM-Apps + Livepatch
- **Crons:** 4AM backup, 9AM morning report, Mon 6AM security audit, Mon 8:30 Garmin weekly
- **#24586** cron delivery: ✅ FIXED v2026.3.8
- **#33093** browser relay: ✅ Workaround (port 18793, manual token)
- **#33103** gateway restart loop: IMPROVED (locked on GitHub)

## 🔐 PROTOCOLS
→ `memory/protocols.md`
- SIEMPRE avisar ANTES de cambios SSH/firewall/servicios
- Protocol A+B: Backup → Baseline → Change → Validate → Rollback if needed

## 👤 Familia
- **Vera Pérez León** (sobrina): 10 años, cumpleaños 30 agosto (cron configurado)

## 🔑 Secretos & Seguridad
- Secrets in `~/.openclaw/.env`, referenced as `${VAR_NAME}` in openclaw.json
- **NEVER** change `gateway.bind` when `tailscale.mode=serve` (must be loopback)
- Browser Relay: gateway port + 3 (18790 → 18793)
- Token rotation: every 3 months (next: June 2026, last: March 2026)

## 💰 Finanzas
- **Sheet:** `1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA`
- **Dir:** `/home/mleon/finanzas/` | **Docs:** `finanzas/README.md`
- Banks: CaixaBank (355 movs) + Bankinter (29) | Period: Dec 2025 - Mar 2026

## 🖥️ Dashboards & URLs
→ Remote (Tailscale HTTPS):
- OpenClaw: `https://lola-openclaw-vps.taild8eaf6.ts.net`
- LobsterBoard: `:8443` | VidClaw: `:8444`

→ Local: 18790 (gateway), 8080 (LobsterBoard), 3333 (VidClaw), 5001 (API)

→ Widgets: Finanzas (Sheets, 1h), Salud/Garmin (5m), Calendar (10m)

## 📅 Google Calendar
- Bidirectional: Lola creates events + Manu sees + heartbeats verify
- Tool: gog CLI | Status: in development

## 🔬 Autoresearch — Karpathy (2026-03-09)
- **Repo:** https://github.com/karpathy/autoresearch (15K+ stars)
- Autonomous ML research loop: iterate→test→keep/discard
- Tracking: weekly cron Mon 10AM | Details: `memory/autoresearch-karpathy.md`
- Applied to our setup: `autoimprove/` framework

## 🔴 ARQUITECTURA DE CONFIABILIDAD
- Verificación AFTER every step (don't assume success)
- Slow execution, small steps, plan before changing
- Details: `memory/protocols.md`

## 📋 HEARTBEAT PREFERENCES (2026-03-10)
- **Quiet hours:** 00:00-07:00 Madrid (SILENT unless critical)
- **Post-quiet:** 07:00-10:00 Madrid (monitor silently, no reports)
- **Matutino report:** 10:00+ Madrid (Discord, includes Autoimprove Nightly)
- **Autoimprove Nightly/Resumen:** ONLY in Discord morning report, NOT in regular heartbeats
