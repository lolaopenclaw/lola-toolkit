# Investigación: Comunicación de Voz Bidireccional para OpenClaw

**Fecha:** 2026-03-24  
**Autor:** Lola (subagente de investigación)  
**Contexto:** Evaluación de posibilidades para conversación de voz fluida sin botones (tipo Alexa/Google Assistant)

---

## 🎯 Resumen Ejecutivo

**Flujo actual:**  
Manu → audio a Telegram → Lola transcribe (STT) → Lola genera respuesta → TTS → Manu pulsa play

**Objetivo:**  
Comunicación fluida bidireccional sin pulsar botones, tipo asistente de voz

**Hallazgos clave:**
1. ✅ **OpenClaw YA TIENE soporte de voz bidireccional** vía companion apps (iOS/macOS con Talk Mode + Voice Wake)
2. ✅ **Existe plugin `voice-call`** para llamadas telefónicas reales (Twilio/Telnyx/Plivo)
3. ❌ **Telegram NO soporta** voice calls bot-to-user (limitación de API)
4. 🔄 **Android** tiene soporte parcial (mic manual, sin wake word por ahora)

**Recomendación:** **Plan A** (solución inmediata) es viable y ya disponible.

---

## 1. Estado del Arte (2026)

### Tecnologías para STT+TTS en Tiempo Real

#### APIs Speech-to-Speech Comerciales
- **OpenAI Realtime API** (WebSocket, latencia <400ms, tool calling mid-conversation)
- **Google Gemini Live API** (bidireccional, voz+video, baja latencia)
- **xAI Grok Voice Agent API** (conversaciones >15 min ininterrumpidas)

#### Frameworks Open Source
- **Pipecat** (Daily.co, Python, vendor-agnostic, 100% open source)
  - Integra: WebRTC, WebSocket, SIP
  - Soporta: Deepgram (STT), GPT-4 (LLM), Silero (VAD)
  - SDKs: JavaScript, React, React Native, Swift, Kotlin, C++, ESP32
- **LiveKit** (infraestructura WebRTC para streaming)
- **FastRTC** (Python, streaming de audio)
- **LLMRTC** (TypeScript, capa de infraestructura para voz+visión en tiempo real)

#### Proyectos Open Source de Asistentes de Voz
- **Rhasspy** (offline, múltiples idiomas, template-based)
- **OpenVoiceOS** (community-driven, privacidad-first, multi-dispositivo)
- **Home Assistant Voice** (Linux-Voice-Assistant project, x64/ARM64)
- **Jasper** (always-on listening, control del hogar)
- **Mycroft** (obsoleto, reemplazado por OpenVoiceOS)

### Transport Layer
Los agentes de producción en 2026 usan:
- **WebRTC** (ultra-baja latencia, P2P cuando es posible)
- **WebSockets** (streaming bidireccional, full-duplex)
- **SIP** (Session Initiation Protocol, telefonía)

### Latencia Típica
- **STT**: 50-200ms (Deepgram, Whisper API, Google)
- **LLM**: 200-800ms (streaming, depende del modelo)
- **TTS**: 100-300ms (ElevenLabs streaming, OpenAI, Cartesia)
- **Total objetivo:** <2s (conversación natural, <500ms es ideal)

---

## 2. OpenClaw: Capacidades Actuales

### ✅ Soporte Nativo de Voz Bidireccional

OpenClaw **YA TIENE** funcionalidad bidireccional completa a través de:

#### **Talk Mode** (macOS/iOS)
- **Flujo continuo:** Escucha → STT → envía a agente → recibe respuesta → TTS streaming → reproduce
- **Fases visuales:** Listening → Thinking → Speaking
- **Interrupciones:** Si el usuario habla mientras el asistente está respondiendo, detiene el playback automáticamente
- **Backend:** ElevenLabs streaming API (latencia ultra-baja, reproducción incremental)
- **Configuración:**
  ```json5
  {
    "talk": {
      "voiceId": "elevenlabs_voice_id",
      "modelId": "eleven_v3",
      "outputFormat": "pcm_44100",  // macOS/iOS, pcm_24000 en Android
      "silenceTimeoutMs": 1500,
      "interruptOnSpeech": true
    }
  }
  ```

#### **Voice Wake** (Wake Words Globales)
- **Triggers personalizables:** "openclaw", "claude", "computer" (lista global)
- **Almacenamiento:** `~/.openclaw/settings/voicewake.json`
- **Sincronización:** Cambios se propagan vía WebSocket a todos los nodos
- **Soporte:**
  - ✅ macOS (VoiceWakeRuntime)
  - ✅ iOS (VoiceWakeManager)
  - ⏳ Android (actualmente deshabilitado, usa mic manual en Voice tab)

#### **Companion Apps (Nodos)**
OpenClaw tiene apps oficiales que se conectan vía WebSocket al Gateway:

**iOS (preview interno):**
- Conexión: LAN (Bonjour) o Tailnet (unicast DNS-SD)
- Features: Canvas, Screen snapshot, Camera, Location, **Talk Mode, Voice Wake**
- Push: APNs relay-backed (oficial/TestFlight builds)

**Android (código abierto, no publicado aún):**
- Conexión: WebSocket directo al Gateway (mDNS/NSD o manual)
- Features: Canvas, Camera, Voice tab (mic on/off manual)
- **Talk Mode/Voice Wake:** Removidos de Android runtime (por ahora)
- Push: (por implementar)

