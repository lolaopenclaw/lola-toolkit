#!/usr/bin/env bash
# ============================================================
# Garmin JSON Export — JSON output for health metrics
# ============================================================
set -euo pipefail

# Dependency check
if ! command -v python3 &>/dev/null; then
  echo '{"error": "python3 not found"}' >&2
  exit 1
fi

if ! python3 -c "import garminconnect" 2>/dev/null; then
  echo '{"error": "garminconnect module not installed. Install: pip install garminconnect"}' >&2
  exit 1
fi

python3 << 'PYEOF'
import json
import os
from datetime import datetime, date, timedelta
from garminconnect import Garmin
import sys

def load_garmin_client():
    """Load Garmin client from env"""
    env_file = os.path.expanduser("~/.openclaw/.env")
    tokens = None
    with open(env_file, 'r') as f:
        for line in f:
            if line.startswith('GARMIN_TOKENS='):
                tokens = line.split('=', 1)[1].strip()
                break
    if not tokens:
        print(json.dumps({"error": "No Garmin tokens found in ~/.openclaw/.env"}), file=sys.stderr)
        sys.exit(1)
    
    client = Garmin()
    client.garth.loads(tokens)
    client.display_name = "Manu_Lazarus"
    return client

def get_current_metrics(client, day_str):
    """Fetch current day metrics as JSON"""
    metrics = {
        'date': day_str,
        'timestamp': datetime.now().isoformat(),
        'hr': {
            'current': None,
            'resting': None,
            'average': None,
            'max': None
        },
        'activity': {
            'steps': 0,
            'distance_km': 0,
            'calories': 0,
            'floors': 0,
            'intensity_minutes': 0
        },
        'sleep': {
            'duration_hours': 0,
            'deep_minutes': 0,
            'light_minutes': 0,
            'rem_minutes': 0
        },
        'stress': {
            'level': 0,
            'status': 'unknown'
        },
        'body_battery': {
            'level': 0,
            'status': 'unknown'
        }
    }
    
    try:
        # Activity summary
        summary = client.get_user_summary(day_str)
        metrics['activity']['steps'] = summary.get('totalSteps', 0)
        metrics['activity']['distance_km'] = summary.get('totalDistanceMeters', 0) / 1000
        metrics['activity']['calories'] = summary.get('activeKilocalories', 0)
        metrics['activity']['floors'] = summary.get('floorsAscended', 0)
        vi = summary.get('vigorousIntensityMinutes', 0)
        mi = summary.get('moderateIntensityMinutes', 0)
        metrics['activity']['intensity_minutes'] = vi + mi
        
        # Heart rate
        hr_data = client.get_heart_rates(day_str)
        if hr_data and 'heartRateValues' in hr_data:
            values = [v[1] for v in hr_data['heartRateValues'] if v and len(v) > 1 and v[1] and v[1] > 30]
            if values:
                metrics['hr']['current'] = values[-1]  # Last recorded
                metrics['hr']['average'] = int(sum(values) / len(values))
                metrics['hr']['max'] = max(values)
        
        # Resting HR
        if 'restingHeartRateData' in summary:
            rest_data = summary['restingHeartRateData']
            if isinstance(rest_data, dict):
                metrics['hr']['resting'] = rest_data.get('lastNightFiveMinuteValue')
            elif isinstance(rest_data, list) and rest_data:
                metrics['hr']['resting'] = rest_data[-1].get('value')
        
        # Sleep
        sleep_data = client.get_sleep_data(day_str)
        if sleep_data and 'dailySleepDTO' in sleep_data:
            sleep = sleep_data['dailySleepDTO']
            if sleep.get('duration'):
                metrics['sleep']['duration_hours'] = sleep['duration'] / 60
            if 'sleepLevels' in sleep:
                for level in sleep['sleepLevels']:
                    duration = (level.get('endGMT', 0) - level.get('startGMT', 0)) / 60
                    if level.get('sleepLevel') == 'Deep':
                        metrics['sleep']['deep_minutes'] += duration
                    elif level.get('sleepLevel') == 'Light':
                        metrics['sleep']['light_minutes'] += duration
                    elif level.get('sleepLevel') == 'REM':
                        metrics['sleep']['rem_minutes'] += duration
        
        # Stress & Body Battery
        if 'stress' in summary:
            stress_val = summary['stress']
            metrics['stress']['level'] = stress_val
            if stress_val < 25:
                metrics['stress']['status'] = 'low'
            elif stress_val < 50:
                metrics['stress']['status'] = 'moderate'
            elif stress_val < 75:
                metrics['stress']['status'] = 'high'
            else:
                metrics['stress']['status'] = 'critical'
        
        if 'bodyBattery' in summary:
            battery = summary['bodyBattery']
            metrics['body_battery']['level'] = battery
            if battery >= 75:
                metrics['body_battery']['status'] = 'excellent'
            elif battery >= 50:
                metrics['body_battery']['status'] = 'good'
            elif battery >= 25:
                metrics['body_battery']['status'] = 'fair'
            else:
                metrics['body_battery']['status'] = 'low'
    
    except Exception as e:
        metrics['error'] = str(e)
    
    return metrics

try:
    client = load_garmin_client()
    today = date.today().isoformat()
    data = get_current_metrics(client, today)
    print(json.dumps(data, indent=2))
except Exception as e:
    print(json.dumps({'error': str(e)}), file=sys.stderr)
    sys.exit(1)

PYEOF
