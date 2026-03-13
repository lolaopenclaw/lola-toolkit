# 🛡️ Critical Update Protocol

## Resumen

Framework para aplicar cambios críticos (SSH, firewall, servicios) con seguridad total: baseline → sandbox → apply → validate → auto-rollback.

**Objetivo:** 0 lockouts, 100% recovery en <2 min.

**Lección origen (2026-02-20):** `AllowTcpForwarding=no` rompió VNC y casi causó lockout total.

---

## Script: `scripts/critical-update.sh`

```bash
bash scripts/critical-update.sh [OPCIÓN] [ARGS]
  --baseline        # Capturar health snapshot
  --test FILE       # Validar cambio en sandbox
  --apply FILE      # Aplicar real (backup + validate + auto-rollback)
  --dry-run FILE    # Simular sin cambios
  --rollback [FILE] # Restaurar backup
  --validate        # Ejecutar validaciones
  --status          # Estado actual
  --log MSG         # Entrada manual en audit trail
```

---

## Flujo Completo (Protocolo A+B)

### Paso 1: Baseline
```bash
bash scripts/critical-update.sh --baseline
```
Captura: SSH, firewall, network, services, disk, memory → `/tmp/critical-baseline-*`

### Paso 2: Preparar cambio en sandbox
```bash
bash scripts/critical-update.sh --test /etc/ssh/sshd_config
# Editar: /tmp/critical-sandbox/sshd_config
```

### Paso 3: Validar sandbox
```bash
bash scripts/critical-update.sh --test /etc/ssh/sshd_config
```
Verifica syntax, detecta settings peligrosos, muestra diff.

### Paso 4: Aplicar (o dry-run)
```bash
bash scripts/critical-update.sh --dry-run /etc/ssh/sshd_config  # primero simular
bash scripts/critical-update.sh --apply /etc/ssh/sshd_config    # aplicar real
```
Auto-rollback si validaciones fallan post-apply.

### Paso 5: Validar estabilidad
```bash
bash scripts/critical-update.sh --validate
```

---

## Validaciones Automáticas

| Categoría | Checks |
|-----------|--------|
| SSH | Servicio activo, puerto 22, syntax config |
| Firewall | UFW activo, SSH permitido |
| Network | DNS, gateway, ping 8.8.8.8, HTTPS |
| Services | fail2ban, openclaw-gateway |
| Resources | Disco >10% libre, memoria disponible |

**Si cualquier check falla post-apply → rollback inmediato automático.**

---

## Audit Trail

Cada acción se registra en `memory/CHANGES/changes-YYYY-MM-DD.log`:
- Timestamp, acción, descripción, detalles, usuario, baseline

---

## Integración con canary-test.sh

Para cambios complejos multi-servicio:
```bash
bash scripts/canary-test.sh start      # baseline canary
# hacer cambios
bash scripts/canary-test.sh test       # validar
bash scripts/canary-test.sh validate   # confirmar
bash scripts/canary-test.sh rollback   # si falla
```

---

## Qué hacer si el rollback falla

1. **No entrar en pánico** — los backups están en `/tmp/critical-backups/`
2. Restaurar manualmente: `sudo cp /tmp/critical-backups/FILE /etc/path/to/file`
3. Reiniciar servicio: `sudo systemctl restart SERVICE`
4. Si SSH roto: usar consola web del proveedor VPS
5. Si todo falla: restaurar desde backup Drive

---

## Settings peligrosos conocidos

| Setting | Riesgo | Detección |
|---------|--------|-----------|
| `AllowTcpForwarding no` | Rompe VNC/tunnels | ⚠️ Warning en --test |
| `PermitRootLogin yes` | Seguridad | ⚠️ Warning en --test |
| UFW deny all sin allow 22 | Lockout SSH | Validación post-apply |

---

## Checklist Pre-Cambio

- [ ] Baseline capturado (`--baseline`)
- [ ] Manu informado del cambio
- [ ] Sesión SSH de respaldo abierta (PuTTY extra)
- [ ] Backup Drive reciente verificado
- [ ] Cambio probado en sandbox (`--test`)
- [ ] Dry-run ejecutado (`--dry-run`)

## Checklist Post-Cambio

- [ ] Todas las validaciones pasan (`--validate`)
- [ ] Manu confirma que funciona
- [ ] Audit trail registrado
- [ ] Sandbox limpio
