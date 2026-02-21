# 🧹 Auditoría de Limpieza de Sistema - 21 feb 2026

## 📊 Resumen Ejecutivo
- **Espacio total identificado:** ~3.95 GB de archivos potencialmente removibles
- **Procesos sospechosos:** 12 servicios innecesarios activos
- **Archivos basura:** 2 instaladores + varios backups

---

## 📁 ARCHIVOS TEMPORALES Y BASURA

### 1. **Instaladores y paquetes** (NO NECESARIOS)
```
/home/mleon/google-chrome-stable_current_amd64.deb (67 MB)
  → Ya instalado via chrome-shim
  → ✅ SEGURO BORRAR
```

### 2. **Cache del Sistema** (SEGURO LIMPIAR)
```
/home/mleon/.cache/Homebrew/
  └─ portable-ruby-3.4.8.x86_64_linux.bottle.tar.gz (2.0 GB)
  → Descargado por Homebrew, pero ya instalado
  → ✅ SEGURO BORRAR

/home/mleon/.cache/whisper/ (1.6 GB)
  → Modelos de Whisper descargados
  → Útil si usas speech-to-text, pero parece offline
  → ⚠️ VERIFICA SI USAS WHISPER — si no, BORRAR

/home/mleon/.cache/google-chrome/ (1.0 GB)
  → Caché del navegador Chrome
  → ✅ SEGURO BORRAR (se reconstruye automáticamente)

/home/mleon/.cache/go-build/ (279 MB)
  → Caché de compilación Go
  → ✅ SEGURO BORRAR

/home/mleon/.cache/uv/ (79 MB)
  → Caché del gestor de paquetes UV
  → ✅ SEGURO BORRAR

/home/mleon/.cache/pip/ (20 MB)
  → Caché de pip (Python)
  → ✅ SEGURO BORRAR
```

**Total caché:** ~3.97 GB (prácticamente casi todo)

### 3. **Backups de configuración** (REVISAR)
```
/home/mleon/.claude.json.backup.1771410788172 (50 KB)
/home/mleon/.claude.json.backup.1771414340452 (2.6 KB)
  → Backups automáticos de Claude CLI
  → Innecesarios si no los usas
  → ✅ SEGURO BORRAR
```

### 4. **Directorios potencialmente removibles**
```
/home/mleon/.node-llama-cpp/ (tamaño pequeño)
  → Node.js bindings para Llama — no parece usarse
  → ⚠️ VERIFICA SI USAS

/home/mleon/.nvm/ (tamaño pequeño)
  → Node Version Manager
  → Solo borrar si no usas Node.js
  → ⚠️ PROBABLEMENTE NECESARIO (usado por OpenClaw)

/home/mleon/.npm/ (tamaño pequeño)
  → NPM global cache
  → ✅ SEGURO LIMPIAR (npm prune)
```

---

## 🔄 PROCESOS SOSPECHOSOS/INNECESARIOS

### Desktop Services (GNOME/Evolution) - Innecesarios en VPS Headless
```
PID 2542    gnome-keyring-daemon (10 MB)
            → Keyring para contraseñas en desktop
            → ✅ REMOVIBLE (usamos file-based keyring)

PID 183389  at-spi-bus-launcher (8.5 MB)
            → Accessibility service para GNOME
            → ✅ REMOVIBLE

PID 183485  system-config-printer applet (35 MB)
            → Interfaz de configuración de impresoras
            → ✅ REMOVIBLE

PID 183538  pulseaudio daemon (13 MB)
            → Servidor de audio
            → ✅ REMOVIBLE (no hay audio en VPS)

PID 183541  dconf-service (5.9 MB)
            → Almacén de configuración GNOME
            → ✅ REMOVIBLE

PID 183587  evolution-source-registry (43 MB)
            → Gestor de calendarios/contactos de GNOME
            → ✅ REMOVIBLE

PID 183694  evolution-calendar-factory (24 MB)
            → Factory de calendarios Evolution
            → ✅ REMOVIBLE

PID 183739  evolution-addressbook-factory (30 MB)
            → Factory de contactos Evolution
            → ✅ REMOVIBLE
```

### GVFS Monitors (Gestión de volúmenes)
```
PID 183432  gvfsd (8.1 MB)
PID 183530  gvfs-udisks2-volume-monitor (10 MB)
PID 183590  gvfs-afc-volume-monitor (8.1 MB)
PID 183607  gvfs-gphoto2-volume-monitor (6.6 MB)
PID 183621  gvfs-mtp-volume-monitor (6.5 MB)
PID 183634  gvfs-goa-volume-monitor (6.5 MB)
PID 183726  gvfsd-metadata (6.6 MB)
PID 183690  gvfsd-trash (8.9 MB)

            → Monitores de sistemas de archivos GNOME
            → Para cámaras, dispositivos USB, etc.
            → ✅ REMOVIBLES (no conectas dispositivos USB)
```

### D-Bus Daemons (Múltiples instancias)
```
5 instancias de dbus-daemon de Linuxbrew
            → Probablemente redundantes
            → ⚠️ VERIFICA — algunos pueden ser necesarios
```

**Resumen procesos:** ~200 MB de memoria en servicios GNOME innecesarios

---

## 🎯 RECOMENDACIONES POR CATEGORÍA

### BORRAR SIN DUDAS (Total: ~3.97 GB)
- [ ] `/home/mleon/google-chrome-stable_current_amd64.deb`
- [ ] `/home/mleon/.cache/Homebrew/portable-ruby-*`
- [ ] `/home/mleon/.cache/google-chrome/`
- [ ] `/home/mleon/.cache/go-build/`
- [ ] `/home/mleon/.cache/uv/`
- [ ] `/home/mleon/.cache/pip/`
- [ ] `/home/mleon/.claude.json.backup.*`
- [ ] Limpiar `/home/mleon/.cache/fontconfig/`
- [ ] Limpiar `/home/mleon/.cache/gstreamer-1.0/`

### REVISAR CON MANU
- [ ] `/home/mleon/.cache/whisper/` (1.6 GB) — ¿Usas Whisper?
- [ ] `/home/mleon/.node-llama-cpp/` — ¿Para qué?
- [ ] Múltiples dbus-daemon de Linuxbrew — ¿Necesarios?

### SERVICIOS A DESABILITAR/REMOVER
- [ ] `gnome-keyring-daemon` → Usar keyring file-based
- [ ] `at-spi-bus-launcher` → Accesibilidad (no necesaria)
- [ ] `system-config-printer` → Impresoras (no necesarias)
- [ ] `pulseaudio` → Audio (no necesario)
- [ ] `dconf-service` → GNOME config
- [ ] `evolution-*` servicios → Calendar/Contacts (no necesarios)
- [ ] `gvfs-*` monitors → Gestión de volúmenes (no necesaria)

---

## ⚠️ NOTAS IMPORTANTES

1. **Whisper (1.6 GB):** ¿Usas speech-to-text? Si no, es basura pura.
2. **Homebrew:** Instaló ruby portable gigante, ya que Node.js está en NVM.
3. **GNOME/Evolution:** Toda esta infraestructura es para desktop, completamente innecesaria en VPS headless.
4. **D-Bus:** Hay demasiadas instancias, probablemente por arranques múltiples.

---

## 📈 POTENCIAL LIBERADO
- **Espacio en disco:** ~4 GB (liberados)
- **Memoria RAM:** ~200 MB (liberados)
- **Procesos:** 12 → posibilidad de streamline

**¿Cómo ves? ¿Borro todo lo que marca ✅?**
