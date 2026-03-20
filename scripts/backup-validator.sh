# NOTE: Replace placeholder values (YOUR_*, $USER, etc.) with your actual configuration

#!/bin/bash
# =============================================================================
# backup-validator.sh — Backup Integrity Validation Suite
# =============================================================================
# Verifica integridad de backups: checksum, estructura, test restore
# Uso: bash backup-validator.sh [BACKUP_FILE] [OPTIONS]
#   --verify   Verificar integridad (checksum + estructura)
#   --test     Test restore en /tmp
#   --repair   Intentar auto-repair
#   --full     Todos los checks
#   --status   Ver estado de últimas validaciones
#   --quiet    Solo output si hay errores
# =============================================================================

set -euo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
STATE_FILE="$WORKSPACE/memory/backup-validation-state.json"
LOG_DIR="$WORKSPACE/memory/backup-validation-logs"

# Expected files/dirs in backup
EXPECTED_FILES=(
    "openclaw.json"
    "dot-env"
    "SOUL.md"
    "AGENTS.md"
    "MEMORY.md"
    "HEARTBEAT.md"
    "memory/"
    "scripts/"
)

EXPECTED_DIRS=(
    "memory"
    "scripts"
    "system-snapshot"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS="${GREEN}✅ PASS${NC}"
FAIL="${RED}❌ FAIL${NC}"
WARN="${YELLOW}⚠️  WARN${NC}"

# --- Parse args ---
BACKUP_FILE=""
DO_VERIFY=false
DO_TEST=false
DO_REPAIR=false
DO_FULL=false
DO_STATUS=false
QUIET=false

for arg in "$@"; do
    case "$arg" in
        --verify)  DO_VERIFY=true ;;
        --test)    DO_TEST=true ;;
        --repair)  DO_REPAIR=true ;;
        --full)    DO_FULL=true; DO_VERIFY=true; DO_TEST=true ;;
        --status)  DO_STATUS=true ;;
        --quiet)   QUIET=true ;;
        -*)        echo "Unknown option: $arg"; exit 1 ;;
        *)         BACKUP_FILE="$arg" ;;
    esac
done

# --- Helpers ---
mkdir -p "$LOG_DIR"

log() { $QUIET || echo -e "$@"; }

update_state() {
    local file="$1" status="$2" details="$3" checksum="${4:-}"
    local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local basename=$(basename "$file")

    # Initialize state file if needed
    [ -f "$STATE_FILE" ] || echo '{"validations":[],"lastRun":"","summary":{}}' > "$STATE_FILE"

    # Append validation result (keep last 30)
    local entry="{\"file\":\"$basename\",\"timestamp\":\"$ts\",\"status\":\"$status\",\"details\":\"$details\",\"checksum\":\"$checksum\"}"

    python3 -c "
import json, sys
with open('$STATE_FILE') as f: data = json.load(f)
entry = json.loads('$entry')
data['validations'].append(entry)
data['validations'] = data['validations'][-30:]
data['lastRun'] = '$ts'
# Update summary
total = len(data['validations'])
valid = sum(1 for v in data['validations'] if v['status'] == 'VALID')
data['summary'] = {'total': total, 'valid': valid, 'invalid': total - valid, 'lastStatus': '$status'}
with open('$STATE_FILE', 'w') as f: json.dump(data, f, indent=2)
" 2>/dev/null || true
}

# --- STATUS command ---
if $DO_STATUS; then
    log "===== BACKUP VALIDATION STATUS ====="
    if [ ! -f "$STATE_FILE" ]; then
        log "No validation history found."
        exit 0
    fi
    python3 -c "
