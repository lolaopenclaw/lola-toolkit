# Arneses Avanzados para OpenClaw: Investigación Fase 2

**Fecha:** 2026-03-24  
**Investigadora:** Lola (subagent)  
**Contexto:** Expansión del validador pre-restart básico hacia validación IA-sobre-IA robusta  
**Restricciones:** Solo investigación + diseño (no implementación todavía)

---

## Resumen Ejecutivo

Este documento investiga patrones avanzados de **harness engineering** para hacer OpenClaw más robusto mediante validación IA-sobre-IA. La investigación cubre:

1. **Validador de output de subagentes** — Revisor IA que valida output antes de aplicar
2. **Testing automático de crons** — Dry-run y validación antes de deploy
3. **Pre-flight checks de APIs externas** — Health checks periódicos de APIs críticas
4. **Otros arneses útiles** — Config drift, dependency pinning, sandbox escape, rate limits, log anomalies

**Hallazgo clave:** El validador pre-restart actual (`pre-restart-validator.sh`) es **estructural** (JSON, permisos, env vars). Los arneses propuestos añaden capas de validación **semántica** (comportamiento, output, seguridad) usando IA para supervisar IA.

**Recomendación inmediata:** Empezar con **Pre-flight checks de APIs externas** (quick win, alto impacto, bajo esfuerzo) + **Testing automático de crons** (previene fallos silenciosos).

---

## 1. Validador de Output de Subagentes

### Problema

**Escenario de fallo:**
- Subagente completa tarea de "actualizar cron jobs"
- Genera sintaxis correcta pero lógica errónea (ej. ejecuta cada 5 min en vez de cada 5 horas)
- O genera comando peligroso (`rm -rf ~/.openclaw/memory/*` en vez de `rm -rf ~/.openclaw/tmp/*`)
- Main agent aplica el output sin verificar → **sistema roto**

**Casos reales que prevenir:**
1. **Tokens/secrets en código:** Subagente escribe API key hardcodeada en script
2. **Comandos destructivos:** `dd`, `mkfs`, `rm -rf` sin safeguards
3. **Config errónea:** Cambio que rompe dependencias de otros componentes
4. **Race conditions:** Código que funciona en prueba pero falla en producción
5. **Logic bugs:** Algoritmo correcto sintácticamente pero equivocado semánticamente

### Solución Propuesta: Agente Revisor

**Arquitectura:** Pipeline de validación en 3 fases

```
Subagent Output
    ↓
[Fase 1: Structural Validation] ← Code-based graders
    ↓
[Fase 2: Semantic Review] ← AI reviewer agent
    ↓
[Fase 3: Human Threshold] ← Auto-apply vs flag for review
    ↓
Applied to System (or Flagged)
```

#### Fase 1: Structural Validation (Determinística)

**Qué detecta:**
- **Secrets/tokens:** Regex patterns para API keys, tokens, passwords
- **Dangerous commands:** Whitelist de comandos permitidos, blacklist de destructivos
- **Syntax errors:** Lint/parse del output (bash -n, python -m py_compile, jq, etc.)
- **File paths:** Validar que paths están dentro de workspace/allowed dirs
- **Dependencies:** Check que imports/requires están disponibles

**Herramientas:**
```bash
# Detector de secrets
git secrets --scan output.sh
trufflehog --json output.sh

# Dangerous command detector
grep -E "(rm -rf|dd |mkfs|format |>\/dev)" output.sh

# Syntax validation
bash -n output.sh  # Bash syntax
python -m py_compile output.py  # Python syntax
jq empty output.json  # JSON syntax
yamllint output.yml  # YAML syntax
```

**Exit criteria:** Si falla cualquier check → **rechazar automáticamente** (no pasar a Fase 2)

#### Fase 2: Semantic Review (IA Reviewer)

**Prompt template para AI reviewer:**

```markdown
You are a code/config reviewer for autonomous agent output.

**Task:** Review the following output from a subagent and evaluate:
1. **Correctness:** Does it accomplish the stated goal?
2. **Safety:** Are there any dangerous operations or side effects?
3. **Quality:** Does it follow best practices and conventions?
4. **Completeness:** Are there edge cases or error handling missing?

**Original task:** {original_task_description}

**Subagent output:**
{subagent_output}

**Context files (if relevant):**
{relevant_files_from_workspace}

**Scoring (1-10 scale):**
- Correctness: _/10
- Safety: _/10
- Quality: _/10
- Completeness: _/10

**Issues found (if any):**
- [List specific concerns]

**Recommendation:** [APPROVE / APPROVE_WITH_NOTES / REJECT / FLAG_FOR_HUMAN]

**Rationale:** [Explain your decision]
```

**Model choice:** 
- **Sonnet 4.5** para balance velocidad/calidad
- **Opus 4.6** si subagent output es crítico (config changes, cron jobs, security)

**Caching strategy:** Prompt template cached, solo el output cambia → bajo costo

#### Fase 3: Human Threshold

**Decision tree:**

| Reviewer Score | Safety | Action |
|----------------|--------|--------|
| ≥ 8.5/10 | ≥ 9/10 | **Auto-apply** + log to memory |
| 7-8.4/10 | ≥ 8/10 | **Auto-apply** + notify Manu (no blocking) |
| 6-6.9/10 | ≥ 7/10 | **Flag for review** (Telegram notification) |
| < 6/10 | any | **Reject** + notify |
| any | < 7/10 | **Flag for review** (safety concern) |

**Notification format (Telegram):**
```
⚠️ Subagent output requires review

Task: "Update cron jobs for healthcheck"
Reviewer score: 6.8/10 (Safety: 8/10)

Issues:
- Missing error handling for API timeout
- Cron schedule might be too frequent (every 5 min)

View output: /tmp/subagent-{id}-output.txt
Approve: /approve-subagent {id}
Reject: /reject-subagent {id}
```

### Patrones Detectables Automáticamente

**1. Tokens/secrets en código:**
```python
# BAD - Reviewer detecta
api_key = "sk-proj-abc123..."

# GOOD
api_key = os.getenv("OPENAI_API_KEY")
```

**2. Comandos destructivos sin confirmación:**
```bash
# BAD - Reviewer detecta
rm -rf ~/.openclaw/memory/*

# GOOD
read -p "Delete all memory files? (yes/no): " confirm
[[ "$confirm" == "yes" ]] && rm -rf ~/.openclaw/memory/*
```

**3. Hardcoded paths:**
```bash
# BAD - Reviewer detecta
cp file.txt /home/mleon/.openclaw/workspace/

# GOOD
cp file.txt "${OPENCLAW_WORKSPACE}/"
```

**4. Missing error handling:**
```python
# BAD - Reviewer detecta
response = requests.get(url)
data = response.json()

# GOOD
response = requests.get(url, timeout=10)
response.raise_for_status()
data = response.json()
```

**5. Logic errors (requiere contexto):**
```python
# Task: "Send notification if Garmin stress > 80"
# BAD - Reviewer detecta (lógica invertida)
if stress_level < 80:
    send_notification()

# GOOD
if stress_level > 80:
    send_notification()
```

### Integración sin Ralentizar Workflows

**Challenge:** Validación añade latencia → frustración si es lenta

**Soluciones:**

**1. Async validation (no bloqueante):**
```python
# Main agent spawns subagent
subagent_id = spawn_subagent(task="update cron jobs")

# Subagent completes
subagent_output = get_result(subagent_id)

# Validation en paralelo (no bloquea main agent)
validation_future = validate_async(subagent_output)

# Main agent puede hacer otras cosas mientras valida
# ...

# Cuando necesites el resultado:
validation_result = await validation_future
if validation_result.approved:
    apply(subagent_output)
```

**2. Fast-path para cambios triviales:**
```python
# Skip validation si output es simple y safe
if is_trivial(subagent_output):  # ej. solo comentarios, docs
    apply(subagent_output)  # Fast path
else:
    validate_and_apply(subagent_output)  # Full pipeline
```

**3. Cached validation patterns:**
```python
# Si vemos el mismo patrón de output, reusar decisión
pattern_hash = hash(extract_pattern(subagent_output))
if pattern_hash in validation_cache:
    apply_cached_decision(validation_cache[pattern_hash])
else:
    result = validate(subagent_output)
    validation_cache[pattern_hash] = result
```

