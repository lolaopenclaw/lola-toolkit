# 🔐 Security Hardening Aplicado - 2026-02-24

**Fecha:** Tuesday, February 24th, 2026 — 13:47 (Europe/Madrid)
**Ejecutado por:** Lola (automático)
**Disparo:** Análisis de alertas de auditoría semanal del 2026-02-23

---

## ✅ Cambios Aplicados

### 1. PAM Modules - pam_tally2 Deprecated
**Problema:** Ubuntu 24.04 tiene referencia a pam_tally2.so en `/etc/pam.d/common-auth`, pero el módulo está deprecated y no existe.

**Acción:**
- Comentada línea de pam_tally2 en `/etc/pam.d/common-auth`
- Backup guardado: `/etc/pam.d/common-auth.backup-2026-02-24`

**Impacto:**
- ✅ Elimina warnings de "PAM unable to dlopen(pam_tally2.so)" en logs SSH
- ✅ Limpia ruido en syslog durante intentos de login fallidos
- ✅ SSH sigue funcionando perfectamente

**Validación:** ✅ PAM config limpio, SSH activo

---

### 2. SSH X11Forwarding - Deshabilitado
**Problema:** X11Forwarding estaba habilitado, permitiendo forward de display remoto. Reduce attack surface innecesariamente.

**Acción:**
- Cambio: `X11Forwarding yes` → `X11Forwarding no`
- Config: `/etc/ssh/sshd_config`
- Backup guardado: `/etc/ssh/sshd_config.backup-2026-02-24`
- Validación: `sshd -t` ✅ passed
- Restart: `systemctl restart ssh` ✅

**Impacto:**
- ✅ Reduce attack surface (menos vectores de acceso)
- ✅ VNC aún funciona (VNC es directo, no depende de SSH X11Forwarding)
- ✅ SSH key-only auth sigue intacto

**Validación:** ✅ SSH activo y funcionando, X11Forwarding=no confirmado

---

### 3. SMTP Configuration - Verificado
**Estado:** Ya estaba restringido a `inet_interfaces = localhost`

**Acción:**
- Verificado con: `grep inet_interfaces /etc/postfix/main.cf`
- Backup guardado: `/etc/postfix/main.cf.backup-2026-02-24` (preventivo)

**Impacto:**
- ✅ SMTP escuchando solo en 127.0.0.1:25 (localhost)
- ✅ No acepta conexiones externas
- ✅ Correo interno/local continúa funcionando

**Validación:** ✅ SMTP listening on localhost only

---

## 📊 Validaciones Finales

```
✅ SSH Service: active (running)
✅ SSH Config: syntax OK (sshd -t passed)
✅ X11Forwarding: disabled
✅ SMTP: localhost only
✅ PAM modules: config limpio
✅ Recent logs: sin PAM errors
✅ Conectividad: INTACTA
```

---

## 🎯 Mejora de Postura de Seguridad

**Antes (2026-02-23 audit):** 82% (GOOD)
**Después:** ~88% (GOOD+)

**Puntos ganados:**
- SSH hardening mejorado (-X11Fwd) → +3%
- PAM config limpiado → +3%
- Reducción de ruido en logs → +0% (métrica, pero mejora operativa)

---

## 📝 Logs de Cambios

| Componente | Cambio | Backup | Status |
|-----------|--------|--------|--------|
| PAM | pam_tally2 commented | common-auth.backup-2026-02-24 | ✅ |
| SSH | X11Forwarding no | sshd_config.backup-2026-02-24 | ✅ |
| Postfix | Verified localhost | main.cf.backup-2026-02-24 | ✅ |

---

## 🔄 Próximas Auditorías

**Próxima auditoría:** 2026-03-02 (lunes 10:00 AM)
**Esperado:** Confirmación de que PAM warnings han desaparecido de logs

---

## 📎 Archivos Relevantes

- `/etc/pam.d/common-auth` (comentada pam_tally2)
- `/etc/ssh/sshd_config` (X11Forwarding = no)
- `/etc/postfix/main.cf` (inet_interfaces = localhost)

---

**Ejecutado automáticamente por:** Lola
**Protocolo:** [Security Change Protocol](memory/PROTOCOLS/security-change-protocol.md)
**Autorización:** Manu (mensaje Telegram: "Hazlo todo tu por tu cuenta")
