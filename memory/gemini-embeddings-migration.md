# Gemini Embeddings Migration Plan

**Status:** ⏳ Bloqueado — API key no cargada por OpenClaw
**Created:** 2026-03-21
**Priority:** Media (Ollama funciona como workaround)

## Contexto
- Gemini free tier: 1,500 req/día — sobra para nuestro uso (708 chunks + ~50-100 búsquedas/día)
- La API key funciona con curl directo (probado con `x-goog-api-key` header y `?key=` param)
- OpenClaw NO la carga al arrancar: error "API Key not found" (400)

## Investigación realizada (2026-03-21)
1. ✅ Key en `~/.openclaw/.env` como `GEMINI_API_KEY` — código busca prefix `GEMINI` para provider `google`
2. ✅ Añadido `GOOGLE_API_KEY` también — mismo resultado
3. ✅ Añadido `EnvironmentFile` en systemd drop-in — mismo resultado
4. ✅ Pasado como env var explícita en CLI — mismo resultado
5. ✅ Auth profile `google:default` existe con `mode: api_key`
6. ❌ `process.env` del gateway NO contiene ni GEMINI_API_KEY ni GOOGLE_API_KEY
7. Conclusión: `loadDotEnv()` no está cargando las vars, o el provider de embeddings las busca por otra vía

## Issue GitHub
- **Repo:** openclaw/openclaw
- **Issue:** https://github.com/openclaw/openclaw/issues/51541
- **Label:** bug

## Siguiente paso
1. Abrir issue con reproducción mínima
2. Monitorizar respuesta de la comunidad
3. Cuando haya fix, migrar (reindex ~8 min)

## Config actual (workaround)
```json
{
  "agents.defaults.memorySearch.provider": "ollama",
  "agents.defaults.memorySearch.fallback": "ollama"
}
```

## Config objetivo
```json
{
  "agents.defaults.memorySearch.provider": "gemini",
  "agents.defaults.memorySearch.fallback": "ollama"
}
```
