#!/usr/bin/env python3
"""
YouTube Smart Transcript Extractor
Estrategia de 3 capas: Caché → YouTube native captions → Whisper API
"""

import sys
import json
import os
import re
import time
import argparse
from pathlib import Path
from datetime import datetime
from typing import Optional, Tuple, Dict, Any

# Verificar dependencias
try:
    from youtube_transcript_api import YouTubeTranscriptApi, NoTranscriptFound, TranscriptsDisabled, VideoUnavailable
    from youtube_transcript_api.formatters import TextFormatter, JSONFormatter
except ImportError:
    print("❌ Error: youtube-transcript-api no está instalado", file=sys.stderr)
    print("   Instala con: pip install youtube-transcript-api", file=sys.stderr)
    sys.exit(1)

try:
    import yt_dlp
except ImportError:
    print("⚠️  Advertencia: yt-dlp no está instalado (necesario para fallback Whisper)", file=sys.stderr)
    print("   Instala con: pip install yt-dlp", file=sys.stderr)
    yt_dlp = None

try:
    from openai import OpenAI
except ImportError:
    print("⚠️  Advertencia: openai no está instalado (necesario para fallback Whisper)", file=sys.stderr)
    print("   Instala con: pip install openai", file=sys.stderr)
    OpenAI = None


# Configuración
CACHE_DIR = Path.home() / ".openclaw/workspace/youtube-transcripts"
CACHE_DIR.mkdir(parents=True, exist_ok=True)


def extract_video_id(url_or_id: str) -> str:
    """Extrae el VIDEO_ID de una URL de YouTube o lo devuelve si ya es un ID."""
    patterns = [
        r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})',
        r'^([a-zA-Z0-9_-]{11})$'
    ]
    
    for pattern in patterns:
        match = re.search(pattern, url_or_id)
        if match:
            return match.group(1)
    
    raise ValueError(f"No se pudo extraer VIDEO_ID de: {url_or_id}")


def get_cache_path(video_id: str, languages: list) -> Path:
    """Genera la ruta del archivo de caché."""
    lang_suffix = "_".join(languages)
    return CACHE_DIR / f"{video_id}_{lang_suffix}.json"