**macOS app:**
- Gateway embebido o remoto
- Talk Mode: overlay siempre visible, click para stop/exit
- Voice Wake: activa Talk Mode al detectar trigger
- Menu bar: toggle Talk, Config tab con voice id + interrupt toggle

### ✅ Plugin `voice-call` (Llamadas Telefónicas Reales)

OpenClaw tiene un **plugin oficial** para llamadas de voz bidireccionales vía VoIP:

**Proveedores soportados:**
- **Twilio** (Programmable Voice + Media Streams)
- **Telnyx** (Call Control v2)
- **Plivo** (Voice API + XML transfer + GetInput speech)
- **Mock** (dev sin red)

**Instalación:**
```bash
openclaw plugins install @openclaw/voice-call
# Reiniciar Gateway
```

**Configuración:**
```json5
{
  "plugins": {
    "entries": {
      "voice-call": {
        "enabled": true,
        "config": {
          "provider": "twilio",  // o "telnyx" | "plivo" | "mock"
          "fromNumber": "+15550001234",
          "toNumber": "+15550005678",
          "twilio": {
            "accountSid": "ACxxxxxxxx",
            "authToken": "..."
          },
          "serve": {
            "port": 3334,
            "path": "/voice/webhook"
          },
          "streaming": {
            "enabled": true,
            "streamPath": "/voice/stream",
            "preStartTimeoutMs": 5000,
            "maxConnections": 128
          },
          "inboundPolicy": "allowlist",  // Para recibir llamadas
          "allowFrom": ["+34600123456"],
          "inboundGreeting": "¡Hola! ¿En qué puedo ayudarte?"
        }
      }
    }
  }
}
```

**Comandos CLI:**
```bash
openclaw voicecall status --call-id <id>
openclaw voicecall call --to "+34600123456" --message "Hola Manu" --mode notify
openclaw voicecall continue --call-id <id> --message "¿Alguna pregunta?"
openclaw voicecall end --call-id <id>
```

**Modos:**
- **notify:** Llamada unidireccional (bot habla, usuario escucha, luego cuelga)
- **conversation:** Bidireccional (STT → LLM → TTS en loop)

**Webhook security:**
- Twilio/Plivo: firma de webhook verificada automáticamente
- Telnyx: requiere `publicKey` (o env `TELNYX_PUBLIC_KEY`)
- Protección anti-replay para webhooks
- Rate limiting: `maxPendingConnections`, `maxPendingConnectionsPerIp`

**TTS para llamadas:**
- Usa configuración `messages.tts` (ElevenLabs, OpenAI, Google)
- Override específico para llamadas: `plugins.entries.voice-call.config.tts`
- **Microsoft speech NO soportado** en llamadas (necesita PCM telefónico)

**Costos típicos:**
- Twilio: ~$0.01/min (voz) + ~$0.0025/min (media streaming si se usa)
- Telnyx: ~$0.004-0.01/min (depende de región)
- Plivo: ~$0.0065-0.02/min

**Limitación:** Requiere webhook públicamente accesible (ngrok, Tailscale funnel, o dominio propio).

### ✅ Audio y Transcripción

OpenClaw tiene soporte robusto de **audio understanding**:

**Auto-detección STT (sin config):**
1. CLIs locales (si están instalados):
   - `sherpa-onnx-offline` (requiere `SHERPA_ONNX_MODEL_DIR`)
   - `whisper-cli` (whisper-cpp, modelo tiny incluido)
   - `whisper` (Python, descarga modelos automáticamente)
2. Gemini CLI (`gemini read_many_files`)
3. Proveedores con API key: OpenAI → Groq → Deepgram → Google

**Configuración manual:**
```json5
{
  "tools": {
    "media": {
      "audio": {
        "enabled": true,
        "maxBytes": 20971520,  // 20MB default
        "models": [
          { "provider": "openai", "model": "gpt-4o-mini-transcribe" },
          {
            "type": "cli",
            "command": "whisper",
            "args": ["--model", "base", "{{MediaPath}}"],
            "timeoutSeconds": 45
          }
        ],
        "echoTranscript": false,  // Si true, envía transcripción de vuelta al chat
        "echoFormat": "📝 \"{transcript}\""
      }
    }
  }
}
```

**TTS (Text-to-Speech):**
```json5
{
  "audio": {
    "tts": {
      "voiceId": "EXAVITQu4vr4xnSDxMaL",  // ElevenLabs
      "voice": "es-ES-ElviraNeural",      // Azure fallback
      "outputFormat": "audio-24khz-48kbitrate-mono-mp3"
    }
  }
}
```

**Proveedores soportados:**
- ElevenLabs (streaming, voz clonada, múltiples idiomas)
- OpenAI (alloy, echo, fable, onyx, nova, shimmer, marin)
- Google Cloud TTS (gratis hasta cierto límite)
- Azure Cognitive Services
- Piper (local, offline)

### ❌ Limitaciones Encontradas

**Telegram:**
- **NO soporta** llamadas de voz bot-to-user (limitación de API oficial)
- Bots solo pueden enviar/recibir **archivos de audio** (voice messages, hasta 50MB)
- Rate limit: 30 calls/sec para mensajes
- **No hay API** para iniciar voice calls desde bots

