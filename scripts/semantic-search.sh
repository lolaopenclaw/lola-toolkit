#!/bin/bash
# Semantic Memory Search - Wrapper Script
# Usage:
#   semantic-search.sh search "query"     # Search memories by meaning
#   semantic-search.sh search "q" --top N  # Return N results
#   semantic-search.sh search "q" --json   # JSON output (for scripts)
#   semantic-search.sh index               # Re-index all memory files
#   semantic-search.sh status              # Show index stats

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

node scripts/semantic-search.js "$@"
