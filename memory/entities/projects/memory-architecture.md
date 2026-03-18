# Memory Architecture — Summary

**Type:** project  
**Last synthesized:** 2026-03-18  
**Tiers:** 6 hot, 0 warm, 0 cold

## 🔥 Hot (recent / frequent)

- **[context]** Goal: Build structured, decaying knowledge graph for Lola's memory. Inspired by Nate Eliason article on PARA + QMD + atomic facts.
- **[milestone]** Paso 1 DONE: memory_search switched from local to openai provider (anthropic embeddings).
- **[milestone]** Paso 2 DONE: Structured entities with PARA schema. Directory: memory/entities/. JSON atomic facts with schema (id, fact, category, timestamp, source, status, supersededBy, relatedEntities, lastAccessed, accessCount).
- **[milestone]** Paso 3 DONE: Memory decay script (scripts/memory-decay.sh). Hot (7 days)/Warm (8-30 days)/Cold (30+ days) tiering. Frequency resistance for high-access facts. Weekly cron: Sundays 23:00.
- **[status]** Paso 4 PENDING: QMD or equivalent search layer. Only if memory_search (openai provider) proves insufficient.
- **[context]** Key constraint: autoimprove must SKIP memory/entities/ (.autoimprove-skip marker in place). Entities are auto-generated from JSON by memory-decay.sh.

---

See `memory-architecture.json` for all 6 facts.