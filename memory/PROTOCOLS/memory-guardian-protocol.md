# Memory Guardian Protocol

## Qué es
Script automático que detecta y limpia bloat en `memory/`. Se ejecuta semanalmente (domingos 23:00) antes de la tier-rotation del lunes.

## Comandos
```bash
bash scripts/memory-guardian.sh --status     # Vista rápida
bash scripts/memory-guardian.sh --analyze    # Solo análisis (read-only)
bash scripts/memory-guardian.sh --dry-run --clean  # Simular limpieza
bash scripts/memory-guardian.sh --clean      # Limpiar temp/backups
bash scripts/memory-guardian.sh --compress   # Comprimir >30 días → COLD
bash scripts/memory-guardian.sh --full       # Todo junto
```

## Qué elimina
- `*.tmp`, `*.bak`, `*.temp` — archivos temporales
- `*.backup-*` — backups viejos
- Archivos `.md` < 100 bytes (vacíos/inútiles)
- Reports de guardian antiguos (mantiene últimos 4)

## Qué NUNCA toca
- `memory/CORE/` — perfil de Manu, preferencias
- `memory/PROTOCOLS/` — documentos de decisión
- `MEMORY.md`, `SOUL.md`, `IDENTITY.md`, `TOOLS.md`, `AGENTS.md`
- `memory/INDEX.md`

## Seguridad
- Usa `.trash/` en vez de `rm` (recuperable en `workspace/.trash/YYYYMMDD/`)
- `--dry-run` para simular antes de ejecutar
- Archivos protegidos hardcodeados, imposible borrar por accidente

## Compression
Archivos en HOT/WARM con >30 días de antigüedad → comprimidos a DAILY/COLD/

## Token Estimation
Estima tokens basándose en ~4 chars/token. Reporta por tier.

## Estado
Tracking en `memory/guardian-state.json` (última ejecución, acción, tamaño).

## Cron
Programado: domingos 23:00 (Europe/Madrid), cron name: `memory-guardian-weekly`

## Desactivar
- Cron: `openclaw cron disable memory-guardian-weekly`
- O simplemente no ejecutar el script

## Troubleshooting
- **Script falla:** Verificar que `memory/DAILY/` existe
- **No borra nada:** Probablemente todo está limpio. Usar `--analyze` para verificar
- **Recuperar archivo:** Buscar en `workspace/.trash/YYYYMMDD/`
