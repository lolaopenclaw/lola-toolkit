# Control de Gastos — Sesión 2026-03-03

## Resumen
- Implementado sistema completo de control de gastos para Manu
- Datos: 12 CSV vencimientos + CaixaBank XLS (420 movs) + Bankinter XLSX (29 movs)

## Archivos creados
- `/home/mleon/finanzas/config.yaml` — configuración categorías, alertas, cuentas
- `/home/mleon/finanzas/parser.py` — parser CaixaBank (XLS) + Bankinter (XLSX) + vencimientos (CSV)
- `/home/mleon/finanzas/report.py` — informes mensuales con comparativa vs presupuesto
- `/home/mleon/finanzas/data/movimientos.json` — 449 movimientos parseados
- `/home/mleon/finanzas/data/sheets_config.json` — config Google Sheets

## Google Sheets
- **ID:** `1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA`
- **URL:** https://docs.google.com/spreadsheets/d/1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA/edit
- Compartida con manuelleonmendiola@gmail.com (writer)
- Contenido: Resumen mensual (A-F) + Categorías (A10+) + Movimientos detallados (I-O)

## Categorización
- 449 movimientos → 447 categorizados (99.6%)
- 2 sin categorizar: LOGROÑO SUC 2 (-12€), C.O. LOGROÑO (-11€)
- 18 categorías: nomina, prestamos, hogar, supermercado, restauracion, transporte, compras_online, ocio_cultura, salud, ropa_personal, bizum, telecom, suscripciones, financiacion, impuestos_tasas, ingresos_extra, mantenimiento_hogar, transferencias_internas

## Info financiera clave
- **CaixaBank:** ES44 2100 5585 (cuenta principal), saldo 823€
- **Bankinter:** ES04 0128 7820 (nómina Arsys + préstamos), saldo 3.780€
- **Total en cuentas:** ~4.603€
- **Préstamo hermano:** Bankinter 510326524 (-125,98€/mes)
- **ONEY + COFIDIS:** financiaciones pasadas, se acaban
- **Patreon @athosirart:** ~8€/mes vía PayPal (USD variable)
- **Spotify:** 20,99€/mes vía PayPal

## Pendiente (feedback Manu)
- Bizums: CaixaBank no da nombres de personas → Manu identificará recurrentes
- Revisar categorización general en Sheets
- Posible cron mensual para recordar subir extractos
- Exportar a pestaña separada (limitación gog: no crea tabs)

## Decisiones
- Transferencias entre cuentas = internas, ignorar en balance
- PayPal EUROPE genéricos sin importe conocido = compras_online
- Los ~64,66€/mes de PayPal = financiación terminada
