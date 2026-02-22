#!/bin/bash
# share-drive-folder.sh
# Compartir carpeta Google Drive usando GOG (nativo)

set -e

# Parámetros
FOLDER_ID="${1:-}"
EMAIL="${2:-}"
ROLE="${3:-reader}"  # reader, commenter, writer
ACCOUNT="${4:-lolaopenclaw@gmail.com}"

if [ -z "$FOLDER_ID" ] || [ -z "$EMAIL" ]; then
    echo "❌ Uso: share-drive-folder.sh <FOLDER_ID> <EMAIL> [ROLE] [ACCOUNT]"
    echo "  ROLE: reader (default), commenter, writer"
    echo "  ACCOUNT: lolaopenclaw@gmail.com (default)"
    exit 1
fi

echo "📤 Compartiendo carpeta $FOLDER_ID con $EMAIL ($ROLE)..."

# Usar GOG command nativo
RESULT=$(gog drive share "$FOLDER_ID" --email="$EMAIL" --role="$ROLE" --account="$ACCOUNT" 2>&1)

if echo "$RESULT" | grep -q "permission_id"; then
    PERM_ID=$(echo "$RESULT" | grep "permission_id" | awk '{print $NF}')
    LINK=$(echo "$RESULT" | grep "link" | awk '{print $NF}')
    
    echo "✅ Carpeta compartida exitosamente!"
    echo "   Permiso ID: $PERM_ID"
    echo "   Email: $EMAIL"
    echo "   Rol: $ROLE"
    echo "   Link: $LINK"
    exit 0
else
    echo "❌ Error compartiendo carpeta:"
    echo "$RESULT"
    exit 1
fi
