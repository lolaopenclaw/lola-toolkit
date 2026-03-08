#!/usr/bin/env python3
"""
Extract ALL Garmin activities from a date range and sync to Google Sheets
This is a one-time historical data load to match the date range of health data (Feb 15 - present)
"""

from garminconnect import Garmin
import os
from datetime import datetime, timedelta
import subprocess
import json

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
    print("📊 Extrayendo histórico completo de actividades Garmin...")
    print()
    
    client = get_garmin_client()
    
    # Historical data starts from Feb 15, 2026
    start_date = datetime(2026, 2, 15)
    end_date = datetime.now()
    
    print(f"⏱️  Período: {start_date.strftime('%d/%m/%Y')} → {end_date.strftime('%d/%m/%Y')}")
    print()
    
    # Fetch ALL activities (up to 200)
    activities = client.get_activities(0, 200)
    
    activity_list = []
    total_duration = 0
    total_distance = 0
    total_calories = 0
    activity_count_by_type = {}
    
    day_names_es = {
        'Monday': 'Lunes', 'Tuesday': 'Martes', 'Wednesday': 'Miércoles',
        'Thursday': 'Jueves', 'Friday': 'Viernes', 'Saturday': 'Sábado', 'Sunday': 'Domingo'
    }
    
    print(f"🔍 Procesando {len(activities)} actividades del histórico de Garmin...")
    
    # Process all activities in date range
    for activity in activities:
        try:
            date_str = activity.get('startTimeLocal', '')
            if not date_str:
                continue
            
            # Parse the date (format is usually naive: 2026-03-08 14:04:35)
            if 'T' in date_str:
                activity_date = datetime.fromisoformat(date_str.replace('Z', '+00:00'))
            else:
                # Already in local format
                activity_date = datetime.fromisoformat(date_str)
            
            # Only include if in date range
            if activity_date >= start_date and activity_date <= end_date:
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
                
                if activity_type not in activity_count_by_type:
                    activity_count_by_type[activity_type] = {'count': 0, 'calories': 0}
                activity_count_by_type[activity_type]['count'] += 1
                activity_count_by_type[activity_type]['calories'] += calories
        
        except Exception as e:
            pass
    
    # Sort by date
    activity_list.sort(key=lambda x: x['date'])
    
    print(f"✅ Encontradas {len(activity_list)} actividades en el período")
    print()
    
    # ============= CONSOLE OUTPUT =============
    print("🏃 HISTÓRICO COMPLETO DE ACTIVIDADES")
    print("=" * 80)
    print(f"Total actividades: {len(activity_list)}")
    print(f"Tiempo total: {total_duration} minutos ({int(total_duration // 60)}h {int(total_duration % 60)}m)")
    print(f"Distancia total: {total_distance:.2f} km")
    print(f"Calorías totales: {total_calories:.0f} kcal")
    if activity_list:
        print(f"Promedio por actividad: {total_calories/len(activity_list):.0f} kcal")
    
    print("\n📊 Desglose por tipo de actividad:")
    for atype, data in sorted(activity_count_by_type.items(), key=lambda x: x[1]['calories'], reverse=True):
        if atype != 'Unknown':
            print(f"  • {atype}: {data['count']} actividades, {data['calories']:.0f} kcal")
    
    print("\n" + "=" * 80)
    print("Primeras 5 actividades:")
    for i, act in enumerate(activity_list[:5], 1):
        print(f"{i}. {act['name']} ({act['date_short']}) - {act['duration']} min, {act['calories']:.0f} kcal")
    
    print("\nÚltimas 5 actividades:")
    for i, act in enumerate(activity_list[-5:], len(activity_list)-4):
        print(f"{i}. {act['name']} ({act['date_short']}) - {act['duration']} min, {act['calories']:.0f} kcal")
    
    print("\n" + "=" * 80)
    
    # ============= MARKDOWN FILE =============
    report_file = os.path.expanduser(f"~/.openclaw/workspace/memory/actividades-historico-2026-02-15-a-03-08.md")
    with open(report_file, 'w') as f:
        f.write(f"# 🏃 Histórico Completo de Actividades Garmin\n\n")
        f.write(f"**Período:** {start_date.strftime('%d/%m/%Y')} - {end_date.strftime('%d/%m/%Y')}\n\n")
        f.write(f"**Resumen:**\n")
        f.write(f"- Total actividades: {len(activity_list)}\n")
        f.write(f"- Tiempo total: {int(total_duration // 60)}h {int(total_duration % 60)}m\n")
        f.write(f"- Distancia total: {total_distance:.2f} km\n")
        f.write(f"- Calorías totales: {total_calories:.0f} kcal\n\n")
        
        f.write(f"## Desglose por tipo\n\n")
        for atype, data in sorted(activity_count_by_type.items(), key=lambda x: x[1]['calories'], reverse=True):
            if atype != 'Unknown':
                f.write(f"- **{atype}:** {data['count']}x ({data['calories']:.0f} kcal)\n")
        
        f.write(f"\n## Todas las actividades\n\n")
        for i, act in enumerate(activity_list, 1):
            f.write(f"{i}. **{act['name']}** ({act['date_short']})\n")
            f.write(f"   - Fecha: {act['day']} {act['date_formatted']} @ {act['time']}\n")
            f.write(f"   - Duración: {act['duration']} minutos\n")
            if act['distance'] > 0:
                f.write(f"   - Distancia: {act['distance']:.2f} km\n")
            f.write(f"   - Calorías: {act['calories']:.0f} kcal\n")
            if act['avg_hr'] > 0:
                f.write(f"   - HR: {act['avg_hr']} bpm (máx: {act['max_hr']})\n")
            f.write(f"\n")
    
    print(f"\n✅ Markdown guardado: {report_file}")
    
    # ============= GOOGLE SHEETS SYNC =============
    start_row = 200
    end_row = 200
    
    if activity_list:
        sheet_id = "1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk"
        
        print(f"\n📤 Sincronizando {len(activity_list)} actividades a Google Sheets...")
        
        # Prepare values for sheets
        values = []
        values.append(["HISTÓRICO DE ACTIVIDADES - Desde 2026-02-15"])
        values.append(["Fecha", "Día", "Actividad", "Duración (min)", "Distancia (km)", "Calorías", "HR Promedio", "Tipo"])
        
        for activity in activity_list:
            values.append([
                activity['date_short'],
                activity['day'],
                activity['name'],
                str(activity['duration']),
                f"{activity['distance']:.2f}" if activity['distance'] > 0 else "",
                f"{activity['calories']:.0f}",
                str(activity['avg_hr']) if activity['avg_hr'] > 0 else "",
                activity['type'] if activity['type'] != 'Unknown' else ""
            ])
        
        # Find insertion point (after existing data)
        # We'll use row 200 to avoid conflicts
        start_row = 200
        end_row = start_row + len(values)
        
        range_name = f"'Hoja 1'!A{start_row}:H{end_row}"
        
        print(f"   Rango: {range_name}")
        print(f"   Filas: {len(values)}")
        
        # Build command
        cmd = ["gog", "sheets", "update", sheet_id, range_name]
        for row in values:
            cmd.extend(row)
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"\n✅ Datos sincronizados a Google Sheets")
            print(f"   Ubicación: https://docs.google.com/spreadsheets/d/{sheet_id}")
            print(f"   Total filas: {len(values)} (incluyendo headers)")
        else:
            print(f"\n⚠️  Error al sincronizar: {result.stderr}")
    
    print("\n" + "=" * 80)
    print("✅ Histórico completado")
    print(f"   Markdown: {report_file}")
    if activity_list:
        print(f"   Google Sheets: A{start_row}:H{end_row}")
    else:
        print(f"   ⚠️  No activities found in date range")

if __name__ == "__main__":
    main()
