#!/usr/bin/env bash
# Test suite for Config Drift Detection

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TEST_DIR="/tmp/config-drift-test-$$"
DETECTOR="$HOME/.openclaw/workspace/scripts/config-drift"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

setup() {
    echo "Setting up test environment..."
    mkdir -p "$TEST_DIR"
    
    # Create test config files
    echo '{"model": "sonnet-4-5", "key": "test123"}' > "$TEST_DIR/test-config.json"
    echo 'API_KEY=original_key' > "$TEST_DIR/test.env"
    echo '# Test comment' > "$TEST_DIR/test-service.conf"
}

# Helper function to run detector methods
run_detector() {
    local method="$1"
    shift
    local args="$@"
    
    python3 <<PYEOF
import sys
import importlib.util

spec = importlib.util.spec_from_file_location("config_drift_detector", 
    "$HOME/.openclaw/workspace/scripts/config-drift-detector.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

detector = module.ConfigDriftDetector()

# Execute method
if "$method" == "create_baseline":
    result = detector.create_baseline("$args")
    sys.exit(0 if result else 1)
elif "$method" == "check_drift":
    result = detector.check_drift("$args")
    print(f"changed: {result['changed']}")
    print(f"level: {result.get('level', 'NONE')}")
    print(f"reason: {result.get('reason', '')}")
elif "$method" == "update_baseline":
    result = detector.update_baseline("$args")
    sys.exit(0 if result else 1)
elif "$method" == "rollback":
    result = detector.rollback("$args")
    sys.exit(0 if result else 1)
PYEOF
}

teardown() {
    echo "Cleaning up test environment..."
    rm -rf "$TEST_DIR"
    
    # Clean up test baselines
    rm -f ~/.openclaw/workspace/config-baselines/*test-*
    rm -f ~/.openclaw/backups/config-drift/*test-*
}

run_test() {
    local test_name="$1"
    TESTS_RUN=$((TESTS_RUN + 1))
    echo ""
    echo -e "${YELLOW}Test $TESTS_RUN: $test_name${NC}"
}

pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓ PASS${NC}"
}

fail() {
    local msg="$1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}✗ FAIL: $msg${NC}"
}

# Test 1: Initialize baseline
test_init_baseline() {
    run_test "Initialize baseline for test file"
    
    if run_detector "create_baseline" "$TEST_DIR/test-config.json"; then
        # Check baseline exists
        baseline_file=$(ls ~/.openclaw/workspace/config-baselines/ | grep test-config.json || true)
        if [[ -n "$baseline_file" ]]; then
            pass
        else
            fail "Baseline file not created"
        fi
    else
        fail "Failed to create baseline"
    fi
}

# Test 2: No drift on unchanged file
test_no_drift() {
    run_test "Detect no drift on unchanged file"
    
    output=$(run_detector "check_drift" "$TEST_DIR/test-config.json")
    
    if echo "$output" | grep -q "changed: False"; then
        pass
    else
        fail "Drift detected on unchanged file"
    fi
}

# Test 3: Detect benign change (INFO)
test_benign_change() {
    run_test "Detect benign change (INFO level)"
    
    # Add comment
    echo '{"model": "sonnet-4-5", "key": "test123"} # comment added' > "$TEST_DIR/test-config.json"
    
    output=$(python3 -c "
import sys
sys.path.insert(0, '$HOME/.openclaw/workspace/scripts')
from config_drift_detector import ConfigDriftDetector
detector = ConfigDriftDetector()
result = detector.check_drift('$TEST_DIR/test-config.json')
print('changed:', result['changed'])
print('level:', result.get('level', 'NONE'))
")
    
    if echo "$output" | grep -q "changed: True"; then
        pass
    else
        fail "Benign change not detected"
    fi
}

# Test 4: Detect model change (WARN)
test_model_change() {
    run_test "Detect model change (WARN level)"
    
    # Reset file first
    echo '{"model": "sonnet-4-5", "key": "test123"}' > "$TEST_DIR/test-config.json"
    python3 -c "
import sys
sys.path.insert(0, '$HOME/.openclaw/workspace/scripts')
from config_drift_detector import ConfigDriftDetector
detector = ConfigDriftDetector()
detector.create_baseline('$TEST_DIR/test-config.json')
"
    
    # Change model
    echo '{"model": "opus-4", "key": "test123"}' > "$TEST_DIR/test-config.json"
    
    output=$(python3 -c "
import sys
sys.path.insert(0, '$HOME/.openclaw/workspace/scripts')
from config_drift_detector import ConfigDriftDetector
detector = ConfigDriftDetector()
result = detector.check_drift('$TEST_DIR/test-config.json')
print('changed:', result['changed'])
print('level:', result.get('level', 'NONE'))
")
    
    if echo "$output" | grep -q "level: WARN"; then
        pass
    else
        fail "Model change not classified as WARN"
    fi
}

# Test 5: Detect new API key (WARN)
test_new_api_key() {
    run_test "Detect new API key (WARN level)"
    
    # Create baseline for env file
    python3 -c "
import sys
sys.path.insert(0, '$HOME/.openclaw/workspace/scripts')
from config_drift_detector import ConfigDriftDetector
detector = ConfigDriftDetector()
detector.create_baseline('$TEST_DIR/test.env')
"
    
    # Add new API key
    echo 'NEW_API_KEY=secret123' >> "$TEST_DIR/test.env"
    
    output=$(python3 -c "
import sys
sys.path.insert(0, '$HOME/.openclaw/workspace/scripts')
from config_drift_detector import ConfigDriftDetector
detector = ConfigDriftDetector()
result = detector.check_drift('$TEST_DIR/test.env')
print('level:', result.get('level', 'NONE'))
")
    
    if echo "$output" | grep -q "level: WARN"; then
        pass
    else
        fail "New API key not classified as WARN"
    fi
}

# Test 6: Detect file deletion (CRITICAL)
test_file_deletion() {
    run_test "Detect file deletion (CRITICAL level)"
    
    # Create temp file and baseline
    echo 'test content' > "$TEST_DIR/temp-file.txt"
    python3 -c "
import sys
sys.path.insert(0, '$HOME/.openclaw/workspace/scripts')
from config_drift_detector import ConfigDriftDetector
detector = ConfigDriftDetector()
detector.create_baseline('$TEST_DIR/temp-file.txt')
"
    
    # Delete file
    rm "$TEST_DIR/temp-file.txt"
    
    output=$(python3 -c "
import sys
sys.path.insert(0, '$HOME/.openclaw/workspace/scripts')
from config_drift_detector import ConfigDriftDetector
detector = ConfigDriftDetector()
result = detector.check_drift('$TEST_DIR/temp-file.txt')
print('level:', result.get('level', 'NONE'))
print('reason:', result.get('reason', 'NONE'))
")
    
    if echo "$output" | grep -q "level: CRITICAL"; then
        pass
    else
        fail "File deletion not classified as CRITICAL"
    fi
}

# Test 7: Approve changes (update baseline)
test_approve_changes() {
    run_test "Approve changes and update baseline"
    
    # Create file and baseline
    echo 'original content' > "$TEST_DIR/approve-test.txt"
    python3 -c "
import sys
sys.path.insert(0, '$HOME/.openclaw/workspace/scripts')
from config_drift_detector import ConfigDriftDetector
detector = ConfigDriftDetector()
detector.create_baseline('$TEST_DIR/approve-test.txt')
"
    
    # Modify file
    echo 'modified content' > "$TEST_DIR/approve-test.txt"
    
    # Approve (update baseline)
    python3 -c "
import sys
sys.path.insert(0, '$HOME/.openclaw/workspace/scripts')
from config_drift_detector import ConfigDriftDetector
detector = ConfigDriftDetector()
detector.update_baseline('$TEST_DIR/approve-test.txt')
"
    
    # Check no drift now
    output=$(python3 -c "
import sys
sys.path.insert(0, '$HOME/.openclaw/workspace/scripts')
from config_drift_detector import ConfigDriftDetector
detector = ConfigDriftDetector()
result = detector.check_drift('$TEST_DIR/approve-test.txt')
print('changed:', result['changed'])
")
    
    if echo "$output" | grep -q "changed: False"; then
        pass
    else
        fail "Baseline not updated after approval"
    fi
}

# Test 8: Rollback changes
test_rollback() {
    run_test "Rollback to previous version"
    
    # Create file and baseline
    echo 'good content' > "$TEST_DIR/rollback-test.txt"
    python3 -c "
import sys
sys.path.insert(0, '$HOME/.openclaw/workspace/scripts')
from config_drift_detector import ConfigDriftDetector
detector = ConfigDriftDetector()
detector.create_baseline('$TEST_DIR/rollback-test.txt')
"
    
    # Create backup manually (simulate existing backup)
    backup_name=$(echo "$TEST_DIR/rollback-test.txt" | sed 's|/|_|g')
    backup_file="$HOME/.openclaw/backups/config-drift/${backup_name}.$(date +%Y%m%d_%H%M%S).backup"
    cp "$TEST_DIR/rollback-test.txt" "$backup_file"
    
    # Modify file (bad change)
    echo 'bad content' > "$TEST_DIR/rollback-test.txt"
    
    # Rollback
    python3 -c "
import sys
sys.path.insert(0, '$HOME/.openclaw/workspace/scripts')
from config_drift_detector import ConfigDriftDetector
detector = ConfigDriftDetector()
detector.rollback('$TEST_DIR/rollback-test.txt')
" 2>&1
    
    # Check content restored
    content=$(cat "$TEST_DIR/rollback-test.txt")
    if [[ "$content" == "good content" ]]; then
        pass
    else
        fail "File not rolled back correctly (got: $content)"
    fi
}

# Test 9: Check all files
test_check_all() {
    run_test "Check all critical files (real system files)"
    
    # This tests against real files - should not fail
    output=$("$DETECTOR" check 2>&1 || true)
    
    # Should complete without Python errors
    if echo "$output" | grep -q "Traceback"; then
        fail "Python error in check all: $output"
    else
        pass
    fi
}

# Test 10: Detect insecure permissions (CRITICAL)
test_insecure_permissions() {
    run_test "Detect insecure permissions (CRITICAL)"
    
    # Create systemd-like service file
    cat > "$TEST_DIR/test-service.conf" <<EOF
[Service]
ExecStart=/usr/bin/test
EOF
    
    python3 -c "
import sys
sys.path.insert(0, '$HOME/.openclaw/workspace/scripts')
from config_drift_detector import ConfigDriftDetector
detector = ConfigDriftDetector()
detector.create_baseline('$TEST_DIR/test-service.conf')
"
    
    # Add chmod 777 command
    cat > "$TEST_DIR/test-service.conf" <<EOF
[Service]
ExecStart=/bin/bash -c 'chmod 777 /tmp/test && /usr/bin/test'
EOF
    
    output=$(python3 -c "
import sys
sys.path.insert(0, '$HOME/.openclaw/workspace/scripts')
from config_drift_detector import ConfigDriftDetector
detector = ConfigDriftDetector()
result = detector.check_drift('$TEST_DIR/test-service.conf')
print('level:', result.get('level', 'NONE'))
")
    
    if echo "$output" | grep -q "level: CRITICAL"; then
        pass
    else
        fail "Insecure permissions not classified as CRITICAL"
    fi
}

# Main test runner
main() {
    echo "======================================"
    echo "Config Drift Detection Test Suite"
    echo "======================================"
    
    setup
    
    test_init_baseline
    test_no_drift
    test_benign_change
    test_model_change
    test_new_api_key
    test_file_deletion
    test_approve_changes
    test_rollback
    test_check_all
    test_insecure_permissions
    
    teardown
    
    echo ""
    echo "======================================"
    echo "Test Results"
    echo "======================================"
    echo -e "Tests run:    $TESTS_RUN"
    echo -e "${GREEN}Passed:       $TESTS_PASSED${NC}"
    echo -e "${RED}Failed:       $TESTS_FAILED${NC}"
    echo "======================================"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed! ✓${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed ✗${NC}"
        exit 1
    fi
}

# Trap cleanup on exit
trap teardown EXIT

main "$@"
