# 💰 Finance System Setup — Technical Documentation

**Última actualización:** 2026-03-22
**Estado:** Operativo ✅
**Responsable:** Lola (agent-first interface)

---

## 🔧 Configuración Técnica

### Google Sheet Principal
- **Nombre:** Control de Gastos 2026 — Manu
- **ID:** `1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA`
- **URL:** https://docs.google.com/spreadsheets/d/1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA/edit
- **Cuenta de acceso:** lolaopenclaw@gmail.com
- **Locale:** es_ES
- **Timezone:** Europe/Madrid

### CLI Tool
- **Tool:** `gog` (Google CLI v0.12.0+)
- **Auth method:** OAuth2 (refresh token stored)
- **Keyring backend:** file (env-configured)
- **Credentials path:** `/home/mleon/.config/gogcli/credentials.json`

### Verificación de Acceso
```bash
# Status check
gog auth status

# List sheets
gog drive ls --account lolaopenclaw@gmail.com | grep "Control de Gastos"

# Metadata
gog sheets metadata 1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA --account lolaopenclaw@gmail.com
```

---

## 📊 Estructura del Spreadsheet

### Pestañas Disponibles

| ID | Nombre | Rows | Cols | Propósito |
|---|---|---|---|---|
| 44865282 | Resumen | 1000 | 26 | Vista general mensual |
| 182352981 | Resumen - Detalle | 1000 | 24 | Desglose detallado |
| 732348831 | **Movimientos** | 1000 | 26 | **Fuente principal: todos los movimientos** |
| 910877002 | Bizum | 1000 | 26 | Transferencias Bizum |
| 1451609628 | Contactos Bizum | 1000 | 26 | Directorio de contactos |
| 469784272 | 📊 Gastos por Categoría | 1000 | 26 | Dashboard categorías |
| 2120718717 | 📊 Ingresos vs Gastos | 1000 | 26 | Comparativa |
| 1868247363 | 📊 Balance Mensual | 1000 | 26 | Balance acumulado |
| 1333904637 | 📊 Evolución Saldo | 1000 | 26 | Histórico saldo |
| 282395880 | Comparativa Mensual | 1000 | 26 | Mes a mes |

---

## 📋 Esquema de Columnas

### Pestaña: "Movimientos" (Principal)

**Rango de cabecera:** `A1:H1` (hasta al menos columna H, puede haber más)

| Columna | Nombre | Tipo | Descripción | Ejemplo |
|---------|--------|------|-------------|---------|
| A | Fecha | Date | Fecha del movimiento | 17/03/2026 |
| B | Concepto | String | Descripción del movimiento | "ELEC REPSOL 4301430366" |
| C | Importe | Currency | Cantidad (negativo=gasto, positivo=ingreso) | -56,22 € |
| D | Saldo | Currency | Saldo después del movimiento | 0,00 € |
| E | Categoría | String | Categoría asignada | "Mantenimiento hogar" |
| F | Cuenta | String | Banco origen | "CaixaBank" o "Bankinter" |
| G | Persona | String | Contacto (para Bizum/transferencias) | (vacío o nombre) |
| H | Detalle | String | Notas adicionales | (opcional) |

**Nota:** Las columnas I-Z pueden contener fórmulas o datos adicionales, pero no son esenciales para las consultas básicas.

---

## 🔍 Comandos de Lectura

### Leer últimos movimientos
```bash
# Últimos 50 movimientos (ajustar según necesidad)
gog sheets get 1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA 'Movimientos!A1:H51' --account lolaopenclaw@gmail.com
```

### Leer rango específico
```bash
# Por fecha (ejemplo: primeros 100 de marzo)
gog sheets get 1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA 'Movimientos!A2:H100' --account lolaopenclaw@gmail.com
```

### Leer resumen mensual
```bash
gog sheets get 1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA 'Resumen!A1:E20' --account lolaopenclaw@gmail.com
```

### Leer comparativa mensual
```bash
gog sheets get 1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA 'Comparativa Mensual!A1:F12' --account lolaopenclaw@gmail.com
```

### Output JSON (para parsing)
```bash
gog sheets get SHEET_ID 'RANGE' --account lolaopenclaw@gmail.com --json
```

---

## 📁 Repositorio Local

### Proyecto GitHub
- **Repo:** github.com/lolaopenclaw/finanzas-personal (privado)
- **Local path:** `~/finanzas/`
- **Tech stack:** Python + pandas + Google Sheets API

