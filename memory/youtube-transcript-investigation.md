# Investigación: Soluciones Inteligentes para Extraer Transcripciones de YouTube

**Fecha:** 2026-03-24  
**Objetivo:** Encontrar alternativas eficientes al método actual (yt-dlp + Whisper local) para extraer contenido de YouTube sin consumir CPU VPS intensivamente.

---

## 🔍 Resumen Ejecutivo

**Recomendación: Opción 2 - youtube-transcript-api (Python)**

Método más eficiente encontrado: Extraer subtítulos nativos de YouTube **sin descargar vídeo ni procesar audio**. Gratis, sin API keys, sin cuotas, sin consumo CPU.

**Razón:** YouTube genera subtítulos automáticos para la mayoría de vídeos. Extraerlos directamente es ~1000x más eficiente que descargar + transcribir localmente.

---

## 📊 Comparativa de Métodos

### 1. **YouTube Data API v3** ❌

**¿Ofrece transcripciones?** NO

- **Qué ofrece:** Metadata (título, descripción, estadísticas, comentarios, playlists)
- **NO incluye:** Subtítulos, transcripciones ni captions
- **Límites:** 10,000 unidades/día (búsqueda = 100 unidades, read = 1 unidad)
- **Coste:** Gratis hasta quota, luego hay que solicitar extensión
- **Conclusión:** No sirve para nuestro caso. Es para metadata, no para contenido textual.

---

### 2. **youtube-transcript-api (Python)** ✅ RECOMENDADO

**Lo que necesitas, directo y simple.**

#### ¿Cómo funciona?
- Extrae subtítulos generados automáticamente por YouTube (o manuales si existen)
- **NO descarga vídeo**
- **NO procesa audio localmente**
- **NO requiere API key**
- **NO consume CPU VPS**
- Accede a API no documentada de YouTube (la misma que usa el player web)

#### Ventajas
- ✅ **Gratis** (100%)
- ✅ **Sin cuotas** (sin límite de uso)
- ✅ **Sin API keys** (sin registro)
- ✅ **Rápido** (~1-2s por vídeo)
- ✅ **Ligero** (solo HTTP requests)
- ✅ **Multi-idioma** (soporta +50 idiomas)
- ✅ **Traducción automática** (puede traducir a otros idiomas usando función de YouTube)
- ✅ **Formateos múltiples** (JSON, SRT, VTT, TXT)
- ✅ **CLI incluido** (puede usarse desde bash sin Python)
- ✅ **Timestamps** (cada fragmento con start/duration)

#### Desventajas
- ❌ **Solo funciona si YouTube tiene subtítulos** (auto-generados o manuales)
- ❌ **No funciona con vídeos muy nuevos** (YouTube tarda ~10min en generar subtítulos)
- ❌ **Puede romperse** (API no oficial, puede cambiar)
- ❌ **Bloqueado en cloud IPs** (AWS, GCP, Azure) → **Requiere proxies** para VPS

#### Instalación
```bash
pip install youtube-transcript-api
```

#### Uso básico (Python)
```python
from youtube_transcript_api import YouTubeTranscriptApi

# Extraer transcripción (inglés por defecto)
transcript = YouTubeTranscriptApi.get_transcript('VIDEO_ID')

# Multi-idioma (prioridad: español > inglés)
transcript = YouTubeTranscriptApi.get_transcript('VIDEO_ID', languages=['es', 'en'])

# Traducir a español
transcript = YouTubeTranscriptApi.get_transcript('VIDEO_ID', languages=['en'])
transcript_list = YouTubeTranscriptApi.list_transcripts('VIDEO_ID')
transcript_es = transcript_list.find_transcript(['en']).translate('es').fetch()

# Formato texto plano
from youtube_transcript_api.formatters import TextFormatter
formatter = TextFormatter()
text = formatter.format_transcript(transcript)
```

#### Uso desde CLI
```bash
# Extraer transcripción
youtube_transcript_api VIDEO_ID

# Especificar idiomas
youtube_transcript_api VIDEO_ID --languages es en

# Exportar a JSON
youtube_transcript_api VIDEO_ID --format json > transcript.json

# Traducir
youtube_transcript_api VIDEO_ID --languages en --translate es
```

#### ⚠️ Problema: Bloqueo de IPs de cloud providers
YouTube bloquea la mayoría de IPs de AWS, GCP, Azure → `RequestBlocked` o `IpBlocked`

**Solución: Proxies residenciales rotatorios**

