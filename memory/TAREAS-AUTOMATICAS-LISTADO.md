# 📋 TAREAS AUTOMATIZADAS — Listado Completo

**Última actualización:** 2026-02-27 | **Total:** 21 tareas (EXA Startup eliminado)

---

## 🔄 CADA 6 HORAS (Monitoreo Continuo)

### 1. ⚠️ Fail2Ban Monitoring (cada 6h)
- **Cuándo:** Cada 6 horas
- **Qué hace:** Revisa intentos fallidos de acceso SSH, IPs baneadas
- **Para qué:** Detectar ataques o brute-force temprano
- **Importancia:** ⭐⭐⭐ (Seguridad)
- **Nota:** Respeta horario silencioso (00:00-07:00)

---

## 📅 DIARIOS (L-V)

### 2. 💾 Backup diario a Google Drive (4:00 AM)
- **Cuándo:** Todos los días 4:00 AM
- **Qué hace:** Copia todo el workspace a Drive (openclaw_backups/)
- **Para qué:** Recuperar desde cualquier máquina si esta explota
- **Importancia:** ⭐⭐⭐ (Crítico)
- **Retención:** 30 días

### 3. 📋 Informe matutino unificado (9:00 AM L-V)
- **Cuándo:** Lunes-Viernes 9:00 AM
- **Qué hace:** Reporte unificado: sistema, seguridad, salud Garmin, tareas
- **Para qué:** Resumen diario de todo lo importante
- **Destino:** Discord (no Telegram)
- **Modelo:** Haiku

### 4. ⚠️ Fail2Ban Morning Report (9:00 AM L-V)
- **Cuándo:** Lunes-Viernes 9:00 AM
- **Qué hace:** Resumen de actividad Fail2Ban últimas 24h
- **Para qué:** Detectar patrones de ataque
- **Modelo:** Haiku

### 5. 💰 Usage Report Daily (9:10 AM L-V)
- **Cuándo:** Lunes-Viernes 9:10 AM
- **Qué hace:** Resumen de consumo diario de APIs
- **Para qué:** Monitorear costos
- **Modelo:** Haiku

### 6. 📊 Populate Google Sheets (9:30 AM L-V)
- **Cuándo:** Lunes-Viernes 9:30 AM
- **Qué hace:** Rellena Sheets con datos de consumo IA + Garmin
- **Para qué:** Dashboard visual en Google Sheets
- **Modelo:** Haiku

### 7. 💓 Garmin Alertas de Salud (14:00 y 20:00)
- **Cuándo:** Todos los días 14:00 y 20:00
- **Qué hace:** Verifica alertas de salud Garmin
- **Para qué:** Detectar HR elevado, estrés alto, sueño malo
- **Nota:** Solo alerta si hay problema real (HEARTBEAT_OK si OK)

---

## 📅 DIARIOS (FIN DE SEMANA)

### 8. 📋 Informe matutino (10:00 AM S-D)
- **Cuándo:** Sábado-Domingo 10:00 AM
- **Qué hace:** Versión ligera del informe matutino
- **Destino:** Discord
- **Modelo:** Haiku

### 9. 💰 Usage Report (10:10 AM S-D)
- **Cuándo:** Sábado-Domingo 10:10 AM
- **Qué hace:** Informe consumo fin de semana
- **Modelo:** Haiku

---

## 📅 LUNES (Auditorías Semanales)

### 10. 🗑️ Backup Retention Cleanup (5:30 AM)
- **Cuándo:** Lunes 5:30 AM
- **Qué hace:** Elimina backups >30 días en Drive
- **Para qué:** Mantener Drive limpio

### 11. ✅ Backup Validation Weekly (5:30 AM)
- **Cuándo:** Lunes 5:30 AM
- **Qué hace:** Valida integridad de backups en Drive
- **Para qué:** Confirmar que backups son restaurables

### 12. 📰 EXA: AI News (8:00 AM)
- **Cuándo:** Lunes 8:00 AM
- **Qué hace:** Busca noticias IA de la semana
- **Destino:** Telegram

