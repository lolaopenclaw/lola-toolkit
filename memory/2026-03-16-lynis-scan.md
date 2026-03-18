# Lynis Security Scan - 2026-03-16 (Weekly)

**Fecha:** Lunes 16 de marzo de 2026 - 9:04 AM  
**Tipo:** Scan semanal (agenda: lunes 9:00 AM)  
**Versión Lynis:** 3.1.6

## 📊 Resumen Ejecutivo

```
Hardening Index: 74%
Warnings: 1
Suggestions: 31
Cambio vs anterior (09/03): MÍNIMA DEGRADACIÓN (−1 pt, +1 warning, +1 suggestion)
Estado: ⚠️ MONITORED (reboot required)
```

## 🔐 Comparativa vs Anterior (09/03/2026)

| Métrica | Actual | Anterior | Cambio | Status |
|---------|--------|----------|--------|--------|
| Hardening Index | 74% | 75% | −1 pt | Mínimo |
| Warnings | 1 | 0 | +1 (nuevo) | ⚠️ Reboot |
| Suggestions | 31 | 30 | +1 (3.3%) | Normal |

## 🔍 Warning Detectado

### KRNL-5830: Reboot Required
- **Severidad:** Media
- **Descripción:** El sistema requiere reinicio para aplicar actualizaciones de kernel
- **Acción:** Considerar reinicio en ventana de mantenimiento
- **Contexto:** Kernel updates instalados, pendientes de activación

## 📈 Análisis

- **Degradación mínima:** Hardening index bajó 1 punto (dentro de variabilidad)
- **1 warning nuevo:** KRNL-5830 (reboot) — no crítico, informativo
- **+1 suggestion:** Aumento esperado después de kernel update
- **No hay warnings de seguridad críticos**
- **Conclusión:** Sistema mantiene postura de seguridad. Reboot recomendado en próxima ventana.

## 💡 Detalle de Warnings (1)

```
KRNL-5830: Reboot of system is most likely needed
```

## 💡 Top Suggestions Actuales (31)

### Grupo SSH (Principal, 4):
- **SSH-7408:** Hardening de configuración SSH
  - AllowTcpForwarding: YES → NO
  - TCPKeepAlive: YES → NO
  - AllowAgentForwarding: YES → NO
  - Port (cambio sugerido)

### Infraestructura (6):
- **BOOT-5122:** Proteger GRUB con contraseña
- **FILE-6310:** Particionar /home, /tmp, /var (3 sugerencias)
- **FIRE-4513:** Revisar iptables no utilizadas

### Autenticación (5):
- **AUTH-9229:** PAM configuration y password rotation
- **AUTH-9262:** Instalar pam_cracklib o pam_passwdqc
- **AUTH-9282:** Establecer fechas de expiración para cuentas
- Otros ajustes PAM

### Debian/Package (5):
- **DEB-0810:** apt-listbugs
- **DEB-0811:** apt-listchanges
- **PKGS-7346:** Purge old packages (2 found)
- **PKGS-7394:** apt-show-versions

### Otros (11):
- **BOOT-5264:** Hardening de servicios systemd
- **NAME-4028/4404:** DNS y /etc/hosts
- **LOGG-2154:** External logging host
- **LOGG-2190:** Archivos eliminados aún en uso
- +6 sugerencias menores

## ✨ Conclusión

**Sistema monitoreado — reboot recomendado**

- ✅ Hardening index: 74% (−1 pt, dentro de variabilidad)
- ⚠️ Warnings: 1 (KRNL-5830, informativo, reboot needed)
- ✅ Suggestions: 31 (aumento esperado, no crítico)

**Recomendación:** Programar reinicio en próxima ventana de mantenimiento para activar kernel updates.

Próximo scan: Lunes, 23 de marzo de 2026 - 9:00 AM
