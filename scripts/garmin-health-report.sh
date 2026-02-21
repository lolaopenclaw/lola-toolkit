#!/bin/bash
# Garmin Health Report - Multi-mode health reporting
# Usage: garmin-health-report.sh [OPTIONS]
#   --daily     Daily report (HR, steps, sleep, stress)
#   --weekly    Weekly report (trends, comparisons)
#   --current   Current state (live data)
#   --alerts    Check for active alerts
#   --summary   Last 7 days summary
# Default (no args): --daily

MODE="${1:---daily}"

case "$MODE" in
  --daily)
    DATE="${2:-$(date +%Y-%m-%d)}"
    ;;
  --weekly|--summary)
    DAYS=7
    ;;
  --current)
    DATE="$(date +%Y-%m-%d)"
    ;;
  --alerts)
    exec bash "$(dirname "$0")/garmin-check-alerts.sh"
    ;;
  *)
    echo "Usage: garmin-health-report.sh [--daily|--weekly|--current|--alerts|--summary] [date]"
    exit 1
    ;;
esac

python3 << PYEOF
from garminconnect import Garmin
import os
from datetime import datetime, date, timedelta
import sys

MODE = "$MODE"

def load_garmin_client():
    env_file = os.path.expanduser("~/.openclaw/.env")
    tokens = None
    with open(env_file, 'r') as f:
        for line in f:
            if line.startswith('GARMIN_TOKENS='):
                tokens = line.split('=', 1)[1].strip()
                break
    if not tokens:
        print("❌ Error: No se encontraron tokens de Garmin en ~/.openclaw/.env")
        sys.exit(1)
    client = Garmin()
    client.garth.loads(tokens)
    client.display_name = "Manu_Lazarus"
    return client

def format_date(date_str):
    d = datetime.fromisoformat(date_str)
    days = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo']
    months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic']
    return f"{days[d.weekday()]} {d.day} {months[d.month-1]}"

def get_day_data(client, day_str):
    """Fetch all data for a single day"""
    data = {'date': day_str}
    
    try:
        summary = client.get_user_summary(day_str)
        data['steps'] = summary.get('totalSteps', 0)
        data['distance'] = summary.get('totalDistanceMeters', 0) / 1000
        data['calories'] = summary.get('activeKilocalories', 0)
        data['floors'] = summary.get('floorsAscended', 0)
        data['intensity'] = summary.get('vigorousIntensityMinutes', 0) + summary.get('moderateIntensityMinutes', 0)
    except:
        data['steps'] = 0; data['distance'] = 0; data['calories'] = 0; data['floors'] = 0; data['intensity'] = 0
    
    try:
        hr = client.get_heart_rates(day_str)
        if hr and 'heartRateValues' in hr:
            values = [v[1] for v in hr['heartRateValues'] if v and v[1] and v[1] > 30]
            if values:
                data['hr_latest'] = values[-1]
                data['hr_avg'] = sum(values) / len(values)
                data['hr_max'] = max(values)
                data['hr_min'] = min(values)
    except:
        pass
    
    try:
        stats = client.get_stats(day_str)
        if stats and 'averageStressLevel' in stats:
            data['stress'] = stats['averageStressLevel']
    except:
        pass
    
    try:
        battery = client.get_body_battery(day_str)
        if battery and len(battery) > 0:
            data['battery_current'] = battery[-1].get('charged', None)
            data['battery_max'] = max(b.get('charged', 0) for b in battery)
            data['battery_min'] = min(b.get('charged', 100) for b in battery)
    except:
        pass
    
    try:
        sleep = client.get_sleep_data(day_str)
        if sleep and 'dailySleepDTO' in sleep:
            s = sleep['dailySleepDTO']
            if 'sleepTimeSeconds' in s:
                data['sleep_total'] = s['sleepTimeSeconds'] / 3600
                data['sleep_deep'] = s.get('deepSleepSeconds', 0) / 3600
                data['sleep_light'] = s.get('lightSleepSeconds', 0) / 3600
                data['sleep_rem'] = s.get('remSleepSeconds', 0) / 3600
                data['sleep_awake'] = s.get('awakeSleepSeconds', 0) / 3600
    except:
        pass
    
    return data

