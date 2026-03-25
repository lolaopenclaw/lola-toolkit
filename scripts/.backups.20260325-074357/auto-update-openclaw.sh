#!/bin/bash
# Auto-update OpenClaw - Checks for new stable version and updates if available
# Runs daily at 21:30 Madrid time

set -euo pipefail

# Paths
WORKSPACE="/home/mleon/.openclaw/workspace"
MEMORY_FILE="$WORKSPACE/memory/openclaw-updates.md"
TELEGRAM_CHAT_ID="-1002381931352"  # Manu's default Telegram channel

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Check if there are running subagents (safety check)
check_subagents() {
    local subagents
    subagents=$(/home/mleon/.npm-global/bin/openclaw sessions list --format json 2>/dev/null | jq -r '.[] | select(.type == "subagent") | .id' | wc -l)
    if [ "$subagents" -gt 0 ]; then
        log "${YELLOW}⚠️  Hay $subagents subagents activos. Cancelando update por seguridad.${NC}"
        return 1
    fi
    return 0
}

# Get current version
get_current_version() {
    /home/mleon/.npm-global/bin/openclaw --version 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1
}

# Get latest stable version from npm
get_latest_version() {
    npm view openclaw version 2>/dev/null
}

# Get changelog from GitHub releases
get_changelog() {
    local version="$1"
    local changelog
    
    # Try to fetch from GitHub releases
    changelog=$(curl -s "https://api.github.com/repos/cxllax/openclaw/releases/tags/v${version}" | \
        jq -r '.body // empty' 2>/dev/null)
    
    if [ -z "$changelog" ]; then
        # Fallback: try without 'v' prefix
        changelog=$(curl -s "https://api.github.com/repos/cxllax/openclaw/releases/tags/${version}" | \
            jq -r '.body // empty' 2>/dev/null)
    fi
    
    if [ -z "$changelog" ]; then
        changelog="No changelog available for this version."
    fi
    
    echo "$changelog"
}

# Send Telegram notification (silent)
notify_telegram() {
    local message="$1"
    
    # Use openclaw message tool to send notification
    /home/mleon/.npm-global/bin/openclaw message send \
        --channel telegram \
        --target "$TELEGRAM_CHAT_ID" \
        --message "$message" \
        --silent \
        >/dev/null 2>&1 || log "${YELLOW}⚠️  No se pudo enviar notificación a Telegram${NC}"
}

# Main update logic
main() {
    log "🔍 Checking for OpenClaw updates..."
    
    # Safety check: no subagents running
    if ! check_subagents; then
        exit 0
    fi
    
    # Get versions
    local current_version
    local latest_version
    
    current_version=$(get_current_version)
    latest_version=$(get_latest_version)
    
    log "Current version: $current_version"
    log "Latest version:  $latest_version"
    
    # Compare versions
    if [ "$current_version" = "$latest_version" ]; then
        log "${GREEN}✅ Already on latest version ($current_version)${NC}"
        exit 0
    fi
    
    log "${YELLOW}📦 New version available: $current_version → $latest_version${NC}"
    
    # Get changelog
    local changelog
    changelog=$(get_changelog "$latest_version")
    
    # Save to memory file
    {
        echo "# OpenClaw Update: v$latest_version"
        echo ""
        echo "**Date:** $(date +'%Y-%m-%d %H:%M:%S')"
        echo "**Previous version:** $current_version"
        echo "**New version:** $latest_version"
        echo ""
        echo "## Changelog"
        echo ""
        echo "$changelog"
        echo ""
        echo "---"
        echo ""
    } | cat - "$MEMORY_FILE" > "$MEMORY_FILE.tmp" 2>/dev/null || {
        # Create new file if it doesn't exist
        {
            echo "# OpenClaw Updates Log"
            echo ""
            echo "---"
            echo ""
            echo "# OpenClaw Update: v$latest_version"
            echo ""
            echo "**Date:** $(date +'%Y-%m-%d %H:%M:%S')"
            echo "**Previous version:** $current_version"
            echo "**New version:** $latest_version"
            echo ""
            echo "## Changelog"
            echo ""
            echo "$changelog"
            echo ""
            echo "---"
            echo ""
        } > "$MEMORY_FILE.tmp"
    }
    mv "$MEMORY_FILE.tmp" "$MEMORY_FILE"
    
    log "${GREEN}💾 Changelog guardado en $MEMORY_FILE${NC}"
    
    # Perform update
    log "${YELLOW}⬆️  Actualizando OpenClaw...${NC}"
    
    if npm i -g openclaw@latest; then
        log "${GREEN}✅ Update completado exitosamente${NC}"
        
        # Check if changelog mentions new models
        if echo "$changelog" | grep -iE "(model|gemini|claude|gpt|opus|sonnet|haiku)" >/dev/null; then
            log "🤖 Changelog menciona modelos - ejecutando model-release-checker..."
            if [ -x "$WORKSPACE/scripts/model-release-checker.sh" ]; then
                bash "$WORKSPACE/scripts/model-release-checker.sh" || log "${YELLOW}⚠️  Model release checker falló${NC}"
            else
                log "${YELLOW}⚠️  model-release-checker.sh no encontrado${NC}"
            fi
        fi
        
        # Restart gateway (will auto-restart via systemd or similar)
        log "🔄 Reiniciando gateway..."
        pkill -SIGUSR1 -f "openclaw gateway" || log "${YELLOW}⚠️  No se pudo enviar SIGUSR1 al gateway${NC}"
        
        # Prepare summary for notification
        local summary
        summary=$(echo "$changelog" | head -n 10 | sed 's/^/  /')
        
        # Notify
        notify_telegram "🔄 *OpenClaw actualizado*

📦 $current_version → $latest_version

*Cambios principales:*
$summary

🔗 [Ver changelog completo](https://github.com/cxllax/openclaw/releases/tag/v${latest_version})"
        
        log "${GREEN}✅ Proceso completado${NC}"
    else
        log "${RED}❌ Error durante el update${NC}"
        notify_telegram "❌ *Error al actualizar OpenClaw*

Versión objetivo: $latest_version
Revisa los logs para más detalles."
        exit 1
    fi
}

main "$@"
