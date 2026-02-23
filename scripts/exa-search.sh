#!/bin/bash
# EXA Search - Simple wrapper around Exa API
# Usage: exa-search.sh "search query" [num_results]

set -e

# Config
API_KEY="${EXA_API_KEY:-51f67c8b-636c-4ff3-a271-41f38735529b}"
API_URL="https://api.exa.ai/search"
QUERY="${1:-}"
NUM_RESULTS="${2:-5}"

# Validation
if [ -z "$QUERY" ]; then
  echo "❌ Usage: exa-search.sh \"query\" [num_results]"
  exit 1
fi

if [ -z "$API_KEY" ]; then
  echo "❌ Error: EXA_API_KEY not set"
  exit 1
fi

# Make API call
echo "🔍 Searching for: $QUERY"
echo ""

response=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d "{
    \"query\": \"$QUERY\",
    \"numResults\": $NUM_RESULTS,
    \"contents\": {
      \"text\": true
    }
  }")

# Parse and format results
echo "$response" | jq -r '.results[] | 
  "📄 \(.title)\n🔗 \(.url)\n📝 \(.text[0:300])...\n---\n"' 2>/dev/null || {
  echo "⚠️ Raw response:"
  echo "$response" | jq . 2>/dev/null || echo "$response"
}
