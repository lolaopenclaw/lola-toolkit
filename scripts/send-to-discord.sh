#!/bin/bash
# send-to-discord.sh
# Envía mensajes formateados a Discord vía webhook

set -e

# Cargar variables desde .env
if [ -f "$HOME/.openclaw/.env" ]; then
    export $(grep -v '^#' "$HOME/.openclaw/.env" | xargs)
fi

# Validar que tenemos los datos necesarios
if [ -z "$DISCORD_BOT_TOKEN" ] || [ -z "$DISCORD_CHANNEL_ID" ]; then
    echo "❌ Error: Faltan DISCORD_BOT_TOKEN o DISCORD_CHANNEL_ID en .env"
    exit 1
fi

# Obtener el mensaje del argumento
MESSAGE="${1:-}"

if [ -z "$MESSAGE" ]; then
    echo "❌ Uso: send-to-discord.sh 'mensaje' [embed_color]"
    exit 1
fi

# Color opcional (default azul)
COLOR="${2:-3447003}"

# Crear el embed
EMBED=$(cat <<EOF
{
  "content": "",
  "embeds": [
    {
      "description": "$MESSAGE",
      "color": $COLOR,
      "timestamp": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    }
  ]
}
EOF
)

# Enviar a Discord
RESPONSE=$(curl -s -X POST "https://discord.com/api/v10/channels/$DISCORD_CHANNEL_ID/messages" \
  -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$EMBED")

# Validar respuesta
if echo "$RESPONSE" | jq . > /dev/null 2>&1; then
    MSG_ID=$(echo "$RESPONSE" | jq -r '.id')
    if [ "$MSG_ID" != "null" ] && [ -n "$MSG_ID" ]; then
        echo "✅ Mensaje enviado a Discord (ID: $MSG_ID)"
        exit 0
    fi
fi

echo "❌ Error enviando a Discord:"
echo "$RESPONSE"
exit 1
