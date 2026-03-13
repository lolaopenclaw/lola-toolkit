#!/bin/bash
# send-informe-to-discord.sh
# Envía informe matutino a Discord con embeds bonitos

set -e

# Cargar variables desde .env
if [ -f "$HOME/.openclaw/.env" ]; then
    export $(grep -v '^#' "$HOME/.openclaw/.env" | xargs)
fi

# Validar credenciales
if [ -z "$DISCORD_BOT_TOKEN" ] || [ -z "$DISCORD_CHANNEL_ID" ]; then
    echo "❌ Error: Faltan credenciales Discord en .env"
    exit 1
fi

# El informe viene como argumento (stdin o $1)
INFORME="${1:-}"

if [ -z "$INFORME" ]; then
    echo "❌ Uso: send-informe-to-discord.sh 'informe completo'"
    exit 1
fi

# Crear embeds para Discord (máximo 2000 caracteres por embed)
# Dividir informe en partes si es necesario

python3 <<'PYSCRIPT'
import json
import sys
import os
from datetime import datetime

informe = os.environ.get('INFORME', '')
token = os.environ.get('DISCORD_BOT_TOKEN')
channel_id = os.environ.get('DISCORD_CHANNEL_ID')

if not informe or not token or not channel_id:
    print("❌ Error: variables vacías")
    sys.exit(1)

# Dividir informe en bloques (máx 2000 caracteres por embed)
lines = informe.split('\n')
current_block = []
blocks = []
current_length = 0

for line in lines:
    line_length = len(line) + 1  # +1 para el \n
    if current_length + line_length > 1950:  # Margen de seguridad
        blocks.append('\n'.join(current_block))
        current_block = [line]
        current_length = line_length
    else:
        current_block.append(line)
        current_length += line_length

if current_block:
    blocks.append('\n'.join(current_block))

# Crear embeds
embeds = []
for i, block in enumerate(blocks):
    embed = {
        "title": f"📊 Informe Matutino (Parte {i+1}/{len(blocks)})" if len(blocks) > 1 else "📊 Informe Matutino",
        "description": block,
        "color": 3447003,  # Azul
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }
    embeds.append(embed)

# Payload para Discord
payload = {
    "content": "",
    "embeds": embeds
}

print(json.dumps(payload))
PYSCRIPT
)

# Guardar payload en variable
PAYLOAD=$(python3 <<'PYSCRIPT'
import json
import os
from datetime import datetime

informe = """$INFORME"""
token = os.environ.get('DISCORD_BOT_TOKEN')
channel_id = os.environ.get('DISCORD_CHANNEL_ID')

# Dividir informe en bloques
lines = informe.split('\n')
current_block = []
blocks = []
current_length = 0

for line in lines:
    line_length = len(line) + 1
    if current_length + line_length > 1950:
        if current_block:
            blocks.append('\n'.join(current_block))
        current_block = [line]
        current_length = line_length
    else:
        current_block.append(line)
        current_length += line_length

if current_block:
    blocks.append('\n'.join(current_block))

# Crear embeds
embeds = []
for i, block in enumerate(blocks):
    embed = {
        "title": f"📊 Informe Matutino (Parte {i+1}/{len(blocks)})" if len(blocks) > 1 else "📊 Informe Matutino",
        "description": block,
        "color": 3447003,
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }
    embeds.append(embed)

payload = {"content": "", "embeds": embeds}
print(json.dumps(payload))
PYSCRIPT
)

# Enviar a Discord
RESPONSE=$(curl -s -X POST "https://discord.com/api/v10/channels/$DISCORD_CHANNEL_ID/messages" \
  -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

# Validar respuesta
if echo "$RESPONSE" | jq . > /dev/null 2>&1; then
    MSG_ID=$(echo "$RESPONSE" | jq -r '.id')
    if [ "$MSG_ID" != "null" ] && [ -n "$MSG_ID" ]; then
        echo "✅ Informe enviado a Discord (ID: $MSG_ID)"
        exit 0
    fi
fi

echo "❌ Error enviando a Discord:"
echo "$RESPONSE"
exit 1
