#!/bin/bash
# Análisis histórico de datos de Garmin Connect
# Uso: garmin-historical-analysis.sh [días] (default: 30)
# Requisitos: Python 3, módulo garminconnect, ~/.openclaw/.env con GARMIN_TOKENS

set -euo pipefail

# Validación de dependencias
if ! command -v python3 &> /dev/null; then
  echo "❌ Error: python3 no está instalado"
  exit 1
fi

ENV_FILE="${HOME}/.openclaw/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ Error: No encontrado $ENV_FILE (requerido para GARMIN_TOKENS)"
  exit 1
fi

if ! grep -q "GARMIN_TOKENS=" "$ENV_FILE"; then
  echo "❌ Error: GARMIN_TOKENS no configurado en $ENV_FILE"
  exit 1
fi

DAYS="${1:-30}"
if ! [[ "$DAYS" =~ ^[0-9]+$ ]] || [ "$DAYS" -lt 1 ]; then
  echo "❌ Error: días debe ser un número positivo (pasó: $DAYS)"
  exit 1
fi

python3 << PYEOF
from garminconnect import Garmin
import os
from datetime import datetime, date, timedelta
import sys
import traceback

def load_garmin_client():
    """Carga cliente Garmin con tokens OAuth y aplica fix del displayName"""
    env_file = os.path.expanduser("~/.openclaw/.env")
    
    # Cargar tokens
    tokens = None
    try:
        with open(env_file, 'r') as f:
            for line in f:
                if line.startswith('GARMIN_TOKENS='):
                    tokens = line.split('=', 1)[1].strip()
                    break
    except IOError as e:
        print(f"❌ Error leyendo {env_file}: {e}")
        sys.exit(1)
    
    if not tokens:
        print("❌ Error: GARMIN_TOKENS no encontrado en ~/.openclaw/.env")
        sys.exit(1)
    
    # Crear cliente
    client = Garmin()
    client.garth.loads(tokens)
    
    # 🔧 FIX CRÍTICO: Forzar displayName
    client.display_name = "Manu_Lazarus"
    
    return client

# Configuración
days = int("$DAYS")
end_date = date.today()
start_date = end_date - timedelta(days=days-1)

print(f"📊 ANÁLISIS HISTÓRICO - Últimos {days} días")
print(f"📅 Período: {start_date.strftime('%d/%m/%Y')} - {end_date.strftime('%d/%m/%Y')}")
print("=" * 70)
print()

# Cargar cliente
try:
    client = load_garmin_client()
except Exception as e:
    print(f"❌ Error cargando cliente Garmin: {e}")
    sys.exit(1)

# Recopilar datos
daily_data = []
print("📥 Recopilando datos...")

for i in range(days):
    day = end_date - timedelta(days=i)
    day_str = day.isoformat()
    
    try:
        summary = client.get_user_summary(day_str)
        hr = client.get_heart_rates(day_str)
        stats = client.get_stats(day_str)
        
        # Procesar heart rate
        hr_values = []
        if hr and 'heartRateValues' in hr:
            hr_values = [v[1] for v in hr['heartRateValues'] if v and v[1] and v[1] > 30]
        
        daily_data.append({
            'date': day,
            'steps': summary.get('totalSteps', 0),
            'distance': summary.get('totalDistanceMeters', 0) / 1000,
            'calories': summary.get('activeKilocalories', 0),
            'floors': summary.get('floorsAscended', 0),
            'intensity': summary.get('vigorousIntensityMinutes', 0) + summary.get('moderateIntensityMinutes', 0),
            'resting_hr': min(hr_values) if hr_values else None,
            'avg_hr': sum(hr_values) / len(hr_values) if hr_values else None,
            'max_hr': max(hr_values) if hr_values else None,
            'stress': stats.get('averageStressLevel', None)
        })
    except:
        # Día sin datos, continuar
        pass

if not daily_data:
    print("❌ No se pudieron obtener datos")
    sys.exit(1)

print(f"✅ {len(daily_data)} días de datos recopilados")
print()

# --- ACTIVIDAD ---
print("🏃 ACTIVIDAD:")
print("-" * 70)

# Pasos
total_steps = sum(d['steps'] for d in daily_data)
days_with_steps = [d for d in daily_data if d['steps'] > 0]
avg_steps = total_steps / len(days_with_steps) if days_with_steps else 0

print(f"👣 PASOS:")
print(f"  Total: {total_steps:,}")
print(f"  Promedio diario: {avg_steps:,.0f}")

# Distribución de actividad
very_active = len([d for d in daily_data if d['steps'] >= 10000])
active = len([d for d in daily_data if 7500 <= d['steps'] < 10000])
light = len([d for d in daily_data if 5000 <= d['steps'] < 7500])
sedentary = len([d for d in daily_data if d['steps'] < 5000])

