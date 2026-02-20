#!/bin/bash
# Reporte de salud diario desde Garmin Connect
# Uso: garmin-health-report.sh [YYYY-MM-DD] (default: hoy)

DATE="${1:-$(date +%Y-%m-%d)}"

python3 << PYEOF
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
        print("❌ Error: No se encontraron tokens de Garmin en ~/.openclaw/.env")
        sys.exit(1)
    
    # Crear cliente
    client = Garmin()
    client.garth.loads(tokens)
    
    # 🔧 FIX CRÍTICO: Forzar displayName
    client.display_name = "Manu_Lazarus"
    
    return client

def format_date(date_str):
    """Formato amigable de fecha"""
    d = datetime.fromisoformat(date_str)
    days = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo']
    months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic']
    return f"{days[d.weekday()]} {d.day} {months[d.month-1]}"

# Fecha a consultar
target_date = "$DATE"
print(f"📊 REPORTE DE SALUD - {format_date(target_date)}")
print("=" * 60)
print()

# Cargar cliente
try:
    client = load_garmin_client()
except Exception as e:
    print(f"❌ Error cargando cliente Garmin: {e}")
    sys.exit(1)

# 1. ACTIVIDAD
print("🏃 ACTIVIDAD:")
try:
    summary = client.get_user_summary(target_date)
    
    steps = summary.get('totalSteps', 0)
    distance = summary.get('totalDistanceMeters', 0) / 1000
    calories = summary.get('activeKilocalories', 0)
    floors = summary.get('floorsAscended', 0)
    intensity = summary.get('vigorousIntensityMinutes', 0) + summary.get('moderateIntensityMinutes', 0)
    
    print(f"  👣 Pasos: {steps:,}")
    print(f"  📏 Distancia: {distance:.2f} km")
    print(f"  🔥 Calorías activas: {int(calories)}")
    print(f"  🪜 Pisos: {int(floors)}")
    if intensity > 0:
        print(f"  💪 Minutos intensidad: {intensity}")
    
    # Meta de pasos
    if steps < 5000:
        print(f"  ⚠️ Día sedentario (<5k pasos)")
    elif steps < 7500:
        print(f"  📊 Actividad ligera (5-7.5k pasos)")
    elif steps < 10000:
        print(f"  ✅ Activo (7.5-10k pasos)")
    else:
        print(f"  🏆 Muy activo (>10k pasos)")
    
except Exception as e:
    print(f"  ❌ Error: {e}")

print()

# 2. HEART RATE
print("💓 HEART RATE:")
try:
    hr_data = client.get_heart_rates(target_date)
    
    if hr_data and 'heartRateValues' in hr_data:
        values = [v for v in hr_data['heartRateValues'] if v and v[1] and v[1] > 30]
        
        if values:
            latest = values[-1][1]
            avg = sum(v[1] for v in values) / len(values)
            max_hr = max(v[1] for v in values)
            min_hr = min(v[1] for v in values)
            
            print(f"  💓 Último: {latest} bpm")
            print(f"  📊 Promedio: {avg:.0f} bpm")
            print(f"  ⬆️ Máximo: {max_hr} bpm")
            print(f"  ⬇️ Mínimo (reposo): {min_hr} bpm")
            
            # Evaluación
            if min_hr < 50:
                print(f"  🏃 Forma cardiovascular excelente")
            elif min_hr < 60:
                print(f"  ✅ Forma cardiovascular buena")
            elif min_hr < 70:
                print(f"  📊 Forma cardiovascular normal")
            else:
                print(f"  ⚠️ Frecuencia en reposo alta")
        else:
            print(f"  ⚠️ No hay datos válidos")
    else:
        print(f"  ⚠️ No disponible")
        
except Exception as e:
    print(f"  ❌ Error: {e}")

print()

# 3. ESTRÉS
print("😰 ESTRÉS:")
try:
    stats = client.get_stats(target_date)
    
    if stats and 'averageStressLevel' in stats:
        stress = stats['averageStressLevel']
        print(f"  Nivel promedio: {stress}")
        
        if stress < 25:
            print(f"  ✅ Muy bajo - excelente")
        elif stress < 50:
            print(f"  📊 Bajo - normal")
        elif stress < 75:
            print(f"  ⚠️ Moderado - atención")
        else:
            print(f"  🚨 Alto - necesitas descanso")
    else:
        print(f"  ⚠️ No disponible")
        
except Exception as e:
    print(f"  ⚠️ {e}")

print()

# 4. BODY BATTERY
print("🔋 BODY BATTERY:")
try:
    battery = client.get_body_battery(target_date)
    
    if battery and len(battery) > 0:
        # Obtener valor más reciente y máximo del día
        latest = battery[-1].get('charged', None)
        max_battery = max(b.get('charged', 0) for b in battery)
        min_battery = min(b.get('charged', 100) for b in battery)
        
        if latest is not None:
            print(f"  Nivel actual: {latest}/100")
            print(f"  Rango hoy: {min_battery}-{max_battery}")
            
            if latest < 25:
                print(f"  🔴 Muy bajo - necesitas descanso")
            elif latest < 50:
                print(f"  🟡 Bajo - conserva energía")
            elif latest < 75:
                print(f"  🟢 Bueno - energía suficiente")
            else:
                print(f"  ✅ Alto - energía óptima")
    else:
        print(f"  ⚠️ No disponible")
        
except Exception as e:
    print(f"  ⚠️ {e}")

print()

# 5. SUEÑO (de la noche anterior)
print("😴 SUEÑO (noche anterior):")
try:
    sleep = client.get_sleep_data(target_date)
    
    if sleep and 'dailySleepDTO' in sleep:
        s = sleep['dailySleepDTO']
        
        if 'sleepTimeSeconds' in s:
            total_h = s['sleepTimeSeconds'] / 3600
            deep_h = s.get('deepSleepSeconds', 0) / 3600
            light_h = s.get('lightSleepSeconds', 0) / 3600
            rem_h = s.get('remSleepSeconds', 0) / 3600
            awake_h = s.get('awakeSleepSeconds', 0) / 3600
            
            print(f"  ⏰ Duración total: {total_h:.1f} horas")
            print(f"  🌊 Profundo: {deep_h:.1f}h | 💭 Ligero: {light_h:.1f}h | 👁️ REM: {rem_h:.1f}h")
            
            if awake_h > 0.5:
                print(f"  🌙 Despertares: {awake_h:.1f}h")
            
            # Evaluación
            if total_h < 6:
                print(f"  🔴 Insuficiente - necesitas más descanso")
            elif total_h < 7:
                print(f"  🟡 Corto - podrías mejorar")
            elif total_h < 9:
                print(f"  ✅ Bueno - descanso adecuado")
            else:
                print(f"  📊 Largo - buen descanso")
                
            # Sueño profundo
            if deep_h < 1.0:
                print(f"  ⚠️ Poco sueño profundo")
            elif deep_h > 2.0:
                print(f"  🏆 Excelente sueño profundo")
        else:
            print(f"  ⚠️ No hay datos de duración")
    else:
        print(f"  ⚠️ No disponible")
        
except Exception as e:
    print(f"  ⚠️ {e}")

print()
print("=" * 60)
print("✅ Reporte completado")
PYEOF
