# 💰 Sistema Completo de Gestión de Flujos de Dinero

> **Para:** Manu  
> **Fecha:** 2 de marzo de 2026  
> **Estado:** Diseño completo — listo para implementar  

---

## 📑 Índice

1. [Visión General](#1-visión-general)
2. [Mapa de Flujos de Dinero](#2-mapa-de-flujos-de-dinero)
3. [Arquitectura del Sistema](#3-arquitectura-del-sistema)
4. [Modelo de Datos y Categorización](#4-modelo-de-datos-y-categorización)
5. [Estructura de Google Sheets (Dashboard)](#5-estructura-de-google-sheets-dashboard)
6. [Scripts Python](#6-scripts-python)
   - 6.1 Configuración y parámetros
   - 6.2 Parser de CSVs bancarios
   - 6.3 Motor de categorización automática
   - 6.4 Detector de recurrencias
   - 6.5 Comparador vs gastos estimados
   - 6.6 Calculadora de saldos netos
   - 6.7 Exportador a Google Sheets
   - 6.8 Sistema de alertas Telegram
7. [Automatización (Crons)](#7-automatización-crons)
8. [Plan de Implementación](#8-plan-de-implementación)
9. [Variables que Manu debe personalizar](#9-variables-que-manu-debe-personalizar)
10. [FAQ y Troubleshooting](#10-faq-y-troubleshooting)

---

## 1. Visión General

### ¿Qué es esto?

No es una app de gastos. Es un **sistema de liquidación de dinero real** que entiende que tu vida financiera tiene:

- **Dos cuentas** con propósitos distintos
- **Dinero que entra y sale por obligaciones** (no son "gastos", son compromisos)
- **Flujos cruzados** (bizums que cubren parte de transferencias)
- **Gastos estimados** planificados para todo el año

### El problema que resuelve

Hoy, para saber "cuánto dinero tengo realmente", Manu tiene que:
1. Mirar CaixaBank
2. Mirar Bankinter
3. Restar mentalmente los préstamos que van a llegar
4. Restar la transferencia a su madre
5. Sumar los bizums que faltan por llegar
6. Acordarse de los gastos fijos que vienen este mes
7. **Rezar para que las cuentas cuadren**

Con este sistema, todo eso se calcula automáticamente.

### Resultado final

Un **Google Sheet** que muestra en tiempo real:
- ✅ Dinero real disponible (descontando todo)
- ✅ Qué ha entrado y qué falta por entrar
- ✅ Qué ha salido y qué falta por salir
- ✅ Comparativa con lo que tenías previsto gastar
- ✅ Alertas cuando algo se desvía

---

## 2. Mapa de Flujos de Dinero

```
                    ┌─────────────────────────────────────┐
                    │          FLUJOS DE ENTRADA           │
                    └─────────────────────────────────────┘
                              │
        ┌─────────────────────┼──────────────────────┐
        │                     │                      │
   📥 Nómina            📥 Préstamo 1          📥 Préstamo 2
   (CaixaBank)          (Bankinter)            (Bankinter)
        │                     │               → pasa a hermano
        │                     │                      │
        ▼                     ▼                      ▼
┌──────────────┐    ┌──────────────┐         ┌──────────────┐
│  CAIXABANK   │    │  BANKINTER   │         │   HERMANO    │
│  (Día a día) │    │  (Ahorros/   │         │  devuelve    │
│              │    │  Obligaciones│         │  (variable)  │
└──────┬───────┘    └──────┬───────┘         └──────┬───────┘
       │                   │                        │
       │                   │                        │
       ▼                   ▼                        ▼
┌─────────────────────────────────────────────────────────┐
│                  FLUJOS DE SALIDA                         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  📤 Transferencia fija → Madre                           │
│     └── Cubierta PARCIALMENTE por:                       │
│         📥 Bizum Compañero A (fijo)                      │
│         📥 Bizum Compañero B (fijo)                      │
│         📥 Bizum Compañero C (fijo)                      │
│         📥 ...                                           │
│         ═══════════════════                              │
│         Diferencia = lo que pone Manu de su bolsillo     │
│                                                          │
│  📤 Gastos fijos estimados (por fecha, todo el año)      │
│  📤 Gastos variables (día a día)                         │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Flujo del Local (Madre)

Este es el flujo más complejo y merece detalle:

```
Transferencia a madre:        -€XXX (fija mensual)
  + Bizum compañero 1:        +€YY
  + Bizum compañero 2:        +€YY
  + Bizum compañero 3:        +€YY
  ─────────────────────────────────
  = Coste NETO para Manu:     -€ZZ  ← esto es lo que importa
```

El sistema calcula automáticamente este **coste neto** y lo muestra separado.

---

## 3. Arquitectura del Sistema

```
┌─────────────┐     ┌─────────────┐     ┌──────────────────┐
│  CSV        │     │  CSV        │     │  Google Sheet    │
│  CaixaBank  │     │  Bankinter  │     │  Gastos          │
│  (descarga  │     │  (descarga  │     │  Estimados       │
│   manual)   │     │   manual)   │     │  (existente)     │
└──────┬──────┘     └──────┬──────┘     └────────┬─────────┘
       │                   │                     │
       └───────────┬───────┘                     │
                   ▼                             │
        ┌──────────────────┐                     │
        │  csv_parser.py   │                     │
        │  (normaliza      │                     │
        │   ambos bancos)  │                     │
        └────────┬─────────┘                     │
                 │                               │
                 ▼                               ▼
        ┌──────────────────────────────────────────┐
        │         categorizer.py                    │
        │  - Reglas fijas (préstamos, bizums)       │
        │  - Detección de recurrencias              │
        │  - Matching vs gastos estimados           │
        │  - Cálculo saldos netos                   │
        └────────────────┬─────────────────────────┘
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
   ┌──────────────────┐  ┌──────────────────┐
   │  Google Sheets   │  │  Alertas         │
   │  Dashboard       │  │  Telegram        │
   │  (export vía     │  │  (vía bot API)   │
   │   gog/gspread)   │  │                  │
   └──────────────────┘  └──────────────────┘
```

### Componentes

| Componente | Tecnología | Función |
|---|---|---|
| Almacenamiento CSVs | Carpeta local `/data/csvs/` | CSVs descargados de bancos |
| Parser | Python + pandas | Normaliza formato de cada banco |
| Categorizador | Python + reglas YAML | Clasifica transacciones |
| Dashboard | Google Sheets (via `gog`) | Visualización unificada |
| Alertas | Telegram Bot API | Notificaciones inteligentes |
| Automatización | Cron + scripts bash | Procesamiento periódico |
| Configuración | `config.yaml` | Todas las variables personalizables |

---

## 4. Modelo de Datos y Categorización

### 4.1 Categorías principales

```yaml
categorias:
  INGRESO_NOMINA:
    tipo: ingreso
    descripcion: "Nómina mensual"
    cuenta: caixabank
    
  INGRESO_PRESTAMO_PROPIO:
    tipo: ingreso
    descripcion: "Préstamo 1 - cuota que entra"
    cuenta: bankinter
    recurrente: true
    
  INGRESO_PRESTAMO_HERMANO:
    tipo: ingreso_transitorio  # entra pero sale hacia hermano
    descripcion: "Préstamo 2 - pasa al hermano"
    cuenta: bankinter
    recurrente: true
    contrapartida: SALIDA_HERMANO_PRESTAMO
    
  INGRESO_DEVOLUCION_HERMANO:
    tipo: ingreso
    descripcion: "Hermano devuelve dinero"
    cuenta: caixabank  # o bankinter, según llegue
    recurrente: true
    importe_variable: true
    
  INGRESO_BIZUM_LOCAL:
    tipo: ingreso_afectado  # tiene destino específico
    descripcion: "Bizum compañeros del local"
    cuenta: caixabank
    recurrente: true
    destino: SALIDA_MADRE
    
  SALIDA_MADRE:
    tipo: obligacion
    descripcion: "Transferencia fija a madre"
    cuenta: caixabank
    recurrente: true
    parcialmente_cubierta_por: [INGRESO_BIZUM_LOCAL]
    
  SALIDA_HERMANO_PRESTAMO:
    tipo: obligacion_transitoria
    descripcion: "Paso del préstamo 2 al hermano"
    recurrente: true
    
  GASTO_FIJO_ESTIMADO:
    tipo: gasto_planificado
    descripcion: "Gasto de la hoja de estimaciones"
    
  GASTO_VARIABLE:
    tipo: gasto_real
    descripcion: "Gastos del día a día"
    
  AHORRO:
    tipo: ahorro
    descripcion: "Transferencias entre cuentas propias"
    neutro: true  # no afecta saldo total
    
  OTROS:
    tipo: otros
    descripcion: "Sin clasificar"
```

### 4.2 Esquema de transacción normalizada

```python
@dataclass
class Transaccion:
    fecha: date
    concepto: str              # Descripción original del banco
    importe: float             # Positivo = entrada, Negativo = salida
    cuenta: str                # 'caixabank' | 'bankinter'
    categoria: str             # De las categorías definidas arriba
    subcategoria: str          # Opcional: más detalle
    es_recurrente: bool        # Detectada como recurrente
    persona: str               # Si aplica (hermano, madre, compañero X)
    gasto_estimado_id: str     # Si matchea con gasto estimado
    notas: str                 # Automáticas o manuales
    mes: str                   # YYYY-MM para agrupación
```

### 4.3 Reglas de categorización

El sistema usa **3 niveles** de categorización, en orden de prioridad:

**Nivel 1: Reglas exactas (config.yaml)**
```yaml
reglas_exactas:
  - patron: "PRESTAMO.*CUOTA"
    cuenta: bankinter
    categoria: INGRESO_PRESTAMO_PROPIO
    
  - patron: "BIZUM.*JUAN"  # nombre del compañero
    categoria: INGRESO_BIZUM_LOCAL
    persona: "Juan"
    
  - patron: "TRANSFERENCIA.*MAMA"
    categoria: SALIDA_MADRE
```

**Nivel 2: Detección de recurrencias**
- Misma cantidad ± 5% → mismo mes → mismo concepto similar → recurrente

**Nivel 3: Fallback por tipo**
- Bizum entrante → INGRESO
- Bizum saliente → GASTO_VARIABLE
- Recibo → GASTO_FIJO_ESTIMADO (intentar match)
- Resto → OTROS (para revisar)

---

## 5. Estructura de Google Sheets (Dashboard)

### Hoja 1: 📊 DASHBOARD (vista principal)

Esta es la hoja que Manu abre y ve todo de un vistazo.

```
┌─────────────────────────────────────────────────────────────┐
│                    MARZO 2026                                │
│                                                              │
│  💰 SALDO REAL DISPONIBLE          €X,XXX.XX               │
│     (CaixaBank + Bankinter - compromisos pendientes)         │
│                                                              │
├──────────────────────┬──────────────────────────────────────┤
│  📥 ENTRADAS         │  📤 SALIDAS                          │
│                      │                                       │
│  Nómina    €X,XXX    │  Madre (neto)     -€XXX              │
│  Prést.1   €XXX      │  Gastos fijos     -€XXX              │
│  Hermano   €XXX      │  Gastos variable  -€XXX              │
│  Bizums    €XXX      │  Otros            -€XXX              │
│  ──────────────      │  ──────────────────                   │
│  TOTAL     €X,XXX    │  TOTAL            -€X,XXX            │
│                      │                                       │
├──────────────────────┴──────────────────────────────────────┤
│  🏦 DETALLE POR CUENTA                                      │
│                                                              │
│  CaixaBank:  Saldo €X,XXX  │  Pendiente entrar: €XXX        │
│  Bankinter:  Saldo €X,XXX  │  Pendiente salir:  -€XXX       │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│  📋 OBLIGACIONES DEL MES                                     │
│                                                              │
│  ✅ Préstamo 1 (día 5)          €XXX    RECIBIDO             │
│  ✅ Bizum Juan (día 1)          €XX     RECIBIDO             │
│  ⏳ Bizum Pedro (día ~10)       €XX     PENDIENTE            │
│  ⏳ Transfer madre (día 15)     -€XXX   PENDIENTE            │
│  ✅ Hermano devuelve            €XXX    RECIBIDO             │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│  📊 GASTOS vs ESTIMADO                                       │
│                                                              │
│  Estimado este mes:   €X,XXX                                │
│  Gastado real:        €X,XXX                                │
│  Diferencia:          +€XXX (por debajo ✅)                  │
│                       -€XXX (por encima ⚠️)                  │
│                                                              │
│  [Barra de progreso visual]                                  │
│  ████████████░░░░░░░░  65% del presupuesto usado            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Hoja 2: 📋 TRANSACCIONES

Todas las transacciones de ambas cuentas, normalizadas:

| Fecha | Concepto | Importe | Cuenta | Categoría | Persona | Recurrente | Match Estimado |
|---|---|---|---|---|---|---|---|
| 01/03 | BIZUM JUAN GARCIA | +80.00 | CaixaBank | Bizum Local | Juan | ✅ | - |
| 03/03 | SUPERMERCADO DIA | -45.32 | CaixaBank | Gasto Variable | - | ❌ | - |
| 05/03 | CUOTA PRESTAMO | +350.00 | Bankinter | Préstamo Propio | - | ✅ | - |
| 05/03 | SEGURO COCHE | -89.50 | CaixaBank | Gasto Fijo | - | ✅ | Seguro coche (est. €90) |

### Hoja 3: 🔄 FLUJO LOCAL (Madre)

Detalle específico del flujo del local:

```
MES: MARZO 2026

Transferencia a madre:                    -€XXX.XX
────────────────────────────────────────────────────
Bizums recibidos:
  ✅ Juan García        +€XX.XX   (recibido 01/03)
  ✅ Pedro López        +€XX.XX   (recibido 03/03)
  ⏳ Ana Martínez       +€XX.XX   (pendiente)
  ⏳ Carlos Ruiz        +€XX.XX   (pendiente)
────────────────────────────────────────────────────
Total bizums:                             +€XXX.XX
COSTE NETO PARA MANU:                    -€XXX.XX
```

### Hoja 4: 📅 GASTOS ESTIMADOS

Importada de la hoja de cálculo existente de Manu, con columna adicional de "real":

| Mes | Concepto | Fecha Prevista | Estimado | Real | Diferencia | Estado |
|---|---|---|---|---|---|---|
| Marzo | Seguro coche | 05/03 | €90.00 | €89.50 | +€0.50 | ✅ Pagado |
| Marzo | IBI | 15/03 | €180.00 | - | - | ⏳ Pendiente |
| Marzo | Internet | 20/03 | €45.00 | - | - | ⏳ Pendiente |

### Hoja 5: 📊 RESUMEN ANUAL

Vista de 12 meses con totales por categoría:

| | Ene | Feb | Mar | ... | Dic | TOTAL |
|---|---|---|---|---|---|---|
| Ingresos | X | X | X | ... | X | XX |
| Obligaciones | -X | -X | -X | ... | -X | -XX |
| Gastos fijos | -X | -X | -X | ... | -X | -XX |
| Gastos variables | -X | -X | -X | ... | -X | -XX |
| Coste neto local | -X | -X | -X | ... | -X | -XX |
| **NETO** | **X** | **X** | **X** | ... | **X** | **XX** |

### Hoja 6: ⚙️ CONFIG

Hoja de configuración editable directamente en Sheets:

| Parámetro | Valor | Notas |
|---|---|---|
| Transferencia madre | XXX | Cantidad fija mensual |
| Bizum Juan | XX | Fijo mensual |
| Bizum Pedro | XX | Fijo mensual |
| Día transferencia madre | 15 | Día del mes |
| Préstamo 1 cantidad | XXX | Cuota mensual |
| Préstamo 1 día | 5 | Día del mes |
| ... | ... | ... |

---

## 6. Scripts Python

### 6.1 Configuración central: `config.yaml`

```yaml
# ============================================================
# CONFIGURACIÓN DEL SISTEMA DE FLUJOS DE DINERO
# ============================================================
# ⚠️  Manu: personaliza TODOS los valores marcados con [PERSONALIZAR]

# --- Rutas ---
rutas:
  csv_dir: "/home/mleon/finanzas/csvs"          # [PERSONALIZAR] Donde guardas los CSVs
  output_dir: "/home/mleon/finanzas/output"      # [PERSONALIZAR] Salida procesada
  gastos_estimados: "/home/mleon/finanzas/gastos_estimados.csv"  # [PERSONALIZAR]

# --- Google Sheets ---
google_sheets:
  spreadsheet_id: "TU_SPREADSHEET_ID"           # [PERSONALIZAR] ID del Sheet
  credentials_path: "~/.config/gog/credentials"  # Ruta credenciales gog

# --- Cuentas ---
cuentas:
  caixabank:
    nombre: "CaixaBank"
    tipo_csv: "caixabank"
    # Formato CSV esperado: Fecha;Concepto;Importe;Saldo
    csv_encoding: "latin-1"
    csv_separator: ";"
    csv_date_format: "%d/%m/%Y"
    columnas:
      fecha: "Fecha"                             # [PERSONALIZAR] nombre columna
      concepto: "Concepto"                       # [PERSONALIZAR]
      importe: "Importe"                         # [PERSONALIZAR]
      saldo: "Saldo"                             # [PERSONALIZAR]
      
  bankinter:
    nombre: "Bankinter"
    tipo_csv: "bankinter"
    csv_encoding: "utf-8"
    csv_separator: ";"
    csv_date_format: "%d/%m/%Y"
    columnas:
      fecha: "F. Valor"                          # [PERSONALIZAR]
      concepto: "Concepto"                       # [PERSONALIZAR]
      importe: "Importe"                         # [PERSONALIZAR]
      saldo: "Saldo"                             # [PERSONALIZAR]

# --- Personas ---
personas:
  hermano:
    nombre: "NOMBRE_HERMANO"                     # [PERSONALIZAR]
    patrones_concepto:
      - "BIZUM.*NOMBRE"                          # [PERSONALIZAR] como aparece en extracto
      - "TRANSFERENCIA.*NOMBRE"
      
  madre:
    nombre: "NOMBRE_MADRE"                       # [PERSONALIZAR]
    patrones_concepto:
      - "TRANSFERENCIA.*NOMBRE"                  # [PERSONALIZAR]
      
  compañeros_local:                              # [PERSONALIZAR] todos los compañeros
    - nombre: "Juan García"
      patrones: ["BIZUM.*JUAN.*GARCIA", "BIZUM.*J.*GARCIA"]
      importe_fijo: 80.00                        # [PERSONALIZAR] cantidad fija
    - nombre: "Pedro López"
      patrones: ["BIZUM.*PEDRO.*LOPEZ"]
      importe_fijo: 80.00                        # [PERSONALIZAR]
    - nombre: "Ana Martínez"
      patrones: ["BIZUM.*ANA.*MARTINEZ"]
      importe_fijo: 65.00                        # [PERSONALIZAR]
    # Añadir todos los compañeros...

# --- Flujos recurrentes ---
flujos_recurrentes:
  prestamo_propio:
    tipo: "ingreso"
    cuenta: "bankinter"
    importe_esperado: 350.00                     # [PERSONALIZAR]
    dia_esperado: 5                              # [PERSONALIZAR]
    tolerancia_dias: 3
    tolerancia_importe: 0.05                     # 5%
    patrones: ["CUOTA.*PRESTAMO", "PRESTAMO.*CUOTA"]  # [PERSONALIZAR]
    
  prestamo_hermano:
    tipo: "ingreso_transitorio"
    cuenta: "bankinter"
    importe_esperado: 280.00                     # [PERSONALIZAR]
    dia_esperado: 5                              # [PERSONALIZAR]
    tolerancia_dias: 3
    patrones: ["CUOTA.*PRESTAMO.*2"]             # [PERSONALIZAR]
    contrapartida: "pago_hermano"
    
  devolucion_hermano:
    tipo: "ingreso"
    importe_variable: true
    importe_rango: [200, 400]                    # [PERSONALIZAR] rango esperado
    dia_esperado: 10                             # [PERSONALIZAR]
    tolerancia_dias: 5
    
  transferencia_madre:
    tipo: "obligacion"
    cuenta: "caixabank"
    importe_esperado: -500.00                    # [PERSONALIZAR] (negativo = salida)
    dia_esperado: 15                             # [PERSONALIZAR]
    tolerancia_dias: 3
    parcialmente_cubierta_por: "bizums_local"
    
  bizums_local:
    tipo: "ingreso_afectado"
    cuenta: "caixabank"
    cubre: "transferencia_madre"
    personas: ["compañeros_local"]               # referencia a la lista de arriba

# --- Alertas ---
alertas:
  telegram_chat_id: "6884477"                    # Chat ID de Manu
  # Umbrales
  gasto_vs_estimado_warning: 0.10               # Alerta si gastos superan 10% del estimado
  gasto_vs_estimado_critical: 0.25              # Alerta crítica si superan 25%
  saldo_minimo_caixabank: 500                    # [PERSONALIZAR]
  saldo_minimo_bankinter: 200                    # [PERSONALIZAR]
  dias_aviso_obligacion: 3                       # Avisar X días antes de una obligación
  bizum_no_recibido_dias: 5                      # Alertar si bizum no llega tras X días del esperado

# --- Formato ---
formato:
  moneda: "€"
  locale: "es_ES"
  separador_miles: "."
  separador_decimal: ","
```

### 6.2 Parser de CSVs bancarios: `csv_parser.py`

```python
#!/usr/bin/env python3
"""
csv_parser.py - Normaliza CSVs de CaixaBank y Bankinter
en un formato unificado para procesamiento.
"""

import pandas as pd
import yaml
import re
import os
import glob
from datetime import datetime
from pathlib import Path
from dataclasses import dataclass, asdict
from typing import List, Optional


@dataclass
class Transaccion:
    fecha: str                  # YYYY-MM-DD
    concepto: str
    importe: float
    saldo: Optional[float]
    cuenta: str                 # 'caixabank' | 'bankinter'
    categoria: str = ""
    subcategoria: str = ""
    es_recurrente: bool = False
    persona: str = ""
    gasto_estimado_id: str = ""
    notas: str = ""
    mes: str = ""               # YYYY-MM

    def __post_init__(self):
        if not self.mes and self.fecha:
            self.mes = self.fecha[:7]


def load_config(config_path: str = "config.yaml") -> dict:
    with open(config_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def parse_importe(valor: str) -> float:
    """Convierte string de importe español a float.
    Maneja: '1.234,56' → 1234.56 y '-45,32' → -45.32
    """
    if isinstance(valor, (int, float)):
        return float(valor)
    s = str(valor).strip()
    s = s.replace('.', '').replace(',', '.')
    s = s.replace('€', '').replace(' ', '')
    return float(s)


def parse_csv_caixabank(filepath: str, config: dict) -> List[Transaccion]:
    """Parsea CSV de CaixaBank."""
    cfg = config['cuentas']['caixabank']
    cols = cfg['columnas']
    
    df = pd.read_csv(
        filepath,
        encoding=cfg['csv_encoding'],
        sep=cfg['csv_separator'],
        dtype=str
    )
    
    # Limpiar nombres de columnas (espacios, BOM, etc.)
    df.columns = df.columns.str.strip().str.replace('\ufeff', '')
    
    transacciones = []
    for _, row in df.iterrows():
        try:
            fecha_str = row[cols['fecha']].strip()
            fecha = datetime.strptime(fecha_str, cfg['csv_date_format'])
            
            t = Transaccion(
                fecha=fecha.strftime('%Y-%m-%d'),
                concepto=row[cols['concepto']].strip(),
                importe=parse_importe(row[cols['importe']]),
                saldo=parse_importe(row[cols['saldo']]) if cols['saldo'] in row else None,
                cuenta='caixabank'
            )
            transacciones.append(t)
        except Exception as e:
            print(f"⚠️  Error parseando fila CaixaBank: {e} → {dict(row)}")
    
    return transacciones


def parse_csv_bankinter(filepath: str, config: dict) -> List[Transaccion]:
    """Parsea CSV de Bankinter."""
    cfg = config['cuentas']['bankinter']
    cols = cfg['columnas']
    
    df = pd.read_csv(
        filepath,
        encoding=cfg['csv_encoding'],
        sep=cfg['csv_separator'],
        dtype=str
    )
    
    df.columns = df.columns.str.strip().str.replace('\ufeff', '')
    
    transacciones = []
    for _, row in df.iterrows():
        try:
            fecha_str = row[cols['fecha']].strip()
            fecha = datetime.strptime(fecha_str, cfg['csv_date_format'])
            
            t = Transaccion(
                fecha=fecha.strftime('%Y-%m-%d'),
                concepto=row[cols['concepto']].strip(),
                importe=parse_importe(row[cols['importe']]),
                saldo=parse_importe(row[cols['saldo']]) if cols['saldo'] in row else None,
                cuenta='bankinter'
            )
            transacciones.append(t)
        except Exception as e:
            print(f"⚠️  Error parseando fila Bankinter: {e} → {dict(row)}")
    
    return transacciones


def parse_all_csvs(config: dict) -> List[Transaccion]:
    """Busca y parsea todos los CSVs en el directorio configurado."""
    csv_dir = config['rutas']['csv_dir']
    todas = []
    
    # Buscar CSVs de CaixaBank
    for f in glob.glob(os.path.join(csv_dir, "*caixa*"), recursive=False):
        if f.lower().endswith('.csv'):
            print(f"📄 Parseando CaixaBank: {f}")
            todas.extend(parse_csv_caixabank(f, config))
    
    # Buscar CSVs de Bankinter
    for f in glob.glob(os.path.join(csv_dir, "*bankinter*"), recursive=False):
        if f.lower().endswith('.csv'):
            print(f"📄 Parseando Bankinter: {f}")
            todas.extend(parse_csv_bankinter(f, config))
    
    # Ordenar por fecha
    todas.sort(key=lambda t: t.fecha)
    
    print(f"\n✅ Total transacciones parseadas: {len(todas)}")
    print(f"   CaixaBank: {sum(1 for t in todas if t.cuenta == 'caixabank')}")
    print(f"   Bankinter: {sum(1 for t in todas if t.cuenta == 'bankinter')}")
    
    return todas


def to_dataframe(transacciones: List[Transaccion]) -> pd.DataFrame:
    """Convierte lista de transacciones a DataFrame."""
    return pd.DataFrame([asdict(t) for t in transacciones])


if __name__ == "__main__":
    config = load_config()
    txns = parse_all_csvs(config)
    df = to_dataframe(txns)
    
    output = os.path.join(config['rutas']['output_dir'], 'transacciones_raw.csv')
    os.makedirs(os.path.dirname(output), exist_ok=True)
    df.to_csv(output, index=False, encoding='utf-8')
    print(f"\n💾 Guardado en: {output}")
```

### 6.3 Motor de categorización: `categorizer.py`

```python
#!/usr/bin/env python3
"""
categorizer.py - Clasifica transacciones automáticamente.

Niveles de prioridad:
1. Reglas exactas (config.yaml)
2. Detección de recurrencias
3. Fallback por tipo de transacción
"""

import re
import yaml
from typing import List, Dict, Optional, Tuple
from csv_parser import Transaccion, load_config
from collections import defaultdict
from datetime import datetime, timedelta


class Categorizer:
    def __init__(self, config: dict):
        self.config = config
        self.personas = config.get('personas', {})
        self.flujos = config.get('flujos_recurrentes', {})
        self._build_rules()
    
    def _build_rules(self):
        """Construye reglas de matching desde config."""
        self.rules = []
        
        # Reglas de flujos recurrentes
        for nombre, flujo in self.flujos.items():
            for patron in flujo.get('patrones', []):
                self.rules.append({
                    'patron': re.compile(patron, re.IGNORECASE),
                    'categoria': self._flujo_to_categoria(nombre, flujo),
                    'nombre_flujo': nombre,
                    'tipo': flujo['tipo'],
                    'cuenta_esperada': flujo.get('cuenta'),
                })
        
        # Reglas de personas (compañeros del local)
        for comp in self.personas.get('compañeros_local', []):
            for patron in comp.get('patrones', []):
                self.rules.append({
                    'patron': re.compile(patron, re.IGNORECASE),
                    'categoria': 'INGRESO_BIZUM_LOCAL',
                    'persona': comp['nombre'],
                    'importe_esperado': comp.get('importe_fijo'),
                    'tipo': 'ingreso_afectado',
                })
        
        # Hermano
        hermano = self.personas.get('hermano', {})
        for patron in hermano.get('patrones_concepto', []):
            self.rules.append({
                'patron': re.compile(patron, re.IGNORECASE),
                'categoria': 'INGRESO_DEVOLUCION_HERMANO',
                'persona': hermano.get('nombre', 'Hermano'),
                'tipo': 'ingreso',
            })
        
        # Madre
        madre = self.personas.get('madre', {})
        for patron in madre.get('patrones_concepto', []):
            self.rules.append({
                'patron': re.compile(patron, re.IGNORECASE),
                'categoria': 'SALIDA_MADRE',
                'persona': madre.get('nombre', 'Madre'),
                'tipo': 'obligacion',
            })
    
    def _flujo_to_categoria(self, nombre: str, flujo: dict) -> str:
        """Mapea nombre de flujo a categoría."""
        mapping = {
            'prestamo_propio': 'INGRESO_PRESTAMO_PROPIO',
            'prestamo_hermano': 'INGRESO_PRESTAMO_HERMANO',
            'devolucion_hermano': 'INGRESO_DEVOLUCION_HERMANO',
            'transferencia_madre': 'SALIDA_MADRE',
            'bizums_local': 'INGRESO_BIZUM_LOCAL',
        }
        return mapping.get(nombre, 'OTROS')
    
    def categorize(self, txn: Transaccion) -> Transaccion:
        """Aplica categorización a una transacción."""
        
        # Nivel 1: Reglas exactas
        for rule in self.rules:
            if rule['patron'].search(txn.concepto):
                # Verificar cuenta si se especifica
                if rule.get('cuenta_esperada') and rule['cuenta_esperada'] != txn.cuenta:
                    continue
                    
                txn.categoria = rule['categoria']
                txn.persona = rule.get('persona', '')
                txn.es_recurrente = True
                txn.notas = f"Match: regla '{rule.get('nombre_flujo', rule['categoria'])}'"
                return txn
        
        # Nivel 2: Heurísticas por tipo de concepto
        concepto_upper = txn.concepto.upper()
        
        # Transferencias entre cuentas propias
        if self._is_transferencia_propia(txn):
            txn.categoria = 'AHORRO'
            txn.notas = "Transferencia entre cuentas propias"
            return txn
        
        # Bizum genérico (no matcheado por reglas)
        if 'BIZUM' in concepto_upper:
            if txn.importe > 0:
                txn.categoria = 'INGRESO_OTROS'
                txn.notas = "Bizum entrante sin regla específica"
            else:
                txn.categoria = 'GASTO_VARIABLE'
                txn.notas = "Bizum saliente"
            return txn
        
        # Recibos domiciliados
        if any(kw in concepto_upper for kw in ['RECIBO', 'DOMICILIACION', 'ADEUDO']):
            txn.categoria = 'GASTO_FIJO_ESTIMADO'
            txn.notas = "Recibo - verificar contra gastos estimados"
            return txn
        
        # Nómina
        if any(kw in concepto_upper for kw in ['NOMINA', 'NÓMINA', 'SALARIO']):
            txn.categoria = 'INGRESO_NOMINA'
            txn.es_recurrente = True
            return txn
        
        # Compras con tarjeta
        if any(kw in concepto_upper for kw in ['COMPRA', 'TARJETA', 'TPV', 'PAGO EN']):
            txn.categoria = 'GASTO_VARIABLE'
            return txn
        
        # Nivel 3: Fallback
        if txn.importe > 0:
            txn.categoria = 'INGRESO_OTROS'
        else:
            txn.categoria = 'GASTO_VARIABLE'
        txn.notas = "Clasificación automática por signo"
        
        return txn
    
    def _is_transferencia_propia(self, txn: Transaccion) -> bool:
        """Detecta transferencias entre CaixaBank y Bankinter."""
        concepto = txn.concepto.upper()
        keywords = ['TRASPASO', 'TRANSFERENCIA PROPIA']
        # También se puede detectar si hay una transacción espejo
        # en la otra cuenta el mismo día por el mismo importe
        return any(kw in concepto for kw in keywords)
    
    def categorize_all(self, txns: List[Transaccion]) -> List[Transaccion]:
        """Categoriza todas las transacciones."""
        categorized = [self.categorize(t) for t in txns]
        
        # Detectar transferencias espejo entre cuentas
        categorized = self._detect_mirror_transfers(categorized)
        
        # Estadísticas
        stats = defaultdict(int)
        for t in categorized:
            stats[t.categoria] += 1
        
        print("\n📊 Categorización:")
        for cat, count in sorted(stats.items()):
            print(f"   {cat}: {count}")
        
        sin_clasificar = stats.get('OTROS', 0) + stats.get('', 0)
        total = len(categorized)
        pct = ((total - sin_clasificar) / total * 100) if total > 0 else 0
        print(f"\n   ✅ Clasificadas: {pct:.1f}%")
        
        return categorized
    
    def _detect_mirror_transfers(self, txns: List[Transaccion]) -> List[Transaccion]:
        """Detecta pares de transacciones que son transferencias entre cuentas propias."""
        by_date = defaultdict(list)
        for t in txns:
            by_date[t.fecha].append(t)
        
        for fecha, day_txns in by_date.items():
            if len(day_txns) < 2:
                continue
            caixa = [t for t in day_txns if t.cuenta == 'caixabank']
            bank = [t for t in day_txns if t.cuenta == 'bankinter']
            
            for tc in caixa:
                for tb in bank:
                    if abs(tc.importe + tb.importe) < 0.01:  # Espejo perfecto
                        if tc.categoria in ('', 'OTROS', 'GASTO_VARIABLE', 'INGRESO_OTROS'):
                            tc.categoria = 'AHORRO'
                            tc.notas = "Transferencia entre cuentas propias (espejo detectado)"
                        if tb.categoria in ('', 'OTROS', 'GASTO_VARIABLE', 'INGRESO_OTROS'):
                            tb.categoria = 'AHORRO'
                            tb.notas = "Transferencia entre cuentas propias (espejo detectado)"
        
        return txns
```

### 6.4 Detector de recurrencias: `recurrence_detector.py`

```python
#!/usr/bin/env python3
"""
recurrence_detector.py - Detecta transacciones recurrentes
basándose en patrones: misma cantidad, fecha similar, concepto similar.
"""

import re
from collections import defaultdict
from typing import List, Dict, Tuple
from csv_parser import Transaccion
from datetime import datetime
import difflib


class RecurrenceDetector:
    def __init__(self, config: dict):
        self.config = config
        self.tolerance_amount = 0.05    # 5% de variación
        self.tolerance_days = 5         # ±5 días
        self.min_occurrences = 2        # mínimo para considerar recurrente
    
    def detect(self, txns: List[Transaccion]) -> List[Transaccion]:
        """Detecta y marca transacciones recurrentes."""
        
        # Agrupar por concepto normalizado
        groups = self._group_by_similarity(txns)
        
        for group_name, group_txns in groups.items():
            if len(group_txns) < self.min_occurrences:
                continue
            
            # Verificar si los importes son consistentes
            importes = [t.importe for t in group_txns]
            if not self._amounts_consistent(importes):
                continue
            
            # Verificar si las fechas son periódicas (mensual)
            fechas = [datetime.strptime(t.fecha, '%Y-%m-%d') for t in group_txns]
            if self._is_monthly(fechas):
                for t in group_txns:
                    t.es_recurrente = True
                    if not t.notas:
                        t.notas = f"Recurrencia detectada: grupo '{group_name}'"
                    
                    # Si no tiene categoría, intentar asignar
                    if t.categoria in ('', 'OTROS', 'GASTO_VARIABLE', 'INGRESO_OTROS'):
                        if t.importe > 0:
                            t.categoria = 'INGRESO_RECURRENTE'
                        else:
                            t.categoria = 'GASTO_FIJO_ESTIMADO'
                        t.notas += " (auto-reclasificado)"
        
        return txns
    
    def _normalize_concepto(self, concepto: str) -> str:
        """Normaliza un concepto para agrupación."""
        s = concepto.upper()
        # Quitar números de referencia, fechas, etc.
        s = re.sub(r'\d{6,}', '', s)           # refs largas
        s = re.sub(r'\d{2}/\d{2}/\d{4}', '', s)  # fechas
        s = re.sub(r'\d{2}/\d{2}', '', s)      # fechas cortas
        s = re.sub(r'\s+', ' ', s).strip()
        return s
    
    def _group_by_similarity(self, txns: List[Transaccion]) -> Dict[str, List[Transaccion]]:
        """Agrupa transacciones por similitud de concepto."""
        groups = defaultdict(list)
        assigned = set()
        
        normalized = [(i, self._normalize_concepto(t.concepto)) for i, t in enumerate(txns)]
        
        for i, (idx_i, norm_i) in enumerate(normalized):
            if idx_i in assigned:
                continue
            
            group = [txns[idx_i]]
            assigned.add(idx_i)
            
            for j in range(i + 1, len(normalized)):
                idx_j, norm_j = normalized[j]
                if idx_j in assigned:
                    continue
                
                # Similitud > 80%
                ratio = difflib.SequenceMatcher(None, norm_i, norm_j).ratio()
                if ratio > 0.8:
                    group.append(txns[idx_j])
                    assigned.add(idx_j)
            
            if len(group) >= self.min_occurrences:
                groups[norm_i] = group
        
        return groups
    
    def _amounts_consistent(self, amounts: List[float]) -> bool:
        """Verifica si los importes son consistentes (dentro de tolerancia)."""
        if not amounts:
            return False
        avg = sum(amounts) / len(amounts)
        if avg == 0:
            return all(a == 0 for a in amounts)
        return all(abs(a - avg) / abs(avg) <= self.tolerance_amount for a in amounts)
    
    def _is_monthly(self, dates: List[datetime]) -> bool:
        """Verifica si las fechas siguen un patrón mensual."""
        if len(dates) < 2:
            return False
        
        dates_sorted = sorted(dates)
        days_of_month = [d.day for d in dates_sorted]
        
        # Verificar si caen en días similares del mes
        avg_day = sum(days_of_month) / len(days_of_month)
        return all(abs(d - avg_day) <= self.tolerance_days for d in days_of_month)
    
    def get_recurrence_report(self, txns: List[Transaccion]) -> str:
        """Genera un reporte de recurrencias detectadas."""
        recurrentes = [t for t in txns if t.es_recurrente]
        
        by_category = defaultdict(list)
        for t in recurrentes:
            by_category[t.categoria].append(t)
        
        lines = ["🔄 TRANSACCIONES RECURRENTES DETECTADAS", "=" * 50]
        
        for cat, cat_txns in sorted(by_category.items()):
            lines.append(f"\n📂 {cat}:")
            # Agrupar por concepto similar
            seen = {}
            for t in cat_txns:
                key = self._normalize_concepto(t.concepto)
                if key not in seen:
                    seen[key] = {'concepto': t.concepto, 'importes': [], 'fechas': [], 'persona': t.persona}
                seen[key]['importes'].append(t.importe)
                seen[key]['fechas'].append(t.fecha)
            
            for key, info in seen.items():
                avg = sum(info['importes']) / len(info['importes'])
                persona = f" ({info['persona']})" if info['persona'] else ""
                lines.append(f"   • {info['concepto'][:50]}{persona}")
                lines.append(f"     Importe medio: {avg:+.2f}€ | Ocurrencias: {len(info['importes'])}")
                lines.append(f"     Fechas: {', '.join(info['fechas'][:6])}")
        
        return '\n'.join(lines)
```

### 6.5 Comparador vs gastos estimados: `budget_matcher.py`

```python
#!/usr/bin/env python3
"""
budget_matcher.py - Compara transacciones reales contra
gastos estimados de la hoja de cálculo de Manu.
"""

import pandas as pd
import yaml
import re
from typing import List, Dict, Tuple, Optional
from csv_parser import Transaccion, load_config
from datetime import datetime, date
from dataclasses import dataclass
import difflib


@dataclass
class GastoEstimado:
    id: str
    mes: str            # YYYY-MM
    concepto: str
    fecha_prevista: str  # YYYY-MM-DD
    importe_estimado: float
    # Campos que se rellenan tras matching
    importe_real: Optional[float] = None
    fecha_real: Optional[str] = None
    transaccion_id: Optional[int] = None
    estado: str = "pendiente"  # pendiente | pagado | desviado
    diferencia: float = 0.0


class BudgetMatcher:
    def __init__(self, config: dict):
        self.config = config
        self.gastos_estimados: List[GastoEstimado] = []
        self._load_estimated()
    
    def _load_estimated(self):
        """Carga gastos estimados desde CSV/Sheet."""
        path = self.config['rutas']['gastos_estimados']
        
        try:
            df = pd.read_csv(path, encoding='utf-8')
        except:
            df = pd.read_csv(path, encoding='latin-1', sep=';')
        
        # Esperamos columnas: Mes, Concepto, Fecha, Importe
        # [PERSONALIZAR] Ajustar nombres de columnas
        for i, row in df.iterrows():
            ge = GastoEstimado(
                id=f"est_{i}",
                mes=str(row.get('Mes', '')),
                concepto=str(row.get('Concepto', '')),
                fecha_prevista=str(row.get('Fecha', '')),
                importe_estimado=float(str(row.get('Importe', 0)).replace('.', '').replace(',', '.').replace('€', ''))
            )
            self.gastos_estimados.append(ge)
        
        print(f"📅 Gastos estimados cargados: {len(self.gastos_estimados)}")
    
    def match(self, txns: List[Transaccion]) -> Tuple[List[Transaccion], List[GastoEstimado]]:
        """
        Intenta matchear transacciones reales con gastos estimados.
        Retorna transacciones actualizadas y gastos estimados con estado.
        """
        for ge in self.gastos_estimados:
            best_match = None
            best_score = 0
            
            for i, txn in enumerate(txns):
                if txn.gasto_estimado_id:  # Ya asignada
                    continue
                if txn.importe > 0:  # Los gastos son negativos
                    continue
                
                score = self._match_score(txn, ge)
                if score > best_score and score > 0.5:
                    best_score = score
                    best_match = i
            
            if best_match is not None:
                txn = txns[best_match]
                txn.gasto_estimado_id = ge.id
                txn.notas += f" | Match estimado: '{ge.concepto}' (score: {best_score:.2f})"
                
                ge.importe_real = txn.importe
                ge.fecha_real = txn.fecha
                ge.transaccion_id = best_match
                ge.diferencia = abs(txn.importe) - abs(ge.importe_estimado)
                
                if abs(ge.diferencia) / abs(ge.importe_estimado) < 0.10:
                    ge.estado = "pagado"
                else:
                    ge.estado = "desviado"
        
        return txns, self.gastos_estimados
    
    def _match_score(self, txn: Transaccion, ge: GastoEstimado) -> float:
        """Calcula score de matching entre transacción y gasto estimado."""
        score = 0.0
        
        # 1. Similitud de concepto (0-0.4)
        ratio = difflib.SequenceMatcher(
            None,
            txn.concepto.upper(),
            ge.concepto.upper()
        ).ratio()
        score += ratio * 0.4
        
        # 2. Similitud de importe (0-0.4)
        if ge.importe_estimado != 0:
            diff_pct = abs(abs(txn.importe) - abs(ge.importe_estimado)) / abs(ge.importe_estimado)
            if diff_pct < 0.05:
                score += 0.4
            elif diff_pct < 0.15:
                score += 0.3
            elif diff_pct < 0.30:
                score += 0.1
        
        # 3. Similitud de fecha (0-0.2)
        try:
            fecha_txn = datetime.strptime(txn.fecha, '%Y-%m-%d')
            fecha_est = datetime.strptime(ge.fecha_prevista, '%Y-%m-%d')
            diff_days = abs((fecha_txn - fecha_est).days)
            if diff_days <= 2:
                score += 0.2
            elif diff_days <= 5:
                score += 0.1
            elif diff_days <= 10:
                score += 0.05
        except:
            pass
        
        return score
    
    def get_monthly_comparison(self, mes: str) -> Dict:
        """Genera comparativa mensual estimado vs real."""
        mes_estimados = [ge for ge in self.gastos_estimados if ge.mes == mes or ge.fecha_prevista.startswith(mes)]
        
        total_estimado = sum(abs(ge.importe_estimado) for ge in mes_estimados)
        total_real = sum(abs(ge.importe_real) for ge in mes_estimados if ge.importe_real is not None)
        pagados = [ge for ge in mes_estimados if ge.estado == "pagado"]
        desviados = [ge for ge in mes_estimados if ge.estado == "desviado"]
        pendientes = [ge for ge in mes_estimados if ge.estado == "pendiente"]
        
        return {
            'mes': mes,
            'total_estimado': total_estimado,
            'total_real': total_real,
            'diferencia': total_real - total_estimado,
            'pct_desviacion': ((total_real - total_estimado) / total_estimado * 100) if total_estimado > 0 else 0,
            'pagados': len(pagados),
            'desviados': len(desviados),
            'pendientes': len(pendientes),
            'total_items': len(mes_estimados),
            'detalle_desviados': [
                {'concepto': ge.concepto, 'estimado': ge.importe_estimado, 'real': ge.importe_real, 'diff': ge.diferencia}
                for ge in desviados
            ],
            'detalle_pendientes': [
                {'concepto': ge.concepto, 'estimado': ge.importe_estimado, 'fecha': ge.fecha_prevista}
                for ge in pendientes
            ],
        }
```

### 6.6 Calculadora de saldos netos: `balance_calculator.py`

```python
#!/usr/bin/env python3
"""
balance_calculator.py - Calcula saldos netos reales,
teniendo en cuenta flujos cruzados y obligaciones pendientes.
"""

from typing import List, Dict
from csv_parser import Transaccion
from datetime import datetime, date
from collections import defaultdict


class BalanceCalculator:
    def __init__(self, config: dict):
        self.config = config
        self.flujos = config.get('flujos_recurrentes', {})
        self.alertas_config = config.get('alertas', {})
    
    def calculate_monthly(self, txns: List[Transaccion], mes: str) -> Dict:
        """Calcula el balance completo de un mes."""
        
        mes_txns = [t for t in txns if t.mes == mes]
        
        # --- Ingresos ---
        ingresos = {
            'nomina': sum(t.importe for t in mes_txns if t.categoria == 'INGRESO_NOMINA'),
            'prestamo_propio': sum(t.importe for t in mes_txns if t.categoria == 'INGRESO_PRESTAMO_PROPIO'),
            'prestamo_hermano': sum(t.importe for t in mes_txns if t.categoria == 'INGRESO_PRESTAMO_HERMANO'),
            'devolucion_hermano': sum(t.importe for t in mes_txns if t.categoria == 'INGRESO_DEVOLUCION_HERMANO'),
            'bizums_local': sum(t.importe for t in mes_txns if t.categoria == 'INGRESO_BIZUM_LOCAL'),
            'otros': sum(t.importe for t in mes_txns if t.categoria == 'INGRESO_OTROS'),
        }
        ingresos['total'] = sum(ingresos.values())
        
        # --- Salidas / Obligaciones ---
        salidas = {
            'madre_bruto': sum(t.importe for t in mes_txns if t.categoria == 'SALIDA_MADRE'),
            'madre_bizums': ingresos['bizums_local'],  # Lo que cubren los bizums
            'gastos_fijos': sum(t.importe for t in mes_txns if t.categoria == 'GASTO_FIJO_ESTIMADO'),
            'gastos_variables': sum(t.importe for t in mes_txns if t.categoria == 'GASTO_VARIABLE'),
        }
        salidas['madre_neto'] = salidas['madre_bruto'] + salidas['madre_bizums']  # Neto (bruto es negativo, bizums positivo)
        salidas['total'] = salidas['gastos_fijos'] + salidas['gastos_variables'] + salidas['madre_bruto']
        
        # --- Flujos transitarios (no afectan saldo real) ---
        transitorio = {
            'prestamo_hermano_entrada': ingresos['prestamo_hermano'],
            'prestamo_hermano_salida': sum(t.importe for t in mes_txns if t.categoria == 'SALIDA_HERMANO_PRESTAMO'),
            'transferencias_propias': sum(t.importe for t in mes_txns if t.categoria == 'AHORRO'),
        }
        
        # --- Balance neto ---
        # Dinero que realmente se "mueve" para Manu:
        dinero_real_entrada = (
            ingresos['nomina'] +
            ingresos['prestamo_propio'] +
            ingresos['devolucion_hermano'] +
            ingresos['otros']
            # NO incluir prestamo_hermano (transitorio)
            # NO incluir bizums_local (ya descontados en madre_neto)
        )
        
        dinero_real_salida = (
            salidas['madre_neto'] +    # Lo que Manu pone de su bolsillo
            salidas['gastos_fijos'] +
            salidas['gastos_variables']
        )
        
        neto = dinero_real_entrada + dinero_real_salida  # salida es negativo
        
        # --- Saldos por cuenta ---
        saldos_cuenta = {}
        for cuenta in ['caixabank', 'bankinter']:
            cuenta_txns = [t for t in mes_txns if t.cuenta == cuenta]
            if cuenta_txns:
                ultimo_saldo = next(
                    (t.saldo for t in sorted(cuenta_txns, key=lambda x: x.fecha, reverse=True) if t.saldo is not None),
                    None
                )
                saldos_cuenta[cuenta] = ultimo_saldo
        
        # --- Pendientes del mes ---
        pendientes = self._check_pendientes(mes_txns, mes)
        
        return {
            'mes': mes,
            'ingresos': ingresos,
            'salidas': salidas,
            'transitorio': transitorio,
            'dinero_real_entrada': dinero_real_entrada,
            'dinero_real_salida': dinero_real_salida,
            'neto': neto,
            'saldos_cuenta': saldos_cuenta,
            'saldo_total': sum(v for v in saldos_cuenta.values() if v is not None),
            'pendientes': pendientes,
            'coste_neto_local': salidas['madre_neto'],
        }
    
    def _check_pendientes(self, mes_txns: List[Transaccion], mes: str) -> List[Dict]:
        """Verifica qué flujos recurrentes faltan por llegar/salir."""
        pendientes = []
        hoy = date.today()
        
        for nombre, flujo in self.flujos.items():
            # Buscar si ya existe transacción de este flujo
            categoria_esperada = self._nombre_to_categoria(nombre)
            encontrada = any(t.categoria == categoria_esperada for t in mes_txns)
            
            if not encontrada:
                dia_esperado = flujo.get('dia_esperado', 0)
                importe = flujo.get('importe_esperado', 0)
                
                estado = 'pendiente'
                if hoy.day > dia_esperado + flujo.get('tolerancia_dias', 3):
                    estado = 'retrasado'
                
                pendientes.append({
                    'flujo': nombre,
                    'descripcion': categoria_esperada,
                    'importe_esperado': importe,
                    'dia_esperado': dia_esperado,
                    'estado': estado,
                })
        
        # Bizums del local: verificar cada compañero
        for comp in self.config.get('personas', {}).get('compañeros_local', []):
            encontrado = any(
                t.categoria == 'INGRESO_BIZUM_LOCAL' and t.persona == comp['nombre']
                for t in mes_txns
            )
            if not encontrado:
                pendientes.append({
                    'flujo': f"bizum_{comp['nombre']}",
                    'descripcion': f"Bizum de {comp['nombre']}",
                    'importe_esperado': comp.get('importe_fijo', 0),
                    'dia_esperado': None,
                    'estado': 'pendiente',
                })
        
        return pendientes
    
    def _nombre_to_categoria(self, nombre: str) -> str:
        mapping = {
            'prestamo_propio': 'INGRESO_PRESTAMO_PROPIO',
            'prestamo_hermano': 'INGRESO_PRESTAMO_HERMANO',
            'devolucion_hermano': 'INGRESO_DEVOLUCION_HERMANO',
            'transferencia_madre': 'SALIDA_MADRE',
        }
        return mapping.get(nombre, '')
    
    def format_summary(self, balance: Dict) -> str:
        """Formatea el balance en texto legible."""
        b = balance
        
        lines = [
            f"💰 RESUMEN FINANCIERO — {b['mes']}",
            "=" * 50,
            "",
            "📥 ENTRADAS:",
            f"   Nómina:              {b['ingresos']['nomina']:>+10.2f}€",
            f"   Préstamo propio:     {b['ingresos']['prestamo_propio']:>+10.2f}€",
            f"   Devolución hermano:  {b['ingresos']['devolucion_hermano']:>+10.2f}€",
            f"   Otros ingresos:      {b['ingresos']['otros']:>+10.2f}€",
            f"   ────────────────────────────────",
            f"   TOTAL ENTRADAS:      {b['dinero_real_entrada']:>+10.2f}€",
            "",
            "📤 SALIDAS:",
            f"   Madre (bruto):       {b['salidas']['madre_bruto']:>+10.2f}€",
            f"   Bizums compañeros:   {b['salidas']['madre_bizums']:>+10.2f}€",
            f"   → Coste NETO local:  {b['coste_neto_local']:>+10.2f}€",
            f"   Gastos fijos:        {b['salidas']['gastos_fijos']:>+10.2f}€",
            f"   Gastos variables:    {b['salidas']['gastos_variables']:>+10.2f}€",
            f"   ────────────────────────────────",
            f"   TOTAL SALIDAS:       {b['dinero_real_salida']:>+10.2f}€",
            "",
            f"💵 NETO DEL MES:        {b['neto']:>+10.2f}€",
            "",
            "🏦 SALDOS:",
        ]
        
        for cuenta, saldo in b['saldos_cuenta'].items():
            if saldo is not None:
                lines.append(f"   {cuenta.title():20s} {saldo:>10.2f}€")
        
        if b['saldos_cuenta']:
            lines.append(f"   ────────────────────────────────")
            lines.append(f"   TOTAL:               {b['saldo_total']:>10.2f}€")
        
        if b['pendientes']:
            lines.append("")
            lines.append("⏳ PENDIENTES:")
            for p in b['pendientes']:
                emoji = "⚠️" if p['estado'] == 'retrasado' else "⏳"
                lines.append(f"   {emoji} {p['descripcion']} ({p['importe_esperado']:+.2f}€) — {p['estado']}")
        
        # Flujos transitarios
        lines.append("")
        lines.append("🔄 TRANSITARIOS (no afectan tu bolsillo):")
        lines.append(f"   Préstamo hermano: {b['transitorio']['prestamo_hermano_entrada']:+.2f}€ → {b['transitorio']['prestamo_hermano_salida']:+.2f}€")
        
        return '\n'.join(lines)
```

### 6.7 Exportador a Google Sheets: `sheets_exporter.py`

```python
#!/usr/bin/env python3
"""
sheets_exporter.py - Exporta datos procesados a Google Sheets.
Usa la librería gspread con credenciales de servicio o gog CLI.
"""

import subprocess
import json
import os
from typing import List, Dict
from csv_parser import Transaccion, load_config
from datetime import datetime


class SheetsExporter:
    """
    Exporta datos al Google Sheet dashboard.
    
    Opciones de integración:
    1. gspread (librería Python) - más control
    2. gog CLI (ya instalado) - más simple
    
    Este script usa gog para simplicidad, con fallback a gspread.
    """
    
    def __init__(self, config: dict):
        self.config = config
        self.sheet_id = config['google_sheets']['spreadsheet_id']
    
    def export_via_gog(self, sheet_name: str, data: List[List[str]]):
        """Exporta datos usando gog CLI (Google Sheets)."""
        # Primero limpiar la hoja
        try:
            subprocess.run(
                ['gog', 'sheets', 'clear', self.sheet_id, f'--range={sheet_name}'],
                capture_output=True, text=True, check=True
            )
        except:
            pass  # La hoja puede no existir aún
        
        # Escribir datos fila por fila (o en batch)
        # gog sheets update <spreadsheet_id> --range="Hoja!A1" --values='[["a","b"],["c","d"]]'
        values_json = json.dumps(data)
        
        result = subprocess.run(
            ['gog', 'sheets', 'update', self.sheet_id,
             f'--range={sheet_name}!A1',
             f'--values={values_json}'],
            capture_output=True, text=True
        )
        
        if result.returncode != 0:
            print(f"⚠️  Error exportando a {sheet_name}: {result.stderr}")
            return False
        
        print(f"✅ Exportado a hoja '{sheet_name}'")
        return True
    
    def export_transactions(self, txns: List[Transaccion]):
        """Exporta todas las transacciones a la hoja TRANSACCIONES."""
        header = ['Fecha', 'Concepto', 'Importe', 'Cuenta', 'Categoría',
                  'Persona', 'Recurrente', 'Match Estimado', 'Notas']
        
        rows = [header]
        for t in txns:
            rows.append([
                t.fecha,
                t.concepto,
                f"{t.importe:.2f}",
                t.cuenta,
                t.categoria,
                t.persona,
                '✅' if t.es_recurrente else '',
                t.gasto_estimado_id,
                t.notas
            ])
        
        return self.export_via_gog('Transacciones', rows)
    
    def export_dashboard(self, balance: Dict):
        """Exporta el dashboard mensual."""
        b = balance
        
        rows = [
            ['💰 DASHBOARD FINANCIERO', '', b['mes']],
            [],
            ['📥 ENTRADAS', 'Importe', 'Estado'],
            ['Nómina', f"{b['ingresos']['nomina']:.2f}", ''],
            ['Préstamo propio', f"{b['ingresos']['prestamo_propio']:.2f}", ''],
            ['Devolución hermano', f"{b['ingresos']['devolucion_hermano']:.2f}", ''],
            ['Bizums compañeros', f"{b['ingresos']['bizums_local']:.2f}", ''],
            ['Otros', f"{b['ingresos']['otros']:.2f}", ''],
            ['TOTAL ENTRADAS', f"{b['dinero_real_entrada']:.2f}", ''],
            [],
            ['📤 SALIDAS', 'Importe', 'Estado'],
            ['Madre (bruto)', f"{b['salidas']['madre_bruto']:.2f}", ''],
            ['Bizums que cubren', f"{b['salidas']['madre_bizums']:.2f}", ''],
            ['→ Coste NETO local', f"{b['coste_neto_local']:.2f}", '⬅️ Lo que pones tú'],
            ['Gastos fijos', f"{b['salidas']['gastos_fijos']:.2f}", ''],
            ['Gastos variables', f"{b['salidas']['gastos_variables']:.2f}", ''],
            ['TOTAL SALIDAS', f"{b['dinero_real_salida']:.2f}", ''],
            [],
            ['💵 NETO DEL MES', f"{b['neto']:.2f}", ''],
            [],
            ['🏦 SALDOS', 'Importe', ''],
        ]
        
        for cuenta, saldo in b['saldos_cuenta'].items():
            if saldo is not None:
                rows.append([cuenta.title(), f"{saldo:.2f}", ''])
        
        rows.append(['TOTAL', f"{b['saldo_total']:.2f}", ''])
        
        if b['pendientes']:
            rows.append([])
            rows.append(['⏳ PENDIENTES', 'Importe', 'Estado'])
            for p in b['pendientes']:
                rows.append([p['descripcion'], f"{p['importe_esperado']:.2f}", p['estado']])
        
        return self.export_via_gog('Dashboard', rows)
    
    def export_local_flow(self, balance: Dict, txns: List[Transaccion], mes: str):
        """Exporta el detalle del flujo del local."""
        bizum_txns = [t for t in txns if t.categoria == 'INGRESO_BIZUM_LOCAL' and t.mes == mes]
        
        rows = [
            ['🔄 FLUJO LOCAL (MADRE)', '', mes],
            [],
            ['Transferencia a madre', f"{balance['salidas']['madre_bruto']:.2f}", ''],
            [],
            ['Bizums recibidos:', 'Importe', 'Fecha'],
        ]
        
        for t in bizum_txns:
            rows.append([f"  ✅ {t.persona}", f"{t.importe:.2f}", t.fecha])
        
        # Compañeros pendientes
        recibidos = {t.persona for t in bizum_txns}
        for comp in self.config.get('personas', {}).get('compañeros_local', []):
            if comp['nombre'] not in recibidos:
                rows.append([f"  ⏳ {comp['nombre']}", f"{comp['importe_fijo']:.2f}", 'PENDIENTE'])
        
        rows.append([])
        rows.append(['Total bizums', f"{balance['salidas']['madre_bizums']:.2f}", ''])
        rows.append(['COSTE NETO MANU', f"{balance['coste_neto_local']:.2f}", '← Lo que pagas tú'])
        
        return self.export_via_gog('Flujo Local', rows)
    
    def export_budget_comparison(self, comparison: Dict):
        """Exporta comparativa presupuesto vs real."""
        c = comparison
        
        rows = [
            ['📊 GASTOS vs ESTIMADO', '', c['mes']],
            [],
            ['Total estimado', f"{c['total_estimado']:.2f}", ''],
            ['Total real', f"{c['total_real']:.2f}", ''],
            ['Diferencia', f"{c['diferencia']:.2f}", f"{c['pct_desviacion']:.1f}%"],
            [],
            ['Estado', 'Cantidad', ''],
            ['✅ Pagados', str(c['pagados']), ''],
            ['⚠️ Desviados', str(c['desviados']), ''],
            ['⏳ Pendientes', str(c['pendientes']), ''],
        ]
        
        if c['detalle_desviados']:
            rows.append([])
            rows.append(['⚠️ DESVIACIONES', 'Estimado', 'Real', 'Diferencia'])
            for d in c['detalle_desviados']:
                rows.append([d['concepto'], f"{d['estimado']:.2f}", f"{d['real']:.2f}", f"{d['diff']:.2f}"])
        
        if c['detalle_pendientes']:
            rows.append([])
            rows.append(['⏳ PENDIENTES', 'Estimado', 'Fecha prevista'])
            for d in c['detalle_pendientes']:
                rows.append([d['concepto'], f"{d['estimado']:.2f}", d['fecha']])
        
        return self.export_via_gog('Presupuesto', rows)
```

### 6.8 Sistema de alertas: `alerts.py`

```python
#!/usr/bin/env python3
"""
alerts.py - Sistema de alertas inteligentes por Telegram.
"""

import requests
import json
from typing import List, Dict
from datetime import datetime, date, timedelta
from csv_parser import load_config


class AlertSystem:
    def __init__(self, config: dict):
        self.config = config
        self.alerts_config = config.get('alertas', {})
        self.chat_id = self.alerts_config.get('telegram_chat_id', '6884477')
    
    def send_telegram(self, message: str, silent: bool = False):
        """Envía mensaje por Telegram usando el bot de OpenClaw."""
        # Opción 1: Usar openclaw message (si está disponible)
        # Opción 2: Usar Bot API directamente
        # Opción 3: Escribir a fichero para que Lola lo envíe
        
        # Para integración con OpenClaw, escribimos el mensaje
        # y dejamos que el cron/Lola lo envíe
        alert_file = "/home/mleon/finanzas/output/pending_alerts.json"
        
        try:
            with open(alert_file, 'r') as f:
                alerts = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            alerts = []
        
        alerts.append({
            'timestamp': datetime.now().isoformat(),
            'message': message,
            'silent': silent,
            'sent': False,
        })
        
        with open(alert_file, 'w') as f:
            json.dump(alerts, f, indent=2, ensure_ascii=False)
        
        print(f"🔔 Alerta guardada: {message[:80]}...")
    
    def check_all(self, balance: Dict, budget_comparison: Dict) -> List[str]:
        """Ejecuta todos los checks de alerta."""
        alerts = []
        
        # 1. Saldo bajo
        alerts.extend(self._check_low_balance(balance))
        
        # 2. Gastos vs estimado
        alerts.extend(self._check_budget_deviation(budget_comparison))
        
        # 3. Obligaciones pendientes
        alerts.extend(self._check_pending_obligations(balance))
        
        # 4. Bizums no recibidos
        alerts.extend(self._check_missing_bizums(balance))
        
        # 5. Préstamos no recibidos
        alerts.extend(self._check_missing_loans(balance))
        
        # Enviar alertas
        for alert in alerts:
            self.send_telegram(alert)
        
        return alerts
    
    def _check_low_balance(self, balance: Dict) -> List[str]:
        alerts = []
        for cuenta, saldo in balance.get('saldos_cuenta', {}).items():
            if saldo is None:
                continue
            minimo = self.alerts_config.get(f'saldo_minimo_{cuenta}', 0)
            if saldo < minimo:
                alerts.append(
                    f"⚠️ SALDO BAJO en {cuenta.title()}: {saldo:.2f}€\n"
                    f"Mínimo configurado: {minimo:.2f}€"
                )
        return alerts
    
    def _check_budget_deviation(self, comparison: Dict) -> List[str]:
        alerts = []
        if not comparison:
            return alerts
        
        pct = comparison.get('pct_desviacion', 0)
        warning = self.alerts_config.get('gasto_vs_estimado_warning', 0.10) * 100
        critical = self.alerts_config.get('gasto_vs_estimado_critical', 0.25) * 100
        
        if pct > critical:
            alerts.append(
                f"🚨 GASTOS MUY POR ENCIMA del presupuesto ({comparison['mes']}):\n"
                f"Estimado: {comparison['total_estimado']:.2f}€\n"
                f"Real: {comparison['total_real']:.2f}€\n"
                f"Desviación: +{pct:.1f}%"
            )
        elif pct > warning:
            alerts.append(
                f"⚠️ Gastos por encima del presupuesto ({comparison['mes']}):\n"
                f"Estimado: {comparison['total_estimado']:.2f}€\n"
                f"Real: {comparison['total_real']:.2f}€\n"
                f"Desviación: +{pct:.1f}%"
            )
        
        return alerts
    
    def _check_pending_obligations(self, balance: Dict) -> List[str]:
        alerts = []
        hoy = date.today()
        dias_aviso = self.alerts_config.get('dias_aviso_obligacion', 3)
        
        for p in balance.get('pendientes', []):
            dia = p.get('dia_esperado')
            if dia and isinstance(dia, int):
                # ¿La obligación es pronto?
                if 0 < dia - hoy.day <= dias_aviso:
                    alerts.append(
                        f"📅 Obligación próxima: {p['descripcion']}\n"
                        f"Importe: {p['importe_esperado']:+.2f}€\n"
                        f"Día esperado: {dia} (en {dia - hoy.day} días)"
                    )
                # ¿Está retrasada?
                elif p.get('estado') == 'retrasado':
                    alerts.append(
                        f"⚠️ Flujo RETRASADO: {p['descripcion']}\n"
                        f"Importe esperado: {p['importe_esperado']:+.2f}€\n"
                        f"Día esperado: {dia} (hoy es {hoy.day})"
                    )
        
        return alerts
    
    def _check_missing_bizums(self, balance: Dict) -> List[str]:
        alerts = []
        hoy = date.today()
        dias_limite = self.alerts_config.get('bizum_no_recibido_dias', 5)
        
        for p in balance.get('pendientes', []):
            if 'bizum' in p['flujo'].lower():
                # Si estamos a más de X días del mes sin recibirlo
                if hoy.day > dias_limite:
                    alerts.append(
                        f"💸 Bizum pendiente: {p['descripcion']}\n"
                        f"Importe esperado: {p['importe_esperado']:.2f}€\n"
                        f"Día {hoy.day} del mes y aún no recibido"
                    )
        
        return alerts
    
    def _check_missing_loans(self, balance: Dict) -> List[str]:
        alerts = []
        for p in balance.get('pendientes', []):
            if 'prestamo' in p['flujo'].lower() and p.get('estado') == 'retrasado':
                alerts.append(
                    f"🏦 Préstamo no recibido: {p['descripcion']}\n"
                    f"Importe esperado: {p['importe_esperado']:+.2f}€\n"
                    f"Estado: RETRASADO"
                )
        
        return alerts
    
    def generate_monthly_report(self, balance: Dict, comparison: Dict) -> str:
        """Genera reporte mensual completo para Telegram."""
        b = balance
        c = comparison
        
        report = f"""📊 **REPORTE MENSUAL — {b['mes']}**

💰 **Resumen:**
• Entradas reales: {b['dinero_real_entrada']:+.2f}€
• Salidas reales: {b['dinero_real_salida']:+.2f}€
• **Neto: {b['neto']:+.2f}€**

🏦 **Saldos:**"""
        
        for cuenta, saldo in b['saldos_cuenta'].items():
            if saldo is not None:
                report += f"\n• {cuenta.title()}: {saldo:.2f}€"
        
        report += f"\n• **Total: {b['saldo_total']:.2f}€**"
        
        report += f"""

🏠 **Local (madre):**
• Transfer madre: {b['salidas']['madre_bruto']:.2f}€
• Bizums recibidos: +{b['salidas']['madre_bizums']:.2f}€
• **Coste neto: {b['coste_neto_local']:.2f}€**"""
        
        if c:
            emoji = "✅" if c['pct_desviacion'] <= 0 else "⚠️"
            report += f"""

📋 **Presupuesto:**
• Estimado: {c['total_estimado']:.2f}€
• Real: {c['total_real']:.2f}€
• Desviación: {c['pct_desviacion']:+.1f}% {emoji}
• Pagados: {c['pagados']}/{c['total_items']} | Pendientes: {c['pendientes']}"""
        
        if b['pendientes']:
            report += "\n\n⏳ **Pendientes:**"
            for p in b['pendientes']:
                emoji = "⚠️" if p['estado'] == 'retrasado' else "⏳"
                report += f"\n• {emoji} {p['descripcion']}: {p['importe_esperado']:+.2f}€"
        
        return report
```

### 6.9 Script principal: `main.py`

```python
#!/usr/bin/env python3
"""
main.py - Orquestador principal del sistema de flujos de dinero.

Uso:
  python main.py                    # Procesamiento completo
  python main.py --month 2026-03    # Mes específico
  python main.py --report           # Solo generar reporte
  python main.py --alerts           # Solo verificar alertas
"""

import argparse
import os
import sys
from datetime import datetime

from csv_parser import load_config, parse_all_csvs, to_dataframe
from categorizer import Categorizer
from recurrence_detector import RecurrenceDetector
from budget_matcher import BudgetMatcher
from balance_calculator import BalanceCalculator
from sheets_exporter import SheetsExporter
from alerts import AlertSystem


def main():
    parser = argparse.ArgumentParser(description='Sistema de Flujos de Dinero')
    parser.add_argument('--config', default='config.yaml', help='Ruta al config')
    parser.add_argument('--month', default=None, help='Mes a procesar (YYYY-MM)')
    parser.add_argument('--report', action='store_true', help='Solo generar reporte')
    parser.add_argument('--alerts', action='store_true', help='Solo verificar alertas')
    parser.add_argument('--no-sheets', action='store_true', help='No exportar a Sheets')
    parser.add_argument('--dry-run', action='store_true', help='No escribir nada')
    args = parser.parse_args()
    
    # Cargar configuración
    config = load_config(args.config)
    
    # Mes por defecto: actual
    mes = args.month or datetime.now().strftime('%Y-%m')
    print(f"🗓️  Procesando mes: {mes}")
    print("=" * 60)
    
    # 1. Parsear CSVs
    print("\n📂 Paso 1: Parseando CSVs...")
    txns = parse_all_csvs(config)
    
    if not txns:
        print("❌ No se encontraron transacciones. ¿Hay CSVs en el directorio?")
        sys.exit(1)
    
    # 2. Categorizar
    print("\n🏷️  Paso 2: Categorizando transacciones...")
    categorizer = Categorizer(config)
    txns = categorizer.categorize_all(txns)
    
    # 3. Detectar recurrencias
    print("\n🔄 Paso 3: Detectando recurrencias...")
    detector = RecurrenceDetector(config)
    txns = detector.detect(txns)
    print(detector.get_recurrence_report(txns))
    
    # 4. Matchear con gastos estimados
    print("\n📊 Paso 4: Comparando con gastos estimados...")
    matcher = BudgetMatcher(config)
    txns, gastos_estimados = matcher.match(txns)
    comparison = matcher.get_monthly_comparison(mes)
    
    # 5. Calcular balance
    print("\n💰 Paso 5: Calculando balance neto...")
    calculator = BalanceCalculator(config)
    balance = calculator.calculate_monthly(txns, mes)
    print(calculator.format_summary(balance))
    
    # 6. Exportar a Google Sheets
    if not args.no_sheets and not args.dry_run:
        print("\n📤 Paso 6: Exportando a Google Sheets...")
        exporter = SheetsExporter(config)
        exporter.export_transactions(txns)
        exporter.export_dashboard(balance)
        exporter.export_local_flow(balance, txns, mes)
        exporter.export_budget_comparison(comparison)
    
    # 7. Verificar alertas
    print("\n🔔 Paso 7: Verificando alertas...")
    alert_system = AlertSystem(config)
    triggered = alert_system.check_all(balance, comparison)
    
    if triggered:
        print(f"\n⚠️  {len(triggered)} alertas generadas")
        for a in triggered:
            print(f"   → {a[:80]}")
    else:
        print("   ✅ Sin alertas")
    
    # 8. Generar reporte
    if args.report or not args.alerts:
        report = alert_system.generate_monthly_report(balance, comparison)
        print("\n" + report)
        
        # Guardar reporte
        if not args.dry_run:
            output_dir = config['rutas']['output_dir']
            os.makedirs(output_dir, exist_ok=True)
            report_path = os.path.join(output_dir, f'reporte_{mes}.txt')
            with open(report_path, 'w', encoding='utf-8') as f:
                f.write(report)
            print(f"\n💾 Reporte guardado: {report_path}")
    
    # Guardar transacciones procesadas
    if not args.dry_run:
        df = to_dataframe(txns)
        output = os.path.join(config['rutas']['output_dir'], f'transacciones_{mes}.csv')
        df.to_csv(output, index=False, encoding='utf-8')
        print(f"💾 Transacciones guardadas: {output}")
    
    print("\n✅ Procesamiento completado")


if __name__ == '__main__':
    main()
```

---

## 7. Automatización (Crons)

### 7.1 Script de procesamiento diario

```bash
#!/bin/bash
# process_daily.sh - Procesamiento diario de finanzas
# Cron: 0 20 * * * /home/mleon/finanzas/process_daily.sh

set -euo pipefail

FINANZAS_DIR="/home/mleon/finanzas"
VENV="$FINANZAS_DIR/venv/bin/activate"
LOG="$FINANZAS_DIR/logs/daily_$(date +%Y-%m-%d).log"

mkdir -p "$FINANZAS_DIR/logs"

echo "=== Procesamiento diario $(date) ===" >> "$LOG"

# Activar virtualenv
source "$VENV"

# Ejecutar procesamiento
cd "$FINANZAS_DIR"
python main.py --config config.yaml 2>&1 >> "$LOG"

echo "=== Fin $(date) ===" >> "$LOG"
```

### 7.2 Script de reporte mensual

```bash
#!/bin/bash
# monthly_report.sh - Reporte mensual
# Cron: 0 10 1 * * /home/mleon/finanzas/monthly_report.sh

FINANZAS_DIR="/home/mleon/finanzas"
source "$FINANZAS_DIR/venv/bin/activate"

MES_ANTERIOR=$(date -d "1 month ago" +%Y-%m)

cd "$FINANZAS_DIR"
python main.py --config config.yaml --month "$MES_ANTERIOR" --report 2>&1
```

### 7.3 Script de alertas (más frecuente)

```bash
#!/bin/bash
# check_alerts.sh - Verificar alertas
# Cron: 0 9,14,20 * * * /home/mleon/finanzas/check_alerts.sh

FINANZAS_DIR="/home/mleon/finanzas"
source "$FINANZAS_DIR/venv/bin/activate"

cd "$FINANZAS_DIR"
python main.py --config config.yaml --alerts --no-sheets 2>&1
```

### 7.4 Resumen de crons

```
# Finanzas - Sistema de flujos de dinero
# ========================================
# Procesamiento completo diario (8 PM)
0 20 * * * /home/mleon/finanzas/process_daily.sh

# Alertas 3 veces al día (9 AM, 2 PM, 8 PM)
0 9,14,20 * * * /home/mleon/finanzas/check_alerts.sh

# Reporte mensual (día 1 de cada mes, 10 AM)
0 10 1 * * /home/mleon/finanzas/monthly_report.sh
```

### 7.5 Integración con Lola (OpenClaw)

Alternativa a crons independientes — Lola puede manejar todo esto:

```
# En HEARTBEAT.md, añadir:
## Finanzas
- Si hay alertas pendientes en /home/mleon/finanzas/output/pending_alerts.json → enviar por Telegram
- Día 1 del mes → ejecutar reporte mensual

# Como cron de OpenClaw:
openclaw cron add --schedule "0 20 * * *" --task "Procesa CSVs de finanzas y actualiza Google Sheets"
openclaw cron add --schedule "0 10 1 * *" --task "Genera y envía reporte mensual de finanzas"
```

---

## 8. Plan de Implementación

### Fase 0: Preparación (30 min)

- [ ] Crear directorio: `mkdir -p /home/mleon/finanzas/{csvs,output,logs}`
- [ ] Crear virtualenv: `python3 -m venv /home/mleon/finanzas/venv`
- [ ] Instalar dependencias: `pip install pandas pyyaml gspread`
- [ ] Descargar un CSV de ejemplo de cada banco
- [ ] Crear el Google Sheet (puede ser vacío)

### Fase 1: Configuración (1-2 horas)

- [ ] Copiar `config.yaml` y personalizar TODOS los `[PERSONALIZAR]`
- [ ] Verificar nombres de columnas de los CSVs reales
- [ ] Añadir patrones de concepto para cada persona/flujo
- [ ] Configurar importes de préstamos, bizums, transferencia madre
- [ ] Exportar gastos estimados a CSV

**Esto es lo más importante.** El sistema funciona tan bien como su configuración.

### Fase 2: Parser y categorización (1-2 horas)

- [ ] Copiar scripts Python al directorio
- [ ] Ejecutar `python csv_parser.py` con CSVs reales → verificar parsing
- [ ] Ejecutar `python main.py --dry-run` → revisar categorización
- [ ] Ajustar patrones en `config.yaml` para las transacciones mal clasificadas
- [ ] Iterar hasta tener >90% de clasificación correcta

### Fase 3: Google Sheets (1 hora)

- [ ] Crear Google Sheet con las hojas: Dashboard, Transacciones, Flujo Local, Presupuesto, Resumen Anual, Config
- [ ] Configurar `spreadsheet_id` en config
- [ ] Ejecutar exportación → verificar que los datos llegan
- [ ] Dar formato al Sheet (colores, anchos, condicionales)

### Fase 4: Alertas (30 min)

- [ ] Configurar umbrales de alertas
- [ ] Ejecutar `python main.py --alerts` → verificar que se generan correctamente
- [ ] Integrar envío con Telegram (vía Lola o Bot API)

### Fase 5: Automatización (30 min)

- [ ] Instalar crons (o configurar via OpenClaw)
- [ ] Probar ejecución automática
- [ ] Verificar logs

### Fase 6: Iteración (ongoing)

- [ ] Primer mes: revisar clasificaciones manualmente
- [ ] Ajustar patrones que fallen
- [ ] Añadir nuevas reglas según aparezcan transacciones no reconocidas
- [ ] Refinar umbrales de alertas

### Tiempo total estimado: 4-6 horas de setup inicial

---

## 9. Variables que Manu debe personalizar

### ⚠️ CRÍTICO — Sin esto el sistema no funciona

| Variable | Dónde | Qué poner |
|---|---|---|
| `rutas.csv_dir` | config.yaml | Ruta donde guardas los CSVs descargados |
| `rutas.gastos_estimados` | config.yaml | Ruta al CSV de gastos estimados del año |
| `google_sheets.spreadsheet_id` | config.yaml | ID del Google Sheet (de la URL) |
| Nombres de columnas CSV | config.yaml → cuentas | Los nombres exactos de las columnas de CaixaBank y Bankinter |
| `personas.hermano.nombre` | config.yaml | Nombre como aparece en los extractos |
| `personas.madre.nombre` | config.yaml | Nombre como aparece en los extractos |
| `personas.compañeros_local` | config.yaml | Lista completa de compañeros con nombre, patrones e importe fijo |

### 💰 Importes y fechas

| Variable | Dónde | Qué poner |
|---|---|---|
| `prestamo_propio.importe_esperado` | config.yaml | Cuota mensual del préstamo 1 |
| `prestamo_propio.dia_esperado` | config.yaml | Día del mes que entra |
| `prestamo_hermano.importe_esperado` | config.yaml | Cuota mensual del préstamo 2 |
| `transferencia_madre.importe_esperado` | config.yaml | Cantidad fija mensual (negativo) |
| `transferencia_madre.dia_esperado` | config.yaml | Día del mes que la haces |
| `devolucion_hermano.importe_rango` | config.yaml | Rango [min, max] de lo que devuelve |
| Importe de cada compañero | config.yaml → compañeros_local | Cantidad fija de cada bizum |

### 🔔 Alertas

| Variable | Dónde | Qué poner |
|---|---|---|
| `saldo_minimo_caixabank` | config.yaml | Saldo mínimo antes de alertar |
| `saldo_minimo_bankinter` | config.yaml | Saldo mínimo antes de alertar |
| `gasto_vs_estimado_warning` | config.yaml | % de desviación para warning (default 10%) |
| `gasto_vs_estimado_critical` | config.yaml | % de desviación para alerta crítica (default 25%) |

### 📄 Formato de CSVs

Manu necesita **descargar un CSV de cada banco** y verificar:
1. Qué separador usa (`;` o `,`)
2. Qué encoding tiene (abrir con notepad y ver si los acentos salen bien)
3. Cómo se llaman las columnas exactamente
4. Cómo formatea las fechas (`DD/MM/YYYY` o `YYYY-MM-DD`)
5. Cómo formatea los importes (`1.234,56` o `1234.56`)

### 📅 Gastos estimados

La hoja de cálculo existente de Manu necesita exportarse a CSV con estas columnas mínimas:
- **Mes** (o fecha)
- **Concepto** (nombre del gasto)
- **Fecha prevista** (DD/MM/YYYY)
- **Importe** (cantidad estimada)

---

## 10. FAQ y Troubleshooting

### "¿Y si un compañero no paga un mes?"

El sistema lo detecta como "pendiente" y te alerta. En el dashboard aparecerá como ⏳. El coste neto del local se recalcula automáticamente.

### "¿Y las transferencias entre mis cuentas?"

Se detectan como `AHORRO` y se marcan como neutras — no afectan al cálculo de gastos ni ingresos reales. El sistema busca "transferencias espejo" (misma cantidad, mismo día, cuentas diferentes).

### "¿Qué pasa si el banco cambia el formato del CSV?"

Tendrás que actualizar los nombres de columnas en `config.yaml`. El parser te avisará si no encuentra las columnas esperadas.

### "¿Puedo añadir categorías nuevas?"

Sí. Añade la categoría en `config.yaml` → `categorias` y crea reglas de matching. El sistema es extensible.

### "¿Qué pasa con el préstamo del hermano? Entra y sale."

Se trata como **flujo transitario**. Entra en Bankinter (categoría `INGRESO_PRESTAMO_HERMANO`) y tiene contrapartida (`SALIDA_HERMANO_PRESTAMO`). En el balance neto, se cancelan. En el dashboard se muestra separado para que veas que el flujo se ha completado.

### "¿Y si mi hermano me devuelve cantidades diferentes cada mes?"

El campo `importe_variable: true` con `importe_rango: [min, max]` permite esto. El sistema acepta cualquier cantidad dentro del rango. Si cae fuera, te alerta.

### "¿Cómo descargo los CSVs?"

- **CaixaBank:** CaixaBank Now → Cuentas → Movimientos → Descargar CSV
- **Bankinter:** Bankinter Online → Cuentas → Extracto → Exportar

Guárdalos en la carpeta `csv_dir` con nombres que contengan "caixa" o "bankinter" (el parser los detecta automáticamente).

### "¿Puedo automatizar la descarga de CSVs?"

Ni CaixaBank ni Bankinter tienen API pública. Las opciones son:
1. **Manual** (recomendado al principio): descargar cada 1-2 semanas
2. **Scraping con browser** (avanzado): usando Playwright/Selenium para login automático
3. **Open Banking / PSD2** (futuro): cuando haya agregadores tipo Nordigen/GoCardless que soporten estos bancos

Para empezar, **manual está bien**. El sistema procesa todo de golpe cuando subes los CSVs.

### "¿Y si una transacción se clasifica mal?"

Dos opciones:
1. **Mejorar la regla** en `config.yaml` (mejor a largo plazo)
2. **Corrección manual** en el Google Sheet — el sistema no sobreescribe correcciones manuales si añades una columna "Manual" = TRUE

---

## Estructura de ficheros final

```
/home/mleon/finanzas/
├── config.yaml              # ⚙️  Toda la configuración
├── main.py                  # 🚀 Script principal
├── csv_parser.py            # 📄 Parser de CSVs bancarios
├── categorizer.py           # 🏷️  Motor de categorización
├── recurrence_detector.py   # 🔄 Detector de recurrencias
├── budget_matcher.py        # 📊 Comparador vs estimados
├── balance_calculator.py    # 💰 Calculadora de saldos
├── sheets_exporter.py       # 📤 Exportador a Google Sheets
├── alerts.py                # 🔔 Sistema de alertas
├── process_daily.sh         # ⏰ Script cron diario
├── monthly_report.sh        # 📋 Script cron mensual
├── check_alerts.sh          # 🔔 Script cron alertas
├── requirements.txt         # 📦 pandas, pyyaml, gspread
├── venv/                    # 🐍 Virtual environment
├── csvs/                    # 📂 CSVs descargados de bancos
│   ├── caixabank_marzo_2026.csv
│   └── bankinter_marzo_2026.csv
├── output/                  # 📂 Salida procesada
│   ├── transacciones_2026-03.csv
│   ├── reporte_2026-03.txt
│   └── pending_alerts.json
└── logs/                    # 📂 Logs de ejecución
    └── daily_2026-03-02.log
```

---

> **Siguiente paso:** Manu revisa este documento, rellena las variables de personalización, y lo implementamos juntos paso a paso. Yo (Lola) puedo crear la estructura de directorios, copiar los scripts, y ayudar con la configuración inicial cuando esté listo.