print(f"  Días muy activos (>10k): {very_active} ({very_active/days*100:.0f}%)")
print(f"  Días activos (7.5-10k): {active} ({active/days*100:.0f}%)")
print(f"  Días ligeros (5-7.5k): {light} ({light/days*100:.0f}%)")
print(f"  Días sedentarios (<5k): {sedentary} ({sedentary/days*100:.0f}%)")

# Día más activo
most_active = max(daily_data, key=lambda x: x['steps'])
print(f"  🏆 Día más activo: {most_active['date'].strftime('%d/%m')} ({most_active['steps']:,} pasos)")

# Distancia total
total_distance = sum(d['distance'] for d in daily_data)
print(f"\n📏 DISTANCIA:")
print(f"  Total: {total_distance:.1f} km")
print(f"  Promedio diario: {total_distance/days:.2f} km")

# Calorías
total_calories = sum(d['calories'] for d in daily_data)
print(f"\n🔥 CALORÍAS ACTIVAS:")
print(f"  Total: {total_calories:,.0f}")
print(f"  Promedio diario: {total_calories/days:.0f}")

print()

# --- HEART RATE ---
print("💓 HEART RATE:")
print("-" * 70)

hr_data = [d for d in daily_data if d['resting_hr']]
if hr_data:
    avg_resting = sum(d['resting_hr'] for d in hr_data) / len(hr_data)
    min_resting = min(d['resting_hr'] for d in hr_data)
    max_resting = max(d['resting_hr'] for d in hr_data)
    
    print(f"Frecuencia en reposo:")
    print(f"  Promedio: {avg_resting:.0f} bpm")
    print(f"  Rango: {min_resting:.0f}-{max_resting:.0f} bpm")
    
    # Evaluación
    if avg_resting < 60:
        print(f"  ✅ Excelente forma cardiovascular")
    elif avg_resting < 70:
        print(f"  ✅ Buena forma cardiovascular")
    elif avg_resting < 80:
        print(f"  📊 Forma cardiovascular normal")
    else:
        print(f"  ⚠️ Podría mejorar con más actividad")
    
    # Máximos
    if any(d['max_hr'] for d in hr_data):
        max_hrs = [d['max_hr'] for d in hr_data if d['max_hr']]
        avg_max = sum(max_hrs) / len(max_hrs)
        print(f"\nFrecuencia máxima promedio: {avg_max:.0f} bpm")
else:
    print("⚠️ No hay suficientes datos de heart rate")

print()

# --- ESTRÉS ---
print("😰 ESTRÉS:")
print("-" * 70)

stress_data = [d for d in daily_data if d['stress']]
if stress_data:
    avg_stress = sum(d['stress'] for d in stress_data) / len(stress_data)
    min_stress = min(d['stress'] for d in stress_data)
    max_stress = max(d['stress'] for d in stress_data)
    
    print(f"Nivel de estrés:")
    print(f"  Promedio: {avg_stress:.0f}")
    print(f"  Rango: {min_stress:.0f}-{max_stress:.0f}")
    
    # Días con estrés alto
    high_stress_days = len([d for d in stress_data if d['stress'] >= 50])
    if high_stress_days > 0:
        print(f"  ⚠️ Días con estrés alto (≥50): {high_stress_days} ({high_stress_days/len(stress_data)*100:.0f}%)")
    else:
        print(f"  ✅ Sin días de estrés alto")
    
    # Evaluación general
    if avg_stress < 25:
        print(f"  ✅ Muy bien manejado")
    elif avg_stress < 50:
        print(f"  📊 Normal")
    else:
        print(f"  ⚠️ Considera técnicas de relajación")
else:
    print("⚠️ No hay suficientes datos de estrés")

print()

# --- TENDENCIAS ---
print("📈 TENDENCIAS:")
print("-" * 70)

# Comparar última semana vs semana anterior
if len(daily_data) >= 14:
    recent_7 = daily_data[:7]
    prev_7 = daily_data[7:14]
    
    recent_avg = sum(d['steps'] for d in recent_7) / 7
    prev_avg = sum(d['steps'] for d in prev_7) / 7
    diff = recent_avg - prev_avg
    pct = (diff / prev_avg * 100) if prev_avg > 0 else 0
    
    trend_icon = "📈" if diff > 0 else "📉"
    
    print(f"Actividad (última semana vs anterior):")
    print(f"  Última semana: {recent_avg:,.0f} pasos/día")
    print(f"  Semana anterior: {prev_avg:,.0f} pasos/día")
    print(f"  {trend_icon} Cambio: {diff:+,.0f} pasos/día ({pct:+.1f}%)")
    
    if diff > 1000:
        print(f"  🎉 Mejora significativa!")
    elif diff < -1000:
        print(f"  ⚠️ Disminución notable")
    else:
        print(f"  📊 Estable")

print()
print("=" * 70)
print("✅ Análisis completado")
PYEOF
