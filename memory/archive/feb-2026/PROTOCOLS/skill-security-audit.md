# 🔒 Protocolo: Auditoría de Seguridad de Skills

**Creado:** 2026-02-21
**Política:** Revisar ANTES de instalar cualquier skill nuevo

## Uso

```bash
# Auditar un skill específico
bash scripts/skill-security-audit.sh <SKILL_NAME|PATH> [OPTIONS]

# Auditar todos los instalados
bash scripts/skill-security-audit.sh --all --report

# Solo ver score
bash scripts/skill-security-audit.sh <SKILL> --score

# Generar reporte markdown
bash scripts/skill-security-audit.sh <SKILL> --report
```

## Escala de Riesgo (1-100)

| Score | Nivel | Acción |
|-------|-------|--------|
| 0-24 | 🟢 VERDE | Instalar con confianza |
| 25-49 | 🟢 BAJO | Probablemente OK, revisión rápida |
| 50-74 | 🟡 AMARILLO | Revisar antes de instalar |
| 75-94 | 🟡 MEDIO | Auditoría profunda obligatoria |
| 95-100 | 🔴 CRÍTICO | NO instalar sin review manual |

## Qué Analiza

1. **Code Analysis** — eval(), exec(), fetch, filesystem, prompt injection, obfuscation
2. **Credential Detection** — Hardcoded secrets, .env files, config files
3. **Dependency Audit** — npm audit, unpinned versions, dep count
4. **Permission Analysis** — Executables, sensitive paths, network listeners
5. **Metadata** — SKILL.md, author, version

## Qué Hacer por Nivel

### 🔴 CRÍTICO (95+)
- NO instalar
- Documentar findings
- Reportar al autor si es ClawHub público
- Considerar alternativas

### 🟡 AMARILLO/MEDIO (50-94)
- Revisar cada finding manualmente
- Crear issue/fix para problemas específicos
- Solo instalar si los findings son falsos positivos confirmados
- Re-auditar después de fixes

### 🟢 VERDE/BAJO (0-49)
- Instalar con confianza
- Re-auditar anualmente o tras updates mayores

## Reportes

Guardados en: `memory/audits/<skill>-audit-YYYY-MM-DD.md`
Registry: `memory/skill-audit-registry.md`

## Reportar Vulnerabilidades

Si encuentras algo crítico en un skill público:
1. Documenta el finding
2. Contacta al autor (GitHub issue si es OSS)
3. No publicar detalles hasta que se fixee
4. Registra en el audit registry
