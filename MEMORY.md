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
- **OpenClaw:** 2026.2.17, puerto 18789
- **Modelo:** Claude Opus 4.6 (principal), Haiku 4.5 (crons y tareas rutinarias). Gemini API key revocada.
- **Navegador:** Chrome 145 via chrome-shim
- **Memory search:** local embeddings (embeddinggemma-300m)
- **Email AI:** lolaopenclaw@gmail.com (gog CLI, keyring file-based)

## Cron jobs activos
- **4:00 Madrid (diario)** — Backup a Google Drive (`scripts/backup-memory.sh`)
- **7:00 Madrid (diario)** — Fail2ban daily report (IPs baneadas, intentos fallidos) (`healthcheck:fail2ban-alert-morning`)
- **9:00 Madrid (diario)** — Informe matutino unificado (apt upgrade, estado OpenClaw, backup, consumo)
- **23:55 Madrid (diario)** — Informe consumo diario, alerta si >$50 (`usage:report-daily`)
- **5:00 Madrid (lunes)** — Tareas de fondo semanales (lee Notion Fondo+Frecuencia=Semanal y one-shots)
- **6:00 Madrid (lunes)** — Auditoría de seguridad profunda (`healthcheck:security-audit-weekly`)
- **6:00 Madrid (lunes)** — Scan Lynis semanal (`healthcheck:lynis-scan-weekly`)
- **6:00 Madrid (lunes)** — Scan rkhunter malware (`healthcheck:rkhunter-scan-weekly`)
- **7:00 Madrid (lunes)** — Cleanup Notion Ideas (marca como Hecho las completadas) (`notion:ideas-cleanup-weekly`)
- **8:00 Madrid (lunes)** — Informe consumo semanal (resumen 7 días, tendencias) (`usage:report-weekly`)

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

## Archivos clave
- `RECOVERY.md` — instrucciones para restaurarme desde cero
- `scripts/backup-memory.sh` — backup workspace → Drive
- `scripts/usage-report.sh` — reporte de consumo
- `scripts/critical-change-checklist.md` — checklist para cambios de seguridad
- `memory/security-change-protocol.md` — protocolo A+B completo
- Drive folder: `openclaw_backups` (ID: `1G-OLpZKJ2zQXac0qaKxvaeglbRUuRxfD`)

## Protocolo de cambios críticos
**Decisión 2026-02-20:** Protocolo A+B para SSH, firewall, port forwarding, Fail2Ban
1. **Backup automático** antes del cambio (verificar Drive)
2. **Testing interactivo** con Manu (sesión SSH de respaldo)
3. **Validación manual** antes de confirmar
4. **Rollback inmediato** si falla
Ver: `memory/security-change-protocol.md` y `scripts/critical-change-checklist.md`

## Lecciones aprendidas
- D-Bus SecretService no funciona en VPS headless → usar keyring file-based para gog
- Gemini API keys pueden revocarse sin aviso → tener fallback local
- Sub-agentes con Opus son caros (~$56 en una sesión intensiva) → considerar modelos más baratos para rutinas
- Chrome en VPS necesita chrome-shim wrapper para funcionar con OpenClaw
- Usar IDs oficiales de Anthropic para modelos (claude-haiku-4-5, no claude-haiku-3.5). Verificar en docs.anthropic.com
- claude-3-5-haiku deprecated desde 19 feb 2026 → migrado a claude-haiku-4-5

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

---
*Última actualización: 2026-02-19*
