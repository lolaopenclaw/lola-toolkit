#!/bin/bash
# ============================================================================
# sheets-populate.sh — DEFINITIVE Google Sheets Population Script
# ============================================================================
# 
# Populates two Google Sheets with daily data:
#   1. Consumo IA — AI usage costs and request counts
#   2. Garmin Health — Health metrics from Garmin Connect
#
# KEY DESIGN DECISIONS:
#   - Uses `gog sheets append --values-json` for RELIABLE columnar insertion
#     (previous scripts used space-separated args → all data in one cell)
#   - Numbers are inserted as raw values (2.50, not "2,50 €")
#     Sheet locale (es_ES) handles display formatting
#   - Garmin data is fetched via Python/garminconnect directly (not parsing text)
#   - Idempotent: checks if today's row already exists before inserting
#
# USAGE:
#   ./sheets-populate.sh                    # Populate both sheets
#   ./sheets-populate.sh --consumo-only     # Only Consumo IA
#   ./sheets-populate.sh --garmin-only      # Only Garmin Health  
#   ./sheets-populate.sh --dry-run          # Show what would be inserted
#   ./sheets-populate.sh --date 2026-02-22  # Specific date (backfill)
#
# CRON: L-V 9:30 AM Madrid (after usage report at 9:10 AM)
# ============================================================================

set -euo pipefail

# === Configuration ===
WORKSPACE="${HOME}/.openclaw/workspace"
CONSUMO_SHEET_ID="1Fs9L4DNG81pzeLNSMDZhQsqqNwYz0TYMEQrAzCoSf6Y"
GARMIN_SHEET_ID="1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk"
GOG_ACCOUNT="lolaopenclaw@gmail.com"
SHEET_NAME="Hoja 1"  # Both sheets use default "Hoja 1"

# Load environment
source "${HOME}/.openclaw/.env" 2>/dev/null || true
export GOG_KEYRING_BACKEND="${GOG_KEYRING_BACKEND:-file}"
export GOG_ACCOUNT="${GOG_ACCOUNT}"

# === Parse Arguments ===
DRY_RUN=false
CONSUMO=true
GARMIN=true
TARGET_DATE=$(date +%Y-%m-%d)
GARMIN_ACTIVITY_DATE=$(date -d "yesterday" +%Y-%m-%d)  # Garmin: activity from yesterday

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)     DRY_RUN=true; shift ;;
    --consumo-only) GARMIN=false; shift ;;
    --garmin-only)  CONSUMO=false; shift ;;
    --date)        TARGET_DATE="$2"; GARMIN_ACTIVITY_DATE="$2"; shift 2 ;;
    *)             echo "Unknown option: $1"; exit 1 ;;
  esac
done

# === Helper Functions ===

log() { echo "  $1"; }

check_duplicate() {
  local sheet_id="$1"
  local date_to_check="$2"
  local range="'${SHEET_NAME}'!A:A"
  
  # Get all dates in column A
  local existing
  existing=$(gog sheets get "$sheet_id" "$range" \
    --account "$GOG_ACCOUNT" --plain 2>/dev/null || echo "")
  
  if echo "$existing" | grep -q "^${date_to_check}$"; then
    return 0  # Duplicate found
  fi
  return 1  # No duplicate
}

append_row() {
  local sheet_id="$1"
  local range="'${SHEET_NAME}'!A:Z"
  local json_values="$2"
  
  if $DRY_RUN; then
    log "🔍 [DRY RUN] Would append to $sheet_id:"
    log "   $json_values"
    return 0
  fi
  
  local result
  result=$(gog sheets append "$sheet_id" "$range" \
    --values-json "$json_values" \
    --account "$GOG_ACCOUNT" \
    --input USER_ENTERED \
    --no-input 2>&1)
  
  if echo "$result" | grep -q "Appended"; then
    log "✅ $result"
    return 0
  else
    log "❌ Error: $result"
    return 1
  fi
}

# ============================================================================
# 1. CONSUMO IA
# ============================================================================

