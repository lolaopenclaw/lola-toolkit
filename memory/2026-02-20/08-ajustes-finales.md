# Sesión 8: Ajustes Finales de Configuración

## Fail2ban movido a horario matutino
**Hora:** 12:28 UTC

**Cambio solicitado:** Mover alertas para respetar horario silencioso

**Implementación:**
- Eliminado cron cada 6h
- Creado `healthcheck:fail2ban-alert-morning` (diario 7:00 AM)
- Reporta intentos fallidos últimas 24h
- Solo alerta si >5 IPs baneadas

## Horario silencioso documentado
**00:00-07:00 Madrid (medianoche a 7 AM)**
- NO enviar mensajes a Telegram
- Resumir reportes nocturnos a primera hora
- Excepciones: solo emergencias críticas

## Garmin investigación
Tarea creada en Notion Ideas:
- "Integración con Garmin Connect (health data)"
- Estado: Ideas
- Prioridad: Media

## Crons finales: 10
1. Backup diario (4:00 AM)
2. Fail2ban daily (7:00 AM)
3. Informe matutino (9:00 AM)
4. Informe consumo diario (23:55)
5. Tareas de fondo (lunes 5:00 AM)
6. Auditoría seguridad (lunes 6:00 AM)
7. Lynis scan (lunes 6:00 AM)
8. rkhunter scan (lunes 6:00 AM)
9. Cleanup Ideas (lunes 7:00 AM)
10. Informe consumo semanal (lunes 8:00 AM)

**Todos respetan horario silencioso 00:00-07:00 Madrid**
