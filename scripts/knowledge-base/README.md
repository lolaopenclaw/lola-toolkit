# Knowledge Base Scripts

Personal knowledge management system with semantic search using vector embeddings.

## Quick Start

```bash
# Ingest a YouTube video (auto-generates embeddings)
./ingest.sh "https://youtube.com/watch?v=VIDEO_ID" ai tutorial

# Semantic search (meaning-based)
./search.sh --semantic "prompt injection defense"

# Hybrid search (combines semantic + keyword matching)
./search.sh --hybrid "RAG architecture patterns"

# Traditional keyword search (FTS5)
./search.sh "exact keyword match"

# List all entries
./search.sh --list
```

## Architecture

- **Database:** `../../data/knowledge-base.db` (SQLite)
- **Embeddings:** Gemini `gemini-embedding-001` (3072 dimensions)
- **Search modes:**
  - **Semantic** (`--semantic`): Vector similarity (cosine distance)
  - **FTS5** (default): Full-text keyword matching
  - **Hybrid** (`--hybrid`): Weighted combination (70% semantic / 30% FTS5)

## Scripts

| Script | Purpose |
|--------|---------|
| **ingest.sh** | Ingest content from URLs (auto-generates embeddings) |
| **search.sh** | Search interface (semantic/FTS5/hybrid modes) |
| **embed.py** | Generate vector embeddings for chunks |
| **semantic-search.py** | Core semantic search engine |

## Dependencies

- Python 3 with `numpy`, `requests`
- `GOOGLE_API_KEY` environment variable (for embeddings)
- Python venv (created automatically by ingest.sh): `youtube-transcript-api`, `beautifulsoup4`, `PyPDF2`

## Technical Details

**Chunking:** ~500 words per chunk  
**Similarity:** Cosine similarity with numpy  
**Rate limits:** Exponential backoff (2s → 4s → 8s)  
**Batch processing:** 10 chunks/batch, 1s delay between batches  

## Examples

```bash
# Backfill embeddings for existing chunks
python3 embed.py

# Search with custom result limit
./search.sh --semantic --limit 10 "machine learning safety"

# Compare search modes
./search.sh "prompt injection"              # FTS5
./search.sh --semantic "prompt injection"   # Semantic
./search.sh --hybrid "prompt injection"     # Hybrid
```

## Documentation

See `../../memory/knowledge-base.md` for full details.

---

**Status:** ✅ Production Ready (Phase 2 complete — March 26, 2026)  
**Total chunks:** 132 (all embedded)
