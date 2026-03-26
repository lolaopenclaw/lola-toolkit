# Session Log Rotation

**Status:** ✅ Ready  
**Script:** `scripts/session-log-rotation.sh`  
**Created:** 2026-03-26

## Purpose

Manage disk space usage from OpenClaw session logs by compressing old logs and deleting ancient ones.

## Behavior

1. **Compress** `.jsonl` files older than 7 days → `.jsonl.gz` (gzip -9)
2. **Delete** `.jsonl.gz` files older than 30 days
3. **Skip** today's and yesterday's logs (actively written to)

## Usage

```bash
# Dry run (see what would be done)
bash scripts/session-log-rotation.sh --dry-run

# Execute rotation
bash scripts/session-log-rotation.sh

# Help
bash scripts/session-log-rotation.sh --help
```

## Output

- **Something done:** "✅ Session Log Rotation Complete" + summary
- **Nothing to do:** "LOG_ROTATION_OK"

## Integration

### Scripts Updated to Read Compressed Logs

1. **usage-report.sh** — API cost tracking
2. **performance-tracker.sh** — Latency analysis

Both now support reading `.jsonl.gz` files with `zcat`.

### Recommended Cron

Add to daily maintenance (e.g., 04:00):

```bash
bash scripts/session-log-rotation.sh >> logs/rotation.log 2>&1
```

## Current State (2026-03-26)

- **148+ session logs** in `~/.openclaw/agents/main/sessions/`
- **~60MB total**, oldest ~10 days ago
- **31 files** ready for compression (>7 days old)
- **0 files** ready for deletion (none >30 days old yet)

## Space Savings

Typical compression ratio: **~70-80%** (JSONL compresses very well)

Example:
- 31 files @ 400KB avg = ~12MB uncompressed
- After gzip: ~3MB compressed
- **Saves ~9MB** in first rotation

## Verification

```bash
# Syntax check
bash -n scripts/session-log-rotation.sh

# Linting
shellcheck scripts/session-log-rotation.sh

# Test (dry-run)
bash scripts/session-log-rotation.sh --dry-run
```

## Safety Features

- Uses `set -euo pipefail` for error handling
- Validates dependencies (find, gzip, stat, date)
- Checks sessions directory exists
- Never touches files <7 days old
- Never deletes .jsonl.gz files <30 days old
- Uses `$HOME` instead of hardcoded paths
- Dry-run mode for testing

## Notes

- Session logs grow ~400KB/day avg (varies by activity)
- Without rotation: ~12MB/month
- With rotation: ~3-4MB/month archived + current week uncompressed
- Old compressed logs still readable by all existing scripts
