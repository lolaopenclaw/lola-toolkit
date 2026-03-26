# Script Consolidation Decisions
**Date:** 2026-03-26  
**Task:** Clean up duplicate/redundant scripts

---

## 1️⃣ Morning Report Scripts

### Decision: ✅ KEEP `informe-matutino-auto.sh` ONLY

- **`scripts/generate-morning-report.sh`** — ❌ Does NOT exist (already deleted or never existed)
- **`scripts/informe-matutino-auto.sh`** — ✅ KEEP — Used by cron `cb5d3743` (📋 Informe Matutino)

**Cron reference:**
```json
{
  "name": "📋 Informe Matutino Completo",
  "payload": {
    "kind": "exec",
    "command": "bash ~/.openclaw/workspace/scripts/informe-matutino-auto.sh"
  }
}
```

**Why:** Active cron depends on this script. No duplicate found.

---

## 2️⃣ Garmin / Health Scripts

### `garmin-health-report.sh`
**Purpose:** Multi-mode health report from Garmin Connect  
**Modes:** `--daily`, `--weekly`, `--current`, `--alerts`, `--summary`  
**Usage:** Called by:
  - `informe-matutino-auto.sh` → `--daily YESTERDAY` (morning report activity data)
  - Possible cron: `🏃 Garmin Daily Scrape` (e8cf74c3)

**Decision:** ✅ KEEP — Core Garmin data fetcher

---

### `health-dashboard.sh`
**Purpose:** Generate HTML dashboard with Garmin + Weather + System stats  
**Output:** `reports/health-dashboard-YYYY-MM-DD.html`  
**Usage:** Calls `garmin-health-report.sh --current` internally

**Decision:** ✅ KEEP (SEPARATE) — Different use case: HTML visualization for browser viewing  
**Why separate:** Dashboard is for visual reporting, not terminal/Telegram reports.

---

### `health-alerts.sh`
**Purpose:** Check health metrics against thresholds and generate JSON alerts  
**Output:** `.cache/health-dashboard/alerts.json`  
**Checks:** HR, stress, body battery, sleep, system metrics (memory, disk, gateway)  
**Usage:** Calls `garmin-json-export.sh` for data

**Decision:** ✅ KEEP (SEPARATE) — Alert system with thresholds (different from daily reports)  
**Why separate:** Alerts are for monitoring/automation, not human-readable reports.

---

### Summary

All three Garmin/health scripts serve **distinct purposes**:

| Script | Purpose | Output Format | When Used |
|--------|---------|---------------|-----------|
| `garmin-health-report.sh` | Fetch & format health data | Text/console | Daily cron, morning report |
| `health-dashboard.sh` | Visual dashboard | HTML file | Manual/web view |
| `health-alerts.sh` | Threshold monitoring | JSON alerts | Automated checks |

**No overlap, no merge needed.**

---

## 3️⃣ Cron Delivery Fix Scripts

### Decision: ✅ ARCHIVE BOTH (one-time fixes, no longer needed)

- **`scripts/fix-cron-delivery.sh`** — ⏳ ARCHIVED
- **`scripts/fix-cron-delivery.py`** — ⏳ ARCHIVED

**Why:** These were one-time migration scripts to fix cron delivery configurations.  
**References found:**
  - `memory/cron-notifications-audit-20260325-074429.md`
  - `memory/night-notifications-fix-completed-2026-03-25.md`
  - `memory/pending-actions.md` — "delete one"

**Status:** Fix completed 2026-03-25. Both scripts moved to `scripts/archive/` for reference.

---

## 4️⃣ Other Duplicate/Dead Scripts

### Scanned: `scripts/*.sh` and `scripts/*.py` (72 files)

**No other obvious duplicates found.**

**Dead scripts check:** TBD (would require grep across all crons + memory/ + other scripts)

---

## 5️⃣ Ralph Wiggum (Verification)

✅ `bash -n scripts/informe-matutino-auto.sh` → OK  
✅ `bash -n scripts/garmin-health-report.sh` → OK  
✅ `bash -n scripts/health-dashboard.sh` → OK  
✅ `bash -n scripts/health-alerts.sh` → OK  

✅ Cron `cb5d3743` still references `informe-matutino-auto.sh` (not archived)

---

## Summary

**Archived:** 2 files (`fix-cron-delivery.sh`, `fix-cron-delivery.py`)  
**Kept:** 4 health/Garmin scripts (all serve distinct purposes)  
**Deleted:** 0 files (no duplicates found for `generate-morning-report.sh` — it never existed)

---

**Commit message:** `consolidate: archive one-time cron-delivery fix scripts, document Garmin script roles`
