# Knowledge Base System

Personal knowledge management system with RAG capabilities for OpenClaw workspace.

## Overview

The knowledge base ingests content from various sources (articles, YouTube videos, PDFs) and provides **semantic search** using vector embeddings alongside traditional full-text search.

## Architecture

### Database (`data/knowledge-base.db`)

SQLite database with:
- **entries table**: Stores metadata and full content
- **chunks table**: Content split into ~500 word segments (ready for embeddings)
- **entries_fts**: FTS5 virtual table for full-text search

### Scripts

Located in `scripts/knowledge-base/`:

1. **ingest.sh** - Ingest content from URLs (auto-generates embeddings)
2. **search.sh** - Search with FTS5, semantic, or hybrid modes
3. **embed.py** - Generate vector embeddings for chunks (Gemini API)
4. **semantic-search.py** - Core semantic search engine

## Usage

### Ingest Content

```bash
# Article
./scripts/knowledge-base-ingest.sh "https://example.com/article" tag1 tag2

# YouTube video
./scripts/knowledge-base-ingest.sh "https://youtube.com/watch?v=VIDEO_ID"

# PDF
./scripts/knowledge-base-ingest.sh "https://example.com/paper.pdf"
```

**Source type detection:**
- YouTube: `youtube.com`, `youtu.be`
- PDF: URLs ending in `.pdf`
- Tweet: `twitter.com`, `x.com` (WIP)
- Article: Everything else (HTML extraction)

### Search

```bash
# Semantic search (default: uses vector embeddings)
./scripts/knowledge-base/search.sh --semantic "query terms"

# Full-text search (FTS5, classic keyword matching)
./scripts/knowledge-base/search.sh "query terms"

# Hybrid mode (combines semantic + FTS5 with weighted scoring)
./scripts/knowledge-base/search.sh --hybrid "query terms"

# List all entries
./scripts/knowledge-base/search.sh --list

# Filter by tag (FTS5 only)
./scripts/knowledge-base/search.sh "query" --tag python

# Custom result limit
./scripts/knowledge-base/search.sh --semantic --limit 10 "query"
```

**Search modes:**
- **Semantic** (`--semantic`): Uses Gemini embeddings + cosine similarity for meaning-based search
- **FTS5** (default): Classic keyword matching (exact terms, fast)
- **Hybrid** (`--hybrid`): Combines both with 70% semantic / 30% FTS5 weighting

**Search returns:**
- Top 5 results ranked by relevance (or similarity score for semantic)
- Title, URL, source type
- Date saved, entry ID, chunk ID
- Highlighted snippet (FTS5) or text preview (semantic)
- Tags (if any)
- **Similarity score** (semantic/hybrid modes only)

## Features

### Implemented ✅

- Multi-source ingestion (article, YouTube, PDF)
- Auto source type detection
- Content chunking (~500 words)
- **Vector embeddings** (Gemini `gemini-embedding-001`, 3072 dimensions)
- **Semantic search** with cosine similarity
- **Hybrid search** (semantic + FTS5 weighted combination)
- FTS5 full-text search
- Tag support
- Summary generation
- Duplicate URL detection
- Automatic embedding generation on ingest

### Future Enhancements 🔮

- Twitter/X thread extraction
- Auto-tagging using LLM
- Related content suggestions
- Export to Markdown
- Query expansion for better semantic matching
- Multi-modal embeddings (images, audio)

## Dependencies

Python packages (system or venv):
- `youtube-transcript-api` - YouTube transcripts
- `beautifulsoup4` - HTML parsing
- `requests` - HTTP client (also for Gemini API)
- `PyPDF2` - PDF text extraction
- `numpy` - Vector operations (cosine similarity)

**API requirements:**
- `GOOGLE_API_KEY` environment variable (for Gemini embeddings)
- Read from `~/.openclaw/.env` or workspace `.env`

## Database Schema

```sql
entries (
    id, url [unique], title, source_type,
    content_text, summary, tags [JSON],
    created_at, updated_at
)

chunks (
    id, entry_id, chunk_text, chunk_index,
    embedding [BLOB for future use]
)

entries_fts (
    FTS5 virtual table on title, content, summary, tags
)
```

## Integration Points

- **Memory**: This file (`memory/knowledge-base.md`)
- **TOOLS.md**: Reference added
- **Autoimprove**: Could analyze saved content for patterns
- **Subagents**: Could use knowledge base for context

## Examples

```bash
# Save a technical article (auto-generates embeddings)
./scripts/knowledge-base/ingest.sh "https://blog.example.com/rag-tutorial" rag ai vector-db

# Semantic search (meaning-based, uses embeddings)
./scripts/knowledge-base/search.sh --semantic "how to defend against prompt injection"

# Keyword search (exact term matching)
./scripts/knowledge-base/search.sh "prompt injection defense"

# Hybrid search (best of both)
./scripts/knowledge-base/search.sh --hybrid "RAG architecture patterns"

# List everything
./scripts/knowledge-base/search.sh --list

# Backfill embeddings for existing chunks
python3 scripts/knowledge-base/embed.py
```

## Maintenance

- Database location: `data/knowledge-base.db`
- Python venv: `scripts/knowledge-base/venv/` (for ingestion only)
- Embeddings: Stored as BLOB (float32 array, 3072 dims)
- To reset: `rm data/knowledge-base.db && sqlite3 data/knowledge-base.db < scripts/knowledge-base/schema.sql`
- Re-generate all embeddings: `python3 scripts/knowledge-base/embed.py`

## Technical Details

### Embeddings

- **Model**: `gemini-embedding-001` (Google Generative AI)
- **Dimensions**: 3072 (float32 vectors)
- **Storage**: Binary BLOB in SQLite (`struct.pack`)
- **Similarity**: Cosine similarity (numpy)
- **Rate limits**: Handled with exponential backoff (2s → 4s → 8s)
- **Batch processing**: 10 chunks/batch, 1s delay between batches

### Search Algorithms

**Semantic:**
1. Generate query embedding via Gemini API
2. Fetch all chunk embeddings from DB
3. Calculate cosine similarity for each
4. Return top N by similarity score

**FTS5:**
- Standard SQLite full-text search
- Snippet highlighting with `→ term ←` markers
- Ranked by FTS5's BM25 scoring

**Hybrid:**
- Run both semantic and FTS5
- Normalize scores to 0-1 range
- Weighted combination: `0.7 * semantic + 0.3 * fts`
- Sort by combined score

---

**Created:** 2026-03-25  
**Phase 2 (Embeddings):** 2026-03-26  
**Status:** ✅ Production Ready | 132 chunks embedded
