# TTS Investigation - 2026-03-22

## Problem Statement

OpenClaw's built-in `tts` tool was failing with:
```
"edge: Timed out; openai: no API key; elevenlabs: ElevenLabs API error (401)"
```

However, the Python `edge-tts` CLI worked perfectly from the command line.

## Root Cause Analysis

### Key Findings

1. **node-edge-tts works perfectly in standalone tests**
   - Tested with timeouts of 30s, 10s, and 5s
   - All calls completed in 280-483ms
   - Rapid succession tests (3 simultaneous calls) also succeeded
   - No network or firewall issues detected

2. **OpenClaw uses node-edge-tts (NOT the Python CLI)**
   - Source: `~/.npm-global/lib/node_modules/openclaw/node_modules/node-edge-tts`
   - Version: 1.2.10
   - Properly installed and functional

3. **Provider Fallback Chain Issue**
   - Config has `provider: "edge"` as primary
   - Default fallback order: `["edge", "openai", "elevenlabs"]`
   - When edge times out (or appears to timeout), it tries fallbacks:
     * `openai` → fails with "no API key" (no `OPENAI_API_KEY` set)
     * `elevenlabs` → fails with 401 Unauthorized
   
4. **ElevenLabs API Key Status**
   - API key exists: `sk_***REDACTED***` (stored in .env)
   - Key is valid (tested with curl)
   - Account: **FREE tier, 9997/10000 characters used** (only 3 chars remaining!)
   - This explains the 401 errors when fallback tries to use it

5. **Timeout Configuration**
   - Default TTS timeout: 30 seconds (`DEFAULT_TIMEOUT_MS$2 = 3e4`)
   - Config had NO explicit timeouts set
   - Edge-specific timeout (`edge.timeoutMs`) was not configured
   - Standalone tests complete in <500ms, so timeout shouldn't be the issue

### Why Edge Might Timeout in OpenClaw Context

The actual edge timeout is likely a **red herring**. Possible causes:

1. **First call latency**: Edge TTS might have higher latency on first connection from within OpenClaw's process
2. **Network context**: Different DNS/proxy settings when running as Gateway service vs CLI
3. **Concurrent request issues**: OpenClaw might be making concurrent TTS requests
4. **Gateway process environment**: Different environment variables, working directory, or file descriptors

However, **the real problem is the aggressive fallback behavior** combined with a nearly exhausted ElevenLabs account.

## Solution Implemented

### Configuration Changes

Updated `/home/mleon/.openclaw/openclaw.json`:

```json
"messages": {
  "tts": {
    "auto": "off",
    "provider": "edge",
    "timeoutMs": 60000,           // ← Global timeout increased to 60s
    "elevenlabs": {
      "apiKey": "${ELEVENLABS_API_KEY}",
      "voiceId": "EXAVITQu4vr4xnSDxMaL",
      "modelId": "eleven_multilingual_v2",
      "languageCode": "es"
    },
    "openai": {
      "apiKey": ""                // ← Explicitly empty to prevent fallback
    },
    "edge": {
      "enabled": true,
      "voice": "es-ES-ElviraNeural",
      "lang": "es-ES",
      "outputFormat": "audio-24khz-48kbitrate-mono-mp3",
      "timeoutMs": 60000          // ← Edge-specific timeout increased
    }
  }
}
```

### Rationale

1. **Increased timeouts** (30s → 60s) to handle any first-call latency
2. **Explicitly disabled OpenAI** with empty API key to prevent fallback attempts
3. **Preserved ElevenLabs** config but it won't be used as fallback due to OpenAI blocker
4. **Edge remains primary** and should succeed within 60s timeout

## Testing Evidence

### Standalone node-edge-tts Test Results

```
30000ms timeout: ✓ 483ms (19728 bytes)
10000ms timeout: ✓ 280ms (19728 bytes)
5000ms timeout: ✓ 311ms (19728 bytes)

Rapid succession (3 simultaneous calls):
  Call 1: ✓ 405ms
  Call 2: ✓ 421ms
  Call 3: ✓ 380ms
```

