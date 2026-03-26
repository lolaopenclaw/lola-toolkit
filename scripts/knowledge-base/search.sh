#!/bin/bash
# knowledge-base-search.sh - Search the knowledge base
# Usage: ./search.sh <query> [--list] [--tag TAG] [--semantic] [--hybrid]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="${SCRIPT_DIR}/../../data/knowledge-base.db"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}$1${NC}"; }
highlight() { echo -e "${BLUE}$1${NC}"; }
meta() { echo -e "${GRAY}$1${NC}"; }

# Parse arguments
QUERY=""
LIST_MODE=false
TAG_FILTER=""
SEARCH_MODE="fts"  # fts (default), semantic, or hybrid
LIMIT=5

while [[ $# -gt 0 ]]; do
    case $1 in
        --list)
            LIST_MODE=true
            shift
            ;;
        --tag)
            TAG_FILTER="$2"
            shift 2
            ;;
        --semantic)
            SEARCH_MODE="semantic"
            shift
            ;;
        --hybrid)
            SEARCH_MODE="hybrid"
            shift
            ;;
        --limit)
            LIMIT="$2"
            shift 2
            ;;
        *)
            QUERY="$1"
            shift
            ;;
    esac
done

# List mode
if [ "$LIST_MODE" = true ]; then
    sqlite3 "$DB_PATH" <<SQL
.mode column
.headers on
.width 5 50 15 20
SELECT 
    id,
    title,
    source_type,
    date(created_at) as created
FROM entries
ORDER BY created_at DESC;
SQL
    exit 0
fi

# Check if query provided
if [ -z "$QUERY" ]; then
    echo "Usage: $0 <query> [--list] [--tag TAG] [--semantic] [--hybrid] [--limit N]"
    echo ""
    echo "Options:"
    echo "  --list       List all entries"
    echo "  --tag TAG    Filter by tag"
    echo "  --semantic   Use semantic vector search"
    echo "  --hybrid     Combine FTS5 and semantic search"
    echo "  --limit N    Number of results (default: 5)"
    exit 1
fi

# Use semantic search if requested
if [ "$SEARCH_MODE" = "semantic" ] || [ "$SEARCH_MODE" = "hybrid" ]; then
    python3 "${SCRIPT_DIR}/semantic-search.py" --mode "$SEARCH_MODE" --limit "$LIMIT" "$QUERY"
    exit 0
fi

# Otherwise use FTS5 (default)
python3 - << PYTHON_SCRIPT
import sqlite3
import json
from datetime import datetime

conn = sqlite3.connect('$DB_PATH')
cur = conn.cursor()

query = '''$QUERY'''
tag_filter = '''$TAG_FILTER'''

# Build SQL query
if tag_filter:
    # Tag-filtered search
    sql = """
        SELECT 
            e.id,
            e.title,
            e.url,
            e.source_type,
            e.summary,
            e.tags,
            e.created_at,
            snippet(entries_fts, 1, '→ ', ' ←', '...', 30) as snippet
        FROM entries e
        JOIN entries_fts ON e.id = entries_fts.rowid
        WHERE entries_fts MATCH ? AND e.tags LIKE ?
        ORDER BY rank
        LIMIT 5
    """
    cur.execute(sql, (query, f'%{tag_filter}%'))
else:
    # Full-text search
    sql = """
        SELECT 
            e.id,
            e.title,
            e.url,
            e.source_type,
            e.summary,
            e.tags,
            e.created_at,
            snippet(entries_fts, 1, '→ ', ' ←', '...', 30) as snippet
        FROM entries e
        JOIN entries_fts ON e.id = entries_fts.rowid
        WHERE entries_fts MATCH ?
        ORDER BY rank
        LIMIT 5
    """
    cur.execute(sql, (query,))

results = cur.fetchall()

if not results:
    print(f"🔍 No results found for: {query}")
    exit(0)

print(f"🔍 Found {len(results)} result(s) for: {query}\n")

for i, row in enumerate(results, 1):
    entry_id, title, url, source_type, summary, tags_json, created_at, snippet = row
    
    # Parse tags
    try:
        tags = json.loads(tags_json) if tags_json else []
    except:
        tags = []
    
    # Format date
    created = datetime.fromisoformat(created_at).strftime('%Y-%m-%d')
    
    # Print result
    print(f"\033[0;34m{i}. {title}\033[0m")
    print(f"   \033[0;90m{url}\033[0m")
    print(f"   Type: {source_type} | Saved: {created} | ID: {entry_id}")
    
    if tags:
        print(f"   Tags: {', '.join(tags)}")
    
    if snippet:
        # Clean up snippet
        snippet = snippet.replace('\n', ' ').strip()
        print(f"   \033[1;33m{snippet}\033[0m")
    elif summary:
        print(f"   {summary[:150]}...")
    
    print()

conn.close()
PYTHON_SCRIPT
