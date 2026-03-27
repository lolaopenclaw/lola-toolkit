#!/bin/bash
# =============================================================================
# track-autoresearch.sh — Seguimiento semanal del repo autoresearch de Karpathy
# =============================================================================
# Revisa: commits recientes, forks nuevos, issues/discussions, menciones
# Se ejecuta semanalmente (cron job)
# =============================================================================

set -euo pipefail

REPO="karpathy/autoresearch"
DAYS_BACK=7
CHANGES_FOUND=false
REPORT=""

echo "🔬 Autoresearch Tracker — $(date '+%Y-%m-%d')"
echo ""

SINCE=$(date -d "-${DAYS_BACK} days" -u +%Y-%m-%dT%H:%M:%SZ)

# Parallelize all GitHub API calls
{ COMMITS=$(gh api "repos/${REPO}/commits?since=${SINCE}&per_page=10" --jq '.[].commit.message' 2>/dev/null || echo ""); } &
{ RELEASES=$(gh api "repos/${REPO}/releases?per_page=3" --jq '.[0].tag_name // "none"' 2>/dev/null || echo "none"); } &
{ REPO_INFO=$(gh api "repos/${REPO}" --jq '.stargazers_count,.forks_count' 2>/dev/null || echo "?\n?"); } &
{ ISSUES=$(gh api "repos/${REPO}/issues?since=${SINCE}&per_page=5&state=all" --jq '.[].title' 2>/dev/null || echo ""); } &
wait

# Parse repo info
STARS=$(echo "$REPO_INFO" | sed -n '1p')
FORKS=$(echo "$REPO_INFO" | sed -n '2p')

# --- 1. Commits recientes ---------------------------------------------------
if [ -n "$COMMITS" ]; then
    COMMIT_COUNT=$(echo "$COMMITS" | wc -l)
    REPORT+="📝 ${COMMIT_COUNT} commits nuevos:\n"
    REPORT+="$(echo "$COMMITS" | head -5)\n\n"
    CHANGES_FOUND=true
else
    REPORT+="📝 Sin commits nuevos esta semana\n"
fi

# --- 2. Releases nuevas -----------------------------------------------------
if [ "$RELEASES" != "none" ] && [ "$RELEASES" != "null" ]; then
    REPORT+="🏷️ Última release: ${RELEASES}\n"
    CHANGES_FOUND=true
fi

# --- 3. Stars (indicador de tracción) ----------------------------------------
REPORT+="⭐ Stars: ${STARS} | 🍴 Forks: ${FORKS}\n"

# --- 4. Issues/Discussions recientes -----------------------------------------
if [ -n "$ISSUES" ]; then
    ISSUE_COUNT=$(echo "$ISSUES" | wc -l)
    REPORT+="💬 ${ISSUE_COUNT} issues/discussions recientes:\n"
    REPORT+="$(echo "$ISSUES" | head -3)\n"
    CHANGES_FOUND=true
fi

# --- 5. Buscar menciones relevantes ------------------------------------------
# (Solo título, no necesita fetch completo)
REPORT+="\n"

# --- Output ------------------------------------------------------------------
echo -e "$REPORT"

if [ "$CHANGES_FOUND" = true ]; then
    echo "STATUS: CHANGES_DETECTED"
else
    echo "STATUS: NO_CHANGES"
fi
