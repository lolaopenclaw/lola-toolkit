# HEARTBEAT — Silent Checks

Silent unless issues. Quiet: 00:00-07:00 Madrid. One message per ritual or HEARTBEAT_OK.

## Morning Ritual

1. **Cron:** `cron list` errors (consecutiveErrors>0)
2. **Memory:** >15MB → archive
3. **Calendar:** Check today critical
4. **Gmail:** Unread (5), alert breaches/important
5. **Garmin:** Critical only (sleep/stress/HR)
6. **Autoimprove:** Include if `memory/{today}-autoimprove.md` exists

## Evening Ritual

1. **Sessions:** >10 → suggest consolidation
2. **Pending:** Review `memory/pending-actions.md`, prompt unresolved
3. **Workspace:** Commits (4h), alert suspicious
4. **PRs:** Open >24h no review
5. **Fail2ban:** ≥10 = critical, 5-10 = notice

## Continuous

- **Gateway:** Unusual errors/degraded service
- **Kanban:** Critical tasks, don't auto-move
- **Sandbox:** Pending elevated ops
