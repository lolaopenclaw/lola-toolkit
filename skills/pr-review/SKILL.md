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
bash ~/. openclaw/workspace/scripts/pr-reviewer.sh {owner/repo} --max {max}
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

```
You are an expert code reviewer. Review this Pull Request and provide constructive, actionable feedback.

<pr>
Repository: {owner/repo}
PR #{number}: {title}
URL: {html_url}
Description: {pr_description}
</pr>

<diff>
{diff_content}
</diff>

<review_checklist>
## Security (CRITICAL — always check)
- [ ] Hardcoded secrets, API keys, tokens, passwords
- [ ] SQL injection, XSS, CSRF vulnerabilities
- [ ] Insecure deserialization or eval() usage
- [ ] Sensitive data in logs or error messages
- [ ] Missing input validation/sanitization
- [ ] Insecure dependencies (known CVEs)

## Correctness
- [ ] Logic errors or off-by-one mistakes
- [ ] Null/undefined handling
- [ ] Edge cases not covered
- [ ] Race conditions or concurrency issues
- [ ] Error handling (are errors caught and handled properly?)

## Quality
- [ ] Dead code or unused imports
- [ ] Code duplication that should be extracted
- [ ] Missing or insufficient tests for the changes
- [ ] Naming clarity (variables, functions)
- [ ] Overly complex code that could be simplified

## Style (low priority)
- [ ] Consistent with project conventions
- [ ] console.log/print statements left in
- [ ] TODO/FIXME without issue reference
</review_checklist>

<instructions>
1. Read the diff carefully, file by file.
2. For each issue found, note:
   - **File and line** (from the diff)
   - **Severity:** 🔴 critical | 🟡 warning | 🔵 suggestion
   - **What:** Clear description of the issue
   - **Fix:** Specific suggestion for how to fix it
3. At the end, provide:
   - **Overall assessment:** APPROVE / REQUEST_CHANGES / COMMENT
   - **Summary:** 2-3 sentences about the PR quality
   - **Score:** X/10

Format your response EXACTLY as:

REVIEW_START
ASSESSMENT: [APPROVE|REQUEST_CHANGES|COMMENT]
SCORE: [1-10]
SUMMARY: [2-3 sentence summary]

ISSUES:
- FILE: [path] | LINE: [number] | SEVERITY: [🔴|🟡|🔵] | ISSUE: [description] | FIX: [suggestion]
- FILE: [path] | LINE: [number] | SEVERITY: [🔴|🟡|🔵] | ISSUE: [description] | FIX: [suggestion]
...

If no issues found:
ISSUES: none

REVIEW_END
</instructions>

<constraints>
- Be constructive, not pedantic
- Focus on real issues, not style nitpicks (unless they impact readability significantly)
- Security issues are ALWAYS flagged, even minor ones
- If the diff is too large or unclear, say so honestly
- Do not hallucinate line numbers — only reference lines visible in the diff
</constraints>
```

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
