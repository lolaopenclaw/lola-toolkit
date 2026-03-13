# 🧪 Canary Testing Protocol — 2026-02-21

**Objetivo:** Prevenir desastres en cambios críticos (SSH, firewall, network)  
**Inspiración:** Phoenix Shield (ClawHub), experiencia con "AllowTcpForwarding no"  
**Herramienta:** `scripts/canary-test.sh`

---

## 🎯 Problema Resuelto

**Antecedente:** 2026-02-20  
- Cambio SSH: `AllowTcpForwarding no` para hardening
- Consecuencia: ¡VNC roto! Sin acceso remoto gráfico
- Raíz: No se validó el cambio ANTES de aplicar
- Lección: **SIEMPRE hacer test pre-update**

---

## 📋 Flujo Canary Testing

```
[PRE-CHANGE]
  ↓
1. bash canary-test.sh start
   ↓
   Snapshot: SSH, network, firewall, services
   Baseline guardado en /tmp/canary-baseline-latest

[CRITICAL CHANGE]
  ↓
2. Editar /etc/ssh/sshd_config o similar
   ↓
   systemctl reload ssh / ufw enable / etc.

[POST-CHANGE]
  ↓
3. bash canary-test.sh test
   ↓
   ¿SSH sigue activo? ¿Puedo conectarme?
   ¿Firewall funciona? ¿Servicios OK?

4. bash canary-test.sh validate
   ↓
   Compara contra baseline
   ¿AllowTcpForwarding habilitado? ¿PubkeyAuth OK?

[RESULTADO]
  ↓
✓ TODO OK      → Cambio APROBADO (confirmar)
✗ ALGO FALLÓ   → bash canary-test.sh rollback (manual)
```

---

## 🛠️ Uso en Detalle

### **Paso 1: Snapshot Baseline (PRE-CAMBIO)**

```bash
bash ~/.openclaw/workspace/scripts/canary-test.sh start
```

**Output:**
```
[✓] Capturando health baseline...
[✓] Baseline guardado en: /tmp/canary-baseline-20260221-154530
[✓] Acceso rápido: /tmp/canary-baseline-latest

=== BASELINE SNAPSHOT ===
[SSH STATUS, FIREWALL, PORTS, SERVICES, etc.]
```

**Qué captura:**
- ✅ SSH: servicio activo, puerto 22, config crítica
- ✅ Firewall: UFW status, reglas activas
- ✅ Network: interfaces, routing, DNS
- ✅ Services: fail2ban, ssh, ufw estados
- ✅ Disk/Memory: espacio disponible

### **Paso 2: Aplica el Cambio Crítico**

```bash
# Ejemplo: Habilitar AllowTcpForwarding (lo que debí haber hecho)
sudo nano /etc/ssh/sshd_config
# → Cambiar "AllowTcpForwarding no" a "AllowTcpForwarding yes"

sudo systemctl reload ssh
```

### **Paso 3: Test de Conectividad**

```bash
bash ~/.openclaw/workspace/scripts/canary-test.sh test
```

**Output:**
```
[✓] Testando conectividad...
[✓] SSH local: OK
[✓] SSH port listening: OK
[✓] External ping: OK
[✓] Firewall: ACTIVE

[✓] Testando servicios críticos...
[✓] ssh: ACTIVE
[✓] fail2ban: ACTIVE

[✓] All tests PASSED
```

Si algo falla → ve a Paso 5 (Rollback)

### **Paso 4: Validación contra Baseline**

```bash
bash ~/.openclaw/workspace/scripts/canary-test.sh validate
```

**Output:**
```
[✓] Validando contra baseline...
[✓] SSH service is ACTIVE
[✓] SSH port NOT LISTENING
[✓] SSH: PubkeyAuthentication enabled
[✓] AllowTcpForwarding is ENABLED ✓
[✓] All validations PASSED
```

Si algo no coincide → Paso 5

### **Paso 5A: Cambio APROBADO**

```bash
echo "✓ Cambio validado. Listo para producción."
```

### **Paso 5B: ROLLBACK (Si algo falló)**

```bash
bash ~/.openclaw/workspace/scripts/canary-test.sh rollback
```

**Salida:**
```
❌ ROLLBACK INITIATED
[!] Broken configs backed up to: /tmp/canary-backup-20260221-154530
[!] Manual restore may be needed. Contact Manu.
```

**Manual recovery:**
```bash
# Restaurar desde backup pre-cambio
sudo cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
sudo systemctl reload ssh
```

---

## 🔍 Settings Críticos Monitoreados