1. **Opción A: Webshare (recomendado por el autor)**
   - Servicio de proxies residenciales rotatorios
   - $5/mes (Starter) = 1,000 créditos
   - Integración nativa en youtube-transcript-api
   - Setup:
     ```python
     from youtube_transcript_api import YouTubeTranscriptApi
     from youtube_transcript_api.proxies import WebshareProxyConfig
     
     api = YouTubeTranscriptApi(
         proxy_config=WebshareProxyConfig(
             proxy_username="tu_usuario",
             proxy_password="tu_password"
         )
     )
     transcript = api.get_transcript('VIDEO_ID')
     ```

2. **Opción B: Proxy genérico**
   - Cualquier HTTP/HTTPS/SOCKS proxy
   - Puedes montar tu propio proxy en casa o usar servicios tipo BrightData, Oxylabs, etc.
   - Setup:
     ```python
     from youtube_transcript_api import YouTubeTranscriptApi
     from youtube_transcript_api.proxies import GenericProxyConfig
     
     api = YouTubeTranscriptApi(
         proxy_config=GenericProxyConfig(
             http_url="http://user:pass@proxy.org:port",
             https_url="https://user:pass@proxy.org:port"
         )
     )
     ```

**Coste estimado (VPS con proxy):**
- Webshare Starter: $5/mes (1,000 créditos)
- Alternativamente: Proxy propio en casa (Raspberry Pi + Tailscale = $0)

---

### 3. **TranscriptAPI.com + Skills OpenClaw** ✅ ALTERNATIVA PREMIUM

**Servicio gestionado basado en youtube-transcript-api con skill oficial para OpenClaw.**

