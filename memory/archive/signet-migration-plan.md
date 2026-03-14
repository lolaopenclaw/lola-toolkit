# Plan de Mejora de Memoria — Inspirado en Signet
**Creado:** 2026-03-03
**Discussion:** openclaw/openclaw #28597
**Estado:** Fase 1 en progreso

---

## FASE 1: Mejoras inmediatas SIN Signet ✅ (Semana 1 - 3 Mar)

### 1. Secrets encriptados ✅
- [x] GPG key creada (lolaopenclaw@gmail.com, RSA 4096)
- [x] `pass` inicializado con 12 secrets migrados
- [ ] Verificar que scripts usen `pass show` en vez de leer .env directamente
- [ ] Documentar proceso de recuperación de GPG key en BOOTSTRAP.md

### 2. Entity extraction ✅
- [x] `memory/entities.md` creado — registro manual de personas, proyectos, herramientas
- [ ] Actualizar entities.md semanalmente (añadir al cron de lunes)

### 3. Retention decay + deduplicación ✅
- [x] Script `scripts/memory-maintenance.sh` creado
- [x] Detecta archivos >30 días, duplicados, archivos grandes
- [ ] Añadir al cron semanal (lunes)
- [ ] Implementar archivado automático (mover a memory/archive/)

### 4. Session synthesis
- [ ] Al final de sesiones largas, extraer puntos clave automáticamente
- [ ] Formato: `memory/YYYY-MM-DD-session-synthesis.md`
- [ ] Triggear desde HEARTBEAT.md cuando detecte fin de sesión

---

## FASE 2: Evaluar Signet en sandbox (Semana 2 - 10 Mar)

### Prerequisitos
- [ ] Verificar RAM disponible para Ollama
- [ ] Instalar Ollama (modelo pequeño: llama3.2:3b o similar)
- [ ] `npm install -g signetai`
- [ ] `signet` (wizard interactivo)

### Tests
- [ ] Alimentar 5-10 archivos .md de memoria existente
- [ ] Comparar calidad de recall: Signet vs memory_search
- [ ] Medir consumo RAM/CPU con daemon corriendo
- [ ] Test de secrets: migrar 2-3 secrets a Signet .secrets/
- [ ] Verificar compatibilidad con OpenClaw connector

### Criterios de decisión
- **Adoptar SI:** Recall significativamente mejor Y overhead < 500MB RAM
- **No adoptar SI:** Overhead > 1GB RAM O recall comparable a memory_search
- **Parcial SI:** Adoptar solo secrets module

---

## FASE 3: Decisión informada (Semana 3 - 17 Mar)

### Si adoptamos Signet:
- [ ] Migración gradual de memoria (document ingest de todos los .md)
- [ ] Migrar secrets de `pass` a Signet `.secrets/`
- [ ] Configurar connector OpenClaw
- [ ] Actualizar BOOTSTRAP.md con nuevo flujo de recuperación
- [ ] Backup del SQLite en el tarball diario

### Si NO adoptamos:
- [ ] Mantener mejoras Fase 1
- [ ] Mejorar memory_search con tags/categorías
- [ ] Implementar auto-recall en HEARTBEAT (inyectar contexto relevante)
- [ ] Expandir entities.md con más relaciones

---

## CRONS CONFIGURADOS

| Cron | Frecuencia | Script |
|------|-----------|--------|
| Gateway health | Cada 30 min (8-22h) | `scripts/gateway-health-check.sh` |
| GitHub issues review | Lunes 9:30 AM | `scripts/review-github-issues.sh` |
| Memory maintenance | Lunes (pendiente) | `scripts/memory-maintenance.sh` |
| Entity review | Lunes (pendiente) | Manual en heartbeat |

---

## NOTAS

- Discussion #28597 tiene buenas ideas pero requiere Bun + Ollama
- Nuestra VPS tiene recursos limitados → evaluar overhead cuidadosamente
- El valor principal de Signet: auto-recall (no depender de que yo recuerde buscar)
- Nuestro memory_search ya hace semantic search, la diferencia es la inyección automática
