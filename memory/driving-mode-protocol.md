# 🚗 Driving Mode Protocol (2026-03-08)

**Status:** ACTIVE - Implemented with Plan A (commands + auto-reset)

## Rules

### Manual Activation (Manu tells me)
- **Trigger phrase:** "estoy en el coche" / "estoy conduciendo" / "en el coche"
  - **Action:** Activate DRIVING MODE → respond ONLY via audio (TTS) until deactivated
  
- **Trigger phrase:** "ya estoy en casa" / "he llegado" / "ya no estoy en el coche"
  - **Action:** Deactivate DRIVING MODE → back to text-only responses

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

## Notes
- Protocol active as of 2026-03-08 19:23 (Manu driving at this time)
- User prefers responsiveness over complexity
- Safety-first: auto-reset prevents audio spam late at night
