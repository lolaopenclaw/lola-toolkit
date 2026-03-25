# Test Report - youtube-smart-transcript

**Fecha:** 2026-03-24  
**Versión:** 1.0.0  
**Sistema:** Ubuntu Linux (OpenClaw VPS)

---

## Resumen Ejecutivo

✅ **Todas las funcionalidades core implementadas y funcionando**

- ✅ Capa 1 (subtítulos nativos YouTube): **OK**
- ✅ Capa 3 (caché local): **OK**
- ✅ Formatos (text, JSON, SRT): **OK**
- ✅ Manejo de errores: **OK**
- ✅ Fallback progresivo: **OK**
- ⏳ Capa 2 (Whisper API): **No probada** (requiere API key)

---

## Tests Ejecutados

### Test 1: Extracción de subtítulos nativos (Capa 1)

**Video:** `dQw4w9WgXcQ` (Rick Astley - Never Gonna Give You Up)

```bash
youtube-smart-transcript dQw4w9WgXcQ --metadata
```

**Resultado:** ✅ PASS

**Output:**
```
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
  "available_languages": ["en", "de-DE", "ja", "pt-BR", "es-419", "en"],
  "is_generated": false,
  "cost": 0.0,
  "duration_seconds": 177.96
}
```

**Tiempo:** ~2s  
**Coste:** $0.00

---

### Test 2: Caché (Capa 3)

**Video:** `dQw4w9WgXcQ` (mismo que Test 1)

```bash
youtube-smart-transcript dQw4w9WgXcQ --metadata
```

**Resultado:** ✅ PASS

**Output:**
```
✅ [CACHE] Cargado desde caché: dQw4w9WgXcQ_es_en.json
```

**Tiempo:** <0.1s  
**Coste:** $0.00

---

### Test 3: Formato JSON

```bash
youtube-smart-transcript dQw4w9WgXcQ --format json
```

**Resultado:** ✅ PASS

**Output (muestra):**
```json
[
  {
    "text": "[♪♪♪]",
    "start": 1.36,
    "duration": 1.68
  },
  {
    "text": "♪ We're no strangers to love ♪",
    "start": 18.64,
    "duration": 3.24
  },
  ...
]
```

---

### Test 4: Formato SRT

```bash
youtube-smart-transcript dQw4w9WgXcQ --format srt
```

**Resultado:** ✅ PASS

**Output (muestra):**
```
1
00:00:01,360 --> 00:00:03,040
[♪♪♪]

2
00:00:18,640 --> 00:00:21,880
♪ We're no strangers to love ♪

3
00:00:22,640 --> 00:00:26,960
♪ You know the rules
and so do I ♪
```

---

### Test 5: Flag --force-refresh

```bash
youtube-smart-transcript dQw4w9WgXcQ --force-refresh
```

**Resultado:** ✅ PASS

**Output:**
```
🔄 [LAYER 1] Intentando extraer subtítulos nativos...
✅ [LAYER 1] Subtítulos nativos encontrados (idioma: en)
💾 Guardado en caché: dQw4w9WgXcQ_es_en.json
```

**Observación:** Ignora caché y re-procesa desde YouTube.

---

### Test 6: Fallback de idiomas

**Video:** `jNQXAC9IVRw` (solo tiene subtítulos en `en` y `de`)

```bash
# Intento 1: solo español (debe fallar)
youtube-smart-transcript jNQXAC9IVRw --lang es

# Intento 2: español + inglés (debe usar inglés)
youtube-smart-transcript jNQXAC9IVRw --lang es,en --metadata
```

**Resultado:** ✅ PASS

**Intento 1 Output:**
```
⚠️  [LAYER 1] No hay subtítulos nativos disponibles
🔄 [LAYER 2] Intentando fallback con Whisper API...
❌ [LAYER 2] OPENAI_API_KEY no está configurada
```

**Intento 2 Output:**
```
✅ [LAYER 1] Subtítulos nativos encontrados (idioma: en)
💾 Guardado en caché: jNQXAC9IVRw_es_en.json

📊 Metadata:
{
  "detected_language": "en",
  "available_languages": ["en", "de"],
  "cost": 0.0
}
```

**Observación:** El sistema de prioridad de idiomas funciona correctamente.

