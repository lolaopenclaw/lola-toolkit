#!/bin/bash
# apply-all-notification-fixes.sh
# Apply all notification fixes to scripts

set -euo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
BACKUP_DIR="$WORKSPACE/scripts/.backups.$(date +%Y%m%d-%H%M%S)"

echo "🔧 Applying notification fixes to scripts..."
echo ""

# Create backup dir
mkdir -p "$BACKUP_DIR"

# Function to backup a script
backup_script() {
    local script="$1"
    cp "$script" "$BACKUP_DIR/$(basename "$script")"
    echo "  ✅ Backed up: $(basename "$script")"
}

# Function to add quiet hours check function
add_quiet_hours_func() {
    local script="$1"
    local severity="${2:-MEDIUM}"
    
    # Check if already has quiet hours function
    if grep -q "check_quiet_hours" "$script" 2>/dev/null; then
        echo "    (already has quiet hours function)"
        return
    fi
    
    # Add function after shebang
    cat > /tmp/quiet_hours_func.sh << 'FUNC'

# Check quiet hours (00:00-07:00 Madrid)
check_quiet_hours() {
    local SEVERITY=${1:-"MEDIUM"}
    local HOUR=$(TZ=Europe/Madrid date +%H)
    
    if [ "$HOUR" -ge 0 ] && [ "$HOUR" -lt 7 ]; then
        # During quiet hours
        if [ "$SEVERITY" = "CRITICAL" ]; then
            return 0  # Allow
        else
            echo "Quiet hours: suppressing $SEVERITY notification" >&2
            return 1  # Suppress
        fi
    fi
    
    return 0  # Outside quiet hours: allow
}

FUNC
    
    # Insert after #!/bin/bash and set -euo lines
    awk '
    BEGIN { inserted=0 }
    /^#!/ { print; next }
    /^set -[euo]/ { print; if (!inserted) { system("cat /tmp/quiet_hours_func.sh"); inserted=1 }; next }
    { print }
    ' "$script" > "$script.tmp"
    
    mv "$script.tmp" "$script"
    rm /tmp/quiet_hours_func.sh
}

# Function to fix message send calls
fix_message_send() {
    local script="$1"
    local topic="$2"
    
    # Replace openclaw message send patterns
    sed -i.bak \
        -e "s|openclaw message send --channel telegram --target \"\$ALERT_CHANNEL\"|openclaw message send --channel telegram --target \"-1003768820594\" --topic $topic|g" \
        -e "s|openclaw message send --channel telegram --target .\$.*|openclaw message send --channel telegram --target \"-1003768820594\" --topic $topic \\\\|g" \
        -e "s|openclaw message send \"\$MESSAGE\"|openclaw message send --channel telegram --target \"-1003768820594\" --topic $topic --message \"\$MESSAGE\"|g" \
        "$script"
    
    rm -f "$script.bak"
}

# FIX 1: nightly-security-review.sh
echo "1️⃣  Fixing nightly-security-review.sh..."
SCRIPT="$WORKSPACE/scripts/nightly-security-review.sh"
if [ -f "$SCRIPT" ]; then
    backup_script "$SCRIPT"
    
    # Add quiet hours check before alert section
    sed -i '/^# Alert if findings and channel specified/i \
# Check quiet hours (00:00-07:00 Madrid)\
HOUR=$(TZ=Europe/Madrid date +%H)\
CRITICAL_FINDINGS=$(grep -c "\\[CRITICAL\\]" "$REPORT_FILE" 2>/dev/null || echo "0")\
\
if [ "$HOUR" -ge 0 ] && [ "$HOUR" -lt 7 ] && [ "$CRITICAL_FINDINGS" -eq 0 ]; then\
    # During quiet hours: only alert if CRITICAL findings\
    echo "Quiet hours: non-critical findings logged, no notification" >> "$LOG_FILE"\
    exit 0\
fi\
' "$SCRIPT"
    
    # Fix message send
    sed -i 's|openclaw message send --channel telegram --target "$ALERT_CHANNEL"|openclaw message send --channel telegram --target "-1003768820594" --topic 29|g' "$SCRIPT"
    
    echo "  ✅ Fixed"
else
    echo "  ⚠️  Script not found"
fi
echo ""

# FIX 2: log-review.sh
echo "2️⃣  Fixing log-review.sh..."
SCRIPT="$WORKSPACE/scripts/log-review.sh"
if [ -f "$SCRIPT" ]; then
    backup_script "$SCRIPT"
    add_quiet_hours_func "$SCRIPT" "MEDIUM"
    fix_message_send "$SCRIPT" "25"
    echo "  ✅ Fixed"
else
    echo "  ⚠️  Script not found"
fi
echo ""

# FIX 3: rate-limit-alert-sender.sh
echo "3️⃣  Fixing rate-limit-alert-sender.sh..."
SCRIPT="$WORKSPACE/scripts/rate-limit-alert-sender.sh"
if [ -f "$SCRIPT" ]; then
    backup_script "$SCRIPT"
    add_quiet_hours_func "$SCRIPT" "HIGH"
    fix_message_send "$SCRIPT" "25"
    echo "  ✅ Fixed"
else
    echo "  ⚠️  Script not found"
fi
echo ""

# FIX 4: auto-update-openclaw.sh
echo "4️⃣  Fixing auto-update-openclaw.sh..."
SCRIPT="$WORKSPACE/scripts/auto-update-openclaw.sh"
if [ -f "$SCRIPT" ]; then
    backup_script "$SCRIPT"
    fix_message_send "$SCRIPT" "25"
    echo "  ✅ Fixed (topic routing only, runs at 21:30)"
else
    echo "  ⚠️  Script not found"
fi
echo ""

# FIX 5: autoimprove-trigger.sh
echo "5️⃣  Fixing autoimprove-trigger.sh..."
SCRIPT="$WORKSPACE/scripts/autoimprove-trigger.sh"
if [ -f "$SCRIPT" ]; then
    backup_script "$SCRIPT"
    fix_message_send "$SCRIPT" "25"
    echo "  ✅ Fixed (topic routing, already has quiet hours)"
else
    echo "  ⚠️  Script not found"
fi
echo ""

# FIX 6: Archive exa scripts
echo "6️⃣  Archiving exa scripts..."
if [ -f "$WORKSPACE/scripts/exa-cron-report.sh" ]; then
    mkdir -p "$WORKSPACE/scripts/archive/exa"
    mv "$WORKSPACE/scripts/exa-cron-report.sh" "$WORKSPACE/scripts/archive/exa/" 2>/dev/null || true
    echo "  ✅ Archived exa-cron-report.sh"
else
    echo "  ℹ️  Already archived or not found"
fi
echo ""

echo "✅ All fixes applied"
echo ""
echo "📦 Backups saved to: $BACKUP_DIR"
echo ""
echo "⚠️  Gateway restart required for cron changes:"
echo "    openclaw gateway restart"
echo ""

exit 0
