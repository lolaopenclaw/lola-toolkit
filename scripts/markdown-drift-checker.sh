#!/usr/bin/env bash
set -uo pipefail
# Note: -e disabled because grep/bc may return 1 on no-match, which is expected

# Markdown Drift Checker
# Audits workspace markdown files for inconsistencies, orphans, and staleness

WORKSPACE_ROOT="/home/mleon/.openclaw/workspace"
REPORT_FILE="$WORKSPACE_ROOT/memory/drift-check-latest.md"
EXIT_CODE=0

# Key files to cross-reference
KEY_FILES=(
  "MEMORY.md"
  "TOOLS.md"
  "USER.md"
  "IDENTITY.md"
  "SOUL.md"
  "AGENTS.md"
  "HEARTBEAT.md"
)

# Initialize report
init_report() {
  cat > "$REPORT_FILE" << EOF
# Markdown Drift Check Report
Generated: $(date -Iseconds)

## Summary
EOF
}

# Add issue to report
add_issue() {
  local severity="$1"
  local category="$2"
  local message="$3"
  
  echo "" >> "$REPORT_FILE"
  echo "### [$severity] $category" >> "$REPORT_FILE"
  echo "$message" >> "$REPORT_FILE"
  
  EXIT_CODE=1
}

# Cross-reference check: broken links
check_broken_links() {
  echo "🔗 Checking broken markdown links..."
  local broken_count=0
  local all_broken=$(mktemp)
  
  for key_file in "${KEY_FILES[@]}"; do
    local file_path="$WORKSPACE_ROOT/$key_file"
    
    [[ ! -f "$file_path" ]] && continue
    
    # Extract all .md references to a temp file
    local refs_tmp=$(mktemp)
    grep -oE '\b[A-Za-z0-9_/-]+\.md\b' "$file_path" 2>/dev/null | sort -u > "$refs_tmp" || true
    
    # Check each reference
    if [[ -s "$refs_tmp" ]]; then
      while IFS= read -r ref; do
        # Skip problematic refs
        [[ -z "$ref" ]] && continue
        [[ "$ref" == "$key_file" ]] && continue
        [[ "$ref" =~ ^(README|CHANGELOG|LICENSE)\.md$ ]] && continue
        # Skip template patterns (YYYY-MM-DD.md is an instruction, not a real file)
        [[ "$ref" =~ YYYY-MM-DD\.md ]] && continue
        
        # Check if file exists
        if [[ ! -f "$WORKSPACE_ROOT/$ref" ]] && [[ ! -f "$(dirname "$file_path")/$ref" ]]; then
          echo "$key_file|$ref" >> "$all_broken"
        fi
      done < "$refs_tmp"
    fi
    
    rm -f "$refs_tmp"
  done
  
  # Process broken links
  if [[ -s "$all_broken" ]]; then
    while IFS='|' read -r file ref; do
      add_issue "HIGH" "Broken Link" \
        "**$file** references non-existent file: \`$ref\`"
      ((broken_count++))
    done < "$all_broken"
    
    echo "  ❌ Found $broken_count broken link(s)"
  else
    echo "  ✅ No broken links found"
  fi
  
  rm -f "$all_broken"
}

# Cross-reference check: conflicting information
check_conflicts() {
  echo "⚔️  Checking for conflicting information..."
  
  # Check timezone consistency
  local tz_madrid=$(grep -ihc "europe/madrid\|madrid" "$WORKSPACE_ROOT"/{USER,TOOLS,MEMORY}.md 2>/dev/null | paste -sd+ | bc || echo 0)
  local tz_total=$(grep -ihc "timezone\|time.*zone" "$WORKSPACE_ROOT"/{USER,TOOLS,MEMORY}.md 2>/dev/null | paste -sd+ | bc || echo 0)
  
  if [[ $tz_total -gt 0 ]] && [[ $tz_madrid -lt $tz_total ]]; then
    add_issue "MEDIUM" "Potential Conflict" \
      "Timezone references may be inconsistent (found $tz_total mentions, only $tz_madrid Madrid)"
  fi
  
  echo "  ✅ Conflict check complete"
}

