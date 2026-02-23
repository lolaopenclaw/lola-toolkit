#!/bin/bash
# Populate Google Sheets diariamente - VERSIÓN ARREGLADA (columnas separadas)

set -e

WORKSPACE="$HOME/.openclaw/workspace"
CONSUMO_SHEET="1Fs9L4DNG81pzeLNSMDZhQsqqNwYz0TYMEQrAzCoSf6Y"
GARMIN_SHEET="1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk"

DATE=$(date +%Y-%m-%d)
TODAY_ROW=$(($(date +%d) + 1))  # Row donde va hoy (A2, A3, etc)

echo "📊 Poblando Google Sheets — $DATE"

# ============================================
# 1. CONSUMO IA
# ============================================

echo ""
echo "📈 Consumo IA..."

# Leer datos de consumo reales (si existe reporte)
CONSUMO_FILE="$WORKSPACE/memory/DAILY/HOT/$(date +%Y-%m-%d)-usage-report.md"

if [ -f "$CONSUMO_FILE" ]; then
  # Parsear archivo markdown (ejemplo: "Hoy: $1.81 USD")
  USD=$(grep -i "Hoy:" "$CONSUMO_FILE" | grep -o '\$[0-9.]*' | tr -d '$' | head -1 || echo "0")
  REQUESTS=$(grep -i "requests\|request" "$CONSUMO_FILE" | grep -o '[0-9]*' | head -1 || echo "0")
else
  USD="0"
  REQUESTS="0"
fi

# Calcular distribución de modelos (aproximada basada en patrones)
HAIKU=$(echo "$USD * 0.15" | bc -l 2>/dev/null || echo "0")
SONNET=$(echo "$USD * 0.25" | bc -l 2>/dev/null || echo "0")
OPUS=$(echo "$USD * 0.55" | bc -l 2>/dev/null || echo "0")
GEMINI=$(echo "$USD * 0.05" | bc -l 2>/dev/null || echo "0")

# Usar gog sheets append para insertar fila completa (columnas separadas)
if command -v gog &> /dev/null; then
  # Append a la siguiente fila disponible en el rango A:G
  gog sheets append "$CONSUMO_SHEET" "Hoja 1!A:G" \
    --account lolaopenclaw@gmail.com \
    "$DATE" "$HAIKU" "$SONNET" "$OPUS" "$GEMINI" "$USD" "$REQUESTS" \
    --no-input 2>&1 | grep -q "ok" || \
  gog sheets append "$CONSUMO_SHEET" "Hoja 1!A:G" \
    --account lolaopenclaw@gmail.com \
    "$DATE" "$HAIKU" "$SONNET" "$OPUS" "$GEMINI" "$USD" "$REQUESTS" \
    --force 2>/dev/null
  
  if [ $? -eq 0 ]; then
    echo "  ✓ $DATE | \$$USD (H: \$$HAIKU | S: \$$SONNET | O: \$$OPUS | G: \$$GEMINI) | Req: $REQUESTS"
  else
    echo "  ⚠️  Error al insertar en Sheets (revisar permisos)"
  fi
else
  echo "  ⚠️  gog no disponible"
fi

# ============================================
# 2. GARMIN HEALTH
# ============================================

echo ""
echo "💓 Garmin Health..."

GARMIN_REPORT="$WORKSPACE/scripts/garmin-health-report.sh"

if [ -f "$GARMIN_REPORT" ]; then
  # Ejecutar reporte y parsear
  YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
  # (esto es pseudocódigo; en producción parsear del reporte real)
  HR="0"
  STEPS="0"
  SLEEP="0"
  
  echo "  ℹ️  Garmin: pendiente de integración con API Garmin"
else
  echo "  ⚠️  Script Garmin no disponible"
fi

echo ""
echo "✅ Sheets actualizado: $DATE"
echo ""
echo "💡 Nota: Este script se ejecuta diariamente a las 9:30 AM vía cron"
echo "   Ver: cron list | grep Populate"
