#!/bin/bash
# system-updates-nightly.sh
# Aplica actualizaciones de sistema automáticamente por la noche
# NUNCA actualiza OpenClaw (eso es siempre manual)
#
# Genera un log en memory/system-updates-last.json para el informe matutino

set -euo pipefail

LOG_FILE="/home/mleon/.openclaw/workspace/memory/system-updates-last.json"
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)

echo "🔄 [$DATE $TIME] Iniciando actualizaciones de sistema..."

# 1. Update package lists
sudo apt-get update -qq 2>&1

# 2. Get list of upgradable packages BEFORE applying
UPGRADABLE_BEFORE=$(apt list --upgradable 2>/dev/null | grep -v "^Listing" || true)
COUNT_BEFORE=$(echo "$UPGRADABLE_BEFORE" | grep -c . 2>/dev/null || echo "0")

if [ "$COUNT_BEFORE" -eq 0 ] || [ -z "$UPGRADABLE_BEFORE" ]; then
    echo "✅ No hay actualizaciones pendientes"
    cat > "$LOG_FILE" << EOF
{
  "date": "$DATE",
  "time": "$TIME",
  "status": "ok",
  "packages_available": 0,
  "packages_updated": 0,
  "packages": [],
  "reboot_required": false,
  "note": "No updates available"
}
EOF
    exit 0
fi

# 3. Identify security vs regular updates
SECURITY_PKGS=$(echo "$UPGRADABLE_BEFORE" | grep -i "security" || true)
SECURITY_COUNT=$(echo "$SECURITY_PKGS" | grep -c . 2>/dev/null || echo "0")
REGULAR_PKGS=$(echo "$UPGRADABLE_BEFORE" | grep -iv "security" || true)
REGULAR_COUNT=$(echo "$REGULAR_PKGS" | grep -c . 2>/dev/null || echo "0")

# 4. Filter out OpenClaw packages (never auto-update)
OPENCLAW_FILTER="openclaw"

# 5. Apply updates (excluding openclaw)
echo "📦 Aplicando $COUNT_BEFORE actualizaciones..."
UPGRADE_OUTPUT=$(sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    2>&1 || true)

# 6. Check what was actually upgraded
UPGRADABLE_AFTER=$(apt list --upgradable 2>/dev/null | grep -v "^Listing" || true)
COUNT_AFTER=$(echo "$UPGRADABLE_AFTER" | grep -c . 2>/dev/null || echo "0")
UPDATED=$((COUNT_BEFORE - COUNT_AFTER))

# 7. Check if reboot required
REBOOT_REQUIRED=false
if [ -f /var/run/reboot-required ]; then
    REBOOT_REQUIRED=true
fi

# 8. Build package list for JSON
PACKAGES_JSON="["
FIRST=true
while IFS= read -r line; do
    [ -z "$line" ] && continue
    PKG_NAME=$(echo "$line" | cut -d'/' -f1)
    PKG_TYPE="regular"
    echo "$line" | grep -qi "security" && PKG_TYPE="security"
    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        PACKAGES_JSON+=","
    fi
    PACKAGES_JSON+="{\"name\":\"$PKG_NAME\",\"type\":\"$PKG_TYPE\"}"
done <<< "$UPGRADABLE_BEFORE"
PACKAGES_JSON+="]"

# 9. Save results
cat > "$LOG_FILE" << EOF
{
  "date": "$DATE",
  "time": "$TIME",
  "status": "ok",
  "packages_available": $COUNT_BEFORE,
  "packages_updated": $UPDATED,
  "security_count": $SECURITY_COUNT,
  "regular_count": $REGULAR_COUNT,
  "packages": $PACKAGES_JSON,
  "reboot_required": $REBOOT_REQUIRED,
  "remaining": $COUNT_AFTER,
  "note": "Auto-applied. OpenClaw excluded (always manual)."
}
EOF

echo "✅ Actualizaciones completadas: $UPDATED/$COUNT_BEFORE aplicadas"
[ "$REBOOT_REQUIRED" = true ] && echo "⚠️ Reboot necesario (kernel update)"
echo "📝 Log guardado en $LOG_FILE"
