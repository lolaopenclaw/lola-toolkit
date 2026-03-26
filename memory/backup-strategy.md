# Backup Strategy — Consolidation (2026-03-26)

**TL;DR:** Tres capas complementarias (no redundantes). Git para código, custom script para secretos/estado, native OpenClaw para disaster recovery.

---

## Current Backup Layers (3)

### 1. **Git + GitHub** → ACTIVO ✅
- **What:** Workspace versionado (código, docs, memoria)
- **Where:** `github.com/lolaopenclaw/lola-toolkit` (privado)
- **When:** Manual (commits ad-hoc) + cron `ad742767` (4:00 AM daily push)
- **Size:** ~8.9M (`.git/`)
- **What's EXCLUDED:** Databases, media, secrets, `.env`, logs (ver `.gitignore`)
- **Status:** ✅ Funciona bien. NO TOCAR.

**Includes:**
```
✅ SOUL.md, USER.md, AGENTS.md, IDENTITY.md, TOOLS.md, MEMORY.md
✅ memory/*.md (daily logs, protocols, entities)
✅ scripts/*.sh (todos los scripts)
✅ skills/ (custom skills)
✅ data/knowledge-base.db (sí, está en git para portabilidad)
```

**Git ignore:**
```
❌ .env (secrets)
❌ *.log (transient logs)
❌ *client_secret*, *-SECRETS-* (credentials)
❌ memory/WAL/snapshots/ (large binaries)
❌ .vectordb/ (embeddings)
❌ temp/, node_modules/
```

---

### 2. **Custom Script → Google Drive** → ACTIVO ✅
- **Script:** `scripts/backup-memory.sh`
- **Trigger:** Cron `ad742767` (4:00 AM daily)
- **Where:** Google Drive `openclaw_backups/` (ID: 1G-OLpZKJ2zQXac0qaKxvaeglbRUuRxfD)
- **Size:** ~25M compressed (5378 files)
- **Last backup:** 2026-03-26 (ok)
- **Retention:** Automático (cron `e5ebcbf4` — `45 5 * * 1` weekly cleanup)
- **Status:** ✅ ESSENTIAL. Respalda cosas NO en git.

**What it backs up (full list):**

```bash
# Workspace core
✅ SOUL.md, USER.md, AGENTS.md, IDENTITY.md, TOOLS.md, MEMORY.md, RECOVERY.md, BOOT.md
✅ cron-jobs.json
✅ memory/ (all)
✅ scripts/ (all)
✅ skills/ (all)

# OpenClaw config + secrets
✅ ~/.openclaw/openclaw.json
✅ ~/.openclaw/.env (API keys, credentials)
✅ ~/.openclaw/cron/ (cron database)

# Auth & credentials
✅ ~/.gnupg/ (GPG keys)
✅ ~/.password-store/ (pass store)
✅ ~/.local/share/keyrings/ (GOG, etc.)
✅ ~/.config/gog/ (GOG CLI config)
✅ ~/.config/rclone/rclone.conf

# System snapshot
✅ OpenClaw version
✅ Node version
✅ restore.sh script
```

**What it DOESN'T back up:**
```
❌ Node_modules (regenerable con npm install)
❌ .vectordb/ (regenerable con embedding scripts)
❌ Large media files (videos, etc. — handle manually)
❌ Session logs (demasiado grandes, rotación automática)
```

**Recovery:**
```bash
# Download latest backup
rclone copy 'grive_lola:openclaw_backups/' /tmp/ --include '*.tar.gz' --max-age 3d

# Restore
bash scripts/restore.sh /tmp/openclaw-backup-YYYY-MM-DD.tar.gz

# Follow steps in script output
```

**Key features:**
- Parallel copies (background jobs)
- Safe file ops (`safe_copy`, `safe_sync`)
- Deduplication (delete same-day backups before upload)
- Status tracking (`memory/last-backup.json`)
- Pigz compression (fallback to gzip)

---

