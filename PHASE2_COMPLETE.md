# Knowledge Base Phase 2: Vector Embeddings — COMPLETE ✅

**Date:** March 26, 2026  
**Duration:** ~2 hours (including backfill of 132 chunks)  
**Status:** Production Ready

---

## What Was Built

### 1. Embedding Generation (`scripts/knowledge-base/embed.py`)
- **Model:** Gemini `gemini-embedding-001` (3072 dimensions)
- **Features:**
  - Reads chunks from database with NULL embeddings
  - Generates embeddings via Gemini API
  - Stores as binary BLOB in SQLite (float32 array)
  - Batch processing (10 chunks/batch) with rate limit handling
  - Exponential backoff on 429 errors (2s → 4s → 8s)
  - Progress reporting ("Embedding chunk X/Y...")
  - Summary report (processed/failed counts)

**Usage:**
```bash
python3 scripts/knowledge-base/embed.py
```

### 2. Semantic Search Engine (`scripts/knowledge-base/semantic-search.py`)
- **Modes:**
  - **Semantic:** Pure vector similarity (cosine distance)
  - **FTS5:** Classic full-text search (keyword matching)
  - **Hybrid:** Weighted combination (70% semantic / 30% FTS5)
- **Features:**
  - Query embedding generation
  - Cosine similarity calculation (numpy)
  - Result ranking by score
  - Configurable result limit
  - Configurable semantic weight for hybrid mode

**Usage:**
```bash
python3 scripts/knowledge-base/semantic-search.py --mode semantic "query"
python3 scripts/knowledge-base/semantic-search.py --mode hybrid --limit 10 "query"
```

### 3. Updated Search Wrapper (`scripts/knowledge-base/search.sh`)
- **New flags:**
  - `--semantic`: Use vector embeddings
  - `--hybrid`: Combine semantic + FTS5
  - `--limit N`: Custom result count
- **Backward compatible:** No flags = FTS5 (existing behavior)

**Examples:**
```bash
./search.sh --semantic "prompt injection defense"
./search.sh --hybrid "RAG patterns"
./search.sh "exact keyword"  # FTS5 (classic)
```

### 4. Auto-Embedding on Ingest (`scripts/knowledge-base/ingest.sh`)
- **Change:** After ingesting content, automatically calls `embed.py` for new chunks
- **Effect:** New URLs get embeddings immediately (no manual backfill needed)

### 5. Documentation Updates
- **Updated files:**
  - `memory/knowledge-base.md` — Added Phase 2 details, technical specs
  - `TOOLS.md` — Updated KB entry with embedding info
  - `PRD.md` — Feature #5 marked as Phase 2 complete, moved roadmap item to ✅
  - `scripts/knowledge-base/README.md` — New quick reference

---

## Technical Details

### Embedding Model
- **Provider:** Google Generative AI
- **Model:** `gemini-embedding-001`
- **Dimensions:** 3072 (float32 vectors)
- **API Key:** Read from `$GOOGLE_API_KEY` env variable or `.env` files
- **Endpoint:** `https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent`

### Storage
- **Format:** Binary BLOB (`struct.pack(f"{len(embedding)}f", *embedding)`)
- **Column:** `chunks.embedding` (already existed, now populated)
- **Size:** ~12KB per chunk (3072 floats × 4 bytes)

### Similarity Algorithm
```python
def cosine_similarity(a, b):
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))
```

### Search Modes Comparison

| Mode | Speed | Precision | Use Case |
|------|-------|-----------|----------|
| **FTS5** | Fast | Exact keywords | Known terminology |
| **Semantic** | Medium | Meaning-based | Conceptual queries |
| **Hybrid** | Medium | Best of both | General-purpose |

---

## Testing Results

### Backfill Performance
- **Total chunks:** 132
- **Successful:** 132 (100%)
- **Failed (initial run):** 2 (rate limit 429)
- **Failed (retry):** 0
- **Duration:** ~3 minutes (including retries)

### Search Quality Tests

**Query:** "prompt injection defense"

**Semantic mode results:**
1. Berman video — chunk about prompt injection attack (score: 0.7505) ✅
2. OpenClaw video — security layers discussion (score: 0.7273) ✅
3. Berman video — sleeper agent attack (score: 0.7064) ✅

**FTS5 mode results:**
1. OpenClaw video — exact phrase "prompt injection defense" (snippet match) ✅
2. Another OpenClaw video — phrase match ✅
3. Berman video — phrase match ✅