**Latencia esperada:**
- Fase 1 (structural): **< 500ms** (determinístico)
- Fase 2 (AI review): **2-5s** (depende del tamaño del output)
- Fase 3 (threshold): **< 100ms** (simple comparison)

**Total: ~3-6s** para validación completa → aceptable para subagents (que ya tardan minutos)

### ¿Puede un Revisor ser Más Confiable que el Ejecutor?

**Sí, bajo ciertas condiciones:**

**1. Especialización:**
- Ejecutor (subagent): Optimizado para **generar** soluciones
- Revisor: Optimizado para **evaluar** soluciones
- Diferentes prompts, diferentes strengths

**2. Segundo par de ojos:**
- Blind spots del ejecutor ≠ blind spots del revisor
- Errores que el ejecutor no ve, el revisor sí

**3. Contexto adicional:**
- Revisor tiene acceso a:
  - Output del ejecutor
  - Task original
  - Files relevantes del workspace
  - Historical patterns de errores
- Más información = mejor evaluación

**4. Sin presión de generar:**
- Ejecutor: "Debo completar esta tarea" → presión puede llevar a shortcuts
- Revisor: "Solo debo evaluar si esto está bien" → más objetivo

**Pero NO es infalible:**
- Revisor también puede equivocarse (false positives/negatives)
- **Solución:** Calibración periódica con feedback humano

**Calibration loop:**
```
1. Revisor evalúa output → decision
2. Humano revisa (sample) → confirma o corrige
3. Log discrepancias → memory/reviewer-calibration.jsonl
4. Cada semana: Review patterns de error del revisor
5. Ajustar prompt/threshold si necesario
```

### Ejemplos de Otros Proyectos

**1. Constitutional AI (Anthropic):**
- IA genera respuesta → **Otro IA critica** basándose en principios → Finetune con respuestas revisadas
- Proceso: Self-critique + revision
- Resultado: Modelo más seguro sin massive human labeling

**2. LangChain PreCompletionChecklistMiddleware:**
- Antes de considerar task "done", agente pasa por checklist
- ¿Tests escritos? ¿Tests passed? ¿Docs actualizadas?
- Si falla checklist → agente corrige antes de completion

**3. OpenAI Codex with Linters:**
- Codex genera código → Passa por linters determinísticos → Si falla, Codex ve el error y regenera
- Loop hasta que pasa todos los linters

**4. AutoGPT Failsafes:**
- Múltiples safeguards:
  - Command whitelist (solo comandos aprobados)
  - Resource limits (CPU, memory, time)
  - Approval required para destructive operations
- Agente puede "querer" hacer algo peligroso → harness lo bloquea

**Patrón común:** **AI + Rules hybrid**
- Rules (determinístico) para safety critical
- AI (flexible) para quality/completeness
- Combinación = robusto

---

## 2. Testing Automático de Crons Antes de Deploy

### Problema

**Escenario de fallo:**
- Editas cron job para "healthcheck diario"
- Sintaxis del schedule es correcta: `0 9 * * *`
- Pero el script referenciado tiene typo: `helthcheck.sh` (missing 'a')
- O el script asume env var `TELEGRAM_CHAT_ID` que no existe en cron context
- Cron job se instala → **falla silenciosamente** → te enteras días después

**Casos reales que prevenir:**
1. **Syntax errors en cron schedule:** `0 99 * * *` (hora inválida)
2. **Script no encontrado:** Path incorrecto
3. **Permisos insuficientes:** Script no ejecutable
4. **Env vars missing:** Script asume vars que cron no tiene
5. **Dependencias faltantes:** Script usa tool no instalado
6. **Infinite loops:** Script que nunca termina
7. **Resource exhaustion:** Script que consume toda la RAM/CPU

### Solución Propuesta: Dry-Run Framework

**Arquitectura:** Pre-deploy validation pipeline

```
Cron Job Change (jobs.json edit)
    ↓
[1. Schedule Syntax Validation]
    ↓
[2. Script Existence & Permissions Check]
    ↓
[3. Dependency Resolution]
    ↓
[4. Dry-Run Execution (sandbox)]
    ↓
[5. Historical Pattern Comparison]
    ↓
Deploy (or Alert)
```

#### 1. Schedule Syntax Validation

**Tool:** `cron-validator` npm package o custom regex

```bash
#!/bin/bash
# validate-cron-schedule.sh

schedule="$1"

# Method 1: Use cron-validator (npm)
if ! npx --yes cron-validator "$schedule" 2>/dev/null; then
    echo "ERROR: Invalid cron schedule: $schedule"
    exit 1
fi

# Method 2: Custom regex (backup)
if ! echo "$schedule" | grep -qE '^(\*|[0-5]?[0-9])(\/[0-9]+)? (\*|[01]?[0-9]|2[0-3])(\/[0-9]+)? (\*|[1-2]?[0-9]|3[01])(\/[0-9]+)? (\*|[1-9]|1[012])(\/[0-9]+)? (\*|[0-6])(\/[0-9]+)?$'; then
    echo "WARNING: Schedule pattern looks suspicious: $schedule"
fi

echo "✅ Schedule syntax valid: $schedule"
```

**Test cases:**
```bash
# Valid
0 9 * * *        # Every day at 9am
*/30 * * * *     # Every 30 minutes
0 0 * * 0        # Every Sunday at midnight

# Invalid
0 99 * * *       # Hour 99 doesn't exist
60 * * * *       # Minute 60 doesn't exist
* * 32 * *       # Day 32 doesn't exist
```

#### 2. Script Existence & Permissions

```bash
#!/bin/bash
# validate-cron-script.sh

script_path="$1"

# Check existence
if [ ! -f "$script_path" ]; then
    echo "ERROR: Script not found: $script_path"
    exit 1
fi

# Check executable permission
if [ ! -x "$script_path" ]; then
    echo "WARNING: Script not executable: $script_path"
    echo "Fix: chmod +x $script_path"
    exit 1
fi

# Check shebang
if ! head -n1 "$script_path" | grep -q '^#!'; then
    echo "WARNING: Missing shebang in $script_path"
fi

# Check for common issues
if grep -q 'source ~/.bashrc' "$script_path"; then
    echo "WARNING: Script sources ~/.bashrc (may not work in cron context)"
fi

echo "✅ Script validation passed: $script_path"
```

#### 3. Dependency Resolution

```bash
#!/bin/bash
# check-cron-dependencies.sh

script_path="$1"

echo "🔍 Checking dependencies for: $script_path"

# Extract commands used in script
commands=$(grep -oP '(?<=\s|^)[a-z_-]+(?=\s)' "$script_path" | sort -u)

missing=()
for cmd in $commands; do
    if ! command -v "$cmd" &>/dev/null; then
        missing+=("$cmd")
    fi
done

if [ ${#missing[@]} -gt 0 ]; then
    echo "ERROR: Missing commands: ${missing[*]}"
    echo "Install with: apt install / npm install / pip install"
    exit 1
fi

# Check env vars referenced
env_vars=$(grep -oP '\$\{?[A-Z_]+\}?' "$script_path" | sed 's/[${}]//g' | sort -u)

missing_env=()
for var in $env_vars; do
    if [ -z "${!var}" ]; then
        missing_env+=("$var")
    fi
done

if [ ${#missing_env[@]} -gt 0 ]; then
    echo "WARNING: Env vars not set: ${missing_env[*]}"
    echo "These will need to be in crontab or ~/.openclaw/.env"
fi

echo "✅ Dependencies check passed"
```

#### 4. Dry-Run Execution (Sandbox)

**Challenge:** ¿Cómo ejecutar sin side effects?

**Estrategias:**

**A) Mock mode (añadir flag al script):**
```bash
#!/bin/bash
# heartbeat.sh

DRY_RUN=${DRY_RUN:-false}

if [ "$DRY_RUN" = "true" ]; then
    echo "[DRY-RUN] Would send Telegram message: Morning heartbeat"
    echo "[DRY-RUN] Would update memory/heartbeat-log.md"
else
    # Real execution
    message send --target telegram-me --message "Morning heartbeat"
    echo "$(date): Heartbeat sent" >> memory/heartbeat-log.md
fi
```

