#!/bin/bash
# Weekly GitHub Issues & Discussions Review
# Checks openclaw repo for open issues related to our work

set -euo pipefail

# Check dependencies
if ! command -v gh &>/dev/null; then
    echo "❌ Missing required dependency: gh (GitHub CLI)" >&2
    exit 1
fi

echo "=== OpenClaw Issues Review - $(date) ==="
echo

# Issues related to Gateway (our recent focus)
echo "🔴 GATEWAY-RELATED ISSUES:"
gh issue list --repo openclaw/openclaw --state open --search "gateway" --limit 10 2>/dev/null || echo "Error fetching issues"
echo

# Our most recent issue
echo "📌 OUR REPORTED ISSUES:"
gh issue list --repo openclaw/openclaw --state open --limit 3 --search "restart infinite\|zombie process" 2>/dev/null || echo "No filter results"
echo

# Browser Relay issues (we had issues there)
echo "🔧 BROWSER RELAY ISSUES:"
gh issue list --repo openclaw/openclaw --state open --search "browser relay" --limit 5 2>/dev/null | head -10
echo

# Cron/automation issues
echo "⏰ CRON & AUTOMATION ISSUES:"
gh issue list --repo openclaw/openclaw --state open --search "cron" --limit 5 2>/dev/null | head -10
echo

echo "=== End of Review ==="