def print_daily(data):
    """Print daily report for a single day"""
    day_str = data['date']
    print(f"📊 REPORTE DE SALUD - {format_date(day_str)}")
    print("=" * 60)
    print()
    
    # Activity
    print("🏃 ACTIVIDAD:")
    steps = data.get('steps', 0)
    print(f"  👣 Pasos: {steps:,}")
    print(f"  📏 Distancia: {data.get('distance', 0):.2f} km")
    print(f"  🔥 Calorías activas: {int(data.get('calories', 0))}")
    print(f"  🪜 Pisos: {int(data.get('floors', 0))}")
    if data.get('intensity', 0) > 0:
        print(f"  💪 Minutos intensidad: {data['intensity']}")
    if steps < 5000: print(f"  ⚠️ Día sedentario (<5k pasos)")
    elif steps < 7500: print(f"  📊 Actividad ligera")
    elif steps < 10000: print(f"  ✅ Activo")
    else: print(f"  🏆 Muy activo (>10k pasos)")
    print()
    
    # Heart Rate
    print("💓 HEART RATE:")
    if 'hr_min' in data:
        print(f"  💓 Último: {data.get('hr_latest', '?')} bpm")
        print(f"  📊 Promedio: {data['hr_avg']:.0f} bpm")
        print(f"  ⬆️ Máximo: {data['hr_max']} bpm")
        print(f"  ⬇️ Mínimo (reposo): {data['hr_min']} bpm")
        rhr = data['hr_min']
        if rhr < 50: print(f"  🏃 Forma cardiovascular excelente")
        elif rhr < 60: print(f"  ✅ Forma cardiovascular buena")
        elif rhr < 70: print(f"  📊 Forma cardiovascular normal")
        else: print(f"  ⚠️ Frecuencia en reposo alta")
    else:
        print(f"  ⚠️ No disponible")
    print()
    
    # Stress
    print("😰 ESTRÉS:")
    if 'stress' in data:
        s = data['stress']
        print(f"  Nivel promedio: {s}")
        if s < 25: print(f"  ✅ Muy bajo - excelente")
        elif s < 50: print(f"  📊 Bajo - normal")
        elif s < 75: print(f"  ⚠️ Moderado - atención")
        else: print(f"  🚨 Alto - necesitas descanso")
    else:
        print(f"  ⚠️ No disponible")
    print()
    
    # Body Battery
    print("🔋 BODY BATTERY:")
    if 'battery_current' in data and data['battery_current'] is not None:
        bb = data['battery_current']
        print(f"  Nivel actual: {bb}/100")
        print(f"  Rango hoy: {data.get('battery_min', '?')}-{data.get('battery_max', '?')}")
        if bb < 25: print(f"  🔴 Muy bajo - necesitas descanso")
        elif bb < 50: print(f"  🟡 Bajo - conserva energía")
        elif bb < 75: print(f"  🟢 Bueno - energía suficiente")
        else: print(f"  ✅ Alto - energía óptima")
    else:
        print(f"  ⚠️ No disponible")
    print()
    
    # Sleep
    print("😴 SUEÑO (noche anterior):")
    if 'sleep_total' in data:
        t = data['sleep_total']
        print(f"  ⏰ Duración total: {t:.1f} horas")
        print(f"  🌊 Profundo: {data['sleep_deep']:.1f}h | 💭 Ligero: {data['sleep_light']:.1f}h | 👁️ REM: {data['sleep_rem']:.1f}h")
        if data.get('sleep_awake', 0) > 0.5:
            print(f"  🌙 Despertares: {data['sleep_awake']:.1f}h")
        if t < 6: print(f"  🔴 Insuficiente")
        elif t < 7: print(f"  🟡 Corto")
        elif t < 9: print(f"  ✅ Bueno")
        else: print(f"  📊 Largo")
        if data['sleep_deep'] < 1.0: print(f"  ⚠️ Poco sueño profundo")
        elif data['sleep_deep'] > 2.0: print(f"  🏆 Excelente sueño profundo")
    else:
        print(f"  ⚠️ No disponible")
    
    print()
    print("=" * 60)
    print("✅ Reporte completado")