**B) Network isolation (docker/sandbox):**
```bash
# Run in isolated container
docker run --rm \
    --network none \
    --read-only \
    --tmpfs /tmp \
    -v "$script_path:/script.sh:ro" \
    ubuntu:latest \
    bash /script.sh
```

**C) Simular agentTurn payload:**
```bash
# Para cron jobs que usan `openclaw turn`
# En vez de ejecutar realmente, solo validar el payload

payload=$(jq -r '.jobs[] | select(.name=="heartbeat") | .agentTurn.payload' cron/jobs.json)

# Validate payload JSON
echo "$payload" | jq empty || { echo "ERROR: Invalid JSON payload"; exit 1; }

# Check references
message=$(echo "$payload" | jq -r '.message // empty')
if [ -z "$message" ]; then
    echo "WARNING: Empty message in payload"
fi

echo "✅ AgentTurn payload valid"
```

**D) Timeout enforcement:**
```bash
# Never let dry-run hang forever
timeout 30s bash "$script_path" || {
    code=$?
    if [ $code -eq 124 ]; then
        echo "ERROR: Script timeout (>30s) - might hang in production"
    else
        echo "ERROR: Script exited with code $code"
    fi
    exit 1
}
```

#### 5. Historical Pattern Comparison

**Idea:** Comparar nuevo cron job con versiones previas que funcionaron

```bash
#!/bin/bash
# compare-with-history.sh

job_name="$1"
new_schedule="$2"
new_command="$3"

# Retrieve previous successful config from git
prev_schedule=$(git log -1 --format=%H --grep="cron.*$job_name" -- cron/jobs.json | \
    xargs git show | jq -r ".jobs[] | select(.name==\"$job_name\") | .schedule")

if [ -n "$prev_schedule" ] && [ "$prev_schedule" != "$new_schedule" ]; then
    echo "⚠️  Schedule changed:"
    echo "   Old: $prev_schedule"
    echo "   New: $new_schedule"
    echo "   Verify this is intentional"
fi

# Similar comparison for command/payload
```

### Integration: Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit (or husky)

# Only check if cron/jobs.json changed
if git diff --cached --name-only | grep -q 'cron/jobs.json'; then
    echo "🔍 Validating cron job changes..."
    
    # Run validation suite
    bash scripts/validate-all-crons.sh || {
        echo ""
        echo "❌ Cron validation failed. Fix errors before committing."
        echo "   Or use --no-verify to skip (not recommended)"
        exit 1
    }
    
    echo "✅ Cron validation passed"
fi
```

### Alertar vs Bloquear Deploy

**Decision matrix:**

| Severity | Action | Example |
|----------|--------|---------|
| **Critical** | **Block** | Syntax error, missing script, no permissions |
| **High** | **Block** (with override) | Missing dependencies, env vars not set |
| **Medium** | **Warn** (log to memory) | Schedule changed significantly |
| **Low** | **Info** (notify Telegram) | New cron job added |

**Override mechanism:**
```bash
# If you REALLY need to deploy despite warnings
openclaw cron deploy --force --job heartbeat

# Logs override to memory
echo "$(date): FORCED deployment of cron 'heartbeat' - warnings ignored" >> \
    memory/cron-force-deploys.log
```

### ¿Simular Env Vars en Sandbox?

**Challenge:** Cron jobs corren en diferente contexto que shell interactivo

**Solución:** Reproducir cron environment

```bash
#!/bin/bash
# simulate-cron-env.sh

# Save current env
original_env=$(env)

# Clear almost everything (como cron)
env -i \
    HOME="$HOME" \
    USER="$USER" \
    PATH="/usr/bin:/bin" \
    SHELL="/bin/bash" \
    $(cat ~/.openclaw/.env | grep -v '^#' | xargs) \
    bash "$script_path"

# Restore original env
# (happens automatically when script exits)
```

**Test:** Si script funciona en cron-like env → probablemente funcionará en cron real

---

## 3. Pre-flight Checks de APIs Externas

### Problema

**Escenario de fallo:**
- Workflow de "morning briefing" depende de:
  - Garmin API (health stats)
  - Weather API (forecast)
  - Google Drive API (backup status)
- Garmin API cambia formato de response → tu parser rompe → briefing falla
- Te enteras cuando Manu pregunta "¿Por qué no recibí briefing hoy?"

**Casos reales que prevenir:**
1. **API downtime:** Servicio caído → todos los workflows que dependen de él fallan
2. **Schema changes:** API cambia formato de response → parsers rompen
3. **Auth expiration:** OAuth token expiró → 401 Unauthorized
4. **Rate limit exhaustion:** Cuota agotada → requests bloqueados
5. **Latency spikes:** API responde lento → timeouts → failures

### APIs Usadas en OpenClaw

**Identificadas en la investigación:**

| API | Uso | Criticidad | Auth Type |
|-----|-----|------------|-----------|
| **Anthropic (Claude)** | Core agent runtime | **CRITICAL** | API key |
| **Google (Gemini, Drive, Gmail, Calendar)** | Secondary LLM + workspace tools | **HIGH** | OAuth / API key |
| **Telegram** | Primary communication | **CRITICAL** | Bot token |
| **Discord** | Secondary communication | MEDIUM | Bot token |
| **GitHub** | Code operations | MEDIUM | OAuth / PAT |
| **Garmin Connect** | Health monitoring | MEDIUM | OAuth |
| **Weather (wttr.in / Open-Meteo)** | Forecasts | LOW | None |
| **Brave Search** | Web search | MEDIUM | API key |
| **OpenAI (Whisper, TTS)** | Audio processing | MEDIUM | API key |

### Solución Propuesta: Health Check Cron

**Arquitectura:** Scheduled API monitoring

```
Daily Cron (09:00 Madrid time)
    ↓
[For each critical API]
    ↓
[1. Connectivity Check (ping)]
    ↓
[2. Auth Check (test call)]
    ↓
[3. Schema Check (validate response)]
    ↓
[4. Latency Check (timing)]
    ↓
[Log results + Alert if failed]
```

#### Health Check Script Template

```bash
#!/bin/bash
# scripts/api-health-check.sh

# Config
APIS=(
    "anthropic:https://api.anthropic.com/v1/messages"
    "google:https://generativelanguage.googleapis.com/v1beta/models"
    "telegram:https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe"
    "github:https://api.github.com/user"
    "garmin:https://connectapi.garmin.com/wellness-api/rest/user/id"
)

RESULTS_FILE="$HOME/.openclaw/workspace/memory/api-health-$(date +%Y-%m-%d).json"
ALERT_THRESHOLD=2  # Alert if >= 2 APIs fail

echo "[" > "$RESULTS_FILE"
failed_count=0

