#!/bin/bash
# Sistema de alertas inteligentes para Garmin Connect
# Detecta condiciones anormales y alerta a Manu

python3 << 'PYEOF'
from garminconnect import Garmin
import os
from datetime import datetime, date, timedelta
import sys

def load_garmin_client():
    """Carga cliente Garmin con tokens OAuth y aplica fix del displayName"""
    env_file = os.path.expanduser("~/.openclaw/.env")
    
    # Cargar tokens
    tokens = None
    with open(env_file, 'r') as f:
        for line in f:
            if line.startswith('GARMIN_TOKENS='):
                tokens = line.split('=', 1)[1].strip()
                break
    
    if not tokens:
        return None
    
    # Crear cliente
    client = Garmin()
    client.garth.loads(tokens)
    client.display_name = "Manu_Lazarus"
    
    return client

# Cargar cliente
client = load_garmin_client()
if not client:
    sys.exit(1)

# Analizar últimos 3 días
alerts = []
end_date = date.today()

for i in range(3):
    day = end_date - timedelta(days=i)
    day_str = day.isoformat()
    
    try:
        # Heart Rate
        hr = client.get_heart_rates(day_str)
        if hr and 'heartRateValues' in hr:
            values = [v[1] for v in hr['heartRateValues'] if v and v[1] and v[1] > 30]
            if values:
                min_hr = min(values)
                max_hr = max(values)
                
                # Alerta: HR reposo muy bajo
                if min_hr < 40:
                    alerts.append({
                        'level': 'warning',
                        'type': 'hr_low',
                        'date': day,
                        'message': f"Frecuencia cardíaca muy baja: {min_hr} bpm"
                    })
                
                # Alerta: HR reposo alto
                if min_hr > 80:
                    alerts.append({
                        'level': 'warning',
                        'type': 'hr_high',
                        'date': day,
                        'message': f"Frecuencia cardíaca en reposo alta: {min_hr} bpm"
                    })
                
                # Alerta: HR máximo muy alto
                if max_hr > 180:
                    alerts.append({
                        'level': 'info',
                        'type': 'hr_max',
                        'date': day,
                        'message': f"Frecuencia cardíaca máxima alta: {max_hr} bpm (¿ejercicio intenso?)"
                    })
        
        # Estrés
        stats = client.get_stats(day_str)
        if stats and 'averageStressLevel' in stats:
            stress = stats['averageStressLevel']
            
            # Alerta: Estrés alto
            if stress >= 60:
                alerts.append({
                    'level': 'warning',
                    'type': 'stress_high',
                    'date': day,
                    'message': f"Nivel de estrés alto: {stress}"
                })
        
        # Sueño
        sleep = client.get_sleep_data(day_str)
        if sleep and 'dailySleepDTO' in sleep:
            s = sleep['dailySleepDTO']
            if 'sleepTimeSeconds' in s:
                hours = s['sleepTimeSeconds'] / 3600
                
                # Alerta: Poco sueño
                if hours < 6:
                    alerts.append({
                        'level': 'warning',
                        'type': 'sleep_low',
                        'date': day,
                        'message': f"Sueño insuficiente: {hours:.1f} horas"
                    })
                
                # Sueño profundo
                deep_hours = s.get('deepSleepSeconds', 0) / 3600
                if deep_hours < 0.5 and hours >= 6:
                    alerts.append({
                        'level': 'info',
                        'type': 'deep_sleep_low',
                        'date': day,
                        'message': f"Poco sueño profundo: {deep_hours:.1f}h (total {hours:.1f}h)"
                    })
        
        # Body Battery
        battery = client.get_body_battery(day_str)
        if battery and len(battery) > 0:
            min_battery = min(b.get('charged', 100) for b in battery)
            
            # Alerta: Body Battery muy bajo
            if min_battery < 15:
                alerts.append({
                    'level': 'warning',
                    'type': 'battery_low',
                    'date': day,
                    'message': f"Body Battery muy bajo: {min_battery}/100"
                })
        
    except:
        continue

# Eliminar duplicados (mismo tipo, mismos últimos 3 días)
unique_types = set()
filtered_alerts = []

for alert in alerts:
    if alert['type'] not in unique_types:
        filtered_alerts.append(alert)
        unique_types.add(alert['type'])

# Si hay alertas, imprimirlas
if filtered_alerts:
    print("🚨 ALERTAS DE SALUD (últimos 3 días)")
    print("=" * 60)
    print()
    
    warnings = [a for a in filtered_alerts if a['level'] == 'warning']
    infos = [a for a in filtered_alerts if a['level'] == 'info']
    
    if warnings:
        print("⚠️ ADVERTENCIAS:")
        for alert in warnings:
            date_str = alert['date'].strftime('%d/%m')
            print(f"  • {date_str}: {alert['message']}")
        print()
    
    if infos:
        print("ℹ️ INFORMATIVAS:")
        for alert in infos:
            date_str = alert['date'].strftime('%d/%m')
            print(f"  • {date_str}: {alert['message']}")
        print()
    
    # Recomendaciones
    if any(a['type'] == 'stress_high' for a in filtered_alerts):
        print("💡 Recomendación: Considera técnicas de relajación o ejercicio ligero")
    
    if any(a['type'] == 'sleep_low' for a in filtered_alerts):
        print("💡 Recomendación: Prioriza dormir 7-8 horas las próximas noches")
    
    if any(a['type'] == 'battery_low' for a in filtered_alerts):
        print("💡 Recomendación: Descansa más y reduce actividad intensa")
    
    print()
    print("=" * 60)
else:
    # No hay alertas - todo OK
    print("✅ Sin alertas de salud - todo normal")

PYEOF
