# 🧹 Cleanup Audit - 2026-03-29

**Fecha:** Domingo 29 marzo 2026, 22:01  
**Disco usado:** 88G / 464G (19%)

---

## 📊 Resumen Ejecutivo

**Estado general:** ✅ Sistema saludable  
**Basura crítica:** ❌ Ninguna  
**Oportunidades de limpieza:** 🟡 Moderadas (340 MB recuperables)

---

## 🗂️ Hallazgos por Categoría

### 1. Instaladores y Paquetes Obsoletos
- **Resultado:** ✅ No se encontraron `.deb`, `.AppImage` o instaladores en `/home/mleon` (depth 3)
- **Paquetes residuales:** 2 paquetes con configuración residual (`dpkg -l | grep ^rc`)
  - **Acción potencial:** `sudo dpkg --purge $(dpkg -l | grep ^rc | awk '{print $2}')`
  - **Espacio:** ~KB, despreciable

---

### 2. Cache (~/.cache/)

**Total cache:** ~550 MB (excluyendo whisper)

#### 🟢 Conservar (esenciales/activos):
- `google-chrome` — 146 MB (navegador activo)
- `pnpm` — 145 MB (gestor paquetes Node)
- `node-gyp` — 65 MB (compilación nativa Node)
- `Homebrew` — 53 MB (gestor paquetes)
- `chrome-cdp` — 48 MB (browser control server)
- `pip` — 12 MB (Python packages)
- `mesa_shader_cache` — 1.3 MB (GPU shaders)
- `fontconfig` — 652 KB (fuentes sistema)

#### 🟡 Limpiables (bajo riesgo):
- `icon-cache.kcache` — 11 MB (cachés iconos KDE, poco uso)
- `vscode-ripgrep` — 2 MB (binario ripgrep VSCode, regenerable)
- `yt-dlp` — 16 KB (metadata descargas, vaciar seguro)
- `deno` — 396 KB (runtime Deno, regenerable)
- `evolution` — 52 KB (cliente email, poco uso)

**Espacio recuperable:** ~15 MB (trivial)

---

### 3. Temporales (/tmp/)

#### 🔴 Limpiables (alta prioridad):
- `openclaw-backup-2026-03-26` — 84 MB
- `openclaw-backup-2026-03-27` — 85 MB
- `openclaw-backup-2026-03-28` — 85 MB
- `openclaw-backup-2026-03-29` — 85 MB
- **Total:** ~340 MB
- **Razón:** Backups diarios obsoletos (debería haber rotación automática)
- **Acción recomendada:** Configurar limpieza automática en script de backup

#### 🟢 Conservar:
- `memory-backup-*.tar.gz` — 2.6 MB (backups recientes memory/)
- `lola-toolkit-audit` — 3.3 MB (auditorías recientes)
- `openclaw/` — 6.4 MB (runtime temporal)

---

### 4. Logs del Sistema

- **Journald:** 923.8 MB
- **Evaluación:** Normal para sistema con uptime de 5+ días
- **Acción potencial:** `sudo journalctl --vacuum-time=7d` (conservar última semana)
- **Espacio recuperable:** ~300-500 MB (estimado)

---

### 5. Procesos y Memoria

#### 🔴 Alto consumo (legítimos):
- `openclaw-gateway` — 11.0% RAM (1.8 GB) — ✅ Esperado
- `chrome` — ~15% RAM total (múltiples procesos) — ✅ Navegador activo
- `Xtigervnc` (2 instancias) — 1.3% RAM — ✅ VNC sessions

#### 🟢 Servicios GNOME/X11:
- `unity-greeter` — 129 MB (lightdm, necesario para login gráfico)
- `xfwm4` (2 instancias) — 225 MB (window manager XFCE, sesiones VNC)
- `xfce4-session` (2 instancias) — 159 MB (sesiones VNC activas)

**Evaluación:** Todos procesos legítimos. No hay servicios innecesarios.

---

## 🎯 Recomendaciones Priorizadas

### Alta Prioridad
1. **Configurar rotación /tmp/openclaw-backup-***  
   - Espacio: ~340 MB inmediatos  
   - Script: `scripts/backup-*.sh` debería limpiar backups >3 días

### Media Prioridad
2. **Vacuum journald logs**  
   - Comando: `sudo journalctl --vacuum-time=7d`  
   - Espacio: ~400 MB  
   - Frecuencia: Mensual

### Baja Prioridad
3. **Limpiar paquetes residuales dpkg**  
   - Comando: `sudo dpkg --purge $(dpkg -l | grep ^rc | awk '{print $2}')`  
   - Espacio: Despreciable

---

## ✅ Conclusión

**Sistema limpio.** No hay basura crítica. Principal oportunidad: rotación automática de backups temporales (~340 MB).

**Próxima auditoría:** Domingo 2026-04-05 22:00
