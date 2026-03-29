# Memory Architecture — Summary

**Type:** project  
**Last synthesized:** 2026-03-29  
**Tiers:** 0 hot, 6 warm, 0 cold

## 🌡️ Warm (8-30 days)

- **[context]** Goal: Build structured, decaying knowledge graph for Lola's memory. Inspired by Nate Eliason article on PARA + QMD + atomic facts.
- **[milestone]** Paso 1 DONE: memory_search working with Ollama/nomic-embed-text (local, free). Previously tried openai (no key), gemini (key invalid). 221 files, 685 chunks indexed. Daily reindex cron at 4:30AM.
- **[milestone]** Paso 2 DONE: Structured entities with PARA schema. Directory: memory/entities/. JSON atomic facts with schema (id, fact, category, timestamp, source, status, supersededBy, relatedEntities, lastAccessed, accessCount).
- **[milestone]** Paso 3 DONE: Memory decay script (scripts/memory-decay.sh). Hot (7 days)/Warm (8-30 days)/Cold (30+ days) tiering. Frequency resistance for high-access facts. Weekly cron: Sundays 23:00.
- **[status]** Paso 4 DONE: Search layer resolved via OpenClaw native memory_search + Ollama embeddings (hybrid: vector 70% + FTS 30%). QMD project closed as redundant.
- **[context]** Key constraint: autoimprove must SKIP memory/entities/ (.autoimprove-skip marker in place). Entities are auto-generated from JSON by memory-decay.sh.

---

See `memory-architecture.json` for all 6 facts.