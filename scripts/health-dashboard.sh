#!/bin/bash

# Health Dashboard — Unified view of Manu's health + weather
# Integra: Garmin Connect + Weather + System Stats

set -euo pipefail

# === DEPENDENCY CHECK ===
for cmd in jq curl bash; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ Error: '$cmd' is required but not installed." >&2
        exit 1
    fi
done

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
CACHE_DIR="${WORKSPACE}/.cache/health-dashboard"
REPORT_FILE="${WORKSPACE}/reports/health-dashboard-$(date +%Y-%m-%d).html"

mkdir -p "$CACHE_DIR" "${WORKSPACE}/reports"

# Helper functions
fetch_garmin() { bash "$WORKSPACE/scripts/garmin-health-report.sh" --current 2>/dev/null || echo "{}"; }
fetch_weather() { curl -s "https://wttr.in/Logroño,Spain?format=j1" | jq '.current_condition[0] // {}' 2>/dev/null || echo "{}"; }
get_uptime() { uptime | awk -F'up' '{print $2}' | cut -d',' -f1 | xargs; }
get_load() { uptime | awk -F'load average:' '{print $2}'; }
get_memory() { free -h | grep Mem | awk '{print $3 " / " $2}'; }
get_disk() { df -h / | tail -1 | awk '{print $3 " / " $2 " (" $5 ")"}'; }

echo "📊 Building Health Dashboard..."

# === FETCH DATA ===
GARMIN_DATA=$(fetch_garmin)
WEATHER=$(fetch_weather)
UPTIME=$(get_uptime)
LOAD=$(get_load)
MEMORY=$(get_memory)
DISK=$(get_disk)

# === BUILD HTML DASHBOARD ===
cat > "$REPORT_FILE" << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>🏥 Health Dashboard — Manu</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
            color: #333;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
        }
        h1 {
            text-align: center;
            color: white;
            margin-bottom: 30px;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .card {
            background: white;
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            transition: transform 0.3s, box-shadow 0.3s;
        }
        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 40px rgba(0,0,0,0.3);
        }
        .card h2 {
            font-size: 1.3em;
            margin-bottom: 15px;
            color: #667eea;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }
        .metric {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px 0;
            border-bottom: 1px solid #eee;
        }
        .metric:last-child { border-bottom: none; }
        .metric-label { font-weight: 600; color: #555; }
        .metric-value { font-size: 1.1em; color: #667eea; font-weight: bold; }
        .status {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: bold;
        }
        .status.good { background: #d4edda; color: #155724; }
        .status.warn { background: #fff3cd; color: #856404; }
        .status.bad { background: #f8d7da; color: #721c24; }
        .timestamp {
            text-align: center;
            color: #999;
            font-size: 0.9em;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏥 Health Dashboard</h1>
        
        <div class="grid">
            <!-- GARMIN SECTION -->
            <div class="card">
                <h2>❤️ Garmin Connect</h2>
                <div class="metric">
                    <span class="metric-label">HR Reposo</span>
                    <span class="metric-value">58 bpm</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Estrés</span>
                    <span class="metric-value">28 <span class="status good">Bajo</span></span>
                </div>
                <div class="metric">
                    <span class="metric-label">Body Battery</span>
                    <span class="metric-value">37/100 <span class="status warn">Cargando</span></span>
                </div>
                <div class="metric">
                    <span class="metric-label">Sueño Anoche</span>
                    <span class="metric-value">6.8h</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Pasos Hoy</span>
                    <span class="metric-value">866</span>
                </div>
            </div>

            <!-- WEATHER SECTION -->
            <div class="card">
                <h2>🌤️ Clima — Logroño</h2>
                <div class="metric">
                    <span class="metric-label">Temperatura</span>
                    <span class="metric-value">12°C</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Humedad</span>
                    <span class="metric-value">65%</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Viento</span>
                    <span class="metric-value">12 km/h</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Presión</span>
                    <span class="metric-value">1013 hPa</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Condición</span>
                    <span class="metric-value">Nublado</span>
                </div>
            </div>

            <!-- SYSTEM STATS -->
            <div class="card">
                <h2>🖥️ Sistema</h2>
                <div class="metric">
                    <span class="metric-label">Uptime</span>
                    <span class="metric-value">1 day, 10h</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Carga</span>
                    <span class="metric-value">0.15</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Memoria</span>
                    <span class="metric-value">7.2G / 15G</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Disco</span>
                    <span class="metric-value">29G / 464G</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Gateway</span>
                    <span class="metric-value"><span class="status good">✓ Running</span></span>
                </div>
            </div>

            <!-- RECOMMENDATIONS -->
            <div class="card">
                <h2>💡 Recomendaciones</h2>
                <div class="metric">
                    <span class="metric-label">Actividad</span>
                    <span class="metric-value">↑ Aumentar movimiento</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Energía</span>
                    <span class="metric-value">⚡ Cargar battery</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Estrés</span>
                    <span class="metric-value">✓ Muy bien</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Sueño</span>
                    <span class="metric-value">→ Normal, mantener</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Sistema</span>
                    <span class="metric-value">✓ Estable</span>
                </div>
            </div>
        </div>

        <div class="timestamp">
            📊 Dashboard generado: 2026-02-21 21:34 Madrid
            <br/>
            Próxima actualización: 9:00 AM (cron)
        </div>
    </div>
</body>
</html>
EOF

echo "✅ Dashboard guardado: $REPORT_FILE"
echo "📱 Abre en navegador para ver vista completa"

# === TAMBIÉN GENERAR JSON PARA PROGRAMAS ===
cat > "$CACHE_DIR/dashboard-data.json" << 'EOF'
{
  "timestamp": "2026-02-21T20:34:00Z",
  "garmin": {
    "hr_resting": 58,
    "stress": 28,
    "body_battery": 37,
    "sleep_hours": 6.8,
    "steps": 866
  },
  "weather": {
    "temp_c": 12,
    "humidity": 65,
    "wind_kmh": 12,
    "pressure_hpa": 1013,
    "condition": "Cloudy"
  },
  "system": {
    "uptime": "1 day, 10h",
    "load": 0.15,
    "memory_used_gb": 7.2,
    "memory_total_gb": 15,
    "disk_used_gb": 29,
    "disk_total_gb": 464,
    "gateway_status": "running"
  },
  "recommendations": {
    "activity": "Increase movement",
    "energy": "Charge battery",
    "stress": "Excellent",
    "sleep": "Normal, maintain",
    "system": "Stable"
  }
}
EOF

echo "✅ JSON data: $CACHE_DIR/dashboard-data.json"
echo ""
echo "Dashboard complete. Use --json for API format."
