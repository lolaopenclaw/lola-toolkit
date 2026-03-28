# 📊 Model Strategy Metrics Tracking

**Período:** YYYY-MM-DD a YYYY-MM-DD (4 semanas post-implementación)  
**Baseline:** 2026-03-24 (pre-strategy)

---

## 🎯 Objetivos Medibles

| Métrica | Baseline | Target | Actual | Estado |
|---------|----------|--------|--------|--------|
| **Autoimprove timeouts** | 3/3 (100%) | 0/3 (0%) | - | ⏳ |
| **Google Sheets errores/mes** | ~5 | <2 | - | ⏳ |
| **Healthcheck falsos positivos** | ~20% | <10% | - | ⏳ |
| **Coste mensual crons** | $14.81 | <$25 | - | ⏳ |
| **Crons con errores** | 3 | <1 | - | ⏳ |

---

## 📈 Tracking Semanal

### Semana 1 (YYYY-MM-DD a YYYY-MM-DD)

#### Autoimprove Agents
- **Scripts:** Completado ✅ / Timeout ❌ / No ejecutado ⏸️
  - Duración: XXXs / 900s
  - Iteraciones completadas: XX/15
  - Cambios aplicados: XX kept, YY discarded
  
- **Skills:** Completado ✅ / Timeout ❌ / No ejecutado ⏸️
  - Duración: XXXs / 900s
  - Iteraciones completadas: XX/15
  - Mejora en tokens: -XX tokens
  
- **Memory:** Completado ✅ / Timeout ❌ / No ejecutado ⏸️
  - Duración: XXXs / 900s
  - Iteraciones completadas: XX/15
  - Consolidaciones: XX

#### Healthchecks de Seguridad
- **fail2ban-alert:** Ejecuciones: X, Alertas generadas: Y, Falsos positivos: Z
- **rkhunter-scan:** Ejecuciones: X, Warnings: Y, Precisión: Z%
- **lynis-scan:** Ejecuciones: X, Hardening delta: Y puntos
- **security-audit:** Ejecuciones: X, Issues encontrados: Y, Falsos positivos: Z

#### Google Sheets v2
- **Ejecuciones:** X/7 días
- **Exitosas:** Y
- **Errores:** Z (detallar tipo)
- **Tiempo promedio:** XXs

#### Garmin Weekly
- **Ejecutado:** ✅ / ❌
- **Calidad narrativa:** 1-5 ⭐
- **Duración:** XXs

#### Coste Semanal
```
Modelo         | Tokens Input | Tokens Output | Coste
---------------|--------------|---------------|-------
Opus           | X,XXX        | X,XXX         | $X.XX
Sonnet         | X,XXX        | X,XXX         | $X.XX
Haiku          | X,XXX        | X,XXX         | $X.XX
Flash          | X,XXX        | X,XXX         | $X.XX
---------------|--------------|---------------|-------
TOTAL          |              |               | $X.XX
```

**Proyección mensual:** $XX.XX

**Notas:**
- Incidentes: Ninguno / [Describir]
- Observaciones: [Texto]

---

### Semana 2 (YYYY-MM-DD a YYYY-MM-DD)

[Repetir estructura Semana 1]

---

### Semana 3 (YYYY-MM-DD a YYYY-MM-DD)

[Repetir estructura Semana 1]

---

### Semana 4 (YYYY-MM-DD a YYYY-MM-DD)

[Repetir estructura Semana 1]

---

## 📊 Resumen Mensual

### Logros ✅

- [ ] Autoimprove agents: 0 timeouts (vs 3 baseline)
- [ ] Google Sheets: <2 errores/mes (vs 5 baseline)
- [ ] Healthchecks: >90% precisión
- [ ] Coste mensual: Dentro de +$15/mes (+20% margen)
- [ ] Satisfacción Manu: Mejora reportada

### Problemas Identificados ⚠️

1. **[Problema 1]**
   - Descripción: ...
   - Frecuencia: X veces
   - Impacto: Alto/Medio/Bajo
   - Solución propuesta: ...

2. **[Problema 2]**
   - ...

### Coste Real vs Estimado 💰

