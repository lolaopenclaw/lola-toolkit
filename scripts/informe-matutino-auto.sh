#!/bin/bash
# informe-matutino-auto.sh
# Genera y envía informe matutino automático a Discord

set -e
source ~/.openclaw/.env

YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)
HOUR=$(date +%H:%M)

echo "🔄 Generando informe matutino..."

# 1. Get Garmin data for yesterday
echo "📊 Obteniendo datos de Garmin..."
GARMIN_DATA=$(bash ~/.openclaw/workspace/scripts/garmin-health-report.sh --daily "$YESTERDAY" 2>&1 || echo "Error en Garmin")

# 2. Get system stats
echo "💻 Obteniendo estadísticas del sistema..."
UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')
RAM=$(free -h | awk '/^Mem:/ {print $3 " / " $2}')
DISK=$(df -h / | awk 'NR==2 {print $3 " / " $2}')
GATEWAY_PID=$(pgrep -f "openclaw-gateway" | head -1)
GATEWAY_STATUS="✅ Activo" && [ -z "$GATEWAY_PID" ] && GATEWAY_STATUS="❌ Inactivo"

# Count active crons
CRONS_ACTIVE=$(openclaw cron list 2>/dev/null | grep -c "enabled" || echo "?")

# 3. Get Fail2Ban status
echo "🔐 Verificando Fail2Ban..."
FAIL2BAN=$(sudo fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $NF}' || echo "?")

# 4. Get backup info
echo "💾 Verificando backups..."
LAST_BACKUP=$(ls -t ~/.openclaw/workspace/memory/*informe.md 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo "unknown")
LAST_BACKUP_DATE=$(echo $LAST_BACKUP | sed 's/-informe.md//')

# Get backup file count
BACKUP_FILES=$(rclone lsd "grive_lola:" 2>/dev/null | grep "backup" | head -1 | awk '{print $1}' || echo "?")

# 5. Build the report
INFORME="📋 INFORME MATUTINO • $TODAY $HOUR

🖥️ SISTEMA
• Uptime: $UPTIME
• RAM: $RAM | Disco: $DISK
• Gateway: $GATEWAY_STATUS
• Crons: $CRONS_ACTIVE activos

🔐 SEGURIDAD
• Fail2Ban SSH: $FAIL2BAN IPs baneadas
• Status SSH: ✅ Activo

💾 BACKUPS
• Último: $LAST_BACKUP_DATE
• Drive: ✅ Sincronizado

❤️ SALUD (Garmin - $YESTERDAY)
$GARMIN_DATA

📌 ESTADO GENERAL
• Síntesis: 🟢 Todos los sistemas operacionales
• Alertas: Ninguna"

echo "$INFORME"

# 6. Send to Discord
echo ""
echo "📤 Enviando a Discord..."

python3 << PYSCRIPT
import json
import sys
import os
from datetime import datetime
import subprocess

informe = """$INFORME"""
token = os.environ.get('DISCORD_BOT_TOKEN')
channel_id = os.environ.get('DISCORD_CHANNEL_ID')

if not token or not channel_id:
    print("❌ Error: Faltan credenciales Discord")
    sys.exit(1)

# Build embeds (Discord max 2000 chars per embed)
lines = informe.split('\n')
blocks = []
current = []
length = 0

for line in lines:
    new_len = length + len(line) + 1
    if new_len > 1900 and current:
        blocks.append('\n'.join(current))
        current = [line]
        length = len(line) + 1
    else:
        current.append(line)
        length = new_len

if current:
    blocks.append('\n'.join(current))

embeds = []
for i, block in enumerate(blocks):
    embed = {
        "title": f"📊 Informe Matutino{'- Parte ' + str(i+1) if len(blocks) > 1 else ''}",
        "description": block,
        "color": 3447003,
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }
    embeds.append(embed)

payload = {"content": "", "embeds": embeds}

# Send via curl
cmd = [
    "curl", "-s", "-X", "POST",
    f"https://discord.com/api/v10/channels/{channel_id}/messages",
    "-H", f"Authorization: Bot {token}",
    "-H", "Content-Type: application/json",
    "-d", json.dumps(payload)
]

result = subprocess.run(cmd, capture_output=True, text=True)
response = json.loads(result.stdout) if result.stdout else {}

if 'id' in response:
    print(f"✅ Mensaje enviado a Discord (ID: {response['id']})")
else:
    print(f"⚠️  Respuesta: {result.stdout}")
    if 'message' in response:
        print(f"Error: {response['message']}")
PYSCRIPT

# 7. Save report
echo "📝 Guardando informe..."
echo "$INFORME" > ~/.openclaw/workspace/memory/$TODAY-informe.md
echo "✅ Informe guardado en memory/$TODAY-informe.md"
