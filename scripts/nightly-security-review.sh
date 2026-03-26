#!/bin/bash
# =============================================================================
# Nightly Security Review for OpenClaw
# =============================================================================
# Comprehensive security audit aligned with Berman's 6-layer defense.
# Runs daily at 4 AM (after autoimprove & backup).
# Usage: bash scripts/nightly-security-review.sh [--alert-channel CHANNEL_ID]
# Exit 0 = clean, Exit 1 = issues found
# =============================================================================

set -euo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
CONFIG_DIR="$HOME/.openclaw"
BASELINE="$WORKSPACE/memory/security-checksums.json"
LOG_FILE="$WORKSPACE/memory/security-review.log"
REPORT_FILE="$WORKSPACE/memory/security-review-$(date +%Y%m%d).md"
SILENT=true
ALERT_CHANNEL=""
FINDINGS=0

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --alert-channel)
            ALERT_CHANNEL="$2"
            shift 2
            ;;
        --verbose)
            SILENT=false
            shift
            ;;
        *)
            echo "Usage: $0 [--alert-channel CHANNEL_ID] [--verbose]"
            exit 1
            ;;
    esac
done

# Logging helper
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_finding() {
    local severity="$1"
    local message="$2"
    FINDINGS=$((FINDINGS + 1))
    echo "[$severity] $message" | tee -a "$REPORT_FILE"
    log "FINDING [$severity]: $message"
}

# Header
{
    echo "# Nightly Security Review"
    echo "**Date:** $(date '+%Y-%m-%d %H:%M:%S')"
    echo "**Baseline:** $BASELINE"
    echo ""
    echo "---"
    echo ""
} > "$REPORT_FILE"

log "=========================================="
log "Nightly Security Review — START"
log "=========================================="

# =============================================================================
# Check 1: File Permissions (Sensitive Files)
# =============================================================================
log "[1/7] Checking file permissions..."
echo "## 1. File Permissions" >> "$REPORT_FILE"

SENSITIVE_FILES=(
    "$CONFIG_DIR/.env"
    "$CONFIG_DIR/openclaw.json"
    "$CONFIG_DIR/credentials/telegram-allowFrom.json"
    "$CONFIG_DIR/credentials/telegram-pairing.json"
    "$CONFIG_DIR/exec-approvals.json"
    "$CONFIG_DIR/identity/device-auth.json"
)

for file in "${SENSITIVE_FILES[@]}"; do
    if [ -f "$file" ]; then
        perms=$(stat -c "%a" "$file")
        if [ "$perms" != "600" ] && [ "$perms" != "640" ]; then
            log_finding "CRITICAL" "Incorrect permissions on $file: $perms (should be 600)"
        else
            echo "- ✅ $file: $perms" >> "$REPORT_FILE"
        fi
    else
        log_finding "WARNING" "Sensitive file not found: $file"
    fi
done

echo "" >> "$REPORT_FILE"

# =============================================================================
# Check 2: Secrets in Version Control
# =============================================================================
log "[2/7] Checking for secrets in version control..."
echo "## 2. Secrets in Version Control" >> "$REPORT_FILE"

cd "$WORKSPACE"
if [ -d .git ]; then
    # Fast check: only scan tracked files in working tree (not history)
    # Full history scan is too slow for nightly cron
    SECRET_PATTERNS="sk-ant-|sk-proj-|ANTHROPIC_API_KEY|GOOGLE_API_KEY|Bearer [a-zA-Z0-9]|-----BEGIN.*PRIVATE KEY"
    
    # Known/accepted risk exceptions (secrets that cannot be rotated)
    # Format: one pattern per line, grep -vE compatible
    # - sk-ant-oat01: Anthropic OAuth token, cannot be rotated (accepted risk 2026-03-26)
    SECRETS_ALLOWLIST="sk-ant-oat01|ANTHROPIC_API_KEY=sk-ant"
    
    SECRETS_FOUND=0
    # Check only tracked files (fast)
    tracked_files=$(git ls-files 2>/dev/null)
    
    if [ -n "$tracked_files" ]; then
        # Count matches excluding allowlisted patterns
        matches=$(echo "$tracked_files" | xargs grep -iE "$SECRET_PATTERNS" 2>/dev/null | grep -vE "$SECRETS_ALLOWLIST" | wc -l)
        SECRETS_FOUND=$matches
        
        if [ "$SECRETS_FOUND" -gt 0 ]; then
            log_finding "CRITICAL" "Secrets detected in tracked files: $SECRETS_FOUND occurrences"
            # Log which files (but not the actual secrets), excluding allowlisted
            echo "$tracked_files" | xargs grep -iE "$SECRET_PATTERNS" 2>/dev/null | grep -vE "$SECRETS_ALLOWLIST" | cut -d: -f1 | sort -u | while read -r file; do
                log_finding "CRITICAL" "  → $file"
            done
        fi
    fi
    
    if [ "$SECRETS_FOUND" -eq 0 ]; then
        echo "- ✅ No secrets detected in tracked files" >> "$REPORT_FILE"
    else
        echo "- ❌ **$SECRETS_FOUND secrets found in tracked files** — review and rotate!" >> "$REPORT_FILE"
    fi
