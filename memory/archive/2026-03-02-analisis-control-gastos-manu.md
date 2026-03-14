# 💰 Control de Gastos - Análisis Completo de Opciones

Manu, aquí tienes el análisis detallado de todas las opciones para montar tu sistema de control de gastos. Al final, la recomendación concreta con plan de implementación.

---

## 📊 Tu Situación

- **Todo por tarjeta CaixaBank** → cada gasto queda registrado digitalmente
- **Sin efectivo** → cobertura ~100% de gastos
- **Datos disponibles:** CSV/Excel descargable desde CaixaBank Now
- **Infraestructura:** VPS con Python, Google Sheets (gog), Drive, Crons, Telegram

---

## Opción 1: CSV Local Manual

**Qué es:** Descargas el CSV del banco, lo guardas en una carpeta, y lo consultas con scripts o a mano.

| Aspecto | Detalle |
|---|---|
| **Pros** | Cero dependencias externas. Máxima privacidad. Sin coste. |
| **Contras** | Sin visualización fácil. Consultar datos = abrir terminal. No hay alertas. Aburre rápido → se abandona. |
| **Esfuerzo Manu** | Alto: descargar CSV + recordar consultarlo manualmente |
| **Esfuerzo Lola** | Bajo: scripts básicos de parsing |
| **Automatización** | Mínima. El cuello de botella es la descarga manual del CSV. |
| **Privacidad** | ✅ Excelente: datos solo en VPS local |
| **Mantenimiento** | Bajo técnicamente, pero alto en disciplina personal |
| **Veredicto** | ❌ **Descartada.** Sin interfaz visual ni alertas, morirá en 2 semanas. |

---

## Opción 2: Google Sheets Manual

**Qué es:** Creas una hoja de cálculo en Google Sheets y metes los gastos a mano (o copias del CSV).

| Aspecto | Detalle |
|---|---|
| **Pros** | Visual. Gráficos integrados. Accesible desde móvil. Fórmulas para totales/categorías. |
| **Contras** | Meter datos a mano es tedioso. Copy-paste del CSV requiere formateo. Propenso a errores humanos. |
| **Esfuerzo Manu** | Muy alto: entrada manual de datos o copy-paste semanal |
| **Esfuerzo Lola** | Medio: diseñar la hoja, fórmulas, gráficos |
| **Automatización** | Ninguna real. Todo depende de que Manu meta los datos. |
| **Privacidad** | ⚠️ Datos en Google Cloud (cuenta lolaopenclaw@gmail.com) |
| **Mantenimiento** | Medio: las fórmulas se rompen si cambias estructura |
| **Veredicto** | ❌ **Descartada.** Si el sistema depende de tu disciplina manual, no sobrevive. |

---

## Opción 3: CSV → Python → Google Sheets ⭐ RECOMENDADA

**Qué es:** Descargas el CSV del banco → un script Python lo parsea, categoriza y sube a Google Sheets → Lola genera reportes y alertas automáticas por Telegram.

| Aspecto | Detalle |
|---|---|
| **Pros** | Categorización automática. Dashboard visual en Sheets. Alertas por Telegram. Reportes automáticos. Tu único trabajo: descargar el CSV. |
| **Contras** | Setup inicial (~2-3h de desarrollo). Dependencia de formato CSV de CaixaBank (si lo cambian, hay que ajustar parser). |
| **Esfuerzo Manu** | **Mínimo:** descargar CSV 1-2 veces/semana y subirlo a Drive (2 min) |
| **Esfuerzo Lola** | Alto inicial (crear scripts), bajo después (mantenimiento) |
| **Automatización** | Alta: procesamiento, categorización, reportes, alertas — todo automático |
| **Privacidad** | ⚠️ Datos en Google (misma cuenta Lola). Aceptable para uso personal. |
| **Mantenimiento** | Bajo: solo si CaixaBank cambia formato del CSV |
| **Veredicto** | ✅ **GANADORA. Máximo resultado con mínimo esfuerzo tuyo.** |

---

## Opción 4: Notion Database

**Qué es:** Base de datos en Notion con cada gasto como entrada, vistas filtradas, y resúmenes.

| Aspecto | Detalle |
|---|---|
| **Pros** | UI bonita. Filtros potentes. Vistas múltiples (tabla, calendario, kanban). |
| **Contras** | API de Notion es lenta. No tiene gráficos nativos buenos. Importar CSV a Notion es engorroso. Notion es overkill para una tabla de gastos. Ya usas Notion para Ideas — mezclar puede ser confuso. |
| **Esfuerzo Manu** | Medio: tiene que familiarizarse con la estructura |
| **Esfuerzo Lola** | Alto: la API de Notion para bulk inserts es tediosa |
| **Automatización** | Media: posible pero frágil con la API |
| **Privacidad** | ⚠️ Datos en Notion Cloud |
| **Mantenimiento** | Medio: Notion suele tener cambios de API |
| **Veredicto** | ❌ **Descartada.** Notion es mejor para gestión/proyectos que para datos financieros brutos. |

