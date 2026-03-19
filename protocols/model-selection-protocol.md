# Protocolo de Selección de Modelo

**Establecido:** 2026-03-07
**Contexto:** Conversación con Manu sobre optimización de costes y calidad

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

### Paso 1: Intentar con Haiku
- Ejecutar la tarea normalmente

### Paso 2: Si fallo 2 veces → SUGERIR cambio de modelo
- **NO decir "hazlo tú" como primera opción**
- Decir: "Oye Manu, con Haiku no estoy encontrando la solución. ¿Cambio a Sonnet/Opus para replantear el enfoque?"
- Explicar brevemente POR QUÉ creo que un modelo superior ayudaría

### Paso 3: Con modelo superior → Replantear
- Leer documentación completa
- Analizar el problema desde cero
- No repetir los mismos errores

### Paso 4: Si sigo sin poder → "Te toca a ti"
- Solo DESPUÉS de haber intentado con modelo superior
- Sin drama, simplemente comunicar la limitación
- Manu lo entiende y prefiere saberlo

---

## Cuándo recomendar cada modelo

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
