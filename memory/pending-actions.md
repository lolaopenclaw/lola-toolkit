# Pending Actions

## 🔴 Ready to Implement

### 1. Knowledge Base con RAG
- **Status:** Plan aprobado — LISTO PARA IMPLEMENTAR
- **Date:** 2026-03-25
- **Priority:** Alta
- **Esfuerzo:** 6-8h
- **Plan:** Topic Telegram "📚 Knowledge Base" → dejar links → ingesta automática (web, YouTube, tweets, PDFs) → búsqueda semántica (SQLite + vector embeddings)

### 2. Prompt Optimization Guide (completar)
- **Status:** Plan aprobado — LISTO PARA IMPLEMENTAR
- **Date:** 2026-03-25
- **Priority:** Media-alta
- **Esfuerzo:** 4h
- **Base existente:** memory/best-practices/, memory/model-specific-prompts.md
- **Plan:** Referencia automática al modificar prompts + audit de prompts existentes + auto-update mejorado

## 🟡 Backlog (aprobadas pero no urgentes)

### 3. Markdown Drift Checker
- **Esfuerzo:** 2-3h
- **Qué:** Audit diario de todos los .md — buscar duplicados, conflictos, info obsoleta
- **Nota:** Complementa autoimprove pero enfocado en coherencia, no tokens

### 4. API Cost Tracker
- **Esfuerzo:** 2h
- **Qué:** Logear todas las llamadas API, poder preguntar "¿cuánto he gastado esta semana?"
- **Nota:** Más relevante ahora con Opus permanente

## ❌ Descartadas

- CRM Personal — No interesa a Manu
- Meeting Prep matutino — Sin CRM no aporta suficiente
- Sesiones sin expiración — Peor rendimiento, no necesario con nuestro sistema de memoria
- Food Journal — No aplica
- Video/Content Pipeline — No aplica
- X/Twitter management — No aplica

## 📺 Fuente: Vídeos Matthew Berman
- "21 INSANE Use Cases" (8kNv3rjQaVA)
- "Use Cases that are actually helpful" (Q7r--i9lLck)
- "I figured out the best way to run OpenClaw" (3GrG-dOmrLU)
- "I Played with Clawdbot all Weekend" (MUDvwqJWWIw)
- "The Clawdbot situation is..." (WNXbRyA1JC4)

---

## ✅ Completed Today (2026-03-25)
- OpenSpec integration (specs/, scripts/openspec-helpers.sh)
- GitHub push (lola-toolkit repo + historial limpio + .gitignore)
- Modelo por defecto → Opus (permanente, cron reset eliminado)
- Secrets rotation (Groq, Discord, Google OAuth)
- SSH key subida a GitHub
- Análisis 5 vídeos Berman → priorización de ideas
