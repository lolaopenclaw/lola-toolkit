#!/bin/bash
# Helper script to check and update driving mode state

STATE_FILE="$HOME/.openclaw/workspace/memory/driving-mode-state.json"

# Check if in driving mode
is_driving() {
    if [ -f "$STATE_FILE" ]; then
        mode=$(grep -o '"mode"[^,}]*' "$STATE_FILE" | grep -o '"[^"]*"$' | tr -d '"')
        [ "$mode" = "driving" ]
        return $?
    fi
    return 1  # default: not driving
}

# Set driving mode
set_driving() {
    cat > "$STATE_FILE" << EOF
{
  "mode": "driving",
  "activated_at": "$(date -u +%Y-%m-%dT%H:%M:%S+01:00)",
  "last_reset": null,
  "notes": "Driving mode activated by Manu"
}
EOF
    echo "✅ Driving mode ACTIVATED"
}

# Set home mode
set_home() {
    cat > "$STATE_FILE" << EOF
{
  "mode": "home",
  "last_activated": null,
  "last_reset": "$(date -u +%Y-%m-%dT%H:%M:%S+01:00)",
  "notes": "Reset to home mode"
}
EOF
    echo "✅ Driving mode DEACTIVATED (home)"
}

# Show current status
show_status() {
    if [ -f "$STATE_FILE" ]; then
        echo "📍 Current mode:"
        cat "$STATE_FILE" | grep -o '"mode"[^,}]*'
    else
        echo "❌ State file not found"
    fi
}

# Main
case "${1:-status}" in
    is_driving)
        is_driving
        ;;
    set_driving)
        set_driving
        ;;
    set_home)
        set_home
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: check-driving-mode.sh {status|is_driving|set_driving|set_home}"
        exit 1
        ;;
esac
