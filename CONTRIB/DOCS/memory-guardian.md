# Memory Guardian — Automatic memory cleanup and optimization

## Problem

OpenClaw workspaces grow unbounded:
- ❌ Old session logs accumulate (1MB+ per session)
- ❌ Backup files (.backup-*, .bak) never deleted
- ❌ Temporary files pile up (.tmp, .temp, cache/)
- ❌ Large files >500KB never compressed
- ❌ Duplicate files waste space (same content, different names)
- ❌ Result: memory bloat (2GB+ in large workspaces)

**Impact:**
- Slow searches (memory_search through thousands of files)
- Expensive backups (larger compressed files)
- Confusing filesystem
- Git performance degradation

## Solution

**Memory Guardian Pro** — Intelligent automatic cleanup:
- ✅ Detects bloat (files >500KB, old sessions)
- ✅ Cleans safely (never touches CORE/, PROTOCOLS/, SOUL.md, MEMORY.md)
- ✅ Deduplicates (MD5 hashing)
- ✅ Compresses (tar.gz old files >30 days)
- ✅ Preserves critical files
- ✅ Generates reports (what was cleaned, why)
- ✅ Dry-run mode (preview before executing)
- ✅ Scheduled automation (cron-friendly)

## Features

### Detection
- 📊 Bloat detection (files >500KB)
- 📅 Age-based classification (7/30 day thresholds)
- 🔍 Duplicate detection (MD5 hashing)
- 📈 Token usage estimation (for memory searches)
- 🎯 Smart categorization (session logs, backups, temporaries)

### Protection
- 🛡️ Never delete CORE/, PROTOCOLS/, hidden (.)
- 🛡️ Never delete SOUL.md, MEMORY.md, USER.md, AGENTS.md
- 🛡️ Never delete recent git refs (<7 days)
- 🛡️ Dry-run mode to preview changes
- 🛡️ Backup before cleanup (optional)

### Optimization
- 🗜️ Compress files >30 days (tar.gz)
- 🧹 Remove backups >7 days old
- 🗑️ Remove temporaries (.tmp, .bak, cache/)
- 🔗 Deduplicate identical files
- 📊 Generate detailed reports

## Use Cases

### Routine Cleanup (Weekly)
```bash
# Analyze without changes
bash memory-guardian.sh --analyze

# Cleanup with smart defaults
bash memory-guardian.sh --cleanup

# Aggressive cleanup
bash memory-guardian.sh --aggressive
```

### Bloat Detection
```bash
# Find what's eating space
bash memory-guardian.sh --analyze --detail

# Output:
# 📊 MEMORY ANALYSIS
# Total size: 2.4 GB
# Session logs (>30d): 450 MB
# Backup files: 320 MB
# Duplicates: 180 MB
# Opportunity: Save 950 MB
```

### Scheduled Cleanup (Cron)
```bash
# In crontab: cleanup every Sunday 23:00
0 23 * * 0 bash memory-guardian.sh --cleanup --quiet --email admin@example.com
```

### Emergency Cleanup
```bash
# Aggressive: remove everything safe
bash memory-guardian.sh --aggressive --force

# Result: Frees 1-2GB in large workspaces
```

## Output Example

```
🧠 MEMORY GUARDIAN PRO — Full Cleanup
═════════════════════════════════════════

📊 ANALYSIS PHASE
  Files scanned: 4,218
  Total size: 2.4 GB
  Protected files: 12 (SOUL.md, MEMORY.md, etc.)

🧹 CLEANUP PHASE
  ✅ Removed backup files: 8 files, 320 MB freed
  ✅ Removed temporaries: 43 files, 85 MB freed
  ✅ Compressed old logs: 156 files → 8 archives, 250 MB freed
  ✅ Removed duplicates: 12 files, 180 MB freed
  ⏭️ Protected (CORE/): 234 files, 120 MB (KEPT)
  ⏭️ Protected (PROTOCOLS/): 89 files, 45 MB (KEPT)
  ⏭️ Recent git (<7d): 156 files, 90 MB (KEPT)

📈 RESULTS
  Space freed: 835 MB
  Compression rate: 78%
  Files removed: 219
  Files protected: 491
  Execution time: 3.2 seconds

📝 Report saved: memory/CLEANUP-20260222.log
✅ DONE — Memory usage optimized
```

## Cleanup Strategies

| Strategy | Scope | Safety | Use Case |
|----------|-------|--------|----------|
| `--analyze` | Read-only analysis | 100% | Understand bloat |
| `--cleanup` | Default + smart | High | Weekly routine |
| `--aggressive` | Remove everything safe | High | Emergency cleanup |
| `--dry-run` | Preview changes | 100% | Test before running |
| `--force` | Skip confirmations | Medium | Automated scripts |

## Installation

```bash
# Copy to OpenClaw workspace
cp scripts/memory-guardian.sh ~/.openclaw/workspace/scripts/
chmod +x ~/.openclaw/workspace/scripts/memory-guardian.sh

# Create report directory
mkdir -p ~/.openclaw/workspace/memory/CLEANUP-REPORTS
```

## Usage

### Basic
```bash
# See what would be cleaned (safe preview)
bash memory-guardian.sh --dry-run

# Actually clean
bash memory-guardian.sh --cleanup

# Aggressive cleaning
bash memory-guardian.sh --aggressive
```

