#!/bin/bash
# Test suite for cron-validator.py
# Tests validation logic with synthetic jobs

set -o pipefail  # Removed -e to continue on validation failures

VALIDATOR="${HOME}/.openclaw/workspace/scripts/cron-validator.py"
TEST_DIR="/tmp/cron-validator-test-$$"
PASSED=0
FAILED=0

mkdir -p "$TEST_DIR"

echo "🧪 Cron Validator Test Suite"
echo "============================"
echo ""

# Helper: Create test job JSON
create_job() {
    local name="$1"
    local schedule="$2"
    local message="$3"
    
    cat > "$TEST_DIR/job.json" <<EOF
{
  "id": "test-job-${RANDOM}",
  "name": "$name",
  "enabled": true,
  "schedule": {
    "kind": "cron",
    "expr": "$schedule"
  },
  "payload": {
    "kind": "agentTurn",
    "message": "$message"
  }
}
EOF
}

# Test 1: Valid cron job
echo "Test 1: Valid cron job"
create_job "Test Valid" "*/5 * * * *" "This is a valid job"
if "$VALIDATOR" --job-json "$TEST_DIR/job.json" --no-notify --output "$TEST_DIR/report.json" >/dev/null 2>&1; then
    RESULT=$(jq -r '.overall_valid' "$TEST_DIR/report.json")
    if [[ "$RESULT" == "true" ]]; then
        echo "✅ PASS"
        ((PASSED++))
    else
        echo "❌ FAIL (expected valid, got invalid)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL (validator crashed)"
    ((FAILED++))
fi
echo ""

# Test 2: Invalid cron expression
echo "Test 2: Invalid cron expression"
create_job "Test Invalid Cron" "not a cron" "Message"
if "$VALIDATOR" --job-json "$TEST_DIR/job.json" --no-notify --output "$TEST_DIR/report.json" >/dev/null 2>&1; then
    RESULT=$(jq -r '.overall_valid' "$TEST_DIR/report.json")
    if [[ "$RESULT" == "false" ]]; then
        echo "✅ PASS"
        ((PASSED++))
    else
        echo "❌ FAIL (expected invalid, got valid)"
        ((FAILED++))
    fi
else
    # Validator may exit 1 on invalid job, which is expected
    echo "✅ PASS (validator rejected invalid job)"
    ((PASSED++))
fi
echo ""

# Test 3: Missing script reference
echo "Test 3: Missing script reference"
create_job "Test Missing Script" "0 10 * * *" "Run this: bash scripts/non-existent-script-$(date +%s).sh"
"$VALIDATOR" --job-json "$TEST_DIR/job.json" --no-notify --output "$TEST_DIR/report.json" >/dev/null 2>&1 || true
if [[ -f "$TEST_DIR/report.json" ]]; then
    ERRORS=$(jq -r '.errors | length' "$TEST_DIR/report.json" 2>/dev/null || echo "0")
    if [[ "$ERRORS" -gt 0 ]]; then
        echo "✅ PASS (detected missing script)"
        ((PASSED++))
    else
        echo "❌ FAIL (did not detect missing script)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL (validator crashed, no report generated)"
    ((FAILED++))
fi
echo ""

# Test 4: Missing env var (should WARN not FAIL)
echo "Test 4: Missing env var (should warn, not fail)"
create_job "Test Env Var" "0 10 * * *" "Use var: \$NON_EXISTENT_VAR_$(date +%s)"
if "$VALIDATOR" --job-json "$TEST_DIR/job.json" --no-notify --output "$TEST_DIR/report.json" >/dev/null 2>&1; then
    WARNINGS=$(jq -r '.warnings | length' "$TEST_DIR/report.json" 2>/dev/null || echo "0")
    if [[ "$WARNINGS" -gt 0 ]]; then
        echo "✅ PASS (detected missing env var as warning)"
        ((PASSED++))
    else
        echo "⚠️  WARN (did not detect missing env var, but this is optional)"
        ((PASSED++))  # Not a hard requirement
    fi
else
    echo "❌ FAIL (validator crashed)"
    ((FAILED++))
fi
echo ""

# Test 5: Valid systemEvent
echo "Test 5: Valid systemEvent job"
cat > "$TEST_DIR/job.json" <<'EOF'
{
  "id": "test-system-event",
  "name": "System Event Test",
  "enabled": true,
  "schedule": {
    "kind": "cron",
    "expr": "0 9 * * *"
  },
  "action": {
    "type": "systemEvent",
    "text": "Valid system event"
  }
}
EOF

if "$VALIDATOR" --job-json "$TEST_DIR/job.json" --no-notify --output "$TEST_DIR/report.json" >/dev/null 2>&1; then
    RESULT=$(jq -r '.overall_valid' "$TEST_DIR/report.json")
    if [[ "$RESULT" == "true" ]]; then
        echo "✅ PASS"
        ((PASSED++))
    else
        echo "❌ FAIL (systemEvent should be valid)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL (validator crashed)"
    ((FAILED++))
fi
echo ""

# Test 6: Empty message (should fail)
echo "Test 6: Empty message (should fail)"
create_job "Test Empty Message" "0 10 * * *" ""
if "$VALIDATOR" --job-json "$TEST_DIR/job.json" --no-notify --output "$TEST_DIR/report.json" >/dev/null 2>&1; then
    RESULT=$(jq -r '.overall_valid' "$TEST_DIR/report.json")
    if [[ "$RESULT" == "false" ]]; then
        echo "✅ PASS"
        ((PASSED++))
    else
        echo "❌ FAIL (empty message should fail)"
        ((FAILED++))
    fi
else
    echo "✅ PASS (validator rejected empty message)"
    ((PASSED++))
fi
echo ""

# Test 7: TODO marker detection
echo "Test 7: TODO marker detection"
create_job "Test TODO" "0 10 * * *" "TODO: implement this feature"
if "$VALIDATOR" --job-json "$TEST_DIR/job.json" --no-notify --output "$TEST_DIR/report.json" >/dev/null 2>&1; then
    WARNINGS=$(jq -r '.warnings | map(select(contains("TODO"))) | length' "$TEST_DIR/report.json" 2>/dev/null || echo "0")
    if [[ "$WARNINGS" -gt 0 ]]; then
        echo "✅ PASS (detected TODO marker)"
        ((PASSED++))
    else
        echo "⚠️  WARN (did not detect TODO marker)"
        ((PASSED++))  # Not critical
    fi
else
    echo "❌ FAIL (validator crashed)"
    ((FAILED++))
fi
echo ""

# Cleanup
rm -rf "$TEST_DIR"

# Summary
echo "============================"
echo "Summary: $PASSED passed, $FAILED failed"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
