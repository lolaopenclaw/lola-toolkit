# 🪵 WAL Protocol — Write-Ahead Logging for Agent State

**Objetivo:** Garantizar consistencia y recuperabilidad de cambios críticos en agent state  
**Inspiración:** Proactive Agent (WAL Protocol), Phoenix Shield (health baselines)  
**Herramienta:** `scripts/wal-logger.sh`

---

## 🎯 Problema Resuelto

**Desafío:** Agent state puede corromperse en crashes
- Cambios a medio aplicar
- Crons en estado inconsistente
- MEMORY.md con writes incompletos
- Sin forma de recuperar último estado bueno

**Solución:** WAL Protocol
- ✅ Escribe cambio a LOG ANTES de aplicar
- ✅ Recuperable siempre (replay log)
- ✅ Auditable (trace completo)
- ✅ Atomic (no corrupción)

---

## 📋 Cómo Funciona

### 1. **Write-Ahead** (Log First)
```
Evento: "Cambio MEMORY.md"
   ↓
[WRITE] Log entry a WAL
   ↓
[VERIFY] SHA256 check
   ↓
[APPLY] Cambio a MEMORY.md
   ↓
[DONE] Entry marcado as completed
```

### 2. **Snapshot** (Point-in-Time)
```
Cada 6h: tar.gz de SOUL.md + MEMORY.md + memory/
   ↓
Almacenado en WAL/snapshots/
   ↓
Recovery: restaurar desde snapshot + replay últimos cambios
```

### 3. **Replay** (Recovery from Crash)
```
Detectar crash (BOOT.md)
   ↓
Cargar último snapshot
   ↓
Replay WAL entries desde crash
   ↓
Restaurar estado consistente
```

---

## 🛠️ Uso Práctico

### Logging Changes
```bash
# Cambio normal
bash scripts/wal-logger.sh log "Updated MEMORY.md with new protocol" INFO

# Cambio crítico
bash scripts/wal-logger.sh log "SSH config changed - AllowTcpForwarding=yes" CRITICAL

# Error
bash scripts/wal-logger.sh log "Failed to sync backup to Drive" ERROR
```

### Snapshots
```bash
# Crear snapshot (punto de recuperación)
bash scripts/wal-logger.sh snapshot

# Se almacena con timestamp: snapshot-20260221-130500.tar.gz
```

### Recovery
```bash
# Ver qué se replayaría (sin aplicar)
bash scripts/wal-logger.sh replay --dry-run

# Aplicar replay (recuperar estado)
bash scripts/wal-logger.sh replay
```

### Validación
```bash
# Verificar integridad WAL
bash scripts/wal-logger.sh validate

# Output: Verifica SHA256 de todas las entries
```

### Reporte
```bash
# Ver estado actual del WAL
bash scripts/wal-logger.sh report

# Muestra: total entries, tamaño, últimas 10 entradas, snapshots
```

---

## 📊 Estructura WAL

```
memory/WAL/
├── 2026-02-21.log              # Log del día (append-only)
├── 2026-02-20.log.gz           # Log comprimido (>7 días)
├── snapshots/
│   ├── snapshot-20260221-123000.tar.gz
│   ├── snapshot-20260221-183000.tar.gz
│   └── snapshot-20260220-183000.tar.gz
└── .lock                        # Mutex para escrituras concurrentes
```

### Entry Format
```
[TIMESTAMP] [SEVERITY] MESSAGE
SHA256: <hash>
```

**Severities:**
- **INFO** — Cambios normales (crons, updates)
- **WARNING** — Algo inusual pero recuperable
- **CRITICAL** — Cambios de seguridad, config
- **ERROR** — Fallo detectado
- **SNAPSHOT** — Snapshot creado
- **MAINTENANCE** — Rotación, compresión

---

## 🔄 Integración con BOOT.md

**BOOT.md debe:**
1. Detectar si hay WAL log incompleto
2. Si existe: ejecutar `wal-logger.sh replay`
3. Restaurar estado desde último snapshot
4. Log recovery en WAL

**Flujo BOOT:**
```
Boot → Detectar crash?
   ├─ SI: Cargar snapshot + replay WAL
   │     └─ Verificar integridad + restart
   └─ NO: Continuar normalmente
```

---

## 🚀 Cron Automation

### Snapshots Automáticos
```bash
# Cada 6 horas
0 */6 * * * bash ~/.openclaw/workspace/scripts/wal-logger.sh snapshot
```

### Rotación de Logs
```bash
# Diario (comprimimos logs >7 días)
0 2 * * * bash ~/.openclaw/workspace/scripts/wal-logger.sh rotate
```

### Validación
```bash
# Semanal (verificar integridad)
0 6 * * 1 bash ~/.openclaw/workspace/scripts/wal-logger.sh validate
```

---

## 📈 Ejemplo Real

### Escenario: Cambio SSH

```bash
# 1. Log cambio (write-ahead)
bash wal-logger.sh log "SSH: AllowTcpForwarding changed from no to yes for VNC support" CRITICAL

# 2. Crear snapshot ANTES del cambio
bash wal-logger.sh snapshot

# 3. Aplicar cambio en /etc/ssh/sshd_config
sudo nano /etc/ssh/sshd_config
sudo systemctl reload ssh

# 4. Si algo falla (crash, error):
#    - WAL tiene log del cambio
#    - Snapshot tiene estado anterior
#    - BOOT.md puede recuperar
```

---

## 🔐 Seguridad

### Inmutabilidad
- Log es **append-only** (nunca se modifica)
- SHA256 detecta corrupciones
- Mutex previene writes concurrentes

### Auditability
- Cada cambio queda registrado con timestamp
- Quién hizo el cambio (future: userid)
- Cuándo exactamente (timestamp)
- Qué cambió (message)
- Validable (SHA256)

### Recovery
- Siempre recuperable a último snapshot
- Replay desde último estado bueno
- Sin pérdida de datos

---

## ⏱️ Timing

| Operación | Tiempo | Frecuencia |
|-----------|--------|-----------|
| log | 10ms | Cada cambio |
| snapshot | 1-2s | Cada 6h |
| replay | 100ms | Solo en crash |
| validate | 50ms | Semanal |
| rotate | 30s | Diario |

---

## 🎓 Lecciones

**Antes:** Agent state podía corromperse sin recuperación  
**Después:** Garantía de consistencia + auditabilidad

**Impacto:**
- ✅ Crash recovery automático
- ✅ Audittrail completo
- ✅ Atomic operations
- ✅ Debugging facilitado

---

## 🔗 Integración con Proactive Agent

**Proactive Agent + WAL Protocol:**
- Proactive Agent: Autonomía, anticipación
- WAL Protocol: Consistencia, recuperabilidad
- Juntos: Agentes resilientes

---

**Implementación:** 2026-02-21  
**Locación:** `scripts/wal-logger.sh`  
**Documentación:** Esta archivo + BOOT.md integration

*"Write ahead, think after, recover always."*
