#!/bin/bash
set -euo pipefail

# Unified Autoimprove Script
# Consolidates Scripts, Skills, and Memory optimization agents into one script
# Usage: bash scripts/autoimprove-unified.sh [--target scripts|skills|memory|all] [--dry-run] [--max-iterations 15]

# ============================================================================
# Configuration
# ============================================================================

WORKSPACE="${HOME}/.openclaw/workspace"
LOG_DIR="${WORKSPACE}/memory"
EXPERIMENT_LOG="${WORKSPACE}/autoimprove/experiment-log.jsonl"
DATE=$(date +%Y-%m-%d)
LOG_FILE="${LOG_DIR}/autoimprove-log-${DATE}.md"

# Default values
TARGET="all"
DRY_RUN=false
MAX_ITERATIONS=15

# ============================================================================
# Argument Parsing
# ============================================================================

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --max-iterations)
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --target <scripts|skills|memory|all>  Target area to optimize (default: all)"
      echo "  --dry-run                              Show what would be done without applying changes"
      echo "  --max-iterations <N>                   Max iterations per target (default: 15)"
      echo "  --help, -h                             Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Use --help for usage information" >&2
      exit 1
      ;;
  esac
done

# Validate target
case "$TARGET" in
  scripts|skills|memory|all) ;;
  *)
    echo "Error: Invalid target '$TARGET'. Must be one of: scripts, skills, memory, all" >&2
    exit 1
    ;;
esac

# ============================================================================
# Helper Functions
# ============================================================================

log_message() {
  local level="$1"
  shift
  echo "[$(date +%H:%M:%S)] [$level] $*" | tee -a "$LOG_FILE"
}

log_experiment() {
  local file="$1"
  local description="$2"
  local score_before="$3"
  local score_after="$4"
  local result="$5"  # kept|discarded
  
  if [[ ! -d "$(dirname "$EXPERIMENT_LOG")" ]]; then
    mkdir -p "$(dirname "$EXPERIMENT_LOG")"
  fi
  
  local entry
  entry=$(jq -n \
    --arg date "$DATE" \
    --arg file "$file" \
    --arg desc "$description" \
    --arg before "$score_before" \
    --arg after "$score_after" \
    --arg result "$result" \
    '{date: $date, file: $file, description: $desc, score_before: $before, score_after: $after, result: $result}')
  
  echo "$entry" >> "$EXPERIMENT_LOG"
  log_message "INFO" "Experiment logged: $file - $description - $result"
}

# ============================================================================
# Target: SCRIPTS
# ============================================================================

run_scripts_optimization() {
  log_message "INFO" "=== Starting Scripts Optimization ==="
  
  local program_dir="${WORKSPACE}/autoimprove/programs/backup-speed"
  local eval_script="${program_dir}/eval.sh"
  local target_script="${WORKSPACE}/scripts/backup-memory.sh"
  
  # Check if eval script exists
  if [[ ! -f "$eval_script" ]]; then
    log_message "WARN" "Eval script not found: $eval_script (skipping scripts optimization)"
    return 0
  fi
  
  # Baseline evaluation
  log_message "INFO" "Running baseline evaluation for scripts..."
  local baseline_score
  if baseline_score=$(bash "$eval_script" 2>&1 | tail -1 | grep -oE '[0-9]+'); then
    log_message "INFO" "Baseline score: $baseline_score"
    
    if [[ "$baseline_score" -lt 200 ]]; then
      log_message "INFO" "Scripts already optimized (score < 200), skipping"
      echo "HEARTBEAT_OK — Scripts already optimized (score: $baseline_score)"
      return 0
    fi
  else
    log_message "ERROR" "Failed to get baseline score"
    return 1
  fi
  
  # In dry-run mode, just report what would be done
  if [[ "$DRY_RUN" == true ]]; then
    log_message "INFO" "[DRY-RUN] Would optimize backup-memory.sh (current score: $baseline_score)"
    log_message "INFO" "[DRY-RUN] Would run up to $MAX_ITERATIONS experiments"
    return 0
  fi
  
  # Actual optimization would happen here
  # For now, we just report that the framework is ready
  log_message "INFO" "Scripts optimization: baseline score $baseline_score, ready for experiments"
  echo "🔧 Scripts Optimization Report — $DATE"
  echo ""
  echo "Target: backup-memory.sh"
  echo "Baseline score: $baseline_score"
  echo "Status: Framework ready (experiment logic to be implemented by agent)"
}

