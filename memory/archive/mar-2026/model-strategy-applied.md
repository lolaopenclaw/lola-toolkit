# 🎯 Model Strategy — Cambios Aplicados (Fase 1)

**Fecha:** 2026-03-24 21:30 CET  
**Ejecutado por:** Lola (subagent)  
**Autorizado por:** Manu (via subagent spawn)

---

## ✅ Resumen

Se aplicaron **SOLO** los cambios de **Fase 1 (Críticos)** según lo documentado en:
- `memory/model-strategy-executive-summary.md`
- `memory/model-strategy-changes-2026-03-24.md`

**Estado:** ✅ COMPLETADO (con 1 limitación conocida)

---

## 📋 Cambios Aplicados

### 1️⃣ Timeouts Autoimprove (600s → 900s)

| Cron | Timeout Anterior | Timeout Nuevo | Status |
|------|------------------|---------------|--------|
| 🔬 Autoimprove Scripts Agent | 600s | **900s** | ✅ |
| 🔬 Autoimprove Skills Agent | 600s | **900s** | ✅ |
| 🔬 Autoimprove Memory Agent | 600s | **900s** | ✅ |

**Justificación:** Los 3 agents estaban fallando con timeout en 15 iteraciones. 900s (15 min) da ~60s por iteración.

**Comandos ejecutados:**
```bash
openclaw cron edit dcae7b06-e6fb-40d4-88bc-9bc618feb70d --timeout-seconds 900
openclaw cron edit 8d65b575-5023-4160-bbc3-45ac449f17d3 --timeout-seconds 900
openclaw cron edit 881d2943-dc39-4bf4-b1cf-6344ff6bbf53 --timeout-seconds 900
```

**Impacto coste:** $0 (solo tiempo de ejecución)

---

### 2️⃣ Upgrade Healthchecks de Seguridad (Haiku → Sonnet)

| Cron | Modelo Anterior | Modelo Nuevo | Status |
|------|-----------------|--------------|--------|
| healthcheck:fail2ban-alert | (default) | **anthropic/claude-sonnet-4-5** | ✅ |
| healthcheck:rkhunter-scan-weekly | (default) | **anthropic/claude-sonnet-4-5** | ✅ |
| healthcheck:lynis-scan-weekly | (default) | **anthropic/claude-sonnet-4-5** | ✅ |
| healthcheck:security-audit-weekly | (default) | **anthropic/claude-sonnet-4-5** | ✅ |

**Justificación:** Análisis de seguridad requiere razonamiento complejo. Haiku no es suficiente para:
- Interpretación de logs de malware (rkhunter)
- Comparación de configuraciones (lynis)
- Auditoría profunda (security-audit)
- Detección de anomalías (fail2ban)

**Comandos ejecutados:**
```bash
openclaw cron edit c8522805-6bc4-451e-887b-69866ddf5b95 --model anthropic/claude-sonnet-4-5
openclaw cron edit 78d3556f-a203-455d-b718-b9ac7c183dbc --model anthropic/claude-sonnet-4-5
openclaw cron edit edc0db6e-a1b3-4837-858a-68f859300614 --model anthropic/claude-sonnet-4-5
openclaw cron edit fdf38b8f-6d68-4798-84ea-1e2a24c61e75 --model anthropic/claude-sonnet-4-5
```

**Impacto coste:** +$4.20/mes (4 crons × ~$0.06/día × 30 días)

---

### 3️⃣ Cron Duplicado config-drift-check

**Status:** ⚠️ PARCIALMENTE RESUELTO

**Problema detectado:**
```json
ID: null - Daily config drift detection check
ID: a3bd469e-f7cf-47cc-ab0b-1185e508a922 - Daily config drift detection at 2 AM
```

**Análisis:**
- **Cron 1 (id: null):** Llama al script completo `/home/mleon/.openclaw/workspace/scripts/config-drift check`
- **Cron 2 (id válido):** Usa comando slash `/config-drift check` (correcto)

**Acción tomada:** NINGUNA

**Razón:** `openclaw cron rm` requiere un ID válido. El cron con `id: null` es inaccesible por CLI.

**Soluciones posibles:**
1. **Manual:** Editar el archivo de configuración de crons directamente (ubicación: `~/.openclaw/data/cron/jobs.json` o similar)
2. **Reportar bug:** El sistema no debería permitir crons con `id: null`
3. **Esperar:** Si el cron con `id: null` no tiene próxima ejecución válida, puede ser garbage-collected automáticamente

**Recomendación:** Monitorear en próximos días. Si ambos crons se ejecutan (conflicto), investigar ubicación de configuración y eliminar manualmente.

---

## 💰 Impacto en Coste

### Estimación Mensual

| Cambio | Coste Mensual |
|--------|---------------|
| Timeouts autoimprove | $0 |
| Healthchecks → Sonnet | +$4.20 |
| **TOTAL Fase 1** | **+$4.20/mes** |

**Coste total estimado anterior:** ~$70-120/mes  
**Coste total estimado nuevo:** ~$74-124/mes  
**Incremento:** +6% aprox.

---

## 📊 Verificación

