#!/bin/bash
# pr-reviewer.sh — Find PRs pending review and trigger AI review
# Usage: pr-reviewer.sh <owner/repo> [--label auto-review] [--max 5]
# Requires: GH_TOKEN env var, jq, curl

set -euo pipefail

REPO="${1:-}"
LABEL="auto-review"
MAX_PRS=5
REVIEWED_FILE="$HOME/.openclaw/workspace/.pr-reviews-done.json"

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
    echo "ERROR: GH_TOKEN not found in env or openclaw.json"
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

# Filter: only PRs we haven't reviewed (or that have new commits since our last review)
PENDING="[]"
for i in $(seq 0 $((PR_COUNT - 1))); do
    PR_NUM=$(echo "$PRS" | jq -r ".[$i].number")
    PR_SHA=$(echo "$PRS" | jq -r ".[$i].head.sha")
    PR_TITLE=$(echo "$PRS" | jq -r ".[$i].title")
    PR_DRAFT=$(echo "$PRS" | jq -r ".[$i].draft")
    
    # Skip drafts
    if [ "$PR_DRAFT" = "true" ]; then
        echo "  #$PR_NUM — draft, skipping"
        continue
    fi
    
    # Check if already reviewed at this SHA
    REVIEWED_SHA=$(jq -r --arg pr "$PR_NUM" '.[$pr] // ""' "$REVIEWED_FILE")
    if [ "$REVIEWED_SHA" = "$PR_SHA" ]; then
        echo "  #$PR_NUM — already reviewed at $PR_SHA, skipping"
        continue
    fi
    
    echo "  #$PR_NUM — $PR_TITLE (needs review)"
    PENDING=$(echo "$PENDING" | jq --argjson pr "$(echo "$PRS" | jq ".[$i]")" '. + [$pr]')
done

PENDING_COUNT=$(echo "$PENDING" | jq 'length')
echo ""
echo "$PENDING_COUNT PRs pending review."

if [ "$PENDING_COUNT" -eq 0 ]; then
    exit 0
fi

# Output the pending PRs as JSON for the orchestrator to consume
echo "$PENDING" | jq -c '.[] | {number, title, html_url, head_sha: .head.sha, changed_files, additions, deletions}'
