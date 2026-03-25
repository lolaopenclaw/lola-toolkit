# Rate Limit Monitoring Skill

Monitor API quota consumption and alert before limits are reached.

## Overview

This skill tracks usage of rate-limited APIs used by OpenClaw and sends Telegram alerts when thresholds are exceeded.

## Monitored APIs

| API | Limit | Reset Period | Warning % | Critical % | Check Interval |
|-----|-------|--------------|-----------|------------|----------------|
| Brave Search | 2,000 requests | Monthly | 80% | 95% | 6h |
| Google Gemini | 1,000 requests | Daily | 80% | 95% | 2h |
| Google Sheets | 100 requests | 100s | 80% | 95% | 2h |
| Google Drive | 1,000 requests | 100s | 80% | 95% | 2h |
| OpenAI Whisper | $50 USD | Monthly | 80% | 95% | 24h |
| Anthropic | 10 x 429/day | Daily | 50% | 80% | 1h |

## Components

### 1. Monitor Script (`scripts/rate-limit-monitor.py`)

Main monitoring script with three commands:

```bash
# Run all checks
rate-limit-monitor.py check

# Increment usage counter
rate-limit-monitor.py increment brave_search 1

# Reset counter manually
rate-limit-monitor.py reset brave_search
```

**Features:**
- Tracks usage locally (stored in `memory/rate-limit-status.json`)
- Logs metrics to `logs/rate-limit-metrics.jsonl` (last 30 days)
- Detects threshold breaches (warning 80%, critical 95%)
- Generates alert files for Telegram notifications
- Auto-resets counters based on quota periods

### 2. Status Dashboard (`scripts/rate-limit-status`)

CLI dashboard showing current status:

```bash
rate-limit-status
```

**Output:**
```
Rate Limit Status Dashboard
Generated: 2026-03-24 10:00:00 UTC

┌─────────────────────┬──────────┬─────────┬────────┬────────────────────┐
│ API                 │ Used     │ Limit   │ %      │ Status             │
├─────────────────────┼──────────┼─────────┼────────┼────────────────────┤
│ Brave Search        │      106 │   2,000 │   5.3% │ ✅ OK              │
│ Google Gemini       │      450 │   1,000 │  45.0% │ ✅ OK              │
│ Google Sheets       │       12 │     100 │  12.0% │ ✅ OK              │
│ Google Drive        │       89 │   1,000 │   8.9% │ ✅ OK              │
│ OpenAI Whisper      │  $12.50  │     $50 │  25.0% │ ✅ OK              │
│ Anthropic           │        2 │      10 │  20.0% │ ✅ OK              │
└─────────────────────┴──────────┴─────────┴────────┴────────────────────┘

Next Quota Resets:
  • Brave Search: 2026-04-01 00:00 UTC
  • Google Gemini: 2026-03-25 00:00 UTC
  • Google Sheets: 2026-03-24 10:01 UTC
  • Google Drive: 2026-03-24 10:01 UTC
  • OpenAI Whisper: 2026-04-01 00:00 UTC
  • Anthropic: 2026-03-25 00:00 UTC
```

### 3. Alert System

When thresholds are exceeded, alerts are written to:
```
memory/rate-limit-alert-pending.json
```

The main agent checks this file periodically and sends Telegram messages.

**Alert Format:**
```
🚨 CRITICAL: Rate Limit Alert - Brave Search

Usage: 1950/2000 requests (97.5%)
Status: CRITICAL threshold exceeded (>95%)
Reset: monthly

Actions:
• Consider upgrading Brave Search plan
• Reduce search frequency
• Cache search results when possible
```

### 4. Integration with Existing Tools

To increment counters automatically, wrap API calls:

**Example for Brave Search:**
```bash
# Before web_search tool call
rate-limit-monitor.py increment brave_search 1
```

**Example for Google Sheets:**
```bash
# After gog sheets command
rate-limit-monitor.py increment google_sheets 1
```

## Storage

### Status File (`memory/rate-limit-status.json`)

Current state of all monitored APIs:

```json
{
  "brave_search": {
    "used": 106,
    "limit": 2000,
    "pct": 5.3,
    "last_check": "2026-03-24T10:00:00+00:00",
    "quota_reset": "2026-04-01T00:00:00+00:00",
    "last_alert": "2026-03-20T15:30:00+00:00"
  },
  "google_gemini": {
    "used": 450,
    "limit": 1000,
    "pct": 45.0,
    "last_check": "2026-03-24T10:00:00+00:00",
    "quota_reset": "2026-03-25T00:00:00+00:00"
  }
}
```

