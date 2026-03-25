# Changelog

## [1.0.0] - 2026-03-24

### ✨ Features

- **Arquitectura de 3 capas** con fallback progresivo:
  - Capa 3 (Caché): Almacenamiento local para evitar re-procesamiento
  - Capa 1 (Subtítulos nativos): Extracción gratuita desde YouTube
  - Capa 2 (Whisper API): Fallback con OpenAI cuando no hay subtítulos
  
- **Múltiples formatos de salida**:
  - `text`: Texto plano (default)
  - `json`: JSON con timestamps y metadata
  - `srt`: Formato de subtítulos estándar
  
- **Sistema de caché inteligente**:
  - Guarda transcripciones procesadas en `~/.openclaw/workspace/youtube-transcripts/`
  - Flag `--force-refresh` para ignorar caché
  
- **Soporte multi-idioma**:
  - Prioridad de idiomas configurable (e.g., `--lang es,en`)
  - Fallback automático si el idioma preferido no está disponible
  
- **Metadata detallada**:
  - Método usado (native_captions, whisper_api, cache)
  - Idioma detectado
  - Idiomas disponibles
  - Coste estimado ($0.00 para nativos, $0.006/min para Whisper)
  - Duración del vídeo
  - Timestamp de procesamiento
  
- **Manejo robusto de errores**:
  - Vídeos no disponibles / privados / geobloqueados
  - Vídeos sin subtítulos en el idioma solicitado
  - IPs bloqueadas por YouTube (con sugerencias de solución)
  - API keys faltantes o inválidas
  
- **Optimización de costes**:
  - Descarga solo audio (no vídeo completo) para Whisper API
  - Caché para evitar re-procesar vídeos
  - Priorización de métodos gratuitos (nativos > Whisper)

### 🛠️ Technical Details

- **Dependencias:**
  - `youtube-transcript-api` 1.2.4 (requerido)
  - `yt-dlp` 2026.3.17 (opcional, para Whisper fallback)
  - `openai` 2.29.0 (opcional, para Whisper fallback)
  
- **CLI executable:** `youtube-smart-transcript.py`
- **Instalación:** Script `install.sh` automatizado
- **Documentación completa:** `SKILL.md`
- **Test report:** `TEST-REPORT.md`

### 📊 Testing

- ✅ Extracción de subtítulos nativos (Capa 1)
- ✅ Sistema de caché (Capa 3)
- ✅ Formatos text, JSON, SRT
- ✅ Fallback de idiomas (es,en → en)
- ✅ Manejo de errores (vídeos no disponibles)
- ✅ Flag --force-refresh
- ✅ Flag --metadata
- ⏳ Capa 2 (Whisper API) — no probada (requiere API key)

### 🎯 Performance

| Operación | Tiempo | Coste |
|-----------|--------|-------|
| Extracción inicial (Capa 1) | ~1-2s | $0.00 |
| Desde caché (Capa 3) | <0.1s | $0.00 |
| Whisper API (estimado) | ~10-20s | ~$0.006/min |

### 📝 Known Limitations

- VPS en clouds públicos (AWS, GCP, Azure) pueden estar bloqueados por YouTube
  - **Solución:** Configurar Tailscale exit node o usar Whisper API fallback
- Whisper API requiere OPENAI_API_KEY configurada
- No soporta vídeos privados sin autenticación
- No incluye diarización (identificación de speakers)

### 🚀 Future Enhancements (Opcional)

- [ ] Auto-limpieza de caché antiguo (>30 días)
- [ ] Soporte para playlists (procesar múltiples vídeos)
- [ ] Flag `--translate` para traducción automática de subtítulos
- [ ] Integración con proxy SOCKS5 configurable
- [ ] Modo batch: procesar lista de URLs desde archivo
- [ ] Progress bar para descargas largas
- [ ] Webhook/callback para procesamiento asíncrono

---

## Versioning

Este proyecto sigue [Semantic Versioning](https://semver.org/):
- MAJOR: Cambios incompatibles en API/CLI
- MINOR: Nuevas features compatibles
- PATCH: Bug fixes

## Maintainer

Desarrollado para OpenClaw por subagent (2026-03-24)
