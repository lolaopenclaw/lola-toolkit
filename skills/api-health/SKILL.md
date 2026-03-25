# api-health

Monitor critical OpenClaw APIs, handle failover, and alert on status changes.

## When to Use

Use when:
- Checking if critical APIs (Anthropic, Google, Telegram) are operational
- Investigating outages or degraded performance
- Setting up automated monitoring
- Reviewing API health history
- Manually triggering failover to backup providers

NOT for:
- Testing user applications
- Network diagnostics (use `ping`, `traceroute`)
- General system health (see `healthcheck` skill)

## Requirements

- Python 3.8+
- Dependencies: `requests`, `pytz` (installed in venv at `scripts/api-health-venv/`)
- Config: `~/.openclaw/workspace/config/api-health-config.json`
- Environment: API keys in `~/.openclaw/.env`

## Usage

### Check All APIs

```bash
python3 scripts/api-health-checker.py --check all
```

### Check Specific API

```bash
python3 scripts/api-health-checker.py --check anthropic
python3 scripts/api-health-checker.py --check telegram
python3 scripts/api-health-checker.py --check google
```

### Show Current Status

```bash
python3 scripts/api-health-checker.py --status
```

### Interactive Mode

```bash
python3 scripts/api-health-checker.py --interactive
```

## What It Does

1. **Health Checks**: Tests API endpoints with minimal requests
2. **Failover**: Automatically switches to backup providers when primary fails
3. **Alerting**: Sends Telegram notifications on status changes (respects quiet hours)
4. **History**: Tracks status over time in `memory/api-health-history.json`
5. **Logging**: Records all checks in `logs/api-health.log`

## Monitored APIs

| API | Priority | Check Interval | Failover |
|-----|----------|----------------|----------|
| Anthropic | Critical | 30 min | → Google |
| Google | High | 2 hours | - |
| Telegram | High | 2 hours | - |
| GitHub | Medium | Daily | - |
| Garmin | Medium | Daily | - |
| Brave Search | Medium | Daily | - |

## Configuration

Edit `config/api-health-config.json`:

- **Check intervals**: Adjust `check_interval_minutes` per API
- **Quiet hours**: Mute alerts overnight (default: 00:00-07:00 Madrid)
- **Failover**: Enable/disable auto-switching, set restore delay
- **Alerting**: Toggle Telegram notifications, set chat ID

## Cron Schedule

For automated monitoring, add to cron:

```bash
# Every 30 minutes: check critical APIs
*/30 * * * * cd ~/.openclaw/workspace && python3 scripts/api-health-checker.py --check all >> logs/api-health-cron.log 2>&1
```

## Status Files

- **Current status**: `memory/api-health-status.json`
- **History**: `memory/api-health-history.json` (7-day rolling)
- **Logs**: `logs/api-health.log` (rotates at 10MB)

## Failover Behavior

When Anthropic fails:
1. Script backs up `~/.openclaw/openclaw.json`
2. Updates `agents.defaults.chatModel.primary` to Google
3. Sends alert if outside quiet hours
4. Auto-restores after 60 minutes if Anthropic recovers

## Troubleshooting

### No API key errors

Ensure keys are in `~/.openclaw/.env`:
```
ANTHROPIC_API_KEY=sk-ant-...
GEMINI_API_KEY=AIza...
TELEGRAM_BOT_TOKEN=123456:ABC...
```

### Permission errors

```bash
chmod +x scripts/api-health-checker.py
```

### Venv issues

```bash
cd scripts
python3 -m venv api-health-venv
source api-health-venv/bin/activate
pip install requests pytz
```

## Examples

**Morning check before work:**
```bash
python3 scripts/api-health-checker.py --status
```

**Investigate why Claude is slow:**
```bash
python3 scripts/api-health-checker.py --check anthropic
# Check latency in output
```

**Force failover test:**
```bash
# Temporarily break Anthropic key, then:
python3 scripts/api-health-checker.py --check anthropic
# Verify openclaw.json switched to Google
```

## Agent Instructions

When Manu asks about API status:
1. Run `--status` first for overview
2. If issues found, check specific API with `--check <name>`
3. Report latency, error details, and failover status
4. If down >10 minutes, proactively suggest checking provider status pages

When setting up monitoring:
1. Verify venv and dependencies exist
2. Test `--check all` manually
3. Add cron job (respect work schedule from `memory/work-schedule.md`)
4. Confirm first run succeeds

## Related

- `healthcheck` skill: System-level security/hardening
- `github` skill: GitHub-specific operations beyond health checks
- `TOOLS.md`: Provider-specific notes (speaker names, etc.)
