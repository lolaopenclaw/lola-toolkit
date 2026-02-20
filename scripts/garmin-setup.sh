#!/bin/bash
set -euo pipefail

echo "🔐 Garmin Connect - Obtener OAuth Tokens"
echo "==========================================="
echo ""
echo "Este script te ayudará a obtener tokens de Garmin Connect"
echo "Tu password NO se guarda - solo se usa para obtener los tokens"
echo ""

# Leer credenciales
read -p "Email de Garmin Connect: " GARMIN_EMAIL
read -sp "Password de Garmin Connect: " GARMIN_PASSWORD
echo ""
echo ""
echo "⏳ Conectando a Garmin Connect..."

# Ejecutar Python para obtener tokens
python3 << EOF
import sys
from garminconnect import Garmin

try:
    # Login
    client = Garmin("$GARMIN_EMAIL", "$GARMIN_PASSWORD")
    client.login()
    
    # Obtener tokens
    oauth1 = client.session_data.get('oauth1_token', '')
    oauth2 = client.session_data.get('oauth2_token', '')
    
    if not oauth1 or not oauth2:
        print("❌ Error: No se pudieron obtener los tokens")
        print("   Verifica tu email y password")
        sys.exit(1)
    
    # Guardar en .env
    env_file = "/home/mleon/.openclaw/.env"
    
    # Leer .env actual
    with open(env_file, 'r') as f:
        lines = f.readlines()
    
    # Eliminar líneas viejas de Garmin si existen
    lines = [l for l in lines if not l.startswith('GARMIN_')]
    
    # Añadir nuevos tokens
    lines.append(f"GARMIN_EMAIL={client.email}\n")
    lines.append(f"GARMIN_OAUTH1_TOKEN={oauth1}\n")
    lines.append(f"GARMIN_OAUTH2_TOKEN={oauth2}\n")
    
    # Escribir
    with open(env_file, 'w') as f:
        f.writelines(lines)
    
    print("✅ Tokens guardados correctamente en .env")
    print("")
    print("OAuth1 Token (primeros 20 caracteres):", oauth1[:20] + "...")
    print("OAuth2 Token (primeros 20 caracteres):", oauth2[:20] + "...")
    print("")
    print("🔒 Tu password NO fue guardado")
    print("✨ Lola ahora puede acceder a tus datos de Garmin")
    
except Exception as e:
    print(f"❌ Error: {e}")
    print("")
    print("Posibles causas:")
    print("  - Email o password incorrectos")
    print("  - Garmin Connect temporalmente inaccesible")
    print("  - Necesitas verificar tu cuenta (revisa email de Garmin)")
    sys.exit(1)
EOF

# Limpiar variables
unset GARMIN_EMAIL
unset GARMIN_PASSWORD

echo ""
echo "🎉 ¡Configuración completada!"
echo ""
echo "Ahora Lola puede leer tus datos de Garmin usando los tokens OAuth."
echo "Los tokens se renuevan automáticamente."
echo ""
echo "Si quieres revocar el acceso más adelante:"
echo "  1. Elimina las líneas GARMIN_* de ~/.openclaw/.env"
echo "  2. Cambia tu password en Garmin Connect (opcional)"
