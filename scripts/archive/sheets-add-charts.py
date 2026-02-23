#!/usr/bin/env python3
"""
Crear gráficas automáticas en Google Sheets usando google-api-python-client
"""

import json
import os
import sys
from pathlib import Path

try:
    from google.auth.transport.requests import Request
    from google.oauth2.service_account import Credentials
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
except ImportError:
    print("❌ Librerías de Google no instaladas")
    print("   Instalando: pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client")
    sys.exit(1)

CONSUMO_SHEET = "1Fs9L4DNG81pzeLNSMDZhQsqqNwYz0TYMEQrAzCoSf6Y"
GARMIN_SHEET = "1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk"

print("📊 Creando gráficas con Google Sheets API...")

# Intentar cargar credenciales desde gog
creds_path = Path.home() / ".config" / "gog" / "credentials.json"

if not creds_path.exists():
    print(f"❌ Credenciales no encontradas en {creds_path}")
    print("   Necesitas: gog auth add lolaopenclaw@gmail.com")
    sys.exit(1)

try:
    # Cargar credenciales
    with open(creds_path, 'r') as f:
        creds_data = json.load(f)
    
    # Crear cliente Sheets
    service = build('sheets', 'v4', credentials=creds_data.get('credentials'))
    
    print("✓ Credenciales cargadas")
    
except Exception as e:
    print(f"❌ Error al cargar credenciales: {e}")
    sys.exit(1)

# ============================================
# 1. CONSUMO IA - Gráfica de línea
# ============================================

print("\n1️⃣ Consumo IA (gráfica de línea)...")

chart_request = {
    "requests": [
        {
            "addChart": {
                "chart": {
                    "spec": {
                        "title": "Consumo IA - Últimos 7 días",
                        "basicChart": {
                            "chartType": "LINE",
                            "legendPosition": "BOTTOM_LEGEND",
                            "axis": [
                                {"position": "BOTTOM_AXIS", "title": "Fecha"},
                                {"position": "LEFT_AXIS", "title": "USD"}
                            ],
                            "series": [
                                {
                                    "series": {"sheetId": 0, "rowIndex": 0, "columnIndex": 1},
                                    "targetAxis": 0
                                }
                            ],
                            "domains": [
                                {"domain": {"sheetId": 0, "rowIndex": 0, "columnIndex": 0}}
                            ]
                        }
                    },
                    "position": {
                        "overlayPosition": {
                            "anchorCell": {"sheetId": 0, "rowIndex": 0, "columnIndex": 4}
                        }
                    }
                }
            }
        }
    ]
}

try:
    service.spreadsheets().batchUpdate(
        spreadsheetId=CONSUMO_SHEET,
        body=chart_request
    ).execute()
    print("  ✓ Gráfica creada")
except Exception as e:
    print(f"  ⚠️ {e}")

# ============================================
# 2. GARMIN HEALTH - Gráfica multi-serie
# ============================================

print("\n2️⃣ Garmin Health (gráfica multi-serie)...")

garmin_chart_request = {
    "requests": [
        {
            "addChart": {
                "chart": {
                    "spec": {
                        "title": "Garmin Health - Últimos 7 días",
                        "basicChart": {
                            "chartType": "COMBO",
                            "legendPosition": "BOTTOM_LEGEND",
                            "axis": [
                                {"position": "BOTTOM_AXIS", "title": "Fecha"},
                                {"position": "LEFT_AXIS", "title": "HR (bpm) / Pasos"},
                                {"position": "RIGHT_AXIS", "title": "Sueño (h)"}
                            ],
                            "series": [
                                {
                                    "series": {"sheetId": 0, "rowIndex": 0, "columnIndex": 1},
                                    "targetAxis": 0
                                },
                                {
                                    "series": {"sheetId": 0, "rowIndex": 0, "columnIndex": 2},
                                    "targetAxis": 0
                                },
                                {
                                    "series": {"sheetId": 0, "rowIndex": 0, "columnIndex": 3},
                                    "targetAxis": 1
                                }
                            ],
                            "domains": [
                                {"domain": {"sheetId": 0, "rowIndex": 0, "columnIndex": 0}}
                            ]
                        }
                    },
                    "position": {
                        "overlayPosition": {
                            "anchorCell": {"sheetId": 0, "rowIndex": 0, "columnIndex": 5}
                        }
                    }
                }
            }
        }
    ]
}

try:
    service.spreadsheets().batchUpdate(
        spreadsheetId=GARMIN_SHEET,
        body=garmin_chart_request
    ).execute()
    print("  ✓ Gráfica creada")
except Exception as e:
    print(f"  ⚠️ {e}")

print("\n✅ Gráficas creadas")
print("\n📱 Abre en Google Sheets:")
print(f"  • Consumo IA: https://docs.google.com/spreadsheets/d/{CONSUMO_SHEET}")
print(f"  • Garmin Health: https://docs.google.com/spreadsheets/d/{GARMIN_SHEET}")
