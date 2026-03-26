#!/bin/bash
set -euo pipefail
API_URL="http://127.0.0.1:5001/api/finanzas"
TIMEOUT=5

response=$(curl -s --max-time $TIMEOUT "$API_URL" 2>&1)
if [ $? -eq 0 ]; then
  echo "✅ API 5001 OK"
else
  echo "❌ API 5001 FAILED: $response"
fi