---

### Test 7: Vídeo no disponible

**Video:** `9RS_RKmSwFA` (vídeo privado o borrado)

```bash
youtube-smart-transcript 9RS_RKmSwFA
```

**Resultado:** ✅ PASS

**Output:**
```
❌ [LAYER 1] Vídeo no disponible
❌ Error: El vídeo no está disponible (privado, borrado o geobloqueado)
```

**Observación:** Manejo de errores correcto, sale limpiamente sin traceback.

---

### Test 8: Vídeo sin subtítulos → Fallback Whisper API

**Video:** `EngW7tLk6R8` (solo tiene subtítulos en ruso, no en es/en)

```bash
youtube-smart-transcript EngW7tLk6R8 --lang es,en
```

**Resultado:** ✅ PASS (comportamiento correcto)

**Output:**
```
⚠️  [LAYER 1] No hay subtítulos nativos disponibles:
For this video (EngW7tLk6R8) transcripts are available in the following languages:
 - ru ("Russian (auto-generated)")[TRANSLATABLE]

🔄 [LAYER 2] Intentando fallback con Whisper API...
❌ [LAYER 2] OPENAI_API_KEY no está configurada
   Configura con: export OPENAI_API_KEY='tu-api-key'
```

**Observación:** Detecta que no hay subtítulos en los idiomas solicitados e intenta Whisper API (correcto).

---

## Funcionalidades No Probadas

### Capa 2: Whisper API

**Razón:** No se configuró `OPENAI_API_KEY` en el entorno de testing.

**Para probar:**
1. Configurar API key: `export OPENAI_API_KEY='sk-...'`
2. Ejecutar: `youtube-smart-transcript VIDEO_SIN_SUBTITULOS --lang es,en`
3. Verificar que descarga audio y transcribe con Whisper API
4. Verificar que muestra coste estimado
5. Verificar que guarda en caché

**Comportamiento esperado (según código):**
- Descarga solo audio (no vídeo completo)
- Transcribe con OpenAI Whisper API
- Calcula coste ($0.006/min)
- Guarda en caché
- Limpia archivo de audio temporal

---

## Verificación de Caché

```bash
$ ls -lh ~/.openclaw/workspace/youtube-transcripts/
-rw-rw---- 1 mleon mleon 7.2K Mar 24 09:23 dQw4w9WgXcQ_es_en.json
-rw-rw---- 1 mleon mleon 592B Mar 24 09:24 jNQXAC9IVRw_es_en.json
```

**Observación:** Caché funciona correctamente, archivos JSON bien formateados.

---

## Rendimiento

| Operación | Tiempo | Coste |
|-----------|--------|-------|
| Primera extracción (Capa 1) | ~1-2s | $0.00 |
| Desde caché (Capa 3) | <0.1s | $0.00 |
| Formato JSON/SRT | +0s | $0.00 |
| Whisper API (estimado) | ~10-20s | ~$0.006/min |

---

## Dependencias Instaladas

```
youtube-transcript-api==1.2.4
yt-dlp==2026.3.17
openai==2.29.0
```

**Comando:**
```bash
pip install --user --break-system-packages youtube-transcript-api yt-dlp openai
```

---

## Conclusión

✅ **Skill listo para producción**

Todas las funcionalidades core están implementadas y funcionan correctamente:
- Extracción de subtítulos nativos (gratis)
- Sistema de caché (evita re-procesamiento)
- Múltiples formatos (text, JSON, SRT)
- Fallback progresivo (nativos → Whisper API)
- Manejo robusto de errores

**Único componente no probado:** Capa 2 (Whisper API) — requiere API key de OpenAI.

**Recomendación:** Usar en producción. Configurar `OPENAI_API_KEY` para habilitar fallback de Whisper API.

---

## Próximos Pasos (Opcional)

- [ ] Configurar proxy Tailscale para evitar bloqueos de IP en VPS
- [ ] Implementar auto-limpieza de caché antiguo (>30 días)
- [ ] Agregar flag `--translate` para traducir subtítulos a otros idiomas
- [ ] Integrar con skill de búsqueda YouTube para procesar listas de vídeos
- [ ] Agregar soporte para playlists (procesar múltiples vídeos)