**Android:**
- Voice Wake deshabilitado actualmente en runtime/Settings
- Talk Mode removido (solo mic manual en Voice tab)
- Sin push notifications implementado aún
- App no publicada oficialmente (código en `apps/android/`)

---

## 3. Telegram: Limitaciones Confirmadas

### ❌ Voice Calls Bot-to-User NO Disponibles

**Hallazgos:**
- La API oficial de Telegram **NO expone** funcionalidad para que bots inicien llamadas de voz
- Bots solo pueden:
  - ✅ Enviar voice messages (archivos .ogg hasta 50MB)
  - ✅ Recibir voice messages del usuario
  - ❌ Iniciar/recibir voice calls bidireccionales

**Evidencia:**
- Búsqueda en documentación oficial (`core.telegram.org/bots/api`): no existe método `initiateVoiceCall()`
- Community reports (Latenode, Stack Overflow): confirmado que no es posible
- Voice calls en Telegram son **peer-to-peer** (user-to-user), bots excluidos

### ⚠️ Alternativas Dentro de Telegram (Limitadas)

**Voice Chats (grupos):**
- Bots NO pueden unirse a voice chats en grupos
- Solo users pueden participar

**Inline Bots:**
- No resuelven el problema de voz bidireccional
- Solo entregan contenido (texto, imágenes, etc.)

### ✅ Flujo Actual Optimizable

**Mejora posible SIN salir de Telegram:**
1. Manu envía audio → Lola transcribe
2. Lola genera respuesta
3. **TTS automático** → envía voice message de vuelta
4. **Auto-play en Telegram** (si Manu tiene auto-play enabled en settings de Telegram)

**Limitación:** Sigue siendo asíncrono (no es conversación fluida)

---

## 4. Companion Apps: Análisis Detallado

### iOS (Status: Internal Preview)

**Conexión:**
- Gateway: WebSocket (LAN vía Bonjour o Tailnet vía unicast DNS-SD)
- Discovery: `_openclaw-gw._tcp` (mDNS o DNS-SD zone, ej. `openclaw.internal.`)
- Manual: host/port fallback

**Pairing:**
```bash
openclaw gateway --port 18789
# En iOS app: Settings → descubre gateway o manual host
openclaw devices list
openclaw devices approve <requestId>
```

**Features:**
- ✅ **Talk Mode:** Listening → STT → LLM → TTS streaming → reproduce
- ✅ **Voice Wake:** "openclaw", "claude", etc. (configurable globalmente)
- ✅ Canvas (WKWebView, `node.invoke canvas.navigate`)
- ✅ Camera capture (`camera.snap`, `camera.clip`)
- ✅ Screen snapshot
- ✅ Location
- ✅ Push: APNs relay-backed (oficial/TestFlight builds)

**Auth Flow (Relay):**
1. iOS → Gateway: pairing + `gateway.identity.get`
2. iOS → Relay: App Attest + receipt + gateway identity
3. Relay → devuelve handle + send grant delegado a ese gateway
4. Gateway → Relay: firma con device identity, relay envía a APNs
5. Protección: solo builds oficiales, solo gateway que emparejó puede enviar push

**Requisitos:**
- Gateway corriendo (macOS, Linux, o Windows WSL2)
- Red: LAN o Tailnet (Tailscale recomendado para cross-network)

### Android (Status: Open Source, No Publicado)

**Conexión:**
- WebSocket directo (NSD/mDNS o manual host/port)
- Foreground service (notificación persistente)
- Auto-reconnect: última configuración manual o gateway descubierto

**Pairing:**
```bash
openclaw devices list
openclaw devices approve <requestId>
openclaw nodes status
```

**Features:**
- ✅ Canvas (WebView, live-reload)
- ✅ Camera (`camera.snap`, `camera.clip`)
- ⚠️ Voice: Mic on/off manual en Voice tab (sin Talk Mode ni Voice Wake)
  - STT: Deepgram/Whisper/Google (según config Gateway)
  - TTS: ElevenLabs (si configurado) o system TTS fallback
  - Reproduce: `pcm_24000` (AudioTrack streaming)
- ✅ Device: `device.status`, `device.info`, `device.permissions`, `device.health`
- ✅ Notifications: `notifications.list`, `notifications.actions`
- ✅ Photos: `photos.latest`
- ✅ Contacts: `contacts.search`, `contacts.add`
- ✅ Calendar: `calendar.events`, `calendar.add`
- ✅ Call log: `callLog.search`
- ✅ SMS: `sms.search`
- ✅ Motion: `motion.activity`, `motion.pedometer`

**Limitaciones:**
- ❌ Talk Mode removido de Android UX/runtime
- ❌ Voice Wake deshabilitado (no hay wake word detection)
- ❌ Push notifications (aún no implementado)

**Build:**
```bash
cd apps/android
./gradlew :app:assemblePlayDebug
# Requiere Java 17 + Android SDK
```

### macOS App (Status: Oficial, Más Completo)

**Gateway:**
- Embebido (bundled) o remoto (conecta a otro host)
- launchd service (daemon)

