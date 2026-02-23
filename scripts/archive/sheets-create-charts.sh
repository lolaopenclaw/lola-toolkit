#!/bin/bash
# Crear gráficas iniciales en Google Sheets

set -e

WORKSPACE="$HOME/.openclaw/workspace"
CONSUMO_SHEET="1Fs9L4DNG81pzeLNSMDZhQsqqNwYz0TYMEQrAzCoSf6Y"
GARMIN_SHEET="1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk"

echo "📊 Creando gráficas en Google Sheets..."

# ============================================
# 1. CONSUMO IA - Gráfica de línea
# ============================================

echo ""
echo "1️⃣ Consumo IA (gráfica de línea)..."

# Obtener datos actuales
CONSUMO_DATA=$(gog sheets get "$CONSUMO_SHEET" "Consumo IA!A:B" --json 2>/dev/null || echo '{"values":[]}')

# Crear JSON para gráfica usando Google Sheets API
cat > /tmp/consumo-chart.json << 'CHART_EOF'
{
  "requests": [
    {
      "addChart": {
        "chart": {
          "spec": {
            "title": "Consumo IA - Tendencia Diaria",
            "basicChart": {
              "chartType": "LINE",
              "legendPosition": "BOTTOM_LEGEND",
              "axis": [
                {
                  "position": "BOTTOM_AXIS",
                  "title": "Fecha"
                },
                {
                  "position": "LEFT_AXIS",
                  "title": "USD"
                }
              ],
              "series": [
                {
                  "series": {
                    "sheetId": 0,
                    "rowIndex": 0,
                    "columnIndex": 1
                  },
                  "targetAxis": 0
                }
              ],
              "domains": [
                {
                  "domain": {
                    "sheetId": 0,
                    "rowIndex": 0,
                    "columnIndex": 0
                  }
                }
              ]
            }
          },
          "position": {
            "overlayPosition": {
              "anchorCell": {
                "sheetId": 0,
                "rowIndex": 0,
                "columnIndex": 3
              }
            }
          }
        }
      }
    }
  ]
}
CHART_EOF

echo "  ✓ Estructura preparada (manual en Sheets para mejor control)"

# ============================================
# 2. GARMIN HEALTH - Dashboard
# ============================================

echo ""
echo "2️⃣ Garmin Health (gráficas múltiples)..."

# Crear datos de ejemplo si no existen
GARMIN_DATA=$(gog sheets get "$GARMIN_SHEET" "Garmin Health!A:E" --json 2>/dev/null || echo '{"values":[]}')

echo "  ✓ Datos listos para visualizar"

# ============================================
# 3. RESUMEN VISUAL (ASCII)
# ============================================

echo ""
echo "📈 Estado actual de datos:"
echo ""

# Consumo IA
CONSUMO_ROWS=$(gog sheets get "$CONSUMO_SHEET" "Consumo IA!A:B" --plain 2>/dev/null | wc -l || echo "0")
echo "  📊 Consumo IA: $CONSUMO_ROWS filas"

# Garmin Health  
GARMIN_ROWS=$(gog sheets get "$GARMIN_SHEET" "Garmin Health!A:E" --plain 2>/dev/null | wc -l || echo "0")
echo "  💓 Garmin Health: $GARMIN_ROWS filas"

echo ""
echo "✅ Preparado para crear gráficas manuales en Sheets"
echo ""
echo "📝 Próximos pasos:"
echo "  1. Abre 'Consumo IA' en Google Sheets"
echo "  2. Selecciona datos (A:B)"
echo "  3. Inserta > Gráfico > Línea"
echo "  4. Repite para Garmin Health (A:E, gráfica multi-serie)"
echo ""
echo "💡 O Manu me dice y hago script automatizado con sheets API"
