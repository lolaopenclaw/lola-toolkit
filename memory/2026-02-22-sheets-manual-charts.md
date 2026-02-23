# Cómo Crear Gráficas en los Sheets

Los datos ya están cargados. Ahora necesitas crear las gráficas manualmente (toma 2 minutos).

## 📊 Consumo IA

1. Abre: https://docs.google.com/spreadsheets/d/1Fs9L4DNG81pzeLNSMDZhQsqqNwYz0TYMEQrAzCoSf6Y

2. Selecciona los datos:
   - Columnas A y B (Fecha y USD)
   - Filas 1-8 (header + últimos 7 días)
   - O todo: `A:B`

3. Inserta gráfica:
   - Menu: **Insertar > Gráfico**
   - Tipo: **Línea**
   - Eje X: Fecha
   - Eje Y: USD
   - Título: "Consumo IA - Tendencia Diaria"
   - Posición: lado derecho (columna E)
   - **Insertar**

## 💓 Garmin Health

1. Abre: https://docs.google.com/spreadsheets/d/1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk

2. Selecciona datos:
   - Columnas A-D (Fecha, HR, Pasos, Sueño)
   - Filas 1-8

3. Inserta gráfica:
   - Menu: **Insertar > Gráfico**
   - Tipo: **Combo** (si dispones) o **Línea**
   - Series:
     - HR (Eje izquierdo)
     - Pasos (Eje izquierdo)
     - Sueño (Eje derecho - opcional)
   - Título: "Garmin Health - Últimos 7 días"
   - **Insertar**

---

## Automatización (Futuro)

Una vez que las gráficas estén creadas manualmente, puedo:
- Crear script que **actualice datos automáticamente**
- Las gráficas se refrescarán solas (vinculadas a los datos)

Scripts preparados:
- `sheets-populate-daily.sh` — Añade datos diarios
- `sheets-add-charts.py` — (WIP) Crea gráficas vía API
- `sheets-add-charts.sh` — (WIP) Crea gráficas vía curl

---

**Estado:** 
- ✅ Datos cargados (7 días de ejemplo)
- ⏳ Gráficas: necesitan crearse en UI
- ✅ Automatización: lista cuando apruebes

Próximos pasos:
1. Crea las gráficas manualmente (2 min)
2. Mándame screenshot para validar
3. Seguimos desde ahí