**Features:**
- ✅ **Talk Mode overlay:** Always-on mientras activo, click cloud para stop
- ✅ **Voice Wake:** Activa Talk Mode al detectar trigger
- ✅ Menu bar: toggle Talk, Config tab
- ✅ Canvas: live-reload de `~/.openclaw/workspace/canvas/index.html`
- ✅ Peekaboo Bridge (window/screen control)
- ✅ Voice overlay (UI de Talk Mode)
- ✅ WebChat (Control UI en navegador)

**Permisos:**
- Speech + Microphone (System Settings → Privacy & Security)

**Config Talk Mode:**
```json5
{
  "talk": {
    "voiceId": "elevenlabs_voice_id",
    "modelId": "eleven_v3",
    "silenceTimeoutMs": 1500,
    "interruptOnSpeech": true
  }
}
```

**UX de Talk Mode:**
- **Listening:** cloud pulsa con nivel de mic
- **Thinking:** animación de hundimiento
- **Speaking:** anillos radiantes
- Click cloud: detiene habla
- Click X: sale de Talk Mode

---

## 5. Soluciones Híbridas: Comparativa

### Opción A: iOS/macOS App con Talk Mode (✅ RECOMENDADO)

**Estado:** ✅ **Disponible ahora** (iOS preview interno, macOS oficial)

**Ventajas:**
- ✅ Soporte nativo bidireccional (Talk Mode)
- ✅ Wake words configurables (Voice Wake)
- ✅ Interrupciones automáticas (interrupt on speech)
- ✅ Latencia ultra-baja (ElevenLabs streaming PCM)
- ✅ Sin costos recurrentes (usa infraestructura existente)
- ✅ Integración completa con OpenClaw (Canvas, Camera, etc.)
- ✅ Privacidad: tráfico directo Gateway ↔ Node (LAN o Tailnet)

**Desventajas:**
- ⚠️ iOS en preview (no publicado en App Store)
- ⚠️ Requiere compilar app Android si se quiere usar ahí (y aún sin Talk Mode)
- ⚠️ Necesita Gateway corriendo (pero ya lo tienes en VPS)

**Implementación:**
1. Gateway ya corriendo en VPS
2. iOS app: conectar vía Tailnet (unicast DNS-SD)
3. Configurar Talk Mode (voice id, silence timeout, interrupt)
4. Configurar Voice Wake ("Ok Lola" o similar)
5. ¡Listo! Conversación fluida sin botones

**Tiempo estimado:** 0-1 hora (configuración)

---

### Opción B: Plugin `voice-call` (Llamadas VoIP)

**Estado:** ✅ **Disponible ahora**

**Ventajas:**
- ✅ Llamadas telefónicas reales (funciona desde cualquier móvil)
- ✅ Soporte bidireccional (STT → LLM → TTS en loop)
- ✅ Inbound calls (allowlist por número)
- ✅ Tool calling mid-conversation
- ✅ No requiere app especial (solo teléfono)

**Desventajas:**
- ❌ Costo recurrente (~$0.01/min con Twilio)
- ❌ Requiere webhook público (ngrok, Tailscale funnel, o dominio)
- ❌ Latencia ligeramente mayor (red telefónica)
- ⚠️ Ancho de banda: ~100KB/min (G.711 codec, mínimo)

**Implementación:**
1. Instalar plugin: `openclaw plugins install @openclaw/voice-call`
2. Cuenta Twilio (trial gratis para testing)
3. Configurar webhook público (ej. Tailscale funnel)
4. Config `openclaw.json` (provider, numbers, webhook)
5. Test: `openclaw voicecall call --to "+34600123456" --message "Hola" --mode conversation`

**Tiempo estimado:** 2-4 horas (setup inicial)

**Costos estimados:**
- Twilio: $0.01/min + $1/mes por número (España ~$1/mes)
- Telnyx: $0.004-0.01/min + $0.40/mes por número
- Ancho de banda VPS: ~6MB/hora conversación (negligible)

---

### Opción C: Wake Word Local + Telegram Audio (Híbrido)

**Estado:** 🔧 **Requiere desarrollo custom**

**Concepto:**
1. App móvil custom (React Native, Flutter, o nativa)
2. Wake word detection local (ej. Porcupine, Snowboy)
3. Al detectar "Ok Lola" → graba audio → envía a Telegram
4. Gateway procesa como siempre → TTS → responde en Telegram

**Ventajas:**
- ✅ Sin costos recurrentes
- ✅ Aprovecha infraestructura Telegram existente
- ✅ Wake word local (privacidad)

**Desventajas:**
- ❌ Requiere app custom (desarrollo significativo)
- ❌ Sigue siendo asíncrono (no conversación fluida)
- ❌ No resuelve "pulsar play" (a menos que app auto-reproduzca)
- ❌ Fragmentación: necesitas mantener app iOS + Android

**Tiempo estimado:** 2-4 semanas (desarrollo + testing)

**Recomendación:** ❌ **No vale la pena** (Opción A es mejor y ya existe)

---

### Opción D: WhatsApp/Discord Voice Channels

**Estado:** ❌ **No viable**

**WhatsApp:**
- Bots NO pueden participar en llamadas de voz
- WhatsApp Business API no expone voice calls

**Discord:**
- Bots pueden unirse a voice channels (✅)
- Pueden enviar audio (✅)
- **Problema:** Recibir audio de usuarios requiere privileged intents + bot verification
- **Problema:** Discord voice es de baja calidad para transcripción (Opus codec, compresión agresiva)

**Recomendación:** ❌ **No viable** (limitaciones técnicas + UX pobre)

