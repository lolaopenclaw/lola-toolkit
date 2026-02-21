# Sesión 13: Garmin - Automatización Completa

**Hora:** 20:06-20:12 UTC (21:06-21:12 Madrid)

## Sistema de automatización implementado

Manu solicitó ejecutar TODOS los pasos sugeridos para automatizar Garmin Connect.

### Scripts creados

#### 1. `garmin-check-alerts.sh` - Sistema de alertas inteligentes
**Detecta condiciones anormales en últimos 3 días:**

**Alertas WARNING (⚠️):**
- Heart rate reposo < 40 bpm (bradicardia)
- Heart rate reposo > 80 bpm (taquicardia)
- Estrés ≥ 60 (estrés alto)
- Sueño < 6 horas (insuficiente)
- Body Battery < 15 (agotamiento)

**Alertas INFO (ℹ️):**
- Heart rate máximo > 180 bpm (ejercicio intenso)
- Sueño profundo < 0.5h (con sueño total ≥6h)

**Recomendaciones automáticas:**
- Estrés alto → técnicas de relajación
- Poco sueño → priorizar 7-8h las próximas noches
- Body Battery bajo → descansar más, reducir intensidad

### Crons configurados

#### 1. Informe matutino (9:00 AM diario)
**Nombre:** `Garmin - Informe matutino`
**Modelo:** Haiku (económico)
**Acción:**
1. Ejecuta `garmin-health-report.sh` (ayer)
2. Análisis breve: ¿algo destacable?
3. Formato: conciso, bullets, emojis
4. **Solo envía si hay algo relevante** (no rutinario)

**Próxima ejecución:** Mañana 21/02 9:00 AM

#### 2. Resumen semanal (lunes 8:30 AM)
**Nombre:** `Garmin - Resumen semanal`
**Modelo:** Haiku
**Acción:**
1. Ejecuta `garmin-historical-analysis.sh 7`
2. Análisis: tendencias, mejoras, oportunidades
3. Compara con semana anterior
4. Recomendaciones específicas para esta semana
5. Formato: organizado, visual, accionable

**Próxima ejecución:** Lunes 24/02 8:30 AM

#### 3. Alertas de salud (14:00 y 20:00 diario)
**Nombre:** `Garmin - Alertas de salud`
**Modelo:** Haiku
**Acción:**
1. Ejecuta `garmin-check-alerts.sh`
2. **Si hay alertas:** envía resumen + recomendaciones
3. **Si todo OK:** HEARTBEAT_OK (sin enviar)
4. Solo condiciones realmente importantes

**Próximas ejecuciones:**
- Hoy 20/02 20:00 (en 48 minutos)
- Mañana 21/02 14:00 y 20:00

### Total de crons Garmin: 3

- **Diarios:** 2 (informe 9 AM + alertas 14:00/20:00)
- **Semanales:** 1 (resumen lunes 8:30 AM)
- **Modelo:** Haiku (todos) - económico
- **Delivery:** Telegram a Manu (6884477)

### Frecuencia de consultas API Garmin

**Estimado:**
- Informe matutino: 1x/día (1 día de datos)
- Alertas: 2x/día (3 días de datos c/u)
- Resumen semanal: 1x/semana (7 días de datos)

**Total consultas/mes:** ~90 llamadas API

**Tokens OAuth:** Renovables automáticamente, no expiran si se usan regularmente.

## Métricas baseline (20 feb 2026)

Para comparación futura:

### Actividad (últimos 7 días):
- Pasos promedio: 5,155/día
- Días activos (>7.5k): 29%
- Días sedentarios (<5k): 57%
- Distancia: 4.13 km/día

### Cardiovascular:
- HR reposo promedio: 54 bpm ✅ (excelente)
- HR rango: 52-57 bpm
- HR máximo promedio: 103 bpm

### Bienestar:
- Estrés promedio: 26 (bajo)
- Sueño promedio: 7.9h/noche
- Sueño profundo: 1.3h/noche

### Observaciones:
- 🏆 Forma cardiovascular excelente
- ✅ Estrés muy bien manejado
- ✅ Sueño adecuado
- ⚠️ Oportunidad: aumentar actividad física diaria

## Archivos actualizados

- `MEMORY.md` → Añadidos 3 nuevos crons Garmin (total: 13 crons)
- `USER.md` → Sección Health & Fitness completada con datos actuales
- `memory/2026-02-20/12-garmin-completado.md` → Actualizado con scripts y análisis

## Commit guardado

```
feat: Garmin automatización completa - 3 crons + alertas

CRONS CREADOS:
- Informe matutino (9 AM diario) - Haiku
- Resumen semanal (lunes 8:30 AM) - Haiku
- Alertas salud (14:00 y 20:00 diario) - Haiku

SCRIPT NUEVO:
- garmin-check-alerts.sh: Detecta condiciones anormales (HR, estrés, sueño, body battery)

TOTAL CRONS ACTIVOS: 13 (10 previos + 3 Garmin)

Baseline 20/02: HR 54bpm, estrés 26, 5.1k pasos/día
```

## Beneficios

### Para Manu:
1. **Visibilidad proactiva** de su salud sin revisar manualmente
2. **Alertas automáticas** de condiciones anormales
3. **Tendencias semanales** para ajustar hábitos
4. **Cero esfuerzo** - todo automatizado

### Para el sistema:
1. **Datos históricos** para correlaciones futuras
2. **Baseline establecido** para medir mejoras
3. **Alertas inteligentes** no invasivas (solo si importa)
4. **Económico** - todo con Haiku (~$0.02/día estimado)

## Próximas mejoras (opcional - futuro)

1. [ ] Correlación actividad vs estado de ánimo
2. [ ] Sincronización con Notion (tabla Health)
3. [ ] Gráficos de tendencias (ASCII art o imágenes)
4. [ ] Predicción de Body Battery para planificar día
5. [ ] Recomendaciones personalizadas basadas en patrones

---

**Estado:** ✅ COMPLETAMENTE OPERATIVO  
**Próxima acción:** Esperar primer informe mañana 9 AM