### Metrics Log (`logs/rate-limit-metrics.jsonl`)

Historical data (last 30 days):

```jsonl
{"timestamp": "2026-03-24T10:00:00+00:00", "api": "brave_search", "used": 106, "limit": 2000, "pct": 5.3}
{"timestamp": "2026-03-24T10:00:00+00:00", "api": "google_gemini", "used": 450, "limit": 1000, "pct": 45.0}
```

## Cron Schedule

Automated checks via cron (configured separately):

```bash
# Brave Search - every 6h
0 */6 * * * ~/.openclaw/workspace/scripts/rate-limit-monitor.py check >> ~/.openclaw/workspace/logs/rate-limit-cron.log 2>&1

# Google APIs - every 2h
0 */2 * * * ~/.openclaw/workspace/scripts/rate-limit-monitor.py check >> ~/.openclaw/workspace/logs/rate-limit-cron.log 2>&1

# OpenAI - daily at 12:00
0 12 * * * ~/.openclaw/workspace/scripts/rate-limit-monitor.py check >> ~/.openclaw/workspace/logs/rate-limit-cron.log 2>&1

# Anthropic - every hour
0 * * * * ~/.openclaw/workspace/scripts/rate-limit-monitor.py check >> ~/.openclaw/workspace/logs/rate-limit-cron.log 2>&1
```

**Note:** Single unified cron running every hour covers all APIs (most frequent check interval).

## Usage Patterns

### Manual Check

```bash
# Run all checks
rate-limit-monitor.py check

# View status
rate-limit-status
```

### Increment After API Call

```bash
# After Brave search
rate-limit-monitor.py increment brave_search

# After Google Sheets operation
rate-limit-monitor.py increment google_sheets

# After Whisper transcription (cost in USD)
rate-limit-monitor.py increment openai_whisper 0.12
```

### Reset Counter

```bash
# Manual reset (e.g., after plan upgrade)
rate-limit-monitor.py reset brave_search
```

### Check Alert Status

```bash
# Check if alerts pending
cat ~/.openclaw/workspace/memory/rate-limit-alert-pending.json
```

## Alert Suppression

Alerts are suppressed for 6 hours after being sent to avoid spam. This is tracked via the `last_alert` timestamp in status.

## Testing

### Simulate High Usage

```bash
# Increment Brave Search to 80%
rate-limit-monitor.py increment brave_search 1494  # Gets to 1600/2000

# Run check (should trigger warning alert)
rate-limit-monitor.py check

# Increment to 95%
rate-limit-monitor.py increment brave_search 300  # Gets to 1900/2000

# Run check (should trigger critical alert)
rate-limit-monitor.py check

# View dashboard
rate-limit-status
```

### Reset After Test

```bash
rate-limit-monitor.py reset brave_search
```

## Troubleshooting

### No data showing

```bash
# Initialize with a check
rate-limit-monitor.py check

# Verify status file created
cat ~/.openclaw/workspace/memory/rate-limit-status.json
```

### Alerts not sending

Check pending alert file:
```bash
cat ~/.openclaw/workspace/memory/rate-limit-alert-pending.json
```

The main agent should pick this up and send via Telegram.

### Counter not resetting

Check logs:
```bash
tail -f ~/.openclaw/workspace/logs/rate-limit-cron.log
```

Verify reset logic in status file (quota_reset timestamp).

## Future Enhancements

1. **Real API Integration**
   - OpenAI Usage API for actual costs
   - Google Cloud Console API for real quotas
   - Brave Search response headers parsing

2. **Predictive Alerts**
   - Alert 1 hour before quota exhaustion based on usage rate
   - Trend analysis from metrics log

3. **Dashboard Web UI**
   - Real-time graph of usage over time
   - Integration with existing dashboard-api-server.js

4. **Auto-throttling**
   - Slow down requests when approaching limits
   - Queue non-critical requests until reset

## References

- Monitor script: `~/.openclaw/workspace/scripts/rate-limit-monitor.py`
- Dashboard: `~/.openclaw/workspace/scripts/rate-limit-status`
- Status: `~/.openclaw/workspace/memory/rate-limit-status.json`
- Metrics: `~/.openclaw/workspace/logs/rate-limit-metrics.jsonl`
- Alerts: `~/.openclaw/workspace/memory/rate-limit-alert-pending.json`

---

**Created:** 2026-03-24  
**Author:** Lola (Subagent)  
**Status:** Active ✅
