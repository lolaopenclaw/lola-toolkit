#!/bin/bash
# Crear gráficas en Google Sheets desde laptop (usuario autenticado)

set -e

CONSUMO_SHEET="1Fs9L4DNG81pzeLNSMDZhQsqqNwYz0TYMEQrAzCoSf6Y"
GARMIN_SHEET="1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk"

echo "📊 Creando gráficas en Google Sheets..."

# ============================================
# OPCIÓN 1: Usar gog (ya autenticado en laptop)
# ============================================

echo ""
echo "✓ Usando gog (ya autenticado en tu laptop)"

# Consumo IA - Verificar datos
echo ""
echo "1️⃣ Consumo IA..."
CONSUMO_DATA=$(gog sheets get "$CONSUMO_SHEET" "Consumo IA!A:B" --plain 2>/dev/null)
echo "$CONSUMO_DATA" | head -5
echo "   ✓ Datos presentes ($(echo "$CONSUMO_DATA" | wc -l) filas)"

# Garmin Health - Verificar datos  
echo ""
echo "2️⃣ Garmin Health..."
GARMIN_DATA=$(gog sheets get "$GARMIN_SHEET" "Garmin Health!A:E" --plain 2>/dev/null)
echo "$GARMIN_DATA" | head -5
echo "   ✓ Datos presentes ($(echo "$GARMIN_DATA" | wc -l) filas)"

echo ""
echo "✅ Datos confirmados. Ahora necesitas crear las gráficas manualmente:"
echo ""
echo "   CONSUMO IA:"
echo "   1. Abre: https://docs.google.com/spreadsheets/d/$CONSUMO_SHEET"
echo "   2. Selecciona A:B (Fecha y USD)"
echo "   3. Insertar > Gráfico > Línea"
echo "   4. Título: 'Consumo IA - Últimos 7 días'"
echo "   5. Insertar"
echo ""
echo "   GARMIN HEALTH:"
echo "   1. Abre: https://docs.google.com/spreadsheets/d/$GARMIN_SHEET"
echo "   2. Selecciona A:D (Fecha, HR, Pasos, Sueño)"
echo "   3. Insertar > Gráfico > Combo"
echo "   4. Eje izquierdo: HR y Pasos"
echo "   5. Eje derecho: Sueño"
echo "   6. Título: 'Garmin Health - Últimos 7 días'"
echo "   7. Insertar"
echo ""
echo "💡 Alternativa: Ejecuta esto desde la laptop:"
echo "   python3 ~/.openclaw/workspace/scripts/sheets-create-charts-oauth.py"
