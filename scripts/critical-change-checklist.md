# ✅ Checklist para Cambios Críticos

**Usar SIEMPRE antes de:** SSH, firewall, port forwarding, Fail2Ban, servicios de red

---

## Pre-Cambio

- [ ] **1. Backup automático**
  ```bash
  bash ~/.openclaw/workspace/scripts/backup-memory.sh
  ```
  - Verificar que subió a Google Drive
  - Si falla → ABORTAR cambio

- [ ] **2. Análisis de impacto**
  - ¿Afecta a SSH? → Puede dejarme sin acceso
  - ¿Afecta a port forwarding? → Puede romper VNC
  - ¿Afecta al firewall? → Puede bloquear conexiones
  - ¿Puede banear IP de Manu? → Dejaría sin acceso

- [ ] **3. Backup del archivo original**
  ```bash
  sudo cp /ruta/archivo /ruta/archivo.backup-$(date +%Y%m%d-%H%M%S)
  ```

- [ ] **4. Avisar a Manu por Telegram**
  - Qué voy a cambiar
  - Qué puede verse afectado (VNC, SSH, etc.)
  - Pedirle que abra otra ventana de PuTTY

---

## Durante el Cambio

- [ ] **5. Manu tiene sesión SSH de respaldo abierta**

- [ ] **6. Aplicar cambio**
  - Para SSH: `sudo systemctl reload sshd` (NO restart)
  - Para firewall: aplicar reglas una a una
  - Para servicios: con `systemctl reload` si es posible

- [ ] **7. Verificar config (si aplica)**
  ```bash
  # SSH
  sudo sshd -t
  
  # Firewall
  sudo ufw status numbered
  
  # Fail2Ban
  sudo fail2ban-client status
  ```

---

## Post-Cambio

- [ ] **8. Validar desde otra sesión**
  ```bash
  # SSH: abrir nueva conexión en otra terminal
  ssh mleon@79.117.197.5
  
  # VNC: verificar puerto responde
  nc -zv 127.0.0.1 5901
  
  # Port forwarding: desde Windows
  Test-NetConnection -ComputerName localhost -Port 5901
  ```

- [ ] **9. Pedir a Manu que valide**
  - "Prueba VNC desde tu Windows"
  - "Prueba abrir nueva sesión SSH"
  - "Prueba [lo que sea relevante]"

- [ ] **10. Decidir según resultado**
  
  **✅ Si funciona:**
  - Confirmar cambio
  - Manu puede cerrar sesión de respaldo
  - Documentar en memoria del día
  
  **❌ Si falla:**
  - Rollback inmediato:
    ```bash
    sudo cp /ruta/archivo.backup-YYYYMMDD-HHMMSS /ruta/archivo
    sudo systemctl reload [servicio]
    ```
  - Verificar que rollback restauró funcionalidad
  - Pedir a Manu que confirme que vuelve a funcionar
  - Investigar por qué falló antes de reintentar

---

## Si Algo Sale Mal

### SSH no responde
1. Usar sesión de respaldo que Manu mantuvo abierta
2. Rollback config: `sudo cp /etc/ssh/sshd_config.backup-* /etc/ssh/sshd_config`
3. Recargar: `sudo systemctl reload sshd`
4. Si aún no funciona → acceso físico/consola web

### VNC no funciona
1. Verificar AllowTcpForwarding: `sudo grep AllowTcpForwarding /etc/ssh/sshd_config`
2. Debe ser `yes` para VNC
3. Verificar servidor VNC: `ps aux | grep vnc`
4. Verificar puerto: `ss -tlnp | grep 5901`

### Firewall bloqueó todo
1. Desde sesión de respaldo: `sudo ufw disable`
2. Verificar acceso restaurado
3. Reconfigurar firewall correctamente
4. Re-habilitar: `sudo ufw enable`

---

## Cambios Específicos

### SSH (/etc/ssh/sshd_config)
**Crítico:** AllowTcpForwarding, PasswordAuthentication, PermitRootLogin
- Backup: ✅
- Sesión respaldo: ✅
- Reload (no restart): ✅
- Validar config: `sudo sshd -t`
- Probar nueva conexión ANTES de cerrar original

### Firewall (UFW)
**Crítico:** Cualquier cambio en puerto 22 o reglas default
- Backup reglas: `sudo ufw status numbered > ~/ufw-backup-$(date +%Y%m%d).txt`
- Verificar puerto 22 SIEMPRE permitido
- Aplicar reglas una a una
- Probar conexión entre cada cambio

### Fail2Ban
**Crítico:** Configuración de jails, especialmente sshd
- Backup: `sudo cp /etc/fail2ban/jail.local /etc/fail2ban/jail.local.backup-$(date +%Y%m%d)`
- Verificar IP de Manu NO baneada: `sudo fail2ban-client status sshd`
- Si baneada: `sudo fail2ban-client set sshd unbanip 79.117.197.5`

---

**Última actualización:** 2026-02-20  
**Decisión:** Propuesta A + B (backup automático + testing interactivo)