---

### Opción E: Home Assistant Voice / Rhasspy

**Estado:** 🤔 **Posible si Manu usa smart home**

**Concepto:**
- Rhasspy/Home Assistant Voice: asistente offline
- Integración: wake word → captura audio → envía a OpenClaw Gateway (API call)
- Gateway procesa → devuelve TTS → Rhasspy reproduce

**Ventajas:**
- ✅ Offline wake word detection
- ✅ Privacidad total (no sale de red local)
- ✅ Hardware: Raspberry Pi, ESP32, o x64/ARM64

**Desventajas:**
- ❌ Requiere hardware adicional (Pi, ESP32, o dedicar laptop)
- ❌ Setup complejo (instalación Rhasspy, configuración, testing)
- ❌ No es móvil (salvo que montes ESP32 en dispositivo portable)

**Pregunta:** ¿Manu tiene/quiere smart home setup?

**Si NO:** ❌ **Descartado** (overkill para caso de uso)  
**Si SÍ:** 🔧 **Considerar** como proyecto a medio plazo (1-3 meses)

---

## 6. Arquitectura Propuesta (Si Viable)

### Flujo Óptimo: iOS/macOS Talk Mode

```
┌─────────────────────────────────────────────────────────────┐
│ Cliente (iOS/macOS app con Talk Mode)                       │
├─────────────────────────────────────────────────────────────┤
│ 1. Voice Wake detecta trigger ("Ok Lola")                   │
│ 2. Activa Talk Mode → Listening state                       │
│ 3. Usuario habla → STT local o remoto (Deepgram/Whisper)   │
│ 4. Transcript → WebSocket → Gateway                         │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ Gateway (VPS corriendo OpenClaw)                            │
├─────────────────────────────────────────────────────────────┤
│ 5. Recibe transcript vía chat.send (session: main)          │
│ 6. Agent procesa (Pi/Claude) → genera respuesta             │
│ 7. TTS → ElevenLabs streaming API                           │
│ 8. Audio chunks → WebSocket → cliente                       │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ Cliente (playback)                                           │
├─────────────────────────────────────────────────────────────┤
│ 9. Recibe audio → reproduce incrementalmente (PCM streaming)│
│ 10. Si usuario interrumpe → detiene playback automático     │
│ 11. Loop: vuelve a Listening state                          │
└─────────────────────────────────────────────────────────────┘
```

**Latencia total:**
- STT: ~100-200ms (Deepgram)
- Gateway → Agent → TTS: ~300-800ms (streaming)
- TTS → Audio chunks: ~100-300ms (ElevenLabs)
- **Total:** <1.5s (conversación natural ✅)

**Interrupciones:**
- Si usuario habla mientras assistant está en Speaking state:
  - Cliente detecta voz → detiene playback
  - Registra timestamp de interrupción
  - Envía interrupción al Gateway (para próximo prompt context)
  - Vuelve a Listening state

**Manejo de errores:**
- Timeout en STT → retry o mensaje de error
- Gateway unreachable → notificación + auto-reconnect
- TTS falla → fallback a system TTS local

---

### Flujo Alternativo: Plugin `voice-call` (VoIP)

```
┌─────────────────────────────────────────────────────────────┐
│ Usuario (teléfono cualquiera)                                │
├─────────────────────────────────────────────────────────────┤
│ 1. Manu llama a +34XXXXXXXXX (número Twilio de Lola)        │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ Twilio → Webhook → Gateway                                   │
├─────────────────────────────────────────────────────────────┤
│ 2. Inbound call → verifica allowFrom                         │
│ 3. Si permitido → responde TwiML (greeting + Gather)         │
│ 4. Abre media stream (WebSocket bidireccional)              │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ Gateway (voice-call plugin)                                  │
├─────────────────────────────────────────────────────────────┤
│ 5. Recibe audio raw (µ-law PCM) → convierte a WAV           │
│ 6. STT (Deepgram/Whisper) → transcript                      │
│ 7. Agent procesa → genera respuesta                         │
│ 8. TTS (ElevenLabs) → audio PCM                             │
│ 9. Convierte a µ-law → envía a Twilio media stream          │
│ 10. Loop: espera próximo input del usuario                  │
└─────────────────────────────────────────────────────────────┘
```

**Latencia total:**
- Red telefónica: ~50-100ms
- STT + LLM + TTS: ~500-1200ms
- **Total:** ~1-1.5s (aceptable para conversación)

**Costos por conversación de 5 min:**
- Twilio voice: $0.05
- Media streaming: $0.0125
- STT (Deepgram): ~$0.03
- TTS (ElevenLabs): ~$0.10-0.20 (depende de chars)
- **Total:** ~$0.20-0.30 por conversación de 5 min

---

## 7. Costos Estimados (Comparativa)

### Opción A: iOS/macOS Talk Mode

| Concepto | Costo |
|----------|-------|
| Gateway (VPS ya existente) | $0 (ya corriendo) |
| iOS app | $0 (preview gratuito) |
| STT (Deepgram/Whisper API) | $0.006/min (~$0.30/mes uso ligero) |
| TTS (ElevenLabs) | $5-11/mes (starter tier) |
| Ancho de banda VPS | Negligible (~10MB/hora) |
| **TOTAL MENSUAL** | **~$5-12/mes** |

