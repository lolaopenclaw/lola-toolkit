# Manu — Health Profile

**Last updated:** 2026-03-22  
**Device:** Garmin Instinct 2S Solar Surf  
**Garmin account:** Manu_Lazarus

---

## Personal Data

- **Name:** Manuel León Mendiola
- **Age:** [To be filled based on available data]
- **Weight:** 109 kg
- **Height:** 1.80 m
- **BMI:** 33.6 (weight/height² in meters)

---

## Activity Profile

### Primary Activities

1. **Surf**
   - Primary sport and passion
   - Frequency: Variable (weather/conditions dependent)
   - Intensity: High (cardiovascular + strength)
   - Location: La Rioja coast access (specifics TBD)

2. **Surfskate**
   - Cross-training for surf technique
   - Frequency: [To be tracked]
   - Intensity: Moderate-high

3. **Functional Training with Jorge**
   - Personal training sessions
   - Frequency: [To be tracked from calendar integration]
   - Focus: General fitness, surf performance support
   - Intensity: High

### Activity Goals

- **Primary:** Support surf performance
- **Secondary:** General fitness and wellness
- **Tertiary:** Maintain healthy weight and cardiovascular health

---

## Garmin Data Available

### Real-time Metrics
- Heart rate (continuous monitoring)
- Steps and distance
- Floors climbed
- Calories burned
- Intensity minutes

### Recovery Metrics
- Resting heart rate (RHR)
- HRV (Heart Rate Variability)
- Stress level
- Body Battery
- VO2 max (if available from device)

### Sleep Tracking
- Total sleep time
- Sleep stages: Deep, Light, REM, Awake
- Sleep quality score
- Restlessness events

### Activity Tracking
- Workouts/sessions logged
- GPS tracks (for outdoor activities)
- Performance metrics per activity type

---

## Baselines (To Be Established)

**Note:** These baselines will be refined over time as we collect more data.

### Heart Rate
- **Resting HR (RHR):** ~50-55 bpm (typical for active individual)
- **Alert threshold:** >60 bpm sustained for 3+ days
- **Max HR estimate:** 220 - age (formula-based, device may provide better estimate)

### Sleep
- **Target:** 7-8 hours per night
- **Deep sleep target:** >1 hour
- **Alert threshold:** <6.5 hours for 3+ consecutive nights

### Stress
- **Normal range:** 0-40
- **Elevated:** 40-50
- **High (alert):** ≥50

### Body Battery
- **Optimal:** >75
- **Functional:** 50-75
- **Low (caution):** 25-50
- **Critical:** <25

### Activity
- **Steps target:** 7,500-10,000/day
- **Active days/week:** 4-5 (surf + training)
- **Sedentary threshold:** <5,000 steps

---

## Health Goals

### Short-term (3 months)
- Establish consistent baseline data
- Optimize recovery between surf sessions
- Maintain sleep quality during training cycles
- Track correlation between training load and recovery metrics

### Medium-term (6-12 months)
- Improve Body Battery recovery patterns
- Maintain or lower resting HR (indicator of cardiovascular fitness)
- Establish predictable patterns for surf performance optimization
- Reduce stress levels through better recovery management

### Long-term (1+ year)
- Sustained improvement in surf performance supported by health data
- Weight management aligned with fitness goals
- Injury prevention through fatigue monitoring
- Seasonal pattern recognition and adaptation

---

## Known Patterns (To Be Populated)

### Sleep
- [Will track: typical bedtime, wake time, sleep duration trends]
- [Weekend vs weekday differences]
- [Impact of late events/activities]

### Activity
- [Weekly patterns: which days are typically high/low activity]
- [Training cycles and recovery needs]
- [Seasonal variations]

### Recovery
- [How long does Manu typically need to recover from surf sessions?]
- [Body Battery recharge patterns]
- [Stress accumulation triggers]

### Surf Performance
- [Optimal conditions for Manu's fitness level]
- [Fatigue impact on session quality]
- [Best time of day based on energy patterns]

---

## Integration Notes

### Calendar Sync (gog)
- Training sessions with Jorge
- Planned surf sessions
- Events that might impact sleep/recovery
- Travel affecting routine

### Garmin Cron Schedule
- **Daily report:** 9:00 AM (activity from yesterday, sleep from last night)
- **Health alerts:** 2:00 PM, 8:00 PM (check for warning thresholds)
- **Weekly summary:** Monday 8:30 AM (7-day trends)

### Data Storage
- Daily reports: `/home/mleon/.openclaw/workspace/memory/health/daily-YYYY-MM-DD.md`
- Weekly summaries: Append to `/home/mleon/.openclaw/workspace/memory/health/weekly-patterns.md`
- Alerts log: Track in memory for pattern analysis

---

## Privacy & Data Handling

- All health data stays local in workspace
- No external sharing without explicit request
- GitHub publishing: health data excluded (see `.gitignore`)
- Garmin tokens: stored encrypted in `~/.openclaw/.env`

---

## Next Steps

1. **Week 1:** Establish baseline data collection
   - Run daily reports consistently
   - Track initial patterns
   - Note any anomalies or device issues

2. **Week 2-4:** Pattern identification
   - Calculate personal baselines (avg RHR, typical sleep, etc.)
   - Identify weekly rhythms
   - Correlate activity → recovery patterns

3. **Month 2+:** Optimization
   - Refine alert thresholds to Manu's norms
   - Develop personalized recommendations
   - Integrate with surf coach for performance link

---

**This profile is a living document. Update as we learn more about Manu's health patterns and as goals evolve.**
