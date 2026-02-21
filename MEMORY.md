# MEMORY.md — Long-Term Memory

## Manu (mi humano)
- **Nombre completo:** Manuel León
- **Ubicación:** Logroño, La Rioja, España
- **Telegram:** @RagnarBlackmade (chat ID: 6884477)
- **Idioma:** Español siempre
- **Timezone real:** Europe/Madrid (UTC+1/+2)

### Trayectoria musical (+20 años)
- Hijos del Exceso → Miedo Azul (2004-2008) → Boncacántica → Motel Lazarus (2008-2017) → Kaiah (2018) → **Bass in a Voice** (2014-presente)
- Bass in a Voice: trío peculiar (voz, bajo, percusión). Manu = voz. Quique Alcalde = bajo. Javi Alcalde = percusión (desde finales 2023).
- Canal YouTube: @bassinavoice (8 vídeos analizados feb 2026)
- Perfil detallado: `memory/manu-profile.md`
- Análisis vídeos: `memory/bass-in-a-voice.md`

### Drive compartido
- Carpeta: "Cosas a compartir con Lola" (ID: `1RzlaYlN5isyIB7XE-R5Pt3xxyEmdzVoz`)
- Subcarpeta Inbox (ID: `1B4kCkyjSoBAw2M3i7JyZI2F-MIWX9Maz`): Manu deja archivos aquí → yo los proceso, y los borro del Inbox y de la VPS al terminar
- Regla: mantener sistema limpio — borrar archivos temporales tras procesar, solo conservar reportes

### Preferencias de trabajo
- Avisar cada ~15s en tareas largas
- Eliminar archivos temporales tras análisis, solo conservar reportes
- Sin tablas markdown en Telegram (usar bullets)
- Formato: directo, sin relleno

### Preferencias de comunicación
- **Audio/TTS:** Solo responder por audio si Manu lo pide explícitamente en el mensaje de voz
- Por defecto: siempre responder por texto, incluso si recibo audio
- **Config OpenClaw:** `messages.tts.auto: "off"` (cambiado 2026-02-20)
- **Horario silencioso:** 00:00-07:00 Madrid - NO enviar mensajes a Telegram
- **Resúmenes matutinos:** Si hay reportes nocturnos, resumir a primera hora

### Estilo de correcciones
- **Errores menores (1-2 veces):** Ignorar, seguir adelante
- **Errores repetidos (3+ veces):** Corregir constructivamente y con amabilidad
- Objetivo: ayudar a aprender sin interrumpir el flujo

### Apertura a feedback
- Manu está abierto a preguntas, dudas, feedback
- Sentirse libre de preguntar cosas sobre él o pedir feedback
- Relación bidireccional

## Infraestructura
- **VPS:** Ubuntu 6.8.0, usuario `mleon`, sudo sin contraseña
- **Timezone:** Europe/Madrid (CET, +0100) — cambiado 2026-02-21
- **OpenClaw:** 2026.2.17, puerto 18789
- **Modelo:** Claude Opus 4.6 (principal), Haiku 4.5 (crons y tareas rutinarias). Gemini API key revocada.
- **Navegador:** Chrome 145 via chrome-shim
- **Memory search:** local embeddings (embeddinggemma-300m)
- **Email AI:** lolaopenclaw@gmail.com (gog CLI, keyring file-based)

