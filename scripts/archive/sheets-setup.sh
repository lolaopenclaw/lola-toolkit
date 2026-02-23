#!/bin/bash
# Setup Google Sheets automation

set -e

CLIENT_SECRET="$HOME/.openclaw/workspace/temp/client_secret.json"
CONFIG_DIR="$HOME/.config/gog"

echo "🔐 Google Sheets Setup"
echo ""

# 1. Copiar client_secret.json a config
mkdir -p "$CONFIG_DIR"
cp "$CLIENT_SECRET" "$CONFIG_DIR/client_secret.json"
echo "✓ client_secret.json guardado en $CONFIG_DIR"

# 2. Autenticar con gog
echo ""
echo "🔑 Autenticando con Google..."
gog auth credentials "$CONFIG_DIR/client_secret.json"

# 3. Añadir cuenta con permisos de Sheets + Drive
echo ""
echo "📊 Añadiendo cuenta lolaopenclaw@gmail.com..."
gog auth add lolaopenclaw@gmail.com --services gmail,calendar,drive,sheets,docs

# 4. Verificar acceso
echo ""
echo "✓ Verificando acceso a Sheets..."
gog sheets list --max 5

echo ""
echo "✅ Setup completo. Listo para automatizar Sheets."
