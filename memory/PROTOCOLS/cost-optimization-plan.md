# Plan de Optimización de Costos

**Creado:** 2026-02-20  
**Motivo:** Consumo actual (~€570/mes proyectado) no es sostenible para salario medio  
**Objetivo:** Reducir a €150-200/mes máximo sin perder funcionalidad crítica

## Análisis actual (febrero 2026)

### Consumo por modelo:
- **Opus 4.6:** €275 (68%) - Día 19 feb intensivo con Notion
- **Sonnet 4.5:** €110 (27%)
- **Haiku 4.5 + otros:** €20 (5%)

**Proyección:** €570-620/mes

### Desglose por uso:
- **Sesiones directas (Manu ↔ Lola):** ~60-70% del costo
  - Sonnet dominante
  - Opus ocasional (sub-agentes complejos)
- **Crons automatizados:** ~5% (todo Haiku ya)
- **Sub-agentes investigación:** ~25-30% (mayormente Opus)

## Estrategias de optimización

### 1. Cambio de modelo por defecto ⭐ PRIORITARIO

**Estado actual:** Sonnet 4.5 por defecto  
**Propuesta:** Haiku 4.5 por defecto

**Impacto estimado:**
- Reducción: ~60-70% del costo de sesiones directas
- De ~€350/mes → ~€70-100/mes
- **Ahorro:** ~€250/mes

**Trade-offs:**
- ✅ Haiku es muy capaz para mayoría de tareas
- ✅ Más rápido (menor latencia)
- ⚠️ Menos profundidad en análisis complejos
- ⚠️ Manu necesitará pedir Sonnet/Opus explícitamente cuando necesite calidad premium

**Implementación:**
```bash
# Cambiar modelo por defecto en config
openclaw config set agents.defaults.model "anthropic/claude-haiku-4-5"

# Manu puede pedir Sonnet/Opus cuando quiera:
# /model sonnet
# /model opus
```

### 2. Sub-agentes con Haiku por defecto

**Estado actual:** Algunos usan Opus  
**Propuesta:** Usar Haiku salvo investigación compleja

**Implementación:**
- `sessions_spawn` siempre especificar `model="haiku"` salvo caso crítico
- Solo Opus para: investigación técnica profunda, análisis complejos

**Ahorro:** ~€50-80/mes

### 3. Compactación agresiva

**Estado actual:** `reserveTokensFloor: 5000`  
**Propuesta:** Reducir a `3000-4000`

**Beneficio:** Menos tokens en contexto = menos costo por request

**Implementación:**
```bash
openclaw config set agents.defaults.compaction.reserveTokensFloor 3500
```

**Ahorro:** ~5-10% del costo total

### 4. Crons optimizados

**Estado actual:** Ya todo en Haiku ✅  
**Mejora adicional:** Reducir frecuencia de alertas no críticas

Ejemplos:
- Garmin alertas: 2x/día → 1x/día
- Fail2ban: cada 6h → 1x/día
- Reducir timeout de crons (menos tokens si falla)

**Ahorro:** ~€5-10/mes

### 5. Memoria más eficiente

**Estado actual:** Memoria modular implementada ✅  
**Mejora adicional:**
- Compactar memoria mensualmente (archivar meses antiguos)
- Cargar solo últimos 7 días en contexto por defecto
- MEMORY.md solo esencial (no todo el historial)

**Ahorro:** Indirecto, pero reduce tokens por conversación

### 6. Límites y alertas

**Implementación en Anthropic Console:**
1. Configurar "Monthly spend limit": $200 (€185)
2. Alerta email al 50%, 80%, 90%
3. **Hard stop al 100%** → Lola se detiene automáticamente

**Script de monitoreo:**
```bash
# Crear alerta si consumo diario > $10
if [ $(daily_cost) -gt 10 ]; then
  notify "⚠️ Alto consumo hoy: $X - revisar uso"
fi
```

## Plan de implementación

### Fase 1 (INMEDIATO - esta noche):
- [ ] Cambiar modelo por defecto a Haiku
- [ ] Configurar límite mensual en Anthropic Console ($200)
- [ ] Documentar cómo Manu puede cambiar a Sonnet/Opus cuando quiera
- [ ] Añadir tarea de fondo en Notion: investigar alternativas de modelos

### Fase 2 (próximos 7 días):
- [ ] Revisar todos los sub-agentes y cambiar a Haiku por defecto
- [ ] Optimizar compactación (reserveTokensFloor: 3500)
- [ ] Reducir frecuencia de alertas no críticas
- [ ] Monitoreo diario de consumo

### Fase 3 (próximas 2 semanas):
- [ ] Analizar qué tareas realmente necesitan Sonnet vs Haiku
- [ ] Crear "profile" de uso: qué modelo para qué tipo de tarea
- [ ] Investigar modelos alternativos más baratos (Gemini Flash, etc.)

### Fase 4 (largo plazo):
- [ ] Feature request a OpenClaw: cambio automático de modelo según contexto
- [ ] Evaluar modelos locales (Ollama) para tareas simples
- [ ] Explorar fine-tuning de modelo más barato con nuestro estilo

## Proyección de ahorro

**Escenario conservador (Fase 1+2):**
- Actual: €570/mes
- Tras optimización: €150-200/mes
- **Ahorro: ~€350-420/mes (~60-70%)**

**Composición nueva:**
- Haiku (sesiones directas): €70-100
- Sonnet (cuando Manu pida explícitamente): €30-50
- Opus (investigación crítica): €20-30
- Crons + automatización: €20
- **Total: €140-200/mes**

## Seguimiento

### KPIs mensuales:
- Costo total mes
- Distribución por modelo (%)
- Costo por día promedio
- Alertas de consumo alto
- Tareas que requirieron Sonnet/Opus (justificación)

### Revisión:
- Semanal: Revisar si estamos en track (€30-50/semana)
- Mensual: Ajustar estrategia según resultados reales

## Alternativas a investigar (tarea de fondo)

1. **Gemini 2.0 Flash** (~10x más barato que Sonnet)
   - Ya configurado en OpenClaw
   - Evaluar calidad para tareas rutinarias
   
2. **Modelos locales (Ollama)**
   - Llama 3.1, Mistral, etc.
   - Costo = 0 (solo electricidad)
   - Trade-off: calidad y velocidad
   
3. **OpenAI GPT-4o-mini**
   - ~5x más barato que Sonnet
   - Evaluar vs Haiku
   
4. **Mezcla estratégica:**
   - Haiku: 80% de tareas
   - Gemini Flash: tareas visuales, resúmenes
   - Sonnet: análisis complejos
   - Opus: solo investigación crítica

## Nota importante

**Para Manu:**
- Cambiar a Haiku por defecto NO significa perder calidad en todo
- Haiku es MUY capaz para la mayoría de conversaciones
- Cuando necesites análisis profundo: `/model sonnet` o `/model opus`
- El ahorro (~€350/mes) vale la pena el pequeño cambio de workflow

**Para Lola (yo):**
- Mantener calidad de respuestas incluso con Haiku
- Ser consciente del costo en cada decisión (sub-agentes, thinking, etc.)
- Sugerir Sonnet/Opus solo cuando realmente aporte valor
- Optimizar tokens: respuestas concisas, evitar repetición
