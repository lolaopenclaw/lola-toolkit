#!/bin/bash
# =============================================================================
# eval.sh — Evaluate backup-memory.sh performance
# =============================================================================
# Returns: execution time in seconds (float)
# Also validates: backup completeness and integrity
# =============================================================================

set -euo pipefail

SCRIPT="/home/mleon/.openclaw/workspace/scripts/backup-memory.sh"
BACKUP_DATE=$(date -u +%Y-%m-%d)
EXPECTED_FILE="/tmp/openclaw-backup-${BACKUP_DATE}.tar.gz"

# Clean up any previous test artifacts
rm -rf "/tmp/openclaw-backup-${BACKUP_DATE}" "$EXPECTED_FILE" 2>/dev/null || true

# Time the execution (redirect output to avoid noise)
START=$(date +%s.%N)
bash "$SCRIPT" > /tmp/autoimprove-backup-eval.log 2>&1 || true
END=$(date +%s.%N)

ELAPSED=$(echo "$END - $START" | bc)

# --- Validation: check backup was created and has required components ---
VALID=true
PENALTY=0

# Check the backup file exists (might have been cleaned up by script itself)
# The script cleans up after upload, so check the log
if ! grep -q "status: ok" /tmp/autoimprove-backup-eval.log 2>/dev/null; then
    VALID=false
    PENALTY=999
fi

# Check key components were copied
for check in "Copiando workspace" "Copiando config" "Copiando secrets" "Creando tarball"; do
    if ! grep -q "$check" /tmp/autoimprove-backup-eval.log 2>/dev/null; then
        PENALTY=$((PENALTY + 100))
    fi
done

# Check validation passed
if grep -q "validation: FAIL" /tmp/autoimprove-backup-eval.log 2>/dev/null; then
    PENALTY=$((PENALTY + 500))
fi

# Final score = time + penalties (lower is better)
SCORE=$(echo "$ELAPSED + $PENALTY" | bc)

echo "$SCORE"
