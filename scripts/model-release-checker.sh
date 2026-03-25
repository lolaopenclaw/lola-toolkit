#!/usr/bin/env bash
# model-release-checker.sh - Detect new AI models and trigger best practices update
# Part of OpenClaw workspace automation

set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
MEMORY_DIR="$WORKSPACE/memory/best-practices"
MODELS_FILE="$MEMORY_DIR/known-models.json"
SCRIPT_DIR="$WORKSPACE/scripts"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Ensure directory exists
mkdir -p "$MEMORY_DIR"

# Function to get current available models from OpenClaw
get_current_models() {
    # Try to get models from OpenClaw CLI
    if command -v openclaw &> /dev/null; then
        # This would ideally query OpenClaw's model registry
        # For now, we'll create a simple JSON structure
        openclaw models list --json 2>/dev/null || echo '{"models": [], "timestamp": "'$(date -Iseconds)'", "source": "fallback"}'
    else
        echo '{"models": [], "timestamp": "'$(date -Iseconds)'", "source": "manual"}'
    fi
}

# Function to extract model names from JSON
extract_model_names() {
    local json="$1"
    echo "$json" | jq -r '.models[]? | select(.id != null) | .id' 2>/dev/null | sort -u || echo ""
}

# Initialize models file if it doesn't exist
initialize_models_file() {
    log "Initializing models tracking file..."
    
    local current_models=$(get_current_models)
    local timestamp=$(date -Iseconds)
    
    cat > "$MODELS_FILE" << EOF
{
  "last_check": "$timestamp",
  "models": $(echo "$current_models" | jq -c '.models // []'),
  "history": [
    {
      "date": "$timestamp",
      "action": "initial",
      "models_count": $(echo "$current_models" | jq '.models // [] | length')
    }
  ]
}
EOF
    
    log "Models file initialized: $MODELS_FILE"
}

# Main check function
check_for_new_models() {
    log "Checking for new models..."
    
    # Get current models
    local current_models=$(get_current_models)
    local current_names=$(extract_model_names "$current_models")
    
    # Load previous models
    if [[ ! -f "$MODELS_FILE" ]]; then
        initialize_models_file
        warn "First run - baseline created, no comparison available"
        return 0
    fi
    
    local previous_names=$(jq -r '.models[]? | select(.id != null) | .id' "$MODELS_FILE" 2>/dev/null | sort -u || echo "")
    
    # Find new models (in current but not in previous)
    local new_models=$(comm -13 <(echo "$previous_names") <(echo "$current_names"))
    
    if [[ -z "$new_models" ]]; then
        log "No new models detected"
        
        # Update last check timestamp
        local temp_file=$(mktemp)
        jq --arg timestamp "$(date -Iseconds)" '.last_check = $timestamp' "$MODELS_FILE" > "$temp_file"
        mv "$temp_file" "$MODELS_FILE"
        
        return 0
    fi
    
    # New models found!
    warn "🆕 NEW MODELS DETECTED:"
    echo "$new_models" | while IFS= read -r model; do
        [[ -n "$model" ]] && warn "  - $model"
    done
    
    # Update models file with new models and history entry
    local temp_file=$(mktemp)
    local timestamp=$(date -Iseconds)
    local new_models_json=$(echo "$new_models" | jq -R . | jq -s .)
    
    jq --arg timestamp "$timestamp" \
       --argjson new_models "$new_models_json" \
       --argjson current "$(echo "$current_models" | jq '.models // []')" \
       '.last_check = $timestamp | 
        .models = $current |
        .history += [{
          "date": $timestamp,
          "action": "new_models_detected",
          "new_models": $new_models,
          "models_count": ($current | length)
        }]' "$MODELS_FILE" > "$temp_file"
    
    mv "$temp_file" "$MODELS_FILE"
    
    # Trigger best practices checker
    log "Triggering best practices update due to new models..."
    if [[ -x "$SCRIPT_DIR/best-practices-checker.sh" ]]; then
        "$SCRIPT_DIR/best-practices-checker.sh"
    else
        error "best-practices-checker.sh not found or not executable"
        return 1
    fi
    
    return 1  # Return 1 to indicate new models found
}

# Manual trigger option
if [[ "${1:-}" == "--force" ]]; then
    log "Force mode: Running best practices checker regardless of model changes"
    exec "$SCRIPT_DIR/best-practices-checker.sh"
fi

# Run check
check_for_new_models
