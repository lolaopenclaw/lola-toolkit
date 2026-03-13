# Lynis Security Scan - 2026-02-23 (Baseline)

**Fecha:** Lunes 23 de febrero de 2026 - 10:03 AM  
**Tipo:** Scan semanal (agenda: lunes 10:00 AM)  
**Versión Lynis:** 3.0.9

## 📊 Resumen Ejecutivo

```
Hardening Index: 70%
Warnings: 1
Suggestions: 44
Estado: BASELINE (Primer scan - No hay comparación anterior)
```

## 🔐 Métricas Principales

| Métrica | Valor | Status |
|---------|-------|--------|
| Hardening Index | 70% | ⚠️ Moderado |
| Warnings | 1 | ⚠️ Información importante |
| Suggestions | 44 | ℹ️ Recomendaciones de mejora |

## ⚠️ Warnings (1)

### MAIL-8818: Information Disclosure en SMTP Banner
- **Severidad:** Baja
- **Descripción:** Se detectó información de identificación (OS/software) en el banner SMTP
- **Componente:** Postfix
- **Recomendación:** Ocultar `mail_name` en configuración de Postfix
- **Acción sugerida:** Cambiar `smtpd_banner` en `/etc/postfix/main.cf`

## 💡 Top 10 Suggestions por Prioridad

### Críticas / High Impact:
1. **SSH-7408:** Hardening de configuración SSH
   - AllowTcpForwarding: YES → NO ⚠️ (ya configurado en protocolo anterior)
   - ClientAliveCountMax: 3 → 2
   - MaxAuthTries: 6 → 3
   - MaxSessions: 10 → 2
   - X11Forwarding: YES → NO
   - AllowAgentForwarding: YES → NO
   - TCPKeepAlive: YES → NO
   - LogLevel: INFO → VERBOSE
   - Port: cambiar de 22 (se recomienda puerto alternativo)

2. **BOOT-5122:** Proteger GRUB con contraseña
   - Prevenir alteración de configuración de arranque

3. **FILE-6310:** Particiones separadas para /home, /tmp, /var
   - Mitigar impacto de disco lleno

### Moderadas:
4. **KRNL-6000:** Optimizar valores de sysctl según perfil
5. **AUTH-9229 / AUTH-9262 / AUTH-9282:** Políticas de contraseñas PAM
6. **FINT-4350:** Herramienta de integridad de archivos (AIDE, tripwire)
7. **ACCT-9628:** Habilitar auditd para auditoría de cambios

### Bajas (Informativas):
8. **LYNIS:** Actualizar Lynis (>4 meses sin actualizar)
9. **DEB-0810 / DEB-0811:** Herramientas de APT (apt-listbugs, apt-listchanges)
10. **NAME-4028 / NAME-4404:** Configuración DNS en /etc/hosts

## 🔧 Próximos Pasos Recomendados

### Inmediatos (Esta semana):
- [ ] MAIL-8818: Hardening de Postfix (reducir fingerprint)
- [ ] SSH-7408: Review y aplicar cambios SSH (validar acceso antes)

### Próximas dos semanas:
- [ ] BOOT-5122: GRUB password
- [ ] AUTH-9262: PAM module para password strength

### Próximo mes:
- [ ] FINT-4350: Implementar file integrity monitoring
- [ ] KRNL-6000: Kernel hardening (sysctl tuning)

## 📝 Notas Técnicas

**Baseline establecido:** Este es el primer scan programado. Los próximos scans (semanales) se compararán contra estas métricas para detectar:
- ↓ Hardening index >5 puntos
- ⬆️ Nuevos warnings
- ⬆️ Aumento significativo de suggestions

**Versión:** Lynis 3.0.9 (recomendación: actualizar a versión reciente)

**Próximo scan programado:** Lunes, 2 de marzo de 2026 - 10:00 AM
