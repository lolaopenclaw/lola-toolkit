# 💓 Garmin Health - Datos de Salud

**Dispositivo:** Garmin Instinct 2S Solar Surf  
**Usuario:** Manu (Manu_Lazarus)  
**Actualización:** Diaria automática (9:30 AM, Lun-Vie)

---

## 📂 Estructura de Archivos

### Datos históricos
- **`historico-2026.md`** — Todos los datos diarios de 2026 (pasos, HR, sueño, estrés, Body Battery)
- Datos importados desde Google Sheet "Garmin Health"

### Resúmenes semanales
- **`resumen-semanal/`** — Resúmenes semanales con análisis de tendencias
  - `2026-w10.md` — Semana del 3 marzo
  - `2026-w11.md` — Semana del 9 marzo
  - `2026-w12.md` — Semana del 16 marzo
  - `2026-w13.md` — Semana del 23 marzo

### Análisis
- **`tendencias.md`** — Análisis de tendencias del último mes (promedios, evolución)

---

## 📊 Métricas Disponibles

### Actividad Diaria
- **Pasos** (steps/día)
- **Distancia** (km)
- **Calorías** (kcal activas)

### Heart Rate
- **HR Promedio** (bpm)
- **HR Máximo** (bpm)
- **HR Reposo** (bpm mínimo nocturno)

### Sueño
- **Duración total** (horas)
- **Sueño profundo** (horas)
- Fases: Ligero, REM, Profundo

### Bienestar
- **Estrés promedio** (0-100, menor = mejor)
- **Body Battery** (0-100, mayor = mejor)

---

## 🔄 Integración Automática

### Script diario
```bash
scripts/garmin-health-report.sh --daily
```
Genera reporte completo con datos de ayer.

### Población de Google Sheet
- **Cron job:** Lun-Vie 9:30 AM
- **Script:** `scripts/sheets-populate-v2.py`
- **Backfill:** Últimos 60 días automático
- **Sheet ID:** `1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk`

---

## 📋 Comandos Útiles

### Ver datos históricos del Sheet
```bash
source ~/.bashrc && gog sheets get "1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk" "A1:K100" -p
```

### Reporte diario
```bash
bash scripts/garmin-health-report.sh --daily
```

### Resumen semanal
```bash
bash scripts/garmin-health-report.sh --weekly
```

---

## 🎯 Uso

1. **Consultar tendencias:** `memory/garmin/tendencias.md`
2. **Ver histórico completo:** `memory/garmin/historico-2026.md`
3. **Resumen de una semana:** `memory/garmin/resumen-semanal/2026-wXX.md`
4. **Datos actualizados:** Google Sheet sincronizado diariamente

---

**Última actualización:** 2026-03-24