def load_from_cache(video_id: str, languages: list, force_refresh: bool = False) -> Optional[Dict[str, Any]]:
    """Carga transcripción desde caché si existe."""
    if force_refresh:
        return None
    
    cache_path = get_cache_path(video_id, languages)
    
    if not cache_path.exists():
        return None
    
    try:
        with open(cache_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            print(f"✅ [CACHE] Cargado desde caché: {cache_path.name}", file=sys.stderr)
            return data
    except Exception as e:
        print(f"⚠️  Error leyendo caché: {e}", file=sys.stderr)
        return None


def save_to_cache(video_id: str, languages: list, data: Dict[str, Any]) -> None:
    """Guarda transcripción en caché."""
    cache_path = get_cache_path(video_id, languages)
    
    try:
        with open(cache_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"💾 Guardado en caché: {cache_path.name}", file=sys.stderr)
    except Exception as e:
        print(f"⚠️  Error guardando en caché: {e}", file=sys.stderr)


def try_native_captions(video_id: str, languages: list, use_proxy: bool = False) -> Optional[Tuple[list, Dict[str, Any]]]:
    """
    Capa 1: Intenta extraer subtítulos nativos de YouTube.
    
    Returns:
        (transcript_list, metadata) si tiene éxito, None si falla
    """
    print(f"🔄 [LAYER 1] Intentando extraer subtítulos nativos...", file=sys.stderr)
    
    try:
        # Instanciar API
        api = YouTubeTranscriptApi()
        
        # Intenta obtener transcripción en los idiomas especificados
        fetched = api.fetch(video_id, languages=languages)
        
        # Convertir a formato lista de diccionarios (compatible con el resto del código)
        transcript = [
            {
                'text': snippet.text,
                'start': snippet.start,
                'duration': snippet.duration
            }
            for snippet in fetched
        ]
        
        # Obtener metadata adicional
        transcript_list = api.list(video_id)
        available_transcripts = [t.language_code for t in transcript_list]
        
        # Detectar idioma usado
        detected_lang = fetched.language_code
        
        metadata = {
            "video_id": video_id,
            "method": "native_captions",
            "detected_language": detected_lang,
            "available_languages": available_transcripts,
            "is_generated": fetched.is_generated,
            "timestamp": datetime.now().isoformat(),
            "cost": 0.0,
            "duration_seconds": sum(segment['duration'] for segment in transcript)
        }
        
        print(f"✅ [LAYER 1] Subtítulos nativos encontrados (idioma: {detected_lang})", file=sys.stderr)
        return transcript, metadata
        
    except (NoTranscriptFound, TranscriptsDisabled) as e:
        print(f"⚠️  [LAYER 1] No hay subtítulos nativos disponibles: {e}", file=sys.stderr)
        return None
    except VideoUnavailable as e:
        print(f"❌ [LAYER 1] Vídeo no disponible: {e}", file=sys.stderr)
        raise
    except Exception as e:
        # Si es error de bloqueo de IP, informar al usuario
        error_msg = str(e).lower()
        if 'blocked' in error_msg or 'forbidden' in error_msg or '403' in error_msg:
            print(f"⚠️  [LAYER 1] IP bloqueada por YouTube: {e}", file=sys.stderr)
            print(f"💡 Sugerencia: Considera configurar un proxy o usar Tailscale", file=sys.stderr)
        else:
            print(f"⚠️  [LAYER 1] Error inesperado: {e}", file=sys.stderr)
        return None


def try_whisper_api(video_id: str, languages: list) -> Optional[Tuple[str, Dict[str, Any]]]:
    """
    Capa 2: Descarga audio y transcribe con OpenAI Whisper API.
    
    Returns:
        (transcript_text, metadata) si tiene éxito, None si falla
    """
    print(f"🔄 [LAYER 2] Intentando fallback con Whisper API...", file=sys.stderr)
    
    # Verificar dependencias
    if yt_dlp is None:
        print(f"❌ [LAYER 2] yt-dlp no está instalado", file=sys.stderr)
        return None
    
    if OpenAI is None:
        print(f"❌ [LAYER 2] openai no está instalado", file=sys.stderr)
        return None
    
    # Verificar API key
    api_key = os.environ.get('OPENAI_API_KEY')
    if not api_key:
        print(f"❌ [LAYER 2] OPENAI_API_KEY no está configurada", file=sys.stderr)
        print(f"   Configura con: export OPENAI_API_KEY='tu-api-key'", file=sys.stderr)
        return None
    
    audio_path = None
    
    try:
        # Descargar solo audio (más ligero que vídeo completo)
        print(f"📥 Descargando audio...", file=sys.stderr)
        audio_path = CACHE_DIR / f"{video_id}.m4a"
        
        ydl_opts = {
            'format': 'm4a/bestaudio/best',
            'outtmpl': str(audio_path),
            'quiet': True,
            'no_warnings': True,
        }
        
        start_time = time.time()
        
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(f'https://youtube.com/watch?v={video_id}', download=True)
            video_title = info.get('title', 'Unknown')
            duration_seconds = info.get('duration', 0)
        
        download_time = time.time() - start_time
        file_size_mb = audio_path.stat().st_size / (1024 * 1024)
        
        print(f"✅ Audio descargado: {file_size_mb:.2f} MB en {download_time:.1f}s", file=sys.stderr)
        
        # Transcribir con OpenAI Whisper API
        print(f"🎙️  Transcribiendo con Whisper API...", file=sys.stderr)
        
        client = OpenAI(api_key=api_key)
        start_time = time.time()
        
        with open(audio_path, 'rb') as audio_file:
            # Especificar idioma preferido si es español
            language = languages[0] if languages[0] in ['es', 'en', 'fr', 'de', 'it', 'pt', 'nl', 'ru', 'zh', 'ja', 'ko'] else None
            
            response = client.audio.transcriptions.create(
                model="whisper-1",
                file=audio_file,
                response_format="text",
                language=language
            )
        
        transcription_time = time.time() - start_time
        
        # Calcular coste (Whisper API: $0.006 por minuto)
        duration_minutes = duration_seconds / 60
        cost = duration_minutes * 0.006
        
        print(f"✅ [LAYER 2] Transcripción completada en {transcription_time:.1f}s", file=sys.stderr)
        print(f"💰 Coste estimado: ${cost:.4f} ({duration_minutes:.1f} min × $0.006/min)", file=sys.stderr)
        
        metadata = {
            "video_id": video_id,
            "title": video_title,
            "method": "whisper_api",
            "model": "whisper-1",
            "detected_language": language or "auto",
            "timestamp": datetime.now().isoformat(),
            "duration_seconds": duration_seconds,
            "duration_minutes": round(duration_minutes, 2),
            "cost": round(cost, 4),
            "audio_size_mb": round(file_size_mb, 2),
            "download_time_seconds": round(download_time, 1),
            "transcription_time_seconds": round(transcription_time, 1)
        }
        
        return response, metadata
        
    except Exception as e:
        print(f"❌ [LAYER 2] Error en Whisper API: {e}", file=sys.stderr)
        return None
    
    finally:
        # Limpiar archivo de audio
        if audio_path and audio_path.exists():
            try:
                audio_path.unlink()
                print(f"🗑️  Audio temporal eliminado", file=sys.stderr)
            except Exception as e:
                print(f"⚠️  No se pudo eliminar audio temporal: {e}", file=sys.stderr)


def format_transcript(transcript: list, format_type: str = 'text') -> str:
    """Formatea la transcripción según el tipo solicitado."""
    if format_type == 'json':
        return json.dumps(transcript, ensure_ascii=False, indent=2)
    elif format_type == 'text':
        # Extraer solo el texto de cada segmento
        return "\n".join(segment.get('text', '') for segment in transcript)
    elif format_type == 'srt':
        # Formato SRT básico
        srt_lines = []
        for i, segment in enumerate(transcript, 1):
            start = segment.get('start', 0)
            duration = segment.get('duration', 0)
            end = start + duration
            text = segment.get('text', '')
            
            start_time = format_timestamp_srt(start)
            end_time = format_timestamp_srt(end)
            
            srt_lines.append(f"{i}\n{start_time} --> {end_time}\n{text}\n")
        
        return "\n".join(srt_lines)
    else:
        raise ValueError(f"Formato no soportado: {format_type}")


def format_timestamp_srt(seconds: float) -> str:
    """Formatea segundos a formato SRT (00:00:00,000)."""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    millis = int((seconds % 1) * 1000)
    return f"{hours:02d}:{minutes:02d}:{secs:02d},{millis:03d}"


def main():
    parser = argparse.ArgumentParser(
        description='Extrae transcripciones de YouTube con estrategia de coste cero',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos:
  %(prog)s "https://youtube.com/watch?v=dQw4w9WgXcQ"
  %(prog)s dQw4w9WgXcQ --lang es --format text
  %(prog)s dQw4w9WgXcQ --force-refresh
  %(prog)s dQw4w9WgXcQ --format json > transcript.json
        """
    )
    
    parser.add_argument('video', help='URL de YouTube o VIDEO_ID')
    parser.add_argument('--lang', '--languages', dest='languages', default='es,en',
                        help='Idiomas preferidos separados por comas (default: es,en)')
    parser.add_argument('--format', choices=['text', 'json', 'srt'], default='text',
                        help='Formato de salida (default: text)')
    parser.add_argument('--force-refresh', action='store_true',
                        help='Ignorar caché y re-procesar')
    parser.add_argument('--proxy', action='store_true',
                        help='Usar proxy (experimental, requiere configuración)')
    parser.add_argument('--metadata', action='store_true',
                        help='Mostrar metadata en stderr')
    
    args = parser.parse_args()
    
    # Extraer VIDEO_ID
    try:
        video_id = extract_video_id(args.video)
        print(f"🎬 Video ID: {video_id}", file=sys.stderr)
    except ValueError as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Parsear idiomas
    languages = [lang.strip() for lang in args.languages.split(',')]
    print(f"🌐 Idiomas preferidos: {', '.join(languages)}", file=sys.stderr)
    
    # Capa 3: Verificar caché
    cached = load_from_cache(video_id, languages, args.force_refresh)
    if cached:
        transcript_data = cached.get('transcript')
        metadata = cached.get('metadata', {})
        
        if args.metadata:
            print(f"\n📊 Metadata:", file=sys.stderr)
            print(json.dumps(metadata, indent=2, ensure_ascii=False), file=sys.stderr)
        
        # Formatear y mostrar
        if isinstance(transcript_data, list):
            output = format_transcript(transcript_data, args.format)
        else:
            output = transcript_data
        
        print(output)
        return
    
    # Capa 1: Intentar subtítulos nativos
    try:
        result = try_native_captions(video_id, languages, args.proxy)
    except VideoUnavailable:
        print(f"\n❌ Error: El vídeo no está disponible (privado, borrado o geobloqueado)", file=sys.stderr)
        sys.exit(1)
    
    if result:
        transcript, metadata = result
        
        # Guardar en caché
        cache_data = {
            'transcript': transcript,
            'metadata': metadata
        }
        save_to_cache(video_id, languages, cache_data)
        
        if args.metadata:
            print(f"\n📊 Metadata:", file=sys.stderr)
            print(json.dumps(metadata, indent=2, ensure_ascii=False), file=sys.stderr)
        
        # Formatear y mostrar
        output = format_transcript(transcript, args.format)
        print(output)
        return
    
    # Capa 2: Fallback a Whisper API
    result = try_whisper_api(video_id, languages)
    
    if result:
        transcript_text, metadata = result
        
        # Guardar en caché
        cache_data = {
            'transcript': transcript_text,
            'metadata': metadata
        }
        save_to_cache(video_id, languages, cache_data)
        
        if args.metadata:
            print(f"\n📊 Metadata:", file=sys.stderr)
            print(json.dumps(metadata, indent=2, ensure_ascii=False), file=sys.stderr)
        
        print(transcript_text)
        return
    
    # Si llegamos aquí, todas las capas fallaron
    print(f"\n❌ Error: No se pudo extraer transcripción por ningún método", file=sys.stderr)
    print(f"   1. Subtítulos nativos: No disponibles o bloqueados", file=sys.stderr)
    print(f"   2. Whisper API: No configurado o falló", file=sys.stderr)
    sys.exit(1)


if __name__ == '__main__':
    main()
