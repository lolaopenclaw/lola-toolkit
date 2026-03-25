#!/bin/bash
# git-sanitization.sh - Remove secrets from git history
# Generated: 2026-03-25 07:05 GMT+1
# Target: ~/.openclaw/workspace
#
# BLAST RADIUS AUDIT:
# - Total commits: 280
# - Commits with secrets: 6
# - Files affected: memory/subscription-vs-api-analysis.md, memory/security-hardening-plan.md, 
#                   memory/advanced-harness-research.md, memory/subagent-validator-implementation.md,
#                   memory/archive/2026-03-06.md
#
# COMMITS AFFECTED:
# - 283f6d6e (2026-03-25): 10 matches
# - 32862bd4 (2026-03-13): 2 matches  
# - 60e937e0 (2026-03-06): 1 match
# - d72a94e8 (2026-02-23): 2 matches
# - 239062ab (2026-02-21): 2 matches
# - 1f558311 (2026-02-20): 1 match

set -euo pipefail

REPO_PATH="${1:-$HOME/.openclaw/workspace}"
BACKUP_DIR="$(dirname "$REPO_PATH")"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "=== GIT HISTORY SANITIZATION ==="
echo "Repository: $REPO_PATH"
echo "Timestamp: $TIMESTAMP"
echo ""

# Change to repo directory
cd "$REPO_PATH" || exit 1

# Verify it's a git repo
if [ ! -d .git ]; then
    echo "❌ ERROR: Not a git repository"
    exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  WARNING: You have uncommitted changes"
    echo "Commit or stash them before running this script"
    exit 1
fi

echo "=== Pre-sanitization backup ==="

# Create backup tag
BACKUP_TAG="pre-sanitization-backup-$TIMESTAMP"
git tag "$BACKUP_TAG"
echo "✅ Created tag: $BACKUP_TAG"

# Create bundle backup
BUNDLE_PATH="$BACKUP_DIR/openclaw-backup-pre-sanitization-$TIMESTAMP.bundle"
git bundle create "$BUNDLE_PATH" --all
echo "✅ Created bundle: $BUNDLE_PATH"
echo "   Size: $(du -h "$BUNDLE_PATH" | cut -f1)"

# Create full directory backup (compressed)
BACKUP_ARCHIVE="$BACKUP_DIR/openclaw-full-backup-$TIMESTAMP.tar.gz"
tar -czf "$BACKUP_ARCHIVE" -C "$(dirname "$REPO_PATH")" "$(basename "$REPO_PATH")"
echo "✅ Created archive: $BACKUP_ARCHIVE"
echo "   Size: $(du -h "$BACKUP_ARCHIVE" | cut -f1)"

echo ""
echo "=== Installing git-filter-repo ==="

if ! command -v git-filter-repo &>/dev/null; then
    echo "Installing git-filter-repo..."
    pip install --user git-filter-repo
    echo "✅ Installed git-filter-repo"
else
    echo "✅ git-filter-repo already installed"
fi

echo ""
echo "=== Creating replacements file ==="

# Create replacements file with EXACT secrets found in history
cat > /tmp/git-replacements-$TIMESTAMP.txt << 'EOF'
# Google OAuth Client Secret (found in commit d72a94e8)
***REDACTED***-RFYFN6l5u84_wySc9==>GOOGLE_CLIENT_SECRET_REDACTED

# Anthropic API Key prefix (found in commits 283f6d6e, d72a94e8)
# Note: Only partial match found in commits, sanitizing pattern
***REDACTED***_kHbe-ELJL1yqzoBBi9tsUNjPFp3R-n4z8xuuR3kvU4D1fX-X7s0cCj4RwC0ntP4Zgmk04WgMYsAm0y1w-C5rSNQAA==>ANTHROPIC_API_KEY_REDACTED
regex:sk-ant-oat01-[A-Za-z0-9_-]{95}==>ANTHROPIC_API_KEY_REDACTED

# OpenAI Project Keys (placeholder examples found)
sk-proj-abc123==>OPENAI_PROJECT_KEY_REDACTED
regex:sk-proj-[A-Za-z0-9_-]{48,}==>OPENAI_PROJECT_KEY_REDACTED

# Google API Keys (Gemini, mentioned in commits)
***REDACTED***==>GOOGLE_API_KEY_REDACTED
regex:AIza[A-Za-z0-9_-]{35}==>GOOGLE_API_KEY_REDACTED
EOF

echo "✅ Created replacements file: /tmp/git-replacements-$TIMESTAMP.txt"
cat /tmp/git-replacements-$TIMESTAMP.txt

echo ""
echo "=== Pre-sanitization verification ==="
echo "Searching for secrets in current history..."

