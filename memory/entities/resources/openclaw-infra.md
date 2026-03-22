# OpenClaw Infrastructure — Summary

**Type:** resource  
**Last synthesized:** 2026-03-22  
**Tiers:** 7 hot, 0 warm, 0 cold

## 🔥 Hot (recent / frequent)

- **[context]** VPS: Ubuntu 24.04 LTS, 16GB RAM, 8 cores. Provider: IONOS Cloud. Hostname: [redacted].ts.net (Tailscale).
- **[status]** OpenClaw v2026.3.13. Default model: claude-haiku-4-5. Fallbacks: claude-sonnet-4-5, gemini-3-flash-preview.
- **[context]** Security: Hardened (DROP default policy, SSH key-only, AppArmor). Ubuntu Pro: ESM-Infra + ESM-Apps + Livepatch. Protocol A+B before any SSH/firewall changes.
- **[context]** Crons: 4AM daily backup (Google Drive, 30-day retention), 9AM morning report, Mon 6AM security audit, Mon 8:30 Garmin weekly, Sun 23:00 memory decay.
- **[context]** Integrations: Google Workspace (gog CLI, lolaopenclaw@gmail.com), GitHub (gh CLI, lolaopenclaw account), Garmin Connect (OAuth), Telegram (primary channel), Discord (morning reports).
- **[context]** Local ports: 18790 (gateway), 8080 (web), 3333 (dev), 5001 (misc). Memory search: OpenAI embeddings provider (changed 2026-03-18 from local).
- **[status]** Kernel 6.8.0-106 pending reboot (deferred 2026-03-18, running 6.8.0-101). Tailscale 1.96.2 updated. Chrome 146 updated.

---

See `openclaw-infra.json` for all 7 facts.