# Duplicate detection
check_duplicates() {
  echo "📋 Checking for duplicate information..."
  local dup_count=0
  local temp_sentences=$(mktemp)
  
  for key_file in "${KEY_FILES[@]}"; do
    local file_path="$WORKSPACE_ROOT/$key_file"
    [[ ! -f "$file_path" ]] && continue
    
    # Extract meaningful lines
    grep -v '^#\|^-\|^*\|^[[:space:]]*$' "$file_path" 2>/dev/null | \
      awk 'length($0) > 30' | \
      sed "s|^|$key_file\t|" >> "$temp_sentences" || true
  done
  
  # Find duplicates across files
  awk -F'\t' '{print $2}' "$temp_sentences" | sort | uniq -d | while read -r dup_line; do
    [[ -z "$dup_line" ]] && continue
    
    local files_with_dup=$(grep -F "$dup_line" "$temp_sentences" | cut -f1 | sort -u | tr '\n' ',' | sed 's/,$//')
    local file_count=$(echo "$files_with_dup" | tr ',' '\n' | wc -l)
    
    if [[ $file_count -gt 1 ]]; then
      add_issue "LOW" "Duplicate Content" \
        "Line appears in $file_count files ($files_with_dup): \`${dup_line:0:60}...\`"
      ((dup_count++))
    fi
  done || true
  
  rm -f "$temp_sentences"
  
  if [[ $dup_count -eq 0 ]]; then
    echo "  ✅ No significant duplicates"
  else
    echo "  ⚠️  Found $dup_count duplicate(s)"
  fi
}

# Orphan detection
check_orphans() {
  echo "🏝️  Checking for orphaned files..."
  local orphan_count=0
  local orphans_file=$(mktemp)
  local all_content=$(mktemp)
  
  # Directories to exclude from orphan detection (managed by automated systems)
  local exclude_dirs=(
    "entities"
    "archive"
    "garmin"
    "surf"
    "WAL"
    "best-practices"
  )
  
  # Build find exclude pattern
  local find_exclude=""
  for dir in "${exclude_dirs[@]}"; do
    find_exclude="$find_exclude -path '$WORKSPACE_ROOT/memory/$dir' -prune -o"
  done
  
  # Collect all content to search through
  find "$WORKSPACE_ROOT" -maxdepth 1 -name "*.md" -type f -exec cat {} \; > "$all_content" 2>/dev/null
  eval "find '$WORKSPACE_ROOT/memory' $find_exclude -name '*.md' -type f -print" | xargs cat >> "$all_content" 2>/dev/null || true
  
  # Check each memory file (excluding managed directories)
  eval "find '$WORKSPACE_ROOT/memory' $find_exclude -name '*.md' -type f -print" 2>/dev/null | while read -r mem_file; do
    local basename=$(basename "$mem_file")
    local relpath="${mem_file#$WORKSPACE_ROOT/}"
    
    if ! grep -q -F "$basename" "$all_content" && ! grep -q -F "$relpath" "$all_content"; then
      echo "$relpath" >> "$orphans_file"
    fi
  done || true
  
  # Report orphans
  if [[ -s "$orphans_file" ]]; then
    orphan_count=$(wc -l < "$orphans_file")
    local orphan_list=$(head -15 "$orphans_file" | sed 's/^/  - /')
    
    add_issue "MEDIUM" "Orphaned Files" \
      "Found $orphan_count file(s) in memory/ with no references:\n$orphan_list"
    
    [[ $orphan_count -gt 15 ]] && echo "  (showing first 15 of $orphan_count)" >> "$REPORT_FILE"
    echo "  ⚠️  Found $orphan_count orphan(s)"
  else
    echo "  ✅ No orphans found"
  fi
  
  rm -f "$orphans_file" "$all_content"
}

# Staleness check
check_staleness() {
  echo "📅 Checking for stale files (>90 days)..."
  local stale_file=$(mktemp)
  
  find "$WORKSPACE_ROOT" -maxdepth 1 -name "*.md" -type f -mtime +90 2>/dev/null | while read -r file; do
    local basename=$(basename "$file")
    local mtime=$(stat -c %Y "$file")
    local days_old=$(( ($(date +%s) - mtime) / 86400 ))
    echo "$basename ($days_old days)" >> "$stale_file"
  done || true
  
  if [[ -s "$stale_file" ]]; then
    local stale_count=$(wc -l < "$stale_file")
    local stale_list=$(cat "$stale_file" | sed 's/^/  - /')
    
    add_issue "LOW" "Stale Files" \
      "Found $stale_count file(s) not modified in >90 days:\n$stale_list"
    
    echo "  ⚠️  Found $stale_count stale file(s)"
  else
    echo "  ✅ No stale files"
  fi
  
  rm -f "$stale_file"
}

# Main execution
main() {
  echo "🔍 Markdown Drift Checker"
  echo "========================="
  echo ""
  
  init_report
  
  check_broken_links
  check_conflicts
  check_duplicates
  check_orphans
  check_staleness
  
  echo ""
  
  if [[ $EXIT_CODE -eq 0 ]]; then
    echo "✅ DRIFT_CHECK_OK"
    sed -i "s|^## Summary$|**Status:** ✅ No issues detected\n\n## Summary|" "$REPORT_FILE"
  else
    echo "❌ Issues found - see $REPORT_FILE"
    sed -i "s|^## Summary$|**Status:** ❌ Issues detected\n\n## Summary|" "$REPORT_FILE"
  fi
  
  exit $EXIT_CODE
}

main "$@"
