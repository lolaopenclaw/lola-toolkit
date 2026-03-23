# Security & Config Change Protocol

## Pre-Restart Checklist (MANDATORY before any gateway restart)

1. **`openclaw doctor`** — run and verify 0 errors before restarting
2. **Verify secrets**: all `$ENV_VAR` references in `openclaw.json` must have matching entries in `~/.openclaw/.env`
3. **Syntax check**: `python3 -c "import json; json.load(open('$HOME/.openclaw/openclaw.json'))"` — must pass
4. **Backup**: `cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.pre-restart`
5. **Only then**: restart gateway

## Removal Protocol (API keys, integrations, services)

When removing an integration:
1. Delete cron jobs referencing it
2. Remove env var from `.env`
3. **ALSO remove any `openclaw.json` references** (skills.entries.X, secrets, etc.)
4. Run pre-restart checklist
5. Only then restart

## Post-Restart Verification

1. Check gateway status: `systemctl --user status openclaw-gateway`
2. Check for errors: `journalctl --user -u openclaw-gateway --since "1 minute ago" --no-pager -q | grep -i error`
3. If crash-looping → **immediately notify Manu** with diagnosis and proposed fix

## Subagent Config Changes

When a subagent modifies `openclaw.json` or `.env`:
- Parent session MUST verify the change before triggering restart
- Never trust subagent config changes blindly

## Incident: 2026-03-23 Notion Removal Crash Loop

- **Root cause**: Subagent removed NOTION_API_KEY from .env but left `skills.entries.notion.apiKey` in openclaw.json
- **Impact**: 568 crashes over 1h43m, required manual VNC intervention
- **Fix**: Always remove BOTH the env var AND the config reference
- **Lesson**: Pre-restart checklist is non-negotiable
