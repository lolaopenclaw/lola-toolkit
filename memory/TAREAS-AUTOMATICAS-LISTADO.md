# 📋 TAREAS AUTOMATIZADAS — Listado Completo

**Ultima actualización:** 2026-02-23 | **Total:** 28 tareas

---

## 🔄 CADA 6 HORAS (Monitoreo Continuo)

### 1. 📸 WAL Snapshots (cada 6h)
- **Cuándo:** Cada 6 horas (01:33, 07:33, 13:33, 19:33 aprox)
- **Qué hace:** Crea un punto de recuperación automático de todo tu sistema
- **Para qué:** Si algo se daña, puedo recuperar tu estado de hace 6h
- **Importancia:** ⭐⭐⭐ (Crítico para recuperación ante crashes)

### 2. 🚨 WAL Snapshot Monitor (cada 6h)  
- **Cuándo:** Cada 6 horas (mismo ciclo)
- **Qué hace:** Verifica que los snapshots no crezcan demasiado
- **Para qué:** Alerta si almacenamiento está gordo (>100MB warning, >150MB crítico)
- **Importancia:** ⭐⭐⭐ (Previene problemas de disco)

### 3. ⚠️ Fail2Ban Monitoring (cada 6h)
- **Cuándo:** Cada 6 horas 
- **Qué hace:** Revisa intentos fallidos de acceso SSH, IPs baneadas
- **Para qué:** Detectar ataques o brute-force temprano
- **Importancia:** ⭐⭐⭐ (Seguridad)
- **Nota:** Respeta horario silencioso (00:00-07:00). Reportes en carpeta pending si es de noche.

---

## 📅 DIARIOS

### 4. 🔄 WAL Log Rotation (2:00 AM)
- **Cuándo:** Todos los días 2:00 AM
- **Qué hace:** Comprime logs WAL antiguos para ahorrar espacio
- **Para qué:** Mantener la carpeta WAL limpia
- **Importancia:** ⭐⭐ (Mantenimiento)

### 5. 💾 Backup diario a Google Drive (4:00 AM)
- **Cuándo:** Todos los días 4:00 AM  
- **Qué hace:** Copia todo el workspace a tu Drive (openclaw_backups folder)
- **Para qué:** Recuperar desde cualquier máquina si esta explota
- **Importancia:** ⭐⭐⭐ (Crítico)
- **Nota:** Genera checksum. Si falla, alerta automáticamente.

### 6. 💰 Usage Report Daily (9:10 AM - L-V)
- **Cuándo:** Lunes-Viernes 9:10 AM
- **Qué hace:** Resumen de cuánto dinero gastaste ese día en APIs
- **Para qué:** Monitorear costos, detectar gastar anormal
- **Importancia:** ⭐⭐ (Presupuesto)
- **Nota:** Solo alerta si gasto > 0 USD ese día

### 7. 💰 Usage Report Daily - Fin de Semana (10:10 AM - S/D)
- **Cuándo:** Sábado-Domingo 10:10 AM
- **Qué hace:** Lo mismo que arriba pero para fin de semana
- **Para qué:** Consistencia en reportes
- **Importancia:** ⭐⭐

### 8. 📊 Populate Google Sheets (9:30 AM - L-V)
- **Cuándo:** Lunes-Viernes 9:30 AM
- **Qué hace:** Rellena automáticamente tu sheet "Consumo IA" con datos del día anterior
- **Para qué:** Dashboard de gastos (Haiku, Sonnet, Opus, etc. por columnas)
- **Importancia:** ⭐⭐ (Visualización)
- **Nota:** Necesita client_secret.json (aún pendiente)

---

## 📋 LUNES A VIERNES - 9:00 AM

### 9. 📰 Informe Matutino Unificado (L-V 9:00 AM)
- **Qué hace:** Reporte ÚNICO que lo incluye TODO:
  - ✅ Estado del sistema (actualizaciones, backup)
  - ✅ Seguridad (Fail2Ban)
  - ✅ Salud Garmin (pasos, HR, estrés, sueño)
  - ✅ Consumo (cuánto gastaste)
  - ✅ Tareas completadas
  - ✅ Lunes: auditorías profundas, Notion cleanup, consumo semanal
- **Para qué:** "Buenos días, aquí está tu resumen de todo"
- **Importancia:** ⭐⭐⭐ (Tu briefing diario)
- **Nota:** Va a Discord, no a Telegram

---

## 🛡️ SOLO LUNES - AUDITORÍAS PROFUNDAS

### 10. 🔐 Security Audit Weekly (Lunes 9:00 AM)
- **Qué hace:** Escaneo profundo de seguridad del sistema
  - Firewall status
  - Accesos SSH recientes
  - Puertos abiertos
  - Actualizaciones críticas pendientes
