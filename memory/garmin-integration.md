# 💓 Garmin Health Integration

**Estado:** ✅ Operativa (desde 2026-02-22)  
**Última actualización:** 2026-03-24 19:56

---

## 📊 Resumen

Sistema automatizado de recopilación y análisis de datos de salud del Garmin Instinct 2S Solar Surf, con sincronización diaria a Google Sheets y almacenamiento local en Markdown.

---

## 🔄 Flujo de Datos

```
Garmin Watch (Manu_Lazarus)
    ↓ (sincronización automática vía Garmin Connect)
Garmin Connect API
    ↓ (OAuth token)
scripts/garmin-health-report.sh
    ↓ (parse + formato)
Google Sheets (1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk)
    ↓ (download)
memory/garmin/*.md (local)
```

---

## 🗂️ Estructura Local

**Ubicación:** `memory/garmin/`

### Archivos principales:
- **`README.md`** — Índice y documentación completa
- **`historico-2026.md`** — Todos los datos diarios de 2026
- **`tendencias.md`** — Análisis de tendencias del último mes
- **`resumen-semanal/`** — Resúmenes semanales
  - `2026-w10.md` (3-9 marzo)
  - `2026-w11.md` (10-16 marzo)
  - `2026-w12.md` (17-23 marzo)
  - `2026-w13.md` (24-30 marzo, en curso)

---

## 🔧 Scripts y Automatización

### Script principal
**`scripts/garmin-health-report.sh`**
- Genera reporte diario completo
- Uso: `bash scripts/garmin-health-report.sh --daily`
- Métricas: pasos, HR, sueño, estrés, Body Battery, actividades

### Sincronización Google Sheets
**`scripts/sheets-populate-v2.py`**
- Cron job: Lun-Vie 9:30 AM (Europe/Madrid)
- Job ID: `6344d609-2bfd-4295-8471-373125381779`
- Backfill automático: últimos 60 días
- Sheet: "Garmin Health" en 📊 Lola Dashboards

### Comandos útiles

```bash
# Reporte diario (ayer)
bash scripts/garmin-health-report.sh --daily

# Descargar datos del Sheet
source ~/.bashrc && gog sheets get "1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk" "A1:K100" -p

# Ver estado del cron job
openclaw cron list | grep -A 5 "Garmin"
```

---

## 📊 Métricas Disponibles

### Actividad
- **Pasos** (steps/día)
- **Distancia** (km)
- **Calorías activas** (kcal)
- **Pisos subidos**
- **Minutos intensidad**

### Heart Rate
- **HR actual** (bpm)
- **HR promedio 24h** (bpm)
- **HR máximo** (bpm)
- **HR reposo** (bpm mínimo nocturno)

### Sueño
- **Duración total** (horas)
- **Sueño profundo** (horas)
- **Sueño ligero** (horas)
- **REM** (horas)

### Bienestar
- **Estrés promedio** (0-100, menor = mejor)
- **Body Battery** (0-100, mayor = mejor energía)

### Actividades deportivas
- **Tipo** (fuerza, surf, cardio, etc.)
- **Duración** (minutos)
- **Distancia** (cuando aplica)
- **Calorías** (kcal)
- **HR promedio durante actividad**

---

## 🔐 Autenticación

### OAuth Garmin
- **Usuario:** Manu_Lazarus
- **Tokens:** Almacenados en `~/.garmin-tokens/` (encriptados)
- **Renovación:** Automática cada 90 días

### Google Workspace (gog CLI)
- **Cuenta:** lolaopenclaw@gmail.com
- **Cliente:** optimal-courage-486312-c8
- **Tokens:** `~/.config/gog/`
- **Servicios activos:** Drive, Sheets, Calendar, Gmail

---

## 📈 Uso y Consultas

### Consultar tendencias actuales
```bash
cat memory/garmin/tendencias.md
```

### Ver histórico completo
```bash
cat memory/garmin/historico-2026.md
```

### Resumen de una semana específica
```bash
cat memory/garmin/resumen-semanal/2026-w12.md
```

### Generar reporte actualizado
```bash
bash scripts/garmin-health-report.sh --daily
```

---

## 🎯 Estado y Próximos Pasos

### ✅ Completado
- [x] Integración OAuth con Garmin Connect
- [x] Script de reporte diario funcional
- [x] Sincronización automática a Google Sheets
- [x] Backfill histórico (60 días)
- [x] Estructura Markdown local completa
- [x] Análisis de tendencias mensual
- [x] Resúmenes semanales

### 🔄 En curso
- [ ] Resumen semanal automático (cada lunes)
- [ ] Alertas si métricas críticas (sueño <6h, estrés >50)
- [ ] Dashboard visual en Google Sheets

### 💡 Futuro (opcional)
- [ ] Correlación actividad/sueño/estrés
- [ ] Predicción de recuperación (Body Battery)
- [ ] Integración con calendario (eventos vs HR/estrés)
- [ ] Exportación mensual a PDF

---

## 🐛 Troubleshooting

### Problema: "401 Unauthorized"
**Causa:** Token OAuth expirado  
**Solución:** Re-autenticar con `garmin-cli login`

### Problema: Datos de sueño = 0.0h
**Causa:** Falta sincronización nocturna del reloj  
**Solución:** Forzar sync manual en Garmin Connect app

### Problema: Google Sheet no actualiza
**Causa:** Cron job deshabilitado o fallando  
**Solución:**
```bash
openclaw cron list | grep "6344d609"
openclaw cron enable 6344d609-2bfd-4295-8471-373125381779
```

---

## 📚 Referencias

- **Google Sheet:** https://docs.google.com/spreadsheets/d/1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk/edit
- **Perfil de salud:** `memory/health/manu-health-profile.md`
- **Setup original:** `memory/archive/feb-2026/DAILY/WARM/2026-02-22-google-sheets-automation.md`
- **Documentación gog:** https://github.com/openclawai/gog

---

**Última actualización:** 2026-03-24 | Migración a estructura Markdown completada ✅