**Hybrid mode results:**
- Combines both approaches
- Top result: exact FTS5 match (chunk 38, score 0.7902)
- Subsequent results: semantic relevance

**Conclusion:** Semantic search finds conceptually relevant content even without exact phrase matches. FTS5 excels at exact terminology. Hybrid balances both.

---

## Rate Limit Handling

**Observed behavior:**
- Gemini API enforces rate limits (429 errors)
- Script implements exponential backoff: 2s → 4s → 8s
- Max 3 retries per chunk
- 2 chunks failed on initial run (recovered on second run)
- Recommendation: Increase batch delay from 1s to 2s for large ingests

**Current safeguards:**
- 0.1s delay per chunk
- 1s delay between batches
- Exponential backoff on errors

---

## Migration Notes

### Existing Users
1. Run `python3 scripts/knowledge-base/embed.py` once to backfill embeddings
2. No schema changes needed (column already existed)
3. Existing FTS5 searches work unchanged
4. New flags (`--semantic`, `--hybrid`) are opt-in

### New Ingests
- Embeddings generated automatically on ingest
- No manual backfill needed

---

## Future Enhancements

### Phase 3 (Potential)
- **Auto-ingestion:** Weekly cron to ingest from RSS/bookmarks
- **Query expansion:** Use LLM to reformulate queries for better semantic matches
- **Multi-modal embeddings:** Support images/audio (Gemini multimodal)
- **Relevance feedback:** Learn from which results users click
- **Local embeddings:** Reduce API dependency with local models (Ollama)

---

## Files Changed

```
scripts/knowledge-base/
├── embed.py                  # NEW: Embedding generation
├── semantic-search.py        # NEW: Core search engine
├── search.sh                 # MODIFIED: Added --semantic, --hybrid flags
├── ingest.sh                 # MODIFIED: Auto-call embed.py after ingest
└── README.md                 # NEW: Quick reference

memory/knowledge-base.md      # UPDATED: Phase 2 documentation
TOOLS.md                      # UPDATED: KB entry
PRD.md                        # UPDATED: Feature #5 marked complete
```

---

## Verification Commands

```bash
# Check all chunks have embeddings
sqlite3 data/knowledge-base.db "SELECT COUNT(*) as total, COUNT(embedding) as with_embeddings FROM chunks;"
# Output: 132|132 ✅

# Test semantic search
bash scripts/knowledge-base/search.sh --semantic "AI safety techniques"

# Test hybrid search
bash scripts/knowledge-base/search.sh --hybrid "prompt injection"

# Syntax checks
bash -n scripts/knowledge-base/search.sh
python3 -m py_compile scripts/knowledge-base/embed.py
python3 -m py_compile scripts/knowledge-base/semantic-search.py
```

---

## Ralph Wiggum Validation ✅

```bash
# Syntax checks
bash -n scripts/knowledge-base/search.sh          # ✅ OK
python3 -m py_compile scripts/knowledge-base/embed.py  # ✅ OK
shellcheck scripts/knowledge-base/search.sh       # ⚠️ 4 minor warnings (YELLOW unused, SC2124, SC1091)

# Functional tests
python3 scripts/knowledge-base/embed.py           # ✅ 132/132 chunks embedded
bash scripts/knowledge-base/search.sh --semantic "test"  # ✅ Returns results
bash scripts/knowledge-base/search.sh --hybrid "test"    # ✅ Returns results
```

---

## Cost Analysis

### Embedding Generation
- **API:** Gemini `gemini-embedding-001`
- **Cost:** $0.000001 per 1K tokens (practically free)
- **Total chunks:** 132
- **Estimated cost:** <$0.01 for entire backfill
- **Ongoing:** ~$0 (minimal text, free tier)

### Search
- **Query embedding:** ~1 API call per semantic search
- **Cost:** <$0.0001 per search
- **Monthly (estimated 100 searches):** <$0.01

**Conclusion:** Negligible cost impact. Primary cost remains Claude API usage for other tasks.

---

## Acknowledgments

- **OpenClaw framework** — Agent orchestration
- **Gemini API** — Embedding generation
- **SQLite FTS5** — Full-text search baseline
- **Karpathy Autoresearch pattern** — Self-improvement inspiration

---

**Implemented by:** Lola 💃🏽  
**System:** OpenClaw 2026.3.8  
**Date:** March 26, 2026  
**Phase:** 2 of 2 (complete)
