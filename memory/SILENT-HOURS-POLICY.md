# 🤐 Política de Horario Silencioso (Silent Hours)

## Vigencia
**Desde:** 2026-02-22 (aplicada tras violación a las 4:20 AM)
**Horario:** 00:00-07:00 Europe/Madrid (medianoche a 7 AM)

## Regla de Oro
**NUNCA enviar a Telegram durante horario silencioso a menos que sea CRÍTICO.**

### Niveles de Criticidad

| Nivel | Ejemplos | ¿Enviar de noche? |
|-------|----------|------------------|
| ⛔ CRÍTICO | Fail2Ban ≥10 IPs baneadas, rootkit detectado, acceso no autorizado, error de seguridad | ✅ SÍ, inmediatamente |
| ⚠️ ALTO | Backup fallido, WAL corruption, error de sistema | ❌ NO, guardar para 9 AM |
| ℹ️ INFO | Reportes normales, status checks, análisis | ❌ NO, guardar para 9 AM |

### Implementación Técnica

1. **Todos los crons nocturnos (00:00-07:00):**
   - `delivery: "none"` en configuración de cron
   - Sub-agentes guardan reportes en `memory/pending-reports/YYYY-MM-DD.md`
   - NO envían a Telegram

2. **Entregas agendadas a las 9:00 AM (o después):**
   - Cron batch a las 9:00 AM lee `memory/pending-reports/`
   - Agrupa todos los reportes nocturnos
   - Envía resumen unificado a Telegram
   - Limpia `memory/pending-reports/`

3. **Excepciones críticas:**
   - Si `fail2ban >= 10 IPs`: alerta inmediatamente
   - Si `security breach detected`: alerta inmediatamente
   - Documentar en WAL con timestamp

## Archivos relacionados
- `HEARTBEAT.md` — comprobaciones periódicas (puntos de control nocturno)
- `memory/pending-reports/` — zona de almacenamiento temporal nocturno
- Crons: todos los de 00:00-07:00 con delivery="none"

## Histórico de violaciones
- **2026-02-22 4:20 AM:** Reporte enviado en horario silencioso. Causa: [A investigar]. Acción: política implementada.