- **Para qué:** Detectar vulnerabilidades, asegurar que todo esté harcodeado
- **Importancia:** ⭐⭐⭐ (Seguridad)

### 11. 📊 Lynis Scan Weekly (Lunes 9:00 AM)
- **Qué hace:** Scan de hardening del sistema (herramienta Lynis)
- **Para qué:** Medir índice de seguridad (0-100), comparar con semana anterior
- **Importancia:** ⭐⭐⭐ (Seguridad)
- **Nota:** Alerta si hardening baja >5 puntos o aparecen nuevos warnings

### 12. 🛡️ rkhunter Scan Weekly (Lunes 9:00 AM)
- **Qué hace:** Escanea malware, rootkits, binarios modificados
- **Para qué:** Verificar que nada malicioso se instaló
- **Importancia:** ⭐⭐⭐ (Seguridad)
- **Nota:** ALERTA CRÍTICA si detecta rootkits

### 13. 📦 WAL Archive to COLD (Lunes 6:15 AM)
- **Qué hace:** Archiva snapshots viejos a carpeta COLD comprimida
- **Para qué:** Liberar espacio en HOT (pasaría de 150M a 20M)
- **Importancia:** ⭐⭐⭐ (Storage)
- **Nota:** Solo corre lunes (después de eso podría ser diario - PHASE 2)

### 14. ✅ WAL Validation (Lunes 6:00 AM)
- **Qué hace:** Verifica que todos los WAL logs estén íntegros (SHA256)
- **Para qué:** Asegurar que backup está sano
- **Importancia:** ⭐⭐⭐ (Integridad)

### 15. 🗑️ Backup Retention Cleanup (Lunes 5:30 AM)
- **Qué hace:** Elimina backups >30 días desde Google Drive
- **Para qué:** Ahorrar espacio, mantener solo backups recientes
- **Importancia:** ⭐⭐ (Storage, costo Drive)

### 16. 🔍 Backup Validation Weekly (Lunes 5:30 AM)
- **Qué hace:** Valida que el backup de ayer sea válido (integridad, restoreable)
- **Para qué:** Asegurar que puedo recuperar desde ese backup si lo necesito
- **Importancia:** ⭐⭐⭐ (Crítico para recuperación)

### 17. 📋 Notion Ideas Cleanup (Lunes 9:00 AM)
- **Qué hace:** Revisa tareas en "Ideas" del tablero Notion
  - Si alguna se completó esta semana, la mueve a "Hecho"
  - Añade comentario con fecha y dónde lo hizo (memory file)
- **Para qué:** Mantener Notion limpio, tracking de tareas completadas
- **Importancia:** ⭐⭐ (Organización)

### 18. 🔎 Tareas de Fondo Semanales (Lunes 9:00 AM)
- **Qué hace:** Ejecuta tareas marcadas como "Fondo" con frecuencia "Semanal"
  - Ejemplo: revisar si los precios de modelos IA cambiaron
  - Buscar novedades en internet sobre temas pendientes
- **Para qué:** Investigación recurrente, monitoreo de cambios externos
- **Importancia:** ⭐⭐ (Context updates)

### 19. 📊 Usage Report Weekly (Lunes 9:00 AM)
- **Qué hace:** Resumen de gasto de la última semana
  - Gráfico de consumo diario
  - Top 3 días más caros + razones
  - Distribución por modelo (%)
  - Tendencias (↗️/↘️/→)
  - Proyección fin de mes
- **Para qué:** Análisis de gastos, detección de anomalías
- **Importancia:** ⭐⭐ (Presupuesto)

---

## 🕐 TARDE (Recurrente)

### 20. 💓 Garmin Health Alerts (14:00 + 20:00 - Diario)
- **Cuándo:** 2:00 PM y 8:00 PM todos los días
- **Qué hace:** Revisa tu reloj Garmin
  - HR muy alto/bajo
  - Estrés crítico
  - Poco sueño predicho
- **Para qué:** Alerta de salud en tiempo real
- **Importancia:** ⭐⭐⭐ (Salud)
- **Nota:** Solo alerta condiciones realmente preocupantes

---

## 🌙 DOMINGO NOCHE

### 21. 🧹 Cleanup Audit Semanal (Domingo 22:00)
- **Qué hace:** Auditoria de limpieza
  - Archivos temporales obsoletos
  - Instaladores viejos (.deb, .AppImage)
  - Procesos innecesarios
  - Caché (excepto Whisper)
- **Para qué:** Identificar basura del sistema
- **Importancia:** ⭐⭐ (Storage, limpiar)
- **Nota:** NO borra nada, solo reporta hallazgos

### 22. 📚 Memory Organization Review (Domingo 23:00)
- **Qué hace:** Revisa estructura de memory/
  - Si archivos >4KB, compacta dividiendo por tema
  - Busca duplicados
  - Actualiza INDEX.md
