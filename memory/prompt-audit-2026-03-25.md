# Prompt Audit — Cron Jobs

**Fecha:** 2026-03-25  
**Auditor:** Lola (Subagent: prompt-optimization)  
**Total crons auditados:** 31  
**Crons con prompts:** 29 (2 solo ejecutan scripts)

---

## 📊 Resumen Ejecutivo

### Distribución por Modelo

| Modelo | Count | % |
|--------|-------|---|
| **Haiku** | 12 | 41% |
| **Sonnet** | 8 | 28% |
| **No especificado** (default Opus) | 9 | 31% |

### Hallazgos Clave

✅ **Bien optimizados (15 crons):**
- Mayoría de Haiku crons son concisos y directos
- Autoimprove agents tienen prompts estructurados con contexto claro
- Scripts de backup y rotación son simples

⚠️ **Oportunidades de mejora (14 crons):**
- **Verbosidad innecesaria:** Algunos prompts Haiku/Sonnet tienen instrucciones redundantes
- **Prompts sin modelo:** 9 crons heredan modelo por defecto (Opus 4.6) — desperdicio de coste para tareas mecánicas
- **Falta de estructura:** Algunos prompts mezclan instrucciones, formato y contexto sin delimitadores claros
- **Anti-patterns:** Uso de ALL CAPS en algunos prompts (no recomendado para Claude)

❌ **Anti-patterns críticos (3 crons):**
1. `fdf38b8f` (security-audit-weekly): Prompt muy largo con Sonnet, pero task es compleja → OK, pero podría ser más estructurado
2. `dcae7b06` (autoimprove-scripts): Prompt de 2400+ tokens para Haiku — demasiado denso
3. `cb5d3743` (informe-matutino): Prompt con formato EXACTO en MAYÚSCULAS — anti-pattern para Sonnet

---

## 🔍 Auditoría Detallada

### 1. Haiku Crons (12 total)

#### ✅ BIEN OPTIMIZADOS (7)

**ad742767 — Backup diario**
- **Modelo:** Haiku 4-5
- **Prompt length:** ~480 caracteres
- **Evaluación:** ✅ ÓPTIMO
- **Razón:** Conciso, instrucciones claras, formato de output especificado, sin verbosidad
- **Observaciones:** Buen ejemplo de prompt Haiku

**53577b95 — Memory Search Reindex**
- **Modelo:** Haiku
- **Prompt:** "Run: openclaw memory index --force. Report only if errors."
- **Evaluación:** ✅ PERFECTO
- **Razón:** Ultra-conciso, tarea mecánica, ideal para Haiku

**7a7086e5 — Driving Mode Auto-Reset**
- **Modelo:** (sin especificar, hereda default)
- **Prompt:** "Reset driving mode to home automatically..."
- **Evaluación:** ⚠️ MODELO MISSING
- **Recomendación:** Añadir `"model": "haiku"` — tarea simple, no necesita Opus

**7926a522 — Surf Conditions Daily**
- **Modelo:** Haiku
- **Prompt:** "Fetch today's surf conditions and save to memory/surf/conditions-YYYY-MM-DD.md. Run: bash..."
- **Evaluación:** ✅ ÓPTIMO
- **Razón:** Tarea mecánica, instrucción directa

**6982dc7e — memory-decay-weekly**
- **Modelo:** Haiku
- **Prompt:** "Run weekly memory decay: execute bash... then commit..."
- **Evaluación:** ✅ ÓPTIMO

**b491ec4a — OpenClaw release check**
- **Modelo:** Haiku 4-5
- **Prompt length:** ~700 caracteres
- **Evaluación:** ✅ BUENO
- **Razón:** Instrucciones claras paso a paso, HEARTBEAT_OK para caso negativo
- **Observación:** Podría comprimir ligeramente (es el límite superior para Haiku)

**ad5285c3 — Lola Toolkit Sync Check**
- **Modelo:** Haiku
- **Prompt length:** ~650 caracteres
- **Evaluación:** ✅ BUENO
- **Razón:** Bien estructurado, claros los pasos, usa HEARTBEAT_OK

