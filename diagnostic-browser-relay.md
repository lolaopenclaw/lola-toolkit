# 🔍 Diagnóstico: Error de Extensión Chrome Browser Relay - OpenClaw

**Fecha:** 2026-02-22 22:39 GMT+1  
**Versión OpenClaw:** 2026.2.17  
**Navegador:** Chrome 145 (via chrome-shim)  
**Estado del Gateway:** ✅ Ejecutándose

---

## 🚨 PROBLEMA IDENTIFICADO

**Error exacto:**
```
Chrome extension relay is running, but no tab is connected. 
Click the OpenClaw Chrome extension icon on a tab to attach it (profile "chrome").
```

**Causa raíz:** La extensión Browser Relay de OpenClaw está escuchando en el puerto 18792, pero **ninguna pestaña de Chrome tiene la extensión instalada o activada**.

---

## 📊 HALLAZGOS TÉCNICOS

### 1. Estado del Gateway ✅
- **Puerto 18789:** Gateway principal (loopback)
- **Puerto 18792:** Relay de la extensión Chrome
- **Puerto 18800:** Navegador administrado por OpenClaw (perfil "openclaw")
- **Estado RPC:** OK
- **Servicio:** Running (PID 13200)

### 2. Perfiles de Navegador Disponibles

```
openclaw: running (2 tabs) [default]
  ✅ Navegador administrado, aislado, sin extensión requerida
  Puerto: 18800

chrome: running (0 tabs)  ⚠️ 
  ❌ Requiere extensión Browser Relay
  Puerto: 18792
  Estado: SIN TABS CONECTADOS
```

### 3. Configuración Actual (openclaw.json)

```json
{
  "browser": {
    "enabled": true,
    "executablePath": "/usr/local/bin/chrome-shim",
    "headless": true,
    "noSandbox": true,
    "defaultProfile": "openclaw"  // ✅ Está configurado correctamente
  }
}
```

### 4. Extensiones Chrome Instaladas

Se encontraron dos extensiones en `~/.config/google-chrome/Default/Extensions/`:
- **ghbmnnjooekpmoecnnnilnnbdlolhkhi** = Google Docs (no relevante)
- **nmmhkkegccagdldgiimedpiccmgmieda** = Chrome Web Store (no es la OpenClaw relay)

**❌ CONCLUSIÓN:** La extensión Browser Relay de OpenClaw **NO está instalada**.

---

## 🎯 CAUSA: Dos Escenarios Posibles

### Escenario 1: Se está forzando el perfil "chrome"
**Síntoma:** Alguien llamó `browser(profile="chrome", ...)` en lugar de usar el default  
**Solución:** Usar `profile="openclaw"` o dejar el default

### Escenario 2: La extensión Browser Relay no está disponible
**Síntoma:** La extensión se intenta usar pero no está instalada  
**Causa:** 
- La extensión Browser Relay puede no estar en Chrome Web Store (algunos reportes lo confirman)
- Instalación manual fallida o incompleta

**Solución:** Usar el perfil administrado `openclaw` (recomendado)

### Escenario 3: Problema de conexión entre extension y gateway
**Síntoma:** Extensión instalada pero sin tabs conectados  
**Causa:**
- Token/autenticación no configurado en la extensión
- Extensión deshabilitada
- Incompatibilidad de versión (Chrome 145 vs OpenClaw 2026.2.17)

---

## 📋 PASOS PARA REPRODUCIR EL ERROR

```bash
# Esto causará el error:
openclaw browser action=open profile="chrome" targetUrl="https://example.com"

# Resultado:
# Error: Chrome extension relay is running, but no tab is connected.
# Click the OpenClaw Chrome extension icon on a tab to attach it (profile "chrome").
```

**Razón:** El gateway intenta conectar al puerto 18792 (relay), pero no hay ningún tab de Chrome con la extensión instalada/conectada.

---

## ✅ SOLUCIONES RECOMENDADAS

### OPCIÓN A: Usar el Perfil Administrado (RECOMENDADO)
**Ventaja:** Sin extensiones, sin configuración extra, funciona out-of-the-box

```bash
# Este perfil ya está funcionando:
openclaw browser profiles

# Output: openclaw: running (2 tabs) ✅

# Usar en llamadas:
browser(action="open", profile="openclaw", targetUrl="https://example.com")

# O simplemente dejar el default (ya es "openclaw"):
browser(action="open", targetUrl="https://example.com")
```

**Estado actual:** ✅ **YA FUNCIONA** - 2 tabs activos en el perfil `openclaw`