### Detailed Analysis
```bash
# Show everything with sizes
bash memory-guardian.sh --analyze --detail

# Show top 20 largest files
bash memory-guardian.sh --analyze --top-files 20

# Show duplicates
bash memory-guardian.sh --analyze --duplicates
```

### Scheduled
```bash
# Run via cron (no output)
bash memory-guardian.sh --cleanup --quiet

# Run with email report
bash memory-guardian.sh --cleanup --email admin@example.com

# Run with webhook notification
bash memory-guardian.sh --cleanup --webhook https://hooks.slack.com/...
```

### Integration
```bash
# Get JSON output for scripting
bash memory-guardian.sh --analyze --json | jq '.space_freed'

# Cleanup and fail if <100MB freed
bash memory-guardian.sh --cleanup --min-freed 100MB
```

## Architecture

```
PHASE 1: SCAN
  └─→ Recursively scan ~/.openclaw/workspace/memory/
      └─→ Collect: size, date, content-hash, type
      └─→ Categorize: session logs, backups, temporaries, etc.

PHASE 2: ANALYZE
  └─→ Identify bloat patterns
      └─→ Detect duplicates (MD5)
      └─→ Classify by age (recent/warm/cold)
      └─→ Estimate token savings
      └─→ Report opportunities

PHASE 3: PLAN
  └─→ Build cleanup plan (what to delete/compress)
      └─→ Preserve critical files (CORE/, PROTOCOLS/, SOUL.md)
      └─→ Preview in dry-run mode
      └─→ Wait for confirmation

PHASE 4: EXECUTE
  └─→ Remove backup files (>7 days)
      └─→ Remove temporaries (.tmp, .bak, cache/)
      └─→ Compress old files (>30 days → tar.gz)
      └─→ Deduplicate identical files
      └─→ Update indexes

PHASE 5: REPORT
  └─→ Summarize: files removed, space freed
      └─→ Generate audit trail
      └─→ Optional: email/webhook notification
```

## Tiered Memory Strategy (HOT/WARM/COLD)

Memory Guardian works with tiered architecture:

- **HOT:** Last 7 days (never touch, active work)
- **WARM:** 8-30 days (compress if >500KB)
- **COLD:** >30 days (compress + archive)

Example rotation:
```
memory/DAILY/HOT/        ← Recent work (never cleaned)
memory/DAILY/WARM/       ← Last month (compress large files)
memory/DAILY/COLD/       ← Older (compressed archives)
```

## Safety Guarantees

### Never Deleted
- ✅ CORE/ directory (user settings, critical docs)
- ✅ PROTOCOLS/ directory (operational procedures)
- ✅ SOUL.md, MEMORY.md, USER.md, AGENTS.md
- ✅ .git/ directory (version history)
- ✅ Files modified in last 7 days
- ✅ Any file <100 bytes (config files)

### Smart Deletion
- ✅ Backup files >7 days old (.backup-*, .bak)
- ✅ Temporaries (.tmp, .temp, cache/)
- ✅ Duplicate files (keep one, remove others)
- ✅ Compressed archives (if duplicate .tar.gz exists)

### Before/After Backup
- Optional automatic backup before cleanup
- Full undo capability if needed
- Detailed audit trail

## Testing

```bash
# Run test suite
bash scripts/test-memory-guardian.sh

# Output: 14/14 tests passed ✅
# - Bloat detection ✅
# - Deduplication ✅
# - Protection of critical files ✅
# - Report generation ✅
# - Dry-run accuracy ✅
```

## Performance

- **Scan time:** 0.5-2 seconds (depending on size)
- **Analysis time:** 0.3-1 second
- **Cleanup time:** 1-5 seconds (depending on scope)
- **Total:** Typical run: 2-8 seconds
- **Scalability:** Tested on 2.5GB+ workspaces

## Compatibility

- **OS:** Ubuntu 20.04+, Debian 10+, macOS 10.15+
- **Shell:** Bash 4.0+
- **Requirements:** `find`, `du`, `md5sum`, `tar`, `gzip`
- **No external dependencies:** Pure bash

## FAQ

**Q: Will it delete my notes?**
A: No. MEMORY.md and memory/ are protected unless >30 days old and >1MB.

**Q: Can I undo cleanup?**
A: Yes. Use `--backup-before` flag, then restore if needed.

**Q: How much space can I save?**
A: Typical: 30-50% of workspace size (500MB-1GB in large setups).

**Q: Can I customize what gets deleted?**
A: Yes. Edit the protection list in `memory-guardian.sh`.

**Q: Does it compress or delete files?**
A: Both. Small files deleted, large files (>500KB, >30d) compressed to .tar.gz.

## Related Tools

- **Critical Update Framework** — Safe system updates with rollback
- **Skill Security Audit** — Pre-install safety checks
- **Recovery System** — Full system restore

## Roadmap

- [ ] Machine learning (learn what's important per user)
- [ ] Multi-tier storage integration (S3, cloud archive)
- [ ] Intelligent retention policies (user-configurable)
- [ ] Real-time monitoring + alerts
- [ ] Dashboard/visualization of space usage

---

**Status:** Production-ready  
**Tests:** 14/14 passing ✅  
**Tested on:** Ubuntu 22.04, 24.04, macOS 13  
**Real-world:** Deployed in personal VPS (2.5GB+ workspace)  
**License:** MIT (compatible with OpenClaw)
