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

## 🖥️ Dashboards & URLs (2026-03-05)

### Acceso Remoto (desde casa vía Tailscale Serve — HTTPS)
```
🔐 OpenClaw Dashboard  → https://lola-openclaw-vps.taild8eaf6.ts.net
🦞 LobsterBoard        → https://ubuntu.taild8eaf6.ts.net:8443
🎬 VidClaw             → https://ubuntu.taild8eaf6.ts.net:8444
```

### Acceso Local (desde VPS)
```
localhost:18790 → OpenClaw Gateway (⚠️ puerto real, no 18789)
localhost:8080  → LobsterBoard
localhost:3333  → VidClaw
localhost:5001  → Custom API (backend widgets)
```

### ⚠️ Lección: NO tocar gateway.bind
OpenClaw usa `tailscale.mode=serve` + `gateway.bind=loopback`.
Tailscale Serve hace el proxy HTTPS automáticamente.
NUNCA cambiar bind a "tailnet" o "lan" — rompe la validación.

### Detalles de cada Dashboard

**LobsterBoard (8080)**
- Descripción: Dashboard builder con widgets custom
- Tecnología: Node.js server.cjs
- Status: ✅ Expuesto en 0.0.0.0
- Plugins: /home/mleon/lobsterboard/plugins/
  - finanzas.js → Google Sheets (ingresos/gastos/balance)
  - garmin.js → Garmin Health (HR, pasos, sueño)
  - calendar.js → Google Calendar (próximos eventos)
- API Backend: 5001 (api-custom.cjs, systemd service)

**VidClaw (3333)**
- Descripción: Dashboard de métricas/costes de Lola
- Tecnología: Node.js server.js (/home/mleon/vidclaw/)
- Status: ✅ Expuesto en 0.0.0.0

**OpenClaw Gateway (18789)**
- Descripción: Gateway central de OpenClaw (websocket, agentes)
- Tecnología: OpenClaw CLI gateway --port 18789 --bind tailnet
- Status: ✅ Accesible desde Tailscale (--bind tailnet aplicado 2026-03-05)
- Systemd: /home/mleon/.config/systemd/user/openclaw-gateway.service
- Auth: token-based

### Puertos Ocupados
- 22 → SSH
- 53 → DNS (systemd-resolved)
- 80, 443 → Libre (sin nginx/reverse proxy)
- 3333 → VidClaw
- 5001 → Custom API
- 5901 → VNC
- 8080 → LobsterBoard
- 8443, 8444 → Tailscale serve (proxy)
- 18789, 18791, 18792 → OpenClaw gateway/services

### Cambios Aplicados (5 marzo 2026)
1. LobsterBoard: 127.0.0.1 → 0.0.0.0 (Tailscale access)
2. Custom API: 127.0.0.1 → 0.0.0.0
3. VidClaw: 127.0.0.1 → 0.0.0.0
4. OpenClaw Gateway: --bind tailnet (Tailscale access)
5. Plugins: Hardcoded 127.0.0.1:5001 → window.location.hostname:5001 (dynamic)
