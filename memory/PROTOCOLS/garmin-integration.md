# Garmin Connect Integration

## Setup
- **Device:** Garmin Instinct 2S Solar Surf
- **Display Name:** Manu_Lazarus
- **Library:** python-garminconnect 0.2.38 (via garth OAuth)
- **Tokens:** Base64 OAuth tokens in `~/.openclaw/.env` as `GARMIN_TOKENS=...`
- **Fix crítico:** `client.display_name = "Manu_Lazarus"` must be set after loading tokens

## Scripts

### `scripts/garmin-health-report.sh`
```bash
bash garmin-health-report.sh --daily [YYYY-MM-DD]  # Full daily report
bash garmin-health-report.sh --weekly               # 7-day summary + trends
bash garmin-health-report.sh --current              # Compact live status
bash garmin-health-report.sh --alerts               # Delegates to check-alerts
bash garmin-health-report.sh --summary              # Same as --weekly
```

### `scripts/garmin-check-alerts.sh`
```bash
bash garmin-check-alerts.sh                # Check all alerts
bash garmin-check-alerts.sh --hr-abnormal  # HR reposo >60 or <40
bash garmin-check-alerts.sh --stress-high  # Estrés >50
bash garmin-check-alerts.sh --sleep-low    # <6.5h sueño
bash garmin-check-alerts.sh --battery-critical  # Body Battery <20%
```
Output includes `ALERT_COUNT=N` and `ALERT_TYPES=...` for machine parsing.

### `scripts/garmin-historical-analysis.sh`
```bash
bash garmin-historical-analysis.sh [days]  # Default: 30 days
```

## Alert Thresholds
| Metric | Threshold | Level |
|--------|-----------|-------|
| HR reposo alto | >60 bpm | warning |
| HR reposo bajo | <40 bpm | warning |
| HR máximo | >180 bpm | info |
| Estrés | ≥50 | warning |
| Sueño total | <6.5h | warning |
| Sueño profundo | <0.5h | info |
| Body Battery | <20 | warning |

## Cron Schedule
| Cron | Schedule | Script |
|------|----------|--------|
| garmin-morning-report | 9:00 diario | --daily |
| garmin-health-alerts | 14:00, 20:00 diario | check-alerts |
| garmin-weekly-summary | Lun 8:30 | --weekly |

## HEARTBEAT Integration
During heartbeats, run `--current` for quick health context. Use to adjust communication:
- **Estrés alto:** Ofrecer pausas, no proponer tareas pesadas
- **Sueño malo:** Evitar tareas cognitivamente demandantes
- **Body Battery bajo:** Sugerir descanso
- **HR elevado:** Preguntar si está bien

## Troubleshooting
- **Token expired:** Tokens refresh automatically via garth. If persistent auth errors, need to re-login.
- **No data:** Some metrics may not be available if watch wasn't worn.
- **displayName error:** Always set `client.display_name = "Manu_Lazarus"` after loading client.

## Data Available
- Heart rate (resting, avg, max, timeline)
- Steps, distance, calories, floors, intensity minutes
- Stress level (average)
- Body Battery (current, min, max)
- Sleep (total, deep, light, REM, awake)
- Activities/workouts
