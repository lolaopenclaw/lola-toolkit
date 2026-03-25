#!/bin/bash
# Script de instalación rápida para youtube-smart-transcript

set -e

echo "🚀 Instalando youtube-smart-transcript..."
echo ""

# Verificar Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 no está instalado"
    exit 1
fi

echo "✅ Python 3 encontrado: $(python3 --version)"

# Instalar dependencias
echo ""
echo "📦 Instalando dependencias Python..."
echo "   - youtube-transcript-api (requerido)"
echo "   - yt-dlp (opcional, para fallback Whisper)"
echo "   - openai (opcional, para fallback Whisper)"
echo ""

# Detectar sistema de gestión de paquetes
if command -v pip3 &> /dev/null; then
    PIP="pip3"
elif command -v pip &> /dev/null; then
    PIP="pip"
else
    PIP="python3 -m pip"
fi

# Intentar instalación
if $PIP install --user youtube-transcript-api yt-dlp openai 2>/dev/null; then
    echo "✅ Dependencias instaladas correctamente"
else
    # Si falla por externally-managed-environment, usar --break-system-packages
    echo "⚠️  Entorno gestionado externamente, usando --break-system-packages..."
    $PIP install --user --break-system-packages youtube-transcript-api yt-dlp openai
    echo "✅ Dependencias instaladas correctamente"
fi

# Crear directorio de caché
echo ""
echo "📁 Creando directorio de caché..."
mkdir -p ~/.openclaw/workspace/youtube-transcripts
echo "✅ Directorio creado: ~/.openclaw/workspace/youtube-transcripts"

# Crear symlink en scripts/
echo ""
echo "🔗 Creando symlink en scripts/..."
mkdir -p ~/.openclaw/workspace/scripts
ln -sf ~/.openclaw/workspace/skills/youtube-smart-transcript/youtube-smart-transcript.py \
       ~/.openclaw/workspace/scripts/youtube-smart-transcript
echo "✅ Symlink creado: ~/.openclaw/workspace/scripts/youtube-smart-transcript"

# Verificar instalación
echo ""
echo "🧪 Verificando instalación..."
if python3 -c "import youtube_transcript_api; import yt_dlp; from openai import OpenAI" 2>/dev/null; then
    echo "✅ Todas las dependencias están disponibles"
else
    echo "⚠️  Algunas dependencias no están disponibles, pero el skill puede funcionar con subtítulos nativos"
fi

echo ""
echo "✅ Instalación completada"
echo ""
echo "📚 Uso:"
echo "   youtube-smart-transcript VIDEO_ID"
echo "   youtube-smart-transcript VIDEO_ID --format json"
echo "   youtube-smart-transcript VIDEO_ID --metadata"
echo ""
echo "📖 Documentación completa: ~/.openclaw/workspace/skills/youtube-smart-transcript/SKILL.md"
echo ""
echo "💡 Para habilitar fallback Whisper API (opcional):"
echo "   export OPENAI_API_KEY='sk-...'"
echo "   # O agregar a ~/.openclaw/.env"
