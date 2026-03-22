#!/bin/bash
# Surf Conditions Fetcher — Agent-First Surfing Coach
# Fetches wave/wind data from Open-Meteo Marine API (no API key needed)
# Saves to memory/surf/conditions-YYYY-MM-DD.md in human-readable format

set -euo pipefail

# Configuration
WORKSPACE="/home/mleon/.openclaw/workspace"
OUTPUT_DIR="$WORKSPACE/memory/surf"
DATE=$(date +%Y-%m-%d)
OUTPUT_FILE="$OUTPUT_DIR/conditions-$DATE.md"

# Surf spot coordinates
# Hendaya (spot principal de Manu): 43.37, -1.77
# Santander area: 43.4, -3.8
# San Sebastián area: 43.3, -2.0
LAT_HENDAYA=43.37
LON_HENDAYA=-1.77
LAT_SANTANDER=43.4
LON_SANTANDER=-3.8
LAT_SANSEB=43.3
LON_SANSEB=-2.0

# Open-Meteo Marine Weather API
# Docs: https://open-meteo.com/en/docs/marine-weather-api
API_BASE="https://marine-api.open-meteo.com/v1/marine"

# Fetch function
fetch_conditions() {
    local lat=$1
    local lon=$2
    local location_name=$3
    
    # Current + 7-day forecast
    # Marine vars: wave_height, wave_direction, wave_period, wind_wave_height, wind_wave_direction, wind_wave_period
    # Hourly vars: wave_height, wave_direction, wave_period, wind_speed_10m, wind_direction_10m, ocean_current_velocity, ocean_current_direction
    
    curl -s "${API_BASE}?latitude=${lat}&longitude=${lon}&hourly=wave_height,wave_direction,wave_period,wind_wave_height,wind_wave_direction,wind_wave_period&daily=wave_height_max,wave_direction_dominant,wave_period_max,wind_wave_height_max&timezone=Europe/Madrid&forecast_days=7" \
        | jq -r --arg location "$location_name" '
            # Current conditions (first hourly data point)
            .hourly as $hourly |
            .daily as $daily |
            
            "## \($location)\n",
            "**Ahora mismo** (estimado para \($hourly.time[0] | split("T")[1])):\n",
            "- 🌊 Altura de ola: \($hourly.wave_height[0] // "N/A")m",
            "- 📐 Dirección ola: \($hourly.wave_direction[0] // "N/A")°",
            "- ⏱️ Período: \($hourly.wave_period[0] // "N/A")s",
            "- 💨 Altura ola viento: \($hourly.wind_wave_height[0] // "N/A")m",
            "- 🧭 Dirección ola viento: \($hourly.wind_wave_direction[0] // "N/A")°\n",
            
            "**Previsión 7 días:**\n",
            (
                range(0; $daily.time | length) | 
                "### \($daily.time[.])\n" +
                "- 🌊 Altura máxima: \($daily.wave_height_max[.] // "N/A")m\n" +
                "- 📐 Dirección dominante: \($daily.wave_direction_dominant[.] // "N/A")°\n" +
                "- ⏱️ Período máximo: \($daily.wave_period_max[.] // "N/A")s\n" +
                "- 💨 Altura máx ola viento: \($daily.wind_wave_height_max[.] // "N/A")m\n"
            )
        '
}

# Generate markdown report
{
    echo "# 🏄 Condiciones de Surf — $DATE"
    echo ""
    echo "**Generado:** $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "**Fuente:** Open-Meteo Marine API"
    echo ""
    echo "---"
    echo ""
    
    # Hendaya (spot principal de Manu)
    fetch_conditions "$LAT_HENDAYA" "$LON_HENDAYA" "🇫🇷 Hendaya (País Vasco francés) ⭐ SPOT PRINCIPAL"
    echo ""
    echo "---"
    echo ""
    
    # Santander area
    fetch_conditions "$LAT_SANTANDER" "$LON_SANTANDER" "Santander (Cantabria)"
    echo ""
    echo "---"
    echo ""
    
    # San Sebastián area
    fetch_conditions "$LAT_SANSEB" "$LON_SANSEB" "San Sebastián (País Vasco)"
    echo ""
    echo "---"
    echo ""
    
    echo "## 📊 Interpretación"
    echo ""
    echo "**Altura de ola:**"
    echo "- <0.5m: Muy pequeño (principiante absoluto)"
    echo "- 0.5-1m: Pequeño (principiante/intermedio)"
    echo "- 1-1.5m: Bueno (intermedio)"
    echo "- 1.5-2.5m: Muy bueno (intermedio/avanzado)"
    echo "- >2.5m: Grande (avanzado)"
    echo ""
    echo "**Período:**"
    echo "- <8s: Wind swell (olas de viento local, choppier)"
    echo "- 8-12s: Bueno (ground swell, olas más ordenadas)"
    echo "- >12s: Excelente (long period swell, potentes y limpias)"
    echo ""
    echo "**Dirección:**"
    echo "- 0° = Norte, 90° = Este, 180° = Sur, 270° = Oeste"
    echo "- Costa Cantábrica: mejor swell del N/NW (315-45°)"
    echo "- Costa vasca: mejor swell del NW/W (270-315°)"
    echo ""
    echo "_Nota: Esta info es aproximada. Para decisión final, consultar con Lola considerando calendario, fatiga Garmin, y experiencia._"
    
} > "$OUTPUT_FILE"

echo "✅ Condiciones guardadas en: $OUTPUT_FILE"
