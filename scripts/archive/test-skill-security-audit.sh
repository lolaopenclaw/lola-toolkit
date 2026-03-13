#!/usr/bin/env bash
# ============================================================
# Test Suite for skill-security-audit.sh (SIMPLIFIED)
# ============================================================
set -uo pipefail

TEST_DIR="/tmp/skill-security-audit-tests-$$"
AUDIT_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skill-security-audit.sh"
PASS=0
FAIL=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Cleanup
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Test framework
test_case() {
    local name="$1" expected_exit="$2" cmd="$3"
    echo -ne "TEST: $name ... "
    
    # Run command with env var and capture exit code
    (export OPENCLAW_WORKSPACE="$TEST_DIR"; eval "$cmd" >/tmp/test-out.$$ 2>&1)
    local actual_exit=$?
    rm -f /tmp/test-out.$$
    
    if [ "$actual_exit" -eq "$expected_exit" ]; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASS++))
    else
        echo -e "${RED}❌ FAIL (expected $expected_exit, got $actual_exit)${NC}"
        ((FAIL++))
    fi
}

# Skill factory
make_test_skill() {
    local skill_name="$1" pattern="$2"
    local skill_dir="$TEST_DIR/skills/$skill_name"
    mkdir -p "$skill_dir"
    
    # Basic SKILL.md
    cat > "$skill_dir/SKILL.md" << 'EOF'
# Test Skill
A skill for testing security audits.
EOF

    cat > "$skill_dir/SKILL.sh" << 'EOF'
#!/bin/bash
# Test skill script
EOF

    # Add pattern-specific code
    case "$pattern" in
        clean)
            cat >> "$skill_dir/SKILL.sh" << 'EOF'
echo "Hello"
EOF
            ;;
        eval_bad)
            cat >> "$skill_dir/SKILL.sh" << 'EOF'
eval "$USER_INPUT"
EOF
            ;;
        exec_bad)
            cat >> "$skill_dir/SKILL.sh" << 'EOF'
exec "dangerous-command"
EOF
            ;;
        network)
            cat >> "$skill_dir/SKILL.sh" << 'EOF'
curl https://example.com/data
EOF
            ;;
        credentials)
            cat >> "$skill_dir/SKILL.sh" << 'EOF'
API_KEY="sk_test_12345678901234567890"
EOF
            ;;
        env_file)
            cat > "$skill_dir/.env" << 'EOF'
DATABASE_PASSWORD=super_secret
EOF
            ;;
    esac

    chmod +x "$skill_dir/SKILL.sh"
}

echo "🧪 Skill Security Audit Test Suite"
echo "=================================="
echo ""

# Test 1: Help flag
test_case "Help flag" 0 "bash $AUDIT_SCRIPT --help"

# Test 2: Missing skill
test_case "Missing skill error" 1 "bash $AUDIT_SCRIPT nonexistent-skill"

# Test 3: No skill specified
test_case "No skill specified error" 1 "bash $AUDIT_SCRIPT"

# Create test skills
make_test_skill "clean" "clean"
make_test_skill "eval-skill" "eval_bad"
make_test_skill "network-skill" "network"
make_test_skill "creds-skill" "credentials"
make_test_skill "env-skill" "env_file"

# Test 4: Audit clean skill
test_case "Audit clean skill" 0 "bash $AUDIT_SCRIPT clean"

# Test 5: Score flag
test_case "Score-only flag" 0 "bash $AUDIT_SCRIPT clean --score"

# Test 6: JSON output
test_case "JSON output flag" 0 "bash $AUDIT_SCRIPT clean --json"

# Test 7: Detect eval
test_case "Detect eval() in skill" 0 "bash $AUDIT_SCRIPT eval-skill"

# Test 8: Detect network calls
test_case "Detect network calls" 0 "bash $AUDIT_SCRIPT network-skill"

# Test 9: Detect hardcoded credentials
test_case "Detect hardcoded credentials" 0 "bash $AUDIT_SCRIPT creds-skill"

# Test 10: Detect .env file
test_case "Detect .env file" 0 "bash $AUDIT_SCRIPT env-skill"

# Test 11: Strict mode - clean skill passes
test_case "Strict mode: clean skill" 0 "bash $AUDIT_SCRIPT clean --strict"

# Test 12: Strict mode - skill with issues fails
test_case "Strict mode: eval skill fails" 1 "bash $AUDIT_SCRIPT eval-skill --strict"

# Test 13: Strict mode with JSON
test_case "Strict mode JSON output" 0 "bash $AUDIT_SCRIPT clean --strict --json"

# Test 14: STRICTNESS env var
test_case "STRICTNESS env var" 1 "STRICTNESS=1 bash $AUDIT_SCRIPT eval-skill"

# Test 15: Report generation
mkdir -p "$TEST_DIR/memory/audits"
test_case "Report generation" 0 "bash $AUDIT_SCRIPT clean --report"

echo ""
echo "=================================="
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAIL test(s) failed${NC}"
    exit 1
fi
