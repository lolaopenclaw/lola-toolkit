# 💰 Finanzas Personal

**Sistema:** Local Markdown + Google Sheet (legacy)  
**Actualizado:** 2026-03-24  
**Estado:** ✅ Migrado a estructura Markdown

---

## 📁 Estructura de Archivos

### Archivos Principales

| Archivo | Propósito | Actualización |
|---------|-----------|---------------|
| `memory/finanzas/movimientos-2026.md` | Tabla completa con todos los movimientos | Manual (bajo demanda) |
| `memory/finanzas/resumen-mensual-2026.md` | Resumen por mes y categoría | Manual (bajo demanda) |
| `memory/finanzas/categorias.md` | Criterios de categorización | Manual (cuando cambian reglas) |
| `memory/finanzas/setup.md` | Documentación técnica del sistema | Manual (cambios de config) |
| `memory/finanzas/agent-instructions.md` | Instrucciones para Lola | Manual (cambios de workflow) |

---

## 📊 Datos Actuales (2026-03-24)

### General
- **Total movimientos:** 447 (desde 01/12/2025)
- **Rango:** 01/12/2025 → 17/03/2026
- **Cuentas:** CaixaBank + Bankinter

### Marzo 2026 (último mes completo)
- **Movimientos:** 76
- **Ingresos:** +572,23 €
- **Gastos:** -2.798,64 €
- **Balance:** -2.226,41 €

**Nota:** Los datos de Marzo están desactualizados (último dato: 17/03). Los totales pueden no cuadrar exactamente con el balance final del mes.

---

## 🔄 Workflow de Actualización

### 1. Descargar datos del Google Sheet

```bash
source ~/.bashrc && \
gog sheets get 1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA \
"Movimientos!A1:G500" -p > /tmp/finanzas_full.tsv
```

### 2. Procesar y generar Markdown

Ver script de referencia: `/tmp/process_full.py`

```bash
python3 /tmp/process_full.py
```

### 3. Copiar archivos generados

```bash
cp /tmp/movimientos-2026.md memory/finanzas/
cp /tmp/resumen-mensual-2026.md memory/finanzas/
```

### 4. Verificar totales

Comparar con datos esperados (ej. `memory/finanzas.md` anterior o resúmenes de Manu).

---

## 🎯 Migración Completada (24 Mar 2026)

✅ **Completado:**
- Descarga de 447 movimientos del Google Sheet
- Generación de `movimientos-2026.md` (tabla completa)
- Generación de `resumen-mensual-2026.md` (stats mensuales)
- Creación de `categorias.md` (criterios de categorización)
- Actualización de `memory/finanzas.md` (este archivo)

⏳ **Pendiente:**
- Decisión de Manu sobre desactivar cron del Google Sheet
- Actualización con datos completos de Marzo (hasta 31/03)
- Implementación de automatización para refresh periódico

---

## 📈 Fuente de Datos

### Google Sheet (Legacy)
- **ID:** `1otxo5V79XaY4GKCubCTrq19SaXdngcW59dGzZSUo8VA`
- **Hoja:** `Movimientos`
- **Cuenta:** lolaopenclaw@gmail.com
- **Cron:** Diario 9:30 AM (TODAVÍA ACTIVO)
- **Última sincronización:** 17/03/2026

**Nota:** El Google Sheet sigue siendo la fuente de verdad. Los Markdown files son **copias locales** para consulta rápida y análisis.

---

## 🔐 Seguridad

- ⚠️ Los archivos Markdown contienen **datos financieros reales**
- ⚠️ **NO commitear a repositorios públicos**
- ⚠️ Solo Lola y Manu tienen acceso
- ✅ Los archivos están en `.gitignore` del workspace

---

## 🚀 Próximos Pasos

1. **Automatización de refresh:** Script semanal/mensual para actualizar Markdown desde Sheet
2. **Dashboard en Canvas:** Visualización interactiva de gastos
3. **Alertas proactivas:** Notificar gastos inusuales o presupuestos superados
4. **Proyecciones:** Estimación de gastos futuros basado en histórico
5. **Integración Garmin:** Correlacionar gastos con métricas de salud

---

## 📚 Documentación Relacionada

- `memory/finanzas/setup.md` — Configuración técnica completa
- `memory/finanzas/agent-instructions.md` — Guía de uso para Lola
- `memory/archive/finances-criteria-2026-03-04.md` — Criterios originales (archivado)

---

**Sistema operativo desde:** 2026-03-24  
**Próxima revisión:** Fin de Marzo 2026 (datos completos del mes)
