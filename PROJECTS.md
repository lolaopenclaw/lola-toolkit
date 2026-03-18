# PROJECTS.md — Proyectos Activos

**Léeme cada sesión junto con AGENTS.md, SOUL.md, USER.md**

---

## 🔴 Activos

### Finanzas
- **Repo:** github.com/lolaopenclaw/finanzas-personal (privado)
- **Local:** ~/finanzas/
- **Sheet:** [1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA](https://docs.google.com/spreadsheets/d/1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA/edit)
- **Actualización:** Cada 15 días (Manu me pasa extractos bancarios)
- **Última actualización:** 2026-03-18 (63 movimientos nuevos, 42 de marzo)
- **Estado:** ✅ Al día
- **Notas:**
  - Parsear Norma 43 (CaixaBank) + XLSX (Bankinter)
  - Deduplicar automáticamente
  - Correlacionar PayPal con movimientos de CaixaBank
  - Script: `~/finanzas/update_from_raw.py`

### Surf Coach AI
- **Repo:** github.com/lolaopenclaw/surf-coach-ai (privado, compartido con RagnarBlackmade)
- **Local:** ~/projects/surf-coach/
- **Descripción:** AI coach para análisis de movimientos de surf usando MediaPipe pose estimation
- **Estado:** 🚧 MVP en desarrollo
- **Última actividad:** 2026-03-18 (análisis de 9 vídeos completos en curso)
- **Sub-agente activo:** surf-coach-full-analysis-v2 (Haiku, timeout 1h)
- **Notas:**
  - 5 vídeos corregidos (Jorge, Surf Labs) como ground truth
  - 4 vídeos brutos para comparación
  - Objetivo: feedback técnico automatizado (pop-ups, turns, compresión/extensión)
  - Stack: Python, MediaPipe, OpenCV, optical flow

### Memory Architecture
- **Local:** ~/.openclaw/workspace/memory/entities/
- **Descripción:** Knowledge graph estructurado con PARA + atomic facts + memory decay
- **Estado:** ✅ Pasos 1-3 completados (2026-03-18)
- **Entities:** memory/entities/ — `areas/people/`, `areas/companies/`, `projects/`, `resources/`
- **Decay:** `scripts/memory-decay.sh` — Cron semanal dom 23:00 (Hot/Warm/Cold tiering)
- **Notas:**
  - 13 entities, 62 atomic facts
  - memory_search → provider: openai (funcional)
  - `.autoimprove-skip` protege entities/ de autoimprove
  - Fuente de verdad: JSON (.json) → auto-genera summaries (.md)

### QMD Local Search
- **Repo:** github.com/tobi/qmd
- **Estado:** 📋 Planificado (no instalado)
- **Descripción:** Motor de búsqueda local (SQLite + BM25 + vector) para archivos de memoria
- **Prioridad:** Media — instalar cuando tengamos tiempo (Manu quiere hacerlo)
- **Por qué:** Backup de memory_search, zero-cost, offline, escala mejor con 200+ archivos

### Lola Toolkit
- **Repo:** github.com/lolaopenclaw/lola-toolkit (público)
- **Descripción:** Scripts, skills y protocolos para gestión de agentes IA
- **Estado:** ✅ Activo (publicar todo lo útil, NUNCA tokens/keys/IPs)

---

## 🟡 En pausa / Mantenimiento

### Autoimprove Nightly
- **Local:** ~/.openclaw/workspace/skills/autoimprove/
- **Cron ID:** 08325b21-cd9c-490e-904c-e668e38418af
- **Horario:** 2:00 AM Madrid (diario)
- **Estado:** ⚠️ Error (último: 2026-03-18 02:00)
- **Investigar:** Circuit breaker activado, posible conflicto con OpenClaw v2026.3.13

### Security Audits
- **Cron IDs:**
  - healthcheck:security-weekly (fdf38b8f) — Lunes 9:00 AM
  - 🔬 Seguimiento Autoresearch (4de42cb2) — Lunes 10:00 AM
- **Estado:** ⚠️ Ambos en error desde hace 2 días
- **Última auditoría exitosa:** 2026-03-16

---

## 📋 Pendientes

- [ ] Investigar errores de cron (autoimprove + security audits)
- [ ] Completar análisis completo de vídeos (Surf Coach)
- [ ] Añadir alertas de presupuesto a finanzas (cron/heartbeat)
- [ ] Automatizar detección de CSVs nuevos en finanzas

---

## 🗑️ Archivados

_(Añadir aquí proyectos completados o cancelados)_

---

**Última actualización:** 2026-03-18 21:22 CET
