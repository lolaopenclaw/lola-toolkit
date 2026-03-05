# Plan: Finanzas + Dashboard + Calendar (2026-03-04)

**Última actualización:** 2026-03-04 21:24 CET

---

## ✅ COMPLETADO

### 1. Google Sheet de finanzas
- [x] Parser CSV CaixaBank → JSON detallado con categorías
- [x] Parser Bankinter (movimientos.json)
- [x] Nueva categoría: `cajero` (separada de transferencias_internas)
- [x] Pestañas de datos: Resumen, Resumen - Detalle, Movimientos, Contactos Bizum, Bizum
- [x] Resumen - Detalle: layout horizontal 4 bloques (A:E categorías, G:K fijos, M:Q detalle gastos, S:W detalle ingresos)
- [x] Categoría en cada fila de detalles (filtrable)
- [x] 4 gráficas nativas: Ingresos vs Gastos (barras), Gastos por Categoría (donut), Balance Mensual (línea), Evolución Saldo (línea 3 series: CX + BK + Total)
- [x] Formateo completo: headers coloreados por sección, €, condicionales verde/rojo, zebra, bordes, freeze
- [x] Pestaña Comparativa Mensual: categorías × meses + tendencias (📈📉➡️) + ingresos
- [x] Limpieza: borrada Hoja 1, renombrada Resumen Mensual → Resumen, limpiado Y:AC residual

### 2. Resumen por Telegram
- [x] Script `telegram_report.py`: balance, top 5 gastos, tendencias, cambios notables, saldos
- [x] Cron mensual configurado: `finanzas-resumen-mensual` — día 1 cada mes a 9:00 AM Madrid
- [x] Próxima ejecución: 1 abril 2026

### 3. Google Calendar integración
- [x] Script `calendar-tasks.sh`: check, add, add-important, add-recurring, list, today, tomorrow
- [x] Colores por tipo (blueberry=tarea, tomato=urgente, basil=recurrente)
- [x] Integrado en HEARTBEAT.md (check 9)
- [x] Calendario compartido con Manu (manuelleonmendiola@gmail.com, role=reader)
- [x] Tarea de prueba creada: "Instalar LobsterBoard" para 5 marzo

### 4. Documentación
- [x] `/home/mleon/finanzas/README.md` — guía completa del sistema de finanzas
- [x] MEMORY.md actualizado con referencia a finanzas, dashboard, calendar
- [x] Este plan creado

---

## 🔲 PENDIENTE — Requiere portátil/SSH

### 5. LobsterBoard (dashboard visual)
- [x] Instalar LobsterBoard en la VPS (`/home/mleon/lobsterboard`)
- [x] Servicio systemd: `lobsterboard.service` (enabled, auto-start)
- [x] Tailscale Serve: `https://ubuntu.taild8eaf6.ts.net:8443` → proxy 127.0.0.1:8080
- [x] Widgets estándar: CPU, memoria, disco, uptime, weather, clock, cron
- [x] Widgets OpenClaw: sessions, AI costs (today+month), tokens
- [x] Endpoints custom: `/api/sessions`, `/api/costs`, `/api/usage/tokens` (parsean JSONL logs)
- [ ] Widget custom: Finanzas (leer JSONs de /home/mleon/finanzas/data/)
- [ ] Widget custom: Garmin (HR, pasos, sueño, Body Battery)
- [ ] Widget: Calendar (tareas de lolaopenclaw)
- [ ] Widget: Emails no leídos
- [ ] Documentar en TOOLS.md
- **Acceso:** Tailscale only (móvil, portátil trabajo, portátil casa)

### 6. VidClaw (complementario)
- [x] Instalar VidClaw (`/home/mleon/vidclaw`)
- [x] Servicio systemd: `vidclaw.service` (enabled, auto-start, port 3333)
- [x] Tailscale Serve: `https://ubuntu.taild8eaf6.ts.net:8444`
- [ ] Evaluar si merece la pena vs solo LobsterBoard

---

## 🔲 PENDIENTE — Se puede hacer desde Telegram

### 7. Reducir reportes → solo alertas
- [ ] Revisar HEARTBEAT.md: quitar reportes rutinarios, dejar solo alertas
- [ ] Mover info repetitiva (Garmin, VPS status) a dashboard
- [ ] Informe matutino: simplificar a solo "hay X alertas + Y tareas calendar"
- [ ] Documentar nueva política de comunicación

### 8. Ideas de finanzas pendientes
- [ ] 🔔 Alertas de gasto: presupuesto por categoría, avisar cuando se pase
- [ ] 🔄 Automatizar actualización: detectar CSVs nuevos, parsear y subir
- [ ] 💰 Presupuesto vs Real: columna con objetivo por categoría y % desviación

---

## 📁 Archivos clave

| Archivo | Función |
|---------|---------|
| `/home/mleon/finanzas/update_sheet.py` | Sube datos a Google Sheet (6 pestañas) |
| `/home/mleon/finanzas/create_charts.py` | Crea 4 gráficas nativas |
| `/home/mleon/finanzas/format_sheet.py` | Aplica formateo a todas las pestañas |
| `/home/mleon/finanzas/telegram_report.py` | Genera informe mensual para Telegram |
| `/home/mleon/finanzas/parser_csv_detallado.py` | Parser CaixaBank CSV → JSON |
| `/home/mleon/finanzas/README.md` | Documentación completa |
| `~/.openclaw/workspace/scripts/calendar-tasks.sh` | Integración Google Calendar |
| `~/.openclaw/workspace/HEARTBEAT.md` | Heartbeat con check de calendar |

---

## 📝 Notas para futuro yo

- **Donut chart**: valores DEBEN ser positivos (no negativos)
- **gog CLI**: no tiene add-sheet ni share-calendar → usar google-api-python-client directamente
- **Token temporal**: `gog auth tokens export` → `/tmp/gog_token.json` → BORRAR siempre después
- **Sheet ID**: `1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA`
- **Calendar ID**: `lolaopenclaw@gmail.com`
- **Cron finanzas**: `finanzas-resumen-mensual` (ID: 95aee1f1-319e-4474-88a7-62160cb2eec8)
