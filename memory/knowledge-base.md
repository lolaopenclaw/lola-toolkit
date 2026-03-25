# Knowledge Base System

Personal knowledge management system with RAG capabilities for OpenClaw workspace.

## Overview

The knowledge base ingests content from various sources (articles, YouTube videos, PDFs) and provides full-text search with future support for vector embeddings.

## Architecture

### Database (`data/knowledge-base.db`)

SQLite database with:
- **entries table**: Stores metadata and full content
- **chunks table**: Content split into ~500 word segments (ready for embeddings)
- **entries_fts**: FTS5 virtual table for full-text search

### Scripts

Located in `scripts/knowledge-base/`:

1. **ingest.sh** - Ingest content from URLs
2. **search.sh** - Search and list entries

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
# Full-text search
./scripts/knowledge-base-search.sh "query terms"

# List all entries
./scripts/knowledge-base-search.sh --list

# Filter by tag
./scripts/knowledge-base-search.sh "query" --tag python
```

**Search returns:**
- Top 5 results ranked by relevance
- Title, URL, source type
- Date saved, entry ID
- Highlighted snippet or summary
- Tags (if any)

## Features

### Implemented ✅

- Multi-source ingestion (article, YouTube, PDF)
- Auto source type detection
- Content chunking (~500 words)
- FTS5 full-text search
- Tag support
- Summary generation
- Duplicate URL detection

### Future Enhancements 🔮

- Vector embeddings (BLOB field ready in `chunks.embedding`)
- Semantic search using embeddings
- Twitter/X thread extraction
- Auto-tagging using LLM
- Related content suggestions
- Export to Markdown

## Dependencies

Python packages (auto-installed in venv):
- `youtube-transcript-api` - YouTube transcripts
- `beautifulsoup4` - HTML parsing
- `requests` - HTTP client
- `PyPDF2` - PDF text extraction

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
# Save a technical article
./scripts/knowledge-base-ingest.sh "https://blog.example.com/rag-tutorial" rag ai vector-db

# Search for RAG content
./scripts/knowledge-base-search.sh "retrieval augmented generation"

# List everything
./scripts/knowledge-base-search.sh --list
```

## Maintenance

- Database location: `data/knowledge-base.db`
- Python venv: `scripts/knowledge-base/venv/`
- To reset: `rm data/knowledge-base.db && sqlite3 data/knowledge-base.db < scripts/knowledge-base/schema.sql`

---

**Created:** 2026-03-25  
**Status:** ✅ Production Ready