**Nota:** Si usas Whisper local (offline), STT es gratis.

---

### Opción B: Plugin `voice-call` (VoIP)

| Concepto | Costo |
|----------|-------|
| Twilio número (España) | ~$1/mes |
| Llamadas (inbound/outbound) | $0.01/min |
| Media streaming | $0.0025/min |
| STT (Deepgram) | $0.006/min |
| TTS (ElevenLabs) | ~$0.02-0.04/min de audio generado |
| **Ejemplo:** 60 min/mes conversación | **~$1.50/mes** |
| **TOTAL MENSUAL** (uso ligero) | **~$2.50-3/mes** |

**Nota:** Si Manu no usa frecuentemente, este es el más barato operacionalmente.

---

### Opción C: Wake Word Local + Telegram

| Concepto | Costo |
|----------|-------|
| Desarrollo app custom | $0 (Manu lo hace) o $2000-5000 (contractor) |
| STT (Telegram → Gateway) | $0.006/min |
| TTS (ElevenLabs) | $5-11/mes |
| Mantenimiento app | Tiempo de Manu (debugging, updates) |
| **TOTAL INICIAL** | **$2000-5000 o 2-4 semanas** |
| **TOTAL MENSUAL** | **~$5-12/mes** |

**Recomendación:** ❌ **No vale la pena** (Opción A es gratis y mejor)

---

### Opción E: Home Assistant Voice

| Concepto | Costo |
|----------|-------|
| Hardware (Raspberry Pi 4) | ~$60-80 |
| Mic + Speaker | ~$20-50 |
| SD card + case | ~$20 |
| Software (Rhasspy/HA) | $0 (open source) |
| Setup time | 1-3 días (learning curve) |
| STT/TTS | $0 (offline con Piper + faster-whisper) |
| **TOTAL INICIAL** | **~$100-150** |
| **TOTAL MENSUAL** | **$0** (después de setup) |

**Nota:** Solo viable si Manu quiere smart home + proyecto DIY.

---

## 8. Proyectos Similares (Benchmarks)

### Comerciales

**Vapi.ai:**
- Plataforma managed para voice agents
- WebRTC + STT/TTS/LLM integrado
- Pricing: $0.05-0.10/min
- **Problema:** Vendor lock-in, no self-hosted

**Bland.ai:**
- AI phone agents (outbound calls)
- Twilio backend
- Pricing: $0.09-0.12/min
- **Problema:** No soporta inbound real-time bidireccional

**Retell AI:**
- Voice agent platform (WebRTC + telephony)
- Low-latency (<1s)
- Pricing: $0.10-0.20/min
- **Problema:** No self-hosted

### Open Source

**Pipecat (Daily.co):**
- ✅ Framework Python para voice agents
- ✅ Vendor-agnostic (soporta múltiples STT/TTS/LLM)
- ✅ WebRTC, WebSocket, SIP
- ✅ SDKs: JavaScript, React, Swift, Kotlin, etc.
- ✅ 100% open source (MIT license)
- **Stack típico:** Deepgram (STT) + GPT-4 (LLM) + ElevenLabs (TTS)
- **Latencia:** <500ms en producción
- **Problema:** Requiere integración custom con OpenClaw (no plug-and-play)

**Rhasspy:**
- ✅ Offline, privacidad-first
- ✅ Template-based intents
- ✅ Múltiples idiomas
- ❌ No es conversacional (comando-respuesta, no diálogo libre)
- ❌ Wake word detection básico

**OpenVoiceOS:**
- ✅ Community-driven
- ✅ Multi-dispositivo (Pi, x64, ARM64)
- ✅ Skills extensibles
- ❌ Learning curve alto
- ❌ No integra fácilmente con LLMs externos

**Home Assistant Voice:**
- ✅ Integración con HA ecosystem
- ✅ Wake word + STT + TTS local
- ✅ ESP32 support
- ❌ Limitado a comandos de smart home (no conversación libre)

**Comparación con OpenClaw:**
- OpenClaw + iOS Talk Mode ≈ **funcionalidad de Vapi.ai self-hosted**
- OpenClaw + voice-call plugin ≈ **Bland.ai self-hosted**
- Ventaja OpenClaw: **ya existe, ya funciona, sin vendor lock-in**

---

## 9. Evaluación de Viabilidad

### ✅ Fácil (0-1 semana): **iOS/macOS Talk Mode**

**¿Qué hacer?**
1. Descargar iOS app (preview interno) o usar macOS app (oficial)
2. Conectar a Gateway vía Tailnet (ya configurado)
3. Config Talk Mode en `openclaw.json`:
   ```json5
   {
     "talk": {
       "voiceId": "EXAVITQu4vr4xnSDxMaL",  // Voice id actual de Manu
       "modelId": "eleven_v3",
       "silenceTimeoutMs": 1500,
       "interruptOnSpeech": true
     }
   }
   ```
4. Config Voice Wake:
   ```bash
   # Desde iOS app o macOS app, editar triggers
   # O manualmente:
   echo '{"triggers":["ok lola","hey lola","lola"],"updatedAtMs":'$(date +%s)000'}' > ~/.openclaw/settings/voicewake.json
   ```
5. Test: decir "Ok Lola, ¿qué tiempo hace hoy?" y conversar

