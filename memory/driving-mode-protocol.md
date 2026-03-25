# 🚗 Driving Mode Protocol (2026-03-08)

**Status:** ACTIVE - Implemented with Plan A (commands + auto-reset)

## Rules

### Manual Activation (Manu tells me)
- **Trigger phrase:** "estoy en el coche" / "estoy conduciendo" / "en el coche" / "me monto en el coche"
  - **Action:** Activate DRIVING MODE → respond ONLY via audio (TTS) until deactivated
  
- **Trigger phrase:** "ya estoy en casa" / "he llegado" / "ya no estoy en el coche"
  - **Action:** Deactivate DRIVING MODE → back to text-only responses

### ⚠️ SCOPE: GLOBAL (All Topics/Sessions)
- **Driving mode is a GLOBAL state** — applies to ALL Telegram topics simultaneously
- When activated in ANY topic → ALL topics respond via audio
- When deactivated in ANY topic → ALL topics respond via text
- **State file is the single source of truth:** `memory/driving-mode-state.json`
- **Every session/topic MUST check state file before every response** (as per SOUL.md mandatory check)
- **Reports, security alerts, cron outputs** → still delivered as TEXT (written notifications)
- **Conversational replies to Manu** → delivered as AUDIO when driving mode is active

### Auto-Reset (Nightly)
- **Time:** 22:00 Madrid time (every day)
- **Action:** Automatically reset to text-only mode
- **Purpose:** Safety catch in case Manu forgets to tell me he's home

## Storage
- **File:** `~/.openclaw/workspace/memory/driving-mode-state.json`
- **Format:** 
  ```json
  {
    "mode": "driving" | "home",
    "activated_at": "2026-03-08T19:23:00+01:00",
    "last_reset": "2026-03-08T22:00:00+01:00"
  }
  ```

## Implementation Details

### Current (Plan A - Commands)
✅ Reliable
✅ 100% accurate  
✅ Zero false positives
✅ Simple state management
❌ Requires manual activation/deactivation

### Future (Plan B - Auto-Detection)
**Ideas explored:**
1. **Bluetooth detection** - Would need Tailscale device info (not exposed to CLI)
2. **Audio analysis** - Detect road/engine noise in voice messages (slow, compute-heavy)
3. **Pattern learning** - Learn Manu's typical driving hours (feasible but imperfect)

**Recommendation:** Start with Plan A, safe and proven. Revisit Plan B if time permits.

## Cron Job for Auto-Reset
```
Name: 🏠 Driving Mode Auto-Reset
Schedule: 0 22 * * * (22:00 daily)
Action: Reset driving_mode_state.json to "home" mode
```

---

## Examples

**Scenario 1: Manu starts driving**
- Manu: "Oye, estoy en el coche ya"
- Lola: Detects phrase, sets mode=driving, replies via TTS audio for rest of session
- All responses via audio until...

**Scenario 2: Manu arrives home (manual)**
- Manu: "Vale, ya estoy en casa"
- Lola: Detects phrase, sets mode=home, switches back to text-only

**Scenario 3: Manu forgets to tell Lola (auto-reset)**
- 22:00 PM - Auto-reset cron runs
- Lola: Resets mode to "home" automatically
- Next message: Text-only responses resume

---

## TTS Status (2026-03-19 23:34) ✅ PRODUCTION READY

### TTS Strategy (updated 2026-03-19)
- **PRIMARY:** Google TTS script (`scripts/google-tts.sh`) — always try first
- **FALLBACK:** OpenClaw native `tts` tool — only if Google TTS fails
- **Reason:** Native tts has unreliable providers (Edge timeout, no OpenAI key, ElevenLabs out of credits). Google TTS is free and reliable.
- **Override:** Manu will say when to switch back to native-first

### Configuración Final
- **Proveedor principal:** Google TTS (online, gratis, natural)
- **Velocidad:** 1.25x (25% más rápido)
- **Idioma:** Spanish (es)
- **Formato:** MP3 (24 kHz, mono)
- **Fallback 1:** OpenClaw native tts tool
- **Fallback 2:** eSpeak-ng (offline, robótico)

### Instalación
- Google TTS: `~/.openclaw/venv/gtts/bin/activate` (gTTS)
- eSpeak-ng: `brew install espeak-ng`
- ffmpeg: para aceleración de audio

### Uso en Modo Conducción
Cuando Manu dice "estoy en el coche":
1. Lola detecta phrase y activa driving mode
2. Genera respuesta con Google TTS + ffmpeg (atempo=1.25)
3. Envía audio vía Telegram
4. Espera comando "ya estoy en casa" o reset automático a las 22:00

## Notes
- Protocol active as of 2026-03-08 19:23
- TTS enabled as of 2026-03-13 10:31
- User prefers responsiveness over complexity
- Safety-first: auto-reset prevents audio spam late at night
