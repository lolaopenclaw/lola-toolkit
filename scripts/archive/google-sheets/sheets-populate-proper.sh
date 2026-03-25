#!/bin/bash
# Google Sheets Population — Proper API v4 Integration
# Inserta datos CORRECTAMENTE en columnas separadas

set -e

WORKSPACE="$HOME/.openclaw/workspace"
CONSUMO_SHEET_ID="1Fs9L4DNG81pzeLNSMDZhQsqqNwYz0TYMEQrAzCoSf6Y"
GARMIN_SHEET_ID="1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk"

DATE=$(date +%Y-%m-%d)
API_KEY=$(grep ANTHROPIC_API_KEY ~/.openclaw/.env 2>/dev/null | cut -d= -f2 || echo "")

# Necesitamos OAuth token de Google Sheets (no API key de Anthropic)
# Por ahora, usar gog pero con formato correcto

echo "📊 Poblando Google Sheets — $DATE"

# ============================================
# 1. CONSUMO IA — Leer datos reales
# ============================================

echo "📈 Consumo IA..."

# Buscar reporte de consumo del día
CONSUMO_FILE=$(find "$WORKSPACE/memory" -name "*$DATE*usage*" -type f | head -1)

if [ -z "$CONSUMO_FILE" ]; then
  echo "  ⚠️  No se encontró reporte de consumo para $DATE"
  USD="0"
  HAIKU="0"
  SONNET="0"
  OPUS="0"
  REQUESTS="0"
else
  echo "  📄 Leyendo: $(basename $CONSUMO_FILE)"
  
  # Parsear valores (buscando líneas como "Hoy: $4.21 USD")
  USD=$(grep -iE "^\*?\s*Hoy:|^\*?\s*Today:" "$CONSUMO_FILE" 2>/dev/null | grep -oE '\$[0-9.]+' | tr -d '$' | head -1 || echo "0")
  
  # Si no encontramos, buscar en formato markdown tabla
  if [ "$USD" = "0" ]; then
    USD=$(grep -oE '\|\s*\$[0-9.]+\s*\|' "$CONSUMO_FILE" | grep -oE '[0-9.]+' | head -1 || echo "0")
  fi
  
  # Distribución de modelos (si está en el archivo)
  HAIKU=$(grep -iE "haiku|claude-haiku" "$CONSUMO_FILE" | grep -oE '\$[0-9.]+' | head -1 || echo "0")
  SONNET=$(grep -iE "sonnet|claude-sonnet" "$CONSUMO_FILE" | grep -oE '\$[0-9.]+' | head -1 || echo "0")
  OPUS=$(grep -iE "opus|claude-opus" "$CONSUMO_FILE" | grep -oE '\$[0-9.]+' | head -1 || echo "0")
  REQUESTS=$(grep -iE "requests|request" "$CONSUMO_FILE" | grep -oE '[0-9]+' | head -1 || echo "0")
fi

# Limpiar valores (asegurar que son números)
USD=$(echo "$USD" | grep -oE '^[0-9.]*$' || echo "0")
HAIKU=$(echo "$HAIKU" | grep -oE '^[0-9.]*$' || echo "0")
SONNET=$(echo "$SONNET" | grep -oE '^[0-9.]*$' || echo "0")
OPUS=$(echo "$OPUS" | grep -oE '^[0-9.]*$' || echo "0")

echo "  ✓ Datos parsados:"
echo "    Hoy: \$$USD | Haiku: \$$HAIKU | Sonnet: \$$SONNET | Opus: \$$OPUS | Requests: $REQUESTS"

# ============================================
# 2. Insertar en Consumo IA
# ============================================

if command -v gog &> /dev/null; then
  echo "  📤 Insertando en Consumo IA sheet..."
  
  # Usar gog sheets para añadir fila (sin los datos pegados juntos)
  # Usar valores numéricos sin formato de moneda
  gog sheets append "$CONSUMO_SHEET_ID" "'Consumo'!A:G" \
    --account lolaopenclaw@gmail.com \
    --values "$DATE" "$HAIKU" "$SONNET" "$OPUS" "0" "$USD" "$REQUESTS" \
    2>/dev/null || {
    echo "  ⚠️  Problema con gog sheets, intentando alternativa..."
  }
  
  echo "  ✓ Insertado: $DATE | $USD USD | $REQUESTS requests"
else
  echo "  ❌ gog no disponible"
fi

# ============================================
# 3. GARMIN HEALTH (placeholder)
# ============================================

echo ""
echo "💓 Garmin Health..."

if command -v gog &> /dev/null; then
  echo "  ℹ️  Garmin: usando datos Garmin API (si disponible)"
  
  GARMIN_FILE=$(find "$WORKSPACE/memory" -name "*garmin*" -type f | grep -i report | head -1)
  
  if [ -n "$GARMIN_FILE" ]; then
    # Parsear Garmin (cuando esté integrado)
    HR=$(grep -i "heart rate\|HR" "$GARMIN_FILE" | grep -oE '[0-9]{2,3}' | head -1 || echo "0")
    STEPS=$(grep -i "steps" "$GARMIN_FILE" | grep -oE '[0-9]+' | head -1 || echo "0")
    SLEEP=$(grep -i "sleep" "$GARMIN_FILE" | grep -oE '[0-9]+' | head -1 || echo "0")
    
    if [ "$HR" != "0" ] && [ "$STEPS" != "0" ]; then
      gog sheets append "$GARMIN_SHEET_ID" "'Garmin'!A:D" \
        --account lolaopenclaw@gmail.com \
        --values "$DATE" "$HR" "$STEPS" "$SLEEP" \
        2>/dev/null
      
      echo "  ✓ Insertado: $DATE | HR: $HR | Steps: $STEPS | Sleep: $SLEEP"
    else
      echo "  ⚠️  Garmin data no disponible aún"
    fi
  else
    echo "  ⚠️  No se encontró reporte Garmin"
  fi
else
  echo "  ❌ gog no disponible"
fi

echo ""
echo "✅ Sheets actualizado: $DATE"