**Ganancia:**
- ✅ Conversación fluida sin pulsar botones
- ✅ Wake word para activar
- ✅ Interrupciones automáticas
- ✅ Latencia <1.5s

**Esfuerzo:** 1-2 horas configuración

---

### ⚙️ Medio (2-4 semanas): **Plugin `voice-call` (VoIP)**

**¿Qué hacer?**
1. Cuenta Twilio (trial gratis, luego pay-as-you-go)
2. Comprar número español (~$1/mes)
3. Configurar webhook público:
   - Opción A: Tailscale funnel (gratis, pero expone gateway)
   - Opción B: ngrok (gratis tier, URL cambia)
   - Opción C: dominio propio + proxy (más estable)
4. Instalar plugin: `openclaw plugins install @openclaw/voice-call`
5. Config `openclaw.json` (ver sección 2)
6. Test inbound: llamar desde móvil de Manu
7. Test outbound: `openclaw voicecall call --to "+34600123456" --mode conversation`

**Ganancia:**
- ✅ Funciona desde cualquier teléfono (no requiere app)
- ✅ Inbound/outbound
- ✅ Conversación bidireccional
- ❌ Costo recurrente (~$0.01/min)

**Esfuerzo:** 4-8 horas setup inicial + troubleshooting

---

### 🚫 Difícil (1-3 meses): **Voice Call Full-Duplex Custom**

**Concepto:**
- App móvil custom (React Native o nativa)
- WebRTC directo a Gateway
- Wake word local (Porcupine)
- Streaming bidireccional (audio chunks en tiempo real)
- Custom backend en Gateway para manejar WebRTC signaling

**Ganancia:**
- ✅ Máximo control
- ✅ Sin costos recurrentes (después de desarrollo)
- ✅ Latencia mínima (<500ms)

**Esfuerzo:**
- Desarrollo app: 2-4 semanas
- Backend Gateway: 1-2 semanas
- Testing + debugging: 1-2 semanas
- **Total:** 1-3 meses

**Recomendación:** ❌ **No vale la pena** (Opción A ya existe y es mejor)

---

## 10. Recomendación Final

### 🎯 **Plan A: iOS/macOS Talk Mode (RECOMENDADO)**

**Estado:** ✅ **Solución inmediata disponible**

**Por qué:**
1. ✅ **Ya existe** (no requiere desarrollo)
2. ✅ **Funciona ahora** (iOS preview, macOS oficial)
3. ✅ **Bidireccional fluido** (Talk Mode + Voice Wake)
4. ✅ **Sin costos recurrentes** significativos (~$5-12/mes TTS)
5. ✅ **Privacidad** (tráfico directo Gateway ↔ Node via Tailnet)
6. ✅ **Integración completa** (Canvas, Camera, etc.)
7. ✅ **Latencia óptima** (<1.5s conversación)

**Implementación:**
```bash
# 1. Configurar Talk Mode
cat >> ~/.openclaw/openclaw.json <<EOF
{
  "talk": {
    "voiceId": "EXAVITQu4vr4xnSDxMaL",
    "modelId": "eleven_v3",
    "outputFormat": "pcm_44100",
    "silenceTimeoutMs": 1500,
    "interruptOnSpeech": true
  }
}
EOF

# 2. Configurar Voice Wake
mkdir -p ~/.openclaw/settings
echo '{"triggers":["ok lola","hey lola","lola"],"updatedAtMs":'$(date +%s)000'}' > ~/.openclaw/settings/voicewake.json

# 3. Reiniciar Gateway
openclaw gateway restart

# 4. Conectar iOS app (preview) o macOS app
# 5. Test: "Ok Lola, ¿qué tiempo hace hoy?"
```

**Próximos pasos:**
1. Solicitar acceso a iOS preview (si aún no lo tiene)
2. Instalar TestFlight build
3. Conectar vía Tailnet a Gateway VPS
4. Probar Talk Mode + Voice Wake
5. Ajustar `silenceTimeoutMs` y `voiceId` según preferencia

---

### 🔧 **Plan B: Plugin `voice-call` (Alternativa VoIP)**

**Estado:** ✅ **Disponible, requiere setup**

**Cuándo usarlo:**
- Si Manu prefiere usar teléfono normal (sin app)
- Si iOS preview no está disponible todavía
- Si quiere inbound calls (ej. llamar a Lola desde cualquier lugar)

**Implementación:**
```bash
# 1. Instalar plugin
openclaw plugins install @openclaw/voice-call

# 2. Configurar Twilio (cuenta + número)
# https://www.twilio.com/console

# 3. Config openclaw.json (ver sección 2 para detalles)

# 4. Exponer webhook (Tailscale funnel o ngrok)
openclaw voicecall expose --mode funnel

# 5. Test
openclaw voicecall call --to "+34600123456" --message "Hola Manu" --mode conversation
```

**Costos:** ~$2.50-3/mes (uso ligero, 60 min/mes)

---

### 📊 **Plan C: Monitorear Tendencias**

**Si ninguna solución es perfecta ahora:**

**¿Qué monitorear?**
1. **Android Talk Mode:** ¿Cuándo se habilitará en companion app?
2. **iOS App Store release:** ¿Cuándo saldrá públicamente?
3. **OpenAI Realtime API:** ¿OpenClaw integrará nativamente?
4. **Gemini Live API:** ¿Soporte nativo en OpenClaw?
5. **Pipecat integration:** ¿Alguien construirá bridge OpenClaw ↔ Pipecat?

