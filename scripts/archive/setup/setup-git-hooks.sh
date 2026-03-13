#!/bin/bash
# setup-git-hooks.sh
# Instala/reinstala git hooks post-restore
# Ejecutar tras cada restore.sh

set -e

WORKSPACE="$HOME/.openclaw/workspace"
GIT_HOOKS_DIR="$WORKSPACE/.git/hooks"

echo "🔧 Configurando git hooks..."

# Crear directorio si no existe
mkdir -p "$GIT_HOOKS_DIR"

# Instalar post-commit hook
cat > "$GIT_HOOKS_DIR/post-commit" << 'EOF'
#!/bin/bash
# Git hook: post-commit
# Ejecutado automáticamente tras cada commit
# Detecta commits importantes y ejecuta backup

bash "$HOME/.openclaw/workspace/scripts/post-commit-backup.sh"
EOF

chmod +x "$GIT_HOOKS_DIR/post-commit"

echo "✅ Git hook post-commit instalado"
echo "   Ubicación: $GIT_HOOKS_DIR/post-commit"
echo "   El sistema de backup post-commit ya está activo"

exit 0
