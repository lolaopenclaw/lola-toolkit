# Proyecto: Organización Financiera Completa - Estado 4 Mar 2026

**Última actualización:** 4 mar 2026 11:53 AM
**Responsable:** Manu (Manuel León Mendiola)

---

## OBJETIVO

Crear un sistema financiero completo (hoja de cálculo) que categorice y analice todos los movimientos de:
- CaixaBank (cuenta principal)
- Bankinter (cuenta de ahorro)
- PayPal (transacciones en línea)

Período: **01/12/2025 - 03/03/2026** (dic 2025 - mar 2026)

---

## DATOS RECOPILADOS ✅

### 1. PayPal (COMPLETO)
- **Archivo:** `paypal-transactions-90days.md`
- **Período:** Dic 2025 - Mar 2026 (26 transacciones)
- **Estado:** ✅ Listo, categorizado

### 2. CaixaBank (PARCIAL)
- **Archivo:** EXTRAÍDO PERO INCOMPLETO
- **Qué tenemos:** Resumen (fecha, importe, saldo final)
- **Qué falta:** DETALLE DETALLADO (3 últimos meses)
- **Estado:** ⏳ PENDIENTE: Esperar detallado de Manu

### 3. Bankinter (COMPLETO)
- **Archivo:** `Movimientos_3_3_2026_1...csv`
- **Período:** 01/12/2025 - 03/03/2026
- **Contenido:** Nóminas, préstamos, transferencias, intereses
- **Estado:** ✅ Listo para usar

---

## CRITERIOS DE CATEGORIZACIÓN ✅

**Guardado en:** `finances-criteria-2026-03-04.md`

### Ingresos
- **Bizums 20€/principios mes:** Compañeros local ensayo (ingreso recurrente)
- **Nómina:** Dividida CaixaBank + Bankinter, fin de mes (+ pagos adicionales beneficios)

### Gastos Especiales
- **Préstamo 510326524 (-125,98€/mes):** Hermano (deuda personal)
- **ONEY SERV.FIN. (-111€/mes):** Financiación antigua (completada)
- **COFIDIS AMAZON (-76€/mes):** Compra financiada (completada)

### Ignorar (Movimientos Internos)
- **Transfers entre CaixaBank ↔ Bankinter:** Ajustes fin de mes
- ❌ NO contar como gastos

### Confirmar
- ONEY SERV.FIN. = tarjeta gasolina
- SEVIAM PLUS, PACK MULTISEGUROS, VIDACAIXA = seguros
- KIKOS = supermercado

---

## PRÓXIMOS PASOS

### COMPLETADO ✅ (4 mar 2026 12:55)
1. **CSV detallado CaixaBank recibido** — 355 movimientos (dic 2025 - mar 2026)
2. **Parser nuevo creado:** `/home/mleon/finanzas/parser_csv_detallado.py`
3. **Google Sheet actualizada** con:
   - Resumen mensual (CaixaBank + Bankinter)
   - Categorías con totales
   - 350 movimientos detallados
   - 19 contactos Bizum con nombres y motivos
   - Gastos fijos mensuales

### PENDIENTE 🔄
1. **Cron semanal** — recordatorio lunes 9AM para que Manu suba CSV (gateway con conflicto de tokens, 2 procesos)
2. **Pulir extracción nombres Bizum** — algunos salen mal formateados
3. **Cruce PayPal ↔ CaixaBank** — ya tenemos el detalle, falta automatizar
4. **Mejorar trazabilidad Bizums** — ahora el CSV trae nombres completos (antes no)
5. **Nómina:** Arsys paga DIVIDIDO entre CaixaBank (~1.740€) y Bankinter (~937€), a FINALES del mes

---

## ARCHIVOS DE REFERENCIA

- `paypal-transactions-90days.md` — Transacciones PayPal ordenadas
- `paypal-caixabank-reconciliation.md` — Cruce inicial (incompleto, espera detallado)
- `finances-criteria-2026-03-04.md` — Criterios de categorización
- `finances-project-status.md` ← **Este archivo (actualizarlo si hay cambios)**

---

## NOTAS IMPORTANTES

- **No olvidar:** Ignorar transfers internas (CaixaBank ↔ Bankinter)
- **Préstamo:** 510326524 es deuda con hermano, categorizar separadamente
- **Nómina:** Busca en AMBAS cuentas (CaixaBank + Bankinter)
- **Session awareness:** Este archivo preserva contexto entre sesiones

