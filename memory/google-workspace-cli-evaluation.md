# Google Workspace CLI (gws) Evaluation — 2026-03-09

## Decisión: MANTENER gog, MONITOREAR gws

**Fecha:** 2026-03-09 10:44 (Madrid)
**Investigación:** Google Workspace CLI (gws) vs gog
**Conclusión:** gog sigue siendo la mejor opción para nosotros

---

## 🔍 Comparación

### gws (Google Workspace CLI) — Ventajas
- ✅ Chat API (no en gog)
- ✅ Admin API (no en gog)
- ✅ Model Armor integration (seguridad)
- ✅ Dinámico (se actualiza automáticamente)
- ✅ MCP Server nativo
- ✅ Git-like workflow para Sheets/Docs
- ✅ Oficial de Google

### gog — Ventajas
- ✅ Cubre 95% de usos reales
- ✅ Menos tokens (sintaxis simple)
- ✅ Estable y probado
- ✅ Ya configurado y funcionando
- ✅ Mantenido activamente

---

## 📋 Nuestro Caso

**Servicios que usamos:**
- Gmail ✅ (ambos)
- Google Drive ✅ (ambos)
- Google Calendar ✅ (ambos)
- Google Contacts ✅ (ambos)
- Google Sheets ✅ (ambos)
- Google Docs ✅ (ambos)

**Servicios que gws ofrece pero NO necesitamos:**
- ❌ Chat API — No usamos Google Chat
- ❌ Admin API — No somos admin de dominio
- ❌ MCP Server — OpenClaw ya cubre esto
- ❌ Model Armor — No es crítico ahora

---

## 📌 Plan

### Ahora (2026-03-09)
✅ **Mantener gog funcionando como está**
- Sin cambios
- Sin migración
- Sin riesgos

### Futuro (cuando gws sea estable)
⏳ **Monitorear gws**
- Si Google lo declara "officially supported"
- Si necesitamos Chat API
- Si necesitamos MCP Server
- Cuando veamos beneficios reales

### Dual Setup (NO)
❌ No necesario
- Overhead innecesario
- Complejidad extra
- gog cubre nuestras necesidades

---

## Fuentes

- GitHub: https://github.com/googleworkspace/cli
- Reddit: r/openclaw (3 días ago)
- HackerNews: Discusión sobre git-like workflow
- Mark TechPost: Google releases gws CLI

## Status

**Decisión:** FINAL ✅
**Owner:** Manu + Lola
**Aprobado:** 2026-03-09 10:44