Comando de verificación ejecutado:
```bash
# Timeouts
openclaw cron list --json | jq -r '.jobs[] | select(.name | contains("Autoimprove")) | "\(.name): \(.payload.timeoutSeconds)s"'

# Modelos
openclaw cron list --json | jq -r '.jobs[] | select(.name | contains("healthcheck")) | "\(.name): \(.payload.model // "default")"'

# Duplicados
openclaw cron list --json | jq -r '.jobs[] | select(.name == "config-drift-check") | "ID: \(.id // "NULL") - \(.description)"'
```

**Resultado:** ✅ Todos los cambios verificados correctamente.

---

## 🚫 Cambios NO Aplicados (Fase 2 - Pendiente Aprobación)

Los siguientes cambios fueron **EXPLÍCITAMENTE EXCLUIDOS** en esta ejecución:

1. ❌ Google Sheets v2 → Sonnet (+$1.80/mes)
2. ❌ Garmin weekly → Sonnet (+$1.80/mes)
3. ❌ Explicitar modelos Haiku en otros crons ($0)
4. ❌ Reclamación bus → Sonnet (+$0.06 one-time)

**Razón:** Solo Fase 1 (críticos) fue autorizada. Fase 2 requiere decisión de Manu.

---

## 📈 Métricas de Éxito (A Monitorear)

### Semana 1 (2026-03-24 → 2026-03-31)

- [ ] **Autoimprove agents:** 0 timeouts (actualmente: 3/3 con timeout)
- [ ] **Healthchecks seguridad:** Mejora en precisión de alertas
- [ ] **Coste real:** Dentro de +$5/mes

### Mes 1 (2026-03-24 → 2026-04-24)

- [ ] **Autoimprove:** 100% de ejecuciones completas (sin timeout)
- [ ] **Seguridad:** >90% precisión en detección de anomalías
- [ ] **Coste:** +$4-6/mes (dentro de estimación)

---

## 🔍 Problemas Conocidos

### 1. Cron Duplicado (id: null)

- **Severidad:** Media
- **Impacto:** Posible ejecución duplicada de config-drift (2× carga)
- **Solución temporal:** Monitorear logs
- **Solución permanente:** Investigar ubicación de configuración o reportar bug

### 2. Bug en `openclaw cron list`

- **Error:** `TypeError: Cannot read properties of undefined (reading 'padEnd')`
- **Workaround:** Usar `openclaw cron list --json | jq`
- **Reportado:** No (considerar reportar a OpenClaw)

---

## 📅 Próximos Pasos

### Inmediatos (Esta Semana)

1. **Monitorear ejecuciones:** Verificar que autoimprove completa sin timeout esta noche (3:00 AM)
2. **Revisar alertas:** Verificar que healthchecks de seguridad generan reportes de mayor calidad
3. **Documentar en MEMORY.md:** Añadir link a este archivo

### Corto Plazo (Próxima Semana)

4. **Evaluar Fase 2:** Presentar a Manu opciones de Google Sheets y Garmin → Sonnet
5. **Resolver config-drift duplicado:** Investigar configuración o esperar garbage collection
6. **Revisar coste real:** Comparar con estimación en `memory/token-usage-2026-03.md`

### Largo Plazo (Mes 1)

7. **Informe mensual:** Métricas de éxito (timeouts, calidad, coste)
8. **Ajustes:** Si timeout 900s aún insuficiente, considerar:
   - Reducir iteraciones (15 → 10)
   - Dividir agents en múltiples crons
   - Upgrade a Sonnet (última opción, 5× más caro)

---

## 🎓 Aprendizajes

### Técnicos

1. **Sintaxis correcta:** `openclaw cron edit <ID> --timeout-seconds <N>` (no `--timeout`)
2. **Modelos:** `--model anthropic/claude-sonnet-4-5` (full path)
3. **Verificación:** Siempre usar `--json | jq` para verificar cambios aplicados
4. **IDs null:** Bug del sistema que impide eliminación por CLI

### Estratégicos

1. **Fase 1 crítica:** Timeouts + seguridad son prioridad (bajo coste, alto impacto)
2. **Fase 2 opcional:** Google Sheets y Garmin pueden esperar evaluación
3. **Coste gradual:** +$4.20/mes es aceptable para mejora en seguridad
4. **Monitoreo esencial:** Necesitamos métricas reales para validar estrategia

---

## 📚 Referencias

- `memory/model-strategy.md` — Estrategia completa (12 KB)
- `memory/model-strategy-changes-2026-03-24.md` — Comandos específicos (9 KB)
- `memory/model-selection-guide.md` — Guía rápida (7 KB)
- `memory/model-strategy-executive-summary.md` — TL;DR ejecutivo (7 KB)

---

## ✍️ Firma

**Ejecutado por:** Lola (subagent `1f5083a2-2a8b-4df3-b7ba-6481c9e1c7bb`)  
**Fecha:** 2026-03-24 21:30 CET  
**Duración:** ~15 minutos  
**Status:** ✅ COMPLETADO

**Entregables:**
1. ✅ Cambios Fase 1 aplicados
2. ✅ Verificación ejecutada
3. ✅ Documento `memory/model-strategy-applied.md` generado
4. ⚠️ Cron duplicado pendiente resolución manual

---

**Próxima acción:** Presentar este informe a Manu para:
1. Confirmar que Fase 1 es satisfactoria
2. Decidir si aplicar Fase 2
3. Autorizar investigación/resolución de cron duplicado
