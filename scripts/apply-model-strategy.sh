#!/bin/bash
# apply-model-strategy.sh — Aplicar Multi-Model Strategy
# Fecha: 2026-03-24
# Autor: Lola
# Uso: bash scripts/apply-model-strategy.sh [--phase 1|2|all] [--dry-run]

set -e

PHASE="${1:-all}"
DRY_RUN=false

# Parse args
for arg in "$@"; do
  case $arg in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --phase)
      PHASE="$2"
      shift 2
      ;;
  esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
  echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
  echo -e "${RED}✗${NC} $1"
}

run_cmd() {
  local cmd="$1"
  local desc="$2"
  
  if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] $desc"
    echo "  → $cmd"
    return 0
  fi
  
  log_info "$desc..."
  if eval "$cmd"; then
    log_success "$desc"
  else
    log_error "Failed: $desc"
    return 1
  fi
}

# Backup current config
backup_crons() {
  local backup_file="$HOME/.openclaw/workspace/memory/crons-backup-$(date +%Y-%m-%d-%H%M%S).json"
  log_info "Backing up current cron config..."
  openclaw cron list --json > "$backup_file"
  log_success "Backup saved: $backup_file"
}

# Phase 1: Critical fixes (timeouts + security)
phase_1() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "🚀 PHASE 1: Critical Fixes (Timeouts + Security)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # 1. Increase autoimprove timeouts
  log_info "⏱️  Increasing autoimprove timeouts to 900s..."
  run_cmd "openclaw cron update '🔬 Autoimprove Scripts Agent' --timeout 900" \
    "Update Scripts Agent timeout"
  run_cmd "openclaw cron update '🔬 Autoimprove Skills Agent' --timeout 900" \
    "Update Skills Agent timeout"
  run_cmd "openclaw cron update '🔬 Autoimprove Memory Agent' --timeout 900" \
    "Update Memory Agent timeout"
  
  # 2. Upgrade security healthchecks to Sonnet
  log_info "🔐 Upgrading security healthchecks to Sonnet..."
  run_cmd "openclaw cron update healthcheck:fail2ban-alert --model anthropic/claude-sonnet-4-5" \
    "Upgrade fail2ban to Sonnet"
  run_cmd "openclaw cron update healthcheck:rkhunter-scan-weekly --model anthropic/claude-sonnet-4-5" \
    "Upgrade rkhunter to Sonnet"
  run_cmd "openclaw cron update healthcheck:lynis-scan-weekly --model anthropic/claude-sonnet-4-5" \
    "Upgrade lynis to Sonnet"
  run_cmd "openclaw cron update healthcheck:security-audit-weekly --model anthropic/claude-sonnet-4-5" \
    "Upgrade security-audit to Sonnet"
  
  log_success "Phase 1 completed!"
  log_info "Cost impact: +\$4.20/month"
}

# Phase 2: Optimization (Google Sheets, Garmin, explicit models)
phase_2() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "🎯 PHASE 2: Optimization"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # 3. Upgrade Google Sheets to Sonnet
  log_info "📊 Upgrading Google Sheets and Garmin to Sonnet..."
  run_cmd "openclaw cron update '📊 Populate Google Sheets v2' --model anthropic/claude-sonnet-4-5" \
    "Upgrade Google Sheets to Sonnet"
  run_cmd "openclaw cron update '🏃 Resumen Semanal de Actividades Garmin' --model anthropic/claude-sonnet-4-5" \
    "Upgrade Garmin weekly to Sonnet"
  
  # 4. Make Haiku models explicit
  log_info "🏷️  Making Haiku models explicit..."
  run_cmd "openclaw cron update '🗑️ Backup retention cleanup (lunes)' --model anthropic/claude-haiku-4-5" \
    "Explicit Haiku: Backup cleanup"
  run_cmd "openclaw cron update '📋 Backup validation (weekly)' --model anthropic/claude-haiku-4-5" \
    "Explicit Haiku: Backup validation"
  run_cmd "openclaw cron update '🚗 Driving Mode - Review for Improvements' --model anthropic/claude-haiku-4-5" \
    "Explicit Haiku: Driving Mode Review"
  
  # 5. Upgrade reclamación bus to Sonnet
  log_info "🚌 Upgrading reclamación bus to Sonnet..."
  run_cmd "openclaw cron update 'Seguimiento reclamación bus Logroño (3 meses)' --model anthropic/claude-sonnet-4-5" \
    "Upgrade reclamación bus to Sonnet"
  
  log_success "Phase 2 completed!"
  log_info "Additional cost impact: +\$3.60/month"
}

# Phase 3: Cleanup (remove duplicate)
phase_3() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_info "🧹 PHASE 3: Cleanup"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Check for duplicate config-drift-check
  log_info "Checking for duplicate config-drift-check crons..."
  
  DRIFT_CRONS=$(openclaw cron list --json | jq -r '.jobs[] | select(.name == "config-drift-check") | .id')
  DRIFT_COUNT=$(echo "$DRIFT_CRONS" | grep -c . || true)
  
  if [ "$DRIFT_COUNT" -gt 1 ]; then
    log_warning "Found $DRIFT_COUNT config-drift-check crons (expected 1)"
    
    # Keep the one with full description
    KEEP_ID=$(openclaw cron list --json | jq -r '.jobs[] | select(.name == "config-drift-check" and .description != null) | .id' | head -1)
    
    if [ -n "$KEEP_ID" ]; then
      log_info "Keeping cron with ID: $KEEP_ID"
      
      echo "$DRIFT_CRONS" | while read -r cron_id; do
        if [ "$cron_id" != "$KEEP_ID" ]; then
          log_warning "Removing duplicate: $cron_id"
          run_cmd "openclaw cron delete '$cron_id'" "Delete duplicate cron"
        fi
      done
    else
      log_warning "Could not determine which cron to keep. Manual review required."
      log_info "Run: openclaw cron list --json | jq '.jobs[] | select(.name == \"config-drift-check\")'"
    fi
  else
    log_success "No duplicate config-drift-check found"
  fi
  
  log_success "Phase 3 completed!"
}

# Main execution
main() {
  echo ""
  echo "╔════════════════════════════════════════════════════════╗"
  echo "║     🤖 Multi-Model Strategy Implementation             ║"
  echo "╚════════════════════════════════════════════════════════╝"
  echo ""
  
  if [ "$DRY_RUN" = true ]; then
    log_warning "DRY-RUN MODE: No changes will be applied"
  fi
  
  # Always backup first
  backup_crons
  
  case "$PHASE" in
    1)
      phase_1
      ;;
    2)
      phase_2
      ;;
    3)
      phase_3
      ;;
    all)
      phase_1
      phase_2
      phase_3
      ;;
    *)
      log_error "Invalid phase: $PHASE"
      echo "Usage: $0 [--phase 1|2|3|all] [--dry-run]"
      exit 1
      ;;
  esac
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_success "✅ Implementation complete!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  log_info "Next steps:"
  echo "  1. Verify changes: openclaw cron list"
  echo "  2. Monitor first runs: openclaw cron logs <name>"
  echo "  3. Check cost: openclaw usage --month \$(date +%Y-%m)"
  echo "  4. Review in 1 week: metrics in memory/model-strategy-metrics.md"
  echo ""
  log_info "Documentation:"
  echo "  - Strategy: memory/model-strategy.md"
  echo "  - Changes: memory/model-strategy-changes-2026-03-24.md"
  echo "  - Quick ref: memory/model-selection-guide.md"
  echo ""
}

# Run
main
