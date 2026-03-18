# Finanzas Personal — Summary

**Status:** Active  
**Goal:** Track personal expenses, auto-categorize, visualize spending patterns  
**Owner:** Manu  
**Started:** 2026-01-15  
**Deadline:** Ongoing  
**Last updated:** 2026-03-18

## Current State

- **Data:** 418 movements tracked (CaixaBank: 64, Bankinter: 6)
- **Bank coverage:** CaixaBank through 2026-03-17, Bankinter through 2026-03-03
- **Categories:** 15+ (Supermercado, Transporte, Bares, Ocio, etc.)
- **Bizum contacts:** 16 tracked
- **March 2026:** +415.02€ ingresos, -2391.20€ gastos, -1976.18€ balance

## Recent Work

1. **OAuth2 setup** (2026-03-18) — Google Sheets API configured, token persistence via pickle
2. **Data import** — CSV parser + deduplication by (fecha, importe, cuenta)
3. **Google Sheets** — Movimientos sheet (70 rows, marzo), Comparativa Mensual working
4. **Dashboard attempt** — Failed due to date format mismatch (active/resolved)

## Blocking Issues

- **Interactive dashboard** — Google Sheets date formula bugs (FILTER+REGEXMATCH). Workaround: use "Comparativa Mensual" sheet
- **Bankinter extract** — Only through 2026-03-03 (waiting for Manu to provide recent extract)
- **PayPal correlations** — Patreon (-9.08$ USD) and AliExpress (-11.28€) not yet matched in CaixaBank

## Tech Stack

- **Repo:** github.com/lolaopenclaw/finanzas-personal (private)
- **Local:** ~/finanzas/
- **Data:** movimientos_detallado.json, bizum_contacts.json
- **Scripts:** parser_csv_detallado.py, update_sheet.py, telegram_report.py
- **Updates:** Every 15 days (when Manu provides bank extracts)

## Next Steps

1. Finish Bankinter + PayPal correlation
2. Add Revolut/Wise tracking (if used)
3. Monthly reports (automated)
4. Visualization dashboard (when time permits)

---

See `finanzas.json` for detailed tracking.
