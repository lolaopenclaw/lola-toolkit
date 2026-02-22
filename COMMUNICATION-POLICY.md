# 📢 Política de Comunicación - Decisión Manu 2026-02-22

## Principio: Silencio por defecto, reportes consolidados por la mañana

**Manu quiere:**
- ✅ Yo hago todos los chequeos internamente (diarios, sin restricción)
- ❌ Pero NO le reporto nada a Telegram salvo que haya problemas críticos
- 📋 **UN ÚNICO INFORME CONSOLIDADO** por la mañana (9 AM lunes-viernes, 10 AM fin de semana)
- 🚨 Excepciones críticas: alerta inmediata (sin restricción horaria)

## Arquitectura de Comunicación

### 1. Heartbeats (checks internos)
- Ejecutar múltiples veces al día (comprobaciones periódicas)
- **Respuesta NORMAL:** `HEARTBEAT_OK` — silencio total
- **Respuesta SI HAY PROBLEMA CRÍTICO:** reportar SOLO problemas de seguridad/operación
- Nunca enviar status summaries rutinarias

### 2. Crons automáticos (todos con delivery: none)
- Todos los chequeos se ejecutan INTERNAMENTE sin enviar a Telegram:
  - `garmin:morning-report` (9 AM) → integrado en informe matutino
  - `healthcheck:fail2ban-alert` (cada 6h) → integrado en informe matutino
  - `healthcheck:security-audit-weekly` (lunes) → integrado en informe matutino
  - `healthcheck:lynis-scan-weekly` (lunes) → integrado en informe matutino
  - `healthcheck:rkhunter-scan-weekly` (lunes) → integrado en informe matutino
  - `usage:report-daily` (10 AM fin de semana) → integrado en informe matutino
  - `usage:report-weekly` (lunes) → integrado en informe matutino
  - `Tareas de fondo semanales` (lunes) → integrado en informe matutino
  - `notion:ideas-cleanup-weekly` (lunes) → integrado en informe matutino
  - `Garmin - Resumen semanal` (lunes) → integrado en informe matutino

### 3. Informes matutinos CONSOLIDADOS (entrega única)
- **Lunes-viernes:** 9:00 AM
- **Sábado-domingo:** 10:00 AM
- **UN SOLO mensaje** con todas las secciones:
  - Sistema (actualizaciones, backup, consumo, Notion)
  - Seguridad (Fail2Ban, auditorías, scans) - SOLO LUNES
  - Salud (Garmin diario + semanal) - SOLO LUNES para semanal
  - Tareas de fondo (Notion background) - SOLO LUNES
  - Consumo semanal - SOLO LUNES

### 4. Excepciones críticas (alertas inmediatas)
- Fail2Ban ≥10 IPs baneadas → alerta ahora
- Rootkit/malware detectado → alerta ahora
- Error crítico del sistema → alerta ahora
- Acceso no autorizado → alerta ahora
- Backup fallido crítico → alerta ahora
- Gateway caído → alerta ahora
- Garmin alertas de salud (14:00, 20:00) → SOLO si condición crítica

## Beneficios
- 📵 **Cero notificaciones rutinarias** a Telegram
- 📋 **Una fuente única** de información (informe matutino)
- 🎯 **Información estructurada y útil**, no fragmentada
- ✅ **Yo trabajo en background** sin interrupciones
- 🚨 **Alertas críticas** entregadas al instante
- 😴 **Manu duerme tranquilo** (00:00-07:00 Madrid = silencio total)