## Cron jobs activos
- **4:00 Madrid (diario)** — Backup a Google Drive (`scripts/backup-memory.sh`)
- **7:00 Madrid (diario)** — Fail2ban daily report (IPs baneadas, intentos fallidos) (`healthcheck:fail2ban-alert-morning`)
- **9:00 Madrid (diario)** — Informe matutino unificado (apt upgrade, estado OpenClaw, backup, consumo)
- **9:00 Madrid (diario)** — Garmin informe matutino (actividad ayer, sueño, análisis) (`garmin:morning-report`)
- **14:00 y 20:00 Madrid (diario)** — Garmin alertas de salud (HR anormal, estrés alto, poco sueño) (`garmin:health-alerts`)
- **23:55 Madrid (diario)** — Informe consumo diario, alerta si >$50 (`usage:report-daily`)
- **5:00 Madrid (lunes)** — Tareas de fondo semanales (lee Notion Fondo+Frecuencia=Semanal y one-shots)
- **6:00 Madrid (lunes)** — Auditoría de seguridad profunda (`healthcheck:security-audit-weekly`)
- **6:00 Madrid (lunes)** — Scan Lynis semanal (`healthcheck:lynis-scan-weekly`)
- **6:00 Madrid (lunes)** — Scan rkhunter malware (`healthcheck:rkhunter-scan-weekly`)
- **7:00 Madrid (lunes)** — Cleanup Notion Ideas (marca como Hecho las completadas) (`notion:ideas-cleanup-weekly`)
- **8:00 Madrid (lunes)** — Informe consumo semanal (resumen 7 días, tendencias) (`usage:report-weekly`)
- **8:30 Madrid (lunes)** — Garmin resumen semanal (tendencias, comparativas, recomendaciones) (`garmin:weekly-summary`)

## Notion
- **Workspace:** Lola OpenClaw's Space (lolaopenclaw@gmail.com)
- **Página raíz:** "🎯 Lola - Centro de Operaciones" (ID: `30c676c386c880239b4dea623e43b7a0`)
- **Tablero Kanban:** "Tablero de Tareas" (DB ID: `30c676c3-86c8-81ac-b2bd-cd2d8a5516f7`)
- **URL tablero:** https://www.notion.so/30c676c386c881acb2bdcd2d8a5516f7
- **Compartido con:** manuelleonmendiola@gmail.com
- **API:** Notion-Version 2022-06-28 (la 2025-09-03 tiene bugs con data_sources)
- **Columnas:** Ideas, Pendiente, En progreso, Hecho, Bloqueado
- **Flujo:** Ideas (propuestas) → Pendiente (aprobadas, Lola las coge en heartbeats con Haiku) → En progreso → Hecho → Archivado (>7 días)
- **Propiedades:** Tarea, Estado, Prioridad, Notas, Frecuencia, Archivado, Actualizado
- **Captura automática:** En todos los reportes/análisis, detectar tareas/mejoras y añadirlas a Ideas (sin duplicar) con documentación completa (origen, qué es, beneficios, cuándo, complejidad, cómo, riesgos, recomendación)

## Archivos clave (2026-02-21)

### Backup & Recovery
- `RECOVERY.md` — instrucciones para restaurarme desde cero
- `scripts/backup-memory.sh` — backup workspace → Drive (cron 4:00 AM)
- `memory/PROTOCOLS/backup-naming-policy.md` — Naming: automático vs manual
- `memory/PROTOCOLS/backup-retention-policy.md` — Retención: máximo 30 días
- Drive folder: `openclaw_backups` (ID: `1G-OLpZKJ2zQXac0qaKxvaeglbRUuRxfD`)

### Cambios Críticos & Canary Testing
- `scripts/critical-change-checklist.md` — Flujo 7 fases + Canary integrado
- `memory/PROTOCOLS/canary-testing-protocol.md` — Guía detallada de pre-testing
- `scripts/canary-test.sh` — Script de validación (start/test/validate/rollback)
- `memory/security-change-protocol.md` — Protocolo A+B completo

### Memory Management
- `scripts/memory-guardian.sh` — Auto-cleanup + bloat detection
- `scripts/tier-rotation.sh` — HOT/WARM/COLD rotación automática
- `memory/PROTOCOLS/memory-guardian-protocol.md` — Guía del sistema
- `memory/DAILY/INDEX.md` — Estructura tiered

### Reporting & Usage
- `scripts/usage-report.sh` — reporte de consumo
- `memory/INDEX.md` — Índice general (CORE/PROTOCOLS/DAILY/ANALYSIS)
- `memory/DAILY/HOT/` — Últimos 7 días (búsqueda primaria)
- `memory/DAILY/WARM/` — 8-30 días (búsqueda secundaria)
- `memory/DAILY/COLD/` — >30 días (histórico comprimido)