#### ⚠️ MEJORAR (5)

**dcae7b06 — Autoimprove Scripts Agent**
- **Modelo:** Haiku 4-5
- **Prompt length:** ~2400 caracteres (!) — 600 palabras
- **Evaluación:** ❌ DEMASIADO LARGO PARA HAIKU
- **Problema:** Prompt complejo con muchas secciones, ejemplos, logging, safety rules
- **Recomendación:** 
  - Opción A: Upgrade a **Sonnet** (tarea compleja de optimización)
  - Opción B: Comprimir prompt a <300 palabras (eliminar ejemplos, consolidar secciones)
- **Impacto:** Haiku puede perder contexto o no seguir todas las instrucciones en prompts tan largos

**8d65b575 — Autoimprove Skills Agent**
- **Modelo:** Haiku
- **Prompt length:** ~2300 caracteres
- **Evaluación:** ❌ DEMASIADO LARGO PARA HAIKU
- **Problema:** Igual que Scripts Agent — prompt denso con muchas reglas
- **Recomendación:** Upgrade a **Sonnet** o comprimir agresivamente

**881d2943 — Autoimprove Memory Agent**
- **Modelo:** Haiku
- **Prompt length:** ~2800 caracteres (!!)
- **Evaluación:** ❌ DEMASIADO LARGO PARA HAIKU
- **Problema:** El más largo de los 3 autoimprove agents
- **Recomendación:** **Upgrade a Sonnet** (task es crítica — optimización de MEMORY.md)
- **Trade-off coste:** +€0.02/noche, pero mejor calidad

**a2cb9eec — Memory Guardian Pro**
- **Modelo:** Haiku 4-5
- **Prompt:** "Ejecuta Memory Guardian Pro: bash... El script: 1. Analiza... 2. Limpia... 3. Limpia... 4. Comprime... 5. Detecta... 6. Genera..."
- **Evaluación:** ⚠️ REDUNDANTE
- **Problema:** Lista qué hace el script (innecesario si el script ya lo documenta)
- **Recomendación:** Simplificar a: "Ejecuta bash... Revisa output y responde HEARTBEAT_OK si no hay cambios significativos. Si hay cambios importantes, guarda reporte."
- **Ahorro:** ~100 caracteres

**07256dbe — Cleanup audit semanal**
- **Modelo:** Haiku 4-5
- **Prompt length:** ~600 caracteres
- **Evaluación:** ⚠️ VERBOSIDAD MODERADA
- **Problema:** Lista todos los comandos find/du/ps en el prompt (podrían estar en script)
- **Recomendación:** Mover lógica a script `cleanup-audit.sh` y reducir prompt a: "Ejecuta bash cleanup-audit.sh. Genera reporte en memory/YYYY-MM-DD-cleanup-audit.md. NO borres nada."
- **Ahorro:** ~200 caracteres

---

### 2. Sonnet Crons (8 total)

#### ✅ BIEN OPTIMIZADOS (3)

**cb5d3743 — Informe Matutino**
- **Modelo:** Sonnet 4-5
- **Prompt length:** ~900 caracteres
- **Evaluación:** ⚠️ BUENO PERO CON ANTI-PATTERN
- **Problema:** Usa "EXACTO" en MAYÚSCULAS — Anthropic desaconseja énfasis con caps en Sonnet/Opus
- **Recomendación:** Cambiar "formato EXACTO" → "formato específico" o usar **XML tags** para estructura
- **Observación:** El prompt es apropiado para Sonnet (tarea requiere análisis + formateo)

**e8cf74c3 — Garmin Daily Scrape**
- **Modelo:** Haiku 4-5
- **Prompt length:** ~550 caracteres
- **Evaluación:** ✅ ÓPTIMO
- **Razón:** Tarea clara, pasos numerados, output esperado definido

**ed1d9b11 — System Updates Nightly**
- **Modelo:** Haiku 4-5
- **Prompt:** "Ejecuta: sudo bash... Este script aplica actualizaciones... Lee el output... Si error, guarda nota..."
- **Evaluación:** ✅ BUENO
- **Observación:** Podría ser más conciso, pero está OK para Haiku