populate_consumo() {
  echo ""
  echo "📈 CONSUMO IA — $TARGET_DATE"
  echo "─────────────────────────────"
  
  # Check for duplicates
  if ! $DRY_RUN && check_duplicate "$CONSUMO_SHEET_ID" "$TARGET_DATE"; then
    log "⏭️  Ya existe fila para $TARGET_DATE — saltando"
    return 0
  fi
  
  # Find usage report for today
  local usage_file=""
  local search_paths=(
    "${WORKSPACE}/memory/${TARGET_DATE}-usage-report.md"
    "${WORKSPACE}/memory/DAILY/HOT/${TARGET_DATE}-usage-report.md"
    "${WORKSPACE}/memory/DAILY/HOT/${TARGET_DATE}-usage-report-final.md"
  )
  
  for path in "${search_paths[@]}"; do
    if [[ -f "$path" ]]; then
      usage_file="$path"
      break
    fi
  done
  
  # Default values
  local total_usd="0" requests="0"
  local haiku="0" sonnet="0" opus="0" gemini="0"
  
  if [[ -n "$usage_file" ]]; then
    log "📄 Leyendo: $(basename "$usage_file")"
    
    # Use Python for structured parsing — much more reliable than grep chains
    local parsed
    parsed=$(python3 << PYEOF
import re, json

with open("$usage_file", "r") as f:
    content = f.read()

result = {"total": 0, "requests": 0, "haiku": 0, "sonnet": 0, "opus": 0, "gemini": 0}

# Strategy: Find "Consumo de Hoy" or "Consumo Hoy" section and parse it
# The section typically looks like:
# ### Consumo de Hoy
# - **Total:** \$4.21 USD
# - **Requests:** 117
# - **Modelo:** Claude Haiku 4.5 (100%)

# Split into sections by ### headers
sections = re.split(r'###\s+', content)

today_section = ""
for s in sections:
    if re.match(r'(?i)consumo\s+(de\s+)?hoy', s):
        today_section = s
        break

if today_section:
    # Extract total from today section
    total_match = re.search(r'\\\$([0-9]+(?:\.[0-9]+)?)\s*(?:USD)?', today_section)
    if total_match:
        result["total"] = float(total_match.group(1))
    
    # Extract requests from today section
    req_match = re.search(r'(?i)requests?\D*?(\d[\d,]*)', today_section)
    if req_match:
        result["requests"] = int(req_match.group(1).replace(",", ""))
    
    # Check model distribution in today section
    # Pattern: "Modelo: Claude Haiku 4.5 (100%)"
    modelo_match = re.search(r'(?i)modelo.*?(haiku|sonnet|opus|gemini).*?\((\d+)%\)', today_section)
    if modelo_match and result["total"] > 0:
        model = modelo_match.group(1).lower()
        pct = int(modelo_match.group(2)) / 100
        result[model] = round(result["total"] * pct, 2)
    
    # If no model distribution in today section, check for per-model lines
    # Pattern: "- Haiku: \$1.20"
    for model in ["haiku", "sonnet", "opus", "gemini"]:
        m = re.search(rf'(?i){model}[^\\n]*\\\$([0-9]+(?:\.[0-9]+)?)', today_section)
        if m:
            result[model] = float(m.group(1))

else:
    # Fallback: look for first "Hoy:" line with dollar amount
    hoy_match = re.search(r'(?i)(?:hoy|today)[:\s]*\\\$([0-9]+(?:\.[0-9]+)?)', content)
    if hoy_match:
        result["total"] = float(hoy_match.group(1))
    
    # Fallback for requests
    req_match = re.search(r'(?i)requests?\D*?(\d[\d,]*)', content)
    if req_match:
        result["requests"] = int(req_match.group(1).replace(",", ""))

print(json.dumps(result))
PYEOF
    ) || parsed='{"total":0,"requests":0,"haiku":0,"sonnet":0,"opus":0,"gemini":0}'
    
    total_usd=$(echo "$parsed" | python3 -c "import sys,json; print(json.load(sys.stdin)['total'])")
    requests=$(echo "$parsed" | python3 -c "import sys,json; print(json.load(sys.stdin)['requests'])")
    haiku=$(echo "$parsed" | python3 -c "import sys,json; print(json.load(sys.stdin)['haiku'])")
    sonnet=$(echo "$parsed" | python3 -c "import sys,json; print(json.load(sys.stdin)['sonnet'])")
    opus=$(echo "$parsed" | python3 -c "import sys,json; print(json.load(sys.stdin)['opus'])")
    gemini=$(echo "$parsed" | python3 -c "import sys,json; print(json.load(sys.stdin)['gemini'])")
  else
    log "⚠️  No usage report found for $TARGET_DATE"
  fi
  
  # Ensure numeric values (strip any non-numeric chars)
  total_usd=$(echo "$total_usd" | grep -oE '^[0-9.]+$' || echo "0")
  requests=$(echo "$requests" | grep -oE '^[0-9]+$' || echo "0")
  haiku=$(echo "$haiku" | grep -oE '^[0-9.]+$' || echo "0")
  sonnet=$(echo "$sonnet" | grep -oE '^[0-9.]+$' || echo "0")
  opus=$(echo "$opus" | grep -oE '^[0-9.]+$' || echo "0")
  gemini=$(echo "$gemini" | grep -oE '^[0-9.]+$' || echo "0")
  
  log "📊 Fecha: $TARGET_DATE"
  log "   Haiku: \$$haiku | Sonnet: \$$sonnet | Opus: \$$opus | Gemini: \$$gemini"
  log "   Total: \$$total_usd | Requests: $requests"
  
  # Build JSON values array — numeric values without quotes for proper sheet handling
  local json="[[\"${TARGET_DATE}\", ${haiku}, ${sonnet}, ${opus}, ${gemini}, ${total_usd}, ${requests}]]"
  
  append_row "$CONSUMO_SHEET_ID" "$json"
}

