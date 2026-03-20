# Protocolo de Selección de Modelo

**Establecido:** 2026-03-07
**Contexto:** Conversación con Manu sobre optimización de costes y calidad

---

## Quick Start: Haiku by Default

Haiku is the default (80-85% of tasks). Escalate to Sonnet/Opus only after **2 failures** with Haiku.

| Scenario | Model | Action |
|----------|-------|--------|
| **Routine**: chats, crons, files, simple queries | 🟢 Haiku | Go ahead |
| **First failure**: tried once, hit a wall | 🟢 Haiku | Try again, read docs more carefully |
| **Second failure**: tried twice, still stuck | 🟡 Sonnet | Escalate: "Manu, should I try Sonnet to rethink this?" |
| **With Sonnet**: new approach, reread docs | 🟡 Sonnet | Execute with fresh perspective |
| **Third strike**: model superior also fails | 📊 Report | "Here's what I tried. This needs your input." |

---

## Modelo por defecto: Haiku

Haiku es el modelo base para el 80-85% de las interacciones.

**Haiku funciona bien para:**
- Chat, consultas, respuestas rápidas
- Tareas rutinarias (crons, archivos, memoria)
- Comandos que ya conozco bien
- Resúmenes, traducciones, formato

---

## Protocolo de escalado (decisión 2026-03-07)

### Paso 1-2: Dos fallos con Haiku
- Intenta normalmente
- Si fallo 2 veces → **SUGERIR cambio de modelo** (no rendirse)

### Paso 3: Con modelo superior → REPLANTEAR
- Leer documentación completa
- Analizar desde cero
- No repetir los mismos errores

### Paso 4: Tercera derrota
- Solo después de modelo superior
- Sin drama: "Manu, necesito tu input."

---

## Cuándo recomendar cada modelo (Referencia)

| Modelo | Cuándo | Ejemplos |
|--------|--------|----------|
| 🟢 **Haiku** | Tareas rutinarias, chat, consultas simples | Crons, archivos, resúmenes, traducciones |
| 🟡 **Sonnet** | Herramientas nuevas, debugging, tareas multi-paso | Integrar APIs, resolver errores, configurar servicios |
| 🔴 **Opus** | Análisis profundo, decisiones importantes, reflexiones | Arquitectura, estrategia, problemas complejos |

---

## Lección clave (2026-03-07)

El problema no siempre es el modelo. A veces es el enfoque:
- **Leer documentación COMPLETA antes de actuar**
- **Si fallo 2 veces → parar y replantear**, no escalar complejidad a lo loco
- **No sugerir "hazlo tú" sin antes intentar con modelo superior**

Ejemplo del día: `gog calendar create --help` tenía todo lo necesario.
Con Haiku no lo vi, con Opus lo encontré al primer intento.
La diferencia: paciencia para leer la documentación completa.

---

## Auto-desescalado (decisión 2026-03-07)

### Después de completar tarea con modelo superior:
- Sugerir a Manu: "¿Volvemos a Haiku?"
- Si Manu confirma o no dice nada → bajar a Haiku

### Reset nocturno automático (cron):
- Todos los días a 00:00 Madrid → forzar vuelta a Haiku
- Evita que me quede en Opus/Sonnet por olvido
- Cron: `model-reset-nightly`

### Principio: Haiku es el estado natural. Sonnet/Opus son escalados temporales.
