#!/bin/bash
# Gateway Health Watchdog
# Checks if gateway is responsive and reports issues

set -euo pipefail

# Check dependencies
for cmd in systemctl nc date ps awk; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ Missing required dependency: $cmd" >&2
        exit 1
    fi
done

STATUS=$(systemctl --user is-active openclaw-gateway.service)
if [ "$STATUS" != "active" ]; then
  echo "⚠️ Gateway is DOWN (status: $STATUS)"
  systemctl --user restart openclaw-gateway.service
  sleep 5
  STATUS=$(systemctl --user is-active openclaw-gateway.service)
  if [ "$STATUS" = "active" ]; then
    echo "✅ Gateway restarted successfully"
  else
    echo "❌ CRITICAL: Gateway failed to restart after 5s"
  fi
  exit 1
fi

# Check port responsiveness
if ! nc -zv 127.0.0.1 18789 >/dev/null 2>&1; then
  echo "⚠️ Gateway port 18789 not responding"
  ps aux | grep openclaw-gateway | grep -v grep | awk '{print $2}' | xargs -r kill -9
  sleep 2
  systemctl --user restart openclaw-gateway.service
  exit 1
fi

echo "✅ Gateway healthy at $(date)"