---

## Opción 5: Sistema Custom Python + Crons

**Qué es:** Script Python que detecta automáticamente CSV nuevo en Drive, lo procesa, genera reportes y alertas — todo sin intervención manual.

| Aspecto | Detalle |
|---|---|
| **Pros** | Cero trabajo manual de Manu. Automatización total. Reportes diarios/semanales automáticos. |
| **Contras** | Requiere monitoreo de Drive (polling). Más complejo que Opción 3. CaixaBank puede no permitir descargas scriptables si requiere login interactivo. |
| **Esfuerzo Manu** | **Nulo:** subes CSV a Drive 1x/semana, todo lo demás automático |
| **Esfuerzo Lola** | Muy alto inicial (monitor Drive, parsing, lógica compleja) |
| **Automatización** | ✅ Máxima: todo end-to-end automático |
| **Privacidad** | ⚠️ Datos en Google |
| **Mantenimiento** | Medio: requiere monitoreo de Drive |
| **Veredicto** | ⚠️ **Posible mejora futura de Opción 3.** Por ahora, Opción 3 es más práctico. |

---

# ✅ RECOMENDACIÓN: OPCIÓN 3 (CSV → Python → Google Sheets)

## ¿Por qué esta?

1. **Máximo automatismo sin sobreingeniería:** Haces 2 min de trabajo (descargar CSV), Lola hace el resto.
2. **Dashboard visual:** Google Sheets es fácil de leer, con gráficos listos.
3. **Alertas automáticas:** Por Telegram, en tiempo real.
4. **Reportes inteligentes:** Semanales/mensuales, con análisis de tendencias.
5. **Escalable:** Si en el futuro quieres más (Opción 5), la base está lista.

---

## Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────┐
│ CaixaBank (tu banco)                                        │
└──────────────────────┬──────────────────────────────────────┘
                       │ (tú descargas CSV 1-2x/semana)
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ Google Drive / lolaopenclaw@gmail.com                       │
│ (carpeta: "Gastos/CaixaBank/")                              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ VPS mleon (Lola)                                            │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Script Python: parse-caixa.py                           │ │
│ │ - Lee CSV desde Drive                                   │ │
│ │ - Parsea estructura (fecha, cantidad, concepto)        │ │
│ │ - Categoriza automáticamente (reglas inteligentes)     │ │
│ │ - Detecta duplicados (si vuelves a subir mismo CSV)   │ │
│ │ - Sube a Google Sheets                                 │ │
│ └─────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Crons OpenClaw:                                         │ │
│ │ - Diario (9 AM): Procesa CSV nuevo si existe           │ │
│ │ - Semanal (domingo): Resumen semanal → Telegram        │ │
│ │ - Mensual (1er día): Análisis completo del mes         │ │
│ └─────────────────────────────────────────────────────────┘ │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ Google Sheets (dashboard visual)                            │
│ - Todas las transacciones categorizadas                     │
│ - Totales por categoría                                     │
│ - Gráficos: Gastos por categoría, tendencia mensual       │
│ - Presupuestos: límites por categoría                       │
│ - Alertas: "Excedeíste límite de X en categoría Y"        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ Telegram (alertas y reportes)                               │
│ - Diarios: "Hoy gastaste €X"                              │
│ - Semanales: "Esta semana: €X (vs semana pasada: €Y)"    │
│ - Alertas: "⚠️ Superaste presupuesto de Restaurantes"     │
│ - Mensuales: "Marzo: €X (arriba/abajo vs media)"          │
└─────────────────────────────────────────────────────────────┘
```

---

## Workflow Detallado

### Manu (tu parte):

1. **Cada lunes/jueves** (o 1-2x/semana):
   - Abre CaixaBank → "Descargar movimientos" → CSV
   - Sube a Google Drive en carpeta "Gastos/CaixaBank/"
   - **Listo.** Nada más.

### Lola (mi parte):

1. **Todos los días a las 9 AM** (cron):
   - Detecta CSV nuevo en Drive
   - Lo parsea y categoriza automáticamente
   - Lo añade a la Google Sheet
   - Elimina el CSV para no procesarlo de nuevo

2. **Domingos a las 10 AM** (cron):
   - Genera resumen semanal
   - Envía por Telegram: "Semana de [fecha]: €X gastados, distribuido en: Comida (€Y), Transporte (€Z)..."

3. **1er día del mes a las 9 AM** (cron):
   - Análisis completo del mes anterior
   - Resumen: "Febrero: €X total, cambio vs enero: +€Y (+Z%)"
   - Gráfico ASCII con tendencias

---

## Categorías de Gastos (Propuesta)

Sugiero estas 8 categorías principales (puedes personalizar):

| Categoría | Ejemplos | Presupuesto sugerido |
|---|---|---|
| **Alimentación** | Supermercados, tiendas gourmet | Personalizado |
| **Restaurantes/Café** | Bares, restaurantes, cafeterías | Personalizado |
| **Transporte** | Uber, autobús, gasolina, parking | Personalizado |
| **Música & Diversión** | Conciertos, cine, juegos | Personalizado |
| **Hogar & Utilidades** | Alquiler (si no está en tarjeta), servicios | Personalizado |
| **Suscripciones** | Spotify, Netflix, seguros | Personalizado |
| **Salud & Bienestar** | Farmacia, médicos, deporte | Personalizado |
| **Varios** | Gastos sin categoría clara | Flexible |

---

## Script Python (parse-caixa.py)

Aquí te dejo un esqueleto del script:

```python
#!/usr/bin/env python3
import csv
import re
from datetime import datetime
import json