**Frecuencia de revisión:**
- **Semanal:** Changelog de OpenClaw (`openclaw update --check`)
- **Mensual:** Revisar GitHub issues/PRs sobre voice features
- **Trimestral:** Re-evaluar estado del arte (APIs nuevas, frameworks)

**Cómo automatizar:**
```bash
# Añadir a cron (semanal)
0 9 * * 1 openclaw update --check && openclaw doctor
```

---

## 📝 Conclusiones

### Hallazgos Clave

1. **OpenClaw ya tiene voz bidireccional** vía iOS/macOS Talk Mode (✅)
2. **Plugin voice-call disponible** para VoIP (Twilio/Telnyx/Plivo) (✅)
3. **Telegram NO soporta** voice calls bot-to-user (❌)
4. **Android en desarrollo** (sin Talk Mode/Voice Wake por ahora) (⏳)
5. **Costos razonables:** $5-12/mes (Talk Mode) o $2.50-3/mes (VoIP ligero)

### Respuesta a Preguntas Iniciales

**¿Existe solución lista para usar?**  
✅ **SÍ:** iOS/macOS Talk Mode + Voice Wake

**¿Requiere desarrollo custom?**  
❌ **NO** (Plan A usa features existentes)

**¿Merece la pena ahora?**  
✅ **SÍ** (Plan A es inmediato y sin fricción)

**¿O esperar?**  
⏳ **Opcional:** Esperar a Android Talk Mode si Manu usa OnePlus como dispositivo primario

### UX de Manu: ¿Realmente lo Necesita?

**Flujo actual:**
- Envía audio Telegram → espera respuesta texto/TTS → pulsa play
- **Fricción:** 2 taps (grabar + play)

**Flujo propuesto (Plan A):**
- Dice "Ok Lola" → habla → escucha respuesta → loop
- **Fricción:** 0 taps (completamente hands-free)

**Ganancia real:**
- ✅ Útil mientras conduce (driving mode mejorado)
- ✅ Útil cocinando, haciendo ejercicio, etc. (manos ocupadas)
- ✅ Conversación más natural (no "grabar mensaje" mental model)

**¿Vale la pena?**  
✅ **SÍ**, especialmente para driving mode y multitasking

---

## 🚀 Próximos Pasos Recomendados

### Inmediato (esta semana)

1. **Verificar acceso iOS preview:** ¿Manu tiene TestFlight build?
2. **Si no:** Usar **macOS app** para testing inicial (en laptop)
3. **Configurar Talk Mode** (ver config arriba)
4. **Configurar Voice Wake** (`ok lola`, `hey lola`)
5. **Test rápido:** Laptop → "Ok Lola, ¿qué hora es?"

### Corto plazo (1-2 semanas)

1. **Si iOS preview disponible:**
   - Instalar en iPhone
   - Conectar vía Tailnet
   - Probar Talk Mode móvil
   - Ajustar settings (voice id, silence timeout)
2. **Si iOS no disponible aún:**
   - Considerar **Plan B** (voice-call plugin) para móvil
   - O esperar a release oficial iOS app

### Medio plazo (1-3 meses)

1. **Android Talk Mode:** Monitorear desarrollo (GitHub issues)
2. **Evaluar OpenAI Realtime API:** ¿OpenClaw lo integrará nativamente?
3. **Re-evaluar costos:** ¿ElevenLabs usage está dentro de budget?
4. **Optimizar:** ¿Whisper local para reducir costos STT?

---

## 📚 Referencias

### Documentación OpenClaw
- [Talk Mode](https://docs.openclaw.ai/nodes/talk.md)
- [Voice Wake](https://docs.openclaw.ai/nodes/voicewake.md)
- [Audio & Voice Notes](https://docs.openclaw.ai/nodes/audio.md)
- [Voice Call Plugin](https://docs.openclaw.ai/plugins/voice-call)
- [iOS App](https://docs.openclaw.ai/platforms/ios.md)
- [Android App](https://docs.openclaw.ai/platforms/android.md)

### Proyectos Similares
- [Pipecat](https://github.com/pipecat-ai/pipecat) (framework Python, WebRTC)
- [Rhasspy](https://rhasspy.readthedocs.io/) (offline voice assistant)
- [OpenVoiceOS](https://github.com/openVoiceOS) (community voice AI)
- [Home Assistant Voice](https://www.home-assistant.io/voice_control/)

### APIs Speech-to-Speech
- [OpenAI Realtime API](https://platform.openai.com/docs/guides/realtime)
- [Gemini Live API](https://ai.google.dev/gemini-api/docs/live)
- [Deepgram STT](https://deepgram.com/)
- [ElevenLabs TTS](https://elevenlabs.io/)

### Stack Técnico
- WebRTC: [WebRTC.ventures](https://webrtc.ventures/)
- Twilio: [Programmable Voice](https://www.twilio.com/docs/voice)
- Telnyx: [Call Control v2](https://developers.telnyx.com/docs/api/v2/call-control)

---

**Documento generado:** 2026-03-24 09:39 CET  
**Tiempo de investigación:** ~35 minutos  
**Próxima revisión sugerida:** Cuando Android Talk Mode esté disponible o iOS app salga públicamente

---

_Fin del documento_
