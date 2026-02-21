# Protocolo para Cambios de Seguridad Críticos

**Creado:** 2026-02-20  
**Motivo:** Hardening SSH rompió acceso VNC, casi dejando a Manu sin acceso remoto.

## Definición de "Cambio Crítico"

Un cambio es crítico si puede afectar:
- ✅ Acceso SSH (llaves, configuración sshd)
- ✅ Firewall (UFW, iptables)
- ✅ Port forwarding / túneles SSH
- ✅ Servicios de red (nginx, VNC, etc.)
- ✅ Fail2Ban (puede banear IPs accidentalmente)
- ✅ Permisos de usuario sudo
- ✅ OpenClaw gateway (si crashea, pierdo control)

## Reglas Obligatorias

### ANTES de aplicar cualquier cambio crítico:

#### 1. Backup automático
```bash
bash ~/.openclaw/workspace/scripts/backup-memory.sh
```
- ✅ Ejecutar SIEMPRE antes de cambios críticos
- ✅ Verificar que subió a Google Drive
- ✅ No proceder hasta confirmar backup exitoso

#### 2. Análisis de impacto
**Preguntar explícitamente a Manu:**
- "Voy a cambiar X en SSH/firewall/etc."
- "Esto puede afectar: [lista específica]"
- "¿Quieres que lo aplique o prefieres probarlo primero?"

**Lista de verificación mental:**
- ¿Afecta a SSH? → Puede dejarme sin acceso
- ¿Afecta a port forwarding? → Puede romper VNC
- ¿Afecta al firewall? → Puede bloquear conexiones
- ¿Puede banear la IP de Manu? → Dejaría sin acceso

#### 3. Testing en paralelo
**Mantener sesión SSH activa durante el cambio:**
- No cerrar la sesión SSH actual
- Aplicar cambio
- Verificar desde OTRA sesión SSH que funciona
- Solo si funciona, cerrar la sesión original

**Para cambios en sshd_config:**
```bash
# NUNCA hacer systemctl restart sshd en sesión única
# Hacer systemctl reload sshd (no cierra conexiones activas)
sudo systemctl reload sshd

# O mejor: validar config primero
sudo sshd -t && sudo systemctl reload sshd || echo "Config inválida, no aplicado"
```

#### 4. Validación post-cambio
**Checklist manual antes de dar por bueno:**

Para SSH:
- [ ] Puedo abrir nueva sesión SSH desde otro terminal
- [ ] Port forwarding funciona (si aplica)
- [ ] Usuario mleon sigue teniendo acceso sudo

Para firewall:
- [ ] Puerto 22 sigue abierto desde IP de Manu
- [ ] Puertos necesarios accesibles (5901 vía túnel, etc.)

Para Fail2Ban:
- [ ] IP de Manu NO está baneada
- [ ] Verificar: `sudo fail2ban-client status sshd`

Para VNC:
- [ ] Túnel SSH funciona (Test-NetConnection desde Windows)
- [ ] Servidor VNC responde (nc -w 2 127.0.0.1 5901)
- [ ] Cliente VNC puede conectar

#### 5. Rollback plan
**Antes de aplicar cambios:**
```bash
# Backup del archivo original
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup-$(date +%Y%m%d-%H%M%S)

# Para UFW (firewall)
sudo ufw status numbered > ~/ufw-rules-backup-$(date +%Y%m%d-%H%M%S).txt
```

**Si algo sale mal:**
```bash
# SSH
sudo cp /etc/ssh/sshd_config.backup-YYYYMMDD-HHMMSS /etc/ssh/sshd_config
sudo systemctl reload sshd

# Firewall
sudo ufw reset  # CUIDADO: borra todas las reglas
# Mejor: tener script de restauración
```

## Cambios Específicos y su Impacto

### AllowTcpForwarding (SSH)
**Configuración:** `/etc/ssh/sshd_config`

- `AllowTcpForwarding yes` → Permite túneles SSH (VNC funciona)
- `AllowTcpForwarding no` → **ROMPE VNC** (y cualquier túnel SSH)

**Validación necesaria:**
1. Aplicar cambio
2. Recargar sshd: `sudo systemctl reload sshd`
3. Pedir a Manu que cierre y reabra PuTTY
4. Pedir a Manu que pruebe conectar VNC
5. Solo si funciona → confirmar cambio
6. Si no funciona → rollback inmediato

