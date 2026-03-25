# 📑 Criterios de Categorización Financiera

**Establecido:** 4 Marzo 2026  
**Actualizado:** 24 Marzo 2026 (migración a estructura Markdown)  
**Mantenido por:** Lola + Manu

---

## 🔍 Categorías Principales

### 💰 INGRESOS

| Categoría | Descripción | Ejemplos |
|-----------|-------------|----------|
| **Nómina** | Salario mensual (CaixaBank + Bankinter) | Arsys Internet S.L.U. |
| **Ingresos extra** | Pagos únicos, beneficios, devoluciones | LEV 197544, Artistamente S.L. |
| **Bizum (recibidos)** | Transferencias recibidas vía Bizum | Compañeros local ensayo, familia |

### 📉 GASTOS

#### 🏠 Vivienda y Seguros
- **Préstamos hipotecarios** (Préstamo hipotecario)
- **Seguros** (VidaCaixa, SEVIAM PLUS, PACK MULTISEGUROS)
- **Comunidad** (CDAD PROP MANUEL DE FALLA 55)
- **Servicios básicos** (Luz: REPSOL/Endesa, Gas: ENERGIA XXI, Agua)
- **Seguridad** (SECURITAS DIRECT)
- **IBI y tasas** (Impuestos y tasas)

#### 💳 Financiación
- **MYCARD** — Cuota mensual tarjeta crédito
- **ONEY SERV.FIN.** — Tarjeta gasolina (históricamente)
- **COFIDIS AMAZON** — Compra financiada (históricamente)

#### 🏦 Préstamos
- **510326524** (Bankinter) — Préstamo del hermano (€125,98/mes)
- **510146351** (Bankinter) — Otro préstamo (€280,46/mes)

#### 🛒 Vida Diaria
- **Supermercado** (MERCADONA, LIDL, SIMPLY, etc.)
- **Bares y restaurantes** (Cafeterías, restaurantes)
- **Transporte** (Gasolina, MOVILIDAD MMD, ORA LOGROÑO, parking)
- **Telecomunicaciones** (DIGI SPAIN TELECOM)
- **Salud** (Farmacia, fisioterapia)

#### 🛍️ Compras
- **Compras online** (AMAZON, PAYPAL, TEMU, etc.)
- **Ropa y personal** (DECATHLON, PRIMARK, PAYPAL *PRIVALIA)

#### 🎭 Ocio
- **Ocio y cultura** (Cine, conciertos, libros)
- **Suscripciones** (PayPal Europe, Amazon Prime, etc.)

#### 📤 Transferencias
- **Bizum (enviados)** — Transferencias salientes
- **Transferencias internas** — Movimientos CaixaBank ↔ Bankinter

---

## 📊 Reglas de Categorización

### ✅ Ingresos

#### Bizums de 20€ a principios de mes
- **Origen:** Compañeros del local de ensayo (Cristian, Juan Jose, Enrique, Diego)
- **Naturaleza:** Ingreso recurrente que compensa transferencias a mamá
- **Categoría:** `Bizum (recibidos)`
- **Acción:** Registrar como ingreso legítimo

#### Nómina dividida
- **CaixaBank:** Parte mayor (ej. 1.739,95 €)
- **Bankinter:** Parte menor (ej. 936,90 €)
- **Timing:** Finales de mes (26-29 generalmente)
- **Categoría:** `Nómina`

---

### ❌ Gastos

#### Transferencias Internas (IGNORAR)
- **Naturaleza:** Ajustes entre cuentas propias
- **Acción:** **NO CONTAR** como gasto en análisis
- **Ejemplos:**
  - TRANS INM/ MANUEL LEON MENDIOL
  - MANUEL LEON MENDIOLA (de CaixaBank → Bankinter o viceversa)

#### Préstamos Bankinter
| Préstamo | Importe | Origen | Nota |
|----------|---------|--------|------|
| 510326524 | -125,98 € | Hermano | Deuda personal |
| 510146351 | -280,46 € | — | Otro préstamo |

**Categoría:** `Préstamos`

#### Financiación Completada (Histórico)
- **ONEY SERV.FIN.** (~111 €/mes) — Ya no activo
- **COFIDIS AMAZON** (~76 €/mes) — Ya no activo
- **Acción:** Mantener en histórico, no proyectar futuro

---

## 🔤 Palabras Clave

### Supermercado
`MERCADONA`, `LIDL`, `SIMPLY`, `SUPER HOGAR`, `KIKOS`

### Transporte
`MOVILIDAD MMD`, `MOVILIDAD ACM`, `ORA LOGRO`, `PARKIA`, `Gasolina`, `ONEY`, `AUTOIL`

### Mantenimiento hogar
`ELEC`, `AGUA`, `GAS`, `ENERGIA XXI`, `REPSOL ELECTRICIDAD`, `CDAD PROP`, `LEROY MERLIN`, `PROYECTA INGENIER`

### Bares y restaurantes
`CAFE`, `BAR`, `CAFETERIA`, `RESTAURANTE`, `PASTELERIA`, `PIZZERIA`

### Compras online
`AMAZON`, `PAYPAL`, `TEMU`, `PRIVALIA`, `WALLAPOP`, `DECATHLON` (online), `MGP*Wallapop`

### Seguros
`VidaCaixa`, `SEVIAM PLUS`, `PACK MULTISEGUROS`, `Endesa Energia SAU` (cuando es seguro)

### Salud
`FARMACIA`, `ANA SALAMERO FISI` (fisioterapia)

### Ocio y cultura
`CINES`, `BTN TOURS`, `CROCANTICKETS`, `MINAS DE MORIA`, `DNDBEYOND`

---

## 🎯 Casos Especiales

### Bizums sin concepto
- Si `Concepto = "Bizum"` y `Importe > 0` → `Bizum (recibidos)`
- Si `Concepto = "Bizum"` y `Importe < 0` → `Bizum (enviados)`

### Conceptos vacíos
- Buscar en categoría asignada por el sistema original
- Si no hay, inferir por importe/cuenta/contexto

### Cajero (efectivo)
- `REINT.CAJERO` → Retiro
- `INGRESO CAJERO` → Ingreso efectivo
- **Categoría:** `Cajero (efectivo)`

### Transferencias a Mamá
- `Bizum Margarita Mendiola Arbea` con concepto "Marzo", "Febrero", etc.
- **Categoría:** `Bizum (enviados)`
- **Nota:** Gasto fijo mensual (~140-205 €)

---

## 🚀 Actualizaciones Futuras

- [ ] Añadir presupuestos por categoría
- [ ] Alertas automáticas para gastos inusuales
- [ ] Proyecciones basadas en histórico
- [ ] Integración con Garmin (gastos de salud/fitness)

---

**Fuente de datos original:** Google Sheet ID `1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA`  
**Migración a Markdown:** 24 Marzo 2026  
**Próxima revisión:** Trimestral (Junio 2026)
