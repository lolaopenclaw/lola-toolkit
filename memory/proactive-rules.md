# Proactive Rules - Heartbeat Suggestions

**Created:** 2026-03-24  
**Status:** Active  
**Purpose:** Reglas configurables para sugerencias proactivas del heartbeat

> **Nota:** Este archivo define reglas para sugerencias **contextuales automáticas** (weather, health, finance, etc.).  
> Para sugerencias de **workflow** (worktrees, PR reviews), ver `workflow-suggestions-protocol.md`.

---

## 🎯 PRINCIPIOS CORE

1. **No spam:** Máximo 3 sugerencias por heartbeat
2. **No repetición:** No repetir la misma sugerencia 2 veces en el mismo día
3. **Quiet hours:** No sugerir nada entre 23:00-07:00 Madrid
4. **Informativas:** Sugerencias no bloquean nada, solo informan/recuerdan

---

## 🌦️ WEATHER-AWARE

### Triggers

| Condición | Sugerencia | Threshold |
|-----------|------------|-----------|
| Lluvia | "Hoy llueve en Logroño, quizás no es día de surf" | precipitation >5mm/h |
| Viento fuerte | "Viento fuerte hoy (>40km/h), ideal para windsurf en Mundaka" | wind >40km/h |
| Temperatura extrema | "Hace mucho calor/frío hoy (>35°C/<5°C), ajusta actividades" | temp >35°C o <5°C |
| Buenas condiciones surf | "Olas en Zarautz/Mundaka: [condiciones]" | swell >1.5m |

### Implementación
- **Skill:** `weather` (wttr.in o Open-Meteo)
- **Cadencia:** Solo en heartbeat matutino (8:00-10:00)
- **Cache:** 4h (no chequear más de 1 vez cada 4h)

---

## 📅 CALENDAR-AWARE

### Triggers

| Condición | Sugerencia | Threshold |
|-----------|------------|-----------|
| Reunión pronto | "Tienes reunión en 30 min: [título]" | event starts <30min |
| Día ocupado | "Día intenso hoy: [N] eventos" | events >5 |
| Conflicto calendario | "⚠️ Conflicto detectado: [eventos]" | overlapping events |
| Evento urgente sin preparar | "Evento importante en [N]h sin prep: [título]" | high-priority event <2h |

### Implementación
- **Skill:** `gog` (Google Calendar)
- **Cadencia:** Morning briefing + cada 2h durante work hours
- **Work hours:** 9:00-21:00 Madrid (ver `memory/work-schedule.md`)
- **Cache:** 30min

---

## 😴 HEALTH-AWARE

### Triggers

| Condición | Sugerencia | Threshold |
|-----------|------------|-----------|
| Sueño insuficiente | "Dormiste poco anoche ([N]h), tómatelo con calma" | sleep <6h |
| Sueño muy corto | "⚠️ Sueño crítico ([N]h), prioriza descanso hoy" | sleep <4h |
| Mucha actividad | "Gran día de actividad ayer: [steps] pasos, [distance] km" | steps >15k |
| Body battery bajo | "Body battery bajo ([N]%), recarga energías" | body_battery <30 |
| Estrés alto | "Estrés elevado detectado ([N]/100), considera relajarte" | stress >70 |

### Implementación
- **Skill:** Garmin integration (ver `memory/garmin-integration.md`)
- **Script:** `scripts/garmin-health-report.sh`
- **Cadencia:** Solo morning briefing (8:00)
- **Device:** Garmin Instinct 2S Solar Surf
- **OAuth:** Manu_Lazarus

---

## 💰 FINANCE-AWARE

### Triggers

| Condición | Sugerencia | Threshold |
|-----------|------------|-----------|
| Gasto diario alto | "Llevas €[X] gastados hoy" | daily_expense >€100 |
| Gasto semanal alto | "Semana cara: €[X] gastados" | weekly_expense >€500 |
| Gasto mensual tracking | "Llevas €[X]/€[budget] este mes" | >70% monthly budget |
| Extracto bancario pendiente | "Hace [N] días del último extracto, recordar actualizar" | >15 days since last update |

### Implementación
- **Source:** Google Sheets (`sheets-populate-v2.py`)
- **Sheet ID:** `1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA`
- **Cadencia:** Morning briefing + cada 2 días
- **Privacy:** NUNCA detallar qué se compró, solo totales

---

## ⏰ PENDING ACTIONS

### Triggers

