#!/usr/bin/env bash
# deliver-pending-reports.sh
# Lee reportes pendientes de la noche (memory/pending-reports/) y los entrega a Telegram
set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
PENDING_DIR="$WORKSPACE/memory/pending-reports"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# Si no hay reportes pendientes, salir silenciosamente
if [ ! -d "$PENDING_DIR" ] || [ -z "$(ls -A "$PENDING_DIR" 2>/dev/null)" ]; then
    exit 0
fi

# Contar archivos ANTES de procesar
count=$(ls -1 "$PENDING_DIR"/*.md 2>/dev/null | wc -l)
if [ "$count" -eq 0 ]; then
    exit 0
fi

# Agregar todos los reportes pendientes a temp file
{
    echo "📦 Reportes de la noche ($count archivos)"
    echo ""
    find "$PENDING_DIR" -maxdepth 1 -name "*.md" -type f | sort | while read -r file; do
        echo "---"
        cat "$file"
        echo ""
    done
} > "$TEMP_FILE"

# Si hay contenido, enviar a Telegram
if [ -s "$TEMP_FILE" ]; then
    cat "$TEMP_FILE"  # Output para el handler de Telegram via cron
    
    # Limpiar directorio SOLO si todo fue ok
    rm -f "$PENDING_DIR"/*.md
    echo "✅ $count reportes procesados y enviados" >&2
fi

exit 0
