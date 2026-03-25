# Best Practices Checker - Implementación

**Fecha de implementación:** 2026-03-24  
**Status:** ✅ Activo

## Descripción

Sistema automático que descarga y compara las best practices de prompting de cada provider (Anthropic, Google, OpenAI) cada 2 meses, y se activa automáticamente cuando se detecta un modelo nuevo.

## Componentes

### 1. Scripts

#### `scripts/best-practices-checker.sh`
- **Función:** Descarga las best practices de los 3 providers y genera diffs con versiones anteriores
- **Fuentes:**
  - Anthropic: https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview
  - Google: https://ai.google.dev/gemini-api/docs/prompting-strategies
  - OpenAI: https://platform.openai.com/docs/guides/prompt-engineering
- **Salida:**
  - `memory/best-practices/{provider}-YYYY-MM-DD.md` (una por provider)
  - `memory/best-practices/changelog.md` (historial de cambios)
- **Método:** web_fetch con fallback a curl
- **Comportamiento:**
  - Primera ejecución → crea baseline (sin comparación)
  - Ejecuciones posteriores → compara con versión más reciente
  - Si hay cambios significativos → genera diff detallado en changelog

#### `scripts/model-release-checker.sh`
- **Función:** Detecta nuevos modelos en OpenClaw y trigger del best practices checker
- **Estado:** `memory/best-practices/known-models.json`
- **Comportamiento:**
  - Compara modelos actuales con lista guardada
  - Si detecta nuevo modelo → ejecuta `best-practices-checker.sh`
  - Actualiza JSON con timestamp y historial
- **Opciones:**
  - Sin argumentos: check normal
  - `--force`: ejecuta best-practices-checker sin comparar modelos

### 2. Cron Job

**ID:** `57fa3f06-705d-4f24-9b71-07706787a76a`  
**Nombre:** Best Practices Checker (Bimensual)  
**Schedule:** `0 3 1 */2 *` (día 1 de cada 2 meses, 3:00 AM Madrid)  
**Delivery:** none (silent, resultados en memoria)  
**Comando:** `bash scripts/best-practices-checker.sh`

**Próxima ejecución:** Mayo 1, 2026 - 03:00 AM

### 3. Hook en Auto-Update

**Ubicación:** `scripts/auto-update-openclaw.sh`

Cuando se detecta un update de OpenClaw:
1. Parsea el changelog
2. Si menciona palabras clave de modelos (model, gemini, claude, gpt, opus, sonnet, haiku)
3. → Ejecuta `model-release-checker.sh`
4. → Si hay modelos nuevos → ejecuta `best-practices-checker.sh`

## Estructura de Archivos

```
memory/best-practices/
├── anthropic-2026-03-24.md       (284K - baseline)
├── google-2026-03-24.md          (142K - baseline)
├── openai-2026-03-24.md          (7.2K - baseline)
├── known-models.json             (tracking de modelos)
└── changelog.md                  (historial de cambios)
```

**Baseline creado:** 2026-03-24 21:08:02  
**Modelos conocidos (baseline):** 8
- google/gemini-3-flash-preview (default)
- anthropic/claude-sonnet-4-5
- anthropic/claude-opus-4-6
- anthropic/claude-haiku-4-5
- google/gemini-3-pro-preview
- google/gemini-2.5-flash
- google/gemini-2.5-pro
- google/gemini-2.5-flash-lite

## Uso Manual

### Ejecutar best practices checker manualmente
```bash
bash scripts/best-practices-checker.sh
```

### Ejecutar model release checker manualmente
```bash
bash scripts/model-release-checker.sh
```

### Forzar best practices check (sin comparar modelos)
```bash
bash scripts/model-release-checker.sh --force
```

### Ver próximo cron run
```bash
openclaw cron list | grep "Best Practices"
```

## Logs y Monitoring

- **Logs del cron:** OpenClaw session logs (isolated sessions)
- **Changelog:** `memory/best-practices/changelog.md`
- **Model history:** `memory/best-practices/known-models.json` → `.history[]`

## Integración con model-specific-prompts.md

**TODO:** Actualizar `memory/model-specific-prompts.md` con referencias a las best practices descargadas.

Estructura propuesta:
```markdown
## Referencias Actualizadas

Las best practices oficiales se descargan automáticamente cada 2 meses:
- Ver archivos más recientes en `memory/best-practices/`
- Changelog de cambios: `memory/best-practices/changelog.md`

**Última actualización:** [date from most recent file]
```

## Troubleshooting

### Si la descarga falla
- Verificar conectividad a Internet
- Comprobar que curl esté instalado
- Revisar si las URLs de las best practices han cambiado

### Si el cron no se ejecuta
```bash
openclaw cron list --json | jq '.[] | select(.name | contains("Best Practices"))'
```

### Si el model checker no detecta modelos nuevos
- Verificar que `openclaw models list --json` funcione
- Comprobar formato del JSON en `known-models.json`

## Mantenimiento

- **Limpieza de archivos antiguos:** Manual (conservar últimos 3-4 por provider)
- **Rotación de changelog:** Manual cuando supere 1MB
- **Revisión de URLs:** Trimestral (verificar que las URLs sigan activas)

## Mejoras Futuras

1. **Notificación Telegram:** Cuando se detecten cambios significativos
2. **Auto-sync con model-specific-prompts.md:** Parser automático que extrae key insights
3. **Diff inteligente:** Usar LLM para resumir cambios en lugar de diff crudo
4. **Provider adicionales:** Agregar Cohere, Mistral, etc.
5. **Monitoreo de rate limits:** Integrar con API health checker

---

**Maintainer:** Lola (OpenClaw workspace)  
**Última revisión:** 2026-03-24
