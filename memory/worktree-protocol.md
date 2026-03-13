# Git Worktree Protocol for Parallel Sub-agents

**Created:** 2026-03-13
**Status:** Active
**Script:** `scripts/worktree-manager.sh`

## Problema

Cuando `gh-issues` lanza múltiples sub-agentes en paralelo, todos hacen `git checkout -b` 
en el mismo directorio. Esto causa conflictos: checkout falla, archivos se mezclan, etc.

## Solución

Cada sub-agente trabaja en su propio **git worktree** — una copia ligera del repo 
con su propia rama, sin compartir working directory.

```
proyecto/                          ← repo principal (main)
proyecto/.worktrees/issue-42/      ← worktree agente 1 (fix/issue-42)
proyecto/.worktrees/issue-37/      ← worktree agente 2 (fix/issue-37)
proyecto/.worktrees/issue-15/      ← worktree agente 3 (fix/issue-15)
```

## Uso

### Antes de lanzar sub-agentes (orquestador):
```bash
# Crear worktree para cada issue
WT_PATH=$(bash scripts/worktree-manager.sh create /path/to/repo 42 main)
# → /path/to/repo/.worktrees/issue-42
```

### En el sub-agente (usar cwd del worktree):
```
sessions_spawn con cwd: $WT_PATH
```
El sub-agente ya está en su rama `fix/issue-42`, en su propio directorio.
No necesita hacer `git checkout -b` — ya está hecho.

### Después de que terminen (orquestador):
```bash
# Limpiar todo
bash scripts/worktree-manager.sh cleanup /path/to/repo
```

## Integración con gh-issues

Cuando se use gh-issues con múltiples issues en paralelo:
1. Orquestador crea worktrees antes de Phase 5
2. Cada sub-agente recibe `cwd` apuntando a su worktree
3. Sub-agente trabaja normalmente (el branch ya existe)
4. Tras completar, orquestador limpia worktrees

## Notas

- Los worktrees van en `.worktrees/` (auto-añadido a .gitignore)
- Cada worktree ocupa poco espacio (comparte .git con el repo principal)
- `git worktree prune` limpia referencias huérfanas
- Si un sub-agente falla, el worktree se puede limpiar individualmente
