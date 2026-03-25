#!/bin/bash
# verify-sanitization.sh - Verify git history is clean
# Run AFTER git-sanitization.sh completes

set -euo pipefail

REPO_PATH="${1:-$HOME/.openclaw/workspace}"
cd "$REPO_PATH" || exit 1

echo "=== Git History Sanitization Verification ==="
echo "Repository: $REPO_PATH"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ISSUES_FOUND=0

echo "🔍 Checking for secrets in git history..."
echo ""

# Check 1: GOCSPX (Google OAuth)
echo -n "  [1/7] Google OAuth Client Secret (GOCSPX)... "
if git log --all --full-history -S"***REDACTED***-RFYFN6l5u84_wySc9" --format="%H" 2>/dev/null | grep -q .; then
    echo -e "${RED}FOUND ❌${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
    git log --all --full-history -S"***REDACTED***-RFYFN6l5u84_wySc9" --pretty=format:"    %H | %ai | %s" | head -3
else
    echo -e "${GREEN}CLEAN ✅${NC}"
fi

# Check 2: Anthropic full key
echo -n "  [2/7] Anthropic API Key (full)... "
if git log --all --full-history -S"***REDACTED***" --format="%H" 2>/dev/null | grep -q .; then
    echo -e "${RED}FOUND ❌${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}CLEAN ✅${NC}"
fi

# Check 3: Anthropic pattern
echo -n "  [3/7] Anthropic API Key (pattern)... "
if git log --all --full-history --pickaxe-regex -S"sk-ant-oat01-[A-Za-z0-9_-]{95}" --format="%H" 2>/dev/null | grep -q .; then
    echo -e "${RED}FOUND ❌${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}CLEAN ✅${NC}"
fi

# Check 4: Google Gemini API key
echo -n "  [4/7] Google Gemini API Key... "
if git log --all --full-history -S"***REDACTED***" --format="%H" 2>/dev/null | grep -q .; then
    echo -e "${RED}FOUND ❌${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}CLEAN ✅${NC}"
fi

# Check 5: Any AIza keys
echo -n "  [5/7] Google API Keys (AIza pattern)... "
AIza_COUNT=$(git log --all --full-history --pickaxe-regex -S"AIza[A-Za-z0-9_-]{35}" --format="%H" 2>/dev/null | wc -l || echo "0")
if [ "$AIza_COUNT" -gt 6 ]; then
    # 6 is expected (placeholders), more means real keys remain
    echo -e "${YELLOW}SUSPICIOUS ($AIza_COUNT commits) ⚠️${NC}"
    echo "    Expected: ~6 commits with REDACTED placeholders"
    echo "    Found: $AIza_COUNT commits"
elif [ "$AIza_COUNT" -gt 0 ]; then
    echo -e "${GREEN}OK ($AIza_COUNT placeholders) ✅${NC}"
else
    echo -e "${GREEN}CLEAN ✅${NC}"
fi

# Check 6: Working tree
echo -n "  [6/7] Current working tree... "
if rg '***REDACTED***|***REDACTED***|***REDACTED***' . --type md --quiet 2>/dev/null; then
    echo -e "${RED}SECRETS FOUND ❌${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
    echo "    Files with secrets:"
    rg '***REDACTED***|***REDACTED***|***REDACTED***' . --type md --files-with-matches | sed 's/^/      - /'
else
    echo -e "${GREEN}CLEAN ✅${NC}"
fi

# Check 7: Placeholders inserted
echo -n "  [7/7] REDACTED placeholders... "
REDACTED_COUNT=$(git log --all --oneline | grep -c "REDACTED" || echo "0")
if [ "$REDACTED_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}NONE FOUND ⚠️${NC}"
    echo "    Warning: Expected placeholder strings not found"
    echo "    This might indicate sanitization didn't run"
else
    echo -e "${GREEN}$REDACTED_COUNT found ✅${NC}"
fi

echo ""
echo "🔧 Repository integrity check..."
if git fsck --full --no-progress 2>&1 | grep -i "error\|corrupt" > /dev/null; then
    echo -e "${RED}  ISSUES DETECTED ❌${NC}"
    echo "  Run: git fsck --full"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo -e "${GREEN}  OK ✅${NC}"
fi

echo ""
echo "📊 Commit count: $(git rev-list --all --count)"

echo ""
echo "=== Verification Summary ==="
if [ "$ISSUES_FOUND" -eq 0 ]; then
    echo -e "${GREEN}✅ ALL CHECKS PASSED${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Rotate all secrets (see SANITIZATION-REPORT.md)"
    echo "  2. Update ~/.openclaw/.env with new secrets"
    echo "  3. Restart OpenClaw: openclaw gateway restart"
    echo "  4. Test integrations"
    echo "  5. (Optional) Force push to remote: git push --force --all"
else
    echo -e "${RED}❌ $ISSUES_FOUND ISSUE(S) FOUND${NC}"
    echo ""
    echo "Action required:"
    echo "  1. Review findings above"
    echo "  2. Re-run git-sanitization.sh if secrets remain"
    echo "  3. Check replacements file for missing patterns"
fi

exit $ISSUES_FOUND
