# Hardening Fase 2 - 2026-02-20

**Fecha:** 2026-02-20 10:50 UTC  
**Cambios adicionales solicitados por Manu**

## Cambios Implementados

### 1. ✅ Core Dumps Deshabilitados

**Qué es:** Previene volcados de memoria cuando procesos crashean

**Comando:**
```bash
echo "* hard core 0" | sudo tee -a /etc/security/limits.conf
```

**Verificación:**
```bash
ulimit -c
# Output: 0 (core dumps deshabilitados)
```

**Archivo modificado:** `/etc/security/limits.conf`

**Beneficio:**
- Previene fuga de información sensible en crashes
- Passwords, tokens, datos en memoria no se vuelcan a disco
- Reduce superficie de ataque post-mortem

**Impacto:**
- Sesiones nuevas: aplica inmediatamente
- Sesiones existentes: aplica en próximo login
- Sin downtime

---

### 2. ✅ libpam-tmpdir Instalado

**Qué es:** Aísla directorios temporales por sesión PAM

**Versión:** 0.09build1

**Comando:**
```bash
sudo apt install -y libpam-tmpdir
```

**Verificación:**
```bash
dpkg -l | grep libpam-tmpdir
ls -la /usr/lib/x86_64-linux-gnu/security/pam_tmpdir.so
```

**Cómo funciona:**
- Cada sesión PAM (login SSH, sudo, etc.) obtiene su propio /tmp
- $TMP y $TMPDIR apuntan a directorio privado
- Previene race conditions en /tmp compartido
- Limpieza automática al cerrar sesión

**Beneficio:**
- Previene ataques de symlink en /tmp
- Aísla archivos temporales entre usuarios/sesiones
- Previene espionaje de datos temporales

**Impacto:**
- Próximo login: $TMPDIR será privado
- Sin cambios en apps que no usan $TMPDIR
- Sin downtime

---

## Impacto Acumulado

**Hardening Index esperado:**
- Fase 1 (3 cambios): 65% → ~68%
- Fase 2 (2 cambios): ~68% → ~70%
- **Total mejora: +5 puntos**

**Próximo scan Lynis:** Lunes 24 feb (verificará todas las mejoras)

---

## Resumen de Todos los Cambios (Fase 1 + 2)

| # | Cambio | Estado | Beneficio |
|---|--------|--------|-----------|
| 1 | Fail2ban jail.local | ✅ | Config persistente |
| 2 | SSH: AllowTcpForwarding no | ✅ | Sin túneles no autorizados |
| 3 | rkhunter instalado | ✅ | Detección malware |
| 4 | Core dumps disabled | ✅ | Sin volcados de memoria |
| 5 | libpam-tmpdir | ✅ | /tmp aislado por sesión |

**Total cambios aplicados: 5**  
**Tiempo total: ~5 minutos**  
**Downtime: 0 segundos**  
**Problemas: Ninguno**

---

## Verificación en Próximo Login

Para confirmar que libpam-tmpdir funciona:
```bash
# Tras próximo SSH login
echo $TMPDIR
# Debería mostrar: /tmp/user/1000 (o similar)

# Verificar que es privado
ls -ld $TMPDIR
# Debería mostrar permisos 700 (solo tu usuario)
```

---

## Comandos de Reversión (si fuera necesario)

**Core dumps:**
```bash
# Remover línea de limits.conf
sudo sed -i '/\* hard core 0/d' /etc/security/limits.conf
```

**libpam-tmpdir:**
```bash
sudo apt remove --purge libpam-tmpdir
```

---

## Pendiente (Opcional, Futuro)

**Baja prioridad:**
- GRUB password (solo si acceso físico/KVM es riesgo)
- Password policies (solo si añades usuarios)
- Deshabilitar protocolos de red raros (dccp, sctp, rds, tipc)

**NO recomendado:**
- Restringir compiladores (rompe npm)
- Particiones separadas (requiere reinstalación)