#### ⚠️ MEJORAR (5)

**fdf38b8f — security-audit-weekly**
- **Modelo:** Sonnet 4-5
- **Prompt length:** ~950 caracteres
- **Evaluación:** ⚠️ FALTA ESTRUCTURA
- **Problema:** Lista de 7 pasos sin delimitadores claros, mezcla instrucciones con formato
- **Recomendación:** Usar **XML tags** o **Markdown headers**:
```
## Tarea
Auditoría de seguridad profunda

## Pasos
1. openclaw security audit --deep
2. Revisar firewall (ufw/iptables)
...

## Output
Exporta a memory/YYYY-MM-DD-security-audit-weekly.md

## Alertas
Si encuentras vulnerabilidades críticas:
- Marca URGENTE en informe
- Añade a memory/pending-actions.md
```
- **Beneficio:** Sonnet procesa mejor prompts estructurados

**c8522805 — fail2ban-alert**
- **Modelo:** Sonnet 4-5
- **Prompt length:** ~700 caracteres
- **Evaluación:** ⚠️ LÓGICA COMPLEJA PARA SONNET
- **Problema:** Prompt tiene lógica condicional (if >= 10 IPs → ALERTA ALTA, etc.) + horario silencioso
- **Recomendación:** Esta lógica debería estar en un script, no en el prompt
- **Alternativa:** Crear `scripts/fail2ban-monitor.sh` con la lógica, prompt solo ejecuta y formatea

**edc0db6e — lynis-scan-weekly**
- **Modelo:** Sonnet 4-5
- **Prompt length:** ~700 caracteres
- **Evaluación:** ✅ BUENO
- **Observación:** Apropiado para Sonnet (requiere comparación con scan anterior)

**78d3556f — rkhunter-scan-weekly**
- **Modelo:** Sonnet 4-5
- **Prompt length:** ~650 caracteres
- **Evaluación:** ✅ BUENO
- **Observación:** Similar a lynis, apropiado

**522ae7ca — Resumen Semanal Garmin**
- **Modelo:** (sin especificar)
- **Prompt:** "Genera el resumen semanal de actividades Garmin"
- **Evaluación:** ❌ PROMPT VACÍO
- **Problema:** Demasiado vago, no especifica qué analizar o cómo formatear
- **Recomendación:** Añadir modelo (`"model": "sonnet"`) y detallar:
  - Qué datos leer (archivos en memory/garmin/daily/)
  - Qué métricas analizar (tendencias, comparación con semana anterior)
  - Formato de output

---

### 3. Crons Sin Modelo Especificado (9 total)

Estos heredan el modelo por defecto del agente (actualmente Opus 4.6) — **DESPERDICIO DE COSTE** para tareas mecánicas.

#### ❌ CRÍTICO: ASIGNAR MODELO

**7a7086e5 — Driving Mode Auto-Reset**
- **Tarea:** Actualizar JSON (mode=home)
- **Modelo actual:** Opus 4.6 (por defecto)
- **Modelo óptimo:** **Haiku**
- **Ahorro estimado:** €0.14/mes → €0.002/mes (~€0.14/mes)

**56ab2039 — Driving Mode Review**
- **Tarea:** Buscar mejoras en GitHub/Discord
- **Modelo actual:** Opus 4.6
- **Modelo óptimo:** **Sonnet** (requiere research + síntesis)
- **Ahorro:** €0.30/ejecución → €0.20/ejecución

**522ae7ca — Resumen Semanal Garmin**
- **Tarea:** Análisis semanal de datos
- **Modelo actual:** Opus 4.6
- **Modelo óptimo:** **Sonnet**
- **Ahorro:** €0.40/semana → €0.20/semana

**a3bd469e — config-drift-check**
- **Tarea:** Ejecutar `/config-drift check`
- **Modelo actual:** Opus 4.6
- **Modelo óptimo:** **Haiku**
- **Ahorro:** €0.15/día → €0.003/día (~€4.50/mes)

