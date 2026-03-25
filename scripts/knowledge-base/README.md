# Knowledge Base System

Personal knowledge management with RAG capabilities.

## Quick Start

```bash
# Ingest content
./scripts/knowledge-base-ingest.sh "https://example.com/article" tag1 tag2

# Search
./scripts/knowledge-base-search.sh "query terms"

# List all
./scripts/knowledge-base-search.sh --list

# Filter by tag
./scripts/knowledge-base-search.sh "query" --tag python
```

## Supported Sources

- **Articles**: Any HTML page (auto-detected)
- **YouTube**: Videos with transcripts (es/en)
- **PDFs**: Direct PDF links
- **Tweets**: WIP (treated as articles for now)

## Files

- `ingest.sh` - Ingest content into database
- `search.sh` - Search and list entries
- `verify.sh` - Verify database integrity
- `schema.sql` - Database schema
- `venv/` - Python virtual environment (auto-created)

## Database

Location: `data/knowledge-base.db`

Tables:
- `entries` - Main content storage
- `chunks` - Content split into ~500 word segments
- `entries_fts` - FTS5 full-text search index

## Documentation

See `memory/knowledge-base.md` for full documentation.