for api_def in "${APIS[@]}"; do
    api_name="${api_def%%:*}"
    api_url="${api_def#*:}"
    
    echo "🔍 Checking $api_name..."
    
    start_time=$(date +%s%3N)
    
    # Attempt request (with appropriate headers)
    case "$api_name" in
        anthropic)
            response=$(curl -s -w "\n%{http_code}" --max-time 10 \
                -H "x-api-key: ${ANTHROPIC_API_KEY}" \
                -H "anthropic-version: 2023-06-01" \
                -H "content-type: application/json" \
                -d '{"model":"claude-sonnet-4-5","messages":[{"role":"user","content":"hi"}],"max_tokens":10}' \
                "$api_url")
            ;;
        google)
            response=$(curl -s -w "\n%{http_code}" --max-time 10 \
                -H "x-goog-api-key: ${GOOGLE_API_KEY}" \
                "$api_url")
            ;;
        telegram)
            response=$(curl -s -w "\n%{http_code}" --max-time 10 \
                "$api_url")
            ;;
        github)
            response=$(curl -s -w "\n%{http_code}" --max-time 10 \
                -H "Authorization: Bearer ${GITHUB_TOKEN}" \
                "$api_url")
            ;;
        garmin)
            # OAuth flow más complejo - skip por ahora o usar saved token
            response="200\n{\"status\":\"skipped\"}"
            ;;
    esac
    
    end_time=$(date +%s%3N)
    latency=$((end_time - start_time))
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    # Evaluate
    status="ok"
    issue=""
    
    if [ "$http_code" -ge 500 ]; then
        status="down"
        issue="Server error (${http_code})"
        failed_count=$((failed_count + 1))
    elif [ "$http_code" = "401" ] || [ "$http_code" = "403" ]; then
        status="auth_failed"
        issue="Authentication failed (${http_code})"
        failed_count=$((failed_count + 1))
    elif [ "$http_code" = "429" ]; then
        status="rate_limited"
        issue="Rate limit exceeded"
        failed_count=$((failed_count + 1))
    elif [ "$http_code" != "200" ]; then
        status="error"
        issue="Unexpected HTTP ${http_code}"
    fi
    
    if [ "$latency" -gt 5000 ]; then
        [ "$status" = "ok" ] && status="slow"
        issue="${issue:+$issue; }Latency ${latency}ms (>5s threshold)"
    fi
    
    # Log result
    cat >> "$RESULTS_FILE" <<EOF
{
  "api": "$api_name",
  "url": "$api_url",
  "timestamp": "$(date -Iseconds)",
  "status": "$status",
  "http_code": $http_code,
  "latency_ms": $latency,
  "issue": "$issue"
},
EOF
    
    case "$status" in
        ok) echo "  ✅ $api_name: OK (${latency}ms)" ;;
        slow) echo "  ⚠️  $api_name: SLOW (${latency}ms)" ;;
        *) echo "  ❌ $api_name: $issue" ;;
    esac
done

# Close JSON array (remove trailing comma)
sed -i '$ s/,$//' "$RESULTS_FILE"
echo "]" >> "$RESULTS_FILE"

# Alert if threshold exceeded
if [ $failed_count -ge $ALERT_THRESHOLD ]; then
    echo ""
    echo "🚨 API HEALTH ALERT: $failed_count APIs failed"
    echo "   Check: $RESULTS_FILE"
    
    # Send Telegram notification
    message send --target telegram-me --message \
        "⚠️ API Health Check Failed\n\n${failed_count} APIs are down or degraded.\n\nCheck: memory/api-health-$(date +%Y-%m-%d).json"
fi

exit $failed_count
```

#### Schema Validation (Advanced)

**Idea:** No solo "¿responde?", sino "¿responde como esperamos?"

```python
#!/usr/bin/env python3
# scripts/api-schema-check.py

import requests
import json
import jsonschema

# Expected schema for Anthropic response
ANTHROPIC_SCHEMA = {
    "type": "object",
    "required": ["id", "type", "role", "content", "model"],
    "properties": {
        "id": {"type": "string"},
        "type": {"type": "string", "enum": ["message"]},
        "role": {"type": "string", "enum": ["assistant"]},
        "content": {"type": "array"},
        "model": {"type": "string"}
    }
}

def check_anthropic():
    response = requests.post(
        "https://api.anthropic.com/v1/messages",
        headers={
            "x-api-key": os.getenv("ANTHROPIC_API_KEY"),
            "anthropic-version": "2023-06-01",
            "content-type": "application/json"
        },
        json={
            "model": "claude-sonnet-4-5",
            "messages": [{"role": "user", "content": "hi"}],
            "max_tokens": 10
        },
        timeout=10
    )
    
    if response.status_code != 200:
        return {"status": "error", "issue": f"HTTP {response.status_code}"}
    
    try:
        data = response.json()
        jsonschema.validate(instance=data, schema=ANTHROPIC_SCHEMA)
        return {"status": "ok", "schema": "valid"}
    except jsonschema.ValidationError as e:
        return {"status": "schema_changed", "issue": str(e)}
    except Exception as e:
        return {"status": "error", "issue": str(e)}

# Similar checks for other APIs...
```

#### Frecuencia de Checks

**Recomendación:**

| Check Type | Frequency | Rationale |
|------------|-----------|-----------|
| **Critical APIs** (Anthropic, Telegram) | **Every 30 min** | Detect outages fast |
| **High APIs** (Google, GitHub) | **Every 2 hours** | Balance monitoring vs rate limits |
| **Medium APIs** (Garmin, OpenAI) | **Daily** (09:00) | Before morning workflows |
| **Low APIs** (Weather) | **Daily** (08:00) | Once before briefing |
| **Schema validation** | **Weekly** (Sunday night) | Catch API changes early |

**Cron config:**
```json
{
  "jobs": [
    {
      "name": "api-health:critical",
      "schedule": "*/30 * * * *",
      "command": "bash scripts/api-health-check.sh --apis anthropic,telegram"
    },
    {
      "name": "api-health:high",
      "schedule": "0 */2 * * *",
      "command": "bash scripts/api-health-check.sh --apis google,github"
    },
    {
      "name": "api-health:full",
      "schedule": "0 9 * * *",
      "command": "bash scripts/api-health-check.sh --all"
    },
    {
      "name": "api-schema-validation",
      "schedule": "0 2 * * 0",
      "command": "python3 scripts/api-schema-check.py"
    }
  ]
}
```

### ¿Qué Hacer Si una API Falla?

**Decision tree:**

```
API Health Check Failed
    ↓
Is it CRITICAL? (Anthropic, Telegram)
    YES → Alert immediately (Telegram/Discord fallback)
    NO  → Log + defer alert to morning briefing
    ↓
Can we fallback?
    YES → Switch to fallback (e.g. Anthropic → Google)
    NO  → Disable dependent workflows
    ↓
Retry after backoff?
    YES → Exponential backoff (1min, 5min, 15min)
    NO  → Mark as "degraded" + manual intervention
```

**Fallback config:**
```json
{
  "api_fallbacks": {
    "anthropic": {
      "primary": "anthropic/claude-sonnet-4-5",
      "fallbacks": ["google/gemini-3-flash-preview"],
      "retry_after_seconds": 300
    },
    "google": {
      "primary": "google/gemini-3-flash-preview",
      "fallbacks": ["anthropic/claude-haiku-4-5"],
      "retry_after_seconds": 600
    }
  }
}
```

**Alert message:**
```
🚨 CRITICAL: Anthropic API Down

Status: HTTP 500 (Server Error)
Last success: 2026-03-24 08:45
Fallback: Switched to Google Gemini Flash
ETA: Retrying in 5 minutes

Action: Monitor status.anthropic.com
```

---

## 4. Otros Arneses Útiles

### 4.1 Config Drift Detection

**Problema:** `openclaw.json` en disco diverge de lo esperado

**Causas:**
- Manual edits que no siguen convenciones
- Merge conflicts mal resueltos
- Corruption (rare, pero posible)

**Solución:**

```bash
#!/bin/bash
# scripts/config-drift-check.sh

CONFIG="$HOME/.openclaw/openclaw.json"
EXPECTED_SCHEMA="$HOME/.openclaw/workspace/schemas/openclaw-config.schema.json"

# 1. JSON schema validation
if ! jq -e . "$CONFIG" >/dev/null 2>&1; then
    echo "❌ Config is not valid JSON"
    exit 1
fi

# 2. Schema compliance
if ! npx --yes ajv-cli validate -s "$EXPECTED_SCHEMA" -d "$CONFIG" 2>/dev/null; then
    echo "⚠️  Config doesn't match expected schema"
fi

# 3. Compare with last known good
LAST_GOOD="$HOME/.openclaw/workspace/memory/last-known-good-config.json"
if [ -f "$LAST_GOOD" ]; then
    diff_output=$(diff -u "$LAST_GOOD" "$CONFIG" | grep -E '^\+|^-' | grep -vE '^\+\+\+|^---')
    
    if [ -n "$diff_output" ]; then
        echo "⚠️  Config drift detected:"
        echo "$diff_output"
        
        # Ask if current config should become new "last known good"
        read -p "Accept these changes as new baseline? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            cp "$CONFIG" "$LAST_GOOD"
            echo "✅ Baseline updated"
        fi
    else
        echo "✅ No drift detected"
    fi
else
    # First run - establish baseline
    cp "$CONFIG" "$LAST_GOOD"
    echo "✅ Baseline established"
