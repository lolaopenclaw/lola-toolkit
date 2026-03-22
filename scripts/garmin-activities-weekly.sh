#!/bin/bash
set -e
# garmin-activities-weekly.sh
# Generate weekly activity report from Garmin

python3 << 'EOF'
from garminconnect import Garmin
import os
from datetime import datetime, timedelta
import json

# Load tokens
env_file = os.path.expanduser("~/.openclaw/.env")
tokens = None

with open(env_file, 'r') as f:
    for line in f:
        if line.startswith('GARMIN_TOKENS='):
            tokens = line.split('=', 1)[1].strip()
            break

if not tokens:
    print("❌ Error: No Garmin tokens found")
    exit(1)

client = Garmin()
client.garth.loads(tokens)
client.display_name = "Manu_Lazarus"

# Get activities for this week
today = datetime.now()
week_start = today - timedelta(days=today.weekday())  # Monday
week_end = today

activities = client.get_activities(0, 100)

print("🏃 RESUMEN DE ACTIVIDADES - SEMANA")
print("=" * 70)
print(f"Período: {week_start.strftime('%d/%m/%Y')} - {week_end.strftime('%d/%m/%Y')}")
print("=" * 70)

activity_list = []
total_duration = 0
total_distance = 0
total_calories = 0
activity_types = {}

day_names_es = {
    'Monday': 'Lunes', 'Tuesday': 'Martes', 'Wednesday': 'Miércoles',
    'Thursday': 'Jueves', 'Friday': 'Viernes', 'Saturday': 'Sábado', 'Sunday': 'Domingo'
}

for activity in activities[:100]:
    try:
        date_str = activity.get('startTimeLocal', '')
        if not date_str:
            continue
        
        activity_date = datetime.fromisoformat(date_str.replace('Z', '+00:00')).astimezone()
        
        # Check if in this week
        if activity_date.date() >= week_start.date() and activity_date.date() <= week_end.date():
            name = activity.get('activityName', 'Unknown')
            activity_type = activity.get('activityType', {}).get('displayName', 'Unknown')
            duration_sec = activity.get('duration', 0)
            duration_min = int(duration_sec / 60)
            distance_m = activity.get('distance', 0)
            distance_km = distance_m / 1000
            calories = activity.get('calories', 0)
            avg_hr = activity.get('averageHeartRate', 0)
            max_hr = activity.get('maxHeartRate', 0)
            elevation = activity.get('elevationGain', 0)
            
            day_name_en = activity_date.strftime('%A')
            day_es = day_names_es.get(day_name_en, day_name_en)
            date_formatted = activity_date.strftime('%d/%m')
            time_formatted = activity_date.strftime('%H:%M')
            
            activity_list.append({
                'name': name,
                'type': activity_type,
                'date': activity_date,
                'day': day_es,
                'date_formatted': date_formatted,
                'time': time_formatted,
                'duration': duration_min,
                'distance': distance_km,
                'calories': calories,
                'avg_hr': avg_hr,
                'max_hr': max_hr,
                'elevation': elevation
            })
            
            total_duration += duration_min
            total_distance += distance_km
            total_calories += calories
            
            # Count activity types
            if activity_type not in activity_types:
                activity_types[activity_type] = 0
            activity_types[activity_type] += 1
    
    except Exception as e:
        pass

# Sort by date
activity_list.sort(key=lambda x: x['date'])

# Print activities
for i, act in enumerate(activity_list, 1):
    print(f"\n{i}. {act['name']}")
    print(f"   📅 {act['day']} {act['date_formatted']} • {act['time']}")
    if act['type'] != 'Unknown':
        print(f"   🏷️  {act['type']}")
    print(f"   ⏱️  {act['duration']} minutos", end="")
    if act['distance'] > 0:
        print(f" | 📍 {act['distance']:.2f} km", end="")
    print(f" | 🔥 {act['calories']:.0f} kcal")
    if act['avg_hr'] > 0:
        print(f"   ❤️  {act['avg_hr']} bpm promedio (máx: {act['max_hr']})")
    if act['elevation'] > 0:
        print(f"   ⛰️  Elevación: {act['elevation']:.0f} m")

print("\n" + "=" * 70)
print("📊 RESUMEN SEMANAL")
print("=" * 70)
print(f"Total actividades: {len(activity_list)}")
print(f"Tiempo total: {total_duration} minutos ({int(total_duration // 60)}h {int(total_duration % 60)}m)")
print(f"Distancia total: {total_distance:.2f} km")
print(f"Calorías totales: {total_calories:.0f} kcal")
print(f"Promedio por actividad: {total_calories/len(activity_list):.0f} kcal" if activity_list else "")

if activity_types:
    print("\nTipos de actividad:")
    for atype, count in sorted(activity_types.items(), key=lambda x: x[1], reverse=True):
        if atype != 'Unknown':
            print(f"  • {atype}: {count}x")

print("\n" + "=" * 70)

# Save to file
report_file = os.path.expanduser(f"~/.openclaw/workspace/memory/{datetime.now().strftime('%Y-%m-%d')}-actividades.md")
with open(report_file, 'w') as f:
    f.write(f"# 🏃 Resumen de Actividades - Semana {week_start.strftime('%d/%m')} a {week_end.strftime('%d/%m/%Y')}\n\n")
    f.write(f"**Total:** {len(activity_list)} actividades | {total_duration} min | {total_calories:.0f} kcal\n\n")
    
    for i, act in enumerate(activity_list, 1):
        f.write(f"## {i}. {act['name']}\n")
        f.write(f"- **Fecha:** {act['day']} {act['date_formatted']} @ {act['time']}\n")
        f.write(f"- **Duración:** {act['duration']} minutos\n")
        if act['distance'] > 0:
            f.write(f"- **Distancia:** {act['distance']:.2f} km\n")
        f.write(f"- **Calorías:** {act['calories']:.0f} kcal\n")
        if act['avg_hr'] > 0:
            f.write(f"- **HR:** {act['avg_hr']} bpm (máx: {act['max_hr']})\n")
        if act['elevation'] > 0:
            f.write(f"- **Elevación:** {act['elevation']:.0f} m\n")

print(f"✅ Reporte guardado: {report_file}")

# Also sync to Google Sheets
import subprocess
try:
    result = subprocess.run(["python3", "/home/mleon/.openclaw/workspace/scripts/garmin-activities-to-sheets.py"], 
                          capture_output=True, text=True, timeout=30)
    print(f"\n{result.stdout}")
except Exception as e:
    print(f"\n⚠️  No se pudo sincronizar a Google Sheets: {e}")

EOF
