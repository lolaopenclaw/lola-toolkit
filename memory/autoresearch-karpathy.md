# 🔬 Autoresearch — Karpathy (Marzo 2026)

**Fecha de descubrimiento:** 2026-03-09
**Fuente:** Manu compartió tweets de Karpathy
**Repo:** https://github.com/karpathy/autoresearch
**License:** MIT

---

## Qué es

Framework minimalista de Karpathy donde un agente de IA ejecuta investigación de ML de forma autónoma. El agente modifica código, entrena 5 min, evalúa si mejoró, guarda o descarta, repite. Sin intervención humana.

**3 archivos:**
- `prepare.py` — datos y tokenizer (NO se toca)
- `train.py` — el agente modifica esto (630 líneas, modelo GPT completo)
- `program.md` — instrucciones del humano al agente (Markdown = "skill")

**Métricas:** validation BPB (bits per byte) — más bajo = mejor

**Resultados demostrados:**
- Run 1 (corto): 83 experimentos, 15 mejoras, 0.998 → 0.977 BPB
- Run 2 (overnight): 276 experimentos, 29 mejoras, 0.8624 → 0.8557 BPB
- Tobi Lütke (Shopify): 19% mejora, modelo pequeño superó a uno grande manual

## Principios Clave

1. **"Programming the program"** — El humano escribe Markdown (dirección), el agente ejecuta código (investigación)
2. **Fixed time budget** — 5 min por experimento = comparable, ~12 exp/hora, ~100 overnight
3. **Greedy hill-climbing** — Solo guarda mejoras (git commits en feature branch)
4. **Self-contained** — 630 líneas, una GPU, un archivo, una métrica
5. **El program.md es un "super lightweight skill"** — Paralelo directo con nuestros SKILL.md

## Tweets Clave

- **Anuncio repo:** https://x.com/karpathy/status/2030371219518931079
  - "I packaged up the autoresearch project..."
  - Imagen: gráfica de 83 experimentos
  
- **Post-AGI sauna:** https://x.com/karpathy/status/2029950967031247231
  - "ah yes, this is what post-agi feels like :) i didn't touch anything. brb sauna"
  - Imagen: gráfica de 276 experimentos

- **Contexto original:** https://x.com/karpathy/status/2029701092347630069

## Forks Notables

- macOS: miolini/autoresearch-macos, trevin-creator/autoresearch-mlx
- Windows: jsegov/autoresearch-win-rtx

## Cita Épica (README)

> "One day, frontier AI research used to be done by meat computers in between eating, sleeping, having other fun, and synchronizing once in a while using sound wave interconnect in the ritual of 'group meeting'. That era is long gone."

---

## 🔄 Seguimiento

### Qué monitorizar
- [ ] Nuevos commits en el repo (evolución del framework)
- [ ] Nuevos forks interesantes (especialmente sin GPU)
- [ ] Tweets de Karpathy sobre resultados/mejoras
- [ ] Adopción por la comunidad (Reddit, HN, papers)
- [ ] Aplicaciones fuera de ML (el patrón es generalizable)

### Cron de seguimiento
- Semanal: revisar actividad del repo y menciones relevantes

---

## 🚀 Aplicabilidad a Nuestro Setup

### El patrón abstracto (generalizable)
```
1. Humano define OBJETIVO + RESTRICCIONES (Markdown)
2. Agente propone CAMBIO
3. Agente ejecuta EXPERIMENTO (time-boxed)
4. Agente evalúa RESULTADO (métrica objetiva)
5. Si mejoró → GUARDAR (git commit)
6. Si no → DESCARTAR
7. REPETIR indefinidamente
```

### Ideas de implementación para nuestro setup

#### 1. Auto-optimización de scripts (Alta viabilidad ✅)
- **Qué:** El agente itera sobre scripts existentes (backup, healthcheck, etc.)
- **Métrica:** Tiempo de ejecución, tamaño output, tasa de errores
- **Ejemplo:** Optimizar backup-memory.sh → probar variantes → medir tiempo + tamaño
- **Requiere:** Solo CPU, ya lo tenemos

#### 2. Auto-tuning de prompts/skills (Alta viabilidad ✅)
- **Qué:** Iterar sobre program.md / SKILL.md para mejorar resultados
- **Métrica:** Tasa de éxito de tareas, tokens consumidos, errores
- **Ejemplo:** Optimizar HEARTBEAT.md → probar variantes → medir falsos positivos/negativos
- **Requiere:** API calls (coste), pero el patrón aplica perfectamente

#### 3. Auto-mejora de cron jobs (Media viabilidad 🟡)
- **Qué:** Agente prueba variaciones de crons (horarios, payload, configuración)
- **Métrica:** Tasa de éxito, tiempo de ejecución, errores consecutivos
- **Requiere:** Tiempo + log de resultados históricos

#### 4. Config optimization (Media viabilidad 🟡)
- **Qué:** Iterar sobre configuraciones del sistema (UFW rules, fail2ban params, etc.)
- **Métrica:** Seguridad score (Lynis), falsos positivos, rendimiento
- **Requiere:** Cuidado — cambios de sistema son peligrosos sin supervisión

#### 5. Dashboard/API performance (Baja prioridad)
- **Qué:** Optimizar respuesta del API server, caching, queries
- **Métrica:** Latencia, memory usage
- **Requiere:** Benchmarking framework

### Limitaciones en nuestro setup
- ❌ No tenemos GPU → no podemos correr autoresearch directamente
- ❌ Coste de API → cada "experimento" con LLM cuesta tokens
- ✅ Pero el PATRÓN es aplicable a cualquier tarea medible
- ✅ Podemos usar Haiku para los experimentos (barato)

### Próximos pasos
- [ ] Diseñar un PoC de "auto-optimization loop" para un script concreto
- [ ] Definir métricas claras para cada área optimizable
- [ ] Crear un framework ligero que implemente el patrón iterate→test→keep/discard
- [ ] Empezar con algo simple: optimizar un prompt de SKILL.md midiendo tokens/éxito

---

*Última actualización: 2026-03-09*
