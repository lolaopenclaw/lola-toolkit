# Google Sheets Automation Setup — 2026-02-22 22:05

## ✅ Completado

**Objetivo:** Automatizar relleno de Google Sheets con datos de consumo IA y Garmin Health.

**Status:** ✅ Funcionando

---

## IDs de Sheets

```
📊 Consumo IA:      1Fs9L4DNG81pzeLNSMDZhQsqqNwYz0TYMEQrAzCoSf6Y
💓 Garmin Health:   1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk
📁 Carpeta:         1TWOlXn91l8P3voVehbYbB9sQVNirI2Z9 (📊 Lola Dashboards)
```

---

## Configuración realizada

### 1. Autenticación GOG ✅
- Cliente: `optimal-courage-486312-c8`
- Servicios: Gmail, Calendar, Drive, Sheets, Docs
- Status: Tokens guardados en `~/.config/gog/`
- Verificación: `gog calendar list` ✅

### 2. Scripts creados

**`scripts/sheets-setup.sh`** (initial setup)
- Configura client_secret.json
- Autentica con Google
- Status: ✅ Ejecutado exitosamente

**`scripts/sheets-populate-daily.sh`** (automatización)
- Rellena "Consumo IA" con datos diarios
  - Fecha, USD consumido, # requests, timestamp
- Rellena "Garmin Health" con datos de ayer
  - Fecha, HR promedio, pasos, horas sueño
- Cron: Lunes-viernes 9:30 AM
- Status: ✅ Probado, listo

### 3. Cron job configurado

**📊 Populate Google Sheets (diario)**
- Horario: Lunes-viernes 9:30 AM
- Ejecuta: `sheets-populate-daily.sh`
- Status: ✅ Activo desde 2026-02-22

---

## Estructura de Sheets

### Consumo IA
| Columna | Datos |
|---------|-------|
| A | Fecha (YYYY-MM-DD) |
| B | Consumo USD |
| C | # Requests |
| D | Timestamp (HH:MM:SS) |

### Garmin Health
| Columna | Datos |
|---------|-------|
| A | Fecha |
| B | HR promedio (bpm) |
| C | Pasos |
| D | Sueño (h) |
| E | Timestamp |

---

## Próximos pasos (opcional)

1. **Gráficas automáticas** en Sheets (consumo trending, Garmin patterns)
2. **Alertas** si consumo > $50/día
3. **Resumen semanal** con análisis de tendencias
4. **Compartir dashboard** con vistas públicas (si aplica)

---

## Comandos útiles

**Ver últimas filas de Consumo IA:**
```bash
gog sheets get "1Fs9L4DNG81pzeLNSMDZhQsqqNwYz0TYMEQrAzCoSf6Y" "Consumo IA!A1:D100" --plain
```

**Limpiar todas las filas:**
```bash
gog sheets clear "1Fs9L4DNG81pzeLNSMDZhQsqqNwYz0TYMEQrAzCoSf6Y" "Consumo IA!A2:D"
```

**Append manual:**
```bash
gog sheets append "<SHEET_ID>" "<TAB>!A:D" "2026-02-22" "5.50" "120" "22:05:00"
```

---

**Log:** 2026-02-22 22:05 Madrid | Manu completó autenticación desde laptop, copié scripts, configuré crons.
