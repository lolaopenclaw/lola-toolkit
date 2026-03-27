# 📋 Preferences — Lola & Manu

## Communication

### Revisión Nocturna de Sistemas
- **TODAS las noches revisar que TODOS los sistemas funcionen:**
  - TTS (probar que genera audio real)
  - Crons (0 errores)
  - Healthchecks (todos verdes)
  - Gmail/gog auth
  - Memory search (provider correcto, no fallback)
  - Gateway (sin warnings críticos)
- Si algo falla → **arreglarlo yo sola**. No esperar a que Manu lo descubra.
- Si necesito un modelo más potente para investigar → **cambiar a Sonnet/Opus**, arreglarlo, y volver a Haiku
- **Set:** 2026-03-22 (Manu's explicit instruction — TTS falló y no estaba detectado)

### Sin Sprints — Velocidad Máxima
- **NO trabajamos por sprints ni semanas artificiales**
- Avanzar todo lo rápido que se pueda, sin pausas arbitrarias
- Solo esperar cuando hay una razón REAL:
  1. Dependencia de Manu (OAuth, decisiones, feedback)
  2. Esperar datos (que un cron se ejecute, que quota se renueve)
  3. Verificar estabilidad (dejar correr 1-2 días para confirmar)
- Si no hay dependencia → seguir adelante inmediatamente
- Fasear por dependencias, no por calendario
- **Set:** 2026-03-22 (Manu's explicit instruction)

### Escuchar Primero, Actuar Después
- **SIEMPRE leer/escuchar el mensaje COMPLETO antes de actuar**
- Analizar el orden correcto de las acciones ANTES de ejecutar nada
- Si el mensaje pide modo coche al final → activar TTS PRIMERO, luego hacer las tareas
- No lanzar herramientas hasta haber procesado todo el mensaje
- **Set:** 2026-03-22 (Manu's explicit feedback — respondí por texto cuando pidió audio)

### YouTube / Vídeos Compartidos
- **Cuando Manu comparta un enlace de YouTube, SIEMPRE:**
  1. Intentar descargar subtítulos: `yt-dlp --write-auto-sub --sub-lang es,en --skip-download`
  2. Si no hay subtítulos: descargar audio con `yt-dlp -x` y transcribir con Whisper
  3. Leer la transcripción ANTES de responder sobre el contenido del vídeo
- **NUNCA responder sobre un vídeo basándose solo en el título o metadatos**
- Herramientas: yt-dlp (instalado), openai-whisper (skill disponible)
- **Set:** 2026-03-23 (Manu's explicit feedback — respondí sin leer la transcripción)

### Sesión Principal Libre
- **SIEMPRE delegar trabajo pesado a subagentes** — la sesión principal queda libre para conversación
- Manu quiere poder dar feedback, preguntar "¿cómo va?", y que yo pueda supervisar subagentes
- Tareas grandes → subagentes. Sesión principal = canal de comunicación con Manu
- **Excepciones:** solo si no hay otra manera (tarea que requiere contexto principal)
- **Set:** 2026-03-22 (Manu's explicit instruction)

### Paralelización con Subagentes
- **SIEMPRE paralelizar tareas cuando sea posible** — usar subagentes para trabajo concurrente
- Si hay múltiples tareas independientes → lanzar en paralelo, no secuencial
- Pruebas, evaluaciones, búsquedas, procesamiento de datos → candidatos naturales para paralelismo
- **Límite:** no tumbar la VPS (monitorizar carga). Empezar con 2-3 agentes, escalar si va bien
- **Aplica a:** autoimprove, investigación, procesamiento de datos, audits, cualquier tarea divisible
- **Set:** 2026-03-22 (Manu's explicit instruction — "grabarlo a fuego")

### Proactive Completion Notifications
- **SIEMPRE avisar a Manu cuando una acción/tarea se complete** — no esperar a que pregunte
- Si Manu preguntó por algo y se resuelve luego (heartbeat, cron, proceso background): enviar aviso inmediato
- Aplica a: reparaciones, crons, procesos largos, cualquier cosa que esté pendiente
- **Set:** 2026-03-21 (Manu's explicit request)

### Telegram Reactions
- **reactionNotifications: all** — SIEMPRE activo (Manu lo quiere así)
- Manu usa emojis para dar feedback rápido sin escribir
- Config: `channels.telegram.reactionNotifications: all` Channels

### Morning Reports (Matutino)
- **Destination:** Telegram topic 24 (📊 Reportes Diarios) en grupo "Lola y Manu" (-1003768820594)
- **Time:** 10:00 Madrid (cron `cb5d3743`)
- **Content:** Sistema, Seguridad, Backups, Autoimprove Nightly, System Updates, Garmin, Estado General
- **Script:** `scripts/informe-matutino-auto.sh`
- **Set:** 2026-03-14 10:10 (Manu's request)
- **Migrated:** 2026-03-25 — Discord → Telegram topics (Manu's decision)

### Notification Schedule
- **00:00–07:00 Madrid (Quiet Hours):** NO messages to Manu unless CRITICAL (security breach, gateway down, data loss). Background work runs normally, results go to memory + pending-actions.md.
- **07:00–10:00 Madrid:** HIGH priority allowed (cron failures, security findings). LOW/MEDIUM → morning report.
- **10:00 Madrid:** Morning report via Telegram topic 24 (Reportes Diarios). Consolidates overnight work.
- **10:00+ Madrid:** Normal communication.
- **Crons deliver via topic routing** (see `memory/night-notification-protocol.md` for topic table).
- Manu can message anytime via Telegram regardless of schedule.
- **Updated:** 2026-03-25 (aligned with night-notification-protocol.md, migrated from Discord to Telegram topics)

### Driving Mode
- **Trigger in:** "estoy en el coche" (I'm in the car)
- **Output:** TTS audio via `tts` tool
- **Trigger out:** "ya estoy en casa" (I'm home now)
- **Default fallback:** Reset at 22:00 daily
- **State file:** `memory/driving-mode-state.json`

## Channels

| Channel | Purpose | Note |
|---------|---------|------|
| **Telegram** | ALL communication + reports (via topics) | ✅ PRIMARY |
| **Discord** | ❌ ELIMINADO (2026-03-26) | Bot + servidor borrados |
| **Email** | Administrative, formal | (via gog) |

### Telegram Topics (Group: Lola y Manu, -1003768820594)

**Full table:** `memory/telegram-topics.md`
**Common:** General (1) | Reportes (24) | Sistema (25) | Finanzas (26) | GitHub (27) | Salud (28) | Seguridad (29) | Tareas (30) | Surf (76)

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
