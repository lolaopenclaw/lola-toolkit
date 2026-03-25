# Markdown Drift Checker

## Purpose
Automated auditing system that detects inconsistencies, broken references, orphaned files, and staleness in the OpenClaw workspace markdown files.

## How It Works

### 1. Cross-Reference Check
Scans key markdown files for broken links:
- Extracts all `.md` file references using regex
- Validates each reference exists (absolute or relative paths)
- Flags missing files as HIGH severity

**Key files scanned:**
- MEMORY.md
- TOOLS.md
- USER.md
- IDENTITY.md
- SOUL.md
- AGENTS.md
- HEARTBEAT.md

### 2. Conflict Detection
Identifies potentially conflicting information:
- Timezone references across USER.md, TOOLS.md, MEMORY.md
- Model references (Claude, GPT, Gemini variants)
- Uses heuristics to detect inconsistent values for the same concept

**Severity:** MEDIUM (requires manual review)

### 3. Duplicate Detection
Finds identical content across multiple files:
- Extracts meaningful sentences (20+ chars, not headers/lists)
- Compares across all key files
- Reports exact duplicates appearing in 2+ files

**Severity:** LOW (may be intentional)

### 4. Orphan Detection
Locates unreferenced files in `memory/`:
- Scans all `.md` files in `memory/` directory
- Checks if each file is referenced from workspace root `.md` files
- Also checks for cross-references within `memory/` itself
- Reports files with zero references

**Severity:** MEDIUM (potential clutter)

### 5. Staleness Check
Identifies outdated documentation:
- Finds `.md` files not modified in >90 days
- Calculates age in days
- Lists files that may need review

**Severity:** LOW (informational)

## Output

### Clean Run
```
✅ DRIFT_CHECK_OK
```
Exit code: 0

### Issues Found
```
❌ Issues found - see memory/drift-check-latest.md
```
Exit code: 1

### Report Format
Saved to `memory/drift-check-latest.md`:
```markdown
# Markdown Drift Check Report
Generated: 2026-03-25T21:00:00+01:00

**Status:** ❌ Issues detected

### [HIGH] Broken Link
**TOOLS.md** references non-existent file: `memory/missing-file.md`

### [MEDIUM] Orphaned Files
Found 5 file(s) in memory/ with no references:
  - memory/old-notes-2025.md
  - memory/deprecated-config.md
```

## Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| **HIGH** | Broken functionality (dead links) | Fix immediately |
| **MEDIUM** | Potential issues (orphans, conflicts) | Review and decide |
| **LOW** | Informational (duplicates, staleness) | Optimize when convenient |

## Usage

### Standalone
```bash
bash scripts/markdown-drift-checker.sh
```

### Via Cron (recommended)
Lola will schedule this to run periodically (e.g., weekly).

### Manual Inspection
```bash
cat memory/drift-check-latest.md
```

## What It Ignores

- `node_modules/`
- `.vectordb/`
- `autoimprove/`
- `logs/`
- Script files in `scripts/` (except READMEs)
- Common false positives: README.md, CHANGELOG.md, LICENSE.md

## Design Principles

1. **Read-only**: Never modifies existing markdown files
2. **Practical**: Focuses on real issues, not pedantic formatting
3. **Fast**: Efficient bash/grep processing
4. **Actionable**: Clear severity levels guide prioritization
5. **Robust**: Handles grep/bc no-match cases gracefully (`set -e` disabled to prevent false failures)

## Maintenance

### Adding New Key Files
Edit the `KEY_FILES` array in the script:
```bash
KEY_FILES=(
  "MEMORY.md"
  "TOOLS.md"
  # ... add new files here
)
```

### Adjusting Staleness Threshold
Change the days in `check_staleness()`:
```bash
local ninety_days_ago=$(date -d "90 days ago" +%s)
#                                  ^^^^ adjust this
```

### Enhancing Conflict Detection
The current implementation uses simple heuristics. To improve:
- Add specific pattern matching for known conflict scenarios
- Implement semantic comparison (requires more complex tooling)
- Cross-reference with config files (.env, config.json)

## Integration

This tool complements:
- **openclaw-checkpoint**: Ensures clean state before backups
- **autoimprove**: Provides drift reports for self-improvement
- **config-drift**: Covers config files; this covers markdown

## Future Enhancements

- [ ] JSON output format for programmatic consumption
- [ ] Incremental checks (only changed files since last run)
- [ ] Integration with vector DB to detect semantic drift
- [ ] Auto-fix mode for simple issues (broken links → update or remove)
- [ ] Diff view showing changes between referenced versions