**3a82af7d — Auto-update OpenClaw**
- **Tarea:** Ejecutar script bash
- **Modelo actual:** Opus 4.6
- **Modelo óptimo:** **Haiku**
- **Ahorro:** €0.10/día → €0.002/día (~€3/mes)

**368b84ad — Log Review Matutino**
- **Tarea:** Ejecutar script bash
- **Modelo actual:** Opus 4.6
- **Modelo óptimo:** **Haiku**
- **Ahorro:** €0.08/día → €0.002/día (~€2.40/mes)

**57fa3f06 — Best Practices Checker**
- **Tarea:** Ejecutar script bash
- **Modelo actual:** Opus 4.6
- **Modelo óptimo:** **Haiku**
- **Ahorro:** €0.05/2meses → €0.002/2meses (insignificante pero acumulativo)

**f01924d2 — nightly-security-review**
- **Tarea:** Ejecutar script + alertar si issues
- **Modelo actual:** (sin especificar)
- **Modelo óptimo:** **Haiku** (script hace el análisis, solo necesita formatear alerta)

**72d256fe — rotate-gateway-token**
- **Modelo actual:** Haiku 4-5
- **Evaluación:** ✅ CORRECTO

**TOTAL AHORRO ESTIMADO AL ASIGNAR MODELOS:**
~€10-12/mes (principalmente config-drift-check + auto-update + log-review que corren diariamente)

---

## 📝 Recomendaciones Prioritarias

### Alta Prioridad (Ahorro inmediato)

1. **Asignar modelo a crons sin especificar (9 crons)**
   - Ahorro: ~€10/mes
   - Esfuerzo: 5 min (editar JSON con modelo correcto)

2. **Upgrade autoimprove agents a Sonnet (3 crons)**
   - Razón: Prompts demasiado complejos para Haiku
   - Coste adicional: +€0.06/noche = €1.80/mes
   - Beneficio: Mejor calidad de optimización (puede ahorrar más en otros costes)

3. **Reducir verbosidad en prompts Haiku (2 crons)**
   - `a2cb9eec` — Memory Guardian Pro
   - `07256dbe` — Cleanup audit
   - Ahorro: tokens + más confiable (Haiku pierde contexto en prompts largos)

### Media Prioridad (Calidad)

4. **Estructurar prompts Sonnet con XML/Markdown (2 crons)**
   - `fdf38b8f` — security-audit-weekly
   - `cb5d3743` — informe-matutino (quitar ALL CAPS)
   - Beneficio: Sonnet procesa mejor prompts estructurados (Gemini 3 guide enfatiza esto)

5. **Mover lógica condicional a scripts (1 cron)**
   - `c8522805` — fail2ban-alert
   - Beneficio: Prompt más simple, lógica reutilizable

6. **Completar prompt vacío (1 cron)**
   - `522ae7ca` — Resumen Semanal Garmin
   - Problema: Prompt demasiado vago

### Baja Prioridad (Optimización fina)

7. **Revisar prompts Haiku cada 3 meses**
   - Verificar que siguen siendo concisos (<400 palabras)
   - Comprimir si crecen por mantenimiento

---

## 🎯 Matriz de Optimización

