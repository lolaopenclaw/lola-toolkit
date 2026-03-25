# Config Drift Detection Skill

Detect unexpected changes in OpenClaw critical configuration files.

## What It Does

Monitors critical config files for changes and classifies them as:
- **INFO**: Benign changes (comments, whitespace, timestamps)
- **WARN**: Suspicious changes (new secrets, model changes, endpoint URLs)
- **CRITICAL**: Dangerous changes (insecure permissions, sudo commands, file deletion)

## Monitored Files

1. `~/.openclaw/openclaw.json` — Main configuration
2. `~/.openclaw/.env` — Environment variables
3. `~/.openclaw/cron/jobs.json` — Cron jobs
4. `~/.openclaw/agents/main/agent/auth-profiles.json` — Agent auth profiles
5. `~/.config/systemd/user/openclaw-gateway.service` — SystemD service

## CLI Commands

### Initialize Baselines

Create initial snapshots of all config files:

```bash
config-drift init
```

Run this once when first setting up drift detection, or after a clean config change.

### Check for Drift

Check all files:

```bash
config-drift check
```

Check specific file:

```bash
config-drift check ~/.openclaw/openclaw.json
```

### Approve Changes

After reviewing changes, approve and update baseline:

```bash
config-drift approve ~/.openclaw/openclaw.json
```

This updates the baseline hash and creates a backup.

### Reject Changes

Rollback to last known good version:

```bash
config-drift reject ~/.openclaw/openclaw.json
```

This restores from the most recent backup and updates the baseline.

### View Detailed Diff

See exactly what changed:

```bash
config-drift diff ~/.openclaw/openclaw.json
```

## How It Works

### Baseline Creation

- Calculates SHA256 hash of each config file
- Stores hash + metadata in `~/.openclaw/workspace/config-baselines/`
- Creates backup copy in `~/.openclaw/backups/config-drift/`

### Drift Detection

1. Calculate current hash
2. Compare with baseline hash
3. If different:
   - Generate unified diff
   - Classify changes using pattern matching
   - Alert based on severity

### Change Classification

**CRITICAL** patterns:
- `chmod 777` or similar insecure permissions
- `sudo` commands added
- `rm -rf /` dangerous deletions
- Passwords in command lines
- File deletion

**WARN** patterns:
- New API keys/secrets/tokens
- Model name changes
- New endpoint URLs
- SystemD service command changes
- Environment variable key changes

**INFO** patterns:
- Comments added/changed
- Timestamp updates
- Whitespace changes

## Integration Points

### Pre-Restart Hook

Add to restart validation flow:

```bash
# Before restarting OpenClaw
config-drift check
if [[ $? -ne 0 ]]; then
    echo "Config drift detected - review before proceeding"
    exit 1
fi
```

### Daily Cron

Catch manual edits:

```bash
# Add to crontab
0 2 * * * /home/mleon/.openclaw/workspace/scripts/config-drift check
```

### Systemd Pre-Start

Add to `openclaw-gateway.service`:

```ini
[Service]
ExecStartPre=/home/mleon/.openclaw/workspace/scripts/config-drift check
```

## Workflow Examples

### Scenario 1: Legitimate Config Change

```bash
# Edit openclaw.json (change model)
vim ~/.openclaw/openclaw.json

# Check drift
config-drift check
# Output: ⚠️ WARN: Suspicious changes: Model changed

# Review diff
config-drift diff ~/.openclaw/openclaw.json

# Approve if OK
config-drift approve ~/.openclaw/openclaw.json
# Output: ✅ Changes approved and baseline updated
```

### Scenario 2: Suspicious Change

```bash
# Someone adds new API key to .env
echo "MALICIOUS_KEY=abc123" >> ~/.openclaw/.env

# Check drift
config-drift check
# Output: ⚠️ WARN: Suspicious changes: New secret/API key

# Review diff
config-drift diff ~/.openclaw/.env

# Reject if malicious
config-drift reject ~/.openclaw/.env
# Output: ✅ Changes rejected and file rolled back
```

### Scenario 3: Critical Change

```bash
# Insecure permissions set
chmod 777 ~/.openclaw/openclaw.json

# Check drift
config-drift check
# Output: 🚨 CRITICAL: Critical change detected: Insecure permissions (777)

# Must manually approve or reject
config-drift reject ~/.openclaw/openclaw.json
```

## File Structure

### Baselines Directory

```
~/.openclaw/workspace/config-baselines/
├── _home_mleon_.openclaw_openclaw.json.baseline
├── _home_mleon_.openclaw_.env.baseline
├── _home_mleon_.openclaw_cron_jobs.json.baseline
└── ...
```

Each `.baseline` file contains:

```json
{
  "file": "/home/mleon/.openclaw/openclaw.json",
  "hash": "a3f5e2d1b4c6...",
  "size": 12345,
  "created": "2026-03-24T10:00:00Z",
  "last_checked": "2026-03-24T10:15:00Z"
}
```

### Backups Directory

```
~/.openclaw/backups/config-drift/
├── _home_mleon_.openclaw_openclaw.json.20260324_100000.backup
├── _home_mleon_.openclaw_openclaw.json.20260324_110000.backup
└── ...
```

## Exit Codes

- `0` - No drift detected or command successful
- `1` - Error occurred or drift detected

## Edge Cases

### Baseline Corruption

If baseline file is corrupted:

```bash
# Recreate baseline
config-drift init
```

### File Deletion

If monitored file is deleted:

```bash
config-drift check
# Output: 🚨 CRITICAL: FILE DELETED

# Restore from backup
config-drift reject <filepath>
```

### Multiple Simultaneous Changes

Each file is checked and alerted independently. Review and approve/reject each one separately.

### No Backup Available

On first run before any backups exist:

```bash
config-drift check
# Output: Hash changed: a3f5e2d1 → b4c6d2e3
#         (No backup available for detailed diff)
```

Solution: Always run `config-drift init` first.

## Security Considerations

- Baselines stored in workspace (user-readable)
- Backups stored in `~/.openclaw/backups/` (700 permissions)
- Sensitive files (.env) should have restricted permissions (600)
- Pattern matching is heuristic - review all WARN/CRITICAL alerts manually

## Performance

- Hash calculation: ~1-5ms per file
- Diff generation: ~10-50ms per file
- Total check time: <100ms for all 5 files

Safe to run on every restart or in tight loops.

## Future Enhancements

- Telegram notification integration
- More sophisticated pattern matching (ML-based?)
- Automatic rollback on CRITICAL + restart block
- Config file integrity signing
- Distributed baseline sync across nodes

## Testing

See test suite: `skills/config-drift/tests/test-drift-detection.sh`

## Troubleshooting

### "No baseline exists"

Run `config-drift init` first.

### "No backup found"

Baseline exists but no backup - this can happen if baseline was created manually. Run:

```bash
# Create backup from current file
cp ~/.openclaw/openclaw.json ~/.openclaw/backups/config-drift/_home_mleon_.openclaw_openclaw.json.$(date +%Y%m%d_%H%M%S).backup
```

### Changes not detected

- Verify baseline exists: `ls ~/.openclaw/workspace/config-baselines/`
- Check file permissions (must be readable)
- Verify hash changed: `config-drift diff <file>`

## Dependencies

- Python 3.6+
- Standard library only (no pip packages required)

## License

Part of OpenClaw workspace skills.
