#!/bin/bash
# =============================================================================
# Pre-Restart Validator (Harness) for OpenClaw Gateway
# =============================================================================
# Run this BEFORE any gateway restart to catch config issues.
# Usage: bash scripts/pre-restart-validator.sh
# Exit 0 = safe to restart, Exit 1 = DO NOT restart
# =============================================================================

set -euo pipefail

CONFIG="$HOME/.openclaw/openclaw.json"
ENV_FILE="$HOME/.openclaw/.env"
CRON_FILE="$HOME/.openclaw/cron/jobs.json"
ERRORS=0
WARNINGS=0

echo "🔍 Pre-Restart Validation — $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================================="

# --- Check 1: JSON Syntax ---
echo -n "[1/5] JSON syntax... "
if python3 -c "import json; json.load(open('$CONFIG'))" 2>/dev/null; then
    echo "✅ Valid"
else
    echo "❌ INVALID JSON in $CONFIG"
    ERRORS=$((ERRORS + 1))
fi

# --- Check 2: File Permissions ---
echo -n "[2/5] File permissions... "
PERMS=$(stat -c "%a" "$CONFIG" 2>/dev/null || echo "unknown")
if [ "$PERMS" = "600" ]; then
    echo "✅ $PERMS (owner-only)"
elif [ "$PERMS" = "unknown" ]; then
    echo "⚠️  Could not check permissions"
    WARNINGS=$((WARNINGS + 1))
else
    echo "❌ Permissions are $PERMS (should be 600)"
    ERRORS=$((ERRORS + 1))
fi

# --- Check 3: Env Var References ---
echo -n "[3/5] Env var references... "
# Load .env vars (just the names)
if [ -f "$ENV_FILE" ]; then
    ENV_VARS=$(grep -v '^#' "$ENV_FILE" | grep '=' | cut -d'=' -f1 | sort -u)
else
    echo "❌ .env file not found at $ENV_FILE"
    ERRORS=$((ERRORS + 1))
    ENV_VARS=""
fi

# Extract ${VAR} references from config
REFS=$(grep -oP '\$\{([^}]+)\}' "$CONFIG" 2>/dev/null | sed 's/\${//;s/}//' | sort -u)
MISSING_VARS=""
for ref in $REFS; do
    if ! echo "$ENV_VARS" | grep -qx "$ref"; then
        # Also check actual environment
        if [ -z "${!ref:-}" ]; then
            MISSING_VARS="$MISSING_VARS $ref"
        fi
    fi
done

if [ -z "$MISSING_VARS" ]; then
    REF_COUNT=$(echo "$REFS" | grep -c . 2>/dev/null || echo 0)
    echo "✅ All $REF_COUNT references resolved"
else
    echo "❌ MISSING env vars:$MISSING_VARS"
    echo "   These are referenced in openclaw.json but not defined in .env"
    echo "   Fix: add them to $ENV_FILE or remove the reference from $CONFIG"
    ERRORS=$((ERRORS + 1))
fi

# --- Check 4: Cron Job Secret References ---
echo -n "[4/5] Cron secret refs... "
if [ -f "$CRON_FILE" ]; then
    CRON_REFS=$(grep -oP '\$[A-Z_]+' "$CRON_FILE" 2>/dev/null | sed 's/\$//' | sort -u | grep -v '^[0-9]' || true)
    CRON_MISSING=""
    for ref in $CRON_REFS; do
        if ! echo "$ENV_VARS" | grep -qx "$ref"; then
            if [ -z "${!ref:-}" ]; then
                CRON_MISSING="$CRON_MISSING $ref"
            fi
        fi
    done
    if [ -z "$CRON_MISSING" ]; then
        echo "✅ Clean"
    else
        echo "⚠️  Cron refs without env vars:$CRON_MISSING"
        echo "   (May be intentional in prompt text — verify manually)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "⚠️  No cron file found (skipped)"
    WARNINGS=$((WARNINGS + 1))
fi

# --- Check 5: Config Drift Detection ---
echo -n "[5/6] Config drift... "
if [ -x "$(command -v python3)" ] && [ -f "$HOME/.openclaw/workspace/scripts/config-drift-detector.py" ]; then
    DRIFT_OUTPUT=$(cd "$HOME/.openclaw/workspace" && python3 scripts/config-drift-detector.py check 2>&1 || true)
    DRIFT_CHANGES=$(echo "$DRIFT_OUTPUT" | grep -c "CHANGED\|CRITICAL\|WARNING" 2>/dev/null || echo 0)
    if [ "$DRIFT_CHANGES" -eq 0 ]; then
        echo "✅ No drift detected"
    else
        echo "⚠️  Config drift detected ($DRIFT_CHANGES changes)"
        echo "   Run: config-drift check (for details)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "⚠️  Config drift detector not available (skipped)"
    WARNINGS=$((WARNINGS + 1))
fi

# --- Check 6: Gateway Service Status ---
echo -n "[6/6] Gateway currently running... "
if systemctl --user is-active openclaw-gateway &>/dev/null; then
    echo "✅ Active"
else
    echo "⚠️  Gateway not running (restart will be a cold start)"
    WARNINGS=$((WARNINGS + 1))
fi

# --- Summary ---
echo "=============================================="
if [ $ERRORS -eq 0 ]; then
    echo "✅ Pre-restart validation PASSED — safe to restart"
    [ $WARNINGS -gt 0 ] && echo "   ($WARNINGS warning(s) — non-blocking)"
    exit 0
else
    echo "❌ Pre-restart validation FAILED — DO NOT RESTART"
    echo "   $ERRORS error(s), $WARNINGS warning(s)"
    echo "   Fix the errors above before restarting the gateway."
    exit 1
fi
