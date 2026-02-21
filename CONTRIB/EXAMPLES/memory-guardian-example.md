# Example: Memory Guardian in Action

## Scenario
Workspace has been running for 3 months. Memory files are growing.

## Status Check
```bash
$ bash scripts/memory-guardian.sh --status

📊 Memory Status
━━━━━━━━━━━━━━━
Total files:      142
Total size:       2.3 MB
Est. tokens:      ~580,000
Files >30 days:   89
Empty files:      7
Duplicates:       3 pairs

📈 Growth: +12 files/week (avg)
⚠️  At this rate, context overhead increases ~3,000 tokens/session
```

## Dry-Run Clean
```bash
$ bash scripts/memory-guardian.sh --clean --dry-run

🧹 Dry Run — No changes will be made
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Would remove (7 empty files):
  memory/2025-10-15.md (0 bytes)
  memory/2025-10-22.md (12 bytes, whitespace only)
  ...

Would archive (89 files >30 days → memory/archive/):
  memory/2025-10-01.md → memory/archive/2025-10/
  ...

Would merge (3 duplicate pairs):
  memory/2025-11-05.md ≈ memory/2025-11-05/01-setup.md (92% similar)
  ...

Summary:
  🗑️  7 files removed (4.2 KB freed)
  📦 89 files archived
  🔗 3 duplicates merged
  💰 Estimated token savings: ~45,000/session
```

## Result
After running `--full`:
- Workspace memory reduced from 2.3 MB to 890 KB
- Agent context load reduced by ~40%
- Old content preserved in archive (not deleted)
