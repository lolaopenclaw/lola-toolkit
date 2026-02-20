# Estructura de Memoria Diaria - Nuevo Sistema

## Problema
Sesiones largas generan archivos YYYY-MM-DD.md enormes (25K+ tokens) que causan context overflow.

## Solución
Dividir memoria diaria en archivos por sesión/tema:

```
memory/
├── 2026-02-20.md              # Índice ligero del día
└── 2026-02-20/
    ├── 01-navegador-chrome.md
    ├── 02-seguridad-audit.md
    ├── 03-lynis-hardening.md
    ├── 04-recovery-system.md
    ├── 05-usage-reports.md
    ├── 06-tts-config.md
    └── 07-garmin-integration.md
```

## Formato del índice (YYYY-MM-DD.md)

```markdown
# 2026-02-20 - Viernes

## Resumen ejecutivo
- Seguridad: Hardening completo (9.6/10)
- Recovery: Sistema automatizado (20-30 min)
- Trazabilidad: Consumo + Ideas + Crons
- Config: TTS off, correcciones constructivas
- Nuevo: Garmin integration iniciada

## Sesiones detalladas
1. [Navegador Chrome y rollback OpenClaw](2026-02-20/01-navegador-chrome.md)
2. [Auditoría de seguridad VPS](2026-02-20/02-seguridad-audit.md)
3. [Lynis y hardening](2026-02-20/03-lynis-hardening.md)
4. [Sistema de recovery](2026-02-20/04-recovery-system.md)
5. [Informes de consumo](2026-02-20/05-usage-reports.md)
6. [Config TTS y correcciones](2026-02-20/06-tts-config.md)
7. [Garmin integration](2026-02-20/07-garmin-integration.md)

## Decisiones clave
- OpenClaw 2026.2.17 (estable)
- Horario silencioso: 00:00-07:00 Madrid
- 10 crons activos
- 13 Ideas en Notion
```

## Cuándo crear nueva sesión
- Cambio de tema significativo (seguridad → recovery → config)
- >2 horas de conversación en un tema
- Cuando el archivo pase de ~3-4KB (~1500 tokens)

## Beneficios
- Memory search más preciso (encuentra secciones específicas)
- Carga de contexto más ligera
- Reorganización más fácil
- Menos riesgo de context overflow

## Migración del archivo de hoy
Script para reorganizar 2026-02-20.md en estructura nueva.