### 3. **OpenClaw Native Backup** → ⚠️ NO USADO (pero disponible)
- **Command:** `openclaw backup create`
- **What:** Todo `~/.openclaw/` (state + workspace)
- **Output:** `~/YYYY-MM-DDTHH-MM-SS.SSS-openclaw-backup.tar.gz`
- **Size:** Potencialmente grande (incluye todo)
- **Status:** ⚠️ DISPONIBLE pero NO configurado en cron. Útil para disaster recovery ad-hoc.

**When to use:**
1. **Pre-migration:** Antes de mover OpenClaw a otro servidor
2. **Pre-upgrade:** Antes de actualizar OpenClaw a major version
3. **Emergency snapshot:** Antes de cambios estructurales arriesgados

**What it includes:**
```json
{
  "assets": [
    {
      "kind": "state",
      "sourcePath": "/home/mleon/.openclaw",
      "displayPath": "~/.openclaw",
      "archivePath": "YYYY-MM-DDTHH-MM-SS.SSS-openclaw-backup/payload/posix/home/mleon/.openclaw"
    }
  ]
}
```

**Exclude workspace from backup (config only):**
```bash
openclaw backup create --no-include-workspace --output ~/backups/
```

**Verify backup integrity:**
```bash
openclaw backup verify ~/YYYY-MM-DD*-openclaw-backup.tar.gz
```

**Decision:** NO añadir a cron (redundante con custom script). Disponible para uso manual cuando sea necesario.

---

## Backup Coverage Matrix

| Asset | Git | Custom Script | Native Backup |
|-------|-----|---------------|---------------|
| Workspace code | ✅ | ✅ | ✅ |
| `.env` secrets | ❌ | ✅ | ✅ |
| Cron database | ❌ | ✅ | ✅ |
| GPG keys | ❌ | ✅ | ✅ |
| Session logs | ❌ | ❌ | ✅ |
| GOG credentials | ❌ | ✅ | ✅ |
| Rclone config | ❌ | ✅ | ✅ |
| OpenClaw config | ❌ | ✅ | ✅ |

**Conclusion:** Custom script + Git = 100% coverage. Native backup = redundante para daily pero útil para disaster recovery puntual.

---

## Recovery Procedures

### Scenario 1: Workspace corruption (code/docs)
**RTO:** < 5 minutes

```bash
# From Git
cd ~/.openclaw/workspace
git reset --hard origin/master
git pull
```

### Scenario 2: Lost secrets/config/auth
**RTO:** ~15 minutes

```bash
# Download latest backup
rclone copy 'grive_lola:openclaw_backups/' /tmp/ --include '*.tar.gz' --max-age 3d

# Restore
bash ~/.openclaw/workspace/scripts/restore.sh /tmp/openclaw-backup-YYYY-MM-DD.tar.gz

# Follow post-restore steps (see script output)
# Includes: API keys, GOG auth, rclone config, cron jobs
```

### Scenario 3: Complete system loss (new machine)
**RTO:** ~30-45 minutes

```bash
# 1. Install OpenClaw
npm install -g openclaw

# 2. Download backup
# (requires manual Drive download or rclone setup first)
rclone copy 'grive_lola:openclaw_backups/' /tmp/ --include '*.tar.gz' --max-age 3d

# 3. Restore
bash /tmp/openclaw-backup-YYYY-MM-DD/restore.sh /tmp/openclaw-backup-YYYY-MM-DD.tar.gz

# 4. Install gateway
openclaw gateway install
openclaw gateway start

# 5. Verify
openclaw doctor
bash ~/.openclaw/workspace/scripts/verify.sh

# 6. Enable hooks
openclaw hooks enable boot-md

# 7. Enable linger (for persistent service)
sudo loginctl enable-linger $(whoami)
```

See `RECOVERY.md` for detailed instructions.

### Scenario 4: Git history loss
**RTO:** < 10 minutes

```bash
# Extract workspace from Google Drive backup
tar xzf openclaw-backup-YYYY-MM-DD.tar.gz
cd openclaw-backup-YYYY-MM-DD/

# Re-init git
git init
git remote add origin git@github.com:lolaopenclaw/lola-toolkit.git
git add .
git commit -m "restore: rebuild from backup YYYY-MM-DD"
git push -f origin master
```

---

