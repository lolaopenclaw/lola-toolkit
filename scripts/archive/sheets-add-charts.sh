#!/bin/bash
# Añadir gráficas automáticas a Google Sheets usando Sheets API

set -e

CONSUMO_SHEET="1Fs9L4DNG81pzeLNSMDZhQsqqNwYz0TYMEQrAzCoSf6Y"
GARMIN_SHEET="1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk"

# Obtener access token de gog
TOKEN=$(gog auth print-access-token 2>/dev/null || echo "")

if [ -z "$TOKEN" ]; then
  echo "❌ No se pudo obtener token OAuth"
  exit 1
fi

echo "📊 Creando gráficas con Google Sheets API..."

# ============================================
# 1. CONSUMO IA - Gráfica de línea
# ============================================

echo ""
echo "1️⃣ Consumo IA (gráfica de línea)..."

CONSUMO_CHART_PAYLOAD=$(cat <<'EOF'
{
  "requests": [
    {
      "addChart": {
        "chart": {
          "spec": {
            "title": "Consumo IA - Últimos 7 días",
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
                "columnIndex": 4
              }
            }
          }
        }
      }
    }
  ]
}
EOF
)

curl -s -X POST \
  "https://sheets.googleapis.com/v4/spreadsheets/$CONSUMO_SHEET:batchUpdate" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$CONSUMO_CHART_PAYLOAD" > /dev/null

echo "  ✓ Gráfica de línea creada"

# ============================================
# 2. GARMIN HEALTH - Gráfica multi-serie
# ============================================

echo ""
echo "2️⃣ Garmin Health (gráfica multi-serie)..."

GARMIN_CHART_PAYLOAD=$(cat <<'EOF'
{
  "requests": [
    {
      "addChart": {
        "chart": {
          "spec": {
            "title": "Garmin Health - Últimos 7 días",
            "basicChart": {
              "chartType": "COMBO",
              "legendPosition": "BOTTOM_LEGEND",
              "axis": [
                {
                  "position": "BOTTOM_AXIS",
                  "title": "Fecha"
                },
                {
                  "position": "LEFT_AXIS",
                  "title": "HR (bpm) / Pasos"
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
                },
                {
                  "series": {
                    "sheetId": 0,
                    "rowIndex": 0,
                    "columnIndex": 2
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
                "sheetId": 1,
                "rowIndex": 0,
                "columnIndex": 5
              }
            }
          }
        }
      }
    }
  ]
}
EOF
)

curl -s -X POST \
  "https://sheets.googleapis.com/v4/spreadsheets/$GARMIN_SHEET:batchUpdate" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$GARMIN_CHART_PAYLOAD" > /dev/null

echo "  ✓ Gráfica multi-serie creada"

echo ""
echo "✅ Gráficas creadas exitosamente"
echo ""
echo "📱 Abre en Google Sheets:"
echo "  • Consumo IA: https://docs.google.com/spreadsheets/d/$CONSUMO_SHEET"
echo "  • Garmin Health: https://docs.google.com/spreadsheets/d/$GARMIN_SHEET"
