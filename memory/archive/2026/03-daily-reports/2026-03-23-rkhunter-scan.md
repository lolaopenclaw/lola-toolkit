# Rkhunter Security Scan - 23 de marzo 2026

**Fecha:** Lunes, 23 de marzo 2026, 10:18-10:22 CET  
**Duración:** 3 minutos y 20 segundos  
**Estado general:** ✅ Sistema limpio (sin rootkits reales detectados)

---

## Resumen ejecutivo

- **Archivos revisados:** 144
- **Rootkits verificados:** 498
- **Rootkits detectados:** 0 ✅
- **Warnings totales:** 65 (todos benignos)

---

## Categorías de warnings

### 1. Archivos del sistema actualizados (60 warnings)
**Causa:** Actualizaciones legítimas del sistema operativo (Ubuntu)

Los siguientes binarios críticos cambiaron debido a actualizaciones:
- **Enero 2026:** coreutils (cat, chmod, chown, cp, cut, etc.)
- **Marzo 2026:** util-linux (mount, dmesg, su, sulogin, fsck), openssh (sshd, ssh), sudo, curl

**Evaluación:** ✅ **Normal y esperado** — Las fechas coinciden con actualizaciones de seguridad de Ubuntu.

**Archivos afectados destacados:**
- `/usr/sbin/sshd` (04-Mar-2026) — Actualización de OpenSSH
- `/usr/bin/sudo` (02-Mar-2026) — Actualización de sudo
- `/usr/bin/curl` (10-Mar-2026) — Actualización de curl

### 2. Proceso con script perl (1 warning)
```
Warning: The command '/usr/bin/lwp-request' has been replaced by a script: 
/usr/bin/lwp-request: Perl script text executable
```

**Evaluación:** ✅ **Benigno** — lwp-request es parte de libwww-perl y es legítimamente un script Perl.

### 3. Segmentos de memoria compartida grandes (1 warning)
```
Process: /usr/bin/xfce4-terminal    PID: 1713547    Owner: mleon    Size: 1.0MB
Process: /usr/sbin/unity-greeter    PID: 1803       Owner: lightdm   Size: 32MB
```

**Evaluación:** ✅ **Normal** — xfce4-terminal (terminal del usuario) y unity-greeter (pantalla de login) son procesos legítimos del sistema gráfico.

### 4. Archivos en /dev/shm (byobu) (1 warning)
```
/dev/shm/byobu-mleon-A3f6dRdt/...
```

**Evaluación:** ✅ **Normal** — byobu es un multiplexor de terminal (wrapper de tmux) que usa /dev/shm para archivos temporales de estado.

### 5. Archivos ocultos en /etc (2 warnings)
```
/etc/.resolv.conf.systemd-resolved.bak
/etc/.updated
```

**Evaluación:** ✅ **Benigno**
- `.resolv.conf.systemd-resolved.bak` — Respaldo de systemd-resolved
- `.updated` — Archivo de timestamp de apt

---

## Resumen de "Possible rootkits: 2"

El contador de rkhunter muestra "2" debido a:
1. El script perl lwp-request (considerado sospechoso por ser script)
2. Los segmentos de memoria compartida grandes

**Ninguno es un rootkit real.** Todos son procesos/archivos legítimos del sistema.

---

## Verificaciones de seguridad pasadas ✅

- ✅ **SSH:** Root login deshabilitado, solo protocolo v2
- ✅ **Cuentas:** No hay cuentas sin contraseña ni equivalentes a root (UID 0)
- ✅ **Logging:** rsyslog y systemd-journald activos, sin remote logging
- ✅ **Malware en startup:** No detectado
- ✅ **Rootkit strings:** No encontrados en archivos de inicio del sistema

---

## Recomendaciones

1. **Actualizar base de datos de rkhunter** para registrar los hashes actuales:
   ```bash
   sudo rkhunter --propupd
   ```
   Esto eliminará los 60 warnings de "file properties changed" en futuros escaneos.

2. **Whitelist de archivos legítimos:**
   ```bash
   # Añadir a /etc/rkhunter.conf:
   SCRIPTWHITELIST=/usr/bin/lwp-request
   ALLOWDEVFILE=/dev/shm/byobu-*
   ```

3. **Escaneos periódicos:** Considerar configurar rkhunter en cron para escaneos automáticos.

---

## Conclusión

🟢 **Estado: SISTEMA SEGURO**

No se detectaron rootkits, malware ni actividad sospechosa real. Todos los warnings son falsos positivos causados por:
- Actualizaciones legítimas del sistema
- Software estándar de Ubuntu (byobu, lwp-request, xfce4-terminal, unity-greeter)

El sistema está limpio y las configuraciones de seguridad críticas (SSH, cuentas, logging) están correctamente implementadas.

---

**Próximo escaneo recomendado:** Después de ejecutar `sudo rkhunter --propupd`
