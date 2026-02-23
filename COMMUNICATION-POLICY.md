# 💬 Communication Policy (2026-02-23 — Implemented)

**Decisión:** Reducir ruido a Telegram. Solo alertas críticas.

---

## 🟢 TELEGRAM = PROBLEMAS SOLAMENTE

### Enviamos a Telegram SI:
- ❌ **Fail2Ban:** ≥10 IPs baneadas (actividad ataque)
- ❌ **Backup:** Fallo en ejecución
- ❌ **Consumo:** > $100 USD en un día
- ❌ **Seguridad:** Vulnerabilidad crítica sin parchear
- ❌ **Memory:** > 250MB
- ❌ **Cron:** Error (≥2 fallos consecutivos)
- ❌ **WAL:** Corrupción detectada
- ❌ **Sistema:** Caído o inaccesible

### NO enviamos a Telegram SI:
- ✅ "Status OK" (heartbeat, status check)
- ✅ "Fail2Ban: 2 IPs" (normal, bajo control)
- ✅ "Consumo: $4.21" (dentro presupuesto)
- ✅ "Memory: 184M" (normal, WAL es recovery)
- ✅ "Cron jobs: 28 OK, 0 errores" (nominal)
- ✅ Cualquier reporte positivo/nominal

---

## 📊 DISCORD = INFORME MATUTINO COMPLETO

**Cuándo:** Lunes-Viernes 9:00 AM, Sábado-Domingo 10:00 AM

**Qué incluye:**
- Sistema (estado, actualizaciones, backup)
- Seguridad (Fail2Ban, auditorías, Lynis, rkhunter)
- Salud (Garmin, actividad, sueño)
- Consumo (diario + semanal)
- Tareas (Notion, ideas completadas)
- Lunes: Auditorías profundas + cleanup + semanal

**Formato:**
- Sin tablas (bullets + emojis)
- Conciso pero completo
- Una vez al día = contexto total

---

## 📱 HEARTBEATS & INTERNAL CHECKS

**Ejecución:** Cada 30 minutos (4:00 AM, 10:30 AM, 3:30 PM, etc.)

**Qué revisa:**
- Estado crons (errores)
- Fail2Ban (IPs baneadas)
- Memory (tamaño)
- Backup (último status)
- WAL (integridad)
- Critical sandbox

**Notificación Telegram:**
- ✅ TODO OK → SILENCIO (`HEARTBEAT_OK`)
- ❌ PROBLEMA → Alerta inmediata

---

## 🚨 CRITICAL ALERTS (Exceptions)

Incluso si es de noche/madrugada, alertar a Telegram:
- Fail2Ban: ≥10 IPs (ataque en progreso)
- Backup: Fallo crítico (sin recovery)
- Security: Rootkit detectado
- System: Caído/inaccesible
- WAL: Corrupción irreversible

---

## 📈 Resultado Esperado

**Antes:** Telegram ruidoso (20+ mensajes/día "status OK")
**Después:** Telegram limpio (0-2 mensajes/día, solo alertas reales)

**Discord:** Tu briefing matutino diario (contexto completo, una vez)

---

## 🔄 Implementación

| Job | Cambio | Efecto |
|-----|--------|--------|
| Heartbeat 8:30 AM | Silencio si OK | -1 msg/día |
| Heartbeat 9:00 AM | Silencio si OK | -1 msg/día |
| Heartbeat 9:30 AM | Silencio si OK | -1 msg/día |
| Fail2Ban diario | Consolidado en Discord | -1 msg/día |
| Consumo diario | Consolidado en Discord | -1 msg/día |
| Garmin daily | Consolidado en Discord | -1 msg/día |
| **Total** | | **-6 msgs/día** |

**Telegram ahora = alerta, no status.**

---

**Fecha:** 2026-02-23 09:30 Madrid
**Propuesto por:** Manu
**Aprobado:** Sí ✅
**Estado:** ACTIVO
