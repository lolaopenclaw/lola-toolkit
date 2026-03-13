# Roadmap de Enriquecimientos - Informes de Consumo

**Fecha inicio:** 2026-02-20  
**Estado:** Versión 1.0 implementada (básica)

---

## ✅ FASE 1: BÁSICO (Implementado hoy)

### Informes Configurados
- ✅ Diario (23:55) - Con alerta si >$50
- ✅ Semanal (lunes 8:00) - Resumen completo

### Contenido Actual
- ✅ Resumen financiero (hoy, ayer, mes)
- ✅ Análisis por modelo
- ✅ Contexto de uso (qué se hizo)
- ✅ Proyección mensual
- ✅ Recomendaciones básicas

---

## 🔄 FASE 2: VISUALIZACIÓN (Próximo)

### 1. Gráficos/Tendencias
**Prioridad:** Alta  
**Implementar:** Próximas 2 semanas

- [ ] Línea de tiempo ASCII del mes (consumo por día)
- [ ] Distribución por modelo (pie chart en texto ASCII)
- [ ] Gráfico de barras: top 5 días más caros
- [ ] Sparklines para tendencias (↗️↘️→)

**Ejemplo:**
```
Consumo Diario (febrero 2026)
$250│     █
    │     █
    │   █ █
 $50│ █ █ █ █ █
    └─────────────
     18 19 20 21 22
```

### 2. Comparativas
**Prioridad:** Alta  
**Implementar:** Con FASE 2

- [ ] Semana actual vs semana anterior
- [ ] Mes actual vs mes anterior
- [ ] Promedio móvil 7 días
- [ ] Detección de anomalías (>2x promedio)

---

## 🚨 FASE 3: ALERTAS INTELIGENTES (Próximo mes)

### 3. Detección de Patrones
**Prioridad:** Media  
**Implementar:** Marzo 2026

- [ ] "⚠️ Consumo hoy 3x promedio diario"
- [ ] "💡 Detectado sub-agente caro: $X (sesión Y)"
- [ ] "📈 Tendencia al alza: +20% vs semana pasada"
- [ ] "🎯 Día eficiente: bajo costo, alta productividad"
- [ ] "🔴 Alerta: proyección excede presupuesto"

### 4. Alertas Proactivas
- [ ] Si consumo >$100 en un día → alerta inmediata
- [ ] Si proyección mensual >$800 → sugerir optimizaciones
- [ ] Si modelo caro usado para tarea simple → sugerir Haiku

---

## 📊 FASE 4: DESGLOSE POR ACTIVIDAD (Futuro)

### 5. Categorización de Requests
**Prioridad:** Baja (requiere instrumentación)  
**Implementar:** Abril-Mayo 2026

**Categorías propuestas:**
- Crons/Heartbeats
- Sesión principal (interactiva)
- Sub-agentes (spawned)
- Generación de código
- Análisis/auditorías
- Debugging/troubleshooting

**Implementación requiere:**
- Tag en cada request con categoría
- Modificar código de OpenClaw o logging
- Alternativa: inferir de contexto en post-procesamiento

**Beneficio:**
```
Desglose por Actividad (20 feb):
- Sesión principal: $46.88 (95.8%)
- Sub-agentes: $1.90 (3.9%)
- Crons: $0.12 (0.3%)
```

---

## 💪 FASE 5: EFICIENCIA Y MÉTRICAS (Futuro)

### 6. KPIs de Eficiencia
**Prioridad:** Media  
**Implementar:** Mayo 2026

- [ ] Tokens/request promedio (por modelo)
- [ ] Costo/hora de trabajo
- [ ] Requests fallidos (waste)
- [ ] Cache hit rate (si disponible)
- [ ] Tiempo respuesta promedio

**Ejemplo:**
```
Eficiencia Hoy:
- Tokens/request: 488 (↓ 12% vs ayer)
- Costo/hora: $12.22
- Requests fallidos: 2 (0.8%)
- Tiempo respuesta: 2.3s promedio
```

### 7. Benchmarks
- [ ] Costo por tipo de tarea común
  - "Generar script: $0.50 promedio"
  - "Auditoría seguridad: $2.00 promedio"
  - "Sub-agente análisis: $1.50 promedio"

---

## 🔌 FASE 6: APIS EXTERNAS (Futuro)

### 8. Tracking de Límites
**Prioridad:** Baja  
**Implementar:** Junio 2026

**APIs a monitorear:**
- [ ] ElevenLabs (TTS)
  - Requests usados/límite mensual
  - Caracteres consumidos
- [ ] Notion API
  - Requests usados/1000 límite por minuto
- [ ] Google APIs (Drive, Gmail)
  - Quotas si disponibles
- [ ] Anthropic
  - Tokens usados vs tier limits

**Nota:** Requiere instrumentación o scraping de dashboards

---

## 📅 CALENDARIO DE IMPLEMENTACIÓN

| Fase | Prioridad | Fecha Objetivo | Esfuerzo |
|------|-----------|----------------|----------|
| **FASE 1** | ✅ Crítica | 2026-02-20 | ✅ Completado |
| **FASE 2** | 🔴 Alta | 2026-03-05 | 1 semana |
| **FASE 3** | 🟡 Media | 2026-03-15 | 1 semana |
| **FASE 4** | 🟢 Baja | 2026-04-30 | 2 semanas |
| **FASE 5** | 🟡 Media | 2026-05-15 | 1 semana |
| **FASE 6** | 🟢 Baja | 2026-06-01 | Variable |

---

## 🎯 PRÓXIMOS PASOS INMEDIATOS

**Esta semana:**
1. ✅ Validar primer informe diario (tonight 23:55)
2. ✅ Validar primer informe semanal (lunes 8:00)
3. Recoger feedback de Manu

**Próximas 2 semanas (FASE 2):**
1. Implementar gráficos ASCII
2. Añadir comparativas semana vs semana
3. Mejorar detección de contexto desde memory/

**Mensual:**
- Revisar roadmap y ajustar prioridades
- Implementar 1-2 fases por mes
- Iterar basado en uso real

---

## 💡 IDEAS FUTURAS (Backlog)

- Export a CSV/JSON para análisis externo
- Dashboard web interactivo (opcional)
- Notificaciones proactivas (Telegram push vs pull)
- Presupuesto mensual configurable con alertas
- Optimizaciones automáticas (modelo selector inteligente)
- Historical analysis (año completo)

---

## 📝 NOTAS

**Principio de diseño:**
- Empezar simple, iterar basado en uso real
- No sobre-ingeniería temprana
- Priorizar insights accionables sobre métricas vanidad
- Balance entre detalle y legibilidad

**Limitaciones conocidas:**
- Datos históricos solo desde 18 feb 2026
- ElevenLabs no tiene logging detallado
- Categorización de actividades requiere trabajo extra

**Feedback bienvenido:**
- Si algo no es útil → eliminar
- Si falta algo crítico → priorizar
- Si formato no funciona → ajustar