# ============================================================================
# Target: SKILLS
# ============================================================================

run_skills_optimization() {
  log_message "INFO" "=== Starting Skills Optimization ==="
  
  local heartbeat_file="${WORKSPACE}/HEARTBEAT.md"
  local agents_file="${WORKSPACE}/AGENTS.md"
  
  # Check if files exist
  if [[ ! -f "$heartbeat_file" ]]; then
    log_message "WARN" "HEARTBEAT.md not found (skipping skills optimization)"
    return 0
  fi
  
  # Calculate baseline token count (approximate: words * 0.75)
  log_message "INFO" "Calculating baseline token counts..."
  local heartbeat_tokens
  local agents_tokens
  
  if [[ -f "$heartbeat_file" ]]; then
    heartbeat_tokens=$(wc -w < "$heartbeat_file" | awk '{print int($1 * 0.75)}')
    log_message "INFO" "HEARTBEAT.md: ~$heartbeat_tokens tokens"
  else
    heartbeat_tokens=0
  fi
  
  if [[ -f "$agents_file" ]]; then
    agents_tokens=$(wc -w < "$agents_file" | awk '{print int($1 * 0.75)}')
    log_message "INFO" "AGENTS.md: ~$agents_tokens tokens"
  else
    agents_tokens=0
  fi
  
  # Check if already optimized
  if [[ "$heartbeat_tokens" -lt 150 ]] && [[ "$agents_tokens" -lt 150 ]]; then
    log_message "INFO" "Skills already optimized (both < 150 tokens), skipping"
    echo "HEARTBEAT_OK — Skills already optimized"
    return 0
  fi
  
  # In dry-run mode, just report what would be done
  if [[ "$DRY_RUN" == true ]]; then
    log_message "INFO" "[DRY-RUN] Would optimize HEARTBEAT.md (current: ~$heartbeat_tokens tokens)"
    log_message "INFO" "[DRY-RUN] Would optimize AGENTS.md (current: ~$agents_tokens tokens)"
    log_message "INFO" "[DRY-RUN] Would run up to $MAX_ITERATIONS experiments"
    return 0
  fi
  
  # Actual optimization would happen here
  log_message "INFO" "Skills optimization: HEARTBEAT=$heartbeat_tokens tokens, AGENTS=$agents_tokens tokens"
  echo "📝 Skills Optimization Report — $DATE"
  echo ""
  echo "Targets: HEARTBEAT.md, AGENTS.md"
  echo "Baseline scores:"
  echo "  - HEARTBEAT.md: ~$heartbeat_tokens tokens"
  echo "  - AGENTS.md: ~$agents_tokens tokens"
  echo "Status: Framework ready (experiment logic to be implemented by agent)"
}

# ============================================================================
# Target: MEMORY
# ============================================================================

