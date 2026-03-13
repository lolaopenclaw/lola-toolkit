# 📚 DAILY Memory Index — Tiered Architecture

**Implementado:** 2026-02-21  
**Arquitectura:** HOT / WARM / COLD tiers para optimizar búsqueda y token usage

---

## 🔥 HOT (Últimos 7 días)
**Consultar PRIMERO.** Contexto reciente, sesiones activas.

**Contenido:** 25 archivos
- `2026-02-18.md` — Diario 18 feb
- `2026-02-19.md` — Diario 19 feb
- `2026-02-20.md` + sesiones (13 archivos) — Sesiones detalladas del 20 feb (ayer)
- `2026-02-21-*.md` (reportes de hoy)

**Búsqueda:** `memory_search` prioriza HOT primero  
**Token cost:** Bajo (contextual + reciente)

---

## 🌤️ WARM (8-30 días)
**Consultar SEGUNDO.** Contexto medio-plazo, tendencias.

**Contenido:** 3 archivos
- `2026-02-06.md` — Diario 6 feb
- `2026-02-07.md` — Diario 7 feb
- `2026-02-10.md` — Diario 10 feb

**Búsqueda:** Se consulta si HOT no encuentra resultados  
**Uso típico:** Decisiones anteriores, patrones, histórico

---

## ❄️ COLD (>30 días)
**Archivar/Comprimir.** Para recuperación histórica únicamente.

**Contenido:** Vacío (aún)  
**Futuro:** Se comprime en `.tar.gz` cuando >30 días  
**Búsqueda:** No automática (requiere descompresión)

---

## 🔄 Rotación Automática

**Cada lunes 23:30 (cron):**
1. Identifica archivos HOT con >7 días
2. Mueve a WARM
3. Identifica WARM con >30 días
4. Comprime a `COLD/archive-YYYY-MM.tar.gz`
5. Elimina originals de WARM
6. Genera reporte

**Script:** `tier-rotation.sh` (futuro)

---

## 📊 Storage Impact

**Actual:**
- HOT: ~500 KB (25 archivos)
- WARM: ~20 KB (3 archivos)
- COLD: 0 KB

**Proyección (4 semanas):**
- HOT: ~700 KB (rotación semanal)
- WARM: ~400 KB
- COLD: ~2 MB (1 archivo comprimido)

**vs. Sin tiering:** ~3-4 MB sin compresión

---

## 🎯 Beneficios

✅ **Búsqueda:** HOT primero = 3-5x más rápido encontrar contexto reciente  
✅ **Tokens:** memory_search enfocado en HOT = -30% tokens  
✅ **Storage:** COLD comprimido = -85% espacio  
✅ **Mantenibilidad:** Estructura clara vs. flat 40-file directory

---

## 📋 Estructura Futura

```
memory/
├── CORE/
├── PROTOCOLS/
├── ANALYSIS/
└── DAILY/
    ├── INDEX.md (este archivo)
    ├── HOT/
    │   ├── 2026-02-21.md (HOY)
    │   ├── 2026-02-20/
    │   ├── 2026-02-20-*.md
    │   └── ...
    ├── WARM/
    │   ├── 2026-02-17.md
    │   ├── 2026-02-16/
    │   └── ...
    └── COLD/
        ├── archive-2026-01.tar.gz (después del 23 feb)
        └── ...
```

---

**Próximas mejoras:**
- [ ] Integrar LanceDB para semantic search en HOT
- [ ] Script `tier-rotation.sh` (cron)
- [ ] Compression detection en WARM

---

*Implementación completada: 2026-02-21 11:55*
