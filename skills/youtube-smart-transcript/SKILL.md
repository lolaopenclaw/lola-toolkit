# youtube-smart-transcript

**Extracción inteligente de transcripciones de YouTube con estrategia de coste cero.**

## Descripción

Este skill extrae transcripciones de vídeos de YouTube usando una arquitectura de 3 capas con fallback progresivo, priorizando métodos gratuitos y minimizando costes.

### Arquitectura de 3 Capas

1. **Capa 3 (Caché)** — Primera verificación
   - Lee transcripciones previamente procesadas desde `~/.openclaw/workspace/youtube-transcripts/`
   - Evita re-procesar vídeos ya vistos
   - **Coste:** $0.00

2. **Capa 1 (Subtítulos nativos)** — Método principal
   - Extrae subtítulos auto-generados o manuales de YouTube
   - Usa `youtube-transcript-api` (API no oficial de YouTube)
   - **NO descarga vídeo ni audio**
   - **Coste:** $0.00
   - **Problema conocido:** VPS pueden estar bloqueados por YouTube (error 403)

3. **Capa 2 (Whisper API)** — Fallback
   - Descarga solo audio (no vídeo completo → más ligero)
   - Transcribe con OpenAI Whisper API
   - **Coste:** ~$0.006/minuto (~$0.30-0.60 por vídeo de 1h)

### Cuándo Usar

- ✅ Extraer transcripciones de vídeos de YouTube
- ✅ Procesar listas de vídeos para análisis de contenido
- ✅ Obtener texto de conferencias, tutoriales, podcasts
- ✅ Cuando necesitas formato JSON con timestamps

### Cuándo NO Usar

- ❌ Vídeos privados sin acceso
- ❌ Vídeos muy recientes (<10 min publicados, YouTube aún no generó subtítulos)
- ❌ Si necesitas análisis de sentimientos o diarización avanzada (usa APIs especializadas)

## Instalación

### Requisitos

**Mínimo (solo Capa 1 + Caché):**
```bash
pip install youtube-transcript-api
```

**Completo (con fallback Whisper API):**
```bash
pip install youtube-transcript-api yt-dlp openai
```

### Configuración OpenAI Whisper API (Opcional)

Si quieres usar el fallback de Capa 2 (Whisper API), configura tu API key:

```bash
# Agregar a ~/.openclaw/.env
echo 'OPENAI_API_KEY="sk-..."' >> ~/.openclaw/.env

# O configurar en la sesión actual
export OPENAI_API_KEY='sk-...'
```

**Obtener API key:** https://platform.openai.com/api-keys

## Uso

### CLI Directo

```bash
# URL completa
youtube-smart-transcript "https://youtube.com/watch?v=dQw4w9WgXcQ"

# Solo VIDEO_ID
youtube-smart-transcript dQw4w9WgXcQ

# Especificar idiomas preferidos
youtube-smart-transcript dQw4w9WgXcQ --lang es

# Formato JSON con timestamps
youtube-smart-transcript dQw4w9WgXcQ --format json > transcript.json

# Formato SRT (subtítulos)
youtube-smart-transcript dQw4w9WgXcQ --format srt > transcript.srt

# Ignorar caché y re-procesar
youtube-smart-transcript dQw4w9WgXcQ --force-refresh

# Mostrar metadata (método usado, coste, duración, etc.)
youtube-smart-transcript dQw4w9WgXcQ --metadata
```

### Desde OpenClaw

```bash
# Agregar alias al script
ln -sf ~/.openclaw/workspace/skills/youtube-smart-transcript/youtube-smart-transcript.py \
       ~/.openclaw/workspace/scripts/youtube-smart-transcript

# Uso
youtube-smart-transcript VIDEO_ID
```

### Desde Python

```python
import subprocess
import json

# Ejecutar y capturar salida
result = subprocess.run(
    ['youtube-smart-transcript', 'VIDEO_ID', '--format', 'json'],
    capture_output=True,
    text=True
)

transcript = json.loads(result.stdout)
```

## Ejemplos

### Caso 1: Vídeo con subtítulos nativos (gratis)

```bash
$ youtube-smart-transcript dQw4w9WgXcQ --metadata

🎬 Video ID: dQw4w9WgXcQ
🌐 Idiomas preferidos: es, en
🔄 [LAYER 1] Intentando extraer subtítulos nativos...
✅ [LAYER 1] Subtítulos nativos encontrados (idioma: en)
💾 Guardado en caché: dQw4w9WgXcQ_es_en.json

📊 Metadata:
{
  "video_id": "dQw4w9WgXcQ",
  "method": "native_captions",
  "detected_language": "en",
  "available_languages": ["en", "es", "fr", "de"],
  "timestamp": "2026-03-24T09:30:00",
  "cost": 0.0,
  "duration_seconds": 212
}

[Transcripción...]
```