- **Para qué:** Mantener memory organizada
- **Importancia:** ⭐⭐ (Organización)
- **Nota:** A veces tarda mucho y timeout. Issue conocido.

### 23. 🧠 Memory Guardian Pro (Domingo 23:00)
- **Qué hace:** Auto-cleanup agresivo
  - Detecta bloat (archivos >500KB)
  - Limpia backups viejos (.backup-*)
  - Limpia temporales (.tmp)
  - Comprime archivos >30 días
  - Detecta duplicados (MD5)
- **Para qué:** Ahorrar espacio automáticamente
- **Importancia:** ⭐⭐⭐ (Storage)

### 24. 📚 Tier Rotation (Lunes 23:30)
- **Qué hace:** Rota archivos de memory entre tiers
  - HOT → WARM (>7 días)
  - WARM → COLD comprimido (>30 días)
- **Para qué:** Mantener HOT pequeño, COLD archivo
- **Importancia:** ⭐⭐ (Storage management)

---

## 🌅 FIN DE SEMANA - 10:00 AM

### 25. 📰 Informe Matutino Unificado (Sábado + Domingo 10:00 AM)
- **Qué hace:** Lo mismo que el informe L-V pero sin auditorías profundas
  - Sistema + backup + seguridad básica
  - Garmin + salud del día
- **Para qué:** Tu briefing de fin de semana
- **Importancia:** ⭐⭐ (Consistencia)
- **Nota:** Va a Discord

### 26. 💰 Usage Report Fin de Semana (Sábado + Domingo 10:10 AM)
- **Qué hace:** Resumen de consumo del día
- **Para qué:** Monitoreo de gastos
- **Importancia:** ⭐⭐

---

## 🚨 CRÍTICAS / CAMBIOS RECIENTES

### 27. 📸 WAL Snapshots + 🚨 Monitor (NUEVA - 2026-02-23)
**Histórico:** Hoy tuvimos una crisis de storage (86M → 184M en 1.5h). Implementé:
- Monitor cada 6h que alerta si HOT > 100M (warning) o > 150M (critical)
- Rollback a ciclo de 6h (es estable)
- Archival solo lunes 6:15 AM (provisional, puede cambiar a diario en PHASE 2)

---

## 📊 RESUMEN POR TIPO

| Tipo | Cantidad | Ejemplos |
|------|----------|----------|
| **Cada 6h** | 3 | Snapshots, Monitoring, Fail2Ban |
| **Diarias** | 4 | Backup, Logs, Usage reports |
| **L-V 9 AM cluster** | 3 | Informe, Fail2Ban morning, Usage daily |
| **Lunes auditorías** | 7 | Security, Lynis, rkhunter, Cleanup, etc. |
| **Tarde** | 1 | Garmin health alerts (2x día) |
| **Domingo noche** | 4 | Cleanup, Memory review, Guardian, Tier rotation |
| **Fin de semana** | 2 | Informe + Usage (10 AM) |
| **Backup cycle** | 1 | Validation (lunes) |

**TOTAL:** 28 tareas (no son "ejecuciones", son definiciones únicas que corren recurrentemente)

---

## ✅ ESTADO ACTUAL

| Tarea | Estado | Última ejecución | Notas |
|-------|--------|------------------|-------|
| Snapshots | ✅ OK | 2026-02-23 07:33 | Ciclo 6h |
| Monitor | ✅ OK (new) | 2026-02-23 08:30 | WARNING (146M) |
| Fail2Ban | ✅ OK | 2026-02-23 06:00 | 3 IPs baneadas (normal) |
| Backup | ✅ OK | 2026-02-23 04:00 | ~37MB a Drive |
| Informe | ✅ OK | 2026-02-20 09:00 | Próximo: lunes 9 AM |
| Auditorías | ⏳ Pending | 2026-02-20 | Próximas: lunes 9 AM |
| Garmin | ✅ OK | 2026-02-23 20:00 | Activo |
| Sunday cleanup | ✅ OK | 2026-02-23 22:00 | Última ejecución exitosa |

---

## 🎯 PRÓXIMAS COSAS A PASAR

- **Hoy (Feb 23) 14:30:** Monitor WAL (chequeo cada 6h)
- **Hoy 20:00:** Garmin health alerts
- **Mañana 02:00:** WAL log rotation
- **Mañana 04:00:** Backup a Drive
- **Lunes (Mar 2) 05:30:** Backup cleanup + validation
- **Lunes 06:00:** WAL validation
- **Lunes 06:15:** WAL archive to COLD
- **Lunes 09:00:** TODAS las auditorías + informe matutino

---

¿Preguntas sobre alguna tarea? ¿Quieres cambiar horario de alguna?