fi
```

**Cron:** Daily check + alert si drift significativo

### 4.2 Dependency Version Pinning

**Problema:** Updates automáticos rompen compatibilidad

**Ejemplos:**
- `npm update` instala nueva major version de skill
- Python package update cambia API
- Node.js version cambió (system update)

**Solución:**

```bash
#!/bin/bash
# scripts/dependency-freeze-check.sh

# Snapshot current versions
npm list --depth=0 > memory/dependency-snapshot-npm.txt
pip freeze > memory/dependency-snapshot-pip.txt
node --version > memory/dependency-snapshot-node.txt

# Compare with previous snapshot
if [ -f memory/dependency-snapshot-npm.txt.prev ]; then
    diff=$(diff memory/dependency-snapshot-npm.txt.prev memory/dependency-snapshot-npm.txt)
    if [ -n "$diff" ]; then
        echo "⚠️  NPM dependencies changed:"
        echo "$diff"
    fi
fi

# Rotate snapshots
cp memory/dependency-snapshot-npm.txt memory/dependency-snapshot-npm.txt.prev
cp memory/dependency-snapshot-pip.txt memory/dependency-snapshot-pip.txt.prev
cp memory/dependency-snapshot-node.txt memory/dependency-snapshot-node.txt.prev
```

**Cron:** Weekly snapshot + alert on unexpected changes

### 4.3 Sandbox Escape Detection

**Problema:** Proceso hace cosas fuera del workspace

**Ejemplos:**
- Script escribe a `/tmp` en vez de `~/.openclaw/tmp`
- Process intenta acceder a `/home/mleon/Documents` (fuera de workspace)
- Network request a IP no permitida

**Solución (limitada sin kernel-level hooks):**

```bash
#!/bin/bash
# scripts/sandbox-escape-check.sh

# Check for unexpected file writes
echo "🔍 Checking for files outside workspace..."

# Find files modified in last hour outside allowed dirs
find / -type f -mmin -60 \
    ! -path "/home/mleon/.openclaw/*" \
    ! -path "/tmp/*" \
    ! -path "/var/log/*" \
    ! -path "/proc/*" \
    ! -path "/sys/*" \
    2>/dev/null | while read -r file; do
    
    echo "⚠️  Unexpected write: $file"
done

# Check network connections from openclaw processes
netstat -tnp 2>/dev/null | grep openclaw | while read -r line; do
    remote_ip=$(echo "$line" | awk '{print $5}' | cut -d: -f1)
    
    # Whitelist known IPs (Anthropic, Google, etc.)
    if ! grep -q "$remote_ip" memory/allowed-ips.txt; then
        echo "⚠️  Unexpected network connection: $remote_ip"
    fi
done
```

**Limitación:** Sin privilegios root, detección es imperfecta  
**Alternativa:** Docker container con network/filesystem restrictions

### 4.4 Rate Limit Monitoring

**Problema:** Agotamos cuotas de APIs sin darnos cuenta

**Identificado en memoria existente:**
- Gemini embeddings quota (2000/day)
- Brave Search quota (tracked pero no monitoreado proactivamente)

**Solución:**

```python
#!/usr/bin/env python3
# scripts/rate-limit-monitor.py

import os
import json
from datetime import datetime

QUOTAS = {
    "anthropic": {
        "limit": None,  # No public limit, but track usage
        "cost_per_1k_input": 0.003,  # Sonnet 4.5
        "cost_per_1k_output": 0.015,
        "monthly_budget": 50  # USD
    },
    "google": {
        "limit": 1500,  # Free tier RPD (requests per day)
        "cost_per_1k": 0.00025,  # Flash
        "monthly_budget": 20
    },
    "brave_search": {
        "limit": 2000,  # Free tier monthly
        "cost_per_query": 0.005,  # Paid tier
        "monthly_budget": 10
    },
    "openai": {
        "limit": None,
        "cost_per_1k_input": 0.001,  # Whisper
        "monthly_budget": 15
    }
}

USAGE_FILE = os.path.expanduser("~/.openclaw/workspace/memory/api-usage-tracking.json")

def load_usage():
    if os.path.exists(USAGE_FILE):
        with open(USAGE_FILE) as f:
            return json.load(f)
    return {}

def save_usage(usage):
    with open(USAGE_FILE, 'w') as f:
        json.dump(usage, f, indent=2)

def check_quotas():
    usage = load_usage()
    today = datetime.now().strftime("%Y-%m-%d")
    alerts = []
    
    for api, quota_info in QUOTAS.items():
        daily_usage = usage.get(api, {}).get(today, 0)
        monthly_usage = sum(
            usage.get(api, {}).get(day, 0)
            for day in usage.get(api, {})
            if day.startswith(datetime.now().strftime("%Y-%m"))
        )
        
        # Check daily limit
        if quota_info["limit"] and daily_usage > quota_info["limit"] * 0.8:
            percent = (daily_usage / quota_info["limit"]) * 100
            alerts.append(f"⚠️  {api}: {percent:.0f}% of daily quota used")
        
        # Check monthly budget
        monthly_cost = monthly_usage * quota_info.get("cost_per_1k", 0) / 1000
        budget = quota_info["monthly_budget"]
        if monthly_cost > budget * 0.8:
            percent = (monthly_cost / budget) * 100
            alerts.append(f"⚠️  {api}: ${monthly_cost:.2f} / ${budget} (${percent:.0f}%) this month")
    
    return alerts

def main():
    alerts = check_quotas()
    
    if alerts:
        print("🚨 Rate Limit Alerts:")
        for alert in alerts:
            print(f"   {alert}")
        
        # Send notification
        os.system(f'message send --target telegram-me --message "{"\\n".join(alerts)}"')
    else:
        print("✅ All API quotas within limits")

if __name__ == "__main__":
    main()
```

**Integration:** Hook into OpenClaw's request layer to auto-increment counters

**Cron:** Check daily at 20:00 (before day ends)

### 4.5 Log Anomaly Detection

**Problema:** Patrones extraños en logs indican problemas

**Ejemplos:**
- Sudden spike en error rate
- Repeated failed auth attempts
- Unusual commands executed
- Memory/CPU spikes

**Solución (simple heuristics):**

```bash
#!/bin/bash
# scripts/log-anomaly-check.sh

LOGS_DIR="$HOME/.openclaw/logs"
ANOMALIES=()

# Check error rate
today_errors=$(grep -c "ERROR" "$LOGS_DIR/gateway-$(date +%Y-%m-%d).log" 2>/dev/null || echo 0)
avg_errors=$(find "$LOGS_DIR" -name "gateway-*.log" -mtime -7 -exec grep -c "ERROR" {} \; | \
    awk '{sum+=$1} END {print sum/NR}')

if [ "$today_errors" -gt "$((avg_errors * 2))" ]; then
    ANOMALIES+=("⚠️  Error rate spike: $today_errors today vs $avg_errors avg")
fi

# Check for repeated failures
repeated=$(grep "ERROR" "$LOGS_DIR/gateway-$(date +%Y-%m-%d).log" 2>/dev/null | \
    awk '{print $NF}' | sort | uniq -c | sort -rn | head -1)

if echo "$repeated" | grep -qE '^\s*[0-9]{2,}'; then
    ANOMALIES+=("⚠️  Repeated error: $(echo $repeated | awk '{$1=""; print $0}')")
fi

