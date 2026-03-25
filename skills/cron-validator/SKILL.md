# cron-validator

**Validate OpenClaw cron jobs before deployment**

Catches schedule syntax errors, missing scripts, broken dependencies, and missing environment variables before jobs go live.

---

## When to Use

- **Before adding new cron jobs** — Use `cron-add-safe` instead of `openclaw cron add`
- **Auditing existing jobs** — Run validation on all enabled crons
- **Troubleshooting failures** — Check validation reports for error patterns
- **CI/CD pipelines** — Validate cron configs in pre-commit hooks

---

## Tools

### 1. `cron-validator.py` — Core validation engine

**Location:** `~/.openclaw/workspace/scripts/cron-validator.py`

**Usage:**
```bash
# Validate specific job by ID
cron-validator.py --job-id <cron-id>

# Validate all enabled jobs
cron-validator.py --validate-all

# Validate from JSON file
cron-validator.py --job-json /path/to/job.json

# Skip Telegram notifications
cron-validator.py --job-id <id> --no-notify

# Custom output path
cron-validator.py --job-id <id> --output /tmp/report.json
```

**What it validates:**

1. **Schedule syntax** ✅
   - Cron expressions: `*/5 * * * *` (validated with croniter)
   - ISO timestamps: `2026-06-24T10:00:00+02:00`
   - Relative times: `every 6h`

2. **Script existence** ✅
   - Detects `scripts/*.sh`, `skills/*/SKILL.md`, etc.
   - Verifies files exist and are executable
   - Checks both workspace-relative and absolute paths

3. **Dependency check** ✅
   - Python imports: `import X` → checks with `python3 -c "import X"`
   - Node modules: `require('X')` → checks with `npm list -g X`
   - Binaries: `gh`, `jq`, `curl`, etc. → checks with `which`

4. **Environment variables** ⚠️
   - Detects `$VAR`, `${VAR}`, `process.env.VAR`, `os.getenv("VAR")`
   - Cross-checks with `~/.openclaw/.env`
   - **Warns but doesn't fail** (env vars can come from system)

5. **Dry-run simulation** ✅
   - For `systemEvent`: checks for empty placeholders `${...}`
   - For `agentTurn`: validates message not empty, flags `TODO` markers
   - Detects very long messages (>10k chars)

**Exit codes:**
- `0` — All jobs passed validation
- `1` — One or more jobs failed validation

---

### 2. `cron-add-safe` — Wrapper for safe cron deployment

**Location:** `~/.openclaw/workspace/scripts/cron-add-safe`

**Usage:**
```bash
# Use exactly like openclaw cron add
cron-add-safe --name "My Job" --schedule "cron 0 10 * * *" --message "Do something"

# Force deployment even if validation fails
cron-add-safe --name "Test Job" --schedule "invalid cron" --force
```

**What it does:**

1. **Pre-flight checks** (fast, inline):
   - Validates schedule format
   - Checks referenced scripts exist
   - Warns about missing env vars

2. **Adds the job** if pre-flight passes

3. **Full validation** on the newly added job:
   - Runs `cron-validator.py --job-id <new-id>`
   - Generates detailed report
   - Shows summary in terminal

4. **Fail-safe:**
   - If validation fails, job is still added (not auto-removed)
   - User can inspect, fix, or delete manually
   - Validation report saved for review

---

## Validation Reports

**Location:** `~/.openclaw/workspace/cron-validation-reports/`

**Format:** `YYYY-MM-DD-<cron-id>.json`

**Example report:**
```json
{
  "job_id": "abc123...",
  "job_name": "📊 Morning Report",
  "timestamp": "2026-03-24T10:30:00+01:00",
  "overall_valid": false,
  "errors": [
    "Missing script: scripts/missing-report.sh",
    "Missing dependency: binary:gh"
  ],
  "warnings": [
    "Missing env var: SOME_API_KEY",
    "Dry-run: Message contains TODO marker"
  ],
  "checks": {
    "schedule": {"valid": true, "error": null},
    "scripts": {"valid": false, "missing": ["scripts/missing-report.sh"]},
    "dependencies": {"valid": false, "missing": ["binary:gh"]},
    "env_vars": {"valid": true, "missing": ["SOME_API_KEY"]},
    "dry_run": {"valid": true, "warnings": ["Message contains TODO marker"]}
  }
}
```

