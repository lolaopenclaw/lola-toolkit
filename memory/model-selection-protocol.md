# Protocolo de Selección de Modelo

**Establecido:** 2026-03-07
**Contexto:** Conversación con Manu sobre optimización de costes y calidad

---

## Default: Haiku (80-85% of tasks)

**Haiku for:** Chat, crons, files, simple queries, summaries, translations

## Escalation Protocol (2026-03-07)

1. **Try with Haiku** (routine approach)
2. **First failure** → Retry with Haiku (read docs carefully)
3. **Second failure** → **Suggest Sonnet**: "Manu, should I try Sonnet to rethink this?"
4. **With Sonnet** → **Rethink completely** (read full docs, fresh approach)
5. **Third failure** → Report: "Here's what I tried. This needs your input."

**Key lesson:** Problem often = approach, not model. Read FULL docs before acting.

## Model Use Cases

| Model | When |
|-------|------|
| 🟢 **Haiku** | Routine tasks, chat, simple queries |
| 🟡 **Sonnet** | New tools, debugging, multi-step tasks |
| 🔴 **Opus** | Deep analysis, architecture, complex problems |

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
