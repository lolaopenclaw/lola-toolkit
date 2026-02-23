#!/bin/bash
# Populate Google Sheets con datos de consumo de IA

set -e

SHEET_ID="15LMYrWxIlWMqLzLl6EqHk9I9f6B5AZI4X0L-8oY8W08"
WORKSPACE="$HOME/.openclaw/workspace"

echo "📊 Rellenando Sheets: Consumo IA"

# 1. Leer datos de consumo de hoy
if [ ! -f "$WORKSPACE/memory/last-backup.json" ]; then
  echo "❌ Archivo de consumo no encontrado"
  exit 1
fi

# Parsear JSON (simple, sin jq)
DATE=$(date +%Y-%m-%d)
CONSUMPTION=$(cat "$WORKSPACE/memory/last-backup.json" 2>/dev/null | grep -o '"size": "[^"]*"' | head -1 | cut -d'"' -f4)
REQUESTS=$(ps aux | grep "gog\|OpenClaw" | wc -l)

# 2. Usar gog para actualizar Sheets
echo "📝 Añadiendo fila: $DATE | $CONSUMPTION | $REQUESTS requests"

gog sheets append \
  --sheet-id "$SHEET_ID" \
  --tab "Consumo IA" \
  --values "$DATE" "$CONSUMPTION" "$REQUESTS" "$(date +%H:%M:%S)"

echo "✓ Fila añadida"

# 3. Próximo paso: crear gráficas (opcional)
echo ""
echo "✅ Sheets actualizado. Próximo: Garmin health"
