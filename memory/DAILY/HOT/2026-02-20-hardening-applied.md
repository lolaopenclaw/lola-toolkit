# Hardening Aplicado - 2026-02-20

**Fecha:** 2026-02-20 10:44 UTC  
**Basado en:** Recomendaciones Lynis (scan inicial 65%)

## Cambios Implementados

### 1. ✅ Fail2Ban: jail.local creado
**Comando:**
```bash
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl restart fail2ban
```

**Motivo:** Proteger configuración personalizada de updates automáticos

**Resultado:** ✅ Fail2ban reiniciado correctamente, usando jail.local

---

### 2. ✅ SSH: TCP Forwarding deshabilitado
**Cambio en:** `/etc/ssh/sshd_config`
```
AllowTcpForwarding no
```

**Comando:**
```bash
sudo sshd -t  # Validar config
sudo systemctl reload sshd  # Aplicar sin cortar conexiones
```

**Motivo:** Prevenir túneles SSH no autorizados, reducir superficie de ataque

**Resultado:** ✅ SSH recargado sin incidentes

---

### 3. ✅ rkhunter instalado
**Versión:** 1.4.6

**Comandos:**
```bash
sudo apt install -y rkhunter
sudo sed -i 's|WEB_CMD="/bin/false"|WEB_CMD="/usr/bin/curl"|' /etc/rkhunter.conf
sudo rkhunter --update
sudo rkhunter --propupd
```

**Motivo:** Detección de rootkits y malware

**Resultado:** ✅ Instalado y configurado, database actualizada

**Configurado scan semanal:** (pendiente añadir cron)

---

## Impacto Esperado

**Hardening Index:**
- Anterior: 65% (219/334 puntos)
- Esperado: ~68-70%
- Próximo scan: Lunes 24 feb (Lynis weekly)

**Mejoras de Seguridad:**
1. Configuración fail2ban persistente
2. Túneles SSH bloqueados
3. Detección de malware activa

**Sin downtime, sin problemas**

## Próximos Pasos (Opcionales)

**No implementadas (bajo impacto para VPS personal):**
- GRUB password (solo útil con acceso físico)
- Restringir compiladores (rompe npm modules)
- Password policies (SSH keys > passwords)
- Particiones separadas (muy disruptivo)

## Comandos de Verificación

```bash
# Fail2ban
sudo systemctl status fail2ban
sudo fail2ban-client status sshd

# SSH
sudo sshd -t
grep AllowTcpForwarding /etc/ssh/sshd_config

# rkhunter
rkhunter --version
sudo rkhunter --check --skip-keypress
sudo tail -50 /var/log/rkhunter.log
```
