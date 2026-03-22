# Weekly Health Patterns — Tracking Template

**Purpose:** Track week-over-week trends to identify patterns, seasonality, and the impact of interventions.

**Updated:** Every Monday (automated from weekly Garmin summary cron)

---

## Week of [YYYY-MM-DD to YYYY-MM-DD]

### Sleep Trends
- **Average total sleep:** [X.X] hours/night
- **Average deep sleep:** [X.X] hours/night
- **Nights <6.5h:** [N/7]
- **Best night:** [Day], [X.X]h
- **Worst night:** [Day], [X.X]h
- **Pattern notes:**
  - [e.g., "Poor sleep Mon-Wed, recovered Thu-Sun"]
  - [e.g., "Weekend sleep longer by ~1h"]

**Week-over-week:**
- Sleep duration: [+/- X.X]h vs previous week
- Deep sleep: [+/- X.X]h vs previous week
- Trend: ⬆️ Improving / ➡️ Stable / ⬇️ Declining

---

### Activity Trends
- **Total steps:** [XXXXX] (avg: [XXXX]/day)
- **Total distance:** [XX.X] km
- **Active days (≥7.5k steps):** [N/7]
- **Sedentary days (<5k steps):** [N/7]
- **Intensity minutes:** [XXX] total
- **Best day:** [Day], [XXXXX] steps
- **Activities logged:**
  - Surf: [N sessions]
  - Jorge training: [N sessions]
  - Surfskate: [N sessions]
  - Other: [List]

**Week-over-week:**
- Steps: [+/- XXXX]/day ([+/- X]%)
- Activity days: [+/- N]
- Trend: ⬆️ More active / ➡️ Similar / ⬇️ Less active

---

### Recovery Patterns
- **Avg resting HR:** [XX] bpm (range: [XX-XX])
- **Avg stress level:** [XX] (range: [XX-XX])
- **Avg Body Battery:** [XX]/100
- **Days with stress ≥50:** [N/7]
- **Days with Body Battery <50:** [N/7]
- **HRV notes:** [If available from device]

**Week-over-week:**
- Resting HR: [+/- X] bpm
- Stress: [+/- X] points
- Body Battery: [+/- X] points
- Trend: ⬆️ Better recovery / ➡️ Stable / ⬇️ Worse recovery

---

### Alerts & Interventions
- **Proactive alerts triggered:** [N]
  - [List specific alerts, e.g., "Sleep debt alert Wed", "High stress Thu-Fri"]
- **Interventions taken:**
  - [e.g., "Skipped surf Sat due to low Body Battery"]
  - [e.g., "Extra rest day Thursday"]
- **Outcome:**
  - [e.g., "Recovered by Sunday, Body Battery 82"]

---

### Correlations & Insights
- **Activity ↔ Recovery:**
  - [e.g., "High intensity training Mon → poor sleep Mon night → low Body Battery Tue"]
  - [e.g., "Surf sessions recover well if >7h sleep the night before"]

- **Calendar Impact:**
  - [e.g., "Late event Wed → sleep 5.8h → high stress Thu"]

- **Environmental:**
  - [e.g., "Poor surf conditions this week → less activity"]

- **Other observations:**
  - [Free-form notes]

---

### Recommendations Adjustments
- **What worked:**
  - [e.g., "Skipping Sat surf allowed full recovery"]
  - [e.g., "7.5h+ sleep → consistently good Body Battery"]

- **What didn't:**
  - [e.g., "Training back-to-back days → stress spike"]

- **Changes for next week:**
  - [e.g., "Schedule rest day between Jorge sessions"]
  - [e.g., "Target 8h sleep Thu-Sun for surf readiness"]

---

## Historical Summary (Last 4 Weeks)

| Week        | Avg Sleep | Avg Steps | Avg RHR | Avg Stress | Avg BB | Active Days | Alerts |
|-------------|-----------|-----------|---------|------------|--------|-------------|--------|
| YYYY-MM-DD  | X.Xh      | XXXXX     | XX bpm  | XX         | XX     | N/7         | N      |
| YYYY-MM-DD  | X.Xh      | XXXXX     | XX bpm  | XX         | XX     | N/7         | N      |
| YYYY-MM-DD  | X.Xh      | XXXXX     | XX bpm  | XX         | XX     | N/7         | N      |
| YYYY-MM-DD  | X.Xh      | XXXXX     | XX bpm  | XX         | XX     | N/7         | N      |

**Trend:** [Overall pattern description]

---

## Long-Term Tracking (Monthly)

### [Month YYYY-MM]
- **Sleep avg:** X.Xh/night
- **Steps avg:** XXXXX/day
- **RHR avg:** XX bpm
- **Stress avg:** XX
- **Body Battery avg:** XX
- **Surf sessions:** N
- **Training sessions:** N
- **Notable events:**
  - [e.g., "Started new training program"]
  - [e.g., "Travel week → disrupted patterns"]

---

## Template Instructions (for Lola)

**When updating this file:**

1. **Every Monday (automated):**
   - Add new "Week of" section with data from Garmin weekly summary
   - Calculate week-over-week comparisons
   - Update 4-week historical table
   - Note any alerts/interventions from the week

2. **End of month:**
   - Add monthly summary to Long-Term Tracking
   - Identify monthly trends
   - Archive detailed weekly data if >3 months old (keep summaries)

3. **Ad-hoc:**
   - Add insights as they emerge
   - Update correlations when new patterns observed
   - Refine recommendations based on outcomes

**Data sources:**
- Garmin weekly summary cron (Mon 8:30 AM)
- Daily alerts log
- Calendar integration (gog)
- Manual notes from Manu (if provided)

---

**First entry starts:** Week of 2026-03-24 (after Phase 4 implementation complete)
