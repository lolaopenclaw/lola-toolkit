# 📋 TAREAS AUTOMATIZADAS — Listado Completo

**Última actualización:** 2026-02-27 17:15 | **Total:** 17 tareas (EXA AI News eliminado)

---

## 🔄 CADA 6 HORAS (Monitoreo Continuo)

### 1. ⚠️ Fail2Ban Monitoring (cada 6h)
- **Cuándo:** Cada 6 horas
- **Qué hace:** Revisa intentos fallidos de acceso SSH, IPs baneadas
- **Para qué:** Detectar ataques o brute-force temprano
- **Importancia:** ⭐⭐⭐ (Seguridad)
- **Nota:** Respeta horario silencioso (00:00-07:00)

---

## 📅 DIARIOS (TODOS LOS DÍAS)

### 2. 💾 Backup diario a Google Drive (4:00 AM)
- **Cuándo:** Todos los días 4:00 AM
- **Qué hace:** Copia todo el workspace a Drive (openclaw_backups/)
- **Para qué:** Recuperar desde cualquier máquina si esta explota
- **Importancia:** ⭐⭐⭐ (Crítico)
- **Retención:** 30 días

### 3. 📋 Informe Matutino Completo (10:00 AM) ✅ CONSOLIDADO
- **Cuándo:** TODOS LOS DÍAS 10:00 AM (consolidado de L-V 9 AM + S-D 10 AM)
- **Qué hace:** Informe unificado sin repeticiones:
  1. **Estado del Sistema** — Uptime, CPU, RAM, disco
  2. **Seguridad (Fail2Ban)** — IPs baneadas últimas 24h
  3. **Consumo de APIs** — Uso Anthropic, costos
  4. **Salud (Garmin)** — HR, estrés, sueño, alertas
  5. **Tareas Pendientes** — Notion (si hay bloqueadas)
- **Destino:** Telegram
- **Modelo:** Haiku
- **Cambio:** Consolidó 3 tareas anteriores (Informe L-V, Informe S-D, Fail2Ban Report, Usage Report)

### 4. 📊 Populate Google Sheets (9:30 AM)
- **Cuándo:** TODOS LOS DÍAS 9:30 AM (antes solo L-V)
- **Qué hace:** Rellena Sheets con datos de consumo IA + Garmin
- **Para qué:** Dashboard visual en Google Sheets
- **Modelo:** Haiku

### 5. 💓 Garmin Alertas de Salud (14:00 y 20:00)
- **Cuándo:** Todos los días 14:00 y 20:00
- **Qué hace:** Verifica alertas de salud Garmin
- **Para qué:** Detectar HR elevado, estrés alto, sueño malo
- **Nota:** Solo alerta si hay problema real (HEARTBEAT_OK si OK)

---

## 📅 LUNES (Auditorías Semanales)

### 6. 🗑️ Backup Retention Cleanup (5:30 AM)
- **Cuándo:** Lunes 5:30 AM
- **Qué hace:** Elimina backups >30 días en Drive
- **Para qué:** Mantener Drive limpio

### 7. ✅ Backup Validation Weekly (5:30 AM)
- **Cuándo:** Lunes 5:30 AM
- **Qué hace:** Valida integridad de backups en Drive
- **Para qué:** Confirmar que backups son restaurables

### 8. 🔒 Security Audit Weekly (9:00 AM)
- **Cuándo:** Lunes 9:00 AM
- **Qué hace:** Auditoría profunda: firewall, SSH, puertos, accesos
- **Modelo:** Haiku

### 9. 📊 Lynis Scan Weekly (9:00 AM)
- **Cuándo:** Lunes 9:00 AM
- **Qué hace:** Scan Lynis del sistema
- **Para qué:** Detectar cambios en hardening index

### 10. 🛡️ rkhunter Scan Weekly (9:00 AM)
- **Cuándo:** Lunes 9:00 AM
- **Qué hace:** Scan de malware/rootkits
- **Para qué:** Detectar binarios modificados o rootkits

### 11. 📋 Notion Ideas Cleanup (9:00 AM)
- **Cuándo:** Lunes 9:00 AM
- **Qué hace:** Revisa Ideas completadas y las mueve a Hecho
- **Para qué:** Mantener tablero Kanban limpio

### 12. 📊 Usage Report Weekly (9:00 AM)
- **Cuándo:** Lunes 9:00 AM
- **Qué hace:** Resumen semanal de consumo con tendencias
- **Modelo:** Haiku

### 13. 🔄 Tareas de Fondo Semanales (9:00 AM)
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

### 14. 🧹 Cleanup Audit (22:00)
- **Cuándo:** Domingo 22:00
- **Qué hace:** Auditoría de archivos temporales, caché, procesos
- **Nota:** NO borra nada, solo reporta hallazgos

### 15. 📚 Memory Organization Review (23:00)
- **Cuándo:** Domingo 23:00
- **Qué hace:** Revisa estructura de memory/, compacta si necesario
- **Timeout:** 600s
- **Modelo:** Haiku

### 16. 🧠 Memory Guardian Pro (23:00)
- **Cuándo:** Domingo 23:00
- **Qué hace:** Limpia backups viejos, temporales, detecta duplicados
- **Modelo:** Haiku

---

## 📅 LUNES NOCHE

### 17. 📚 Tier Rotation (23:30)
- **Cuándo:** Lunes 23:30
- **Qué hace:** Mueve archivos HOT→WARM (>7d) y WARM→COLD (>30d)
- **Modelo:** Haiku

---

## 📊 Resumen

| Frecuencia | Tareas | Descripción |
|-----------|--------|-------------|
| **Cada 6h** | 1 | Fail2Ban monitoring |
| **Diarias (todos)** | 4 | Backup (4 AM) + Informe (10 AM) + Sheets (9:30 AM) + Garmin alerts (14/20h) |
| **Lunes AM** | 8 | Backup cleanup + validation + 6 auditorías semanales |
| **Domingo noche** | 3 | Cleanup + memory maintenance |
| **Lunes noche** | 1 | Tier rotation |

**TOTAL:** 17 tareas recurrentes (EXA AI News eliminado)

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

*Última revisión: 2026-02-27 17:15 (eliminado: EXA AI News)*
