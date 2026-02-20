# Sesión 5: Informes de Consumo Automatizados

## Sistema de reporting de consumo implementado
**Solicitado por:** Manu (quiere trazabilidad completa de tokens/requests)

### Informes configurados
1. ✅ **Diario** (23:55 Madrid) - `usage:report-daily`
   - Analiza consumo del día
   - Alerta si >$50 USD
   - Genera memory/YYYY-MM-DD-usage-report.md
   - Contexto de qué se hizo (extrae de memory/)

2. ✅ **Semanal** (lunes 8:00 Madrid) - `usage:report-weekly`
   - Resumen 7 días
   - Tendencias y comparativas
   - Top días más caros + razones
   - Proyección mensual actualizada

### Primer informe generado
- memory/2026-02-20-usage-report.md (6.7KB)
- Hoy: $48.90 (Sonnet 95.9%, Opus 3.9%)
- Ayer: $221.71 (Opus 86.9% - día intensivo Notion)
- Mes: $398.98 (20 días, proyección $500-650)

### Roadmap de enriquecimientos
Documentado en memory/usage-reports-roadmap.md:
- **Fase 2 (próximas 2 semanas):** Gráficos ASCII, comparativas
- **Fase 3 (marzo):** Alertas inteligentes, detección patrones
- **Fase 4 (abril):** Desglose por actividad (crons, sub-agentes, etc)
- **Fase 5 (mayo):** KPIs de eficiencia (tokens/request, costo/hora)
- **Fase 6 (junio):** Tracking APIs externas (ElevenLabs, Notion)
