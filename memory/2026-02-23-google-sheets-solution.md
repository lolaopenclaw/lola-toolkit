# Google Sheets Automation — Solución Definitiva

**Fecha:** 2026-02-23
**Estado:** ✅ Implementado y funcionando

## Problema Original

El cron "Populate Google Sheets" tenía múltiples problemas:
1. **Garmin Health:** Datos incorrectos — solo Steps, HR avg, y Sleep tenían valores; todo lo demás era 0
2. **Formato de números:** En es_ES locale, los integers aparecían con coma final ("999,") — cosmético pero confuso
3. **Datos históricos:** 2026-02-15 a 2026-02-21 tenían valores erróneos (pasos incorrectos, métricas en 0)
4. **gog CLI:** Funciona correctamente con `--values-json` — los números se almacenan bien como numbers (verificado con `--render UNFORMATTED_VALUE`)

## Diagnóstico Root Cause

- **Garmin data fetch:** El script original v1 no extraía correctamente todos los campos de la API de Garmin (HR max, HR reposo, stress, body battery, sleep deep, distance, calories)
- **Trailing comma display:** NO es un bug de gog — es el formato de número por defecto de es_ES locale en Google Sheets. Se resolvió aplicando formatos explícitos.
- **Los datos SÍ se insertan en columnas separadas:** `gog sheets append --values-json` funciona correctamente. El problema nunca fue "todo en una celda".

## Solución Implementada

### Script Principal: `scripts/sheets-populate-v2.py`

**¿Por qué Python?**
- `garminconnect` library nativa para datos de Garmin
- Parsing de JSON robusto
- Manejo de errores por campo (si falla HR, sigue con el resto)
- No depende de client_secret.json — usa `gog` CLI para OAuth

**Características:**
- `--dry-run` — muestra qué insertaría sin escribir
- `--consumo-only` / `--garmin-only` — procesa solo una sheet
- `--date YYYY-MM-DD` — fecha específica
- `--backfill N` — rellena últimos N días
- `--force` — sobrescribe filas existentes
- `--fix-format` — aplica formato de números correcto
- Detección de duplicados automática
- Actualización de filas existentes (no duplica)

### Wrapper para Cron: `scripts/sheets-populate-v2.sh`

- Ejecuta Consumo IA con fecha de HOY
- Ejecuta Garmin Health con fecha de AYER (datos completos del día)
- Logs en `logs/sheets-populate-YYYY-MM-DD.log`
- Auto-limpieza de logs > 14 días

### Cron Job Actualizado

- **ID:** `6344d609-2bfd-4295-8471-373125381779`
- **Nombre:** 📊 Populate Google Sheets v2
- **Schedule:** L-V 9:30 AM Madrid
- **Model:** claude-haiku-4-5
- **Timeout:** 120s

## Datos Corregidos

### Garmin Health (re-fetched 2026-02-15 a 2026-02-21)
- ✅ Steps: valores reales (7635, 5826, 3959, 4635, 4614, 4336, 4844)
- ✅ Distance: km reales (6.12, 4.67, 3.18, 3.71, 3.70, 3.47, 3.90)
- ✅ Calories: activas (260, 135, 144, 138, 159, 112, 155)
- ✅ HR avg/max/resting: datos completos
- ✅ Stress: niveles reales (24-34)
- ✅ Sleep total + deep: corregidos
- ✅ Body Battery max: datos reales (9-79)

### Formato de Números
- Aplicado `$#,##0.00` para columnas de dinero (Consumo IA)
- Aplicado `#,##0` para enteros (pasos, calorías, HR, stress, battery)
- Aplicado `0.00` / `0.0` para decimales (distancia, horas de sueño)
- Sin trailing commas en la vista formateada

## Sheets IDs

| Sheet | ID |
|---|---|
| Consumo IA | `1Fs9L4DNG81pzeLNSMDZhQsqqNwYz0TYMEQrAzCoSf6Y` |
| Garmin Health | `1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk` |

## Columnas

### Consumo IA
A: Fecha | B: Haiku ($) | C: Sonnet ($) | D: Opus ($) | E: Gemini ($) | F: Total ($) | G: Requests

### Garmin Health
A: Fecha | B: Pasos | C: Distancia (km) | D: Calorías | E: HR Promedio | F: HR Max | G: HR Reposo | H: Estrés | I: Sueño (h) | J: Sueño Profundo (h) | K: Body Battery Max

## Debug Guide

```bash
# Ver datos actuales (formateados)
source ~/.openclaw/.env && export GOG_KEYRING_BACKEND=file
gog sheets get "1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk" "'Hoja 1'!A1:K20" --account lolaopenclaw@gmail.com --plain

# Ver valores reales (sin formato)
gog sheets get "1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk" "'Hoja 1'!A1:K20" --account lolaopenclaw@gmail.com --json --render UNFORMATTED_VALUE

# Dry run del script
python3 ~/.openclaw/workspace/scripts/sheets-populate-v2.py --dry-run

# Backfill de una fecha específica
python3 ~/.openclaw/workspace/scripts/sheets-populate-v2.py --garmin-only --date 2026-02-22 --force

# Ejecutar cron manualmente
openclaw cron run 6344d609-2bfd-4295-8471-373125381779

# Ver logs del cron
openclaw cron runs --id 6344d609-2bfd-4295-8471-373125381779 --limit 5

# Ver logs del script
cat ~/.openclaw/workspace/logs/sheets-populate-$(date +%Y-%m-%d).log
```

## Notas Técnicas

1. **gog CLI v0.9.0** funciona correctamente con `--values-json` — no hay bug
2. **Fechas en Sheets** se almacenan como serial numbers (46068 = 2026-02-15) — esto es normal con `USER_ENTERED`
3. **Sleep data** se fecha con el día de actividad pero se obtiene del día siguiente (wake-up date)
4. **2026-02-15 sleep = 0h** porque es el primer día del dataset y no hay datos de la noche anterior
5. **Body Battery** usa el valor `charged` del endpoint `get_body_battery()`, no el max del array `bodyBatteryValuesArray`
