# 📋 Tareas Recomendadas - Auditoría Seguridad 2026-02-23

**Generado:** 2026-02-23 10:01 AM (cron job semanal)
**Basado en:** Auditoría de seguridad profunda
**Origen:** `memory/2026-02-23-security-audit-weekly.md`

---

## 🔴 CRÍTICO (Esta semana - 15 min)

### 1. Fix PAM Modules Missing

**Problema:** `/etc/pam.d/common-auth` referencia módulos que no existen:
- `pam_tally2.so` — Desaparece en Ubuntu 24.04 LTS
- `pam_pwquality.so` — Desaparece en Ubuntu 24.04 LTS

**Síntoma:** Warnings en syslog en cada intento SSH fallido
```
PAM unable to dlopen(pam_tally2.so): cannot open shared object file
PAM unable to dlopen(pam_pwquality.so): cannot open shared object file
```

**Impacto:**
- ❌ Conteo de fallos de autenticación deshabilitado (pam_tally2)
- ❌ Validación de contraseña débil deshabilitada (pam_pwquality)
- ⚠️ Logs contaminados con warnings (ruido)
- ✅ Acceso actual funciona (PAM failsafe)

**Solución (Opción A - Instalar):**
```bash
sudo apt install libpam-cracklib libpam-modules
# Esto proporciona pam_cracklib.so (reemplazo moderno de pam_pwquality)
```

**Solución (Opción B - Limpiar config):**
```bash
sudo cp /etc/pam.d/common-auth /etc/pam.d/common-auth.backup.2026-02-23
sudo nano /etc/pam.d/common-auth
# Comentar o remover líneas:
#   auth    required                        pam_tally2.so onerr=fail audit silent deny=5 unlock_time=900
# Y si existe:
#   auth    required    pam_pwquality.so retry=3
```

**Recomendación:** Opción A (instalar) es más robusta si quieres protección contra brute-force

**Esfuerzo:** 15 minutos
**Riesgo:** BAJO (PAM failsafe, no rompe nada)
**Prioridad:** MEDIA

---

## 🟡 RECOMENDADO (Próximas 2 semanas - 30 min total)

### 2. Revisar y Restringir SMTP Puerto 25

**Problema:** Puerto 25 está abierto globalmente a 0.0.0.0
- Postfix escuchando en 0.0.0.0:25
- Podría ser usado como relay de spam (si no está bien configurado)

**Verificar configuración:**
```bash
sudo grep -n "inet_interfaces" /etc/postfix/main.cf
```

**Si dice `inet_interfaces = all` o `inet_interfaces = 0.0.0.0`:**

**Solución (si no necesitas SMTP global):**
```bash
sudo nano /etc/postfix/main.cf
# Cambiar:
#   inet_interfaces = all
# A:
#   inet_interfaces = loopback-only
# O:
#   inet_interfaces = localhost

# Luego reload:
sudo systemctl reload postfix

# Verifica:
sudo netstat -tuln | grep 25
# Debería mostrar solo 127.0.0.1:25, no 0.0.0.0:25
```

**Beneficio:** Reduce attack surface, evita spam relay
**Esfuerzo:** 20 minutos
**Riesgo:** BAJO (si OpenClaw/alertas solo usan localhost)
**Prioridad:** MEDIA

---

### 3. Desabilitar X11Forwarding en SSH

**Problema:** SSH permite X11 display forwarding
- Configurado como `X11Forwarding=yes`
- X11 puede ser vector de explotación remota

**Solución:**
```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.2026-02-23
sudo sed -i 's/^X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config

# Verifica:
sudo grep "X11Forwarding" /etc/ssh/sshd_config

# Reload SSH:
sudo systemctl reload ssh
```

**Beneficio:** Reduce attack surface
**Esfuerzo:** 5 minutos
**Riesgo:** BAJO (X11 forwarding probablemente no se usa)
**Prioridad:** BAJA (nice-to-have)

---

## 🟢 INFORMACIÓN (Validar)

### 4. Puerto 42613 Desconocido

**Problema:** Un puerto escuchando en localhost:42613
```bash
lsof -i :42613  # Devolvería qué servicio usa este puerto
```

**Verificación:**
```bash
sudo netstat -tuln | grep 42613
sudo ss -tuln | grep 42613
ps aux | grep -E ":(42613|42613)"
```

**Si no hay nada escuchando actualmente, es probablemente un proceso que cierra/abre dinámicamente.**

**Acción:** Ignorar si no aparece en próximas auditorías

---

## 📌 Checklist de Implementación

Para Manu:

- [ ] **CRÍTICO:** Fix PAM modules
  - [ ] Opción A (instalar): `sudo apt install libpam-cracklib`
  - [ ] O Opción B (limpiar config)
  - [ ] Validar sin warnings: `ssh-keyscan localhost 2>&1 | grep -i pam`

- [ ] **RECOMENDADO:** SMTP puerto 25
  - [ ] Verificar: `grep inet_interfaces /etc/postfix/main.cf`
  - [ ] Si es necesario, restringir a localhost
  - [ ] Reload postfix

- [ ] **RECOMENDADO:** X11Forwarding
  - [ ] Cambiar en `/etc/ssh/sshd_config`
  - [ ] Reload SSH
  - [ ] Validar: `sudo sshd -T | grep X11Forwarding`

- [ ] **INFORMACIÓN:** Puerto 42613
  - [ ] Investigar si está en uso
  - [ ] Ignorar si es temporal

---

## 📊 Resumen de Esfuerzo

| Tarea | Esfuerzo | Prioridad | Risk |
|-------|----------|-----------|------|
| PAM modules | 15 min | MEDIA | BAJO |
| SMTP restrict | 20 min | MEDIA | BAJO |
| X11Forwarding | 5 min | BAJA | BAJO |
| Puerto 42613 | 5 min | BAJA | N/A |
| **TOTAL** | **45 min** | **MEDIA** | **BAJO** |

---

**Siguientes auditorías:** Cada lunes 10:01 AM
**Próxima:** 2026-03-02

