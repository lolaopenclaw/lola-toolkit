# Sesión 10: Resolución de problemas VNC

**Hora:** 18:00-18:45 UTC (19:00-19:45 Madrid)
**Dispositivo:** Portátil del trabajo (Manu)

## Problema inicial
Manu no podía conectar a VNC desde el portátil del trabajo vía túnel SSH (PuTTY).
- **Síntoma:** "La conexión se ha cerrado de forma inesperada" (RealVNC)
- **Síntoma:** "Connection failed - End of Stream" (UltraVNC)
- **Síntoma:** "Connection dropped by server" (TigerVNC)

## Diagnóstico

### 1. Verificación inicial
- ✅ Servidor VNC corriendo en VPS (puerto 5901)
- ✅ Túnel SSH configurado correctamente en PuTTY (L5901 localhost:5901)
- ✅ Puerto 5901 escuchando en Windows (netstat confirmado)
- ✅ Conexiones llegaban a Windows pero se cerraban inmediatamente (TimeWait)
- ❌ **CERO paquetes llegaban a la VPS** (tcpdump confirmó)

### 2. Causa raíz encontrada
**Línea en `/etc/ssh/sshd_config`:**
```
AllowTcpForwarding no
```

Esta configuración se añadió HOY durante el hardening de seguridad (sesión 3).
**Efecto:** Bloqueaba TODOS los túneles SSH (port forwarding).

### 3. Problema secundario (post-conexión)
Una vez habilitado `AllowTcpForwarding yes`, VNC conectaba pero XFCE crasheaba:
**Error:** "Unable to contact settings server - Could not connect: No such file or directory"

**Causa:** D-Bus no se inicializaba correctamente en `~/.vnc/xstartup`

## Solución aplicada

### Paso 1: Habilitar port forwarding en SSH
```bash
sudo sed -i 's/^AllowTcpForwarding no$/AllowTcpForwarding yes/' /etc/ssh/sshd_config
sudo systemctl reload sshd
```

### Paso 2: Arreglar script de inicio XFCE
**Archivo:** `~/.vnc/xstartup`
```bash
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Crear directorio runtime si no existe
export XDG_RUNTIME_DIR=/run/user/$(id -u)
[ ! -d "$XDG_RUNTIME_DIR" ] && mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"

# Iniciar D-Bus
if [ -x /usr/bin/dbus-launch ]; then
   eval $(dbus-launch --sh-syntax)
fi

# Lanzar XFCE
exec startxfce4
```

### Paso 3: Reiniciar VNC con autenticación
```bash
vncserver -kill :1
vncpasswd  # Configurar contraseña
vncserver :1 -localhost yes -geometry 1920x1080 -depth 24 -SecurityTypes VncAuth
```

## Resultado
✅ VNC funcionando correctamente vía túnel SSH
✅ XFCE arranca sin errores
✅ RealVNC Viewer conecta exitosamente desde Windows
✅ Autenticación con contraseña habilitada

## Clientes VNC probados
1. **RealVNC Viewer:** ✅ Funciona (el que finalmente usó Manu)
2. **UltraVNC Viewer:** ⚠️ Problemas de protocolo con TigerVNC
3. **TigerVNC Viewer:** ✅ Compatible (mismo que el servidor)

## Configuración final de VNC

### Servidor VNC (comando completo)
```bash
vncserver :1 -localhost yes -geometry 1920x1080 -depth 24 -SecurityTypes VncAuth
```

### Túnel SSH en PuTTY
- **Source port:** 5901
- **Destination:** localhost:5901
- **Type:** Local
- **Debe aparecer en Event Log:** "Local port forwarding to localhost:5901"

### Conexión desde Windows
- **Cliente recomendado:** RealVNC Viewer o TigerVNC Viewer
- **Servidor:** localhost:5901
- **Contraseña:** (configurada por usuario)

## Cambiar contraseña VNC
Desde dentro de la sesión VNC:
```bash
vncpasswd
vncserver -kill :1
vncserver :1 -localhost yes -geometry 1920x1080 -depth 24 -SecurityTypes VncAuth
```

## Lecciones aprendidas

### 1. Conflicto hardening vs usabilidad
**Problema:** `AllowTcpForwarding no` mejora la seguridad pero rompe túneles SSH legítimos.

**Solución futura:** En lugar de deshabilitarlo completamente, considerar:
- `PermitOpen localhost:5901` (solo permitir forwards específicos)
- O documentar explícitamente qué romperá el hardening

### 2. D-Bus en sesiones VNC
**Problema común:** XFCE (y otros entornos de escritorio) requieren D-Bus inicializado.

**Síntomas:**
- "Unable to contact settings server"
- Aplicaciones no arrancan
- Configuración no se guarda

**Solución:** Asegurar que `~/.vnc/xstartup` inicializa D-Bus con `dbus-launch`

### 3. Diagnóstico de túneles SSH
**Herramientas útiles:**
- `tcpdump` en el servidor (para confirmar si llegan paquetes)
- `netstat`/`ss` en cliente y servidor (para ver conexiones)
- `Test-NetConnection` en Windows (para verificar puertos locales)

### 4. Compatibilidad de clientes VNC
No todos los clientes VNC son compatibles con todos los servidores.
- **Mejor:** Usar mismo cliente que servidor (TigerVNC ↔ TigerVNC)
- **Alternativa:** RealVNC suele ser más compatible
- **Evitar:** UltraVNC con TigerVNC (problemas de protocolo)

## Acciones pendientes
- [x] Verificar que VNC funciona
- [x] Habilitar autenticación
- [ ] Manu cambiará la contraseña a una permanente
- [ ] Considerar añadir VNC a systemd para arranque automático
- [ ] Documentar en RECOVERY.md que hardening SSH requiere ajustes para VNC

## Tiempo total
~45 minutos de troubleshooting intensivo

## Impacto en seguridad
- **Antes:** AllowTcpForwarding no (más seguro pero menos funcional)
- **Después:** AllowTcpForwarding yes (permite túneles SSH pero sigue seguro porque):
  - VNC solo escucha en localhost (-localhost yes)
  - SSH requiere autenticación por clave
  - VNC requiere contraseña
  - Firewall UFW activo
  - Fail2Ban protegiendo SSH

**Conclusión:** El cambio es seguro y necesario para la funcionalidad requerida.