else
    echo "- ⚠️  Workspace is not a git repo (skipped)" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"

# =============================================================================
# Check 3: Security Module Integrity (Checksums)
# =============================================================================
log "[3/7] Verifying security module integrity..."
echo "## 3. Security Module Integrity" >> "$REPORT_FILE"

SECURITY_FILES=(
    "$WORKSPACE/scripts/security-scanner.py"
    "$WORKSPACE/config/security-config.json"
    "$WORKSPACE/scripts/pre-restart-validator.sh"
    "$CONFIG_DIR/openclaw.json"
)

# Generate current checksums
declare -A CURRENT_CHECKSUMS
for file in "${SECURITY_FILES[@]}"; do
    if [ -f "$file" ]; then
        checksum=$(sha256sum "$file" | awk '{print $1}')
        CURRENT_CHECKSUMS["$file"]="$checksum"
    fi
done

# Compare with baseline
if [ -f "$BASELINE" ]; then
    TAMPERED=0
    while IFS= read -r line; do
        file=$(echo "$line" | jq -r '.file')
        baseline_hash=$(echo "$line" | jq -r '.sha256')
        
        if [ -n "${CURRENT_CHECKSUMS[$file]:-}" ]; then
            current_hash="${CURRENT_CHECKSUMS[$file]}"
            if [ "$baseline_hash" != "$current_hash" ]; then
                log_finding "CRITICAL" "Security module tampered: $file (hash mismatch)"
                TAMPERED=$((TAMPERED + 1))
            fi
        else
            log_finding "WARNING" "Security module missing: $file"
        fi
    done < <(jq -c '.[]' "$BASELINE")
    
    if [ "$TAMPERED" -eq 0 ]; then
        echo "- ✅ All security modules verified" >> "$REPORT_FILE"
    else
        echo "- ❌ **$TAMPERED security modules tampered** — investigate immediately!" >> "$REPORT_FILE"
    fi
else
    # First run: create baseline
    echo "- ⚠️  No baseline found — creating initial checksums" >> "$REPORT_FILE"
    {
        echo "["
        first=true
        for file in "${!CURRENT_CHECKSUMS[@]}"; do
            [ "$first" = false ] && echo ","
            first=false
            jq -n --arg f "$file" --arg h "${CURRENT_CHECKSUMS[$file]}" \
                '{file: $f, sha256: $h, created: (now | strftime("%Y-%m-%d %H:%M:%S"))}'
        done
        echo "]"
    } > "$BASELINE"
    log "Baseline checksums created: $BASELINE"
fi

echo "" >> "$REPORT_FILE"

# =============================================================================
# Check 4: Suspicious Log Entries (Last 24h)
# =============================================================================
log "[4/7] Scanning logs for suspicious patterns..."
echo "## 4. Suspicious Log Entries" >> "$REPORT_FILE"

# Only check actual log files (not markdown), recent only
LOG_FILE_MAIN="$CONFIG_DIR/logs/gateway.log"

# High-priority patterns only (performance)
CRITICAL_PATTERN="jailbreak|bypass safety|sk-ant-api|unauthorized.*admin|permission denied.*root"

SUSPICIOUS_COUNT=0
if [ -f "$LOG_FILE_MAIN" ]; then
    # Only last 1000 lines of main log
    matches=$(tail -1000 "$LOG_FILE_MAIN" 2>/dev/null | grep -icE "$CRITICAL_PATTERN" 2>/dev/null || echo 0)
    SUSPICIOUS_COUNT=$matches
fi

if [ "$SUSPICIOUS_COUNT" -eq 0 ]; then
    echo "- ✅ No critical patterns detected in gateway log (last 1000 lines)" >> "$REPORT_FILE"
else
    log_finding "WARNING" "Critical patterns in gateway log: $SUSPICIOUS_COUNT occurrences"
    echo "- ⚠️  $SUSPICIOUS_COUNT critical patterns found — review gateway.log" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"

# =============================================================================
# Check 5: Exec Approvals Log (Suspicious Activity)
# =============================================================================
log "[5/7] Checking exec approvals..."
echo "## 5. Exec Approvals" >> "$REPORT_FILE"

APPROVALS_FILE="$CONFIG_DIR/exec-approvals.json"
if [ -f "$APPROVALS_FILE" ]; then
    # Check for recent approvals in the last 24h
    approval_count=$(jq -r '.approved | length' "$APPROVALS_FILE" 2>/dev/null || echo 0)
    
    # Look for suspicious commands
    suspicious_cmds=$(jq -r '.approved[]? | select(.command | test("rm -rf|dd if=|curl.*sh|wget.*sh|nc |/dev/tcp"))' \
        "$APPROVALS_FILE" 2>/dev/null | wc -l)
    
    if [ "$suspicious_cmds" -gt 0 ]; then
        log_finding "CRITICAL" "Suspicious commands in approvals log: $suspicious_cmds"
        echo "- ❌ **$suspicious_cmds suspicious commands approved** — review immediately!" >> "$REPORT_FILE"
    else
        echo "- ✅ $approval_count approvals, no suspicious commands" >> "$REPORT_FILE"
    fi
