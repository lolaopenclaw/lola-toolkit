#!/bin/bash
# Populate Google Sheets diariamente con datos de consumo y Garmin

set -e

WORKSPACE="$HOME/.openclaw/workspace"
CONSUMO_SHEET="1Fs9L4DNG81pzeLNSMDZhQsqqNwYz0TYMEQrAzCoSf6Y"
GARMIN_SHEET="1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk"

DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M:%S)

echo "📊 Rellenando Sheets: $DATE $TIME"

# ============================================
# 1. CONSUMO IA
# ============================================

# Leer consumo de hoy (si existe)
if [ -f "$WORKSPACE/memory/$(date +%Y-%m-%d)-usage-report.md" ]; then
  CONSUMO=$(grep "💰\|Hoy:" "$WORKSPACE/memory/$(date +%Y-%m-%d)-usage-report.md" | head -1 | grep -o '\$[0-9.]*' | tr -d '$' || echo "0")
else
  CONSUMO="0"
fi

# Contar requests (aproximado)
REQUESTS=$(grep -c "anthropic\|google" "$WORKSPACE/memory/DAILY/HOT/$(date +%Y-%m-%d).md" 2>/dev/null || echo "0")

echo "  📈 Consumo IA: \$$CONSUMO | $REQUESTS requests"

# Append a Sheets
gog sheets append "$CONSUMO_SHEET" "Consumo IA!A:D" "$DATE" "$CONSUMO" "$REQUESTS" "$TIME" --plain 2>/dev/null && echo "    ✓ Fila añadida"

# ============================================
# 2. GARMIN HEALTH
# ============================================

# Leer datos Garmin de ayer
if [ -f "$WORKSPACE/scripts/garmin-health-report.sh" ]; then
  echo "  💓 Garmin Health..."
  
  # Ejecutar reporte Garmin
  YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
  HR=$(bash "$WORKSPACE/scripts/garmin-health-report.sh" --yesterday 2>/dev/null | grep -i "heart rate\|promedio" | head -1 | grep -o '[0-9]*' | head -1 || echo "0")
  STEPS=$(bash "$WORKSPACE/scripts/garmin-health-report.sh" --yesterday 2>/dev/null | grep -i "pasos\|steps" | head -1 | grep -o '[0-9]*' | head -1 || echo "0")
  SLEEP=$(bash "$WORKSPACE/scripts/garmin-health-report.sh" --yesterday 2>/dev/null | grep -i "sleep\|sueño" | head -1 | grep -o '[0-9.]*' | head -1 || echo "0")
  
  echo "    HR: $HR | Steps: $STEPS | Sleep: ${SLEEP}h"
  
  # Append a Sheets
  gog sheets append "$GARMIN_SHEET" "Garmin Health!A:E" "$YESTERDAY" "$HR" "$STEPS" "$SLEEP" "$TIME" --plain 2>/dev/null && echo "    ✓ Fila añadida"
else
  echo "    ⚠️  Script Garmin no disponible"
fi

echo ""
echo "✅ Sheets actualizado: $DATE"
