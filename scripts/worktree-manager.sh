#!/bin/bash
# worktree-manager.sh — Create and manage git worktrees for parallel sub-agents
# Usage:
#   worktree-manager.sh create <repo-path> <issue-number> [base-branch]
#   worktree-manager.sh remove <repo-path> <issue-number>
#   worktree-manager.sh cleanup <repo-path>
#   worktree-manager.sh list <repo-path>
#   worktree-manager.sh path <repo-path> <issue-number>

set -euo pipefail

ACTION="${1:-help}"
REPO_PATH="${2:-}"
ISSUE_NUM="${3:-}"
BASE_BRANCH="${4:-main}"

WORKTREE_DIR="${REPO_PATH}/.worktrees"

usage() {
    echo "Usage:"
    echo "  $0 create <repo-path> <issue-number> [base-branch]"
    echo "  $0 remove <repo-path> <issue-number>"
    echo "  $0 cleanup <repo-path>  (remove all worktrees)"
    echo "  $0 list <repo-path>"
    echo "  $0 path <repo-path> <issue-number>  (print worktree path)"
    exit 1
}

create_worktree() {
    [ -z "$REPO_PATH" ] || [ -z "$ISSUE_NUM" ] && usage

    local wt_path="${WORKTREE_DIR}/issue-${ISSUE_NUM}"
    local branch_name="fix/issue-${ISSUE_NUM}"

    # Ensure we're in the repo
    cd "$REPO_PATH"

    # Create worktrees directory
    mkdir -p "$WORKTREE_DIR"

    # Add to .gitignore if not already there
    if ! grep -q "^\.worktrees/$" .gitignore 2>/dev/null; then
        echo ".worktrees/" >> .gitignore
    fi

    # Fetch latest (if remote exists)
    git fetch origin "$BASE_BRANCH" 2>/dev/null || true

    # Remove stale worktree if exists
    if [ -d "$wt_path" ]; then
        git worktree remove --force "$wt_path" 2>/dev/null || rm -rf "$wt_path"
    fi

    # Delete branch if it exists locally (stale from previous run)
    git branch -D "$branch_name" 2>/dev/null || true

    # Determine base ref: prefer origin/<branch> if available, fallback to local branch
    local base_ref
    if git rev-parse --verify "origin/${BASE_BRANCH}" >/dev/null 2>&1; then
        base_ref="origin/${BASE_BRANCH}"
    elif git rev-parse --verify "${BASE_BRANCH}" >/dev/null 2>&1; then
        base_ref="${BASE_BRANCH}"
    else
        echo "ERROR: Neither origin/${BASE_BRANCH} nor ${BASE_BRANCH} found" >&2
        exit 1
    fi

    # Create worktree with new branch from base
    git worktree add -b "$branch_name" "$wt_path" "$base_ref"

    echo "$wt_path"
}

remove_worktree() {
    [ -z "$REPO_PATH" ] || [ -z "$ISSUE_NUM" ] && usage

    local wt_path="${WORKTREE_DIR}/issue-${ISSUE_NUM}"

    cd "$REPO_PATH"

    if [ -d "$wt_path" ]; then
        git worktree remove --force "$wt_path" 2>/dev/null || rm -rf "$wt_path"
        echo "Removed worktree for issue-${ISSUE_NUM}"
    else
        echo "No worktree found for issue-${ISSUE_NUM}"
    fi

    # Clean up the branch too
    git branch -D "fix/issue-${ISSUE_NUM}" 2>/dev/null || true

    # Prune stale worktree refs
    git worktree prune
}

cleanup_all() {
    [ -z "$REPO_PATH" ] && usage

    cd "$REPO_PATH"

    # Remove all worktrees in our directory
    if [ -d "$WORKTREE_DIR" ]; then
        for wt in "$WORKTREE_DIR"/issue-*; do
            [ -d "$wt" ] || continue
            local num
            num=$(basename "$wt" | sed 's/issue-//')
            git worktree remove --force "$wt" 2>/dev/null || rm -rf "$wt"
            git branch -D "fix/issue-${num}" 2>/dev/null || true
            echo "Cleaned up worktree for issue-${num}"
        done
        rmdir "$WORKTREE_DIR" 2>/dev/null || true
    fi

    git worktree prune
    echo "All worktrees cleaned up."
}

list_worktrees() {
    [ -z "$REPO_PATH" ] && usage

    cd "$REPO_PATH"
    git worktree list
}

get_path() {
    [ -z "$REPO_PATH" ] || [ -z "$ISSUE_NUM" ] && usage
    echo "${WORKTREE_DIR}/issue-${ISSUE_NUM}"
}

case "$ACTION" in
    create)  create_worktree ;;
    remove)  remove_worktree ;;
    cleanup) cleanup_all ;;
    list)    list_worktrees ;;
    path)    get_path ;;
    *)       usage ;;
esac
