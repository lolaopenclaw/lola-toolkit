# Informe de Consumo - 2026-02-20

**Fecha:** 2026-02-20 (viernes)  
**Periodo:** Mes febrero 2026

---

## 💰 RESUMEN FINANCIERO

### Hoy (20 febrero)
**Total: $48.90 USD**

| Modelo | Costo | Input | Output | Requests |
|--------|-------|-------|--------|----------|
| Claude Sonnet 4.5 | $46.88 | 2.5K | 105.9K | 217 |
| Claude Opus 4.6 | $1.90 | 30 | 29.7K | 28 |
| Claude Haiku 4.5 | $0.12 | 85 | 3.2K | 7 |

**Distribución:** 95.9% Sonnet, 3.9% Opus, 0.2% Haiku

### Ayer (19 febrero)
**Total: $221.71 USD** 🔴 Día intensivo

| Modelo | Costo | Input | Output | Requests |
|--------|-------|-------|--------|----------|
| Claude Opus 4.6 | $192.66 | 833 | 99.6K | 529 |
| Claude Sonnet 4.5 | $28.98 | 1.4K | 30.2K | 126 |
| Claude Haiku 4.5 | $0.04 | 74 | 1.5K | 6 |

**Distribución:** 86.9% Opus, 13.1% Sonnet

### Mes Completo (febrero 2026)
**Total: $398.98 USD**

| Modelo | Costo | Input | Output | Requests |
|--------|-------|-------|--------|----------|
| Claude Opus 4.6 | $302.48 | 1.6K | 220.0K | 998 |
| Claude Sonnet 4.5 | $75.86 | 4.0K | 136.1K | 343 |
| Gemini 2.5 Flash Lite | $10.59 | 90.9M | 262.6K | 385 |
| Gemini 2.5 Flash | $9.45 | 26.2M | 40.9K | 128 |
| Gemini 3 Flash Preview | $0.41 | 795.5K | 4.1K | 86 |
| Claude Haiku 4.5 | $0.15 | 159 | 4.7K | 13 |

**Distribución:** 75.8% Opus, 19.0% Sonnet, 5.2% Gemini

---

## 📊 ANÁLISIS DE CONSUMO

### Cambio Diario (ayer → hoy)
- **-$172.81 USD (-78%)** 
- Cambio de Opus → Sonnet como modelo principal
- Menos requests totales (667 → 251)
- Output total: 99.6K → 105.9K tokens (+6%)

### Tendencias del Mes
- **Opus dominante:** 75.8% del gasto total ($302.48)
- **998 requests de Opus** - Usado intensivamente para tareas complejas
- **Gemini:** Usado ocasionalmente ($20.45 total, 599 requests)
- **Haiku:** Muy poco usado ($0.15, 13 requests)

### Promedio Diario (20 días)
- **$19.95 USD/día** (basado en total mensual)
- Picos: 19 feb ($221.71) - Día de configuración intensiva
- Días normales: ~$10-20 USD

---

## 🎯 CONTEXTO DE USO

### HOY (20 febrero) - $48.90
**Actividades principales:**

1. **Sistema de Recovery Automatizado** 🏗️
   - Sub-agente Opus (thinking profundo) - $1.90
   - Diseño de bootstrap.sh, restore.sh, hardening.sh
   - 8min 19s de análisis profundo
   - Output: 29.7K tokens (scripts completos + documentación)

2. **Sesión Principal (Sonnet)** - $46.88
   - Extensión Chrome debugging (~10 requests)
   - Rollback OpenClaw 2026.2.19-2 → 2026.2.17
   - Auditoría de seguridad VPS profunda
   - Hardening fase 1 y 2 (5 mejoras aplicadas)
   - Lynis + rkhunter instalación
   - 8 tareas añadidas a Notion Ideas
   - Sistema de trazabilidad configurado
   - Documentación extensa (RECOVERY.md, BOOTSTRAP.md, etc.)

3. **Crons y Heartbeats (Haiku)** - $0.12
   - 7 checks de heartbeat
   - Configuración de crons semanales

**Razón del gasto:**
- Sub-agente Opus para tarea compleja (recovery system)
- Sesión principal muy larga (>4 horas)
- Mucha generación de scripts y documentación
- 217 requests Sonnet = ~1 request cada minuto