**Alternativa más segura:**
```bash
# Permitir solo forwards específicos
PermitOpen localhost:5901
AllowTcpForwarding local
```

### PermitRootLogin (SSH)
**Impacto:** BAJO (Manu usa mleon, no root)
**Validación:** Verificar que mleon sigue teniendo sudo

### PasswordAuthentication (SSH)
**Impacto:** CRÍTICO si no hay SSH keys configuradas
**Validación:** Verificar que mleon tiene ~/.ssh/authorized_keys con la clave de Manu

### UFW (Firewall)
**Impacto:** CRÍTICO - puede bloquear SSH completamente
**Validación obligatoria:**
```bash
# SIEMPRE verificar que puerto 22 está permitido
sudo ufw status | grep 22/tcp
# Debe mostrar: 22/tcp ALLOW Anywhere
```

**Regla de oro:** NUNCA bloquear puerto 22 sin confirmar acceso alternativo

### Fail2Ban
**Impacto:** MEDIO - puede banear IP de Manu por error
**Validación:**
```bash
# Verificar que IP de Manu NO está baneada
sudo fail2ban-client status sshd
# Si está baneada: sudo fail2ban-client set sshd unbanip <IP>
```

## Propuestas para Mayor Seguridad

### Propuesta 1: Testing interactivo
**Para cambios críticos, pedirle a Manu:**
"Antes de aplicar esto, ¿puedes abrir otra ventana de PuTTY y dejarla conectada? Voy a aplicar el cambio y tú pruebas que sigue funcionando. Si falla, deshago el cambio desde tu sesión original."

**Ventaja:** Manu participa en la validación y siempre tiene una sesión de respaldo.

### Propuesta 2: Backup pre-cambio automático
**Modificar scripts de hardening:**
```bash
#!/bin/bash
# Al inicio de cualquier script de seguridad
echo "🔄 Creando backup pre-cambio..."
bash ~/.openclaw/workspace/scripts/backup-memory.sh
if [ $? -ne 0 ]; then
    echo "❌ Backup falló, abortando cambios"
    exit 1
fi
echo "✅ Backup completado, procediendo con cambios..."
```

**Ventaja:** Automático, no depende de que me acuerde.

### Propuesta 3: Dry-run mode
**Para scripts de hardening:**
```bash
bash hardening.sh --dry-run  # Muestra qué haría sin aplicar
bash hardening.sh --apply     # Solo después de validar dry-run
```

**Ventaja:** Manu puede revisar los cambios antes de aplicarlos.

### Propuesta 4: Validación post-cambio automática
**Al final de scripts de hardening:**
```bash
echo "🔍 Validando conectividad..."
# Desde la VPS, intentar conectar a puerto SSH desde otra terminal
# Si falla, rollback automático
timeout 5 nc -zv localhost 22 || {
    echo "❌ Puerto SSH no responde, haciendo rollback..."
    sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
    sudo systemctl reload sshd
    exit 1
}
echo "✅ Validación exitosa"
```

### Propuesta 5: Documentación de dependencias
**Crear archivo:** `memory/security-dependencies.md`
```markdown
# Dependencias de Servicios

## VNC
- Requiere: AllowTcpForwarding yes (SSH)
- Requiere: Puerto 5901 accesible vía localhost
- Requiere: D-Bus inicializado (~/.vnc/xstartup)

## OpenClaw Gateway
- Requiere: Puerto 18789 localhost
- Requiere: Node.js instalado
- Requiere: Memoria suficiente (>1GB libre)
```

## Checklist de Emergencia

### Si pierdo acceso SSH:
1. ✅ Acceso físico a la VPS (panel de control del proveedor)
2. ✅ Consola VNC desde panel web
3. ✅ Rescate/Recovery mode del proveedor
4. ✅ Contactar soporte del proveedor

### Si pierdo acceso VNC (pero tengo SSH):
1. ✅ Verificar AllowTcpForwarding en sshd_config
2. ✅ Verificar servidor VNC corriendo (ps aux | grep vnc)
3. ✅ Verificar puerto 5901 escuchando (ss -tlnp | grep 5901)
4. ✅ Revisar logs: tail ~/.vnc/ubuntu:1.log