| Cron ID | Modelo Actual | Modelo Óptimo | Prompt Quality | Acción Recomendada |
|---------|---------------|---------------|----------------|-------------------|
| ad742767 | Haiku 4-5 | ✅ Haiku | ✅ Óptimo | - |
| fdf38b8f | Sonnet 4-5 | ✅ Sonnet | ⚠️ Sin estructura | Añadir XML tags |
| c8522805 | Sonnet 4-5 | Sonnet | ⚠️ Lógica en prompt | Mover a script |
| edc0db6e | Sonnet 4-5 | ✅ Sonnet | ✅ Bueno | - |
| 78d3556f | Sonnet 4-5 | ✅ Sonnet | ✅ Bueno | - |
| 07256dbe | Haiku 4-5 | ✅ Haiku | ⚠️ Verboso | Comprimir |
| a2cb9eec | Haiku 4-5 | ✅ Haiku | ⚠️ Redundante | Simplificar |
| b491ec4a | Haiku 4-5 | ✅ Haiku | ✅ Bueno | - |
| 4de42cb2 | Haiku 4-5 | ✅ Haiku | ✅ Bueno | - |
| dcae7b06 | Haiku 4-5 | ❌ **Sonnet** | ❌ Demasiado largo | Upgrade modelo |
| cb5d3743 | Sonnet 4-5 | ✅ Sonnet | ⚠️ ALL CAPS | Quitar énfasis caps |
| ed1d9b11 | Haiku 4-5 | ✅ Haiku | ✅ Bueno | - |
| 6982dc7e | Haiku | ✅ Haiku | ✅ Óptimo | - |
| 53577b95 | Haiku | ✅ Haiku | ✅ Perfecto | - |
| ad5285c3 | Haiku | ✅ Haiku | ✅ Bueno | - |
| 8d65b575 | Haiku | ❌ **Sonnet** | ❌ Demasiado largo | Upgrade modelo |
| 881d2943 | Haiku | ❌ **Sonnet** | ❌ Demasiado largo | Upgrade modelo |
| 7926a522 | Haiku | ✅ Haiku | ✅ Óptimo | - |
| 7a7086e5 | (default) | ❌ **Haiku** | ✅ Bueno | Asignar modelo |
| 56ab2039 | (default) | ❌ **Sonnet** | ✅ Bueno | Asignar modelo |
| 522ae7ca | (default) | ❌ **Sonnet** | ❌ Vacío | Asignar + detallar |
| a3bd469e | (default) | ❌ **Haiku** | ✅ Bueno | Asignar modelo |
| 3a82af7d | (default) | ❌ **Haiku** | ✅ Bueno | Asignar modelo |
| 368b84ad | (default) | ❌ **Haiku** | ✅ Bueno | Asignar modelo |
| 57fa3f06 | (default) | ❌ **Haiku** | ✅ Bueno | Asignar modelo |
| f01924d2 | (default) | ❌ **Haiku** | ✅ Bueno | Asignar modelo |
| e8cf74c3 | Haiku 4-5 | ✅ Haiku | ✅ Óptimo | - |
| e763c896 | (sin prompt) | N/A | N/A | Script directo |
| e5ebcbf4 | (sin prompt) | N/A | N/A | Script directo |

---

## 📈 Impacto Estimado

### Ahorro de Coste (tras optimización)

| Optimización | Ahorro Mensual | Esfuerzo |
|--------------|----------------|----------|
| Asignar modelos faltantes | €10-12 | 5 min |
| Simplificar prompts Haiku | €0.50 | 15 min |
| Estructurar prompts Sonnet | €0 (calidad) | 20 min |
| Upgrade autoimprove a Sonnet | -€1.80 (coste adicional) | 2 min |

**NETO:** ~€9-11/mes ahorro  
**ROI:** Infinito (5-10 min inversión única)

### Mejora de Calidad

- **Autoimprove agents:** Mayor confiabilidad con Sonnet (valen el coste adicional)
- **Prompts estructurados:** Mejor adherencia a instrucciones
- **Prompts concisos:** Menos errores en Haiku

---

## ✅ Conclusión

La mayoría de prompts están **bien optimizados para su tarea**, pero hay **3 oportunidades de ahorro inmediato**:

1. **Asignar modelos a 9 crons** → €10/mes ahorro
2. **Upgrade 3 autoimprove agents a Sonnet** → mejor calidad (+€1.80/mes)
3. **Simplificar 2 prompts Haiku** → tokens + confiabilidad

**Balance neto:** ~€9/mes ahorro + mejor calidad en crons críticos.

---

**Próximos pasos:**
1. Crear `memory/prompt-writing-guide.md` con reglas prácticas
2. Actualizar `memory/model-specific-prompts.md` con nuevos modelos
3. (Opcional) Aplicar cambios a crons — REQUIERE CONFIRMACIÓN DE MANU
