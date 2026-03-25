# 🎙️ Voz Bidireccional OpenClaw: Resumen Ejecutivo

**TL;DR:** OpenClaw YA TIENE voz bidireccional. Usa iOS/macOS Talk Mode + Voice Wake.

---

## ✅ Solución Inmediata: Talk Mode (iOS/macOS)

**Estado:** Disponible ahora (iOS preview, macOS oficial)

**Setup:**
```bash
# 1. Config Talk Mode
cat >> ~/.openclaw/openclaw.json <<EOF
{
  "talk": {
    "voiceId": "EXAVITQu4vr4xnSDxMaL",
    "modelId": "eleven_v3",
    "silenceTimeoutMs": 1500,
    "interruptOnSpeech": true
  }
}
EOF

# 2. Config Voice Wake
mkdir -p ~/.openclaw/settings
echo '{"triggers":["ok lola","hey lola"],"updatedAtMs":'$(date +%s)000'}' > ~/.openclaw/settings/voicewake.json

# 3. Reiniciar Gateway
openclaw gateway restart
```

**Uso:**
1. Dice "Ok Lola"
2. Habla normalmente
3. Lola responde (TTS automático)
4. Loop (hands-free total)

**Costos:** ~$5-12/mes (ElevenLabs TTS)

---

## 🔧 Alternativa: Plugin `voice-call` (VoIP)

**Para qué:** Llamadas telefónicas reales (sin app)

**Setup:**
```bash
openclaw plugins install @openclaw/voice-call
# Config Twilio en openclaw.json
openclaw voicecall call --to "+34600123456" --mode conversation
```

**Costos:** ~$2.50-3/mes (uso ligero, 60 min/mes)

---

## ❌ No Viable

- **Telegram voice calls:** API no lo soporta
- **Android Talk Mode:** En desarrollo (aún no disponible)
- **WhatsApp/Discord:** Limitaciones técnicas

---

## 📊 Comparativa Rápida

| Opción | Estado | Costo/mes | Setup | Latencia |
|--------|--------|-----------|-------|----------|
| iOS/macOS Talk Mode | ✅ Ahora | $5-12 | 1h | <1.5s |
| Plugin voice-call | ✅ Ahora | $2.50-3 | 4h | ~1.5s |
| Android Talk Mode | ⏳ Futuro | $5-12 | 1h | <1.5s |
| Wake word local + Telegram | 🔧 Custom | $5-12 | 2-4 sem | ~2s |

---

## 🎯 Recomendación

**Acción inmediata:** Configurar Talk Mode en iOS/macOS (1 hora)

**Si no disponible:** Esperar iOS preview o usar voice-call plugin

**Monitorear:** Android Talk Mode release (trimestral)

---

**Documento completo:** `memory/voice-bidirectional-research.md`
