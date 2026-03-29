#!/bin/bash
# Auto-update OpenClaw with automatic rollback
# Runs daily at 21:30 Madrid time
# If update breaks gateway → auto-rollback to previous version + config

set -euo pipefail

WORKSPACE="${WORKSPACE:-$HOME/.openclaw/workspace}"
CONFIG_FILE="$HOME/.openclaw/openclaw.json"
MEMORY_FILE="$WORKSPACE/memory/openclaw-updates.md"
BACKUP_DIR="$HOME/.openclaw/update-backups"
HEALTH_TIMEOUT=45
TOPIC_ID="25"
CHAT_ID="-1003768820594"

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }

notify() {
    openclaw message send --channel telegram --target "$CHAT_ID" --thread-id "$TOPIC_ID" -m "$1" 2>/dev/null || true
}

# Check running subagents
check_subagents() {
    local count
    count=$(openclaw sessions list --format json 2>/dev/null | jq -r '[.[] | select(.type == "subagent")] | length' 2>/dev/null || echo "0")
    if [ "$count" -gt 0 ]; then
        log "⚠️ $count subagents activos — cancelando update"
        return 1
    fi
    return 0
}

get_current_version() {
    openclaw --version 2>&1 | grep -oP '\d+\.\d+\.\d+(-\d+)?' | head -1
}

get_latest_version() {
    npm view openclaw version 2>/dev/null
}

# Health check: verify gateway starts and responds
health_check() {
    local timeout=$1
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        # Check if gateway is accepting connections
        if openclaw gateway status 2>&1 | grep -q "running"; then
            # Also verify config is valid
            if ! openclaw gateway status 2>&1 | grep -qi "invalid\|error"; then
                log "✅ Gateway healthy after ${elapsed}s"
                return 0
            fi
        fi
        sleep 3
        elapsed=$((elapsed + 3))
    done
    
    log "❌ Gateway unhealthy after ${timeout}s"
    return 1
}

