#!/bin/bash
# pr-reviewer.sh — Find PRs pending review and trigger AI review
# Usage: pr-reviewer.sh <owner/repo> [--label auto-review] [--max 5]
# Requires: GH_TOKEN env var, jq, curl

set -euo pipefail

REPO="${1:-}"
LABEL="auto-review"
MAX_PRS=5
REVIEWED_FILE="/home/mleon/.openclaw/workspace/.pr-reviews-done.json"

# Parse optional flags
shift || true
while [[ $# -gt 0 ]]; do
    case "$1" in
        --label) LABEL="$2"; shift 2 ;;
        --max) MAX_PRS="$2"; shift 2 ;;
        *) shift ;;
    esac
done

if [ -z "$REPO" ]; then
    echo "Usage: pr-reviewer.sh <owner/repo> [--label auto-review] [--max 5]"
    exit 1
fi

# Resolve GH_TOKEN
if [ -z "${GH_TOKEN:-}" ]; then
    GH_TOKEN=$(cat ~/.openclaw/openclaw.json 2>/dev/null | jq -r '.skills.entries["gh-issues"].apiKey // empty') || true
fi

if [ -z "${GH_TOKEN:-}" ]; then
    echo "ERROR: GH_TOKEN not found"
    exit 1
fi

# Initialize reviewed file if missing
if [ ! -f "$REVIEWED_FILE" ]; then
    echo '{}' > "$REVIEWED_FILE"
fi

# Fetch open PRs
echo "Fetching open PRs from $REPO..."
PRS=$(curl -s \
    -H "Authorization: Bearer $GH_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${REPO}/pulls?state=open&per_page=${MAX_PRS}&sort=created&direction=desc")

# Count PRs
PR_COUNT=$(echo "$PRS" | jq 'length')
echo "Found $PR_COUNT open PRs"

if [ "$PR_COUNT" -eq 0 ]; then
    echo "No open PRs to review."
    exit 0
fi

# Filter using jq (replaces bash loop)
REVIEWED_DATA=$(cat "$REVIEWED_FILE")
PENDING=$(echo "$PRS" | jq --argjson reviewed "$REVIEWED_DATA" '
  map(
    select(.draft == false) |
    select($reviewed[.number | tostring] != .head.sha)
  )
')

PENDING_COUNT=$(echo "$PENDING" | jq 'length')

# Log results
echo "$PRS" | jq -r '.[] | "\(.number) \(.draft) \(.title)"' | while read -r num draft title; do
    if [ "$draft" = "true" ]; then
        echo "  #$num — draft, skipping"
    else
        REVIEWED_SHA=$(echo "$REVIEWED_DATA" | jq -r --arg pr "$num" '.[$pr] // ""')
        PR_SHA=$(echo "$PRS" | jq -r ".[] | select(.number == $num) | .head.sha")
        if [ "$REVIEWED_SHA" = "$PR_SHA" ]; then
            echo "  #$num — already reviewed at $PR_SHA, skipping"
        else
            echo "  #$num — $title (needs review)"
        fi
    fi
done

echo ""
echo "$PENDING_COUNT PRs pending review."

if [ "$PENDING_COUNT" -eq 0 ]; then
    exit 0
fi

# Output the pending PRs as JSON for the orchestrator to consume
echo "$PENDING" | jq -c '.[] | {number, title, html_url, head_sha: .head.sha, changed_files, additions, deletions}'
