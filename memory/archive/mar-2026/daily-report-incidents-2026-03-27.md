# 🚨 Incidentes del Reporte Diario — 2026-03-27

**Fecha:** 2026-03-27 10:09 AM  
**Reporter:** Manu  
**Contexto:** Feedback sobre Morning Report de hoy

---

## ❌ INCIDENTES CONFIRMADOS

### 1. Calendario — Sección innecesaria ✅ VÁLIDO
- **Problema:** Calendario no se usa, sección vacía en reporte
- **Acción:** Eliminar del template del morning report
- **Prioridad:** LOW
- **Estado:** PENDIENTE

### 2. Pending Actions — Aparece vacío ⚠️ INCORRECTO
- **Problema:** Reporte dice "vacío", pero `memory/pending-actions.md` tiene backlog completo
- **Causa:** Script de morning report no lee el archivo, o lo lee mal
- **Evidencia:** 
  - `memory/pending-actions.md` tiene:
    - 15+ tareas completadas
    - 6 tareas activas en Phase Consolidation
    - 6 tareas en Backlog
    - 1 tarea crítica (mensajes perdidos)
  - Reporte dice "empty"
- **Acción:** Auditar script `generate-morning-report.sh` (si existe) o revisar cron de morning report
- **Prioridad:** HIGH
- **Estado:** EN INVESTIGACIÓN

### 3. Autoimprove Nightly — Contradicción ⚠️ INCONSISTENCIA
- **Problema:** Morning report dice "no se ejecutó anoche", pero:
  - En General se confirmó que SÍ se ejecutó
  - Existe archivo `memory/autoimprove-log-2026-03-27.md` generado a las 03:22 AM
  - `openclaw cron list` muestra 3 crons autoimprove ejecutados hace 7h (03:00, 03:05, 03:10)
- **Causa:** Script de morning report no detecta correctamente la ejecución
- **Evidencia:**
  ```bash
  $ ls -lh memory/*autoimprove*.md | tail -2
  -rw-rw---- 1.7K Mar 26 14:23 memory/autoimprove-log-2026-03-26.md
  -rw-rw---- 2.9K Mar 27 03:27 memory/autoimprove-log-2026-03-27.md
  
  $ openclaw cron list | grep autoimprove
  ae60d161... 🔬 Autoimprove Script... cron 0 3 * * * ... 7h ago ok
  f22e5eaf... 🔬 Autoimprove Skills... cron 5 3 * * * ... 7h ago ok
  5645185b... 🔬 Autoimprove Memory... cron 10 3 * * * ... 7h ago ok
  ```
- **Acción:** Revisar lógica de detección en morning report script
- **Prioridad:** MEDIUM
- **Estado:** CONFIRMADO BUG

### 4. Actualizaciones Disponibles — OK ✅ VALIDADO
- **Problema:** Reporte dice "0 actualizaciones"
- **Verificación:** 
  ```bash
  $ apt list --upgradable 2>/dev/null | grep -v "Listing..." | wc -l
  0
  ```
- **Estado:** CORRECTO (no hay actualizaciones pendientes)

### 5. Actividad — Cuenta pasos de HOY, no de AYER ⚠️ INCORRECTO
- **Problema:** Morning report (09:00 AM) muestra "21 pasos" — claramente pasos de la noche/madrugada de hoy, NO de ayer
- **Esperado:** Pasos de todo el día anterior (2026-03-26)
- **Causa:** Script `garmin-health-report.sh` usa lógica correcta SOLO cuando se ejecuta sin fecha manual:
  - `DATE_ACTIVITY="${2:-$(date -d yesterday +%Y-%m-%d)}"`
  - Si se pasa fecha manual, ignora el cálculo de "yesterday"
- **Evidencia:**
  - Reporte manual `--daily 2026-03-26` → muestra 21 pasos (actividad del 26, no del 25)
  - Reporte manual `--daily 2026-03-25` → muestra 6,089 pasos (actividad del 25, no del 24)
- **Acción:** Revisar cómo el morning report cron llama al script de Garmin
- **Prioridad:** HIGH
- **Estado:** CONFIRMADO BUG

### 6. Sueño — 0.0 horas dos días seguidos ⚠️ SOSPECHOSO
- **Problema:** Reporte muestra "0.0 horas de sueño" para 2026-03-26 Y 2026-03-25
- **Causa posible:**
  - Script usa `DATE_SLEEP="$(date +%Y-%m-%d)"` (siempre HOY)
  - Cuando se llama manualmente con fecha pasada, busca sueño en "hoy" (que no existe aún si es futuro)
  - O: Garmin API no devuelve datos de sueño (problema de sync con reloj)
- **Acción:** 
  1. Verificar datos de sueño directamente en Garmin Connect web
  2. Revisar logs de sync del reloj
  3. Auditar script `garmin-health-report.sh` líneas 165-182 (sleep data fetch)
- **Prioridad:** HIGH
- **Estado:** PENDIENTE VERIFICACIÓN MANUAL

### 7. Consumo de Tokens — "Sin información" ❌ INCORRECTO
- **Problema:** Morning report dice "Sin información de tokens"
- **Realidad:** `usage-report.sh --yesterday --by-model` devuelve datos completos:
  - **Total ayer (2026-03-26):** $169.53
  - **Desglose:**
    - Opus: $149.55 (88%)
    - Sonnet: $19.14 (11%)
    - Haiku: $0.62 (<1%)
    - Gemini Flash: $0.22 (<1%)
  - **Total requests:** 1,437
- **Causa:** Script de morning report no ejecuta `usage-report.sh` o no parsea su output
- **Acción:** Auditar integración de cost tracking en morning report
- **Prioridad:** HIGH
- **Estado:** CONFIRMADO BUG

---

## 🔍 ACCIONES REQUERIDAS

### Inmediatas (hoy)
1. [ ] Localizar script de morning report (¿dónde está?)
   - Buscar en `scripts/`
   - Revisar cron que genera el morning report (¿cuál es?)
2. [ ] Verificar datos de sueño manualmente en Garmin Connect
3. [ ] Auditar lógica de pending-actions en morning report

### Esta semana
1. [ ] Fix: Integración de usage-report.sh en morning report
2. [ ] Fix: Detección de autoimprove execution
3. [ ] Fix: Lógica de fechas para actividad Garmin (yesterday vs manual date)
4. [ ] Fix: Lógica de fechas para sueño Garmin
5. [ ] Remove: Sección de calendario del template

### Seguimiento
- [ ] Manu verificará sueño en reloj y confirmará si es problema de script o de sync
- [ ] Validar próximo morning report (2026-03-28 09:00) con estos fixes

---

## 📊 RESUMEN

| Incidente | Prioridad | Estado | Causa raíz |
|-----------|-----------|--------|------------|
| Calendario innecesario | LOW | Pendiente | Feature no usada |
| Pending actions vacío | HIGH | En investigación | Script no lee archivo |
| Autoimprove contradicción | MEDIUM | Confirmado | Lógica de detección |
| Updates (0) | - | OK | No hay actualizaciones |
| Actividad (pasos de hoy) | HIGH | Confirmado | Fecha manual mal manejada |
| Sueño (0.0h x2) | HIGH | Pendiente verificación | API o script |
| Tokens sin info | HIGH | Confirmado | Script no integrado |

**Total incidentes:** 7  
**Críticos/High:** 4  
**Medium:** 1  
**Low:** 1  
**Falsos positivos:** 1

---

**Nota:** Este análisis se basa en feedback de audio de Manu + verificación técnica. Próximo paso: localizar y auditar el script completo del morning report.