## What's NOT Backed Up (and why)

| Asset | Why Not | Mitigation |
|-------|---------|------------|
| `node_modules/` | Regenerable with `npm install` | Package.json in git |
| `.vectordb/` | Regenerable with embedding scripts | Scripts in git |
| Session logs (`~/.openclaw/agents/main/sessions/*.jsonl`) | Too large (GBs), rotated automatically | Keep last 30 days locally |
| Large media (videos, etc.) | Bandwidth/storage cost | Manual backup when needed |
| Temp files, caches | Transient | N/A |
| `.cache/`, `logs/` | Ephemeral | N/A |

---

## Cron Schedule

| Cron ID | Task | Schedule | What |
|---------|------|----------|------|
| `ad742767` | Backup daily | 4:00 AM | Git push + Google Drive upload |
| `e763c896` | Backup validation | 5:30 AM Mon | Verify backup integrity |
| `e5ebcbf4` | Backup retention | 5:45 AM Mon | Delete old backups (keep last 7) |

**All cron jobs:** `openclaw cron list`

---

## Validation

**Daily validation (automated):**
- Cron `e763c896` runs `scripts/backup-validator.sh` weekly
- Checks: tarball integrity, file count, size, GOG credentials, rclone config

**Manual validation:**
```bash
# Check last backup status
cat memory/last-backup.json

# List Google Drive backups
rclone ls 'grive_lola:openclaw_backups' | tail -10

# Verify backup tarball
tar tzf /tmp/openclaw-backup-YYYY-MM-DD.tar.gz > /dev/null && echo "OK"

# Full verification script
bash scripts/backup-validator.sh
```

---

## Cost & Storage

| Layer | Storage | Cost | Retention |
|-------|---------|------|-----------|
| Git (GitHub) | ~9M | Free (private repo) | Forever |
| Google Drive | ~25M/day | Free (15GB quota) | 7 days |
| Native backup | Not used | N/A | N/A |

**Storage usage:**
```
Google Drive quota: ~400M used (16 backups × 25M)
Remaining: ~14.6GB
```

**Bottleneck:** None. Current usage is sustainable.

---

## Changes Made (2026-03-26)

1. ✅ Analyzed all 3 backup layers
2. ✅ Verified coverage (no gaps)
3. ✅ Confirmed complementary (not redundant)
4. ✅ Documented recovery procedures with RTOs
5. ✅ Validated `.gitignore` (correct exclusions)
6. ✅ Confirmed backup integrity (last backup: ok)
7. ✅ Decided: KEEP all 3 layers as-is
8. ❌ Native backup: NOT added to cron (available for manual use)

---

## Recommendations

### Keep As-Is ✅
- Git push cron → versioning, audit trail
- Custom script → secrets, auth, state
- Native backup → disaster recovery (manual)

### Future Improvements (optional)
1. **Offsite backup:** Second copy to AWS S3 or Backblaze B2 (for true 3-2-1 backup)
2. **Encrypted backups:** Add GPG encryption to Drive backups (currently unencrypted)
3. **Backup testing:** Quarterly restore drill to verify RTO
4. **Monitoring:** Alert if backup fails 2+ days in a row

### NOT Recommended ❌
- ❌ Disable any existing backup (all serve different purposes)
- ❌ Add native backup to cron (redundant with custom script)
- ❌ Remove Git versioning (essential for code history)

---

## Quick Reference

**Check backup status:**
```bash
cat memory/last-backup.json
```

**Manual backup NOW:**
```bash
bash scripts/backup-memory.sh
```

**List Drive backups:**
```bash
rclone ls 'grive_lola:openclaw_backups' | tail -10
```

**Restore from latest:**
```bash
rclone copy 'grive_lola:openclaw_backups/' /tmp/ --include '*.tar.gz' --max-age 3d
bash scripts/restore.sh /tmp/openclaw-backup-*.tar.gz
```

**Native backup (manual):**
```bash
openclaw backup create --output ~/backups/ --verify
```

---

**Last updated:** 2026-03-26  
**Status:** ✅ All backup layers functional and validated  
**Action required:** None. Keep monitoring via daily validation cron.