### Caso 2: Vídeo sin subtítulos → Fallback Whisper API

```bash
$ youtube-smart-transcript XYZ123 --metadata

🎬 Video ID: XYZ123
🌐 Idiomas preferidos: es, en
🔄 [LAYER 1] Intentando extraer subtítulos nativos...
⚠️  [LAYER 1] No hay subtítulos nativos disponibles
🔄 [LAYER 2] Intentando fallback con Whisper API...
📥 Descargando audio...
✅ Audio descargado: 8.3 MB en 12.4s
🎙️  Transcribiendo con Whisper API...
✅ [LAYER 2] Transcripción completada en 15.2s
💰 Coste estimado: $0.0360 (6.0 min × $0.006/min)
🗑️  Audio temporal eliminado
💾 Guardado en caché: XYZ123_es_en.json

📊 Metadata:
{
  "video_id": "XYZ123",
  "method": "whisper_api",
  "model": "whisper-1",
  "detected_language": "es",
  "cost": 0.036,
  "duration_minutes": 6.0
}

[Transcripción...]
```

### Caso 3: Segunda ejecución (caché)

```bash
$ youtube-smart-transcript dQw4w9WgXcQ

🎬 Video ID: dQw4w9WgXcQ
🌐 Idiomas preferidos: es, en
✅ [CACHE] Cargado desde caché: dQw4w9WgXcQ_es_en.json

[Transcripción...]
```

## Troubleshooting

### Error: "IP bloqueada por YouTube"

**Síntoma:**
```
⚠️  [LAYER 1] IP bloqueada por YouTube: 403 Forbidden
💡 Sugerencia: Considera configurar un proxy o usar Tailscale
```

**Causa:** YouTube bloquea IPs de proveedores cloud (AWS, GCP, Azure, DigitalOcean, etc.)

**Soluciones:**

1. **Opción A: Usar Tailscale como exit node (GRATIS)**
   
   Si tienes una máquina local con Tailscale:
   
   ```bash
   # En tu máquina local, habilitar exit node
   sudo tailscale up --advertise-exit-node
   
   # En el VPS, usar la máquina local como exit node
   tailscale status  # Verificar estado y obtener IP de exit node
   sudo tailscale up --exit-node=TAILSCALE_IP_LOCAL
   
   # Probar
   youtube-smart-transcript VIDEO_ID
   ```
   
   **Nota:** Esto hace que TODO el tráfico del VPS pase por tu máquina local. Si solo quieres rutear YouTube, considera Opción B.

2. **Opción B: Dejar que el fallback de Whisper API lo resuelva**
   
   Si tienes OpenAI API key configurada, el skill automáticamente usará Capa 2 (Whisper API).
   
   **Coste:** ~$0.006/minuto

3. **Opción C: Usar servicio proxy residencial** (no recomendado, innecesario)
   
   Servicios como Webshare ($5/mes) o BrightData ($20/mes).

**Recomendación:** Configurar Tailscale (gratis) o aceptar el coste mínimo de Whisper API ($0.30-0.60 por vídeo de 1h).

### Error: "OPENAI_API_KEY no está configurada"

**Síntoma:**
```
❌ [LAYER 2] OPENAI_API_KEY no está configurada
   Configura con: export OPENAI_API_KEY='tu-api-key'
```

**Solución:**

1. Obtén una API key en: https://platform.openai.com/api-keys

2. Configura la variable de entorno:
   ```bash
   # Temporal (solo sesión actual)
   export OPENAI_API_KEY='sk-...'
   
   # Permanente (agregar a ~/.openclaw/.env)
   echo 'OPENAI_API_KEY="sk-..."' >> ~/.openclaw/.env
   ```

3. Verifica:
   ```bash
   echo $OPENAI_API_KEY
   ```

### Error: "youtube-transcript-api no está instalado"

**Solución:**
```bash
pip install youtube-transcript-api
```

### Error: "yt-dlp no está instalado"

**Solución:**
```bash
pip install yt-dlp
```

### Error: "No se pudo extraer VIDEO_ID"

**Causa:** URL no reconocida o ID inválido

**Solución:** Verifica que la URL sea de YouTube:
- ✅ `https://youtube.com/watch?v=VIDEO_ID`
- ✅ `https://youtu.be/VIDEO_ID`
- ✅ `https://youtube.com/embed/VIDEO_ID`
- ✅ `VIDEO_ID` (solo el ID de 11 caracteres)

### Vídeo sin transcripción y Whisper API no configurada

**Síntoma:**
```
❌ Error: No se pudo extraer transcripción por ningún método
   1. Subtítulos nativos: No disponibles o bloqueados
   2. Whisper API: No configurado o falló
```