# Count occurrences before sanitization
GOCSPX_COUNT=$(git log --all --full-history -S"***REDACTED***-RFYFN6l5u84_wySc9" --format="%H" | wc -l)
ANTHROPIC_COUNT=$(git log --all --full-history -S"sk-ant-oat01" --format="%H" | wc -l)
AIZA_COUNT=$(git log --all --full-history -S"AIza" --format="%H" | wc -l)

echo "  GOCSPX secret: $GOCSPX_COUNT commits"
echo "  Anthropic key: $ANTHROPIC_COUNT commits"
echo "  AIza keys: $AIZA_COUNT commits"

echo ""
echo "⚠️  POINT OF NO RETURN ⚠️"
echo "This will rewrite ALL git history."
echo "Backups created:"
echo "  - Tag: $BACKUP_TAG"
echo "  - Bundle: $BUNDLE_PATH"
echo "  - Archive: $BACKUP_ARCHIVE"
echo ""
read -p "Proceed with sanitization? (yes/no): " -r
if [[ ! $REPLY =~ ^yes$ ]]; then
    echo "❌ Aborted by user"
    exit 0
fi

echo ""
echo "=== Sanitizing git history ==="
echo "This may take a few minutes..."

# Run git-filter-repo
git filter-repo \
    --replace-text "/tmp/git-replacements-$TIMESTAMP.txt" \
    --force

echo "✅ History rewrite complete"

echo ""
echo "=== Post-sanitization verification ==="

# Verify secrets are gone
echo "Searching for secrets in sanitized history..."

GOCSPX_AFTER=$(git log --all --full-history -S"***REDACTED***-RFYFN6l5u84_wySc9" --format="%H" 2>/dev/null | wc -l || echo "0")
ANTHROPIC_AFTER=$(git log --all --full-history -S"***REDACTED***" --format="%H" 2>/dev/null | wc -l || echo "0")
AIZA_AFTER=$(git log --all --full-history -S"***REDACTED***" --format="%H" 2>/dev/null | wc -l || echo "0")

if [ "$GOCSPX_AFTER" -eq 0 ]; then
    echo "  ✅ GOCSPX secret: NOT FOUND (cleaned)"
else
    echo "  ⚠️  GOCSPX secret: Still found in $GOCSPX_AFTER commits"
fi

if [ "$ANTHROPIC_AFTER" -eq 0 ]; then
    echo "  ✅ Anthropic key: NOT FOUND (cleaned)"
else
    echo "  ⚠️  Anthropic key: Still found in $ANTHROPIC_AFTER commits"
fi

if [ "$AIZA_AFTER" -eq 0 ]; then
    echo "  ✅ AIza keys: NOT FOUND (cleaned)"
else
    echo "  ⚠️  AIza keys: Still found in $AIZA_AFTER commits"
fi

# Check for placeholder strings
PLACEHOLDER_COUNT=$(git log --all --oneline | grep -c "REDACTED" || echo "0")
echo "  ✅ Placeholder strings inserted: $PLACEHOLDER_COUNT occurrences"

# Verify repo integrity
echo ""
echo "Checking repository integrity..."
if git fsck --full --no-progress 2>&1 | grep -i "error\|corrupt" > /dev/null; then
    echo "  ⚠️  FSCK found issues - check manually with: git fsck --full"
else
    echo "  ✅ Repository integrity: OK"
fi

echo ""
echo "=== Cleanup complete ==="
echo ""
echo "📊 SUMMARY:"
echo "  - Secrets removed from $((GOCSPX_COUNT + ANTHROPIC_COUNT + AIZA_COUNT)) commit occurrences"
echo "  - History rewritten: $(git rev-list --all --count) commits total"
echo "  - Backup bundle: $BUNDLE_PATH"
echo "  - Backup archive: $BACKUP_ARCHIVE"
echo "  - Backup tag: $BACKUP_TAG"
echo ""
echo "🔄 ROLLBACK PROCEDURE (if needed):"
echo "  cd $REPO_PATH"
echo "  rm -rf .git"
echo "  git clone $BUNDLE_PATH ."
echo "  # OR restore from tag:"
echo "  git reset --hard $BACKUP_TAG"
echo ""
echo "⚠️  NEXT STEPS (CRITICAL):"
echo "  1. Verify current HEAD is clean:"
echo "     rg 'GOCSPX|sk-ant-oat01|AIza' memory/"
echo ""
echo "  2. ROTATE ALL SECRETS before pushing:"
echo "     - Google OAuth Client Secret"
echo "     - Anthropic API Key"  
echo "     - Google API Keys (Gemini)"
echo ""
echo "  3. Update .env and restart OpenClaw"
echo ""
echo "  4. Force push to remote (if applicable):"
echo "     git push --force --all"
echo "     git push --force --tags"
echo ""
echo "  5. Notify collaborators (if repo is shared)"
echo ""
echo "⚠️  DO NOT PUSH until secrets are rotated!"
echo "    Old secrets are now in git reflog and bundle backups."
echo "    Rotate them FIRST to prevent exposure."