def print_weekly(client, days=7):
    """Print weekly summary with trends"""
    end = date.today()
    all_data = []
    
    print(f"📊 RESUMEN {'SEMANAL' if days == 7 else f'ÚLTIMOS {days} DÍAS'}")
    print(f"📅 {(end - timedelta(days=days-1)).strftime('%d/%m')} - {end.strftime('%d/%m/%Y')}")
    print("=" * 60)
    print()
    
    for i in range(days):
        day = end - timedelta(days=i)
        try:
            d = get_day_data(client, day.isoformat())
            all_data.append(d)
        except:
            pass
    
    if not all_data:
        print("❌ No se pudieron obtener datos")
        return
    
    # Activity summary
    total_steps = sum(d.get('steps', 0) for d in all_data)
    avg_steps = total_steps / len(all_data)
    total_dist = sum(d.get('distance', 0) for d in all_data)
    total_cal = sum(d.get('calories', 0) for d in all_data)
    
    print("🏃 ACTIVIDAD:")
    print(f"  👣 Total pasos: {total_steps:,} (promedio: {avg_steps:,.0f}/día)")
    print(f"  📏 Distancia total: {total_dist:.1f} km")
    print(f"  🔥 Calorías activas: {total_cal:,.0f}")
    
    sedentary = len([d for d in all_data if d.get('steps', 0) < 5000])
    active = len([d for d in all_data if d.get('steps', 0) >= 7500])
    print(f"  📊 Días activos (≥7.5k): {active}/{len(all_data)} | Sedentarios (<5k): {sedentary}/{len(all_data)}")
    
    best = max(all_data, key=lambda x: x.get('steps', 0))
    print(f"  🏆 Mejor día: {format_date(best['date'])} ({best.get('steps', 0):,} pasos)")
    print()
    
    # HR summary
    hr_days = [d for d in all_data if 'hr_min' in d]
    if hr_days:
        avg_rhr = sum(d['hr_min'] for d in hr_days) / len(hr_days)
        print("💓 HEART RATE:")
        print(f"  Reposo promedio: {avg_rhr:.0f} bpm")
        print(f"  Rango reposo: {min(d['hr_min'] for d in hr_days)}-{max(d['hr_min'] for d in hr_days)} bpm")
        print()
    
    # Stress summary
    stress_days = [d for d in all_data if 'stress' in d]
    if stress_days:
        avg_stress = sum(d['stress'] for d in stress_days) / len(stress_days)
        high = len([d for d in stress_days if d['stress'] >= 50])
        print("😰 ESTRÉS:")
        print(f"  Promedio: {avg_stress:.0f}")
        if high > 0:
            print(f"  ⚠️ Días con estrés alto: {high}/{len(stress_days)}")
        else:
            print(f"  ✅ Sin días de estrés alto")
        print()
    
    # Sleep summary
    sleep_days = [d for d in all_data if 'sleep_total' in d]
    if sleep_days:
        avg_sleep = sum(d['sleep_total'] for d in sleep_days) / len(sleep_days)
        avg_deep = sum(d['sleep_deep'] for d in sleep_days) / len(sleep_days)
        short = len([d for d in sleep_days if d['sleep_total'] < 6.5])
        print("😴 SUEÑO:")
        print(f"  Promedio: {avg_sleep:.1f}h/noche (profundo: {avg_deep:.1f}h)")
        if short > 0:
            print(f"  ⚠️ Noches cortas (<6.5h): {short}/{len(sleep_days)}")
        else:
            print(f"  ✅ Sueño consistente")
        print()
    
    # Body Battery
    bb_days = [d for d in all_data if 'battery_current' in d and d['battery_current'] is not None]
    if bb_days:
        avg_bb = sum(d['battery_current'] for d in bb_days) / len(bb_days)
        print("🔋 BODY BATTERY:")
        print(f"  Promedio: {avg_bb:.0f}/100")
        low = len([d for d in bb_days if d['battery_current'] < 25])
        if low > 0:
            print(f"  ⚠️ Días con batería baja: {low}/{len(bb_days)}")
        print()
    
    # Week-over-week comparison (if weekly mode and enough data)
    if days == 7:
        try:
            prev_data = []
            for i in range(7, 14):
                day = end - timedelta(days=i)
                prev_data.append(get_day_data(client, day.isoformat()))
            
            if prev_data:
                prev_steps = sum(d.get('steps', 0) for d in prev_data) / len(prev_data)
                diff = avg_steps - prev_steps
                pct = (diff / prev_steps * 100) if prev_steps > 0 else 0
                trend = "📈" if diff > 0 else "📉"
                print(f"📈 VS SEMANA ANTERIOR:")
                print(f"  Pasos: {trend} {diff:+,.0f}/día ({pct:+.1f}%)")
                
                prev_sleep = [d for d in prev_data if 'sleep_total' in d]
                if prev_sleep and sleep_days:
                    prev_avg_sleep = sum(d['sleep_total'] for d in prev_sleep) / len(prev_sleep)
                    sleep_diff = avg_sleep - prev_avg_sleep
                    trend = "📈" if sleep_diff > 0 else "📉"
                    print(f"  Sueño: {trend} {sleep_diff:+.1f}h/noche")
                print()
        except:
            pass
    
    print("=" * 60)
    print("✅ Resumen completado")

def print_current(data):
    """Print current/live status - compact format"""
    print(f"⚡ ESTADO ACTUAL - {datetime.now().strftime('%H:%M')}")
    print("=" * 40)
    
    if 'hr_latest' in data:
        print(f"💓 HR: {data['hr_latest']} bpm (reposo: {data.get('hr_min', '?')})")
    
    if 'battery_current' in data and data['battery_current'] is not None:
        bb = data['battery_current']
        icon = "🔴" if bb < 25 else "🟡" if bb < 50 else "🟢" if bb < 75 else "✅"
        print(f"🔋 Body Battery: {icon} {bb}/100")
    
    if 'stress' in data:
        s = data['stress']
        icon = "✅" if s < 25 else "📊" if s < 50 else "⚠️" if s < 75 else "🚨"
        print(f"😰 Estrés: {icon} {s}")
    
    print(f"👣 Pasos: {data.get('steps', 0):,}")
    
    if 'sleep_total' in data:
        print(f"😴 Sueño: {data['sleep_total']:.1f}h")
    
    print("=" * 40)

# Main
try:
    client = load_garmin_client()
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)

if MODE == "--daily" or MODE == "--current":
    target = "$DATE" if "$DATE" else date.today().isoformat()
    data = get_day_data(client, target)
    if MODE == "--current":
        print_current(data)
    else:
        print_daily(data)
elif MODE in ("--weekly", "--summary"):
    print_weekly(client, 7)

PYEOF