# Reglas de categorización (patrón → categoría)
CATEGORY_RULES = {
    'Alimentación': [
        r'MERCADONA|CARREFOUR|ALCAMPO|EROSKI|LIDL|ALDI|SIMPLY|SUPERMERCADO'
    ],
    'Restaurantes/Café': [
        r'BAR|CAFE|COFFEE|RESTAURANT|PIZZA|BURGER|COMIDA|McDONALD'
    ],
    'Transporte': [
        r'UBER|TAXI|AUTOBÚS|GASOLINA|ESTACIÓN|PARKING|TREN|RENFE|AVIÓN'
    ],
    'Música & Diversión': [
        r'CINE|CONCIERTO|TEATRO|SPOTIFY|AMAZON PRIME|NETFLIX|GAMING'
    ],
    'Hogar & Utilidades': [
        r'RENTA|LUZ|AGUA|GAS|TELÉFONO|INTERNET|ELECTRICIDAD'
    ],
    'Suscripciones': [
        r'MENSUAL|CUOTA|SUBSCRIPCIÓN|ADOBE|MICROSOFT'
    ],
    'Salud & Bienestar': [
        r'FARMACIA|FARMACIA|DOCTOR|CLINIC|DEPORTE|GYM|YOGA'
    ],
}

def categorize_transaction(description):
    """Categoriza un gasto basado en la descripción."""
    for category, patterns in CATEGORY_RULES.items():
        for pattern in patterns:
            if re.search(pattern, description, re.IGNORECASE):
                return category
    return 'Varios'

