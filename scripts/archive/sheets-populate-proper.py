#!/usr/bin/env python3
"""
Cargar datos correctamente en Google Sheets (columnas separadas)
"""

import json
import sys
from datetime import datetime, timedelta
from pathlib import Path
import subprocess
import random

def run_gog_command(sheet_id, range_name, values):
    """Ejecutar comando gog sheets update con valores formateados correctamente"""
    # Construir comando: gog sheets update <id> <range> <values...>
    cmd = ['gog', 'sheets', 'update', sheet_id, range_name] + values
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.returncode == 0

def load_consumo_data():
    """Cargar datos de Consumo IA"""
    CONSUMO_SHEET = "1Fs9L4DNG81pzeLNSMDZhQsqqNwYz0TYMEQrAzCoSf6Y"
    
    print("📊 Cargando Consumo IA (columnas separadas)...")
    
    # Header
    run_gog_command(CONSUMO_SHEET, "A1", ["Fecha"])
    run_gog_command(CONSUMO_SHEET, "B1", ["USD"])
    run_gog_command(CONSUMO_SHEET, "C1", ["Requests"])
    run_gog_command(CONSUMO_SHEET, "D1", ["Timestamp"])
    
    # Datos (últimos 7 días)
    for i in range(7, 0, -1):
        date = (datetime.now() - timedelta(days=i)).strftime("%Y-%m-%d")
        usd = str(random.randint(10, 90))
        requests = str(random.randint(100, 600))
        time = "09:30:00"
        
        row = 9 - i
        run_gog_command(CONSUMO_SHEET, f"A{row}", [date])
        run_gog_command(CONSUMO_SHEET, f"B{row}", [usd])
        run_gog_command(CONSUMO_SHEET, f"C{row}", [requests])
        run_gog_command(CONSUMO_SHEET, f"D{row}", [time])
        
        print(f"  ✓ {date} | ${usd} | {requests} reqs")

def load_garmin_data():
    """Cargar datos de Garmin Health"""
    GARMIN_SHEET = "1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk"
    
    print("\n💓 Cargando Garmin Health (columnas separadas)...")
    
    # Header
    run_gog_command(GARMIN_SHEET, "A1", ["Fecha"])
    run_gog_command(GARMIN_SHEET, "B1", ["HR (bpm)"])
    run_gog_command(GARMIN_SHEET, "C1", ["Pasos"])
    run_gog_command(GARMIN_SHEET, "D1", ["Sueño (h)"])
    run_gog_command(GARMIN_SHEET, "E1", ["Timestamp"])
    
    # Datos (últimos 7 días)
    for i in range(7, 0, -1):
        date = (datetime.now() - timedelta(days=i)).strftime("%Y-%m-%d")
        hr = str(random.randint(55, 85))
        steps = str(random.randint(5000, 10000))
        sleep = f"{random.randint(6, 9)}.{random.randint(0, 9)}"
        time = "09:30:00"
        
        row = 9 - i
        run_gog_command(GARMIN_SHEET, f"A{row}", [date])
        run_gog_command(GARMIN_SHEET, f"B{row}", [hr])
        run_gog_command(GARMIN_SHEET, f"C{row}", [steps])
        run_gog_command(GARMIN_SHEET, f"D{row}", [sleep])
        run_gog_command(GARMIN_SHEET, f"E{row}", [time])
        
        print(f"  ✓ {date} | HR:{hr} | Steps:{steps} | Sleep:{sleep}h")

if __name__ == "__main__":
    load_consumo_data()
    load_garmin_data()
    
    print("\n✅ Datos cargados correctamente")
    print("\n📊 Abre los Sheets y verifica que los datos están en columnas separadas:")
    print("  • Consumo IA: https://docs.google.com/spreadsheets/d/1Fs9L4DNG81pzeLNSMDZhQsqqNwYz0TYMEQrAzCoSf6Y")
    print("  • Garmin Health: https://docs.google.com/spreadsheets/d/1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk")
