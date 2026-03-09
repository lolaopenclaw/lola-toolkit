# 🧹 Audit de Limpieza Semanal — Domingo 8 Marzo 2026

**Hora:** 22:00 Madrid | **Ejecutor:** Lola | **Acción:** Reporte solo (NO se borró nada)

---

## 📦 Instaladores y Archivos Obsoletos

✅ **Estado:** LIMPIO
- No se encontraron archivos `.deb`, `.AppImage`, ni `*installer*` en `/home/mleon` (hasta profundidad 3)
- **Acción recomendada:** Ninguna

---

## 💾 Caché — Análisis por Carpeta

| Carpeta | Tamaño | Descripción | Acción Recomendada |
|---------|--------|-------------|------------------|
| **whisper** | 1.6 GB | Modelos Whisper (speech-to-text) | ✅ MANTENER (en uso) |
| **google-chrome** | 598 MB | Caché navegador Chrome | 🟡 LIMPIABLE |
| **uv** | 324 MB | Caché gestor dependencias UV | 🟡 LIMPIABLE |
| **node-gyp** | 65 MB | Caché compilación nativa Node | 🟡 LIMPIABLE |
| **Homebrew** | 52 MB | Caché gestor paquetes Homebrew | 🟡 LIMPIABLE |
| **pip** | 36 MB | Caché gestor paquetes Python | 🟡 LIMPIABLE |
| **icon-cache.kcache** | 11 MB | Caché iconos | 🟢 SEGURO |
| **mesa_shader_cache** | 1.3 MB | Caché gráficos GPU | 🟢 SEGURO |
| **fontconfig** | 652 KB | Caché fuentes | 🟢 SEGURO |
| **Otros** (ksycoca, gstreamer, ibus, etc.) | ~1 MB | Varios servicios | 🟢 SEGURO |

**Subtotal limpiable:** ~1 GB

**Observación:** La carpeta `/home/mleon/.cache/` pesa **~2.8 GB total**, con **1.6 GB** siendo Whisper (legítimo).

---

## 🔧 Procesos Innecesarios Corriendo

### Evolution (Calendar/Contacts) — 6 procesos activos

```
mleon  1745  0.3%  evolution-alarm-notify (61 MB)
mleon  1868  0.2%  evolution-source-registry (43 MB)  
mleon  1963  0.1%  evolution-calendar-factory (24 MB)
mleon  1988  0.1%  evolution-addressbook-factory (30 MB)
```

**Status:** ⚠️ ACTIVOS PERO NO USADOS
- No hay cliente de Evolution abierto
- Estos daemons arrancan automáticamente con la sesión
- **Impacto:** ~160 MB de RAM constantemente reservada
- **Recomendación:** Desinstalar Evolution si no se usa, O desactivar autostart

### At-SPI2 (Accessibility Service) — 2 procesos

```
mleon  1454  0.0%  /usr/libexec/at-spi2-registryd (8 MB)
lightdm 1623  0.0%  /usr/libexec/at-spi2-registryd (8 MB)
```

**Status:** 🟢 NECESARIO
- Servicio de accesibilidad de GNOME
- Mínimo impacto, mantener

### GNOME Keyring — 2 procesos

```
lightdm  1564  0.0%  /usr/bin/gnome-keyring-daemon (10 MB)
mleon    3541  0.0%  /usr/bin/gnome-keyring-daemon (10 MB)
```

**Status:** 🟢 NECESARIO
- Gestor seguro de contraseñas y claves
- Requerido por muchas aplicaciones

---

## 📊 Espacio en Disco — Otros Hallazgos

### Skills de OpenClaw
- **Ubicación:** `~/.npm-global/lib/node_modules/openclaw/skills/`
- **Cantidad:** 55 skills instaladas
- **Peso:** 704 KB
- **Status:** 🟢 Muy compacto, MANTENER

### Archivos de Memoria (workspace)
- **Ubicación:** `~/.openclaw/workspace/memory/`
- **Peso:** 1.4 MB
- **Archivos:** 100 documentos
- **Status:** 🟢 Bien organizados, MANTENER

---

## 🎯 Resumen de Acciones

| Tema | Hallazgo | Recomendación | Urgencia |
|------|----------|---------------|----|
| Instaladores | No encontrados | Ninguna | ✅ OK |
| Caché limpiable | ~1 GB (no Whisper) | Limpiar Chrome, uv, pip | 🟡 Media |
| Evolution | ~160 MB + RAM | Desinstalar si no se usa | 🟡 Media |
| Whisper cache | 1.6 GB | Mantener (en uso) | ✅ OK |
| At-SPI2, Keyring | Necesarios | Mantener | ✅ OK |

---

## 💡 Próximos Pasos

- [ ] **Considerar:** `apt remove evolution evolution-data-server` si no se usan calendarios/contactos
- [ ] **Considerar:** Script de limpieza de caché: `rm -rf ~/.cache/{chrome,uv,pip}` (seguro, se regenera)
- [ ] **Monitor:** RAM si Evolution sigue en autostart

---

**Generado:** Domingo 8 Marzo 2026 — 22:00 | **Incluir en:** Informe matutino lunes 9 Marzo
