# PayPal ↔ CaixaBank Reconciliation

**Período:** Diciembre 2024 - Agosto 2025
**Fecha generación:** 4 mar 2026 11:35 AM

---

## Resumen de Cargos PayPal en CaixaBank

### Cargos Identificados (Tarjeta de Crédito)

| Fecha | Descripción | Importe | PayPal Transaction | Categoría |
|-------|-------------|---------|-------------------|-----------|
| 28-12-2024 | PAYPAL *TICKETMAS | 14,97 € | Eventos (Eventim) | Eventos |
| 02-01-2025 | PAYPAL *LEROYMERL | 14,98 € | Compras (Leroy Merlin) | Compras |
| 07-02-2025 | PAYPAL *DNDBEYOND | 31,39 € | Suscripción (D&D Beyond) | Suscripciones |
| 02-03-2025 | PAYPAL (TRANSFER) | 1,70 € | ? (Pequeña transacción) | Pendiente |
| 13-02-2025 | PAYPAL *ROWENTA E | 57,60 € | Electrodomésticos | Compras |
| 18-04-2025 | Etsy.com*NaluNalu | 19,03 € | Compras Etsy | Compras |
| 21-04-2025 | PAYPAL *BANDAAPAR | 14,31 € | ? (Band something) | Eventos/Compras |
| 16-07-2025 | PAYPAL *JUEGOSDEM | 29,95 € | Juegos/Gaming | Compras |
| 16-07-2025 | PAYPAL *LEROYMERL | 137,08 € | Compras (Leroy Merlin) | Compras |
| 27-06-2025 | PAYPAL *DEPORVILL | 91,35 € | Deportes/Equipo | Compras |
| 29-06-2025 | PAYPAL *STEAM GAM | 5,79 € | Videojuegos (Steam) | Compras |
| 05-05-2025 | PAYPAL *SHEIN COM | 40,53 € | Ropa (Shein) | Compras |
| 22-05-2025 | PAYPAL *SHEIN COM | 18,27 € | Ropa (Shein) | Compras |
| 13-06-2025 | PAYPAL *SURFLAB | 100,00 € | Equipo Surf | Compras |
| 21-01-2025 | PAYPAL *TEMU | 13,27 € | Compras (Temu) | Compras |
| 11-05-2025 | PAYPAL *TEMU | 13,27 € | Compras (Temu) | Compras |

---

## CORE PAYPAL → CAIXABANK

**Cargas directas desde CaixaBank (no tarjeta):**

| Fecha | Descripción | Importe | Tipo |
|-------|-------------|---------|------|
| 02-02-2025 | PayPal Europe S.a.r.l. | 1,90 € | SEPA |
| 08-02-2025 | PayPal Europe S.a.r.l. (×4) | 6,05 € + 17,99 € + 20,44 € + 34,66 € | SEPA |
| 10-02-2025 | PayPal Europe S.a.r.l. | 10,08 € | SEPA |
| 17-02-2025 | PayPal Europe S.a.r.l. | 11,46 € | SEPA |
| 22-02-2025 | PayPal Europe S.a.r.l. | 11,77 € | SEPA |
| 28-02-2025 | PayPal Europe S.a.r.l. (×2) | 6,05 € + 17,99 € | SEPA |
| 04-03-2025 | PayPal Europe S.a.r.l. | 1,90 € | SEPA |
| 06-03-2025 | PayPal Europe S.a.r.l. | 17,99 € | SEPA |
| 19-03-2025 | PayPal Europe S.a.r.l. | 234,17 € | **GRAN TRANSFERENCIA** |
| 26-03-2025 | PayPal Europe S.a.r.l. | 10,29 € | SEPA |
| 28-03-2025 | PayPal Europe S.a.r.l. | 1,29 € | SEPA |

---

## Análisis de Movimientos

### Patrón Detectado

✅ **Tarjeta de Crédito (TCR TARJETA CREDITO):**
- PayPal actúa como intermediario
- Cargos específicos a: SHEIN, TEMU, STEAM, ROWENTA, LEROY MERLIN, etc.
- Manu paga la tarjeta → CaixaBank cobra → aparece como PAYPAL

⚠️ **Transferencias Directas (SEPA):**
- Transferencias regulares de PayPal a CaixaBank
- Importe grande el 19-03-2025: **234,17 €** (probablemente retiro de saldo)
- Pequeñas transferencias: probablemente liquidaciones de ventas o devoluciones

---

## Recomendación

**Para tu hoja de cálculo:**
1. Los cargos **PayPal en tarjeta** cuentan como gasto normal (categoría específica)
2. Las **transferencias SEPA** podrían ser:
   - **Ingresos**: Si son ventas desde PayPal
   - **Transferencia**: Si son retiros de tu saldo a CaixaBank

¿Necesitas que profundice en algo específico o que organice esto diferente?