### Si OpenClaw crashea:
1. ✅ SSH sigue funcionando (no depende de OpenClaw)
2. ✅ Logs: journalctl --user -u openclaw-gateway -n 50
3. ✅ Reiniciar: systemctl --user restart openclaw-gateway
4. ✅ Rollback config: restaurar openclaw.json.bak

## Lección del día: AllowTcpForwarding

**Lo que pasó hoy:**
1. Hardening SSH configuró `AllowTcpForwarding no`
2. Esto bloqueó TODOS los túneles SSH
3. VNC dejó de funcionar (requiere túnel SSH para llegar a puerto 5901)
4. Diagnóstico: tcpdump mostró 0 paquetes llegando a VPS
5. Solución: `AllowTcpForwarding yes` + reiniciar sesión SSH

**Lo que debería haber hecho:**
1. ✅ Backup antes de hardening
2. ✅ Análisis de impacto: "Esto romperá VNC, ¿procedemos?"
3. ✅ Validación post-cambio: "Manu, prueba VNC antes de que cierre la sesión"
4. ✅ Si falla: rollback inmediato

**Impacto real:**
- ⏱️ 45 minutos de troubleshooting
- 😰 Manu con miedo a perder acceso completamente
- 🎓 Lección aprendida: validar conectividad ANTES de confirmar cambios

## Frecuencia de Backups

**Propuesta:**
- **Automático diario:** 4:00 AM (ya configurado en cron)
- **Manual pre-cambio:** Antes de hardening, updates críticos, config SSH/firewall
- **Opcional:** Antes de spawn sub-agentes costosos (Opus intensivo)

**NO es necesario:**
- Cada 20 minutos (excesivo)
- Después de cambios menores (editar archivos de memoria, instalar paquetes simples)

**Balance:** Backup automático diario + manual antes de cambios críticos.

## Implementación

**Añadir a AGENTS.md:**
```markdown
### 🔐 Reinicios y Cambios Críticos de Seguridad

**REGLA: Siempre backup + validar ANTES de cambios críticos**

Cambios críticos = SSH, firewall, port forwarding, servicios de red

Antes de aplicar:
1. Backup automático (scripts/backup-memory.sh)
2. Análisis de impacto → avisar a Manu
3. Pedir que mantenga sesión SSH abierta
4. Aplicar cambio
5. Validar desde otra sesión
6. Si falla → rollback inmediato
7. Solo confirmar si Manu valida que todo funciona

Ver: memory/security-change-protocol.md para detalles completos.
```

## Decisión Final

**Fecha:** 2026-02-20
**Propuesta elegida por Manu:** **A + B combinadas**

### Implementación A + B

**Antes de CUALQUIER cambio crítico:**

1. **Backup automático** (B)
   ```bash
   bash ~/.openclaw/workspace/scripts/backup-memory.sh
   # Verificar que subió a Drive
   # Si falla → abortar cambio
   ```

2. **Análisis de impacto y testing interactivo** (A)
   - Avisar a Manu: "Voy a cambiar X, puede afectar Y (VNC/SSH/firewall)"
   - Pedirle: "Abre otra ventana de PuTTY y déjala conectada"
   - Aplicar cambio en una sesión
   - Pedirle: "Prueba que sigue funcionando (VNC, túneles, etc.)"
   - Si falla → rollback desde sesión original
   - Si funciona → confirmar y cerrar sesión de respaldo

3. **Solo confirmar si Manu valida OK**
   - No dar por bueno hasta que Manu diga que todo funciona
   - Mantener plan de rollback listo hasta confirmación

**Ventajas de A + B:**
- ✅ Backup automático (no depende de memoria)
- ✅ Testing interactivo (Manu participa)
- ✅ Sesión de respaldo siempre disponible
- ✅ Validación real antes de confirmar
- ✅ Rollback inmediato si falla

## Próximos Pasos

1. [x] Añadir este protocolo a AGENTS.md
2. [x] Decisión tomada: A + B
3. [ ] Crear checklist en scripts/hardening.sh
4. [ ] Documentar dependencias de servicios
5. [ ] Configurar backup pre-cambio automático en scripts críticos
6. [ ] Revisar RECOVERY.md para incluir este protocolo

---

**Nota final:** El objetivo NO es evitar cambios de seguridad. El objetivo es hacerlos **de forma segura y reversible**, sin riesgo de perder acceso.
