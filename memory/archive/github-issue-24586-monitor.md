# GitHub Issue #24586 - Monitoring Log

**Issue:** Cron announce delivery inconsistent on Discord — messages sometimes delivered, sometimes silently dropped

**OpenClaw Version:** 2026.3.2 (confirmed)

**Problem:** Daily cron jobs with `delivery.mode: announce` to Discord fail silently. Job status shows "ok" but message never reaches Discord.

**Workaround:** Shell script (`informe-matutino-auto.sh`) using Discord API directly. Production-ready, 100% reliable.

**Monitoring Schedule:** Every Monday 8:00 AM (Europe/Madrid)

---

## Status Timeline

### 2026-03-08 11:27 — Problem Identified & Documented
- Created GitHub comment on #24586
- Documented reproduction case with OpenClaw 2026.3.2
- Posted workaround solution
- Created weekly monitoring cron job
- Estimated: likely won't be fixed soon (similar bugs exist since ~Feb 2026)

### Next Review: 2026-03-15 8:00 AM

---

## Action Items When Issue Closes

1. ✅ Test native cron delivery.announce again
2. ✅ If working: remove informe-matutino-auto.sh script
3. ✅ Revert cron job to use native delivery
4. ✅ Archive workaround in scripts/archived/
5. ✅ Update MEMORY.md

## Notes

- GitHub issue is locked (can't comment directly anymore)
- Community aware of the problem
- No fix estimated timeline
- Current workaround completely bypasses broken mechanism

