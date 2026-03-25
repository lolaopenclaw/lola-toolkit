#!/usr/bin/env python3
"""
Sync Garmin weekly activities to Google Sheets
Creates or updates 'Actividades' sheet in Garmin Health spreadsheet
"""

from garminconnect import Garmin
from google.auth.transport.requests import Request
from google.oauth2.service_account import Credentials
from google.oauth2 import service_account
import google.auth
from googleapiclient.discovery import build
import os
from datetime import datetime, timedelta
import json
import subprocess

# Get Garmin client
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

# Get Google Sheets API via gog CLI (alternative approach using subprocess)
def get_google_sheets_creds():
    """Load credentials from gog CLI config"""
    creds_file = os.path.expanduser("~/.config/gogcli/credentials.json")
    
    if not os.path.exists(creds_file):
        # Try alternative path
        creds_file = os.path.expanduser("~/.config/gog/credentials.json")
    
    if os.path.exists(creds_file):
        with open(creds_file, 'r') as f:
            creds_data = json.load(f)
            return creds_data
    
    return None

def append_activities_to_sheet(activities_data):
    """Append activity data to Google Sheets using gog CLI"""
    sheet_id = "1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk"
    
    # Format data for appending
    # We'll use a simple approach: append to a new area in Hoja 1
    # Columns: Fecha, Actividad, Duración (min), Distancia (km), Calorías, HR Promedio
    
    # Clear old activity section if exists (in columns A-F, rows 1-50)
    # For now, just append to the end
    
    print("📊 Preparando datos para Google Sheets...")
    
    # Get last row with data using gog
    result = subprocess.run(
        ["gog", "sheets", "get", sheet_id, "'Hoja 1'!A1:A100"],
        capture_output=True,
        text=True
    ).stdout.strip()
    
    last_row = len([l for l in result.split('\n') if l.strip()]) + 1
    
    print(f"ℹ️  Última fila con datos: {last_row}")
    print(f"ℹ️  Añadiendo actividades a partir de fila {last_row + 2}")
    
    # Instead of appending one by one, collect all and do batch insert
    # But gog CLI append is limited, so we'll use a different strategy
    
    # Create a temporary values list
    values = []
    values.append(["Actividades Semanales"])  # Header
    values.append(["Fecha", "Actividad", "Duración (min)", "Distancia (km)", "Calorías", "HR Promedio"])
    
    for activity in activities_data:
        values.append([
            activity['date_formatted'],
            activity['name'],
            str(activity['duration']),
            f"{activity['distance']:.2f}" if activity['distance'] > 0 else "",
            f"{activity['calories']:.0f}",
            str(activity['avg_hr']) if activity['avg_hr'] > 0 else ""
        ])
    
    # Write to separate area in the same sheet (starting at row 50 to avoid conflicts)
    range_name = f"'Hoja 1'!A50:F{50 + len(values)}"
    
    print(f"📝 Insertando {len(values)-2} actividades...")
    
    # Use gog sheets update instead of append
    # Build command with values
    cmd = ["gog", "sheets", "update", sheet_id, range_name]
    
    for row in values:
        cmd.extend(row)
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode == 0:
        print(f"✅ Datos insertados en Google Sheets")
        print(f"   Rango: {range_name}")
        print(f"   Filas: {len(values)}")
    else:
        print(f"⚠️  Error al insertar: {result.stderr}")
    
    return True

def main():
    try:
        print("🏃 Sincronizando actividades Garmin a Google Sheets...")
        print()
        
        # Get Garmin activities
        client = get_garmin_client()
        
        # Get activities for this week
        today = datetime.now()
        week_start = today - timedelta(days=today.weekday())
        week_end = today
        
        activities = client.get_activities(0, 100)
        
        activity_list = []
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
                
                if activity_date.date() >= week_start.date() and activity_date.date() <= week_end.date():
                    name = activity.get('activityName', 'Unknown')
                    duration_sec = activity.get('duration', 0)
                    duration_min = int(duration_sec / 60)
                    distance_m = activity.get('distance', 0)
                    distance_km = distance_m / 1000
                    calories = activity.get('calories', 0)
                    avg_hr = activity.get('averageHeartRate', 0)
                    
                    date_formatted = activity_date.strftime('%d/%m/%Y')
                    
                    activity_list.append({
                        'name': name,
                        'date_formatted': date_formatted,
                        'duration': duration_min,
                        'distance': distance_km,
                        'calories': calories,
                        'avg_hr': avg_hr
                    })
            except:
                pass
        
        # Sort by date
        activity_list.sort(key=lambda x: x['date_formatted'])
        
        print(f"📊 Encontradas {len(activity_list)} actividades esta semana")
        for act in activity_list:
            print(f"   • {act['name']}: {act['duration']} min, {act['calories']:.0f} kcal")
        
        # Append to Google Sheets
        if activity_list:
            append_activities_to_sheet(activity_list)
        
        print("\n✅ Sincronización completada")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
