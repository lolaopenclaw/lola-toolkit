# 🔐 VPS Security Audit - Ubuntu

**Fecha:** 19 de febrero de 2026  
**Sistema:** Ubuntu (6.8.0-100-generic)  
**Auditor:** Lola  

---

## 📊 Resumen Ejecutivo

El VPS presenta **dos vulnerabilidades críticas** en la configuración SSH que requieren atención inmediata:
- ❌ **Root login habilitado** (`PermitRootLogin yes`)
- ❌ **Autenticación por contraseña habilitada** (`PasswordAuthentication yes`)

Además, **Fail2ban no está instalado**, dejando el sistema sin protección contra ataques de fuerza bruta. El resto de la configuración es aceptable, aunque hay oportunidades de mejora. Se recomienda implementar los cambios de seguridad en **menos de 24 horas**.

---

## 📋 Análisis Detallado

### 1. Firewall (ufw) - ✅ OK

```
Estado: ACTIVO
Política: Deny incoming, Allow outgoing
Logging: On (low)
Puertos abiertos:
  • 22/tcp (SSH) - Anywhere
  • 5901/tcp (VNC) - Anywhere
```

**Evaluación:** El firewall está activo y bien configurado con política de denegación por defecto. Solo acepta SSH y VNC desde cualquier origen.

**Recomendaciones:**
- ⚠️ **Limitar SSH a IPs conocidas** si es posible. Ejemplo:
  ```bash
  sudo ufw delete allow 22
  sudo ufw allow from 203.0.113.0/24 to any port 22
  ```
- ⚠️ **Considerar cambiar puerto SSH** a algo diferente de 22 (ej. 2222) para reducir escaneos automáticos

---

### 2. SSH Configuration - ❌ CRÍTICO

```
PermitRootLogin yes         ← ❌ INSEGURO
PasswordAuthentication yes  ← ❌ INSEGURO
Port 22                     ← ✅ OK (estándar)
```

**Evaluación:** Dos configuraciones críticas permitiendo acceso directo como root y autenticación por contraseña.

**Riesgo:** Ataques de fuerza bruta contra root, combinados con password auth, elevan significativamente el riesgo de compromiso.

**Recomendaciones URGENTES:**
```bash
# 1. Deshabilitar login de root
sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# 2. Deshabilitar autenticación por contraseña (requiere SSH keys)
sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# 3. Verificar cambios
sudo sshd -t  # Validate config

# 4. Reiniciar SSH
sudo systemctl restart sshd
```

**⚠️ ANTES DE APLICAR:** Asegurar tener acceso por clave SSH configurada, o quedarás bloqueado.

---

### 3. Puertos Abiertos (ss -tlnp) - ✅ OK

```
LISTENING:
  • 0.0.0.0:22 (sshd) - SSH
  • 0.0.0.0:5901 (Xtigervnc) - VNC
  • 127.0.0.1:53 (systemd-resolve) - DNS local
  • 127.0.0.1:18789,18792 (openclaw-gateway) - OpenClaw local
  • 127.0.0.1:631 (cupsd) - CUPS (local)
  • 127.0.0.1:18800 (chrome) - Chrome local
  • [::1] (IPv6 equivalentes)
```

**Evaluación:** Servicios restringidos correctamente a localhost, excepto SSH y VNC que están abiertos globalmente (esperado).

**Recomendación:**
- Documentar para qué se usan VNC (5901) y revisar si es realmente necesario en producción

---

### 4. Actualizaciones Pendientes - ⚠️ MEJORABLE

```
Paquetes con actualizaciones disponibles (5):
  • libmtp-common
  • libmtp-runtime
  • libmtp9t64
  • libxnvctrl0
  • systemd-hwe-hwdb
```

**Evaluación:** Solo 5 actualizaciones menores disponibles. No hay actualizaciones de seguridad críticas pendientes.

**Recomendación:**
```bash
# Aplicar actualizaciones
sudo apt update && sudo apt upgrade -y
```

---

### 5. Usuarios con Shell - ✅ OK

