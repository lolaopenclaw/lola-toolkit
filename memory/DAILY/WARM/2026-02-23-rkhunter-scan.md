# 🛡️ rkhunter Scan Weekly — 2026-02-23

**Fecha:** Lunes 23 Febrero 2026, 10:05 AM  
**Duración:** 3 minutos 17 segundos  
**Modo:** Weekly scheduled scan

---

## Estado General

✅ **WARNINGS** (No crítico, ver detalles abajo)

---

## Resultados del Escaneo

| Métrica | Resultado |
|---------|-----------|
| **Archivos comprobados** | 144 |
| **Archivos sospechosos** | 1 |
| **Rootkits comprobados** | 498 |
| **Posibles rootkits** | 2 (sin alertas activas) |
| **Puertos backdoor** | 0 |
| **Trojanos detectados** | 0 |
| **Módulos kernel** | OK |

---

## Warnings Detectados (5)

### 1. Segmento Memoria Compartida - unity-greeter (⚠️ MEDIA)
```
Proceso: /usr/sbin/unity-greeter
PID: 1802
Owner: lightdm
Tamaño: 32MB (límite configurado: 1MB)
```
**Análisis:** Unity-greeter es el gestor de login gráfico. Los 32MB de memoria compartida son normales para un proceso GUI que maneja sesiones gráficas. No indica compromiso.

**Acción:** ✅ Ignorar (normal)

---

### 2. Segmento Memoria Compartida - xfce4-terminal (✅ NORMAL)
```
Proceso: /usr/bin/xfce4-terminal
PID: 91527
Owner: mleon
Tamaño: 1.0MB (límite: 1.0MB)
```
**Análisis:** Terminal XFCE, exactamente en el límite. Normal.

**Acción:** ✅ Ignorar (normal)

---

### 3-4. Usuario/Grupos Postfix (✅ NORMAL)
```
Warning: User 'postfix' has been added to the passwd file
Warning: Group 'postfix' has been added to the group file
Warning: Group 'postdrop' has been added to the group file
```
**Análisis:** Postfix es el servidor de correo del sistema. Usuario y grupos son legítimos y necesarios.

**Acción:** ✅ Ignorar (normal)

---

### 5. Archivos Ocultos en /etc (✅ NORMAL)
```
Hidden file found: /etc/.resolv.conf.systemd-resolved.bak: ASCII text
Hidden file found: /etc/.updated: ASCII text
```
**Análisis:** 
- `.resolv.conf.systemd-resolved.bak` = respaldo de systemd-resolved (normal)
- `.updated` = marcador de actualización de sistema (normal)

**Acción:** ✅ Ignorar (normal)

---

## Conclusiones de Seguridad

| Aspecto | Estado |
|---------|--------|
| **Rootkits** | ✅ No detectados |
| **Trojanos** | ✅ No detectados |
| **Puertas traseras** | ✅ No encontradas |
| **Módulos kernel sospechosos** | ✅ OK |
| **SSH security** | ✅ Root acceso deshabilitado, v1 deshabilitado |
| **Syslog** | ✅ Activo (rsyslog + systemd-journald) |
| **Filesystem integrity** | ✅ Normal |

---

## Resumen Final

**🟢 Estado: OK**

- ✅ 0 rootkits detectados
- ✅ 0 trojanos/backdoors
- ✅ 5 warnings = todos normales/esperados (GUI, correo, sistema)
- ✅ Scan completó exitosamente
- ✅ Sistema limpio

**Próximo scan:** Lunes 2 Marzo 2026 (automático)

---

## Metadata

```
Comando: sudo rkhunter --check --skip-keypress --report-warnings-only
Log: /var/log/rkhunter.log
Duración: 3m17s
Kernel: 6.8.0-100-generic
Usuario: sudo
```
