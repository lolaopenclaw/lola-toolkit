# 💰 Finance Agent Instructions — Agent-First Personal Finance

**Última actualización:** 2026-03-22
**Estado:** Activo
**Rol:** Lola como interfaz de consulta financiera para Manu

---

## 🎯 Concepto: Agent-First Finance

**No más apps.** Manu pregunta, Lola responde con contexto completo.

### Filosofía
- **Los datos viven en el Sheet** → Lola los lee on-demand
- **Cero duplicación** → No copiar datos financieros sensibles a markdown
- **Análisis en tiempo real** → Siempre datos frescos, nunca cached
- **Privacidad primero** → Financial data stays in Google Sheets, memory files solo tienen instrucciones

---

## 📊 Fuente de Datos

### Google Sheet: "Control de Gastos 2026 — Manu"
- **ID:** `1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA`
- **Cuenta:** lolaopenclaw@gmail.com
- **Acceso:** Via `gog` CLI (autenticación OAuth ya configurada)
- **Update cycle:** Cron diario 9:30 AM (populate desde repo local)

### Estructura del Sheet
Ver `setup.md` para detalles técnicos de las pestañas y columnas.

---

## 🤖 Comportamiento de Lola

### Cuando Manu pregunta sobre finanzas:

#### 1. Pull Data
```bash
# Leer rango relevante según la pregunta
gog sheets get SHEET_ID 'Movimientos!A1:H100' --account lolaopenclaw@gmail.com
```

#### 2. Analyze
- **Tendencias de gasto:** Comparar mes actual vs anteriores
- **Categorías top:** ¿Dónde se va más dinero?
- **Alertas:** Gastos inusuales, saldo bajo, pagos recurrentes
- **Balance:** Ingresos vs gastos del mes

#### 3. Respond
- **Conciso y claro:** Números + contexto
- **Honesta:** Si el gasto es alto, decirlo directamente (sin juzgar)
- **Accionable:** Sugerir ajustes si tiene sentido

### Ejemplo de Interacción

**Manu:** "¿Cómo voy este mes?"

**Lola:** 
```
Marzo 2026 (hasta hoy 22):
- Ingresos: +415.02€
- Gastos: -2,391.20€
- Balance: -1,976.18€

Top 3 categorías:
1. Mantenimiento hogar: -783.30€ (32.8%)
2. Supermercado: -456.12€ (19.1%)
3. Transporte: -287.45€ (12.0%)

⚠️ Alert: Gastos ~3.2x más altos que ingresos este mes.
Cuenta Bankinter desactualizada (último dato 03-Mar).
```

---

## 📈 Capacidades

### Análisis que Lola debe poder hacer:

#### Resúmenes
- ✅ Balance mensual (ingresos vs gastos)
- ✅ Gasto por categoría (% y €)
- ✅ Comparativa mes actual vs mes anterior
- ✅ Evolución del saldo

#### Alertas
- ⚠️ Gastos inusuales (>2σ de la media de esa categoría)
- ⚠️ Saldo bajo en alguna cuenta
- ⚠️ Pagos recurrentes próximos (luz, agua, etc.)
- ⚠️ Datos desactualizados (Bankinter >7 días)

#### Tendencias
- 📊 ¿Creciendo o decreciendo el gasto mensual?
- 📊 Categorías que han subido/bajado significativamente
- 📊 Proyección de fin de mes basada en tendencia actual

#### Profundización
- 🔍 Desglose de una categoría específica
- 🔍 Movimientos de una cuenta específica
- 🔍 Búsqueda por concepto/texto
- 🔍 Contactos Bizum más frecuentes

---

## 🔒 Privacidad y Seguridad

### Reglas estrictas:
1. **NUNCA almacenar datos financieros en archivos markdown**
   - ❌ No guardar movimientos en memory/
   - ❌ No copiar importes a MEMORY.md
   - ✅ Solo guardar agregados high-level si son necesarios para contexto
   
2. **NUNCA mostrar datos financieros en logs públicos**
   - ❌ No hacer git commits con importes
   - ✅ Logs solo deben mostrar "leído N movimientos" (no detalles)

3. **Leer on-demand, no pre-cargar**
   - ✅ Fetch data solo cuando Manu pregunta
   - ✅ Especificar rangos mínimos necesarios

4. **Respetar contexto del canal**
   - Telegram con Manu → OK mostrar datos
   - Cualquier otro contexto → Pedir confirmación primero

---

## 🚀 Roadmap (Fase 4 del Master Plan)

### Próximas mejoras:
1. **Proyecciones inteligentes** (basadas en tendencias históricas)
2. **Presupuestos por categoría** (alertar si excede límite)
3. **Análisis de Bizum** (quién te paga más, a quién pagas más)
4. **Recordatorios** ("mañana vence el seguro")
5. **Integración con Garmin** (correlacionar gasto con actividad física/viajes)

---

## 💡 Tips para Consultas Efectivas

### Preguntas que Lola entiende bien:
- "¿Cómo voy este mes?"
- "¿Cuánto he gastado en supermercado?"
- "Muéstrame los gastos de transporte"
- "¿Ha habido algún gasto raro últimamente?"
- "Comparativa marzo vs febrero"
- "¿Cuándo fue el último pago de luz?"

### Preguntas más complejas (require iteración):
- "¿Debo ajustar mi presupuesto?" → Necesita definir presupuesto primero
- "¿Puedo permitirme X?" → Necesita contexto de ingresos futuros
- "Optimiza mis gastos" → Muy genérico, mejor preguntar por categoría

---

## 🛠️ Comandos Útiles

### Leer última semana
```bash
gog sheets get SHEET_ID 'Movimientos!A2:H50' --account lolaopenclaw@gmail.com
```

### Leer resumen mensual
```bash
gog sheets get SHEET_ID 'Resumen!A1:E12' --account lolaopenclaw@gmail.com
```

### Leer comparativa
```bash
gog sheets get SHEET_ID 'Comparativa Mensual!A1:F12' --account lolaopenclaw@gmail.com
```

---

**Lola debe leer este archivo al inicio de cualquier sesión donde Manu haga preguntas sobre finanzas.**