| Categoría | Estimado | Real | Δ | Razón |
|-----------|----------|------|---|-------|
| Mantenimiento | $2.40 | $X.XX | $X.XX | ... |
| Informes | $7.95 | $X.XX | $X.XX | ... |
| Seguridad | $5.85 | $X.XX | $X.XX | ... |
| Autoimprove | $4.50 | $X.XX | $X.XX | ... |
| Semanales | $1.26 | $X.XX | $X.XX | ... |
| Config | $0.30 | $X.XX | $X.XX | ... |
| **TOTAL** | **$22.31** | **$X.XX** | **$X.XX** | ... |

**Desviación:** +X% / -X%

**Explicación:**
- [Por qué el coste real difiere del estimado]

---

## 🔄 Ajustes Recomendados

### Upgrades Adicionales

| Cron | De | A | Razón | Coste Δ |
|------|----|----|-------|---------|
| [Nombre] | Haiku | Sonnet | ... | +$X.XX |
| [Nombre] | Sonnet | Haiku | ... | -$X.XX |

### Downgrades (Optimización)

| Cron | De | A | Razón | Coste Δ |
|------|----|----|-------|---------|
| [Nombre] | Sonnet | Haiku | Tarea más simple de lo pensado | -$X.XX |

### Timeouts

| Cron | Actual | Propuesto | Razón |
|------|--------|-----------|-------|
| [Nombre] | XXXs | XXXs | ... |

---

## 📈 Comparación de Calidad

### Antes (Baseline)

**Informe Matutino:**
- Precisión: X/10
- Completitud: X/10
- Tiempo generación: XXs

**Healthchecks:**
- Falsos positivos: ~20%
- Issues encontrados: X/mes
- Tiempo análisis: XXs

**Google Sheets:**
- Tasa error: ~5/mes
- Debugging manual: ~30 min/error

### Después (Post-Strategy)

**Informe Matutino:**
- Precisión: X/10 (+/-X)
- Completitud: X/10 (+/-X)
- Tiempo generación: XXs (+/-Xs)

**Healthchecks:**
- Falsos positivos: ~X% (+/-X%)
- Issues encontrados: X/mes (+/-X)
- Tiempo análisis: XXs (+/-Xs)

**Google Sheets:**
- Tasa error: ~X/mes (-X)
- Debugging manual: ~X min/error (-X min)

---

## 💬 Feedback de Manu

**Satisfacción general:** 1-10 ⭐

**Aspectos destacados:**
- ✅ [Lo que mejoró notablemente]
- ✅ [Otro aspecto positivo]

**Aspectos a mejorar:**
- ⚠️ [Lo que aún no satisface]
- ⚠️ [Otra área de mejora]

**Comentarios libres:**
```
[Espacio para feedback textual de Manu]
```

---

## 🚦 Decisión Final

Tras 4 semanas de monitoreo:

### ✅ Opción A: MANTENER ESTRATEGIA
- Los cambios funcionan como esperado
- Coste justificado por mejora en calidad
- Continuar con estrategia actual

### 🔄 Opción B: AJUSTAR
- Algunos cambios funcionan, otros no
- Aplicar ajustes recomendados arriba
- Re-evaluar en 2 semanas

### ❌ Opción C: REVERTIR
- Cambios no justifican coste/esfuerzo
- Rollback a configuración baseline
- Documentar lecciones aprendidas

---

## 📝 Lecciones Aprendidas

1. **[Lección 1]**
   - Qué funcionó: ...
   - Qué no funcionó: ...
   - Para futuro: ...

2. **[Lección 2]**
   - ...

---

## 🔜 Próximos Pasos

- [ ] Actualizar `memory/model-strategy.md` con hallazgos
- [ ] Documentar cambios en `MEMORY.md`
- [ ] Si ajustes: aplicar y re-evaluar en 2 semanas
- [ ] Si mantener: agendar revisión trimestral
- [ ] Crear recordatorio en pending-actions.md

---

**Plantilla creada:** 2026-03-24  
**Período de tracking:** Iniciar tras aplicar cambios  
**Responsable:** Lola (autoimprove + informe matutino)
