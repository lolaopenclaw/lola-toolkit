# youtube-smart-transcript

Extracción inteligente de transcripciones de YouTube con estrategia de coste cero.

## Quick Start

```bash
# Instalar dependencias
pip install youtube-transcript-api yt-dlp openai

# Uso básico
youtube-smart-transcript "https://youtube.com/watch?v=VIDEO_ID"
youtube-smart-transcript VIDEO_ID

# Ver metadata (método usado, coste, idioma, etc.)
youtube-smart-transcript VIDEO_ID --metadata

# Formato JSON con timestamps
youtube-smart-transcript VIDEO_ID --format json

# Formato SRT (subtítulos)
youtube-smart-transcript VIDEO_ID --format srt

# Especificar idiomas preferidos
youtube-smart-transcript VIDEO_ID --lang es,en

# Ignorar caché y re-procesar
youtube-smart-transcript VIDEO_ID --force-refresh
```

## Arquitectura

1. **Caché** (instantáneo, gratis)
2. **Subtítulos nativos YouTube** (~1-2s, gratis)
3. **Whisper API** (fallback, ~$0.006/min)

## Documentación Completa

Ver [SKILL.md](SKILL.md)

## Testing Realizado

✅ Capa 1 (subtítulos nativos): OK  
✅ Capa 3 (caché): OK  
✅ Formato text: OK  
✅ Formato JSON: OK  
✅ Formato SRT: OK  
✅ Flag --force-refresh: OK  
✅ Flag --metadata: OK  
✅ Manejo de errores (vídeo no disponible): OK  
✅ Fallback a Capa 2 cuando no hay subtítulos: OK  
⏳ Capa 2 (Whisper API): No probada (requiere OPENAI_API_KEY)

## Nota sobre Capa 2 (Whisper API)

Para habilitar el fallback de Whisper API:

```bash
export OPENAI_API_KEY='sk-...'
```

O agregar a `~/.openclaw/.env`:
```bash
echo 'OPENAI_API_KEY="sk-..."' >> ~/.openclaw/.env
```
