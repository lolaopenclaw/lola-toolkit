# HEARTBEAT — Silent Checks

Silent unless issues. Quiet: 00:00-07:00 Madrid.

## Morning Ritual

1. **Cron:** `cron list` errors (consecutiveErrors>0)
2. **Memory:** >15MB → archive old
3. **Calendar:** Check today for critical
4. **Gmail:** Scan unread (5), alert breaches/important
5. **Garmin:** Critical only (sleep/stress/HR)
6. **Autoimprove:** Include if `memory/{today}-autoimprove.md` exists

Report: One message or HEARTBEAT_OK

## Evening Ritual

1. **Sessions:** >10 → suggest consolidation
2. **Pending:** Review `memory/pending-actions.md`, prompt unresolved
3. **Workspace:** Check commits (4h), alert suspicious
4. **PRs:** Alert if open >24h no review
5. **Fail2ban SSH:** ≥10 attempts = critical, 5-10 = evening notice

Report: One message or HEARTBEAT_OK

## Continuous Checks

- **Gateway:** Alert on unusual errors or degraded service
- **Kanban (Notion):** Check critical tasks, don't auto-move
- **Sandbox:** Alert on pending elevated operations

## Rules

- Proactive > reactive
- One message per ritual (unless CRITICAL)
- Don't repeat alerts for same issue
- Evidence > guesses
