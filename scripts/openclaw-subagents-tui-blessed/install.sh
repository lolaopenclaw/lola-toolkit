#!/usr/bin/env bash
# OpenClaw Subagents Dashboard - Installation Script
# Usage: ./install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🦞 OpenClaw Subagents Dashboard - Installation"
echo "=============================================="
echo

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Error: Node.js not found"
    echo "   Please install Node.js: https://nodejs.org/"
    exit 1
fi

NODE_VERSION=$(node -v)
echo "✅ Node.js found: $NODE_VERSION"

# Check npm
if ! command -v npm &> /dev/null; then
    echo "❌ Error: npm not found"
    exit 1
fi

echo "✅ npm found"

# Check OpenClaw
if ! command -v openclaw &> /dev/null; then
    echo "⚠️  Warning: openclaw command not found in PATH"
    echo "   Make sure OpenClaw is installed and accessible"
    echo
fi

# Install dependencies
echo
echo "📦 Installing dependencies..."
cd "$SCRIPT_DIR"

if npm install; then
    echo "✅ Dependencies installed"
else
    echo "❌ Error installing dependencies"
    exit 1
fi

# Make executable
chmod +x index.js

# Create symlink in workspace scripts
WORKSPACE_SCRIPTS="$(dirname "$SCRIPT_DIR")"
SYMLINK_PATH="$WORKSPACE_SCRIPTS/subagents-dashboard"

if [ -f "$SYMLINK_PATH" ]; then
    echo "✅ Wrapper script already exists at: $SYMLINK_PATH"
else
    echo
    echo "Creating wrapper script..."
    cat > "$SYMLINK_PATH" << 'EOF'
#!/usr/bin/env bash
# OpenClaw Subagents Dashboard - Wrapper script
# Usage: subagents-dashboard

DASHBOARD_DIR="$(dirname "$0")/openclaw-subagents-tui-blessed"

if [ ! -d "$DASHBOARD_DIR" ]; then
  echo "Error: Dashboard directory not found at $DASHBOARD_DIR"
  exit 1
fi

cd "$DASHBOARD_DIR" && node index.js "$@"
EOF
    chmod +x "$SYMLINK_PATH"
    echo "✅ Wrapper script created at: $SYMLINK_PATH"
fi

echo
echo "=============================================="
echo "✅ Installation complete!"
echo
echo "Usage:"
echo "  1. From workspace/scripts:"
echo "     ./subagents-dashboard"
echo
echo "  2. Or directly:"
echo "     cd $SCRIPT_DIR"
echo "     node index.js"
echo
echo "Keyboard shortcuts:"
echo "  ↑↓ / j/k  - Navigate"
echo "  r         - Refresh"
echo "  q / Ctrl+C - Quit"
echo
echo "📖 See README.md for full documentation"
echo "=============================================="