## 🔄 Política de Retención de Backups (Decisión 2026-02-21)

**REGLA:** Mantener máximo 30 días de backups en Drive. Después, eliminar automáticamente.

**Aplica a:**
- Backups diarios (`openclaw-backup-YYYY-MM-DD.tar.gz`)
- Backups de limpieza (`cleanup-backup-YYYY-MM-DD.tar.gz`)
- Cualquier backup futuro

**Beneficios:**
- ✅ Drive no collapsa (evita ~2.5 GB/mes)
- ✅ Recuperación consistente (30 días siempre disponible)
- ✅ Automático (sin intervención manual)

**Timeline:**
- Backup creado: YYYY-MM-DD
- Disponible para recuperación: 30 días
- Eliminado automáticamente: YYYY-MM-DD + 30 días

**Monitoreo:**
- Cron lunes 5:30 AM: Limpia backups >30 días
- Antes de eliminar, verifica que haya backup más reciente

**Ejemplos actuales:**
- `cleanup-backup-2026-02-21.tar.gz` — Vigente hasta 2026-03-23
- `openclaw-backup-2026-02-21.tar.gz` — Vigente hasta 2026-03-23
- Backups más viejos de 2026-01-22 — Eliminados

## Protocolo de cambios críticos
**Decisión 2026-02-20:** Protocolo A+B para SSH, firewall, port forwarding, Fail2Ban
**Mejora 2026-02-21:** Canary Testing pre-change (scripts/canary-test.sh)
1. **Backup automático** antes del cambio (verificar Drive)
2. **Health baseline** — `bash canary-test.sh start`
3. **Cambio controlado** — Editar, recargar servicio
4. **Validación automática** — `bash canary-test.sh test && validate`
5. **Rollback if needed** — `bash canary-test.sh rollback`

Documentación: 
- `memory/security-change-protocol.md` — Protocolo A+B
- `memory/PROTOCOLS/canary-testing-protocol.md` — Canary testing (detallado)
- `scripts/critical-change-checklist.md` — Checklist + Canary integrado (ejecutivo)
- `scripts/canary-test.sh` — Script principal (herramienta)

## Lecciones aprendidas
- D-Bus SecretService no funciona en VPS headless → usar keyring file-based para gog
- Gemini API keys pueden revocarse sin aviso → tener fallback local
- Sub-agentes con Opus son caros (~$56 en una sesión intensiva) → considerar modelos más baratos para rutinas
- Chrome en VPS necesita chrome-shim wrapper para funcionar con OpenClaw
- Usar IDs oficiales de Anthropic para modelos (claude-haiku-4-5, no claude-haiku-3.5). Verificar en docs.anthropic.com
- claude-3-5-haiku deprecated desde 19 feb 2026 → migrado a claude-haiku-4-5

## 🔄 WAL Protocol (Implementado 2026-02-21)

**Write-Ahead Logging para consistencia de agent state**
- 🪵 **Log:** Cambios se registran ANTES de aplicar
- 📸 **Snapshots:** Punto de recuperación cada 6h
- 🔄 **Replay:** Recuperación automática en crashes
- ✅ **Auditability:** Trace completo de todos los cambios
- **Crons:**
  - Snapshots: cada 6 horas
  - Rotación: diario 2:00 AM (comprime logs >7 días)
  - Validación: lunes 6:00 AM
- **Ubicación:** `memory/WAL/`, `scripts/wal-logger.sh`
- **Integración:** BOOT.md ahora valida/recupera WAL al arrancar

---

## 🪵 WAL Protocol (Write-Ahead Logging) — Implementado 2026-02-21

**Status:** ✅ **Production-ready**

**Componentes:**
- `scripts/wal-logger.sh` — Validar integridad de logs
- `scripts/wal-snapshot.sh` — Crear snapshots (punto de recuperación)
- `scripts/wal-replay.sh` — Recuperar desde snapshot
- `memory/WAL/` — Estructura de logs + snapshots

