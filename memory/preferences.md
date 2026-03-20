# 📋 Preferences — Lola & Manu

## Communication

### Telegram Reactions
- **reactionNotifications: all** — SIEMPRE activo (Manu lo quiere así)
- Manu usa emojis para dar feedback rápido sin escribir
- Config: `channels.telegram.reactionNotifications: all` Channels

### Morning Reports (Matutino)
- **Destination:** Discord ONLY ❌ NUNCA Telegram
- **Discord Channel:** `📊-reportes-matutino` (ID: `1475057935368458312`) ⚠️ NO al general
- **Guild ID:** `1475053097230270585`
- **Time:** 10:00 Madrid (cron `cb5d3743`)
- **Content:** Sistema, Seguridad, Backups, Autoimprove Nightly, System Updates, Garmin, Estado General
- **Script:** `scripts/informe-matutino-auto.sh`
- **Set:** 2026-03-14 10:10 (Manu's request)
- **Fix:** 2026-03-15 — Se enviaba al general en vez de reportes-matutino (corregido)

### Quiet Hours
- **00:00–07:00 Madrid:** Zero notifications (unless critical)
- **07:00–10:00 Madrid:** Monitor silently, no reports
- **10:00+ Madrid:** Morning report via Discord

### Driving Mode
- **Trigger in:** "estoy en el coche" (I'm in the car)
- **Output:** TTS audio via `tts` tool
- **Trigger out:** "ya estoy en casa" (I'm home now)
- **Default fallback:** Reset at 22:00 daily
- **State file:** `memory/driving-mode-state.json`

## Channels

| Channel | Purpose | Note |
|---------|---------|------|
| **Telegram** | Direct messages, quick replies | ✅ OK |
| **Discord** | Morning reports, summaries, alerts | ✅ OK (primary for reports) |
| **Email** | Administrative, formal | (via gog) |

## System Updates

- **Auto-update apt:** ✅ Nightly at 01:30 Madrid (cron `ed1d9b11`)
- **OpenClaw updates:** ❌ SIEMPRE MANUAL (nunca auto)
- **Sequence:** 01:30 apt → 02:00 autoimprove → 04:00 backup → 10:00 informe matutino
- **Log:** `memory/system-updates-last.json`

## Browser

- **Chrome CDP:** Activo en VPS (puerto 9222, loopback only)
- **Service:** `chrome-cdp.service` (systemd user, auto-start)
- **User data dir:** `/home/mleon/.config/chrome-cdp` (separado del Chrome normal)
- **Display:** :2 (Lola) — Display :1 es para Manu via VNC
- **VNC :1** → Manu (puerto 5901) | **VNC :2** → Lola/Chrome CDP (puerto 5902)
- **Config OpenClaw:** `browser.cdpUrl = http://127.0.0.1:9222`, `attachOnly = true`
- **Set:** 2026-03-14 10:58

## GitHub

- **Default visibility:** Private (always)
- **Auto-share with:** RagnarBlackmade (write access)
- **Never publish:** tokens, API keys, IPs, Tailscale hostnames, paths, .env, SSH keys, personal data
- **Token rotation:** Q2 2026

---

*Last updated: 2026-03-18 10:53*
