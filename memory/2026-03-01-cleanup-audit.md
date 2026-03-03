# 🧹 Auditoría Semanal de Limpieza - 2026-03-01

**Ejecutada:** Domingo, 1 de marzo 2026 - 22:00 (Madrid)  
**Estado:** ✅ REPORTE SIN CAMBIOS (datos solo para revisión)  
**Próxima auditoría:** Domingo, 8 de marzo 2026

---

## 📊 Resumen Ejecutivo

| Categoría | Hallazgo | Recomendación |
|-----------|----------|---------------|
| 🗂️ Instaladores | 0 encontrados | ✅ Limpio |
| 💾 Caché Total | **2.25 GB** | ⚠️ Revisar |
| 🚀 Procesos GNOME | 16 activos | ⚠️ Algunos innecesarios |
| 📁 Directorios grandes | 3 relevantes | 📝 Monitorear |

---

## 🔍 Hallazgos Detallados

### 1. Instaladores y Archivos Obsoletos

**Resultado:** ✅ NINGUNO encontrado

```
Búsqueda realizada:
find /home/mleon -maxdepth 3 -type f ( -name '*.deb' -o -name '*.AppImage' -o -name '*installer*' )
Resultado: 0 archivos
```

**Análisis:** Sistema limpio de instaladores huérfanos. Excelente estado.

---

### 2. Análisis de Caché (.cache)

**Tamaño total:** ~2.25 GB (con whisper incluido en cuenta)

#### Distribución por aplicación:

| Directorio | Tamaño | Estado | Recomendación |
|------------|--------|--------|---------------|
| `whisper` | 1.6 GB | ⏭️ EXCLUIR | Necesario para OpenAI Whisper (configurado) |
| `uv` | 324 MB | ⚠️ GRANDE | Caché de gestor Python - seguro limpiar |
| `google-chrome` | 154 MB | 📝 REVISAR | Caché del navegador - típico |
| `node-gyp` | 65 MB | ✅ NORMAL | Compilación de módulos Node - necesario |
| `Homebrew` | 52 MB | ✅ NORMAL | Gestor paquetes - esperado |
| `mesa_shader_cache` | 1.3 MB | ✅ NORMAL | Caché de gráficos |
| Otros (8 directorios) | <1 MB c/u | ✅ NORMAL | Mínimo |

**Análisis:**
- **Sin whisper:** ~650 MB (muy manejable)
- El caché de `uv` (324 MB) es candidato para limpieza si no se usa Python frecuentemente
- Chrome en 154 MB es normal para uso activo

---

### 3. Procesos GNOME/Evolution Ejecutándose

**Total activo:** 16 procesos de GNOME/Evolution

#### Procesos CRÍTICOS (mantener):

```
✅ at-spi2-registryd (2x - mleon + lightdm)     → Accesibilidad GNOME (necesario)
✅ gvfsd (3x)                                    → Virtual File System (necesario)
✅ gnome-keyring-daemon (2x)                    → Gestión de contraseñas (necesario)
```

#### Procesos OPCIONALES (considerar deshabilitar):

```
⚠️ evolution-alarm-notify                        → Notificaciones de calendario
⚠️ evolution-source-registry                     → Centro de datos Evolution
⚠️ evolution-calendar-factory                    → Factory de calendario
⚠️ evolution-addressbook-factory                 → Factory de contactos
⚠️ gvfs-udisks2-volume-monitor                  → Monitoreo USB/Storage
⚠️ gvfs-afc-volume-monitor                      → Monitoreo iPhone (poco usado)
⚠️ gvfs-gphoto2-volume-monitor                  → Monitoreo cámaras digitales
⚠️ gvfs-mtp-volume-monitor                      → Monitoreo Android (poco usado)
⚠️ gvfs-goa-volume-monitor                      → Monitoreo cuentas online
⚠️ gvfsd-trash                                  → Monitor de papelera
⚠️ gvfsd-metadata                               → Metadatos de archivos
```

**Ahorro potencial:** Desactivar Evolution + monitores opcionales → ~150 MB RAM

**Nota:** Solo deshabilitar si no usas Calendar, Contacts o gestión de dispositivos móviles.

---

### 4. Directorios Grandes en Home

| Ruta | Tamaño | Tipo | Recomendación |
|------|--------|------|---------------|
| `google-cloud-sdk` | 1.2 GB | Dev Tools | ⚠️ Revisar si activo |
| `go` | 942 MB | Lenguaje | ✅ Necesario si usas Go |
| `node_modules` | 188 MB | Dependencias | ✅ Esperado (npm global) |
| `.npm-global/openclaw` | 1.3 GB | OpenClaw | ✅ Necesario |
| `.cache` | 2.25 GB | Caché | 📝 Monitorear |

**Total acumulado analizado:** ~5.8 GB

**Análisis:**
- `google-cloud-sdk` (1.2 GB): ¿En uso? Si no → podría liberarse espacio
- `go` (942 MB): Mantener si usas Go
- OpenClaw + npm: Necesarios para operación

---

### 5. Descargador (Downloads)

**Tamaño:** 84 KB  
**Contenido:**
- `clawhub-review-es.html` (15 KB) - Viejo, podría archivarse
- `client_secret_*.json` (413 B) - **⚠️ SENSIBLE - Mantener seguro**
- `openclaw-extension/` - Extensión Chrome local

**Recomendación:** Archivo limpio. Considera mover `clawhub-review-es.html` a históricos si no se necesita.

---

### 6. Archivos Obsoletos Antiguos

**Búsqueda:** Archivos en .cache modificados hace >90 días  
**Resultado:** 0 encontrados

✅ Caché recientemente limpiado/regenerado. Buen signo.

---

## 🎯 Recomendaciones Priorizadas

### 🔴 URGENTE (Hacer pronto):
Ninguno. Sistema en buen estado.

### 🟡 DESEADO (Próximos 7 días):
1. **Analizar `google-cloud-sdk`:** ¿Se usa activamente? Si no, desinstalar (~1.2 GB ganados)
2. **Limpiar caché `uv`:** `rm -rf ~/.cache/uv` (~324 MB, regenerable) - solo si no usas Python regularmente

### 🟢 OPCIONAL (Cuando convenga):
3. **Deshabilitar Evolution innecesarios:** Si no usas Calendar/Contacts, deshabilitar los 11 procesos GNOME opcionales
4. **Archivar `clawhub-review-es.html`** desde Downloads

---

## 📈 Evolución Histórica

| Fecha | Total Caché | Procesos GNOME | Instaladores | Estado |
|-------|------------|-----------------|---------------|----|
| 2026-03-01 | 2.25 GB | 16 | 0 | ✅ Bueno |

---

## ✅ Validaciones Post-Auditoría

- [x] Sin instaladores obsoletos
- [x] Sin archivos >90 días sin tocar
- [x] Procesos críticos corriendo
- [x] Espacio en caché controlado
- [x] Downloads limpio
- [x] **Nada borrado** (solo reporte)

---

**Próxima revisión:** Domingo, 8 de marzo 2026, 22:00