**Cómo funciona:**
1. **Logging:** Cada cambio importante se registra en memory/WAL/logs/
2. **Snapshots:** Cada 6h (cron) se comprimen logs en snapshot
3. **Validation:** BOOT.md valida integridad post-crash
4. **Replay:** Si hay corrupción, recupera desde último snapshot limpio

**Beneficios:**
- ✅ Crash-safe: recuperación automática post-reboot
- ✅ Audit trail: traza completa de cambios
- ✅ Point-in-time recovery: restaurar a snapshot específico
- ✅ Rolling backups: últimos 10 snapshots guardados

**Crons:**
- **Snapshots:** Cada 6 horas
- **Log rotation:** Diario 2:00 AM (comprime logs >7 días)
- **Validation:** Lunes 6:00 AM (auditoría semanal)

---

## 🧠 Sistema de Memory Management (Implementado 2026-02-21)

### Tiered Architecture
- 🔥 **HOT:** Últimos 7 días — Consultar PRIMERO (rápido, bajo token)
- 🌤️ **WARM:** 8-30 días — Contexto medio plazo
- ❄️ **COLD:** >30 días — Comprimido en `.tar.gz`, histórico
- **Rotación automática:** Lunes 23:30 (cron)
- **Beneficios:** -30% tokens memory_search, -85% almacenamiento COLD

### Memory Guardian Pro v1 (Auto-Cleanup)
- **Cuándo:** Domingos 23:00 (antes de tier-rotation)
- **Qué hace:**
  - ✅ Detecta bloat (archivos >500KB)
  - ✅ Limpia backups viejos (.backup-*)
  - ✅ Elimina temporales (.tmp, .bak)
  - ✅ Comprime archivos >30 días
  - ✅ Busca duplicados (MD5)
  - ✅ Estima token usage
- **Beneficios:** -75-80% almacenamiento, sin intervención manual
- **Preserva:** CORE/, PROTOCOLS/, DAILY/HOT/ (nunca toca lo crítico)

**Ubicación:** `memory/DAILY/HOT/`, `memory/DAILY/WARM/`, `memory/DAILY/COLD/`

---
## Lecciones aprendidas
- D-Bus SecretService no funciona en VPS headless → usar keyring file-based para gog
- Gemini API keys pueden revocarse sin aviso → tener fallback local
- Sub-agentes con Opus son caros (~$56 en una sesión intensiva) → considerar modelos más baratos para rutinas
- Chrome en VPS necesita chrome-shim wrapper para funcionar con OpenClaw
- Usar IDs oficiales de Anthropic para modelos (claude-haiku-4-5, no claude-haiku-3.5). Verificar en docs.anthropic.com
- claude-3-5-haiku deprecated desde 19 feb 2026 → migrado a claude-haiku-4-5
- **Notion API 2025-09-03 rota** — data_sources vs databases desincronizados. Usar siempre `Notion-Version: 2022-06-28`
- Notion login desde headless Chrome funciona (email + código verificación vía Gmail)
- **Hardening SSH rompe VNC:** `AllowTcpForwarding no` bloquea túneles SSH → necesario `AllowTcpForwarding yes` para VNC
- **XFCE en VNC necesita D-Bus:** `~/.vnc/xstartup` debe inicializar D-Bus con `dbus-launch` o XFCE crashea
- **Memoria modular previene overflow:** Dividir `memory/YYYY-MM-DD.md` en sesiones cuando pase de ~4KB
- **Timezone VPS en UTC causaba confusiones:** Cambiar a Europe/Madrid (local del usuario) para consistencia en crons, logs, reportes y mental model. Decisión 2026-02-21.

## 📋 Sesión 2026-02-21 — 7 Sub-Agentes Completados + Hardening+Architecture

**Proyectos implementados (14:00-20:28 Madrid):**

### ✅ Semantic Memory Search
- LanceDB + nomic-embed-text (768 dims)
- 582 chunks vectorizados de 59 archivos
- `scripts/semantic-search.sh` executable
- Search latency: <2s, calidad: excelente