---

### OPCIÓN B: Instalar la Extensión Browser Relay (Si es necesario)

#### Paso 1: Verificar disponibilidad
```bash
# Revisar si está en Chrome Web Store:
# ID de la extensión: nmmhkkegccagdldgiimedpiccmgmieda (pero eso es Web Store, no OpenClaw)
```

**⚠️ PROBLEMA CONOCIDO:** La extensión Browser Relay no siempre está disponible en Chrome Web Store (GitHub issue #11631 reporta esto)

#### Paso 2: Instalación manual (si la extensión existe)
```bash
# Buscar la extensión en:
# 1. Chrome Web Store: https://chromewebstore.google.com
# 2. O desde OpenClaw marketplace

# Una vez instalada:
# - Abrir cualquier pestaña en Chrome
# - Click en el icono de la extensión (puzzle piece)
# - Debería mostrar estado "Connected"
```

#### Paso 3: Validar conexión
```bash
openclaw browser profiles

# Debería mostrar:
# chrome: running (X tabs)  ✅
```

---

### OPCIÓN C: Revisar GitHub Issues Relevantes

**Issues reportados:**
- #4841: Browser tool ignores profile parameter, routes all requests to chrome extension relay
- #11631: Chrome extension relay not found in Web Store / can't attach tab
- #12765: Chrome extension relay is running, but no tab is connected

**Conclusión:** Este es un **problema conocido y recurrente** en OpenClaw.

---

## 🔧 DIAGNÓSTICO ADICIONAL

### Comandos para validar

```bash
# 1. Ver estado de ambos perfiles:
openclaw browser profiles

# 2. Comprobar que el navegador administrado funciona:
openclaw browser --browser-profile openclaw status
openclaw browser --browser-profile openclaw open "https://example.com"
openclaw browser --browser-profile openclaw snapshot

# 3. Ver logs del gateway:
tail -50 /tmp/openclaw/openclaw-2026-02-22.log | grep -i "chrome\|browser\|relay"

# 4. Verificar puertos:
netstat -tlnp | grep -E "18789|18792|18800"
```

---

## 📋 CHECKLIST DE CONFIGURACIÓN

- ✅ Gateway corriendo (puerto 18789)
- ✅ Perfil "openclaw" funcional (puerto 18800)
- ⚠️ Perfil "chrome" sin tabs conectados (puerto 18792)
- ❌ Extensión Browser Relay NO instalada
- ✅ Configuración openclaw.json correcta
- ✅ chrome-shim ejecutándose correctamente

---

## 🎯 RECOMENDACIÓN FINAL

**USAR EL PERFIL ADMINISTRADO `openclaw`:**

```javascript
// En lugar de:
browser(action="open", profile="chrome", targetUrl="...")  // ❌ Causa error

// Hacer esto:
browser(action="open", profile="openclaw", targetUrl="...")  // ✅ Funciona
// O simplemente:
browser(action="open", targetUrl="...")  // ✅ También funciona (es el default)
```

**Razones:**
1. ✅ Ya está funcionando y tiene tabs activos
2. ✅ No requiere extensión instalada
3. ✅ Es el perfil por defecto en la configuración
4. ✅ Totalmente aislado y seguro

---

## 🔗 REFERENCIAS

- **Troubleshooting oficial:** https://docs.openclaw.ai/gateway/troubleshooting
- **Browser documentation:** https://docs.openclaw.ai/tools/browser.md
- **GitHub Issue #4841:** Browser tool ignores profile parameter
- **GitHub Issue #11631:** OpenClaw Browser Tool Configuration Failure
- **GitHub Issue #12765:** Chrome extension relay not connected

---

## 📝 NOTAS

1. **El error no es crítico:** El perfil administrado `openclaw` funciona perfectamente
2. **La extensión relay es opcional:** Solo se necesita si quieres controlar tu navegador personal
3. **Error frecuente:** Múltiples reportes en GitHub indican que esta es una limitación conocida
4. **Best practice:** Mantener separados navegador personal (chrome) y navegador del agent (openclaw)

---

## 🔄 PRÓXIMOS PASOS (Si quieres la extensión relay)

1. Verificar en Chrome Web Store si la extensión está disponible
2. Si no está: esperar a que OpenClaw la publique (o contactar soporte)
3. Si está: instalar manualmente y verificar que el tab se conecta
4. Validar tokens/auth entre extension y gateway
5. Revisar logs si sigue sin funcionar

**Pero por ahora: simplemente usa `profile="openclaw"` y funciona! 🎉**