# Report anomalies
if [ ${#ANOMALIES[@]} -gt 0 ]; then
    echo "🔍 Log Anomalies Detected:"
    printf '%s\n' "${ANOMALIES[@]}"
else
    echo "✅ No log anomalies"
fi
```

**Cron:** Daily at 23:00 (end of day summary)

---

## 5. Ejemplos de Otros Proyectos

### Resumen de Patrones

| Proyecto | Patrón | Aplicable a OpenClaw |
|----------|--------|----------------------|
| **Constitutional AI** (Anthropic) | IA supervisa IA usando principios | ✅ Reviewer agent |
| **LangChain PreCompletionChecklist** | Middleware validation antes de completion | ✅ Subagent review harness |
| **OpenAI Codex + Linters** | Loop generación → lint → fix | ✅ Cron dry-run con retry |
| **AutoGPT Failsafes** | Command whitelist + resource limits | ✅ Sandbox escape detection |
| **Stripe Minions** | CI integration + devbox isolation | 🔶 Partial (no full CI yet) |
| **LangChain DeepAgents** | Loop detection + reasoning sandwich | ✅ Could add to harness |
| **Descript Evals** | Three dimensions: don't break / do it / do it well | ✅ Review criteria |

**Técnicas comunes:**
1. **Rule-based + AI hybrid** — Combina checks determinísticos con reviewers IA
2. **Self-verification loops** — Agente verifica su propio output antes de completion
3. **Middleware architecture** — Capas composables de validation
4. **Observability integration** — Agentes leen logs/metrics para self-correct
5. **Entropy management** — Cleanup agents periódicos

---

## 6. Trade-Offs: Pros vs Contras

### Pros (Beneficios)

✅ **Más robusto:**
- Catch errors antes de producción
- Menos crashes nocturnos
- Workflows más confiables

✅ **Menos intervenciones manuales:**
- Auto-recovery de fallos comunes
- Alertas solo para casos críticos
- Manu duerme mejor 😴

✅ **Mejor observability:**
- Logs estructurados de validación
- Métricas de health de APIs
- Visibility en dependency drift

✅ **Escalabilidad:**
- Más subagentes sin más risk
- Cron jobs más complejos con confidence
- Foundation para features avanzadas

### Contras (Costos)

❌ **Más complejidad:**
- Más código que mantener
- Más moving parts que pueden fallar
- Learning curve para editar harnesses

❌ **Latencia adicional:**
- Validation añade 3-6s por subagent
- Health checks consumen recursos
- Dry-runs retrasan deployments

❌ **Posibles falsos positivos:**
- Validator rechaza output válido → frustración
- API health check false alarm → alert fatigue
- Schema validation demasiado estricta → bloquea innovación

❌ **Costos de API:**
- Reviewer agent consume tokens
- Schema checks hacen test requests
- Rate limit monitoring overhead

### Balance: ¿Cuánto es "Suficiente"?

**Framework de decisión:**

```
Para cada arnés propuesto:

1. ¿Cuál es el worst-case sin este arnés?
   - If "system breaks" → IMPLEMENT
   - If "inconvenience" → DEFER
   - If "aesthetic issue" → SKIP

2. ¿Cuál es el esfuerzo de implementación?
   - If <1 day → QUICK WIN
   - If 1-3 days → SCHEDULE
   - If >1 week → CHUNK into smaller pieces

3. ¿Se puede hacer más simple?
   - Start with minimal version
   - Add complexity only if needed
   - Prefer rule-based over AI when sufficient

4. ¿Es evolucionable?
   - Can it grow with system?
   - Can it be disabled/bypassed if needed?
   - Does it block future improvements?
```

**Principio guía:** **"Perfect is the enemy of good"**
- Ship 80% solution today > 100% solution never
- Iterate based on real failures
- Add validation when pain is felt, not preemptively

---

## 7. Priorización: Impacto vs Esfuerzo

### Matriz de Priorización

```
      HIGH IMPACT
           |
    Q1     |     Q2
   QUICK   |   INVEST
    WINS   |    TIME
-----------|----------
    Q3     |     Q4
  DEFER    |   AVOID
           |
      LOW IMPACT
```

### Arneses Evaluados

| # | Arnés | Impacto | Esfuerzo | Quadrant | Prioridad |
|---|-------|---------|----------|----------|-----------|
| **1** | **Pre-flight checks de APIs** | 🔴 HIGH | 🟢 LOW (1 day) | **Q1 QUICK WIN** | **P0** |
| **2** | **Testing automático de crons** | 🔴 HIGH | 🟡 MED (2 days) | **Q1 QUICK WIN** | **P0** |
| **3** | **Rate limit monitoring** | 🟠 MEDIUM | 🟢 LOW (1 day) | **Q1 QUICK WIN** | **P1** |
| **4** | **Config drift detection** | 🟠 MEDIUM | 🟢 LOW (0.5 day) | **Q1 QUICK WIN** | **P1** |
| **5** | **Validador de output de subagentes** | 🔴 HIGH | 🔴 HIGH (3-5 days) | **Q2 INVEST** | **P2** |
| **6** | **Dependency version pinning** | 🟢 LOW | 🟢 LOW (0.5 day) | **Q3 DEFER** | **P3** |
| **7** | **Log anomaly detection** | 🟢 LOW | 🟡 MED (2 days) | **Q4 AVOID** | **P4** |
| **8** | **Sandbox escape detection** | 🟢 LOW | 🔴 HIGH (5+ days) | **Q4 AVOID** | **P5** |

### Reasoning

**P0 (Empezar ahora):**

1. **Pre-flight checks de APIs** — **IMPACTO MUY ALTO, ESFUERZO BAJO**
   - **Por qué:** Previene fallos silenciosos de workflows críticos (morning briefing, heartbeats)
   - **Quick win:** Script bash simple + cron job
   - **ROI:** Alta confidence en workflows dependientes de APIs
   - **Esfuerzo:** ~1 día (8h)

2. **Testing automático de crons** — **IMPACTO MUY ALTO, ESFUERZO MEDIO**
   - **Por qué:** Crons que fallan silenciosamente son pesadilla de debugging
   - **Quick win:** Dry-run framework + pre-commit hook
   - **ROI:** Catch errores antes de deploy en vez de días después
   - **Esfuerzo:** ~2 días (16h)

**P1 (Esta semana):**

3. **Rate limit monitoring** — **IMPACTO MEDIO-ALTO, ESFUERZO BAJO**
   - **Por qué:** Ya tuviste issues con Gemini quota
   - **Quick win:** Tracking script + daily cron
   - **ROI:** Evita agotar quotas inesperadamente
   - **Esfuerzo:** ~1 día (8h)

4. **Config drift detection** — **IMPACTO MEDIO, ESFUERZO MUY BAJO**
   - **Por qué:** Protege contra edits manuales que rompen sistema
   - **Quick win:** Diff script + baseline
   - **ROI:** Catch config corruption early
   - **Esfuerzo:** ~4h

**P2 (Próximas 2 semanas):**

5. **Validador de output de subagentes** — **IMPACTO ALTO, ESFUERZO ALTO**
   - **Por qué:** Subagents son cada vez más autónomos → más risk
   - **NOT a quick win:** Requiere diseño cuidadoso + calibración
   - **ROI:** Foundation para más autonomía segura
   - **Esfuerzo:** ~3-5 días (24-40h)
   - **Chunking:** Empezar con Fase 1 (structural) solo

**P3 (Nice to have):**

6. **Dependency version pinning**
   - **Por qué:** No es problema urgente ahora
   - **Cuándo:** Cuando tengas first major breakage por update

**P4-P5 (Defer indefinidamente):**

7. **Log anomaly detection**
   - **Por qué:** Logs son manejables manualmente por ahora
   - **Cuándo:** Si logs crecen 10x en volumen

8. **Sandbox escape detection**
   - **Por qué:** Demasiado esfuerzo, poco ROI sin kernel-level hooks
   - **Alternativa:** Docker container si realmente se necesita

---

## 8. Entregables Requeridos

### 8.1 Listado Priorizado de Arneses

**Ver Sección 7 arriba** ✅

### 8.2 Pseudocódigo/Arquitectura para los 3 Más Importantes

#### #1: Pre-flight Checks de APIs

**Arquitectura:**
```
┌─────────────────────────────────────┐
│  Cron Scheduler (09:00 daily)      │
└───────────────┬─────────────────────┘
                │
                ▼
┌─────────────────────────────────────┐
│  API Health Check Script            │
│  ├─ For each critical API:          │
│  │   ├─ Connectivity test (curl)    │
│  │   ├─ Auth validation             │
│  │   ├─ Latency measurement         │
│  │   └─ Schema check (optional)     │
│  │                                   │
│  └─ Log results to JSON             │
└───────────────┬─────────────────────┘
                │
                ▼
┌─────────────────────────────────────┐
│  Evaluation & Decision              │
│  ├─ If ≥2 APIs failed → Alert       │
│  ├─ If critical API down → Failover │
│  └─ Else → Log only                 │
└───────────────┬─────────────────────┘
                │
                ▼
┌─────────────────────────────────────┐
│  Actions                            │
│  ├─ Telegram notification           │
│  ├─ Update memory/api-health.json   │
│  └─ Switch to fallback if needed    │
└─────────────────────────────────────┘
```

**Pseudocódigo:**
```python
def check_api_health(api_name, api_url, auth_headers):
    """
    Health check for a single API.
    Returns: {status, http_code, latency_ms, issue}
    """
    start = time.now()
    
    try:
        response = http.get(api_url, headers=auth_headers, timeout=10)
        latency = time.now() - start
        
        # Evaluate status
        if response.status >= 500:
            return {status: "down", issue: f"Server error {response.status}"}
        elif response.status in [401, 403]:
            return {status: "auth_failed", issue: "Authentication failed"}
        elif response.status == 429:
            return {status: "rate_limited", issue: "Rate limit exceeded"}
        elif latency > 5000:
            return {status: "slow", issue: f"Latency {latency}ms"}
        else:
            return {status: "ok", latency_ms: latency}
    
    except TimeoutError:
        return {status: "timeout", issue: "Request timed out"}
    except Exception as e:
        return {status: "error", issue: str(e)}

def main():
    apis = [
        ("anthropic", "https://api.anthropic.com/v1/messages", {...}),
        ("google", "https://generativelanguage.googleapis.com/...", {...}),
        # ...
    ]
    
    results = []
    failed_count = 0
    
    for api_name, api_url, headers in apis:
        result = check_api_health(api_name, api_url, headers)
        results.append({api: api_name, **result})
        
        if result.status not in ["ok", "slow"]:
            failed_count += 1
    
    # Log results
    save_json(f"memory/api-health-{today}.json", results)
    
    # Alert if threshold exceeded
    if failed_count >= 2:
        send_telegram_alert(f"🚨 {failed_count} APIs failed. Check logs.")
    
    # Trigger failover if critical API down
    critical_apis = ["anthropic", "telegram"]
    for result in results:
        if result.api in critical_apis and result.status == "down":
            trigger_failover(result.api)
```

#### #2: Testing Automático de Crons

**Arquitectura:**
```
┌─────────────────────────────────────┐
│  Git Pre-commit Hook                │
│  (triggered on cron/jobs.json edit) │
└───────────────┬─────────────────────┘
                │
                ▼
┌─────────────────────────────────────┐
│  Cron Validation Pipeline           │
│  ├─ [1] Schedule syntax check       │
│  ├─ [2] Script existence & perms    │
│  ├─ [3] Dependency resolution       │
│  ├─ [4] Dry-run execution           │
│  └─ [5] Historical comparison       │
└───────────────┬─────────────────────┘
                │
                ▼
┌─────────────────────────────────────┐
│  Decision                           │
│  ├─ All passed → Allow commit       │
│  ├─ Warnings → Prompt user          │
│  └─ Errors → Block commit           │
└─────────────────────────────────────┘
```

**Pseudocódigo:**
```python
def validate_cron_job(job_config):
    """
    Validate a single cron job config.
    Returns: {passed: bool, errors: [], warnings: []}
    """
    errors = []
    warnings = []
    
    # [1] Schedule syntax
    if not is_valid_cron_schedule(job_config.schedule):
        errors.append(f"Invalid schedule: {job_config.schedule}")
    
    # [2] Script existence
    if job_config.command.startswith("bash "):
        script_path = job_config.command.split()[1]
        if not os.path.exists(script_path):
            errors.append(f"Script not found: {script_path}")
        elif not os.access(script_path, os.X_OK):
            warnings.append(f"Script not executable: {script_path}")
    
    # [3] Dependencies
    missing_deps = check_dependencies(job_config.command)
    if missing_deps:
        errors.append(f"Missing dependencies: {', '.join(missing_deps)}")
    
    # [4] Dry-run (if script supports it)
    if supports_dry_run(job_config.command):
        dry_run_result = execute_dry_run(job_config.command)
        if dry_run_result.exit_code != 0:
            errors.append(f"Dry-run failed: {dry_run_result.stderr}")
    
    # [5] Historical comparison
    previous_config = get_previous_version(job_config.name)
    if previous_config and previous_config.schedule != job_config.schedule:
        warnings.append(f"Schedule changed: {previous_config.schedule} → {job_config.schedule}")
    
    return {
        passed: len(errors) == 0,
        errors: errors,
        warnings: warnings
    }

def main():
    # Load changed cron jobs
    changed_jobs = load_changed_cron_jobs()
    
    all_passed = True
    for job in changed_jobs:
        result = validate_cron_job(job)
        
        if not result.passed:
            print(f"❌ Validation failed for '{job.name}':")
            for error in result.errors:
                print(f"   - {error}")
            all_passed = False
        
        if result.warnings:
            print(f"⚠️  Warnings for '{job.name}':")
            for warning in result.warnings:
                print(f"   - {warning}")
    
    if not all_passed:
        print("\n❌ Cron validation failed. Fix errors before committing.")
        print("   Or use: git commit --no-verify (not recommended)")
        sys.exit(1)
    else:
        print("✅ Cron validation passed")
```

#### #3: Rate Limit Monitoring

**Arquitectura:**
```
┌─────────────────────────────────────┐
│  Request Interceptor (hooks)        │
│  (logs API usage to tracking file)  │
└───────────────┬─────────────────────┘
                │
                ▼
┌─────────────────────────────────────┐
│  Usage Tracking File                │
│  memory/api-usage-tracking.json     │
│  {                                   │
│    "anthropic": {                    │
│      "2026-03-24": 450,              │
│      "2026-03-23": 523               │
│    },                                │
│    "google": { ... }                 │
│  }                                   │
└───────────────┬─────────────────────┘
                │
                ▼
┌─────────────────────────────────────┐
│  Daily Cron (20:00)                 │
│  Check usage vs quotas              │
└───────────────┬─────────────────────┘
                │
                ▼
┌─────────────────────────────────────┐
│  Alert if threshold exceeded        │
│  ├─ Daily quota: >80% → Warn        │
│  ├─ Monthly budget: >80% → Warn     │
│  └─ Exceeded: Alert + suggest action│
└─────────────────────────────────────┘
```

**Pseudocódigo:**
```python
# Hook into OpenClaw's request layer
def track_api_usage(api_name, request_tokens):
    """
    Increment usage counter for an API.
    Called after each successful request.
    """
    usage = load_usage_file()
    today = datetime.today().strftime("%Y-%m-%d")
    
    if api_name not in usage:
        usage[api_name] = {}
    
    usage[api_name][today] = usage[api_name].get(today, 0) + request_tokens
    
    save_usage_file(usage)

def check_rate_limits():
    """
    Daily cron job to check if approaching limits.
    """
    usage = load_usage_file()
    today = datetime.today().strftime("%Y-%m-%d")
    this_month = datetime.today().strftime("%Y-%m")
    
    alerts = []
    
    for api, quota_info in QUOTAS.items():
        # Daily check
        daily_usage = usage.get(api, {}).get(today, 0)
        if quota_info.daily_limit:
            percent = (daily_usage / quota_info.daily_limit) * 100
            if percent > 80:
                alerts.append(f"⚠️  {api}: {percent:.0f}% of daily quota used")
        
        # Monthly check
        monthly_usage = sum(
            usage.get(api, {}).get(day, 0)
            for day in usage.get(api, {})
            if day.startswith(this_month)
        )
        monthly_cost = monthly_usage * quota_info.cost_per_token
        monthly_budget = quota_info.monthly_budget
        
        if monthly_cost > monthly_budget * 0.8:
            percent = (monthly_cost / monthly_budget) * 100
            alerts.append(f"⚠️  {api}: ${monthly_cost:.2f} / ${monthly_budget} ({percent:.0f}%) this month")
    
    if alerts:
        send_telegram_notification("\n".join(alerts))
    
    return alerts
```

### 8.3 Recomendación: ¿Cuál Empezamos Primero y Por Qué?

## 🎯 Recomendación: Pre-flight Checks de APIs Externas

**Empezamos con: Pre-flight Checks de APIs Externas**

### Por Qué Este Primero

**1. Quick Win (Alto impacto, bajo esfuerzo):**
- Implementación: ~1 día (8 horas)
- Impacto inmediato: Previene fallos silenciosos de workflows críticos
- ROI visible en primera semana

**2. Fundacional para otros arneses:**
- Rate limit monitoring depende de API health
- Cron testing puede usar API checks como dependency
- Config validation puede verificar que API keys son válidos

**3. Pain point real existente:**
- Ya tuviste issues con Gemini quota exhaustion
- Brave Search rate limits ya se encontraron
- Morning briefing depende de múltiples APIs → single point of failure

**4. No requiere cambios arquitectónicos:**
- Script standalone + cron job
- No modifica código core de OpenClaw
- Fácil de revertir si hay problemas

**5. Aprendizaje incremental:**
- Te familiarizas con patrones de harness engineering
- Validar approach antes de invertir en arneses más complejos
- Feedback loop rápido

### Plan de Implementación (Día 1)

**Morning (4h):**
```
09:00-10:00  Escribir scripts/api-health-check.sh (basic version)
10:00-11:00  Añadir checks para: Anthropic, Google, Telegram
11:00-12:00  Test manual + fix bugs
12:00-13:00  Crear cron job + notification logic
```

**Afternoon (4h):**
```
14:00-15:00  Añadir checks para: GitHub, Garmin, Brave Search
15:00-16:00  Implementar fallback logic (Anthropic → Google)
16:00-17:00  Escribir memory/api-health-baseline.json
17:00-18:00  Documentation + test end-to-end
```

**Evening:**
```
20:00  First scheduled run → validate alerts work
```

### Criterios de Éxito (Semana 1)

✅ **Funcional:**
- Script corre daily sin intervención manual
- Detecta cuando API está down (test: apagar VPN para simular)
- Notifica a Telegram cuando threshold excedido

✅ **Útil:**
- Catch al menos 1 issue real en primera semana
- Manu confía en que workflows dependen de APIs saludables
- Zero false positives (si los hay, ajustar thresholds)

✅ **Evolucionable:**
- Fácil añadir nuevas APIs
- Logs estructurados para future analysis
- Foundation para schema validation (Fase 2)

### Después de Esto: Testing Automático de Crons

**Por qué segundo:**
- Builds on confidence de API checks
- También es quick win (~2 días)
- Previene otro pain point real (cron fallos silenciosos)

**Timing:**
- Empezar 2-3 días después de API checks (dejar que madure primero)
- Implementar durante semana tranquila (no justo antes de viaje)

### Qué NO Hacer Primero

❌ **Validador de output de subagentes:**
- Demasiado complejo para empezar
- Requiere diseño cuidadoso + calibración
- Risk de over-engineering si no tienes pain point claro

❌ **Sandbox escape detection:**
- Alto esfuerzo, bajo ROI
- No hay evidencia de que sea problema actual

❌ **Log anomaly detection:**
- Nice to have, no crítico
- Logs son manejables manualmente por ahora

---

## 9. Conclusiones & Next Steps

### Hallazgos Clave

1. **Harness engineering es más importante que model tuning:**
   - LangChain: +14% benchmark score **sin cambiar modelo**
   - OpenAI: 1M líneas código generadas con harness robusto
   - Pattern: **AI + Rules hybrid** es más efectivo que pure AI

2. **Validación IA-sobre-IA es viable:**
   - Constitutional AI prueba concepto a escala
   - Reviewer agent puede ser más confiable que executor
   - Requiere calibración periódica con feedback humano

3. **Quick wins > Perfect solutions:**
   - Pre-flight checks: 1 día, alto impacto
   - Cron testing: 2 días, previene fallos silenciosos
   - Empezar simple, iterar basándose en fallos reales

4. **OpenClaw ya tiene fundación sólida:**
   - `pre-restart-validator.sh` es buen starting point
   - Memory architecture soporta logging de validación
   - Cron system permite scheduled checks

### Trade-offs Fundamentales

| Dimensión | Sin Arneses | Con Arneses | Balance |
|-----------|-------------|-------------|---------|
| **Robustez** | Frágil | Robusto | ⚖️ Start minimal, grow |
| **Complejidad** | Simple | Complejo | ⚖️ Add complexity only when needed |
| **Latencia** | Rápido | Lento | ⚖️ Async validation, fast-paths |
| **Autonomía** | Limitada | Alta | ⚖️ Safety-first, then scale |

**Principio guía:** **"Fail safe, not safe from failure"**
- Sistemas van a fallar → diseñar para recovery
- Validation previene fallos catastróficos
- Pero no intentes prevenir todos los fallos → diminishing returns

### Roadmap Propuesto

**Fase 1: Quick Wins (Esta semana)**
```
✅ Pre-flight checks de APIs externas (1 día)
✅ Rate limit monitoring básico (1 día)
✅ Config drift detection (0.5 días)
Total: 2.5 días
```

**Fase 2: Testing Infrastructure (Próximas 2 semanas)**
```
✅ Testing automático de crons (2 días)
✅ Dependency version pinning (0.5 días)
Total: 2.5 días
```

**Fase 3: Advanced Validation (Próximo mes)**
```
✅ Validador de output de subagentes - Fase 1 (structural) (2 días)
✅ Validador de output de subagentes - Fase 2 (AI review) (2 días)
✅ Calibration loop para reviewer (1 día)
Total: 5 días
```

**Fase 4: Observability (Futuro)**
```
🔶 Log anomaly detection (2 días)
🔶 Entropy management agents (3 días)
🔶 Advanced schema validation (2 días)
Total: 7 días (defer until pain point)
```

### Métricas de Éxito

**Tracking recomendado:**

```json
{
  "harness_metrics": {
    "api_health_checks": {
      "total_checks": 0,
      "failures_detected": 0,
      "false_positives": 0,
      "failovers_triggered": 0
    },
    "cron_validation": {
      "jobs_validated": 0,
      "errors_caught": 0,
      "commits_blocked": 0
    },
    "subagent_review": {
      "outputs_reviewed": 0,
      "auto_approved": 0,
      "flagged_for_human": 0,
      "rejected": 0
    },
    "rate_limits": {
      "alerts_sent": 0,
      "quotas_exceeded": 0,
      "monthly_cost_usd": 0
    }
  }
}
```

**Review mensual:**
- ¿Cuántos issues caught antes de producción?
- ¿Cuántos false positives? (target: <5%)
- ¿Cuánto tiempo saved vs debugging después?

### Último Pensamiento

> **"The harness is not overhead. The harness is the moat."**
> — Mitchell Hashimoto

Sin arneses, OpenClaw es un agente IA impresionante pero frágil.  
Con arneses, OpenClaw es un **sistema robusto** que puede evolucionar sin break things.

La inversión en harness engineering hoy = foundation para autonomía escalable mañana.

---

## Referencias

1. **Anthropic Research:**
   - Constitutional AI: https://www.anthropic.com/research/constitutional-ai-harmlessness-from-ai-feedback
   - Effective Harnesses for Long-Running Agents: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
   - Demystifying Evals for AI Agents: https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents

2. **Industry Practices:**
   - OpenAI Harness Engineering: https://openai.com/index/harness-engineering/
   - Martin Fowler: https://martinfowler.com/articles/exploring-gen-ai/harness-engineering.html
   - NxCode Complete Guide: https://www.nxcode.io/resources/news/harness-engineering-complete-guide-ai-agent-codex-2026

3. **API Monitoring:**
   - APIDNA Autonomous Agents: https://apidna.ai/api-rate-limiting-and-throttling-with-autonomous-agents/
   - Nordic APIs Rate Limiting: https://nordicapis.com/how-ai-agents-are-changing-api-rate-limit-approaches/

4. **OpenClaw Internal:**
   - Harness Engineering Research (Fase 1): `memory/2026-03-23-harness-engineering-research.md`
   - Pre-restart Validator: `scripts/pre-restart-validator.sh`
   - Backup Validator: `scripts/backup-validator.sh`

---

**Fin del documento de investigación**

**Próximos pasos:** Revisar con Manu → aprobar roadmap → implementar Fase 1
