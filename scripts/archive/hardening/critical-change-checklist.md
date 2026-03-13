# ✅ Critical Change Checklist — SSH, Firewall, Network

**Usar SIEMPRE antes de:** SSH, firewall, port forwarding, Fail2Ban, servicios de red  
**NOVEDAD 2026-02-21:** Integración de Canary Testing (`scripts/canary-test.sh`)

---

## 🚀 Decision Tree

```
¿Cambio SSH/Firewall/Network?
  ↓
Sí → [PRE-CAMBIO: Fase 1-2]
     ↓
     [CAMBIO: Fase 3-4]
     ↓
     [POST-CAMBIO: Fase 5-6 con Canary]
     
     ✓ OK?  → Cambio APROBADO
     ✗ FAIL → Rollback inmediato
  ↓
No  → Cambio directo (sin protocolo)
```

---

## 📋 FASE 1: Pre-Cambio — Backup & Baseline

- [ ] **1. Backup automático**
  ```bash
  bash ~/.openclaw/workspace/scripts/backup-memory.sh
  ```
  - Verificar que subió a Google Drive
  - Si falla → ABORTAR cambio

- [ ] **2. Canary baseline snapshot** ← NUEVO 2026-02-21
  ```bash
  bash ~/.openclaw/workspace/scripts/canary-test.sh start
  ```
  - Captura: SSH config, firewall, network, servicios
  - Guardado automáticamente en `/tmp/canary-baseline-latest`
  - Usaremos para validar post-cambio

- [ ] **3. Backup del archivo original**
  ```bash
  sudo cp /ruta/archivo /ruta/archivo.backup-$(date +%Y%m%d-%H%M%S)
  ```

---

## 📋 FASE 2: Pre-Cambio — Análisis & Comunicación

- [ ] **4. Análisis de impacto**
  - ¿Afecta a SSH? → Puede dejarme sin acceso
  - ¿Afecta a port forwarding? → Puede romper VNC ⚠️ CRÍTICO
  - ¿Afecta al firewall? → Puede bloquear conexiones
  - ¿Puede banear IP de Manu? → Dejaría sin acceso

- [ ] **5. Avisar a Manu por Telegram**
  - Qué voy a cambiar
  - Qué puede verse afectado (VNC, SSH, etc.)
  - Pedirle que abra otra ventana de PuTTY como sesión de respaldo

---

## 📋 FASE 3: Durante el Cambio — Ejecución Controlada

- [ ] **6. Manu mantiene sesión SSH de respaldo abierta**
  - No cerrar hasta validar cambio
  - Fallback en caso de problemas

- [ ] **7. Aplicar cambio**
  - Para SSH: `sudo systemctl reload ssh` (NO restart, para no interrumpir sesiones actuales)
  - Para firewall: aplicar reglas una a una
  - Para servicios: usar `reload` si es posible

- [ ] **8. Validar sintaxis (antes de aplicar)**
  ```bash
  # SSH
  sudo sshd -t
  
  # Firewall
  sudo ufw status numbered
  
  # Fail2Ban
  sudo fail2ban-client status
  ```

---

## 📋 FASE 4: Post-Cambio — Testing Automático (Canary)

- [ ] **9. Test de conectividad**
  ```bash
  bash ~/.openclaw/workspace/scripts/canary-test.sh test
  ```
  - ✓ SSH local: OK?
  - ✓ SSH port 22 listening?
  - ✓ Servicios críticos activos?
  
  **Si FALLA → Ir a Fase 7 (Rollback)**

- [ ] **10. Validación contra baseline**
  ```bash
  bash ~/.openclaw/workspace/scripts/canary-test.sh validate
  ```
  - ✓ AllowTcpForwarding enabled? (VPN critical)
  - ✓ PubkeyAuthentication OK?
  - ✓ Firewall rules applied?
  
  **Si FALLA → Ir a Fase 7 (Rollback)**

---

## 📋 FASE 5: Post-Cambio — Validación Manual

- [ ] **11. Validar desde otra sesión SSH**
  ```bash
  ssh mleon@79.117.197.5
  ```
  - Abrir nueva conexión en otra terminal
  - Si conecta → SSH OK

- [ ] **12. Validar VNC (si aplica)**
  ```bash
  nc -zv 127.0.0.1 5901
  ```
  - O desde Windows (PuTTY tunnel):
  ```bash
  Test-NetConnection -ComputerName localhost -Port 5901
  ```

- [ ] **13. Pedir a Manu que valide desde su lado**
  - "Prueba VNC desde tu máquina"
  - "Prueba abrir nueva sesión SSH"
  - "Verifica que funciona todo"

---

## 📋 FASE 6: Post-Cambio — Decisión Final

**✅ Si TODO funciona:**
- [ ] Confirmar cambio exitoso
- [ ] Manu puede cerrar sesión SSH de respaldo
- [ ] Documentar en `memory/YYYY-MM-DD.md`
- [ ] Cambio APROBADO

**❌ Si ALGO falla:**
- [ ] Ir a Fase 7 (Rollback)

---

## 🚨 FASE 7: Recovery — Rollback Inmediato

Si `canary-test.sh test` O `validate` fallan:

