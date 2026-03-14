# 📋 Preferences — Lola & Manu

## Communication Channels

### Morning Reports (Matutino)
- **Destination:** Discord ONLY ❌ NUNCA Telegram
- **Time:** 10:00 Madrid (cron `cb5d3743`)
- **Content:** Sistema, Seguridad, Backups, Autoimprove Nightly, System Updates, Garmin, Estado General
- **Script:** `scripts/informe-matutino-auto.sh`
- **Set:** 2026-03-14 10:10 (Manu's request)

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

---

*Last updated: 2026-03-14 10:18*