run_memory_optimization() {
  log_message "INFO" "=== Starting Memory Optimization ==="
  
  local memory_file="${WORKSPACE}/MEMORY.md"
  
  # Check if file exists
  if [[ ! -f "$memory_file" ]]; then
    log_message "WARN" "MEMORY.md not found (skipping memory optimization)"
    return 0
  fi
  
  # Calculate baseline token count
  log_message "INFO" "Calculating baseline token count for MEMORY.md..."
  local memory_tokens
  memory_tokens=$(wc -w < "$memory_file" | awk '{print int($1 * 0.75)}')
  log_message "INFO" "MEMORY.md: ~$memory_tokens tokens"
  
  # Check if already optimized
  if [[ "$memory_tokens" -lt 500 ]]; then
    log_message "INFO" "Memory already optimized (< 500 tokens), checking for real duplication..."
    # Could add more sophisticated duplication detection here
  fi
  
  # Check for orphaned references
  log_message "INFO" "Checking for orphaned memory references..."
  local orphans
  orphans=$(grep -oE 'memory/[a-zA-Z0-9_-]+\.md' "$memory_file" | sort -u | while read -r ref; do
    if [[ ! -f "${WORKSPACE}/${ref}" ]]; then
      echo "  - ORPHAN: $ref"
    fi
  done)
  
  if [[ -n "$orphans" ]]; then
    log_message "WARN" "Found orphaned references:"
    echo "$orphans" | tee -a "$LOG_FILE"
  else
    log_message "INFO" "No orphaned references found"
  fi
  
  # Count entries
  local entry_count
  entry_count=$(grep -E '^\s*-\s+\*\*' "$memory_file" 2>/dev/null | wc -l | tr -d '[:space:]')
  log_message "INFO" "MEMORY.md has $entry_count entries"
  
  if [[ "$entry_count" -lt 30 ]]; then
    log_message "WARN" "Coverage might be low: only $entry_count entries"
  fi
  
  # In dry-run mode, just report what would be done
  if [[ "$DRY_RUN" == true ]]; then
    log_message "INFO" "[DRY-RUN] Would optimize MEMORY.md (current: ~$memory_tokens tokens, $entry_count entries)"
    log_message "INFO" "[DRY-RUN] Would consolidate duplicates and archive old references"
    log_message "INFO" "[DRY-RUN] Would run up to $MAX_ITERATIONS experiments"
    return 0
  fi
  
  # Actual optimization would happen here
  log_message "INFO" "Memory optimization: ~$memory_tokens tokens, $entry_count entries"
  echo "🧠 Memory Optimization Report — $DATE"
  echo ""
  echo "Target: MEMORY.md"
  echo "Baseline: ~$memory_tokens tokens, $entry_count entries"
  if [[ -n "$orphans" ]]; then
    echo "Orphaned references found (see log)"
  fi
  echo "Status: Framework ready (experiment logic to be implemented by agent)"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
  log_message "INFO" "Starting unified autoimprove - target: $TARGET, dry-run: $DRY_RUN, max-iterations: $MAX_ITERATIONS"
  
  # Initialize log file
  {
    echo "# Autoimprove Log — $DATE"
    echo ""
    echo "**Target:** $TARGET"
    echo "**Dry Run:** $DRY_RUN"
    echo "**Max Iterations:** $MAX_ITERATIONS"
    echo "**Started:** $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "---"
    echo ""
  } > "$LOG_FILE"
  
  local exit_code=0
  
  # Run optimization based on target
  case "$TARGET" in
    scripts)
      run_scripts_optimization || exit_code=$?
      ;;
    skills)
      run_skills_optimization || exit_code=$?
      ;;
    memory)
      run_memory_optimization || exit_code=$?
      ;;
    all)
      # Run all three in sequence: scripts → skills → memory
      log_message "INFO" "Running all targets in sequence: scripts → skills → memory"
      run_scripts_optimization || exit_code=$?
      echo ""
      run_skills_optimization || exit_code=$?
      echo ""
      run_memory_optimization || exit_code=$?
      ;;
  esac
  
  # Finalize log
  {
    echo ""
    echo "---"
    echo ""
    echo "**Completed:** $(date '+%Y-%m-%d %H:%M:%S')"
    echo "**Exit Code:** $exit_code"
  } >> "$LOG_FILE"
  
  log_message "INFO" "Autoimprove completed (exit code: $exit_code)"
  log_message "INFO" "Log saved to: $LOG_FILE"
  
  return $exit_code
}

# Run main function
main "$@"