# ============================================================================
# 2. GARMIN HEALTH
# ============================================================================

populate_garmin() {
  echo ""
  echo "💓 GARMIN HEALTH — $GARMIN_ACTIVITY_DATE (activity) / $TARGET_DATE (sleep)"
  echo "─────────────────────────────────────────────────────────────────────────"
  
  # Check for duplicates (use activity date as the row date)
  if ! $DRY_RUN && check_duplicate "$GARMIN_SHEET_ID" "$GARMIN_ACTIVITY_DATE"; then
    log "⏭️  Ya existe fila para $GARMIN_ACTIVITY_DATE — saltando"
    return 0
  fi
  
  # Fetch Garmin data directly via Python (most reliable)
  log "🔄 Fetching Garmin data..."
  
  local garmin_json
  garmin_json=$(python3 << 'PYEOF'
import os, sys, json
from datetime import datetime, timedelta

def load_garmin_client():
    env_file = os.path.expanduser("~/.openclaw/.env")
    tokens = None
    with open(env_file, 'r') as f:
        for line in f:
            if line.startswith('GARMIN_TOKENS='):
                tokens = line.split('=', 1)[1].strip()
                break
    if not tokens:
        print(json.dumps({"error": "No Garmin tokens found"}))
        sys.exit(0)
    from garminconnect import Garmin
    client = Garmin()
    client.garth.loads(tokens)
    client.display_name = "Manu_Lazarus"
    return client

try:
    client = load_garmin_client()
    
    activity_date = os.environ.get("GARMIN_ACTIVITY_DATE", (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d"))
    sleep_date = os.environ.get("TARGET_DATE", datetime.now().strftime("%Y-%m-%d"))
    
    result = {"date": activity_date}
    
    # Activity summary
    try:
        summary = client.get_user_summary(activity_date)
        result["steps"] = summary.get("totalSteps", 0) or 0
        result["distance_km"] = round((summary.get("totalDistanceMeters", 0) or 0) / 1000, 2)
        result["calories"] = summary.get("activeKilocalories", 0) or 0
        result["floors"] = summary.get("floorsAscended", 0) or 0
        result["intensity_min"] = (summary.get("vigorousIntensityMinutes", 0) or 0) + (summary.get("moderateIntensityMinutes", 0) or 0)
    except Exception as e:
        result["activity_error"] = str(e)
    
    # Heart rate
    try:
        hr = client.get_heart_rates(activity_date)
        if hr and "heartRateValues" in hr:
            values = [v[1] for v in hr["heartRateValues"] if v and v[1] and v[1] > 30]
            if values:
                result["hr_avg"] = round(sum(values) / len(values))
                result["hr_max"] = max(values)
                result["hr_min"] = min(values)
    except Exception as e:
        result["hr_error"] = str(e)
    
    # Stress
    try:
        stats = client.get_stats(activity_date)
        if stats and "averageStressLevel" in stats:
            result["stress"] = stats["averageStressLevel"]
    except:
        pass
    
    # Body Battery
    try:
        battery = client.get_body_battery(activity_date)
        if battery and len(battery) > 0:
            charged_vals = [b.get("charged", 0) for b in battery if b.get("charged") is not None]
            if charged_vals:
                result["battery_max"] = max(charged_vals)
                result["battery_min"] = min(charged_vals)
    except:
        pass
    
    # Sleep (from today — sleep data is keyed to wake-up date)
    try:
        sleep = client.get_sleep_data(sleep_date)
        if sleep and "dailySleepDTO" in sleep:
            s = sleep["dailySleepDTO"]
            if "sleepTimeSeconds" in s and s["sleepTimeSeconds"]:
                result["sleep_total"] = round(s["sleepTimeSeconds"] / 3600, 1)
                result["sleep_deep"] = round(s.get("deepSleepSeconds", 0) / 3600, 1)
                result["sleep_light"] = round(s.get("lightSleepSeconds", 0) / 3600, 1)
                result["sleep_rem"] = round(s.get("remSleepSeconds", 0) / 3600, 1)
    except:
        pass
    
    print(json.dumps(result))
    
except Exception as e:
    print(json.dumps({"error": str(e)}))
PYEOF
  ) || garmin_json='{"error": "Python script failed"}'
  
  # Parse JSON result
  local error
  error=$(echo "$garmin_json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('error',''))" 2>/dev/null || echo "parse_error")
  
  if [[ -n "$error" && "$error" != "" ]]; then
    log "❌ Garmin error: $error"
    return 1
  fi
  
  # Extract values
  local date steps distance_km calories hr_avg hr_max hr_min stress sleep_total sleep_deep battery_max
  date=$(echo "$garmin_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('date',''))" 2>/dev/null)
  steps=$(echo "$garmin_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('steps',0))" 2>/dev/null)
  distance_km=$(echo "$garmin_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('distance_km',0))" 2>/dev/null)
  calories=$(echo "$garmin_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('calories',0))" 2>/dev/null)
  hr_avg=$(echo "$garmin_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('hr_avg',0))" 2>/dev/null)
  hr_max=$(echo "$garmin_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('hr_max',0))" 2>/dev/null)
  hr_min=$(echo "$garmin_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('hr_min',0))" 2>/dev/null)
  stress=$(echo "$garmin_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('stress',0))" 2>/dev/null)
  sleep_total=$(echo "$garmin_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('sleep_total',0))" 2>/dev/null)
  sleep_deep=$(echo "$garmin_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('sleep_deep',0))" 2>/dev/null)
  battery_max=$(echo "$garmin_json" | python3 -c "import sys,json; print(json.load(sys.stdin).get('battery_max',0))" 2>/dev/null)
  
  log "📊 Fecha: $date"
  log "   👣 Pasos: $steps | 📏 Distancia: ${distance_km}km | 🔥 Calorías: $calories"
  log "   💓 HR: avg=$hr_avg max=$hr_max min=$hr_min"
  log "   😴 Sueño: ${sleep_total}h (profundo: ${sleep_deep}h)"
  log "   😰 Estrés: $stress | 🔋 Battery max: $battery_max"
  
  # Garmin sheet columns:
  # Fecha | Pasos | Distancia(km) | Calorías | HR Promedio | HR Max | HR Reposo | Estrés | Sueño(h) | Sueño Profundo(h) | Body Battery Max
  local json="[[\"${date}\", ${steps}, ${distance_km}, ${calories}, ${hr_avg}, ${hr_max}, ${hr_min}, ${stress}, ${sleep_total}, ${sleep_deep}, ${battery_max}]]"
  
  append_row "$GARMIN_SHEET_ID" "$json"
}

# ============================================================================
# MAIN
# ============================================================================

echo "📊 Google Sheets Population — $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"
$DRY_RUN && echo "🔍 MODE: DRY RUN (no data will be written)"

if $CONSUMO; then
  populate_consumo || log "⚠️  Consumo IA population failed (non-fatal)"
fi

if $GARMIN; then
  populate_garmin || log "⚠️  Garmin Health population failed (non-fatal)"
fi

echo ""
echo "============================================================"
echo "✅ Done — $(date '+%H:%M:%S')"
