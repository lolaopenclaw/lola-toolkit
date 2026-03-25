#!/bin/bash
# Verify knowledge base integrity

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="${SCRIPT_DIR}/../../data/knowledge-base.db"

echo "🔍 Knowledge Base Verification"
echo "================================"
echo ""

# Check if DB exists
if [ ! -f "$DB_PATH" ]; then
    echo "❌ Database not found: $DB_PATH"
    exit 1
fi

echo "✅ Database exists: $DB_PATH"
echo ""

# Check tables
echo "📊 Statistics:"
sqlite3 "$DB_PATH" << SQL
.mode column
SELECT 
    (SELECT COUNT(*) FROM entries) as entries,
    (SELECT COUNT(*) FROM chunks) as chunks,
    (SELECT COUNT(*) FROM entries_fts) as fts_entries;
SQL

echo ""
echo "📝 Recent entries:"
sqlite3 "$DB_PATH" << SQL
.mode column
.headers on
.width 5 50 15
SELECT 
    id,
    SUBSTR(title, 1, 50) as title,
    source_type
FROM entries
ORDER BY created_at DESC
LIMIT 5;
SQL

echo ""
echo "✅ Verification complete"
