# Access Credentials & Infrastructure

## 🔐 Accounts

### Google (gog)
- **Account:** lolaopenclaw@gmail.com
- **Env vars:** GOG_KEYRING_BACKEND=file, GOG_KEYRING_PASSWORD, GOG_ACCOUNT
- **Config:** ~/.openclaw/.env + ~/.bashrc
- **Services:** Gmail, Calendar, Drive, Contacts, Sheets, Docs

### Garmin
- **Device:** Garmin Instinct 2S Solar Surf
- **OAuth:** Manu_Lazarus
- **Full integration details:** `memory/garmin-integration.md`

### GitHub
- **Account:** lolaopenclaw
- **Main repo:** lola-toolkit
- **Policy:** code ✅ | secrets ❌ (NEVER commit secrets/tokens/IPs)
- **Auth:** `gh` CLI (OAuth, auto-renewable)

### Finanzas
- **Repo:** github.com/lolaopenclaw/finanzas-personal (privado)
- **Format:** Markdown
- **Update frequency:** Every 15 days
- **Status:** Sheets integration DEPRECATED (2026-03)

---

## 🌐 Infrastructure

### SSH Access
- **Laptop:** ✅ Available during work hours (see `memory/work-schedule.md`)
- **VPS:** lola-openclaw-vps.taild8eaf6.ts.net (Tailscale)
- **Mobile (OnePlus 13):** ❌ No SSH access

### Ports
- **18790** — OpenClaw Gateway
- **8080** — OpenClaw UI
- **3333** — Canvas
- **5001** — API (firewall-protected)

### TTS Configuration
- **Engine:** Google TTS 1.25x speed
- **Scripts:** scripts/tts-venv/ (edge-tts, gtts-cli)
- **Driving mode:** See SOUL.md (auto-reset 22:00)

### Telegram
- **Bot ID:** 6884477
- **Main chat:** "Lola y Manu" (-1003768820594)
- **Quiet hours:** See AGENTS.md (00:00-07:00 Madrid)
- **Reactions:** MINIMAL mode
- **Topics:** See `memory/telegram-topics.md`

---

## Security Notes

- **Secret rotation:** Quarterly (see `memory/security.md`)
- **Last rotation:** Q1 2026 (2026-03-25)
- **Next rotation:** Q2 2026 (June)
- **Never commit:** API keys, tokens, IPs, .env files
- **Protocol A+B:** Required before SSH/firewall/service changes
