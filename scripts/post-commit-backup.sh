#!/bin/bash
# post-commit-backup.sh
# Hook ejecutado tras cada commit
# Si el commit es "importante", ejecuta backup automáticamente + registra en CHANGELOG.md

set -euo pipefail

# === DEPENDENCY CHECK ===
if [ ! -f "$HOME/.openclaw/workspace/scripts/backup-memory.sh" ]; then
    echo "⚠️  backup-memory.sh not found. Post-commit backup skipped." >&2
    exit 0
fi

for cmd in git date tar; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "⚠️  '$cmd' not found. Post-commit backup skipped." >&2
        exit 0
    fi
done

WORKSPACE="$HOME/.openclaw/workspace"
GIT_LOG=$(cd "$WORKSPACE" && git log -1 --pretty=format:"%s" 2>/dev/null || echo "unknown")
GIT_HASH=$(cd "$WORKSPACE" && git log -1 --pretty=format:"%h" 2>/dev/null || echo "????")
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
    
    if bash "$WORKSPACE/scripts/backup-memory.sh" > /tmp/backup.log 2>&1; then
        # Obtener el backup más reciente
        LATEST_BACKUP=$(ls -t "$WORKSPACE"/memory/openclaw-backup-*.tar.gz 2>/dev/null | head -1)
        
        if [ -n "$LATEST_BACKUP" ]; then
            # Copiar a carpeta de backups por commit con nombre estructurado
            cp "$LATEST_BACKUP" "$BACKUP_DIR/backup-${GIT_HASH}-$(date '+%Y%m%d-%H%M%S').tar.gz"
            echo "✅ Backup creado: $LATEST_BACKUP"
        else
            echo "⚠️  Backup created but archive not found in expected location"
        fi
    else
        echo "⚠️  Backup failed (see /tmp/backup.log for details)"
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
