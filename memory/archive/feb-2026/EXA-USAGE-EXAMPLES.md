# EXA Search - Cómo usarlo (Ejemplos reales)

## 1️⃣ Búsquedas manuales (desde terminal)

```bash
# Búsqueda simple
~/.openclaw/workspace/scripts/exa-search.sh "Python 3.13 features" 5

# Pocos resultados
~/.openclaw/workspace/scripts/exa-search.sh "Anthropic Claude updates" 2

# Búsqueda específica
~/.openclaw/workspace/scripts/exa-search.sh "Argentina economía 2026" 10
```

## 2️⃣ Búsquedas desde Telegram (pidiéndome directamente)

Cuando escribas en Telegram:

> "Búscame las últimas noticias sobre quantum computing"

**Yo haré internamente:**
```bash
exa-search.sh "latest quantum computing news 2026" 5
```

**Y te responderé en Telegram:**
```
🔍 Buscando: quantum computing news

📄 Quantum Computing Breakthrough 2026
🔗 https://example.com/...
📝 (preview del contenido)

📄 IBM Quantum Advances
🔗 https://example.com/...
📝 (preview)

...
```

## 3️⃣ Búsquedas automáticas programadas

**Cada LUNES a las 8 AM:**
- "📰 EXA: AI News"
- Recibes automáticamente en Telegram las 5 últimas noticias de IA

**Cada VIERNES a las 5 PM:**
- "🚀 EXA: Startup Trends"
- Recibes automáticamente las 4 últimas novedades en startups y funding

*Nota: Se ejecutarán automáticamente — sin que tengas que hacer nada*

## Ejemplos de búsquedas que puedes pedirme

### Noticias y actualidad
- "¿Qué pasa en IA estos días?"
- "Dame las últimas noticias sobre Anthropic"
- "¿Cuál es la actualidad en ciberseguridad?"

### Análisis temático
- "Búscame artículos sobre sostenibilidad en tech"
- "¿Qué dicen sobre el impacto de IA en educación?"
- "Última información sobre fusiones y adquisiciones en tech"

### Búsquedas específicas
- "Localiza blogs sobre prompt engineering"
- "¿Hay novedades en el protocolo MCP?"
- "¿Qué está pasando con los reguladores y IA?"

## Cómo funciona internamente

1. **Pides algo:** "Búscame sobre X"
2. **Yo traducto:** A formato de búsqueda optimizado
3. **Ejecuto:** Script `exa-search.sh` con curl a API de Exa
4. **Parse:** Extrae título, URL y preview (primeros 300 caracteres)
5. **Envío:** Te devuelvo los resultados formateados

## Personalizaciones posibles

Si quieres cambiar:
- **Temas de búsqueda:** Editar en `memory/exa-search-crons.json`
- **Horarios:** Modificar crons en OpenClaw
- **Número de resultados:** Cambiar parámetro num_results

---

**Estado:** ✅ Operacional
**Últimas búsquedas:** 2026-02-23 (test exitoso)
**Próxima ejecución programada:** Lunes 24 Feb 8 AM
