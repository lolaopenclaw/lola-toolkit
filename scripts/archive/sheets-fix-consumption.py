#!/usr/bin/env python3
"""
Cargar datos de consumo correctamente en Google Sheets usando googleapiclient
"""

import os
import json
from datetime import datetime, timedelta
from pathlib import Path

try:
    from googleapiclient.discovery import build
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials
except ImportError:
    print("❌ Instala: pip install google-auth-oauthlib google-api-python-client")
    exit(1)

CONSUMO_SHEET_ID = "1Fs9L4DNG81pzeLNSMDZhQsqqNwYz0TYMEQrAzCoSf6Y"

# Datos de consumo por modelo (últimos 8 días)
DATA = [
    ["Fecha", "Haiku", "Sonnet", "Opus", "Gemini", "Total", "Requests"],
    ["2026-02-15", 2.50, 5.20, 35.80, 1.50, 45.00, 245],
    ["2026-02-16", 1.20, 2.10, 18.50, 0.80, 22.60, 128],
    ["2026-02-17", 0.95, 1.80, 12.30, 0.50, 15.55, 95],
    ["2026-02-18", 3.40, 8.60, 42.10, 2.30, 56.40, 298],
    ["2026-02-19", 2.10, 6.80, 38.90, 1.70, 49.50, 267],
    ["2026-02-20", 4.20, 12.50, 78.60, 4.80, 100.10, 533],
    ["2026-02-21", 1.81, 0.00, 0.00, 0.00, 1.81, 68],
    ["2026-02-22", 0.60, 1.20, 8.40, 0.35, 10.55, 58],
]

print("🔧 Intentando conectar a Google Sheets API...")

try:
    # Buscar credenciales desde gog
    creds_path = Path.home() / ".config" / "gog" / "credentials.json"
    
    if not creds_path.exists():
        print(f"❌ Credenciales no encontradas: {creds_path}")
        print("   Intenta: gog auth add lolaopenclaw@gmail.com")
        exit(1)
    
    # Cargar credenciales
    with open(creds_path) as f:
        creds_data = json.load(f)
    
    # Crear servicio
    service = build('sheets', 'v4', credentials=creds_data.get('credentials'))
    
    print("✓ Conectado a Google Sheets API")
    
    # Limpiar Sheet
    print("\n🧹 Limpiando Sheet...")
    service.spreadsheets().batchUpdate(
        spreadsheetId=CONSUMO_SHEET_ID,
        body={"requests": [{"deleteRange": {"range": {"sheetId": 0}, "shiftDimension": "ROWS"}}]}
    ).execute()
    
    # Cargar datos
    print("📝 Cargando datos...")
    service.spreadsheets().values().update(
        spreadsheetId=CONSUMO_SHEET_ID,
        range="Hoja 1!A1:G9",
        valueInputOption="USER_ENTERED",
        body={"values": DATA}
    ).execute()
    
    print("✅ Datos cargados correctamente en columnas separadas")
    print("\n📊 Estructura:")
    print("   A: Fecha")
    print("   B: Haiku ($)")
    print("   C: Sonnet ($)")
    print("   D: Opus ($)")
    print("   E: Gemini ($)")
    print("   F: Total ($)")
    print("   G: Requests (#)")
    
except Exception as e:
    print(f"❌ Error: {e}")
    print("\n💡 Alternativa: Usa gog sheets append de forma manual:")
    print("   gog sheets append SHEET_ID RANGO valor1 valor2 valor3...")
    exit(1)
