# EXA Search Integration - Setup & Usage

**Fecha setup:** 2026-02-23
**Status:** ✅ Funcional - Script bash + crons + prompt integration

## Quick Start

### Manual search
```bash
~/.openclaw/workspace/scripts/exa-search.sh "tu búsqueda" 5
```

### Búsquedas desde prompts
Simplemente pide: "búscame sobre X" o "dame últimas noticias de Y"

## Configuración

### Script
- **Ubicación:** `~/.openclaw/workspace/scripts/exa-search.sh`
- **API Key:** 51f67c8b-636c-4ff3-a271-41f38735529b
- **Dependencias:** curl, jq

### Crons automáticos
- "Noticias IA" - lunes 8 AM
- "Tendencias startups" - viernes 5 PM
- (Personalizable)

## Cómo funciona

1. **Búsqueda manual:**
   ```bash
   exa-search.sh "search term" [num_results]
   ```
   Retorna: Título, URL, preview de contenido

2. **Desde prompts de Telegram:**
   - "Búscame últimas noticias sobre quantum computing"
   - Yo ejecuto `exa-search.sh` automáticamente y te devuelvo resultados con URLs

3. **Crons diarios:**
   - Se ejecutan en horarios fijos
   - Reportan directamente a Telegram
   - Temas configurables

## Ejemplos

### Terminal
```bash
$ exa-search.sh "Python 3.13 features" 3
🔍 Searching for: Python 3.13 features
📄 What's New In Python 3.13
🔗 https://docs.python.org/3.13/whatsnew/3.13.html
📝 (preview del contenido)
```

### Desde Telegram (cuando lo pidas)
> "búscame sobre las últimas IA trends"
```
🔍 Buscando: latest AI trends
📄 OpenAI Releases O1 Reasoning Model
🔗 https://example.com/...
📝 (preview)
...
```

### Cron automático (todos los lunes 8 AM)
> (Mensaje automático)
```
📰 Noticias IA - Lunes 23 Feb
- Article 1
- Article 2
...
```

## Cambiar temas de búsqueda

Editar en `memory/exa-search-crons.json`:
```json
{
  "crons": [
    {
      "name": "AI News",
      "query": "latest AI developments 2026",
      "frequency": "0 8 * * 1",
      "results": 5
    },
    {
      "name": "Startup Trends",
      "query": "new startups funding trends",
      "frequency": "0 17 * * 5",
      "results": 3
    }
  ]
}
```

## Troubleshooting

- ❌ "API Key error" → Verificar `EXA_API_KEY` en el script
- ❌ "jq not found" → `sudo apt install jq`
- ❌ "curl error" → Verificar conexión internet

## API Limits

- Requests: Sin límite explícito (plan gratuito)
- Rate: No especificado en docs
- Resultados por búsqueda: Hasta 100

---
**Próximos pasos:**
- [ ] Crear crons de ejemplo
- [ ] Testear búsquedas desde prompts
- [ ] Añadir más temas si es necesario