**Conclusion**: node-edge-tts is fast, reliable, and works perfectly in isolation.

## Recommendations

### Immediate Actions
1. ✅ **Config updated** with increased timeouts
2. ⚠️ **Gateway restart required** (but NOT done per instructions)
3. 🔄 **After restart**, test with: `/tts audio "Hola, esto es una prueba"`

### Future Improvements

1. **Monitor ElevenLabs usage**
   - Currently 9997/10000 characters used (FREE tier)
   - Only 3 characters remaining before hard limit
   - Consider upgrading plan or switching to OpenAI for paid fallback

2. **Add OpenAI TTS as real fallback** (optional)
   - Set `OPENAI_API_KEY` if you want a paid fallback
   - OpenAI TTS is cheaper than ElevenLabs and has better quota

3. **Consider Google Cloud Text-to-Speech**
   - Free tier: 1 million chars/month (vs ElevenLabs 10k)
   - Spanish voices available
   - Would require custom integration

4. **Investigate edge timeout in production**
   - After restart, if edge still times out, check:
     * Gateway logs during TTS call
     * Network latency to Microsoft servers
     * DNS resolution from Gateway process
     * File descriptor limits
     * Concurrent request handling

## Files Changed

- `/home/mleon/.openclaw/openclaw.json` (config updated, not committed yet)
- `/tmp/test-edge-tts.js` (test script, temporary)
- `/tmp/test-edge-timeout.js` (comprehensive test, temporary)

## Next Steps

1. **User must restart the Gateway** to apply config changes:
   ```bash
   openclaw gateway restart
   ```

2. **Test TTS after restart**:
   ```bash
   # From Telegram or CLI:
   /tts audio "Hola Manu, soy Lola. Esta es una prueba de audio."
   ```

3. **Monitor and report**:
   - If edge still times out, capture logs and investigate further
   - If edge works, consider committing config changes

## Technical Details

### Provider Order Logic

From `~/.npm-global/lib/node_modules/openclaw/dist/auth-profiles-DDVivXkv.js`:

```javascript
const TTS_PROVIDERS = ["openai", "elevenlabs", "edge"];

function resolveTtsProviderOrder(primary) {
  return [primary, ...TTS_PROVIDERS.filter((provider) => provider !== primary)];
}
```

With `provider: "edge"`, the order is: `["edge", "openai", "elevenlabs"]`

### Timeout Handling

```javascript
async function edgeTTS(params) {
  const { text, outputPath, config, timeoutMs } = params;
  await new EdgeTTS({
    voice: config.voice,
    lang: config.lang,
    outputFormat: config.outputFormat,
    saveSubtitles: config.saveSubtitles,
    proxy: config.proxy,
    rate: config.rate,
    pitch: config.pitch,
    volume: config.volume,
    timeout: config.timeoutMs ?? timeoutMs  // Uses edge.timeoutMs or global timeoutMs
  }).ttsPromise(text, outputPath);
}
```

The timeout is passed to EdgeTTS constructor, which should handle it properly.

## Documentation References

- [OpenClaw TTS Docs](https://docs.openclaw.ai/tools/tts.md)
- [node-edge-tts](https://github.com/SchneeHertz/node-edge-tts)
- [Microsoft Speech Output Formats](https://learn.microsoft.com/azure/ai-services/speech-service/rest-text-to-speech#audio-outputs)

## Conclusion

The TTS system is **fundamentally working** — node-edge-tts is functional. The errors are due to:

1. **Fallback chain hitting exhausted services** (ElevenLabs quota, no OpenAI key)
2. **Possible edge timeout in Gateway context** (needs investigation after restart)

The config changes should fix the issue by:
- Giving edge more time to complete
- Preventing wasteful fallback attempts

**Restart required to apply changes.**