---

## Telegram Notifications

**When sent:**
- Validation FAILS (overall_valid: false)
- Critical warnings detected

**When NOT sent:**
- Clean validation (no errors, no warnings)
- `--no-notify` flag used
- Validation passes with minor warnings only

**Message format:**
```
**Cron Validation: ❌ VALIDATION FAILED**

Job: 📊 Morning Report
ID: abc123...

**Errors:**
• Missing script: scripts/missing-report.sh
• Missing dependency: binary:gh

**Warnings:**
• Missing env var: SOME_API_KEY
• Dry-run: Message contains TODO marker
```

---

## Integration Examples

### Example 1: Validate before adding (recommended)
```bash
cron-add-safe \
  --name "Backup Memory Daily" \
  --schedule "cron 0 4 * * *" \
  --message "Run backup: bash scripts/backup-memory.sh"
```

### Example 2: Audit all existing crons
```bash
cron-validator.py --validate-all
```

### Example 3: Check specific failing job
```bash
# Get job ID
openclaw cron list | grep FAILING

# Validate
cron-validator.py --job-id dcae7b06-e6fb-40d4-88bc-9bc618feb70d
```

### Example 4: Pre-commit hook (future enhancement)
```bash
# In .git/hooks/pre-commit
#!/bin/bash
if git diff --cached --name-only | grep -q 'cron-jobs/'; then
    cron-validator.py --validate-all || {
        echo "❌ Cron validation failed. Fix errors or use --force"
        exit 1
    }
fi
```

---

## Common Issues & Fixes

### Issue: "croniter not installed"
**Fix:**
```bash
pip3 install --user --break-system-packages croniter
```

### Issue: "Missing script: scripts/my-script.sh"
**Fix:**
1. Verify script exists: `ls ~/.openclaw/workspace/scripts/my-script.sh`
2. If missing, create it or fix the path in the cron message
3. Make executable: `chmod +x scripts/my-script.sh`

### Issue: "Missing env var: MY_VAR"
**Fix:**
1. Add to `~/.openclaw/.env`:
   ```
   MY_VAR=value123
   ```
2. Or export in shell: `export MY_VAR=value123`
3. Restart gateway: `openclaw gateway restart`

### Issue: "Invalid cron expression"
**Fix:**
```bash
# Wrong:
--schedule "cron 0 10 * *"  # Only 4 fields

# Right:
--schedule "cron 0 10 * * *"  # 5 fields (minute hour day month weekday)
```

---

## Testing

Run the test suite (see below) to verify validator works correctly:

```bash
cd ~/.openclaw/workspace/skills/cron-validator
bash scripts/test-validator.sh
```

**Tests included:**
1. ✅ Valid cron → should PASS
2. ❌ Invalid schedule → should FAIL
3. ❌ Missing script → should FAIL
4. ⚠️ Missing env var → should WARN
5. ⚠️ Missing dependency → should WARN/FAIL
6. ✅ systemEvent with text → should PASS
7. ❌ Empty agentTurn → should FAIL

---

## Maintenance

**Keep validation rules updated:**

- When new OpenClaw features are added (e.g., new schedule types), update `validate_schedule()`
- When common failure patterns emerge, add to `dry_run()`
- Review validation reports weekly to spot false positives

**Performance:**
- Validation takes ~2-5 seconds per job
- Dependency checks are cached by system package managers
- For bulk validation (100+ jobs), expect ~5-10 minutes

---

## Future Enhancements

- [ ] Git pre-commit hook integration
- [ ] GitHub Actions workflow for cron config validation
- [ ] Auto-fix suggestions (e.g., "chmod +x scripts/X.sh")
- [ ] Historical trend analysis (jobs that fail repeatedly)
- [ ] Slack/Discord notification support
- [ ] Web UI for validation reports
- [ ] Schedule conflict detection (too many jobs at same time)

---

## Related

- **OpenClaw cron docs:** `openclaw cron --help`
- **Healthcheck skill:** For validating system security state
- **Backup validator:** `scripts/backup-validator.sh` (similar pattern)
