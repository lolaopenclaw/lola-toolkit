# Finanzas Personal — Summary

**Type:** project  
**Last synthesized:** 2026-03-29  
**Tiers:** 0 hot, 10 warm, 0 cold

## 🌡️ Warm (8-30 days)

- **[context]** Goal: Track personal expenses, auto-categorize, create visualizations. Repo: github.com/lolaopenclaw/finanzas-personal (private). Local: ~/finanzas/
- **[context]** Categories tracked: 15+ including Supermercado, Transporte, Bares y restaurantes, Ocio y cultura, Mantenimiento hogar, Ropa, etc.
- **[context]** Update cycle: Every 15 days (when Manu provides bank extracts from CaixaBank/Bankinter). Last major update: 2026-03-18 (63 new movements + 29 deduplicated)
- **[status]** Data as of 2026-03-18: 418 total movements. CaixaBank: 64 movements through 2026-03-17. Bankinter: 6 movements through 2026-03-03.
- **[status]** March 2026 summary: +415.02€ ingresos, -2391.20€ gastos, -1976.18€ balance (70 movements). Current balances: CaixaBank ~0.00€, Bankinter ~0.00€
- **[status]** Bizum contacts: 16 tracked (friends/family for money transfers). Updated 2026-03-18.
- **[context]** Tech stack: Google Sheets API (OAuth2 + refresh token). Local parsing: pandas, CSV reader. Data format: JSON (movimientos_detallado.json, bizum_contacts.json)
- **[status]** Blocking issue: Interactive dashboard in Google Sheets. Problem: date format mismatch (Movimientos uses serial numbers, dropdown needs YYYY-MM text). Status: Abandoned for now, using 'Comparativa Mensual' sheet instead.
- **[status]** Bankinter extract outdated. Only through 2026-03-03 (15+ days old). Waiting for Manu to provide recent extract covering 2026-03-04 onwards.
- **[status]** PayPal correlations pending: Patreon subscription (-9.08$ USD) and AliExpress purchase (-11.28€) appear in PayPal but not yet found in CaixaBank movements. Needs manual investigation or PayPal statement integration.

---

See `finanzas.json` for all 10 facts.