def parse_caixa_csv(csv_path):
    """Parsea un CSV de CaixaBank."""
    transactions = []
    with open(csv_path, 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                # Estructura típica de CaixaBank (ajustar según tu formato real)
                date_str = row.get('Fecha', '') or row.get('Data', '')
                amount_str = row.get('Importe', '') or row.get('Import', '')
                description = row.get('Concepto', '') or row.get('Descripció', '')
                
                # Limpiar y parsear
                amount = float(amount_str.replace(',', '.').replace('€', '').strip())
                date = datetime.strptime(date_str, '%d/%m/%Y').date()
                
                # Categorizar
                category = categorize_transaction(description)
                
                transactions.append({
                    'date': date.isoformat(),
                    'amount': amount,
                    'description': description,
                    'category': category,
                })
            except Exception as e:
                print(f"Error parsing row {row}: {e}")
                continue
    
    return transactions

def upload_to_sheets(transactions, sheet_id):
    """Sube las transacciones a Google Sheets."""
    # Aquí usaríamos gog sheets append o gog api
    # Por ahora, es pseudocódigo
    for tx in transactions:
        # gog sheets append $SHEET_ID --row "2026-03-02" "20.50" "Supermercado" "Alimentación"
        pass

if __name__ == '__main__':
    import sys
    csv_path = sys.argv[1] if len(sys.argv) > 1 else 'movimientos.csv'
    
    transactions = parse_caixa_csv(csv_path)
    print(f"Parsed {len(transactions)} transactions")
    
    for tx in transactions:
        print(f"{tx['date']} | €{tx['amount']:6.2f} | {tx['category']:20} | {tx['description']}")
    
    # upload_to_sheets(transactions, 'tu-sheet-id')
```

---

## Google Sheet (estructura)

Crear una sheet con estas columnas:

| Fecha | Monto | Descripción | Categoría | Presupuesto | Estado |
|---|---|---|---|---|---|
| 2026-03-01 | 25.50 | MERCADONA | Alimentación | 400 | OK |
| 2026-03-02 | 12.00 | CAFE BAR | Restaurantes/Café | 150 | OK |
| 2026-03-02 | 45.00 | SPOTIFY | Suscripciones | 50 | ⚠️ EXCEDIDO |

**Fórmulas:**
- Columna "Total por categoría": `SUMIF(Categoría:Categoría, "Alimentación", Monto:Monto)`
- Columna "Estado": `IF(SUM_categoría > Presupuesto, "⚠️ EXCEDIDO", "OK")`
- Gráfico: Pie chart de Monto por Categoría

---

## Crons OpenClaw (implementación)

```bash
# Cron diario (9 AM Madrid): Procesar CSV
openclaw cron add \
  --name "💰 Procesar gastos Caixa (diario)" \
  --cron "0 9 * * *" \
  --tz "Europe/Madrid" \
  --session isolated \
  --message "bash ~/.openclaw/workspace/scripts/process-caixa-expenses.sh" \
  --no-deliver

# Cron semanal (domingo 10 AM): Resumen semanal
openclaw cron add \
  --name "📊 Resumen semanal de gastos" \
  --cron "0 10 * * 0" \
  --tz "Europe/Madrid" \
  --session isolated \
  --message "bash ~/.openclaw/workspace/scripts/weekly-expense-report.sh" \
  --deliver --channel telegram --to 6884477

# Cron mensual (1er día 9 AM): Análisis completo
openclaw cron add \
  --name "📈 Análisis mensual de gastos" \
  --cron "0 9 1 * *" \
  --tz "Europe/Madrid" \
  --session isolated \
  --message "bash ~/.openclaw/workspace/scripts/monthly-expense-analysis.sh" \
  --deliver --channel telegram --to 6884477
```

---

## Alertas Inteligentes

El sistema enviará alertas por Telegram en estos casos:

1. **Diaria (si aplica):** "Hoy gastaste €X (media diaria: €Y)"
2. **Límite de categoría:** "⚠️ Restaurantes/Café: €XXX de presupuesto €YYY (Z% usado)"
3. **Gasto inusual:** "🚨 Gasto alto detectado: €XXX en [descripción]"
4. **Cambio vs histórico:** "📉 Esta semana gastaste 15% menos que la media (€X vs €Y)"

---

## Plan de Implementación (pasos concretos)

### PASO 1: Conseguir un CSV de ejemplo (HOY)

1. Abre CaixaBank → descarga movimientos de los últimos 7 días en CSV
2. Guarda el archivo (p.ej., `movimientos-2026-03-02.csv`)
3. Me lo compartes

### PASO 2: Lola crea el parser (1-2h)

1. Analizo el formato exacto del CSV
2. Creo script `parse-caixa.py` personalizado para tu banco
3. Creo las categorías con reglas que aprendan de tus gastos

### PASO 3: Google Sheets base (30 min)

1. Creo una sheet llamada "Gastos 2026"
2. Estructura con columnas: Fecha, Monto, Descripción, Categoría, Presupuesto, Estado
3. Fórmulas de totales y gráficos
4. Te comparto el enlace

### PASO 4: Setup de crons y alertas (1h)

1. Creo scripts bash para procesamiento automático
2. Configuro crons diarios/semanales/mensuales
3. Alertas por Telegram
4. Prueba: subes un CSV → se procesa automáticamente

### PASO 5: Ajustes y refinamiento (iterativo)

1. Pruebas durante 2 semanas
2. Ajustamos categorías, límites de presupuesto
3. Personalizamos alertas según tu preferencia

---

## Próximos pasos

1. **Comparte un CSV de ejemplo** de CaixaBank (últimos 7 días)
2. **Dime qué categorías de gastos prefieres** (puedes ajustar las 8 que propongo)
3. **Cuál es tu presupuesto aproximado por categoría** (sirve para alertas)

Con eso, empezamos la implementación. Serán 2-3 horas de desarrollo de Lola, y luego todo automático para ti.

---

## Resumen Visual

```
TU TRABAJO:        CSV → subir a Drive (2 min, 1-2x/semana)
                         ↓
LOLA TRABAJO:      Python parser → Google Sheets (automático diario)
                         ↓
TU RESULTADO:      Dashboard + alertas semanales/mensuales por Telegram
```

¿Te parece bien este plan?