| Condición | Sugerencia | Threshold |
|-----------|------------|-----------|
| Items urgentes antiguos | "Items urgentes sin resolver >3 días: [lista]" | priority:high age >3d |
| Items muy antiguos | "Items pendientes >7 días: [count]" | any age >7d |
| Muchos items pendientes | "Tienes [N] items pendientes, ¿priorizamos?" | count >10 |
| Items críticos | "⚠️ [N] items críticos sin resolver" | priority:critical |

### Implementación
- **Source:** `memory/pending-actions.md`
- **Parser:** Markdown parsing (formato: `- [ ]` con metadata)
- **Cadencia:** Morning briefing + cada 12h
- **Fields:** título, prioridad, fecha creación, deadline (si existe)

---

## 🔧 SYSTEM-AWARE (Bonus)

### Triggers

| Condición | Sugerencia | Threshold |
|-----------|------------|-----------|
| Backups antiguos | "Último backup hace [N] días, considera ejecutar" | >7 days |
| Muchos subagentes activos | "Tienes [N] subagentes activos, monitor overhead" | >5 active |
| Rate limits cerca | "API [provider] cerca del límite ([N]%)" | >80% rate limit |
| Cron failures | "[N] cron jobs fallando: [lista]" | any failure |

### Implementación
- **Scripts:** `rate-limit-monitor.py`, `backup-validator.sh`
- **Cadencia:** Solo si hay algo relevante (no rutinariamente)
- **Threshold:** Solo alertar si >2 problemas simultáneos

---

## 🚫 ANTI-PATTERNS

### NO sugerir:

1. **Cosas obvias** — "Es de noche" / "Es lunes"
2. **Sin contexto** — "Deberías hacer ejercicio" (sin datos Garmin)
3. **Redundantes** — Si ya se mencionó en morning briefing, no repetir en heartbeat siguiente
4. **Fuera de horas** — Nada entre 23:00-07:00
5. **Spam emocional** — Evitar tono patronizing ("Deberías...", "No olvides...")

### Tono correcto:

✅ "Hoy llueve en Logroño, quizás no es día de surf"  
✅ "Llevas €150 gastados hoy"  
✅ "Tienes reunión en 30 min: [título]"  

❌ "Deberías quedarte en casa porque llueve"  
❌ "¡Cuidado! Estás gastando mucho dinero"  
❌ "No olvides tu reunión"  

---

## 🔄 DEDUPLICATION

### Estado persistente

**Archivo:** `memory/.proactive-suggestions-today.json`

**Estructura:**
```json
{
  "date": "2026-03-24",
  "suggestions_sent": [
    {"type": "weather", "key": "rain-logrono", "timestamp": "2026-03-24T08:15:00Z"},
    {"type": "calendar", "key": "meeting-123", "timestamp": "2026-03-24T09:30:00Z"},
    {"type": "health", "key": "sleep-low-6h", "timestamp": "2026-03-24T08:15:00Z"}
  ],
  "count": 3
}
```

### Reset automático

- **Cuándo:** Cada día a las 00:00 Madrid
- **Cómo:** Cron nocturno o primer heartbeat del día

---

## 🎚️ CONFIGURACIÓN

### Prioridades (1-5, 5=más importante)

| Categoría | Prioridad | Max/día |
|-----------|-----------|---------|
| Calendar | 5 | 3 |
| Health | 4 | 1 |
| Pending actions | 4 | 1 |
| Weather | 3 | 1 |
| Finance | 3 | 1 |
| System | 2 | 1 |

### Horarios

- **Morning briefing:** 8:00 — Todas las categorías
- **Heartbeat diurno:** 10:00, 14:00, 18:00 — Solo calendar + pending actions
- **Heartbeat nocturno:** 22:00 — Solo system-aware (silencioso)

---

## 📊 MÉTRICAS

### Trackear (opcional, para mejora continua):

- Sugerencias enviadas por categoría
- False positives (sugerencias no útiles)
- Timing (¿llegaron en el momento correcto?)
- User feedback (thumbs up/down si Telegram lo permite)

**Archivo:** `memory/.proactive-metrics.jsonl`

---

## 🛠️ MANTENIMIENTO

### Revisión periódica

- **Cada 2 semanas:** Revisar thresholds (¿son correctos?)
- **Cada mes:** Revisar categorías (¿faltan sugerencias útiles?)
- **Cada 3 meses:** Revisar uso real vs configurado

### Extensibilidad

Este archivo es **vivo**. Añade nuevas reglas conforme descubras patrones útiles.

---

**Última actualización:** 2026-03-24  
**Owner:** Lola (lolaopenclaw@gmail.com)  
**Feedback:** Manu decide qué funciona y qué no
