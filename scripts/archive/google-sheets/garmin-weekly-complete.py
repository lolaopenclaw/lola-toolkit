#!/usr/bin/env python3
"""
Complete weekly Garmin activity report
- Console output
- Markdown file
- Google Sheets sync
"""

from garminconnect import Garmin
import os
from datetime import datetime, timedelta
import subprocess

def get_garmin_client():
    env_file = os.path.expanduser("~/.openclaw/.env")
    tokens = None
    with open(env_file, 'r') as f:
        for line in f:
            if line.startswith('GARMIN_TOKENS='):
                tokens = line.split('=', 1)[1].strip()
                break
    if not tokens:
        raise Exception("No Garmin tokens found")
    client = Garmin()
    client.garth.loads(tokens)
    client.display_name = "Manu_Lazarus"
    return client

def main():
    client = get_garmin_client()
    
    # Get week dates
    today = datetime.now()
    week_start = today - timedelta(days=today.weekday())
    week_end = today
    
    # Fetch activities
    activities = client.get_activities(0, 100)
    
    activity_list = []
    total_duration = 0
    total_distance = 0
    total_calories = 0
    activity_types = {}
    
    day_names_es = {
        'Monday': 'Lunes', 'Tuesday': 'Martes', 'Wednesday': 'Miércoles',
        'Thursday': 'Jueves', 'Friday': 'Viernes', 'Saturday': 'Sábado', 'Sunday': 'Domingo'
    }
    
    # Process activities
    for activity in activities[:100]:
        try:
            date_str = activity.get('startTimeLocal', '')
            if not date_str:
                continue
            
            activity_date = datetime.fromisoformat(date_str.replace('Z', '+00:00')).astimezone()
            
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
                date_formatted = activity_date.strftime('%d/%m/%Y')
                date_short = activity_date.strftime('%d/%m')
                time_formatted = activity_date.strftime('%H:%M')
                
                activity_list.append({
                    'name': name,
                    'type': activity_type,
                    'date': activity_date,
                    'day': day_es,
                    'date_formatted': date_formatted,
                    'date_short': date_short,
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
                
                if activity_type not in activity_types:
                    activity_types[activity_type] = 0
                activity_types[activity_type] += 1
        except:
            pass
    
    # Sort by date
    activity_list.sort(key=lambda x: x['date'])
    
    # ============= CONSOLE OUTPUT =============
    print("🏃 RESUMEN DE ACTIVIDADES - SEMANA")
    print("=" * 70)
    print(f"Período: {week_start.strftime('%d/%m/%Y')} - {week_end.strftime('%d/%m/%Y')}")
    print("=" * 70)
    
    for i, act in enumerate(activity_list, 1):
        print(f"\n{i}. {act['name']}")
        print(f"   📅 {act['day']} {act['date_short']} • {act['time']}")
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
    if activity_list:
        print(f"Promedio por actividad: {total_calories/len(activity_list):.0f} kcal")
    
    if activity_types:
        print("\nTipos de actividad:")
        for atype, count in sorted(activity_types.items(), key=lambda x: x[1], reverse=True):
            if atype != 'Unknown':
                print(f"  • {atype}: {count}x")
    
    print("\n" + "=" * 70)
    
    # ============= MARKDOWN FILE =============
    report_file = os.path.expanduser(f"~/.openclaw/workspace/memory/{datetime.now().strftime('%Y-%m-%d')}-actividades.md")
    with open(report_file, 'w') as f:
        f.write(f"# 🏃 Resumen de Actividades - Semana {week_start.strftime('%d/%m')} a {week_end.strftime('%d/%m/%Y')}\n\n")
        f.write(f"**Total:** {len(activity_list)} actividades | {total_duration} min | {total_calories:.0f} kcal\n\n")
        
        for i, act in enumerate(activity_list, 1):
            f.write(f"## {i}. {act['name']}\n")
            f.write(f"- **Fecha:** {act['day']} {act['date_short']} @ {act['time']}\n")
            f.write(f"- **Duración:** {act['duration']} minutos\n")
            if act['distance'] > 0:
                f.write(f"- **Distancia:** {act['distance']:.2f} km\n")
            f.write(f"- **Calorías:** {act['calories']:.0f} kcal\n")
            if act['avg_hr'] > 0:
                f.write(f"- **HR:** {act['avg_hr']} bpm (máx: {act['max_hr']})\n")
            if act['elevation'] > 0:
                f.write(f"- **Elevación:** {act['elevation']:.0f} m\n")
    
    print(f"✅ Reporte Markdown: {report_file}")
    
    # ============= GOOGLE SHEETS =============
    if activity_list:
        sheet_id = "1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk"
        
        # Prepare values for sheets
        values = []
        values.append(["Actividades Semanales"])
        values.append(["Fecha", "Actividad", "Duración (min)", "Distancia (km)", "Calorías", "HR Promedio"])
        
        for activity in activity_list:
            values.append([
                activity['date_short'],
                activity['name'],
                str(activity['duration']),
                f"{activity['distance']:.2f}" if activity['distance'] > 0 else "",
                f"{activity['calories']:.0f}",
                str(activity['avg_hr']) if activity['avg_hr'] > 0 else ""
            ])
        
        # Get last row
        result = subprocess.run(
            ["gog", "sheets", "get", sheet_id, "'Hoja 1'!A1:A100"],
            capture_output=True,
            text=True
        ).stdout.strip()
        
        last_row = len([l for l in result.split('\n') if l.strip()]) + 2
        start_row = last_row + 3
        
        # Update sheets
        range_name = f"'Hoja 1'!A{start_row}:F{start_row + len(values)}"
        
        cmd = ["gog", "sheets", "update", sheet_id, range_name]
        for row in values:
            cmd.extend(row)
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"✅ Datos sincronizados a Google Sheets")
            print(f"   Rango: {range_name}")
            print(f"   Filas: {len(values)}")
            print(f"   Sheet: https://docs.google.com/spreadsheets/d/{sheet_id}")
        else:
            print(f"⚠️  Error Google Sheets: {result.stderr}")
    
    print("\n✅ Reporte completado")

if __name__ == "__main__":
    main()