| Setting | Impacto | Fallback |
|---------|---------|----------|
| **SSH Service Active** | Acceso remoto | Crítico — contactar Manu |
| **SSH Port 22 Listening** | Conectividad | Crítico — contactar Manu |
| **PubkeyAuthentication** | Acceso key-based | ⚠️ Fallback a password (menos seguro) |
| **AllowTcpForwarding** | VNC, tunnels | ❌ Rompe VNC remoto |
| **PermitRootLogin** | Root access | ⚠️ Cambio sin impacto crítico |
| **Firewall Status** | UFW activa | ⚠️ Check manual |

---

## 📊 Scoring de Cambios Críticos

### ⛔ **ALTO RIESGO — SIEMPRE usar canary**
- SSH config changes (puerto, autenticación, forwarding)
- Firewall rules (UFW, iptables)
- Network config (interfaces, routing)
- Fail2ban jail configuration

### 🟡 **RIESGO MODERADO — Recomendar canary**
- System services changes
- Security limits (PAM, limits.conf)
- Sudoers configuration

### 🟢 **BAJO RIESGO — Opcional**
- Package updates (apt)
- Documentation edits
- Memory/cache adjustments

---

## 🧬 Integración con Critical-Change Checklist

**Antes de cualquier cambio crítico (SSH, firewall):**

```bash
# PASO 0: PRE-FLIGHT CHECK
bash ~/.openclaw/workspace/scripts/canary-test.sh start
# ← Esto genera baseline

# PASO 1: CAMBIO CONTROLADO
# [Hacer el cambio]

# PASO 2: VALIDACIÓN
bash ~/.openclaw/workspace/scripts/canary-test.sh test   # Conectividad OK?
bash ~/.openclaw/workspace/scripts/canary-test.sh validate # Settings OK?

# PASO 3: APROBACIÓN (por Manu o automation)
# [Cambio aprobado]

# PASO 4: BACKUP
bash ~/.openclaw/workspace/scripts/backup-memory.sh --manual
```

---

## 💾 Ejemplo: SSH AllowTcpForwarding Fix

**Problema (2026-02-20):**
```bash
AllowTcpForwarding no  # ← VNC ROTO
```

**Con Canary Testing (cómo hubiera sido):**

```bash
# 1. Baseline
bash canary-test.sh start
# → Snapshot guardado

# 2. Cambio
sudo nano /etc/ssh/sshd_config
# AllowTcpForwarding no  →  AllowTcpForwarding yes

# 3. Test
bash canary-test.sh test
# [✓] SSH local: OK
# [✓] SSH port listening: OK

# 4. Validate
bash canary-test.sh validate
# [✓] AllowTcpForwarding is ENABLED ✓
# [✓] All validations PASSED

# 5. Aprovado
echo "✓ Cambio seguro. VNC sigue funcionando."
```

**Sin canary → DESASTRE**  
**Con canary → SEGURO**

---

## 🔐 Security Considerations

**Baseline sensible:**
- Passwords: NO capturados
- SSH keys: NO capturados
- Secrets: NO capturados
- Sólo: estados, configuración, actividad

**Rollback seguro:**
- Backup pre-cambio: sí
- Auto-rollback: NO (manual requiere Manu)
- Contacto en fallo: SIEMPRE

---

## 📝 Reporte de Test

Ejemplo output completo:
```
=== CONNECTIVITY TESTS ===
[✓] SSH local: OK
[✓] SSH port listening: OK
[✓] External ping: OK

=== SERVICE TESTS ===
[✓] ssh: ACTIVE
[✓] fail2ban: ACTIVE

=== FIREWALL TESTS ===
[✓] Firewall: ACTIVE

[✓] All tests PASSED
```

---

## ⏱️ Timing

**Cuándo usar canary testing:**
- PRE-CHANGE: `bash canary-test.sh start` (5 segundos)
- DURANTE: Aplica cambio (5-30 min)
- POST-CHANGE: `bash canary-test.sh test` (10 segundos)
- VALIDACIÓN: `bash canary-test.sh validate` (5 segundos)

**Total overhead:** ~1 minuto para potencialmente evitar horas de recuperación

---

## 📚 Referencias

Inspirado en:
- **Phoenix Shield (ClawHub):** Self-healing backups + canary testing
- **Blue-Green Deployments:** Cambios seguros en producción
- **Pre-flight checks (aviación):** Verificar antes de despegar

---

**Implementación:** 2026-02-21  
**Próxima mejora:** Auto-rollback en caso de fallo (requiere SSH backup remoto)

---

*Lección aprendida el 2026-02-20 con AllowTcpForwarding no. Nunca más sin validation.*
