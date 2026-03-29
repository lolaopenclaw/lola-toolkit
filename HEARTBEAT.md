# HEARTBEAT — Silent Checks

Silent if OK. Quiet: 00:00-07:00 Madrid. One msg/ritual or HEARTBEAT_OK.

## Morning Ritual

1. **Cron:** errors (consecutiveErrors>0)
2. **Memory:** >15MB → archive
3. **Calendar:** critical
4. **Gmail:** unread (5), breaches/important
5. **Garmin:** critical (sleep/stress/HR)
6. **Autoimprove:** if `memory/{today}-autoimprove.md` exists

## Evening Ritual

1. **Sessions:** >10 → consolidate
2. **Pending:** `memory/pending-actions.md`, prompt unresolved
3. **Workspace:** commits (4h), alert suspicious
4. **PRs:** >24h open w/o review
5. **Fail2ban:** ≥10 critical, 5-10 notice

## Continuous

- **Gateway:** unusual errors/degraded service
- **Kanban:** critical tasks only
- **Sandbox:** pending elevated ops