### 13. 🔒 Security Audit Weekly (9:00 AM)
- **Cuándo:** Lunes 9:00 AM
- **Qué hace:** Auditoría profunda: firewall, SSH, puertos, accesos
- **Modelo:** Haiku

### 14. 📊 Lynis Scan Weekly (9:00 AM)
- **Cuándo:** Lunes 9:00 AM
- **Qué hace:** Scan Lynis del sistema
- **Para qué:** Detectar cambios en hardening index

### 15. 🛡️ rkhunter Scan Weekly (9:00 AM)
- **Cuándo:** Lunes 9:00 AM
- **Qué hace:** Scan de malware/rootkits
- **Para qué:** Detectar binarios modificados o rootkits

### 16. 📋 Notion Ideas Cleanup (9:00 AM)
- **Cuándo:** Lunes 9:00 AM
- **Qué hace:** Revisa Ideas completadas y las mueve a Hecho
- **Para qué:** Mantener tablero Kanban limpio

### 17. 📊 Usage Report Weekly (9:00 AM)
- **Cuándo:** Lunes 9:00 AM
- **Qué hace:** Resumen semanal de consumo con tendencias
- **Modelo:** Haiku

### 18. 🔄 Tareas de Fondo Semanales (9:00 AM)
- **Cuándo:** Lunes 9:00 AM
- **Qué hace:** Revisa tareas de Notion en estado "Fondo"
- **Modelo:** Haiku

---

## 📅 VIERNES

### 19. 🚀 EXA: Startup Trends (17:00) ~~ELIMINADO 27/02~~
- **Estado:** ❌ Eliminado (27 febrero 17:00 - No interesaba)
- ~~**Cuándo:** Viernes 17:00~~
- ~~**Qué hace:** Busca tendencias de startups/funding~~
- ~~**Destino:** Telegram~~

---

## 📅 DOMINGO NOCHE (Mantenimiento)

### 20. 🧹 Cleanup Audit (22:00)
- **Cuándo:** Domingo 22:00
- **Qué hace:** Auditoría de archivos temporales, caché, procesos
- **Nota:** NO borra nada, solo reporta hallazgos

### 21. 📚 Memory Organization Review (23:00)
- **Cuándo:** Domingo 23:00
- **Qué hace:** Revisa estructura de memory/, compacta si necesario
- **Timeout:** 600s
- **Modelo:** Haiku

### 22. 🧠 Memory Guardian Pro (23:00)
- **Cuándo:** Domingo 23:00
- **Qué hace:** Limpia backups viejos, temporales, detecta duplicados
- **Modelo:** Haiku

---

## 📅 LUNES NOCHE

### 23. 📚 Tier Rotation (23:30)
- **Cuándo:** Lunes 23:30
- **Qué hace:** Mueve archivos HOT→WARM (>7d) y WARM→COLD (>30d)
- **Modelo:** Haiku

---

## 📊 Resumen

| Frecuencia | Tareas | Descripción |
|-----------|--------|-------------|
| **Cada 6h** | 1 | Fail2Ban monitoring |
| **Diarias (L-V)** | 5 | Backup, informe, fail2ban, usage, sheets |
| **Diarias (S-D)** | 2 | Informe + usage |
| **Diarias (todos)** | 2 | Backup Drive + Garmin alerts |
| **Lunes AM** | 7 | Auditorías semanales |
| **Viernes** | — | ~~Startup trends~~ (eliminado) |
| **Domingo noche** | 3 | Cleanup + memory maintenance |
| **Lunes noche** | 1 | Tier rotation |

**TOTAL:** 21 tareas recurrentes

---

## ✅ Backup Strategy (Simplificada)

```
Workspace (~768KB markdown)
    ↓
Backup diario a Drive (4:00 AM, rclone)
    ↓
Retención: 30 días en Drive
    ↓
Recuperación: restore.sh desde backup descargado
```

**Sin snapshots.** WAL se probó (21-23 feb) y se descartó: overkill para ~1MB de markdown.

---

*Última revisión: 2026-02-24 (limpieza WAL)*