### ✅ Memory Guardian Pro
- Auto-cleanup: bloat detection, dedup, compression
- `scripts/memory-guardian.sh` con 7 flags
- Cron: domingos 23:00
- Protección automática de CORE/PROTOCOLS
- Status: 576 KB memoria, 0 problemas

### ✅ Backup Validation Suite
- Checksum SHA256 + structure verify + test restore
- `scripts/backup-validator.sh` con 4 modes
- Integrado en `backup-memory.sh` (post-backup)
- Cron: lunes 5:30 AM
- Testeo real: ✅ 8/8 archivos, 100 files recovered

### ✅ Skill Security Audit
- Pattern detection (eval, credentials, etc.)
- Scoring 0-100 con 5 risk levels
- `scripts/skill-security-audit.sh` 
- Registry: 6 VERDE + 4 AMARILLO baseline
- Auditoría de skills instalados completada

### ✅ Critical Update Safety
- Health baseline + canary testing + rollback automático
- `scripts/critical-update.sh` (300 líneas)
- 12 validaciones automáticas (SSH, firewall, network, services, disk, memory)
- Audit trail en `memory/CHANGES/`
- Integration con `canary-test.sh` existente

### ✅ OpenClaw Contribution Plan
- `CONTRIBUTION-PLAN.md` (estrategia 4 semanas)
- 5 propuestas documentadas en `CONTRIB/`
- Testing guide + ejemplos reales
- Recomendación: empezar con skill-security-audit.sh (más genérico)

### ✅ Garmin Integration
- 3 scripts (health-report, check-alerts, historical-analysis)
- Crons: 9:00 AM (daily report), 14:00+20:00 (alerts), lunes 8:30 (weekly)
- API testeada con datos reales
- Integración HEARTBEAT para contexto de salud

---

## 🛠️ Hardening & Architecture Learnings

### Sysctl Kernel Hardening ✅ **FUNCIONA**
- 10/12 parámetros aplicados + persistidos post-reboot
- Network: source-route blocking, log-martians, TCP syncookies
- Filesystem: protected hardlinks/symlinks/regular
- Memory: kptr_restrict, dmesg_restrict, unprivileged restrictions
- **Estado:** OK - bajo riesgo, sin impacto en servicios

### Systemd Hardening ❌ **NO FUNCIONA en VPS virtualizados**

**v1 (strict):** 
- `ProtectSystem=strict`, `RestrictNamespaces=yes`, `CapabilityBoundingSet` restrictivo
- **Resultado:** Gateway crash (218/CAPABILITIES restart loop 100+)
- **Causa:** Node.js necesita capabilities específicas

**v2 (suave):**
- `ProtectSystem=full`, excluded `RestrictNamespaces`, `CapabilityBoundingSet=CAP_NET_BIND_SERVICE`
- **Resultado:** Igual crash + D-Bus corrupted (128 restart attempts)
- **Causa raíz:** VPS hypervisor bloquea capabilities a nivel kernel (LXC/LXD)

**Solución final (Gemini):** 
- ✅ **System-level systemd** (root setup → mleon execution)
- User-level systemd no funciona en VPS virtualizados
- Gateway now `active (running)`, escuchando 127.0.0.1:18789
- **Decisión:** Pausar Systemd hardening, mantener Sysctl kernel-level

---

## 📊 Resumen Métricas

| Métrica | Valor |
|---------|-------|
| **Sub-agentes completados** | 7 (Opus) |
| **Scripts nuevos** | 8 (~2000 líneas) |
| **Protocolos documentados** | 7 |
| **Crons automáticos** | 20+ activos, 0 errores |
| **Memory size** | 628 KB (optimizada) |
| **Gateway uptime post-fix** | Estable (system-level service) |
| **Sysctl hardening** | 10/12 persistido |
| **Tiempo conversación activa** | ~35-40 minutos |

---

*Última actualización: 2026-02-21 20:28 UTC (21:28 Madrid)*