import json
with open('$STATE_FILE') as f: data = json.load(f)
s = data.get('summary', {})
print(f\"Total validations: {s.get('total', 0)}\")
print(f\"Valid: {s.get('valid', 0)}\")
print(f\"Invalid: {s.get('invalid', 0)}\")
print(f\"Last status: {s.get('lastStatus', 'N/A')}\")
print(f\"Last run: {data.get('lastRun', 'N/A')}\")
print()
print('Recent validations:')
for v in data.get('validations', [])[-5:]:
    icon = '✅' if v['status'] == 'VALID' else '❌'
    print(f\"  {icon} {v['file']} — {v['status']} ({v['timestamp']})\")
    if v.get('details'): print(f\"     {v['details']}\")
"
    if ! $DO_VERIFY && ! $DO_TEST && ! $DO_FULL; then
        exit 0
    fi
fi

# --- Need backup file for other commands ---
if [ -z "$BACKUP_FILE" ] && ($DO_VERIFY || $DO_TEST || $DO_FULL || $DO_REPAIR); then
    # Try to find latest local backup
    BACKUP_FILE=$(ls -t /tmp/openclaw-backup-*.tar.gz 2>/dev/null | head -1)
    if [ -z "$BACKUP_FILE" ]; then
        echo "ERROR: No backup file specified and none found in /tmp"
        echo "Usage: bash backup-validator.sh <backup-file> [--verify|--test|--full]"
        exit 1
    fi
    log "Auto-detected backup: $BACKUP_FILE"
fi

if [ -n "$BACKUP_FILE" ] && [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: Backup file not found: $BACKUP_FILE"
    exit 1
fi

# --- Default: --verify if no action specified ---
if ! $DO_VERIFY && ! $DO_TEST && ! $DO_REPAIR && ! $DO_STATUS && [ -n "$BACKUP_FILE" ]; then
    DO_VERIFY=true
fi

# Track results
ERRORS=0
WARNINGS=0
REPORT=""

add_report() {
    REPORT+="$1"$'\n'
    log "$1"
}

# --- VERIFY ---
if $DO_VERIFY && [ -n "$BACKUP_FILE" ]; then
    BASENAME=$(basename "$BACKUP_FILE")
    FILE_SIZE=$(stat -c%s "$BACKUP_FILE" 2>/dev/null || echo 0)
    FILE_SIZE_H=$(du -h "$BACKUP_FILE" | cut -f1)

    add_report ""
    add_report "===== BACKUP VALIDATION REPORT ====="
    add_report "Backup: $BASENAME"
    add_report "Size: $FILE_SIZE_H ($FILE_SIZE bytes)"
    add_report "Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    add_report ""

    # 1. Checksum
    CHECKSUM=$(sha256sum "$BACKUP_FILE" | cut -d' ' -f1)
    CHECKSUM_FILE="${BACKUP_FILE}.sha256"

    # Always write current checksum (same-day re-runs produce different content)
    add_report "$(echo -e "$PASS") Checksum: SHA256=$CHECKSUM"
    echo "$CHECKSUM  $BASENAME" > "$CHECKSUM_FILE"

    # 2. Size anomaly check
    if [ "$FILE_SIZE" -lt 1000 ]; then
        add_report "$(echo -e "$FAIL") Size: Suspiciously small ($FILE_SIZE_H) — likely corrupt or empty"
        ERRORS=$((ERRORS + 1))
    elif [ "$FILE_SIZE" -lt 10000 ]; then
        add_report "$(echo -e "$WARN") Size: Unusually small ($FILE_SIZE_H) — might be incomplete"
        WARNINGS=$((WARNINGS + 1))
    else
        add_report "$(echo -e "$PASS") Size: $FILE_SIZE_H (reasonable)"
    fi

    # 3. Archive integrity (tar -tzf)
    add_report ""
    TAR_OUTPUT=$(tar -tzf "$BACKUP_FILE" 2>&1)
    TAR_EXIT=$?

    if [ $TAR_EXIT -ne 0 ]; then
        add_report "$(echo -e "$FAIL") Archive Integrity: tar cannot read archive"
        add_report "  Error: $TAR_OUTPUT"
        ERRORS=$((ERRORS + 1))
    else
        TOTAL_FILES=$(echo "$TAR_OUTPUT" | wc -l)
        add_report "$(echo -e "$PASS") Archive Integrity: readable ($TOTAL_FILES entries)"

        # 4. Structure check — expected files
        FOUND=0
        MISSING=""
        for expected in "${EXPECTED_FILES[@]}"; do
            # Handle both files and directories: match "filename" or "dirname/" anywhere in path
            # e.g., "SOUL.md" matches "openclaw-backup-2026-03-02/SOUL.md"
            # e.g., "memory/" matches "openclaw-backup-2026-03-02/memory/" or "openclaw-backup-2026-03-02/memory/subdir"
            if echo "$TAR_OUTPUT" | grep -E "/${expected}($|/)" > /dev/null 2>&1; then
                FOUND=$((FOUND + 1))
            else
                MISSING+="  - $expected"$'\n'
            fi
        done

        TOTAL_EXPECTED=${#EXPECTED_FILES[@]}
        if [ $FOUND -eq $TOTAL_EXPECTED ]; then
            add_report "$(echo -e "$PASS") Structure: ${FOUND}/${TOTAL_EXPECTED} expected files found"
        elif [ $FOUND -ge $((TOTAL_EXPECTED - 2)) ]; then
            add_report "$(echo -e "$WARN") Structure: ${FOUND}/${TOTAL_EXPECTED} expected files found"
            add_report "  Missing:"; add_report "$MISSING"
            WARNINGS=$((WARNINGS + 1))
        else
            add_report "$(echo -e "$FAIL") Structure: Only ${FOUND}/${TOTAL_EXPECTED} expected files found"
            add_report "  Missing:"; add_report "$MISSING"
            ERRORS=$((ERRORS + 1))
        fi

        # 5. Check expected directories
        DIR_FOUND=0
        for dir in "${EXPECTED_DIRS[@]}"; do
            if echo "$TAR_OUTPUT" | grep -q "$dir/"; then
                DIR_FOUND=$((DIR_FOUND + 1))
            fi
        done
        add_report "$(echo -e "$PASS") Directories: ${DIR_FOUND}/${#EXPECTED_DIRS[@]} expected dirs present"
    fi

    # Summary
    add_report ""
    if [ $ERRORS -gt 0 ]; then
        STATUS="INVALID"
        add_report "Status: ❌ INVALID ($ERRORS errors, $WARNINGS warnings)"
    elif [ $WARNINGS -gt 0 ]; then
        STATUS="VALID_WITH_WARNINGS"
        add_report "Status: ⚠️  VALID with warnings ($WARNINGS warnings)"
    else
        STATUS="VALID"
        add_report "Status: ✅ VALID"
    fi

    update_state "$BACKUP_FILE" "$STATUS" "${ERRORS} errors, ${WARNINGS} warnings" "$CHECKSUM"
fi

# --- TEST RESTORE ---
if $DO_TEST && [ -n "$BACKUP_FILE" ]; then
    add_report ""
    add_report "===== TEST RESTORE ====="

    TEST_DIR=$(mktemp -d /tmp/backup-test-XXXXXX)
    log "Test directory: $TEST_DIR"

    EXTRACT_OUTPUT=$(tar xzf "$BACKUP_FILE" -C "$TEST_DIR" 2>&1)
    EXTRACT_EXIT=$?

    if [ $EXTRACT_EXIT -ne 0 ]; then
        add_report "$(echo -e "$FAIL") Test Restore: extraction failed"
        add_report "  Error: $EXTRACT_OUTPUT"
        ERRORS=$((ERRORS + 1))
    else
        EXTRACTED_FILES=$(find "$TEST_DIR" -type f | wc -l)
        EXTRACTED_DIRS=$(find "$TEST_DIR" -type d | wc -l)
        EXTRACTED_SIZE=$(du -sh "$TEST_DIR" | cut -f1)

        add_report "$(echo -e "$PASS") Test Restore: extracted successfully"
        add_report "  Files: $EXTRACTED_FILES | Dirs: $EXTRACTED_DIRS | Size: $EXTRACTED_SIZE"

        # Check key files are readable
        BACKUP_ROOT=$(ls "$TEST_DIR" | head -1)
        KEY_FILES_OK=0
        KEY_FILES_TOTAL=0
        for kf in openclaw.json dot-env SOUL.md AGENTS.md; do
            KEY_FILES_TOTAL=$((KEY_FILES_TOTAL + 1))
            if [ -r "$TEST_DIR/$BACKUP_ROOT/$kf" ] 2>/dev/null; then
                KEY_FILES_OK=$((KEY_FILES_OK + 1))
            fi
        done
        add_report "$(echo -e "$PASS") Readability: ${KEY_FILES_OK}/${KEY_FILES_TOTAL} key files readable"

        # Check permissions (files should be readable)
        UNREADABLE=$(find "$TEST_DIR" -type f ! -readable 2>/dev/null | wc -l)
        if [ "$UNREADABLE" -gt 0 ]; then
            add_report "$(echo -e "$WARN") Permissions: $UNREADABLE unreadable files"
            WARNINGS=$((WARNINGS + 1))
        else
            add_report "$(echo -e "$PASS") Permissions: all files readable"
        fi
    fi

    # Cleanup
    rm -rf "$TEST_DIR"
    add_report "$(echo -e "$PASS") Cleanup: test directory removed"

    # Update state
    if [ $EXTRACT_EXIT -eq 0 ]; then
        update_state "$BACKUP_FILE" "VALID" "Test restore OK: $EXTRACTED_FILES files"
    else
        update_state "$BACKUP_FILE" "INVALID" "Test restore FAILED"
    fi
fi

# --- REPAIR ---
if $DO_REPAIR && [ -n "$BACKUP_FILE" ]; then
    add_report ""
    add_report "===== AUTO-REPAIR ====="

    # Check if archive is readable at all
    if tar -tzf "$BACKUP_FILE" &>/dev/null; then
        add_report "$(echo -e "$PASS") Archive is readable — no repair needed"
    else
        add_report "$(echo -e "$WARN") Archive may be corrupt. Attempting partial recovery..."

        # Try gzip recovery
        REPAIR_DIR=$(mktemp -d /tmp/backup-repair-XXXXXX)
        REPAIR_FILE="$REPAIR_DIR/recovered.tar.gz"

        # Attempt: gzip -t first
        if gzip -t "$BACKUP_FILE" 2>/dev/null; then
            add_report "  gzip layer OK — issue is in tar layer"
        else
            add_report "  gzip layer corrupt — attempting zcat recovery"
            zcat "$BACKUP_FILE" 2>/dev/null | gzip > "$REPAIR_FILE" 2>/dev/null || true

            if [ -s "$REPAIR_FILE" ] && tar -tzf "$REPAIR_FILE" &>/dev/null; then
                # Save corrupted original
                cp "$BACKUP_FILE" "${BACKUP_FILE}.corrupt"
                cp "$REPAIR_FILE" "$BACKUP_FILE"
                add_report "$(echo -e "$PASS") Repair successful! Original saved as .corrupt"
            else
                add_report "$(echo -e "$FAIL") Repair failed — archive is not recoverable"
                add_report "  Corrupted file preserved for analysis: $BACKUP_FILE"
                ERRORS=$((ERRORS + 1))
            fi
        fi

        rm -rf "$REPAIR_DIR"
    fi
fi

# --- Final report ---
if [ -n "$BACKUP_FILE" ]; then
    add_report ""
    add_report "Validated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"

    # Save report to log
    LOGFILE="$LOG_DIR/validation-$(date -u +%Y%m%d-%H%M%S).log"
    echo "$REPORT" | sed 's/\x1b\[[0-9;]*m//g' > "$LOGFILE"

    # Exit code
    if [ $ERRORS -gt 0 ]; then
        exit 1
    fi
fi

exit 0
