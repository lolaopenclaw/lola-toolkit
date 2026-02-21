# Proposal: Health-Aware Agent (Garmin Integration)

## Problem

AI agents communicate the same way regardless of the user's physical state. They don't know if you're exhausted, stressed, recovering from a workout, or sleeping poorly.

## Solution

Integrate Garmin Connect health data so the agent can adapt its communication style and recommendations based on the user's physical context.

### Features

- **Daily health reports** — Sleep, stress, body battery, activity
- **Alert thresholds** — Notify when metrics are concerning
- **Historical analysis** — Trends over time
- **Agent context** — Agent adjusts tone/urgency based on health data

### Example Agent Behavior

```
Body Battery: 15/100, Stress: High, Sleep: 4h
→ Agent: Keeps messages brief, defers non-urgent items, suggests rest

Body Battery: 90/100, Stress: Low, Sleep: 8h  
→ Agent: Full reports, suggests tackling complex tasks
```

## Requirements

- Garmin Connect account
- `garminconnect` Python package
- OAuth tokens stored in `.env`

## Genericization Needed

- Abstract health data source (not just Garmin — could support Apple Health, Fitbit)
- Configuration for thresholds and alert preferences
- English documentation
- Privacy controls (health data is sensitive)

## Why This Should Be in OpenClaw

1. **Human-centered AI** — Agents that respect your physical state
2. **Unique differentiator** — No other AI assistant does this
3. **Opt-in** — Only for users who want it
4. **Extensible** — Interface could support multiple health platforms
