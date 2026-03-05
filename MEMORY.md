# MEMORY.md — Index (Long-Term Memory)

**⚡ Nueva estructura modular (2026-02-23):** Contenido dividido por tema para evitar truncation de 20KB.

---

## 🔴 CORE - SIEMPRE NECESARIO
→ `memory/core.md` — Manu, infraestructura crítica, archivos clave

### Referencia rápida
- **Manu:** Manuel León Mendiola
- **Email:** manuelleonmendiola@gmail.com ⭐
- **Chat ID:** 6884477 (Telegram @RagnarBlackmade)
- **Timezone:** Europe/Madrid
- **VPS:** Ubuntu 6.8.0, OpenClaw 2026.2.22-2, puerto 18789
- **Horario silencioso:** 00:00-07:00 Madrid (NO enviar a Telegram)

---

## 🔧 TECHNICAL - Sistemas Internos
→ `memory/technical.md` — WAL, Memory Management, crons, Ubuntu Pro, lecciones aprendidas

**Ubuntu Pro:** ✅ Registrado (2026-02-26), ESM-Infra + ESM-Apps + Livepatch activos

**Crons activos:**
- 4:00 AM — Backup a Drive
- 9:00 AM — Informe matutino
- Lunes 6:00 AM — Auditoría seguridad
- Lunes 8:30 AM — Resumen Garmin

---

## 🔐 PROTOCOLS - Backup, Security, Cambios Críticos
→ `memory/protocols.md` — Recovery, security protocols, cambios críticos, Notion config

**⚠️ IMPORTANTE:** 
- SIEMPRE avisar ANTES de cambios en SSH/firewall/servicios
- Protocolo A+B: Backup → Baseline → Change → Validate → Rollback if needed

---

## 👤 Familia

### Vera Pérez León (Sobrina)
- 10 años, cumpleaños: 30 de agosto
- Cron configurado para avisar a Manu

---

**Nota:** Usar `memory_search` para consultas. Este archivo es ahora un índice ligero (~1.5KB).

## 💰 Finanzas - Google Sheet (2026-03-04)
- **Sheet:** `1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA`
- **Directorio:** `/home/mleon/finanzas/`
- **Docs completos:** `/home/mleon/finanzas/README.md`
- **Pestañas:** Resumen, Resumen - Detalle (4 bloques horizontales), Movimientos, Contactos Bizum, Bizum
- **Gráficas:** 4 charts nativos (barras, donut, línea balance, línea saldo)
- **Bancos:** CaixaBank (355 movs) + Bankinter (29 movs)
- **Periodo:** Dic 2025 - Mar 2026
- **Nota:** Donut necesita valores positivos. Charts requieren API directa (no gog CLI).

## 🖥️ Dashboard - Pendiente de instalar (2026-03-04)
- **Opción principal:** LobsterBoard (drag-and-drop, 50 widgets, OpenClaw integration)
- **Complementario:** VidClaw (gestión de Lola: SOUL editor, costes, skills)
- **Objetivo:** Reemplazar reportes periódicos por dashboard visual + solo alertas
- **Investigación completa:** `/home/mleon/finanzas/README.md` (ideas pendientes)
- **Instalar cuando:** Manu esté en portátil con SSH
- **Análisis detallado:** Sesión 2026-03-04

## 📅 Google Calendar - Integración tareas (2026-03-04)
- **Idea:** Usar Google Calendar de lolaopenclaw@gmail.com como sistema de tareas/recordatorios
- **Bidireccional:** Lola crea eventos/tareas + Manu las ve en su Calendar + heartbeats verifican pendientes
- **Herramienta:** gog CLI (ya configurado con calendar)
- **Estado:** En desarrollo

## 🎨 Dashboards Completados (2026-03-05)

### ✅ LobsterBoard
- **Path:** `/home/mleon/lobsterboard`
- **Status:** Instalado, funcional ✅
- **Puerto local:** 8080
- **Tailscale Serve:** `:8443` → `http://127.0.0.1:8080`
- **Acceso:** `https://ubuntu.taild8eaf6.ts.net:8443` (desde VPN)

### ✅ VidClaw
- **Path:** `/home/mleon/vidclaw`
- **Status:** Instalado, complementario
- **Puerto local:** 3333
- **Tailscale Serve:** `:8444` → `http://127.0.0.1:3333`

### ✅ Dashboard API Server
- **Path:** `/home/mleon/.openclaw/workspace/scripts/dashboard-api-server.js`
- **Puerto:** 5001
- **3 Endpoints funcionales:**
  1. `/api/finanzas` → Google Sheets (ingresos, gastos, balance)
  2. `/api/garmin` → Garmin Connect (HR, pasos, sueño, Body Battery)
  3. `/api/calendar` → Google Calendar (próximos eventos)
- **CORS:** Habilitado para requests desde localhost:8080

### ✅ 3 Widgets Custom para LobsterBoard
- **Archivo:** `/home/mleon/lobsterboard/js/widgets.js`
- **Tipo:** Plugins nativos (arrastrables, editables, fullscreen)
- **Configuración:** `/home/mleon/lobsterboard/config.json`

| Widget | Estado | Datos | Refresh |
|--------|--------|-------|---------|
| 💰 Finanzas | ✅ | Sheets | 1h |
| ❤️ Salud/Garmin | ✅ | Garmin | 5m |
| 📅 Próximos Eventos | ✅ | Calendar | 10m |

### 📋 Pendiente: Limpiar Reportes Periódicos
- **Crons a eliminar:** usage:report-daily, usage:report-weekly, recordatorio-csv-gastos, finanzas-resumen-mensual
- **Mantener:** healthchecks, backups, security audits, memory organization
- **Objetivo:** Solo alertas críticas, sin spam
- **Status:** Programado para próxima sesión
