#!/bin/bash
# deliver-pending-reports.sh
# Lee reportes pendientes de la noche (memory/pending-reports/) y los entrega a Telegram

set -e

PENDING_DIR="$HOME/.openclaw/workspace/memory/pending-reports"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

# Si no hay reportes pendientes, salir
if [ ! -d "$PENDING_DIR" ] || [ -z "$(ls -A "$PENDING_DIR" 2>/dev/null)" ]; then
    exit 0
fi

# Agregar todos los reportes pendientes
AGGREGATE=""
for file in "$PENDING_DIR"/*.md; do
    if [ -f "$file" ]; then
        AGGREGATE+=$'\n---\n'
        AGGREGATE+="$(cat "$file")"
    fi
done

# Si hay contenido, enviar a Telegram
if [ -n "$AGGREGATE" ]; then
    # Contar archivos procesados
    count=$(ls -1 "$PENDING_DIR"/*.md 2>/dev/null | wc -l)
    
    # Preparar mensaje para Telegram
    MESSAGE="📦 Reportes de la noche ($count archivos agregados)${AGGREGATE}"
    
    # Enviar via OpenClaw message tool (será manejado por el cron con delivery)
    echo "$MESSAGE"
    
    # Limpiar directorio
    rm -f "$PENDING_DIR"/*.md
fi

exit 0
