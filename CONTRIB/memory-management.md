# Proposal: Memory Management Framework

## Problem

OpenClaw workspaces accumulate memory files over time. Without management:
- Daily memory files grow unbounded
- Duplicate content across files wastes tokens
- Old, irrelevant context pollutes agent reasoning
- No way to search historical memory efficiently

## Solution

Two complementary tools:

### 1. Memory Guardian (`memory-guardian.sh`)

Automated cleanup, analysis, and maintenance of workspace memory files.

**Features:**
- **Analyze** — Report on memory usage, file sizes, token estimates
- **Clean** — Remove empty/trivial files, archive old content
- **Compress** — Summarize files older than 30 days
- **Deduplicate** — Detect and merge duplicate content
- **Dry-run** — Preview all changes before applying

```bash
# See current memory state
bash scripts/memory-guardian.sh --status

# Full analysis without changes
bash scripts/memory-guardian.sh --analyze --dry-run

# Run complete maintenance
bash scripts/memory-guardian.sh --full
```

### 2. Semantic Search (`semantic-search.sh`)

Vector-indexed search across all workspace files.

**Features:**
- Builds vector index of memory files
- Natural language queries
- Returns relevant file excerpts with context
- Incremental index updates

```bash
# Search for context
bash scripts/semantic-search.sh "what did we decide about the API?"

# Rebuild index
bash scripts/semantic-search.sh --reindex
```

## Genericization Needed

| Item | Current | Target |
|------|---------|--------|
| Workspace path | Hardcoded | `$OPENCLAW_WORKSPACE` |
| Protected paths | User-specific | Configurable via `.memory-guardian.conf` |
| Language | Spanish | English (with i18n support) |
| Dependencies | Assumed installed | Check + install instructions |

## Why This Should Be in OpenClaw

1. **Universal need** — Every OpenClaw user generates memory files
2. **Token savings** — Cleaner memory = fewer tokens per session = lower costs
3. **Better agent performance** — Less noise in context = better responses
4. **Searchability** — Finding past decisions without reading every file