```
root       (uid 0)    - /bin/bash
sync       (uid 4)    - /bin/sync
mleon      (uid 1000) - /bin/bash
```

**Evaluación:** Solo 3 usuarios con shell interactivo. `root` y `mleon` son esperados; `sync` es un usuario del sistema con `/bin/sync` (no una shell real).

**Recomendación:** ✅ Aceptable. Mantener bajo control de usuarios administrativos.

---

### 6. Fail2ban - ❌ NO INSTALADO

```
fail2ban.service: No encontrado
```

**Evaluación:** Fail2ban no está instalado. Este es un componente importante para proteger contra ataques de fuerza bruta en SSH.

**Recomendación IMPORTANTE:**
```bash
# Instalar y activar Fail2ban
sudo apt update && sudo apt install -y fail2ban

# Crear configuración básica (proteger SSH)
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
EOF

# Iniciar servicio
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Verificar estado
sudo fail2ban-client status
```

---

### 7. Unattended Upgrades - ✅ OK

```
Status: INSTALADO
Versión: 2.9.1+nmu4ubuntu1
```

**Evaluación:** Unattended-upgrades está instalado. Este servicio aplica automáticamente parches de seguridad.

**Recomendación:** Verificar que está habilitado y configurado:
```bash
sudo systemctl status unattended-upgrades
cat /etc/apt/apt.conf.d/50unattended-upgrades
```

---

### 8. Últimos Logins - ✅ OK

```
Últimos 10 logins:
  • Reboot (hoy, 13:32 UTC) - en ejecución
  • Reboot (ayer, 13:30-13:32)
  • Reboot (ayer, 13:18-13:30)
  • mleon from 82.223.200.207 (hace 7 días, 14:12-16:26)
  • mleon from 82.223.200.207 (hace 7 días, múltiples sesiones)
  
Intentos fallidos (lastb): NINGUNO
```

**Evaluación:** Logins normales, sin actividad sospechosa. No hay intentos fallidos registrados.

**Recomendación:** ✅ Aceptable. Mantener monitoreo regular.

---

## 🎯 Plan de Acción Recomendado

### Fase 1 - CRÍTICA (Hacer hoy)
1. ✅ Asegurar acceso SSH por clave pública
2. ✅ Deshabilitar `PermitRootLogin yes`
3. ✅ Deshabilitar `PasswordAuthentication yes`
4. ✅ Reiniciar SSH y verificar acceso

### Fase 2 - IMPORTANTE (Próximas 24h)
1. Instalar y configurar Fail2ban
2. Aplicar actualizaciones pendientes (`apt upgrade`)
3. Considerar cambiar puerto SSH a número personalizado

### Fase 3 - MANTENIMIENTO (Ongoing)
1. Revisar logs regularmente: `sudo tail -f /var/log/auth.log`
2. Monitorear estado de Fail2ban: `sudo fail2ban-client status sshd`
3. Ejecutar auditoría mensual

---

## 📈 Puntuación de Seguridad General

| Categoría | Puntuación | Estado |
|-----------|-----------|--------|
| Firewall | 8/10 | ✅ Bien configurado |
| SSH | 2/10 | ❌ **Crítico** |
| Puertos | 9/10 | ✅ Restringidos |
| Actualizaciones | 9/10 | ✅ Al día |
| Usuarios | 9/10 | ✅ Limitados |
| Protección Fuerza Bruta | 0/10 | ❌ **Fail2ban ausente** |
| Logs | 7/10 | ⚠️ Sin monitoreo activo |
| **TOTAL** | **5.7/10** | ⚠️ **REQUIERE ACCIÓN** |

---

## ✅ Conclusión

El VPS tiene una estructura base aceptable, pero **las configuraciones de SSH son inaceptables para producción**. La falta de Fail2ban agrava el riesgo. Implementar las recomendaciones Fase 1 reducirá significativamente la superficie de ataque.

**Tiempo estimado para implementar Fase 1:** 15 minutos  
**Impacto en disponibilidad:** Mínimo (cambios en SSH solo)  
**Prioridad:** CRÍTICA
