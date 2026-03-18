---
name: pr-review
description: "Auto-review open PRs with AI. Polls GitHub for unreviewed PRs, spawns a Sonnet sub-agent to review each one, posts comments on GitHub. Usage: /pr-review <owner/repo> [--max 5] [--model sonnet]"
user-invocable: true
metadata:
  { "openclaw": { "requires": { "bins": ["curl", "jq", "git"] }, "primaryEnv": "GH_TOKEN" } }
---

# pr-review — AI Code Review for Pull Requests

You are an orchestrator. Follow these phases exactly.

---

## Phase 1 — Parse Arguments

Positional:
- `owner/repo` — required. The GitHub repository to review PRs for.

Flags (optional):
| Flag | Default | Description |
|------|---------|-------------|
| --max | 5 | Max PRs to review per run |
| --model | sonnet | Model for the review sub-agent |
| --security-only | false | Only check security issues, skip style/logic |
| --notify | _(none)_ | Telegram channel ID to notify with results |

---

## Phase 2 — Find Pending PRs

Resolve GH_TOKEN (same as gh-issues skill):
```bash
if [ -z "$GH_TOKEN" ]; then
    GH_TOKEN=$(cat ~/.openclaw/openclaw.json 2>/dev/null | jq -r '.skills.entries["gh-issues"].apiKey // empty')
fi
```

Run the scanner script:
```bash
bash ~/.openclaw/workspace/scripts/pr-reviewer.sh {owner/repo} --max {max}
```

Parse the output. If no PRs pending, report "No PRs pending review" and stop.

For each pending PR, collect: number, title, html_url, head_sha.

---

## Phase 3 — Fetch PR Diff

For each pending PR, fetch the diff:

```bash
curl -s \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "Accept: application/vnd.github.v3.diff" \
  "https://api.github.com/repos/{owner/repo}/pulls/{pr_number}" > /tmp/pr-{pr_number}.diff
```

Also fetch the PR description:
```bash
curl -s \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/{owner/repo}/pulls/{pr_number}" | jq -r '.body // "No description"'
```

If the diff is larger than 50KB, truncate to the first 50KB and note it in the review.

---

## Phase 4 — Spawn Review Sub-agents

For each pending PR, spawn a sub-agent using `sessions_spawn` with:
- **model:** the `--model` flag value (default: `sonnet`)
- **runTimeoutSeconds:** 300 (5 minutes max per review)
- **cleanup:** "keep"

### Sub-agent Task Prompt:

**You are an expert code reviewer. For PR #{number} ({title}), evaluate the diff against the checklist below:**

| Category | Checks | Mark |
|----------|--------|------|
| **🔴 Security** | Hardcoded secrets, SQL/XSS/CSRF, eval(), input validation, known CVEs, sensitive logs | CRITICAL |
| **🔴 Correctness** | Logic errors, null handling, edge cases, race conditions, error handling | CRITICAL |
| **🟡 Quality** | Dead code, duplication, test coverage, naming, complexity | IMPORTANT |
| **🔵 Style** | Conventions, TODO refs (skip trivial lint unless critical) | NICE-TO-HAVE |

**Output format (EXACT):**
```
REVIEW_START
ASSESSMENT: [APPROVE|REQUEST_CHANGES|COMMENT]
SCORE: [1-10]
SUMMARY: [2-3 sentences]
ISSUES: [FILE: path | LINE: number | SEVERITY: 🔴|🟡|🔵 | ISSUE: description | FIX: suggestion] (or "none")
REVIEW_END
```

**Constraints:**
- Be constructive, not pedantic
- Security issues are ALWAYS flagged
- Do NOT hallucinate line numbers (only reference visible lines)
- If diff >50KB, note truncation; if unclear, say so

---

## Phase 5 — Post Review to GitHub

Parse each sub-agent's response. Extract the structured review.

### Post as PR Review:

```bash
# Determine the event based on assessment
# APPROVE → "APPROVE"
# REQUEST_CHANGES → "REQUEST_CHANGES"  
# COMMENT → "COMMENT"

REVIEW_BODY="## 🤖 AI Code Review\n\n**Score:** {score}/10\n**Assessment:** {assessment}\n\n{summary}\n\n### Issues Found\n\n{formatted_issues}\n\n---\n*Automated review by OpenClaw PR Reviewer (model: {model})*"

curl -s -X POST \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/{owner/repo}/pulls/{pr_number}/reviews" \
  -d "{
    \"body\": \"$REVIEW_BODY\",
    \"event\": \"{event}\"
  }"
```

### Mark as reviewed:

After posting, update the reviewed file:
```bash
REVIEWED_FILE="/home/mleon/.openclaw/workspace/.pr-reviews-done.json"
jq --arg pr "{pr_number}" --arg sha "{head_sha}" '.[$pr] = $sha' "$REVIEWED_FILE" > /tmp/reviewed.json && mv /tmp/reviewed.json "$REVIEWED_FILE"
```

This ensures we don't review the same commit twice, but DO re-review if new commits are pushed.

---

## Phase 6 — Report

Present summary:

| PR | Score | Assessment | Issues |
|----|-------|------------|--------|
| #42 Fix auth | 8/10 | ✅ APPROVE | 1 🔵 suggestion |
| #37 Add export | 5/10 | ⚠️ REQUEST_CHANGES | 2 🔴 critical, 1 🟡 warning |

If `--notify` was provided, send the summary to the Telegram channel.

---

## Cron Integration

To run automatically every 15 minutes:
```
/pr-review owner/repo --max 5 --notify {channel_id}
```

The reviewed-file tracking ensures idempotency — re-running is safe.