### AYER (19 febrero) - $221.71 🔴
**Actividades principales:**

1. **Notion Kanban Board desde cero**
   - Configuración inicial de workspace
   - Navegador headless para login
   - Debugging API Notion (2025-09-03 vs 2022-06-28)
   - Creación de 20 tareas reales
   - Configuración de vistas y propiedades

2. **Problema:** Muchas iteraciones con Opus
   - 529 requests de Opus (vs 217 Sonnet hoy)
   - Debugging intensivo de API Notion
   - Data sources vs databases confusion
   - Múltiples intentos de crear tablero correcto

**Razón del gasto altísimo:**
- Opus usado como modelo principal (antes del rollback)
- Problema complejo con API Notion requirió muchas iteraciones
- No había configuración de Haiku para crons todavía

---

## 📈 PROYECCIÓN MENSUAL

**Basado en $398.98 en 20 días:**
- **Proyección fin de mes:** ~$560 USD
- **Si continúa tendencia actual (~$50/día):** ~$650 USD
- **Si volvemos a promedio pre-19feb (~$10-15/día):** ~$450 USD

**Factores a considerar:**
- 19 feb fue excepcional ($221.71) - inflado por debugging Notion
- Ahora usamos Haiku para crons → Ahorro
- Rollback a 2026.2.17 → Más estable, menos debugging
- Sistema de recovery completo → Menos iteraciones futuras

---

## 🔌 APIS EXTERNAS (Sin Límites Detectados)

### ElevenLabs (TTS)
- **Status:** No hay límite mensual en logs
- **Uso:** Ocasional (solo cuando Manu pide audio explícitamente)
- **Política nueva:** Solo responder con audio si se pide

### Notion API
- **Límite:** 1000 requests/minuto (muy alto)
- **Uso actual:** ~5-10 requests/día (muy bajo)
- **Sin riesgo de agotamiento**

### Google APIs (Gmail, Calendar, Drive vía GOG)
- **Sin límites monetarios visibles**
- **Autenticación OAuth válida**

### Rclone (Google Drive)
- **Sin límites de API**
- **Backup diario funcionando correctamente**

---

## 💡 RECOMENDACIONES

### Para Reducir Costos

1. **✅ Ya aplicado:** Haiku para crons y heartbeats
   - Ahorro estimado: $5-10/día en checks rutinarios

2. **✅ Ya aplicado:** Rollback a 2026.2.17
   - Sistema más estable = menos debugging = menos tokens

3. **Considerar:** Usar Haiku para más tareas rutinarias
   - Verificaciones simples
   - Reportes de estado
   - Queries básicas a Notion

4. **Monitorear:** Sub-agentes Opus
   - Útiles para tareas complejas
   - Pero pueden ser caros si se usan frecuentemente
   - Hoy: $1.90 por 1 sub-agente (razonable para el resultado)

### Para Mejorar Trazabilidad

1. **✅ Implementado hoy:** Sistema de captura automática
   - Reportes → Notion Ideas automáticamente
   - Cleanup semanal de Ideas completadas

2. **Próximo paso:** Este informe diario automatizado
   - Cron para generar informe cada noche
   - Acumulado mensual en memoria

---

## 📝 NOTAS TÉCNICAS

### Datos Disponibles
- **Histórico:** Logs desde 2026-02-06 (parcial)
- **Completo desde:** 2026-02-18
- **Precisión:** Por request individual en session JSONL files
- **Granularidad:** Timestamp, modelo, input, output, costo

### Limitaciones
- No hay datos de requests fallidos (solo exitosos)
- ElevenLabs usage no está en logs (solo inference success/fail)
- Memory files solo dan contexto cualitativo, no cuantitativo exacto

---

## 🎯 CONCLUSIÓN

**Hoy fue un día productivo y relativamente económico:**
- $48.90 vs $221.71 ayer (-78%)
- Sub-agente Opus justificado (sistema de recovery completo)
- Sesión principal con Sonnet = buen balance precio/calidad
- Sistema de trazabilidad implementado → mejorará visibilidad futura

**Mes va bien:**
- $399 en 20 días = $20/día promedio
- Spike de ayer inflado por debugging Notion
- Tendencia hacia uso más eficiente (Haiku para rutinas)

**Próximo mes esperado:** $400-500 USD si continúa uso similar
