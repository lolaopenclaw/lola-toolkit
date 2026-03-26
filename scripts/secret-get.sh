#!/bin/bash
set -euo pipefail
# Get a secret from the encrypted store
# Usage: secret-get.sh <KEY_NAME>
# Example: secret-get.sh ELEVENLABS_API_KEY
if [ -z "$1" ]; then
  echo "Usage: $0 <KEY_NAME>"
  echo "Available keys:"
  pass ls openclaw/ 2>/dev/null
  exit 1
fi
pass show "openclaw/$1" 2>/dev/null || echo "Secret not found: $1"