# Rollback to previous version + config
rollback() {
    local prev_version="$1"
    local config_backup="$2"
    
    log "🔙 ROLLBACK: Restaurando v$prev_version..."
    
    # 1. Restore config
    if [ -f "$config_backup" ]; then
        cp "$config_backup" "$CONFIG_FILE"
        log "✅ Config restaurada desde backup"
    fi
    
    # 2. Rollback npm package
    log "📦 Instalando versión anterior: openclaw@$prev_version"
    npm i -g "openclaw@$prev_version" 2>&1 || {
        log "❌ No se pudo instalar versión anterior"
        notify "🚨 AUTO-UPDATE ROLLBACK FALLIDO

No se pudo restaurar v$prev_version.
Intervención manual necesaria:
\`npm i -g openclaw@$prev_version\`
\`openclaw doctor --fix\`"
        return 1
    }
    
    # 3. Restart gateway
    log "🔄 Reiniciando gateway con versión anterior..."
    systemctl --user restart openclaw-gateway 2>/dev/null || openclaw gateway restart 2>/dev/null || true
    
    sleep 5
    
    # 4. Verify rollback worked
    if health_check 30; then
        local restored_ver
        restored_ver=$(get_current_version)
        log "✅ ROLLBACK EXITOSO: v$restored_ver funcionando"
        notify "🔙 AUTO-UPDATE ROLLBACK

La actualización a la nueva versión falló (config incompatible).
Se ha restaurado automáticamente v$restored_ver.

La próxima versión puede arreglar la incompatibilidad.
No se requiere acción manual."
        return 0
    else
        log "❌ ROLLBACK FALLIDO: gateway sigue sin responder"
        notify "🚨 AUTO-UPDATE ROLLBACK FALLIDO

Ni la nueva versión ni v$prev_version funcionan.
Intervención manual necesaria:
\`openclaw doctor --fix\`
\`openclaw gateway restart\`"
        return 1
    fi
}

main() {
    log "🔍 Checking for OpenClaw updates..."
    
    if ! check_subagents; then
        exit 0
    fi
    
    local current_version latest_version
    current_version=$(get_current_version)
    latest_version=$(get_latest_version)
    
    log "Current: $current_version | Latest: $latest_version"
    
    if [ "$current_version" = "$latest_version" ]; then
        log "✅ Already on latest ($current_version)"
        exit 0
    fi
    
    log "📦 Update available: $current_version → $latest_version"
    
    # === PRE-FLIGHT: BACKUP EVERYTHING ===
    mkdir -p "$BACKUP_DIR"
    local config_backup="$BACKUP_DIR/openclaw.json.pre-$latest_version"
    cp "$CONFIG_FILE" "$config_backup"
    log "💾 Config backed up to $config_backup"
    
    # Save current version for rollback
    echo "$current_version" > "$BACKUP_DIR/previous-version.txt"
    
    # === STOP GATEWAY GRACEFULLY ===
    log "⏸️ Stopping gateway before update..."
    systemctl --user stop openclaw-gateway 2>/dev/null || true
    sleep 2
    
    # === PERFORM UPDATE ===
    log "⬆️ Installing openclaw@$latest_version..."
    if ! npm i -g "openclaw@$latest_version" 2>&1; then
        log "❌ npm install failed — aborting"
        # Restart gateway with current version
        systemctl --user start openclaw-gateway 2>/dev/null || true
        notify "❌ Auto-update falló: npm install error para v$latest_version"
        exit 1
    fi
    
    log "✅ npm install OK"
    
    # === TRY DOCTOR FIRST (fix config if needed) ===
    log "🩺 Running doctor to fix potential config issues..."
    openclaw doctor --fix --non-interactive 2>&1 | tail -5 || true
    
    # === START GATEWAY ===
    log "🔄 Starting gateway with new version..."
    systemctl --user start openclaw-gateway 2>/dev/null || true
    
    # === HEALTH CHECK ===
    log "🏥 Health check (${HEALTH_TIMEOUT}s timeout)..."
    if health_check "$HEALTH_TIMEOUT"; then
        local new_version
        new_version=$(get_current_version)
        log "✅ Update successful: $current_version → $new_version"
        
        # Get changelog
        local changelog
        changelog=$(curl -s "https://api.github.com/repos/openclaw/openclaw/releases/tags/v${latest_version}" | jq -r '.body // "No changelog"' 2>/dev/null | head -15)
        
        # Save to memory
        {
            echo ""
            echo "## v$latest_version ($(date +'%Y-%m-%d %H:%M'))"
            echo "- From: $current_version"
            echo "- Status: ✅ OK (auto-update with health check)"
            echo "- Changes: $changelog"
            echo ""
        } >> "$MEMORY_FILE" 2>/dev/null || true
        
        notify "🔄 OpenClaw actualizado ✅

$current_version → $new_version

Gateway healthy, todo operativo."
    else
        # === HEALTH CHECK FAILED → ROLLBACK ===
        log "❌ Health check FAILED — initiating rollback"
        
        # Check if it's a config issue
        local gateway_error
        gateway_error=$(journalctl --user -u openclaw-gateway --since "2 min ago" --no-pager 2>/dev/null | grep -i "config invalid\|unrecognized\|error" | tail -3)
        log "Gateway errors: $gateway_error"
        
        # Try doctor --fix first
        log "🩺 Trying doctor --fix..."
        if openclaw doctor --fix --non-interactive 2>&1 | grep -q "Doctor complete"; then
            systemctl --user restart openclaw-gateway 2>/dev/null || true
            sleep 5
            
            if health_check 30; then
                local fixed_version
                fixed_version=$(get_current_version)
                log "✅ Doctor fixed the issue: v$fixed_version running"
                notify "🔄 OpenClaw actualizado ✅ (con doctor --fix)

$current_version → $fixed_version

Doctor arregló incompatibilidades de config automáticamente."
                exit 0
            fi
        fi
        
        # Doctor didn't fix it → full rollback
        log "❌ Doctor didn't fix it — full rollback"
        rollback "$current_version" "$config_backup"
        
        # Save failed update to memory
        {
            echo ""
            echo "## v$latest_version ($(date +'%Y-%m-%d %H:%M'))"
            echo "- From: $current_version"
            echo "- Status: ❌ ROLLBACK (config incompatible)"
            echo "- Error: $gateway_error"
            echo ""
        } >> "$MEMORY_FILE" 2>/dev/null || true
        
        exit 1
    fi
}

main "$@"
