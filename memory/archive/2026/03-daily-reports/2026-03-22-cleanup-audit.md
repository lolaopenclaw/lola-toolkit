# 🧹 Cleanup Audit - Domingo 22 Marzo 2026

**Hora:** 21:00 UTC | 22:00 Madrid  
**Estado del sistema:** 91GB / 464GB en uso (20%)

---

## 📦 Descargables Obsoletos (*.deb, *.AppImage, instaladores)

**Resultado:** ✅ **LIMPIOS** - No se encontraron archivos `.deb`, `.AppImage` o instaladores huérfanos en `/home/mleon` (maxdepth 3).

---

## 💾 Caché - Análisis Detallado

**Total en `~/.cache/`:** ~8.8GB

### ⚠️ CRÍTICOS (Basura Comprimible)

| Directorio | Tamaño | Estado | Nota |
|-----------|--------|--------|------|
| **pip** | 4.3GB | 🗑️ Reinstalable | Caché de paquetes Python. Safe to clear. |
| **google-chrome** | 1.4GB | 🗑️ Reinstalable | Caché del navegador. Seguro borrar. |
| **Homebrew** | 838MB | 🗑️ Reinstalable | Caché de paquetes Homebrew. Safe to clear. |
| **uv** | 324MB | 🗑️ Reinstalable | Caché de gestor Python uv. Puede regenerarse. |

**Subtotal recuperable:** **~6.9GB** (sin whisper, que es necesario para transcripción)

### 🟡 MODERADOS (Mantenidos, pero monitoreables)

| Directorio | Tamaño | Notas |
|-----------|--------|-------|
| **whisper** | 2.1GB | ✅ EXCLUIR - Necesario para STT, no tocar |
| **node-gyp** | 65MB | Caché de compilaciones Node, puede limpiar si falla build |
| **chrome-cdp** | 48MB | Protocol debugging, reinstalandose automáticamente |

### 🟢 PEQUEÑOS (Sin impacto)

- icon-cache.kcache: 11MB
- vscode-ripgrep: 2.0MB
- gstreamer: 412KB
- ibus, matplotlib, evolution, etc: < 100KB cada

---

## 🔴 Procesos GNOME/Desktop (Análisis)

**Hallazgo:** Múltiples procesos duplicados corriendo en paralelo, probablemente desde sesiones anteriores no limpias.

### Procesos Detectados

| Proceso | PID | Memoria | Tipo | ¿Necesario? |
|---------|-----|---------|------|------------|
| **at-spi2-registryd** | 1481, 1488, 1893 | 8-8.3MB c/u | Accessibility service | ⚠️ DUPLICADOS |
| **gnome-keyring-daemon** | 1781, 1970, 1976 | 7-9MB c/u | Key management | ⚠️ MÚLTIPLES |
| **evolution-alarm-notify** | 1974, 1985 | ~61MB c/u | Evolution mail daemon | 🗑️ INNECESARIO (no usas Evolution) |
| **evolution-source-registry** | 2245, 2279 | ~43MB c/u | Evolution registry | 🗑️ INNECESARIO (duplicado) |
| **evolution-calendar-factory** | 2443, 2446 | ~24MB c/u | Evolution calendar | 🗑️ INNECESARIO (no sincronizas) |
| **evolution-addressbook-factory** | 2579, 2584 | ~30MB c/u | Evolution contacts | 🗑️ INNECESARIO (no usas) |

### 🚨 RECOMENDACIÓN

**Evolution está bloateando el sistema:**
- **Total Evolution running:** ~6 procesos, ~200-250MB RAM
- **Uso real:** 0% (tú usas Gmail + Contacts vía `gog` CLI)
- **Acción sugerida:** Deshabilitar Evolution autostart o desinstalar si no sincronizas calendar/contacts localmente

**Keyring + at-spi duplicados:**
- Potencialmente sesiones fantasma desde reinicios incompletos
- **Acción sugerida:** `systemctl restart gnome-keyring` o reboot para limpiar

---

## 📊 Espacio Disponible

```
Total:     464GB
En uso:    91GB (20%)
Libre:     374GB
```

✅ **Abundante espacio.** No hay presión inmediata.

---

## 📋 Resumen & Recomendaciones

| Prioridad | Tarea | Impacto | Riesgo |
|-----------|-------|--------|--------|
| 🔴 ALTA | Deshabilitar/desinstalar Evolution services | Libre ~200MB RAM + reducir procesos | Bajo - no los usas |
| 🟡 MEDIA | Limpiar caché pip + chrome | Libre ~5.7GB disco | Muy bajo - se regeneran |
| 🟢 BAJA | Monitorear keyring duplicados | Diagnóstico mejor sesión startup | Bajo |

---

## ✅ Acción Inmediata

**NO BORRASTE NADA.** Reporte listo para decisión manual.

**Próximo paso:** Manu decide qué ejecutar. Sugerido:
1. Deshabilitar Evolution (systemctl --user disable evolution-alarm-notify, etc.)
2. Limpiar caché pip cuando necesites espacio: `rm -rf ~/.cache/pip`
3. Monitor: `ps aux | grep -E 'evolution|gnome-keyring' | wc -l`

---

**Reporte generado:** 2026-03-22 21:00 UTC  
**Para incluir en:** Informe matutino lunes