**Solución:**
1. Verifica que el vídeo tenga subtítulos (abre en YouTube y activa CC)
2. Si no tiene subtítulos, configura OpenAI API key para usar Whisper API (ver arriba)

## Arquitectura Interna

```
┌──────────────────────────────────────────────────────────────┐
│                     youtube-smart-transcript                  │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
                  ┌───────────────────────┐
                  │   Extraer VIDEO_ID    │
                  └───────────────────────┘
                              │
                              ▼
          ┌───────────────────────────────────────┐
          │  Capa 3: Verificar Caché             │
          │  ~/.openclaw/workspace/youtube-      │
          │  transcripts/{VIDEO_ID}_{LANG}.json  │
          └───────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ ¿Caché existe?  │
                    └─────────────────┘
                         │         │
                     Sí  │         │  No
                         ▼         │
                  ┌──────────┐     │
                  │  RETURN  │     │
                  └──────────┘     │
                                   ▼
          ┌───────────────────────────────────────┐
          │  Capa 1: youtube-transcript-api      │
          │  Extraer subtítulos nativos YouTube  │
          └───────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │    ¿Éxito?      │
                    └─────────────────┘
                         │         │
                     Sí  │         │  No
                         ▼         │
              ┌──────────────┐     │
              │ Guardar Caché│     │
              │    RETURN    │     │
              └──────────────┘     │
                                   ▼
          ┌───────────────────────────────────────┐
          │  Capa 2: Whisper API (Fallback)      │
          │  1. Descargar audio (yt-dlp)         │
          │  2. Transcribir (OpenAI Whisper API) │
          │  3. Limpiar audio temporal           │
          └───────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │    ¿Éxito?      │
                    └─────────────────┘
                         │         │
                     Sí  │         │  No
                         ▼         │
              ┌──────────────┐     │
              │ Guardar Caché│     │
              │    RETURN    │     │
              └──────────────┘     │
                                   ▼
                            ┌───────────┐
                            │   ERROR   │
                            └───────────┘
```

## Caché

### Ubicación
```
~/.openclaw/workspace/youtube-transcripts/
```

### Formato
```json
{
  "transcript": [
    {
      "text": "Texto del segmento",
      "start": 0.0,
      "duration": 3.5
    },
    ...
  ],
  "metadata": {
    "video_id": "VIDEO_ID",
    "method": "native_captions",
    "detected_language": "es",
    "timestamp": "2026-03-24T09:30:00",
    "cost": 0.0,
    "duration_seconds": 212
  }
}
```

### Gestión de Caché

```bash
# Ver caché existente
ls -lh ~/.openclaw/workspace/youtube-transcripts/

# Limpiar caché completo
rm -rf ~/.openclaw/workspace/youtube-transcripts/*

# Re-procesar vídeo específico
youtube-smart-transcript VIDEO_ID --force-refresh
```

## Estimación de Costes

| Método | Coste por vídeo (10 min) | Coste por vídeo (1h) | Notas |
|--------|--------------------------|----------------------|-------|
| **Caché** | $0.00 | $0.00 | Instantáneo |
| **Subtítulos nativos** | $0.00 | $0.00 | ~1-2s |
| **Whisper API** | $0.06 | $0.36 | + tiempo descarga/upload |

**Ejemplo mensual (50 vídeos/mes de 10 min cada uno):**
- 100% subtítulos nativos: **$0.00/mes**
- 50% nativos + 50% Whisper: **$1.50/mes**
- 100% Whisper: **$3.00/mes**

## Limitaciones

- ❌ **No funciona con vídeos privados** sin autenticación
- ❌ **Vídeos muy recientes** (<10 min publicados) pueden no tener subtítulos aún
- ❌ **VPS en clouds públicos** pueden estar bloqueados por YouTube (requiere proxy o fallback)
- ❌ **No identifica speakers** (diarización) — para eso usa `gpt-4o-transcribe-diarize` directamente
- ❌ **No analiza sentimientos** — para eso usa AssemblyAI o procesa la transcripción con LLM

## Referencias

- **youtube-transcript-api:** https://github.com/jdepoix/youtube-transcript-api
- **OpenAI Whisper API:** https://platform.openai.com/docs/guides/speech-to-text
- **yt-dlp:** https://github.com/yt-dlp/yt-dlp
- **Documentación completa:** `~/.openclaw/workspace/memory/youtube-transcript-investigation.md`

## Contribuir

Este skill está en `~/.openclaw/workspace/skills/youtube-smart-transcript/`.

Para reportar bugs o sugerir mejoras, contacta con el maintainer o modifica directamente.

## License

MIT
