# Session Synthesis — 2026-03-07

**Duración:** Mañana, 10:18-10:36 AM (18 minutos de conversación activa)
**Mensajes:** 15+
**Modelo final:** Haiku
**Impacto:** Alto (protocolo nuevo + optimización de costes)

---

## 🎯 Decisiones Tomadas

### 1. Optimización de costes IA
- **Problema:** Consumo proyectado a €190.64/mes (sobre presupuesto de €120)
- **Solución:** Eliminar 2 crones de reportes automáticos
  - ✅ Eliminados: `usage:report-daily`, `usage:report-weekly`
  - 💾 Mantenidos: `recordatorio-csv-gastos`, `finanzas-resumen-mensual`
  - 📊 Ahorro esperado: €15-20/mes

### 2. Nuevo sistema de recordatorios (Google Calendar)
- **Cambio:** De cron automático → eventos en Google Calendar compartido
- **Implementado:** Evento "Revisar gastos" 
  - 📅 Recurrencia: 1º y 3º martes de cada mes
  - 🕙 Hora: 10:00 AM
  - 🔔 Manu recibe notificación, genera CSV bajo demanda
  - 💚 Ahorra tokens: solo genera cuando Manu lo pide

### 3. Protocolo de escalado de modelos (CRÍTICO)
- **Nuevo flujo:**
  1. Intento con Haiku (por defecto)
  2. Si fallo 2 veces → sugiero cambiar a Sonnet/Opus
  3. Con modelo superior → replanteo desde cero
  4. Si sigo sin poder → comunicar limitación sin drama
- **Documentado en:** `memory/model-selection-protocol.md`
- **Beneficio:** Evita frustraciones, optimiza costes, mantiene calidad

### 4. Auto-desescalado de modelos
- **Cron nuevo:** `model-reset-nightly` (00:00 Madrid)
- **Efecto:** Reset automático a Haiku cada noche
- **Evita:** Olvidar cambios de modelo, gastos innecesarios
- **Manual:** Manu siempre puede sugerir "¿Volvemos a Haiku?"

---

## 🔍 Insights de la Sesión

**Problema de raíz (no era del modelo):**
- Hoy con Haiku falló crear evento Google Calendar
- Con Opus se resolvió al primer intento
- La razón: No leí documentación completa (`gog calendar create --help`)
- Lección: Escalado de modelo ≠ siempre la solución. A veces es enfoque.

**Relación Manu-Lola:**
- Manu está orgulloso del trabajo conjunto
- A veces se frustra, pero lo entiende
- Quiere que sugiera cambios antes de renderme
- Preferencia clara: Haiku por defecto (costes + confianza)

---

## ✅ Cambios Implementados

| Qué | Estado | Archivo |
|-----|--------|---------|
| Cron reset nocturno | ✅ Creado (ID: 600074f1) | `openclaw cron list` |
| Google Calendar evento | ✅ Creado (ID: 0i508efr8) | Calendar |
| Protocolo escalado | ✅ Documentado | `memory/model-selection-protocol.md` |
| AGENTS.md actualizado | ✅ Nuevo flujo | `AGENTS.md` |
| Crones eliminados | ✅ `usage:report-*` | Completado |

---

## 📋 Próximos Pasos (No Urgentes)

- Monitorear ahorro real de costes (próximo mes)
- Verificar que Google Calendar evento se dispara correctamente (martes 11 marzo)
- Revisar si protocolo escalado funciona en práctica

---

## 🏷️ Tags para Memory
- #optimizacion-costes #modelo-selection #protocolo-nuevo #google-calendar