### Update Pipeline
1. **Manu proporciona extractos** (CaixaBank, Bankinter) cada ~15 días
2. **Script local procesa** → JSON (movimientos_detallado.json)
3. **Cron diario 9:30 AM** → Populate Google Sheet via API
4. **Lola lee on-demand** → Via gog CLI

### Estado Actual (2026-03-22)
- ✅ CaixaBank: actualizado hasta 17-Mar-2026
- ⚠️ Bankinter: desactualizado (último dato 03-Mar-2026)
- ✅ Total movimientos: 418 (70 en marzo 2026)
- ✅ Cron operativo

---

## 🏦 Cuentas Bancarias Tracked

| Banco | Alias | Estado | Último Update |
|-------|-------|--------|---------------|
| CaixaBank | CaixaBank | ✅ Activo | 2026-03-17 |
| Bankinter | Bankinter | ⚠️ Desactualizado | 2026-03-03 |

---

## 📂 Categorías de Gastos

Las siguientes categorías están definidas en el sistema:

1. **Supermercado** — Compras alimentación
2. **Transporte** — Gasolina, parking, taxi
3. **Bares y restaurantes** — Comidas fuera
4. **Ocio y cultura** — Cine, conciertos, libros
5. **Mantenimiento hogar** — Luz, agua, gas, reparaciones
6. **Ropa** — Vestuario y calzado
7. **Salud** — Farmacia, médicos
8. **Tecnología** — Electrónica, software
9. **Viajes** — Hoteles, billetes
10. **Educación** — Cursos, formación
11. **Hogar** — Muebles, decoración
12. **Seguros** — Seguros varios
13. **Otros gastos** — Sin categorizar
14. **Transferencias** — Bizum y transferencias
15. **Ingresos** — Salario, ventas, etc.

---

## 🔐 Seguridad y Privacidad

### Datos Sensibles
- ⚠️ **Google Sheet contiene datos financieros reales**
- ⚠️ **Acceso restringido a lolaopenclaw@gmail.com**
- ⚠️ **No compartir Sheet ID públicamente**

### Best Practices
1. **No copiar datos financieros a markdown files**
2. **No hacer git commits con importes reales**
3. **Solo Lola y Manu tienen acceso al Sheet**
4. **Refresh token almacenado de forma segura (gog CLI keyring)**

---

## 🚨 Troubleshooting

### Error: "unexpected argument list"
**Causa:** Sintaxis incorrecta de gog CLI
**Solución:** 
```bash
# ❌ Incorrecto
gog sheets list --account lolaopenclaw@gmail.com

# ✅ Correcto
gog drive ls --account lolaopenclaw@gmail.com | grep "Control de Gastos"
```

### Error: Auth failure
**Causa:** Token expirado o revocado
**Solución:**
```bash
gog auth status
gog login lolaopenclaw@gmail.com
```

### Error: Sheet not found
**Causa:** ID incorrecto o permisos insuficientes
**Solución:**
1. Verificar ID correcto: `1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA`
2. Verificar acceso: `gog drive ls --account lolaopenclaw@gmail.com`

### Datos desactualizados
**Causa:** Bankinter no actualizado desde 03-Mar
**Solución:** Esperar que Manu proporcione extracto reciente

---

## 📈 Métricas de Uso

### Estado de implementación (2026-03-22)
- ✅ Google Sheet configurado
- ✅ gog CLI autenticado
- ✅ Estructura documentada
- ✅ Agent instructions creadas
- ⏳ **Pendiente:** Primera consulta real de Lola
- ⏳ **Pendiente:** Automatización de alertas
- ⏳ **Pendiente:** Dashboard en Canvas

---

## 🔄 Mantenimiento

### Tareas Recurrentes
- **Diario:** Cron 9:30 AM actualiza Sheet (automático)
- **Cada 15 días:** Manu proporciona extractos bancarios
- **Mensual:** Revisar completitud de datos
- **Trimestral:** Auditar categorías y ajustar si es necesario

### Próximas Mejoras (ver agent-instructions.md Roadmap)
- Proyecciones inteligentes
- Presupuestos por categoría
- Alertas proactivas
- Integración con Garmin

---

**Este documento es la fuente de verdad técnica para el sistema de finanzas agent-first.**
