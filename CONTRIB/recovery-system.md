# Proposal: Recovery System

## Problem

If an OpenClaw VPS dies or gets corrupted, rebuilding from scratch is manual and error-prone. There's no standard way to backup and restore an OpenClaw installation.

## Solution

Two scripts working together:

### 1. Backup (`backup-memory.sh`)
- Packages workspace, config, cron jobs, credentials, and rclone config
- Uploads encrypted tarball to cloud storage (Google Drive via rclone)
- Validates upload integrity
- Runs on schedule via cron

### 2. Restore (`restore.sh`)
- Takes a backup tarball and restores everything
- Idempotent — safe to run multiple times
- Restores: workspace, openclaw.json, .env, cron-db, credentials, rclone config
- Verifies restored state

### 3. Bootstrap (`bootstrap.sh`)
- Fresh server setup from zero
- Installs dependencies, creates user, sets up OpenClaw
- Downloads latest backup and runs restore

## Genericization Needed

- Heavy genericization required (most user-specific of all contributions)
- Cloud storage provider should be configurable (not just Google Drive)
- Backup contents should be configurable
- Bootstrap should support multiple distros
- All Spanish → English

## Why This Should Be in OpenClaw

1. **Disaster recovery** — Critical for any self-hosted setup
2. **Migration** — Move between providers easily
3. **Confidence** — Users more willing to experiment knowing they can recover
