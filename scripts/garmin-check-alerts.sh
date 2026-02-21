#!/bin/bash
# Garmin Health Alerts - Detect abnormal conditions
# Usage: garmin-check-alerts.sh [OPTIONS]
#   --hr-abnormal      HR reposo >60 or very low
#   --stress-high      Stress >50
#   --sleep-low        <6.5h sleep
#   --battery-critical Body battery <20%
#   (no args)          Check all

FILTER="${1:-all}"

python3 << PYEOF
from garminconnect import Garmin
import os
from datetime import datetime, date, timedelta
import sys

FILTER = "$FILTER"

def load_garmin_client():
    env_file = os.path.expanduser("~/.openclaw/.env")
    tokens = None
    with open(env_file, 'r') as f:
        for line in f:
            if line.startswith('GARMIN_TOKENS='):
                tokens = line.split('=', 1)[1].strip()
                break
    if not tokens:
        return None
    client = Garmin()
    client.garth.loads(tokens)
    client.display_name = "Manu_Lazarus"
    return client

client = load_garmin_client()
if not client:
    print("❌ No Garmin tokens")
    sys.exit(1)

alerts = []
end_date = date.today()

# Thresholds
HR_RESTING_HIGH = 60
HR_RESTING_LOW = 40
STRESS_HIGH = 50
SLEEP_LOW = 6.5
BATTERY_CRITICAL = 20

for i in range(3):
    day = end_date - timedelta(days=i)
    day_str = day.isoformat()
    day_label = day.strftime('%d/%m')
    
    try:
        # HR check
        if FILTER in ("all", "--hr-abnormal"):
            hr = client.get_heart_rates(day_str)
            if hr and 'heartRateValues' in hr:
                values = [v[1] for v in hr['heartRateValues'] if v and v[1] and v[1] > 30]
                if values:
                    rhr = min(values)
                    if rhr > HR_RESTING_HIGH:
                        alerts.append(('warning', 'hr_high', day_label, f"HR reposo alto: {rhr} bpm (umbral: {HR_RESTING_HIGH})"))
                    if rhr < HR_RESTING_LOW:
                        alerts.append(('warning', 'hr_low', day_label, f"HR reposo muy bajo: {rhr} bpm"))
                    max_hr = max(values)
                    if max_hr > 180:
                        alerts.append(('info', 'hr_max', day_label, f"HR máximo alto: {max_hr} bpm"))
        
        # Stress check
        if FILTER in ("all", "--stress-high"):
            stats = client.get_stats(day_str)
            if stats and 'averageStressLevel' in stats:
                stress = stats['averageStressLevel']
                if stress >= STRESS_HIGH:
                    alerts.append(('warning', 'stress', day_label, f"Estrés alto: {stress} (umbral: {STRESS_HIGH})"))
        
        # Sleep check
        if FILTER in ("all", "--sleep-low"):
            sleep = client.get_sleep_data(day_str)
            if sleep and 'dailySleepDTO' in sleep:
                s = sleep['dailySleepDTO']
                if 'sleepTimeSeconds' in s:
                    hours = s['sleepTimeSeconds'] / 3600
                    if hours < SLEEP_LOW:
                        alerts.append(('warning', 'sleep', day_label, f"Sueño insuficiente: {hours:.1f}h (umbral: {SLEEP_LOW}h)"))
                    deep = s.get('deepSleepSeconds', 0) / 3600
                    if deep < 0.5 and hours >= 6:
                        alerts.append(('info', 'deep_sleep', day_label, f"Poco sueño profundo: {deep:.1f}h"))
        
        # Battery check
        if FILTER in ("all", "--battery-critical"):
            battery = client.get_body_battery(day_str)
            if battery and len(battery) > 0:
                min_bb = min(b.get('charged', 100) for b in battery)
                if min_bb < BATTERY_CRITICAL:
                    alerts.append(('warning', 'battery', day_label, f"Body Battery crítico: {min_bb}/100 (umbral: {BATTERY_CRITICAL})"))
    except:
        continue

# Deduplicate by type
seen = set()
unique = []
for level, atype, day_label, msg in alerts:
    if atype not in seen:
        unique.append((level, atype, day_label, msg))
        seen.add(atype)

if unique:
    print("🚨 ALERTAS DE SALUD (últimos 3 días)")
    print("=" * 60)
    print()
    
    warnings = [a for a in unique if a[0] == 'warning']
    infos = [a for a in unique if a[0] == 'info']
    
    if warnings:
        print("⚠️ ADVERTENCIAS:")
        for _, _, dl, msg in warnings:
            print(f"  • {dl}: {msg}")
        print()
    
    if infos:
        print("ℹ️ INFORMATIVAS:")
        for _, _, dl, msg in infos:
            print(f"  • {dl}: {msg}")
        print()
    
    # Recommendations
    types = {a[1] for a in unique}
    if 'stress' in types:
        print("💡 Considera técnicas de relajación o ejercicio ligero")
    if 'sleep' in types or 'deep_sleep' in types:
        print("💡 Prioriza dormir 7-8 horas las próximas noches")
    if 'battery' in types:
        print("💡 Descansa más y reduce actividad intensa")
    if 'hr_high' in types:
        print("💡 HR reposo elevada — ¿estrés, enfermedad, poco descanso?")
    
    print()
    print("=" * 60)
    
    # Output summary for HEARTBEAT integration
    print(f"ALERT_COUNT={len(unique)}")
    print(f"ALERT_TYPES={','.join(types)}")
else:
    print("✅ Sin alertas de salud - todo normal")
    print("ALERT_COUNT=0")

PYEOF