### Opción 1: Canary Rollback
```bash
bash ~/.openclaw/workspace/scripts/canary-test.sh rollback
```
- Hace backup del estado "broken"
- Requiere manual restore (ver Opción 2)

### Opción 2: Manual Rollback
```bash
# Restaurar desde backup pre-cambio
sudo cp /ruta/archivo.backup-YYYYMMDD-HHMMSS /ruta/archivo

# O desde git si aplica
git checkout /ruta/archivo

# Recargar servicio
sudo systemctl reload ssh / firewall / etc.
```

### Opción 3: SSH no responde (último recurso)
1. Usar sesión de respaldo que Manu mantuvo abierta
2. `sudo cp /etc/ssh/sshd_config.backup-* /etc/ssh/sshd_config`
3. `sudo systemctl reload ssh`
4. Si aún no funciona → contactar Manu para acceso físico

---

## 🔧 Cambios Específicos & Troubleshooting

### SSH (/etc/ssh/sshd_config)
**Crítico:** AllowTcpForwarding (VNC), PasswordAuthentication, PermitRootLogin

```bash
# Pre-cambio
Backup: ✅
Canary start: ✅

# Aplicar
sudo nano /etc/ssh/sshd_config  # [CAMBIO]
sudo sshd -t                     # Validar sintaxis
sudo systemctl reload ssh        # NO restart

# Post-cambio
bash canary-test.sh test         # Conectividad
bash canary-test.sh validate     # AllowTcpForwarding?
```

**Troubleshooting:**
- SSH no responde → Usar sesión respaldo, rollback
- VNC roto → Verificar `AllowTcpForwarding yes`
- Port forwarding fallido → `grep AllowTcpForwarding /etc/ssh/sshd_config`

### Firewall (UFW)
**Crítico:** Puerto 22 SIEMPRE debe estar permitido

```bash
# Pre-cambio
Backup reglas: sudo ufw status numbered > ~/ufw-backup-$(date +%Y%m%d).txt

# Aplicar UNA REGLA A LA VEZ
sudo ufw allow 22
sudo ufw allow 443
# [Test conectividad]
sudo ufw deny 23
# [Test conectividad]

# Post-cambio
bash canary-test.sh test         # Firewall OK?
bash canary-test.sh validate     # Reglas aplicadas?
```

**Troubleshooting:**
- Firewall bloqueó SSH → `sudo ufw disable`, revert rules
- Puerto 22 bloqueado → `sudo ufw allow 22`

### Fail2Ban (/etc/fail2ban/jail.local)
**Crítico:** No banear IP de Manu (79.117.197.5)

```bash
# Pre-cambio
Backup: sudo cp /etc/fail2ban/jail.local /etc/fail2ban/jail.local.backup-$(date +%Y%m%d)

# Verificar IP no está baneada ANTES
sudo fail2ban-client status sshd

# Aplicar cambio
sudo nano /etc/fail2ban/jail.local
sudo systemctl reload fail2ban

# Post-cambio
bash canary-test.sh validate     # Fail2ban activo?
sudo fail2ban-client status sshd # IP no baneada?
```

**Si IP está baneada:**
```bash
sudo fail2ban-client set sshd unbanip 79.117.197.5
```

---

## 🎓 Lecciones Aprendidas

### El Desastre del 2026-02-20
```
Cambio: AllowTcpForwarding no (para hardening)
Consecuencia: VNC roto
Raíz: No validado pre-aplicar
Tiempo de debug: 1 hora
```

**Solución: Canary Testing**
```
Cambio: AllowTcpForwarding no
bash canary-test.sh validate
[✗] AllowTcpForwarding DISABLED
Rollback inmediato
Cero downtime
```

---

## ⏱️ Timing Estimado

| Fase | Tiempo | Notas |
|------|--------|-------|
| Pre-cambio (1-5) | 5 min | Backup + canary start |
| Cambio (6-8) | 5-30 min | Variable según complejidad |
| Testing (9-10) | 20 sec | Canary test + validate |
| Validación manual (11-13) | 5 min | SSH + VNC + Manu |
| **Total** | **15-45 min** | Worth it para evitar desastres |

---

## ✨ Checklist Ejecutivo

```
☐ 1. Backup automático → Drive
☐ 2. Canary baseline snapshot
☐ 3. Backup archivo original
☐ 4. Análisis de impacto completado
☐ 5. Manu notificado + sesión respaldo
☐ 6. [CAMBIO APLICADO]
☐ 7. canary-test.sh test → PASS
☐ 8. canary-test.sh validate → PASS
☐ 9. SSH nueva conexión → OK
☐ 10. VNC conexión → OK
☐ 11. Manu confirma TODO OK
☐ 12. Documentación completada
☐ ✓ CAMBIO APROBADO
```

---

## 📚 Referencias

- `memory/PROTOCOLS/canary-testing-protocol.md` — Guía Canary Testing
- `scripts/canary-test.sh` — Script de validación
- `memory/security-change-protocol.md` — Protocolo A+B completo

---

**Vigencia:** 2026-02-21 onwards  
**Tipo:** Checklist + Canary Testing integrado  
**Próxima mejora:** Auto-rollback vía respaldo remoto

*"Never again. AllowTcpForwarding no. Always test first."*
