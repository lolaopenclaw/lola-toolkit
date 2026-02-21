# Sysctl Kernel Hardening Protocol

**Aplicado:** 2026-02-21
**Estándar:** CIS Benchmark / NIST

## Parámetros Aplicados

### Kernel
| Parámetro | Valor | Propósito |
|---|---|---|
| `kernel.kptr_restrict` | 2 | Oculta kernel pointers de TODOS los usuarios (previene info disclosure) |
| `kernel.yama.ptrace_scope` | 1 | ptrace solo parent→child (previene process injection) |
| `kernel.dmesg_restrict` | 1 | dmesg solo root (previene info disclosure) |
| `kernel.unprivileged_userns_clone` | 0 | Sin user namespaces para no-root (reduce attack surface) |

### Network
| Parámetro | Valor | Propósito |
|---|---|---|
| `net.ipv4.conf.*.accept_source_route` | 0 | Rechaza source-routed packets (anti-spoofing) |
| `net.ipv6.conf.*.accept_source_route` | 0 | IPv6 equivalent |
| `net.ipv4.conf.*.log_martians` | 1 | Log paquetes con direcciones imposibles |
| `net.ipv4.tcp_syncookies` | 1 | Protección SYN flood |
| `net.ipv4.tcp_timestamps` | 1 | Defense-in-depth |

### Filesystem
| Parámetro | Valor | Propósito |
|---|---|---|
| `fs.protected_hardlinks` | 1 | Previene TOCTOU via hardlinks |
| `fs.protected_symlinks` | 1 | Previene privesc via symlinks |
| `fs.protected_regular` | 2 | Protección estricta archivos regulares |

### System
| Parámetro | Valor | Propósito |
|---|---|---|
| `vm.swappiness` | 10 | Minimiza swap (performance + seguridad) |

## Parámetros NO disponibles en este kernel
- `kernel.unprivileged_ns_clone` — no existe en kernel 6.8.0
- `kernel.audit_backlog_limit` — no disponible (auditd no instalado)

## Cambios reales aplicados (vs baseline)
- `kernel.kptr_restrict`: 1 → **2**
- `net.ipv4.conf.default.accept_source_route`: 1 → **0**
- `net.ipv4.conf.*.log_martians`: 0 → **1**
- `kernel.unprivileged_userns_clone`: 1 → **0**
- `vm.swappiness`: 60 → **10**

## Riesgos y Rollback

**`kernel.unprivileged_userns_clone=0`**: Puede romper Chrome sandbox, Flatpak, o apps que usen user namespaces sin root.
- Rollback: `sudo sysctl -w kernel.unprivileged_userns_clone=1`

**`kernel.kptr_restrict=2`**: Puede afectar herramientas de profiling/debugging.
- Rollback: `sudo sysctl -w kernel.kptr_restrict=1`

**Rollback completo:**
```bash
sudo rm /etc/sysctl.d/99-hardening.conf
sudo sysctl --system
```

## Config file
`/etc/sysctl.d/99-hardening.conf` — persiste entre reboots automáticamente.
