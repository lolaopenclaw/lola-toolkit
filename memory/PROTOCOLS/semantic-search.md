# Semantic Memory Search

**Implementado:** 2026-02-21
**Stack:** LanceDB + Ollama (nomic-embed-text, 768 dims)

## Uso

```bash
# Buscar por significado
bash scripts/semantic-search.sh search "seguridad SSH"

# Más resultados
bash scripts/semantic-search.sh search "calendario eventos" --top 10

# JSON (para integración con scripts)
bash scripts/semantic-search.sh search "query" --json

# Re-indexar (tras añadir nuevos archivos de memoria)
bash scripts/semantic-search.sh index

# Estado del índice
bash scripts/semantic-search.sh status
```

## Desde Node.js

```js
node scripts/semantic-search.js search "query"
node scripts/semantic-search.js index
```

## Arquitectura

- **Chunking:** Divide archivos .md por secciones (`##`), sub-divide chunks >800 chars con 100 char overlap
- **Embeddings:** Ollama local (nomic-embed-text) via batch API (32 chunks/batch)
- **Storage:** LanceDB en `.vectordb/` (~2MB para 582 chunks)
- **Búsqueda:** Vector similarity search con deduplicación por archivo

## Archivos indexados

- Todos los `.md` en `memory/` (excepto `COLD/` y `node_modules/`)
- `MEMORY.md`, `AGENTS.md`, `TOOLS.md` del workspace raíz

## Mantenimiento

- **Re-indexar** cuando se acumulen nuevos archivos de memoria (semanal o tras cambios grandes)
- El indexado completo tarda ~2-3 min para ~60 archivos / ~580 chunks
- Requiere Ollama corriendo (`ollama serve`)

## Métricas actuales

- 59 archivos indexados
- 582 chunks
- Modelo: nomic-embed-text (768 dimensiones)
- Tamaño DB: ~2.1MB
