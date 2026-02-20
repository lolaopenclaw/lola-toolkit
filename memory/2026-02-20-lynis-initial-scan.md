# Lynis Initial Scan - 2026-02-20

**Fecha:** 2026-02-20 10:31 UTC  
**Versión Lynis:** 3.0.9  
**Sistema:** Ubuntu 24.04.4 LTS

## Resultados

**Hardening Index: 65% (219/334 puntos)**  
**Estado:** System has been hardened, but could use additional hardening

### Estadísticas
- Tests realizados: 261 / 453
- Warnings: 0
- Sugerencias: 30
- Plugins activos: 1

## Principales Sugerencias de Hardening

### Alta Prioridad
1. **Malware scanner:** Instalar rkhunter, chkrootkit o OSSEC
2. **GRUB password:** Proteger boot loader
3. **Compilers hardening:** Restringir acceso a compiladores (gcc, as)

### Media Prioridad
4. **SSH hardening:** AllowTcpForwarding (YES → NO)
5. **Password policies:** 
   - Configurar rounds de hashing en /etc/login.defs
   - Instalar pam_cracklib o pam_passwdqc
   - Configurar expire dates
6. **Fail2ban:** Copiar jail.conf → jail.local
7. **PAM:** Instalar libpam-tmpdir
8. **Core dumps:** Deshabilitar si no se necesitan

### Baja Prioridad
9. **Particiones separadas:** /home, /tmp, /var
10. **USB drivers:** Deshabilitar si no se usan
11. **Network protocols:** Revisar dccp, sctp, rds, tipc
12. **APT tools:** Instalar apt-listbugs, apt-listchanges, debsums
13. **CUPS:** Endurecer configuración de impresión

## Comandos Ejecutados
```bash
sudo apt install -y lynis
sudo lynis audit system --quick
```

## Próximos Pasos
- Cron semanal configurado para monitoreo continuo
- Revisar sugerencias y aplicar las de alta prioridad
- Documentar cambios aplicados

## Notas
- Sistema ya tiene buena base de seguridad (SSH, firewall, fail2ban)
- 65% es un buen punto de partida
- Mejoras sugeridas son mayormente opcionales para VPS personal