#### ¿Qué es?
- REST API comercial que wrappea youtube-transcript-api
- **Skill oficial en ClawHub:** `youtube-transcript` (by xthezealot)
- También existe un repo más completo: [ZeroPointRepo/youtube-skills](https://github.com/ZeroPointRepo/youtube-skills)
- Maneja proxies residenciales automáticamente (no te preocupas de bloqueos)
- Incluye funciones extras: búsqueda, canales, playlists

#### Ventajas
- ✅ **Sin gestionar proxies** (ellos lo hacen)
- ✅ **Uptime 99.9%** (6M+ transcripciones/mes)
- ✅ **Skills listas para OpenClaw** (instalar y usar)
- ✅ **API REST** (fácil integrar en cualquier lenguaje)
- ✅ **MCP Server** (integración directa con Claude/ChatGPT)
- ✅ **Funciones extra:** búsqueda YouTube, canales, playlists

#### Desventajas
- ❌ **De pago** (después de 100 créditos gratis)
- ❌ **Límite 300 req/min**

#### Pricing
| Plan | Precio | Créditos | Rate Limit |
|------|--------|----------|------------|
| **Free** | $0 | 100 credits (signup) | 300 req/min |
| **Starter** | $5/mes | 1,000 credits/mes | 300 req/min |
| **Starter Annual** | $54/año | 1,000 credits/mes | 300 req/min |

**Coste por operación:** 1 crédito = 1 transcripción

#### Instalación (OpenClaw)
```bash
npx clawhub@latest install youtube-transcript
# o para todo el toolkit:
npx clawhub@latest install youtube-full
```

#### Uso (OpenClaw)
Simplemente habla con el agente:
- "Resúmeme este vídeo: [URL]"
- "Busca vídeos sobre machine learning"
- "Transcribe todos los vídeos del canal de TED"

El skill maneja autenticación automáticamente (OTP por email en primer uso).

#### Skills disponibles
- `youtube-full` — Todo (transcripciones + búsqueda + canales + playlists) **RECOMENDADO**
- `transcript` — Solo transcripciones
- `youtube-search` — Solo búsqueda
- `youtube-channels` — Solo canales
- `youtube-playlist` — Solo playlists

**Repo GitHub:** https://github.com/ZeroPointRepo/youtube-skills

---

### 4. **APIs de Terceros (AssemblyAI, Deepgram, OpenAI Whisper API)** 💰

**Transcripción de audio mediante APIs cloud.**

#### ¿Cómo funciona?
1. Descargas el vídeo (yt-dlp solo audio: más ligero)
2. Subes el audio a la API
3. Recibes transcripción procesada en la nube

#### Servicios disponibles

**OpenAI Whisper API**
- Modelos: `whisper-1`, `gpt-4o-transcribe`, `gpt-4o-mini-transcribe`, `gpt-4o-transcribe-diarize`
- Precio: ~$0.006/minuto (`whisper-1`)
- Límite archivo: 25 MB
- Formatos: JSON, text, SRT, VTT
- **Diarización** (identificar speakers): `gpt-4o-transcribe-diarize`
- **Traducción:** Solo a inglés (endpoint `/translations`)
- **Streaming:** Soportado en `gpt-4o-transcribe` y `gpt-4o-mini-transcribe`

**AssemblyAI**
- Precio: ~$0.25/hora
- **Más caro que OpenAI**
- Features extra: diarización, sentiment analysis, entity detection
- Requiere: API key (free tier limitado)

**Deepgram**
- Precio: ~$0.0125/minuto
- **Más barato que OpenAI**
- Muy rápido (transcripción en tiempo real)
- Requiere: API key (free tier: $200 créditos)

#### Ventajas
- ✅ **Funciona siempre** (no depende de subtítulos YouTube)
- ✅ **Calidad alta** (mejor que auto-captions YouTube en muchos casos)
- ✅ **Funciona con vídeos nuevos** (sin esperar a que YouTube genere subtítulos)
- ✅ **Funciona con audio sin subtítulos**
- ✅ **Diarización** (identificar quién habla)
- ✅ **Análisis avanzado** (sentiment, entities, etc. en AssemblyAI)

#### Desventajas
- ❌ **De pago** (coste por minuto)
- ❌ **Requiere descargar audio** (aunque más ligero que vídeo completo)
- ❌ **Más lento** (descarga + upload + procesamiento)
- ❌ **Consume ancho de banda** (upload a API)

#### Estimación de costes (vídeo de 10 min)
- **OpenAI Whisper:** $0.06
- **Deepgram:** $0.125
- **AssemblyAI:** $0.0417

**Coste mensual (50 vídeos/mes de 10min cada uno):**
- OpenAI: $3/mes
- Deepgram: $6.25/mes
- AssemblyAI: $2.08/mes

---

### 5. **Optimizaciones del Método Actual (yt-dlp + Whisper local)** 🔧

**Si decides mantener el método actual, aquí las mejoras:**

#### 1. Descargar solo audio (no vídeo completo)
```bash
# Solo audio en formato m4a (más ligero)
yt-dlp -f 'm4a/bestaudio/best' -o '%(id)s.%(ext)s' VIDEO_URL

# Con post-procesamiento a m4a
yt-dlp -f 'bestaudio' --extract-audio --audio-format m4a VIDEO_URL
```

**Ahorro:** ~70-90% (audio 5-10 MB vs vídeo 50-100 MB para 10min)

#### 2. Caché de transcripciones procesadas
```bash
# Guardar transcripciones en base de datos
# Antes de procesar, verificar si ya existe:
if [ -f "transcripts/${VIDEO_ID}.txt" ]; then
    cat "transcripts/${VIDEO_ID}.txt"
else
    yt-dlp + whisper + guardar resultado
fi
```

**Ahorro:** 100% en vídeos repetidos

#### 3. Whisper cloud API en vez de local
- Usar OpenAI Whisper API ($0.006/min)
- **Ventaja:** No consume CPU VPS
- **Desventaja:** Coste por uso

#### 4. Modelos Whisper más pequeños
```bash
# Usar modelo tiny o base en vez de medium/large
whisper audio.m4a --model tiny  # Más rápido, menos preciso
whisper audio.m4a --model base  # Balance
```

**Ahorro CPU:** ~50-70%  
**Trade-off:** Menor precisión

---

## 🎯 Recomendación Final

### **Para uso general: youtube-transcript-api (Opción 2)**

**Instalar:**
```bash
pip install youtube-transcript-api
```

**Crear wrapper CLI:**
```bash
# ~/.openclaw/workspace/scripts/yt-transcript.sh
#!/bin/bash
VIDEO_ID="$1"
LANG="${2:-es,en}"  # Español > Inglés por defecto

python3 -c "
from youtube_transcript_api import YouTubeTranscriptApi
from youtube_transcript_api.formatters import TextFormatter

try:
    transcript = YouTubeTranscriptApi.get_transcript('$VIDEO_ID', languages=['$LANG'.split(',')])
    formatter = TextFormatter()
    print(formatter.format_transcript(transcript))
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    exit(1)
"
```

**Uso:**
```bash
chmod +x scripts/yt-transcript.sh
./scripts/yt-transcript.sh VIDEO_ID
./scripts/yt-transcript.sh VIDEO_ID es,en
```

**Si estás en VPS (bloqueado por YouTube):**
- **Opción A:** Montar proxy en casa (Raspberry Pi + Tailscale) = $0
- **Opción B:** Webshare Starter ($5/mes)
- **Opción C:** TranscriptAPI.com ($5/mes) + skill OpenClaw

---

### **Para vídeos sin subtítulos: OpenAI Whisper API (Opción 4)**

**Cuándo usar:**
- Vídeo muy nuevo (YouTube aún no generó subtítulos)
- Vídeo sin subtítulos (privado, no listado, etc.)
- Necesitas calidad superior
- Necesitas diarización (identificar speakers)

**Flujo híbrido recomendado:**
1. Intentar extraer con `youtube-transcript-api` (gratis, rápido)
2. Si falla → Descargar audio + OpenAI Whisper API ($0.006/min)

**Código ejemplo:**
```python
from youtube_transcript_api import YouTubeTranscriptApi
import yt_dlp
from openai import OpenAI

def get_transcript(video_id):
    # Intentar método 1: Subtítulos nativos
    try:
        transcript = YouTubeTranscriptApi.get_transcript(video_id, languages=['es', 'en'])
        return format_transcript(transcript), "native"
    except:
        pass
    
    # Método 2: Whisper API
    # Descargar solo audio
    ydl_opts = {
        'format': 'm4a/bestaudio/best',
        'outtmpl': f'{video_id}.%(ext)s',
        'postprocessors': [{'key': 'FFmpegExtractAudio', 'preferredcodec': 'm4a'}]
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        ydl.download([f'https://youtube.com/watch?v={video_id}'])
    
    # Transcribir con OpenAI
    client = OpenAI()
    with open(f'{video_id}.m4a', 'rb') as audio:
        transcript = client.audio.transcriptions.create(
            model='whisper-1',
            file=audio,
            response_format='text'
        )
    
    return transcript, "whisper_api"
```

---

## 📝 Siguientes Pasos

1. **Instalar `youtube-transcript-api`:**
   ```bash
   pip install youtube-transcript-api
   ```

2. **Crear skill OpenClaw personalizado** (o instalar desde ClawHub):
   - Wrapper que intente `youtube-transcript-api` primero
   - Fallback a Whisper API si falla
   - Caché de resultados para evitar re-procesar

3. **Si estás en VPS bloqueado:**
   - **Corto plazo:** Usar TranscriptAPI.com (skill `youtube-transcript` de ClawHub) → 100 créditos gratis
   - **Medio plazo:** Montar proxy en casa (Raspberry Pi + Tailscale)
   - **Alternativa:** Webshare ($5/mes)

4. **Pseudocódigo del skill propuesto:**
   ```python
   # ~/.openclaw/workspace/skills/youtube-smart-transcript/main.py
   
   def get_youtube_transcript(video_url_or_id, prefer_language='es'):
       video_id = extract_video_id(video_url_or_id)
       cache_key = f"yt_transcript_{video_id}_{prefer_language}"
       
       # 1. Verificar caché
       if cached := get_from_cache(cache_key):
           return cached, "cache"
       
       # 2. Intentar subtítulos nativos (GRATIS)
       try:
           transcript = YouTubeTranscriptApi.get_transcript(
               video_id, 
               languages=[prefer_language, 'en']
           )
           text = format_transcript(transcript)
           save_to_cache(cache_key, text)
           return text, "native_captions"
       except Exception as e:
           log(f"Native captions failed: {e}")
       
       # 3. Fallback: Whisper API (PAGO)
       try:
           audio_path = download_audio_only(video_url_or_id)
           transcript = transcribe_with_openai(audio_path)
           save_to_cache(cache_key, transcript)
           cleanup(audio_path)
           return transcript, "whisper_api"
       except Exception as e:
           return f"Error: {e}", "failed"
   ```

---

## 🔗 Referencias

- **youtube-transcript-api:** https://github.com/jdepoix/youtube-transcript-api
- **TranscriptAPI.com:** https://transcriptapi.com
- **ZeroPointRepo/youtube-skills:** https://github.com/ZeroPointRepo/youtube-skills
- **ClawHub youtube-transcript skill:** `npx clawhub@latest install youtube-transcript`
- **OpenAI Whisper API:** https://platform.openai.com/docs/guides/speech-to-text
- **YouTube Data API v3:** https://developers.google.com/youtube/v3/getting-started
- **Webshare (proxies):** https://www.webshare.io

---

**Conclusión:** El método más eficiente es extraer subtítulos nativos con `youtube-transcript-api`. Solo usar Whisper API como fallback para casos edge. La optimización clave es **evitar descargar y procesar cuando YouTube ya tiene el texto**.
