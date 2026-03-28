# Gemini Embeddings Migration

**Status:** ✅ Completada — 2026-03-22
**Model:** gemini-embedding-001 (3072 dims)
**Provider:** gemini (fallback: ollama)
**DB:** 714 chunks, 238 files

## Qué se hizo
1. Script custom `scripts/gemini-slow-reindex.py` — embeds chunks 1 a 1 con 3s delay
2. Respeta rate limits del free tier (~20 RPM)
3. Tiempo total: ~36 min para 714 chunks
4. 0 errores

## Rate limits Gemini free tier
- Embedding: ~5-15 RPM según modelo
- Daily quota: se agota tras ~700+ requests en ventana corta
- Se renueva: medianoche Pacific Time (9 AM Madrid hora verano)
- **Búsquedas individuales** no deberían tener problema (1 req por búsqueda)

## Cómo funciona ahora
- DB tiene embeddings de Gemini (3072 dims)
- Búsquedas: Gemini para query embedding → vector search en DB
- Si Gemini rate-limited: fallback a FTS (full-text search) → resultados por keywords
- Ollama fallback NO funciona para vector search (768 dims ≠ 3072 dims)

## Si hay que reindexar
```bash
# 1. Asegurar backup del DB actual
cp ~/.openclaw/memory/main.sqlite ~/.openclaw/memory/main.sqlite.gemini-backup

# 2. Ejecutar reindex lento
source ~/.openclaw/.env
python3 ~/.openclaw/workspace/scripts/gemini-slow-reindex.py
```

## Issue original
- GitHub: openclaw/openclaw#51541 (root cause: stale key in auth-profiles.json)
