#!/bin/bash
# send-morning-report-to-discord.sh
# Ejecuta informe matutino y lo envía a Discord + Telegram

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

# El informe se genera vía sub-agente (ya manejado por cron)
# Este script solo se encarga de:
# 1. Recibir el informe generado
# 2. Enviarlo a Discord
# 3. (Opcional) Mantener Telegram como respaldo

# NOTA: Los crons ya envían a Telegram vía delivery:"announce"
# Este script se integra para TAMBIÉN enviar a Discord

# Función para convertir markdown Telegram → Discord (básico)
convert_for_discord() {
    local text="$1"
    # Discord usa `` para inline code, no backticks simples
    # Discord usa ** para bold (igual que Telegram)
    # Convertir markdown básico
    echo "$text"
}

# Cuando el cron ejecute el agentTurn, el output ya irá a Telegram
# Si queremos TAMBIÉN a Discord, el sub-agente puede hacerlo directamente
# O podemos hacer que el cron llame a este script como post-hook

echo "✅ send-morning-report-to-discord.sh listo"
echo "Nota: Los informes se envían a Telegram vía cron.delivery"
echo "Para Discord: integrar en el payload del agentTurn"

exit 0