else
    echo "- ⚠️  No exec approvals file found (skipped)" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"

# =============================================================================
# Check 6: Security Scanner Self-Test
# =============================================================================
log "[6/7] Running security scanner self-test..."
echo "## 6. Security Scanner Self-Test" >> "$REPORT_FILE"

SCANNER="$WORKSPACE/scripts/security-scanner.py"
if [ -x "$SCANNER" ] || [ -f "$SCANNER" ]; then
    # Test scanner execution (just verify it runs without crashing)
    test_payload="Normal message for testing"
    
    scan_result=$(echo "$test_payload" | python3 "$SCANNER" inbound - --json 2>&1)
    scan_exit=$?
    
    # Check if scanner executed successfully (exit 0-2 are valid)
    if [ "$scan_exit" -le 2 ] && echo "$scan_result" | grep -q '"verdict"'; then
        layer1_checks=$(echo "$scan_result" | jq -r '.layers.layer1_sanitization | length' 2>/dev/null || echo 0)
        if [ "$layer1_checks" -gt 5 ]; then
            echo "- ✅ Security scanner functional (Layer 1: $layer1_checks checks, exit code: $scan_exit)" >> "$REPORT_FILE"
        else
            log_finding "WARNING" "Security scanner may be degraded (Layer 1 checks: $layer1_checks)"
            echo "- ⚠️  Scanner Layer 1 incomplete ($layer1_checks checks)" >> "$REPORT_FILE"
        fi
    else
        log_finding "CRITICAL" "Security scanner failed self-test (exit: $scan_exit)"
        echo "- ❌ **Scanner self-test failed (exit $scan_exit)** — module may be broken!" >> "$REPORT_FILE"
    fi
else
    log_finding "CRITICAL" "Security scanner not found: $SCANNER"
    echo "- ❌ **Security scanner missing** — Layer 2 defense compromised!" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"

# =============================================================================
# Check 7: Permissions Matrix Cross-Reference
# =============================================================================
log "[7/7] Cross-referencing permissions matrix..."
echo "## 7. Permissions Matrix" >> "$REPORT_FILE"

# Check that sensitive directories are still protected
PROTECTED_DIRS=(
    "$CONFIG_DIR/credentials"
    "$CONFIG_DIR/identity"
    "$CONFIG_DIR/cron"
)

for dir in "${PROTECTED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        perms=$(stat -c "%a" "$dir")
        if [ "$perms" != "700" ] && [ "$perms" != "750" ]; then
            log_finding "WARNING" "Protected directory has weak permissions: $dir ($perms)"
        else
            echo "- ✅ $dir: $perms" >> "$REPORT_FILE"
        fi
    fi
done

echo "" >> "$REPORT_FILE"

# =============================================================================
# Summary & Reporting
# =============================================================================
{
    echo "---"
    echo ""
    echo "## Summary"
    echo ""
    if [ "$FINDINGS" -eq 0 ]; then
        echo "✅ **All checks passed** — no security issues detected."
    else
        echo "⚠️  **$FINDINGS findings detected** — review report above."
    fi
    echo ""
    echo "**Report:** $REPORT_FILE"
    echo "**Log:** $LOG_FILE"
    echo ""
} >> "$REPORT_FILE"

log "=========================================="
log "Nightly Security Review — END"
log "Findings: $FINDINGS"
log "Report: $REPORT_FILE"
log "=========================================="

# Check quiet hours (00:00-07:00 Madrid)
HOUR=$(TZ=Europe/Madrid date +%H)
CRITICAL_FINDINGS=$(grep -c "\[CRITICAL\]" "$REPORT_FILE" 2>/dev/null || echo "0")

if [ "$HOUR" -ge 0 ] && [ "$HOUR" -lt 7 ] && [ "$CRITICAL_FINDINGS" -eq 0 ]; then
    # During quiet hours: only alert if CRITICAL findings
    echo "Quiet hours: non-critical findings logged, no notification" >> "$LOG_FILE"
    exit 0
fi

# Alert if findings and channel specified
if [ "$FINDINGS" -gt 0 ] && [ -n "$ALERT_CHANNEL" ]; then
    # Send alert via message tool (if available)
    if command -v openclaw &>/dev/null; then
        openclaw message send --channel telegram --target "-1003768820594" --topic 29 \
            --message "🚨 Nightly Security Review: $FINDINGS findings detected. Review: $REPORT_FILE" \
            2>/dev/null || log "Alert send failed (openclaw not available)"
    fi
fi

# Exit code
if [ "$FINDINGS" -eq 0 ]; then
    [ "$SILENT" = false ] && echo "✅ Security review passed"
    exit 0
else
    [ "$SILENT" = false ] && echo "⚠️  Security review found $FINDINGS issues"
    exit 1
fi
