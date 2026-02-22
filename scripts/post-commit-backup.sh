#!/bin/bash
# post-commit-backup.sh
# Hook ejecutado tras cada commit
# Si el commit es "importante", ejecuta backup automáticamente + registra en CHANGELOG.md

set -e

WORKSPACE="$HOME/.openclaw/workspace"
GIT_LOG=$(cd "$WORKSPACE" && git log -1 --pretty=format:"%s")
GIT_HASH=$(cd "$WORKSPACE" && git log -1 --pretty=format:"%h")
GIT_AUTHOR=$(cd "$WORKSPACE" && git log -1 --pretty=format:"%an")
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
BACKUP_DIR="$WORKSPACE/backups-by-commit"

# Emojis/patrones que marcan commits importantes
IMPORTANT_PATTERNS="🎯|📋|🔐|🤐|💾|📚|🛠️|⚙️|🔧|📢|🗺️|📖|✅|🚀|🔄|💡|🧠|⚡"

# Palabras clave que indican commits importantes
IMPORTANT_KEYWORDS="Implementar|Consolidar|Política|Crítico|Error|Seguridad|Cambio|Decisión|Arquitectura|Fix|Corregir|Agregar|Remover|Actualizar.*importante|Nueva.*política"

# Detectar si es commit importante
is_important() {
    local msg="$1"
    
    # Checar emojis
    if [[ "$msg" =~ $IMPORTANT_PATTERNS ]]; then
        return 0
    fi
    
    # Checar palabras clave
    if echo "$msg" | grep -qiE "$IMPORTANT_KEYWORDS"; then
        return 0
    fi
    
    return 1
}

# Si es importante, ejecutar backup y registrar changelog
if is_important "$GIT_LOG"; then
    # Crear directorio de backups por commit
    mkdir -p "$BACKUP_DIR"
    
    # Ejecutar backup
    echo "🔄 Commit importante detectado: $GIT_LOG"
    echo "📦 Ejecutando backup automático..."
    
    BACKUP_FILE="$WORKSPACE/memory/openclaw-backup-${GIT_HASH}.tar.gz"
    bash "$WORKSPACE/scripts/backup-memory.sh" > /dev/null 2>&1
    
    # Obtener el backup más reciente
    LATEST_BACKUP=$(ls -t "$WORKSPACE"/memory/openclaw-backup-*.tar.gz 2>/dev/null | head -1)
    
    if [ -n "$LATEST_BACKUP" ]; then
        # Copiar a carpeta de backups por commit con nombre estructurado
        cp "$LATEST_BACKUP" "$BACKUP_DIR/backup-${GIT_HASH}-$(date '+%Y%m%d-%H%M%S').tar.gz"
        echo "✅ Backup creado: $LATEST_BACKUP"
    fi
    
    # Registrar en CHANGELOG.md
    CHANGELOG_FILE="$WORKSPACE/CHANGELOG.md"
    
    # Si CHANGELOG no existe, crear con header
    if [ ! -f "$CHANGELOG_FILE" ]; then
        cat > "$CHANGELOG_FILE" << 'EOF'
# CHANGELOG — Historia de cambios importantes

Registro automático de commits importantes con backups asociados.
Formato: fecha | mensaje del commit | hash | backup

---

## 2026-02-22 y posteriores

EOF
    fi
    
    # Agregar entrada al changelog
    cat >> "$CHANGELOG_FILE" << EOF
- **$TIMESTAMP** | $GIT_LOG | \`$GIT_HASH\` | [\`backup-$GIT_HASH\`](backups-by-commit/backup-${GIT_HASH}*.tar.gz)

EOF
    
    echo "📝 CHANGELOG actualizado"
    
fi

exit 0
