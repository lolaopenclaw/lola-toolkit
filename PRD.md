# Product Requirements Document (PRD)
## Lola — Asistente Personal IA 24/7

**Versión:** 1.0  
**Fecha:** 2026-03-24  
**Owner:** Manuel León (manuelleonmendiola@gmail.com)  
**Estado:** Producción activa

---

## 1. Visión del Producto

**Lola** es un asistente personal con IA que funciona 24/7, diseñado para ser una compañera confiable, proactiva y capaz que ayuda a Manuel León (Manu) en todas las áreas de su vida: comunicación, finanzas, salud, desarrollo técnico, seguridad y música.

A diferencia de chatbots reactivos, Lola es **un agente autónomo** que:
- Mantiene memoria a largo plazo
- Ejecuta tareas complejas en segundo plano
- Monitoriza sistemas proactivamente
- Aprende continuamente de cada interacción
- Respeta la privacidad y autonomía de Manu

### Diferenciadores Clave

1. **Memoria persistente estructurada** — No olvida contexto entre sesiones
2. **Autonomía con supervisión** — Ejecuta, pero pregunta antes de acciones externas
3. **Multi-modal** — Texto, voz (TTS en coche), comandos, crons
4. **Harness engineering** — Validación IA-sobre-IA para robustez
5. **Agent-first architecture** — Todo en Markdown y archivos legibles por humanos
6. **Personalidad coherente** — Tono femenino, concisa, directa, sin jerga corporativa

---

## 2. Usuario Objetivo

### Perfil: Manuel León Mendiola

**Demografía:**
- **Edad:** 48 años (nacido 16/02/1978)
- **Ubicación:** Logroño, La Rioja, España
- **Profesión:** Músico profesional (+20 años trayectoria)
- **Proyecto actual:** Bass in a Voice (trío vocal)
- **Tech savvy:** Alto — maneja VPS, GitHub, Python, DevOps

**Necesidades principales:**
1. **Gestión de salud:** Monitoreo continuo (Garmin), prediabetes, resistencia a insulina, tratamiento con Mounjaro
2. **Finanzas personales:** Tracking bimensual, conciliación de extractos bancarios (Norma 43 + XLSX)
3. **Comunicación:** Telegram (primary), Discord (reports), asíncrona pero responsive
4. **Proyectos técnicos:** Surf Coach AI, Lola Toolkit (GitHub), memory architecture
5. **Música:** Coordinación de ensayos, gestión de Bass in a Voice
6. **Seguridad:** Infraestructura (VPS Ubuntu), backups diarios, auditorías semanales

**Restricciones:**
- **Quiet hours:** 00:00-07:00 Madrid (solo emergencias críticas)
- **Driving mode:** Requiere TTS automático (Google TTS 1.25x speed)
- **Privacidad:** NUNCA exponer tokens, API keys, IPs, paths con usuario

**Contexto de uso:**
- **Laptop:** Trabajo dev (SSH disponible en horario laboral)
- **Móvil:** OnePlus 13 (Telegram always-on, no SSH)
- **Comunicación preferida:** Bullets over tables, concisa, actionable

---

## 3. Casos de Uso Principales

### 3.1 Conversación & Asistencia General
**Actor:** Manu  
**Frecuencia:** Diaria (5-15 interacciones/día)  
**Canal:** Telegram

**Flujo:**
1. Manu pregunta/pide algo por Telegram
2. Lola lee contexto (SOUL.md, USER.md, memoria reciente)
3. Lola responde o delega a subagent si tarea >5 min
4. Lola actualiza memoria después de cada sesión

**Ejemplos:**
- "¿Cómo está mi HbA1c este mes?"
- "Resume las últimas 5 decisiones técnicas"
- "Investiga mejores prácticas de rate-limiting en APIs REST"

### 3.2 Finanzas Personales
**Actor:** Manu + Lola (cron automático)  
**Frecuencia:** Cada 15 días  
**Canal:** GitHub (privado) + Google Sheets

**Flujo:**
1. Manu sube extractos bancarios a ~/finanzas/raw/
2. Script parsea Norma 43 (CaixaBank) + XLSX (Bankinter)
3. Deduplica y correlaciona con PayPal
4. Actualiza Google Sheet [1otxo5V79...]
5. Commit a github.com/lolaopenclaw/finanzas-personal (privado)
6. Notifica a Manu si detecta anomalías

**Métricas clave:**
- Movimientos procesados: ~60-100 cada 15 días
- Deduplicación: >95% precisión
- Tiempo de procesamiento: <10 min

### 3.3 Salud & Fitness (Garmin)
**Actor:** Garmin API + Lola (cron)  
**Frecuencia:** Informe matutino diario (10:00 AM L-V, 11:00 AM S-D)  
**Canal:** Discord (#📊-reportes-matutino)

**Flujo:**
1. Cron (9:30 AM) consulta Garmin Connect API
2. Extrae: HR, estrés, Body Battery, sueño, pasos, actividades
3. Compara con metas (HR <55 bpm, estrés <40, sleep 7-8h, pasos >8000)
4. Genera informe unificado en Discord
5. Alerta crítica (14:00, 20:00) si estrés >80 o Body Battery <20

**Datos críticos:**
- **HbA1c:** ~6.0% (target <5.7%) — prediabetes en tratamiento
- **Medicación:** Mounjaro (tirzepatida, agonista dual GIP/GLP-1)
- **Display Garmin:** Manu_Lazarus

### 3.4 Desarrollo Técnico & Coding
**Actor:** Manu + Lola (subagents)  
**Frecuencia:** Semanal  
**Canal:** GitHub (lola-toolkit público, finanzas-personal privado)

**Flujo:**
1. Manu pide implementar feature o investigar algo
2. Lola evalúa: ¿>5 min? → Spawns subagent (Sonnet 4.5)
3. Subagent implementa, testea, documenta
4. Lola valida output (harness de validación)
5. Si aprueba, commit a GitHub
6. Notifica a Manu con resumen

**Políticas GitHub:**
- ✅ Código, scripts, skills, documentación
- ❌ NUNCA secrets, keys, tokens, IPs, paths con usuario
- Rotación de PAT: Q2 2026

### 3.5 Seguridad & Monitoring
**Actor:** Lola (crons autónomos)  
**Frecuencia:** Daily (4 AM backups) + Weekly (auditorías lunes 9 AM)  
**Canal:** Telegram (solo alertas críticas)

**Flujos:**

**Backup diario (4:00 AM):**
1. Comprime ~/.openclaw/workspace/
2. Sube a Google Drive
3. Retención: 30 días
4. Valida integridad
5. Notifica solo si falla

**Auditoría semanal (lunes 9:00 AM):**
1. Ejecuta scripts: rkhunter, lynis, fail2ban check, secrets scanner
2. Compara con baseline (last known good)
3. Clasifica: CRITICAL (0-2h SLA), HIGH (24h), MEDIUM (semanal)
4. Notifica en Discord con plan de remediación

**Seguridad multi-capa (6 capas, Berman architecture):**
1. Sanitización determinística (Unicode, lookalikes, hidden instructions)
2. Frontier scanner (LLM-based, score 0-100, block >70)
3. Outbound PII scanner (secrets, emails, paths)
4. Redaction pipeline (API keys, phones, emails)
5. Runtime governance (rate limits, spend limits, loop detection)
6. Access control (path guards, URL safety, DNS rebinding)

### 3.6 Música & Coordinación
**Actor:** Manu + Lola (ad-hoc)  
**Frecuencia:** Según necesidad  
**Canal:** Telegram

**Flujo:**
1. Manu pide gestionar ensayos, buscar info de venues, crear listas de temas
2. Lola usa Google Calendar API para scheduling
3. Lola busca info en web (Brave Search)
4. Lola actualiza memory/music/bass-in-a-voice.md

**Contexto:**
- **Banda:** Bass in a Voice (Manu voz, Quique bajo, Javi percusión)
- **YouTube:** @bassinavoice
- **Historia:** +20 años trayectoria (Hijos del Exceso, Motel Lazarus, Kaiah...)

---

## 4. Requisitos Funcionales

### 4.1 Canales de Comunicación

| Canal | Uso | SLA Respuesta | Formato Preferido |
|-------|-----|---------------|-------------------|
| **Telegram** | Primary (interacción directa) | <2 min | Text / TTS (driving) |
| **Discord** | Reports consolidados | Async | Rich embeds, bullets |
| **CLI** | Dev/debug (SSH laptop) | Sync | JSON / Markdown |

**FR-001:** Sistema DEBE soportar Telegram como canal primario  
**FR-002:** Sistema DEBE detectar "estoy en el coche" y activar TTS automáticamente  
**FR-003:** Sistema DEBE auto-resetear driving mode a 22:00 diario  
**FR-004:** Sistema DEBE respetar quiet hours (00:00-07:00) excepto emergencias

### 4.2 Memoria Persistente

**FR-005:** Sistema DEBE mantener memoria estructurada en Markdown/JSON  
**FR-006:** Sistema DEBE cargar SOUL.md, USER.md, AGENTS.md cada sesión  
**FR-007:** Sistema DEBE actualizar memory/YYYY-MM-DD.md después de cada sesión  
**FR-008:** Sistema DEBE consolidar learnings en memory/learnings.md  
**FR-009:** Sistema DEBE consolidar decisions en memory/decisions.md  
**FR-010:** Sistema DEBE implementar memory decay (Hot/Warm/Cold) semanal

**Estructura memory/:**
```
memory/
├── YYYY-MM-DD.md (daily logs)
├── learnings.md (filtrado temático)
├── decisions.md (decisiones técnicas)
├── entities/ (knowledge graph PARA)
│   ├── areas/ (people/, companies/)
│   ├── projects/
│   └── resources/
├── finanzas/ (movimientos, resúmenes)
├── garmin/ (histórico, tendencias, semanales)
└── health/ (agent-instructions, profile, patterns)
```

### 4.3 Crons & Automatización

**FR-011:** Sistema DEBE soportar crons con scheduling cron-like o interval-based  
**FR-012:** Sistema DEBE permitir asignar modelo específico por cron  
**FR-013:** Sistema DEBE espaciar crons pesados (≥30 min entre ellos)  
**FR-014:** Sistema DEBE validar crons antes de deploy (syntax, deps, dry-run)

**Crons críticos (≥20 activos):**
- Backup diario (4:00 AM)
- Security audits (lunes 9:00 AM)
- Informe matutino (10:00 AM L-V, 11:00 AM S-D)
- Autoimprove agents (2:00-3:00 AM, 3 agents en secuencia)
- Memory reindex (4:30 AM)
- Surf conditions (6:00 AM)
- Garmin sync (9:30 AM)

### 4.4 Subagents & Delegación

**FR-015:** Sistema DEBE soportar hasta 5 subagents en paralelo  
**FR-016:** Sistema DEBE auto-anunciar completion de subagents (push-based)  
**FR-017:** Sistema DEBE validar output de subagents antes de aplicar (harness)  
**FR-018:** Sistema DEBE permitir depth máximo 1 (no nested subagents)

**Criterios de delegación:**
- Tarea >5 min
- Independiente (no requiere contexto conversacional)
- No requiere decisiones humanas en medio
- Paralelizable

### 4.5 Arneses de Validación

**FR-019:** Sistema DEBE implementar pre-flight checks de APIs externas cada 30 min (critical), 2h (high)  
**FR-020:** Sistema DEBE implementar failover automático Anthropic→Google si health check falla  
**FR-021:** Sistema DEBE validar sintaxis de crons antes de commit (git hook)  
**FR-022:** Sistema DEBE detectar secrets en código pre-commit (git-secrets + trufflehog)  
**FR-023:** Sistema DEBE monitorear rate limits y alertar >80% quota

**APIs críticas:**
- Anthropic (Claude) — CRITICAL
- Google (Gemini, Drive, Gmail, Calendar) — HIGH
- Telegram — CRITICAL
- GitHub — MEDIUM
- Garmin Connect — MEDIUM
- Brave Search — MEDIUM

### 4.6 TTS & Modo Conducción

**FR-024:** Sistema DEBE detectar triggers: "estoy en el coche", "estoy conduciendo", "me he montado"  
**FR-025:** Sistema DEBE usar Google TTS (1.25x speed) en modo conducción  
**FR-026:** Sistema DEBE detectar triggers de salida: "ya estoy en casa", "he llegado"  
**FR-027:** Sistema DEBE guardar estado en memory/driving-mode-state.json

---

## 5. Requisitos No Funcionales

### 5.1 Latencia & Performance

**NFR-001:** Respuesta a mensaje Telegram <2 min (90th percentile)  
**NFR-002:** Informe matutino generado <5 min  
**NFR-003:** Subagent spawn overhead <3s  
**NFR-004:** Backup diario completo <10 min  
**NFR-005:** Memory search query <500ms

### 5.2 Coste Operativo

**Budget mensual:** ~$122/mes ($70-131 rango)

| Concepto | Coste Mensual | Justificación |
|----------|---------------|---------------|
| Anthropic (Opus sessions) | $30-60 | Interacción principal con Manu |
| Anthropic (Sonnet subagents) | $20-40 | Tasks complejas, investigación |
| Google (Gemini Flash) | $5-10 | Bulk tasks, verificación |
| Anthropic (Haiku crons) | $9 | Crons rutinarios (15 crons) |
| Anthropic (Sonnet crons críticos) | $14.40 | Seguridad, Sheets, Garmin (6 crons) |
| TTS (Google) | FREE | Free tier suficiente |
| Brave Search | FREE | Free tier 2000/month suficiente |
| **TOTAL** | **$78.40-133.40** | Promedio ~$106 |

**NFR-006:** Sistema DEBE operar dentro de budget mensual $150  
**NFR-007:** Sistema DEBE alertar si coste projected >$120 a mitad de mes  
**NFR-008:** Sistema DEBE preferir Haiku/Flash para tareas rutinarias (coste optimización)

### 5.3 Seguridad

**NFR-009:** Sistema DEBE implementar 6 capas de seguridad (Berman architecture)  
**NFR-010:** Sistema DEBE escanear secrets pre-commit (git-secrets + trufflehog)  
**NFR-011:** Sistema DEBE rotacional PAT/tokens Q2 2026  
**NFR-012:** Sistema DEBE cifrar backups en Google Drive  
**NFR-013:** Sistema DEBE validar integridad de backups semanalmente  
**NFR-014:** Sistema DEBE auditar permisos de archivos nightly (nightly-security-review cron)

**Políticas:**
- NUNCA commit secrets a GitHub (público o privado)
- NUNCA compartir paths con nombre de usuario
- NUNCA exponer IPs de VPS públicamente
- Backup 30 días retención (disaster recovery)

### 5.4 Disponibilidad

**NFR-015:** Uptime gateway ≥99% mensual (target: <7.2h downtime/month)  
**NFR-016:** Crons críticos DEBEN tener retry automático (3 intentos, backoff exponencial)  
**NFR-017:** Failover API DEBE activarse en <5 min de detección de outage  
**NFR-018:** Restoration backup DEBE ser posible en <1h

**Infraestructura:**
- VPS Ubuntu 24.04 LTS (16GB RAM, 8 cores)
- OpenClaw gateway (puerto 18790)
- systemd service (auto-restart on crash)
- Tailscale VPN (acceso remoto seguro)

### 5.5 Privacidad

**NFR-019:** Sistema DEBE redactar PII antes de logging externo  
**NFR-020:** Sistema DEBE pedir confirmación antes de acciones externas (email, posts, webhooks)  
**NFR-021:** Sistema DEBE guardar memoria solo en disco local o Google Drive cifrado  
**NFR-022:** Sistema DEBE respetar quiet hours incluso en emergencias no-críticas  
**NFR-023:** Sistema DEBE notificar a Manu antes de compartir datos con terceros

---

## 6. Prioridades & Roadmap Actual

### P0 — En Producción (Completado)

✅ Gateway OpenClaw v2026.2.22+ funcional  
✅ Telegram + Discord integrados  
✅ Memoria persistente (PARA + entities)  
✅ Crons activos (20+ crons)  
✅ Backup diario + retention 30 días  
✅ Finanzas bimensuales (GitHub + Sheets)  
✅ Garmin sync + informe matutino  
✅ Driving mode con TTS  
✅ Security audits semanales  
✅ Autoimprove nightly (3 agents)

### P1 — En Desarrollo (Q1 2026)

🚧 **Arneses de validación:**
- Pre-flight checks de APIs externas (1 día) — HIGH PRIORITY
- Testing automático de crons (2 días)
- Rate limit monitoring (1 día)
- Config drift detection (0.5 días)

🚧 **Surf Coach AI:**
- Análisis de 9 vídeos completo
- MVP feedback técnico automatizado

🚧 **Lola Toolkit:**
- Publicación de scripts/skills útiles (público)
- Documentación de protocolos

### P2 — Roadmap (Q2 2026)

🔲 Validador de output de subagentes (Fase 1: structural, 2 días)  
🔲 Validador de output de subagentes (Fase 2: AI review, 2 días)  
🔲 Alertas de presupuesto (finanzas)  
🔲 Detección automática CSVs nuevos (finanzas)  
🔲 Memory decay avanzado (decay basado en uso real, no solo tiempo)  
🔲 Rotación Q2 tokens/PATs

### P3 — Futuro (Q3+ 2026)

🔲 Schema validation APIs (weekly cron)  
🔲 Log anomaly detection (cuando logs 10x volumen)  
🔲 Dependency version pinning automation  
🔲 Integración con más servicios (Notion, Spotify control)

---

## 7. Métricas de Éxito

### Operacionales

| Métrica | Target | Frecuencia Medición |
|---------|--------|---------------------|
| Uptime gateway | ≥99% | Mensual |
| Latency response (Telegram) | <2 min (p90) | Semanal |
| Crons success rate | ≥95% | Diaria |
| Backup success rate | 100% | Diaria |
| Security audit CRITICAL issues | 0 | Semanal |

### Financieras

| Métrica | Target | Frecuencia Medición |
|---------|--------|---------------------|
| Coste mensual total | <$150 | Mensual |
| Coste por sesión (Opus) | <$2 | Semanal |
| Coste por cron (Haiku) | <$0.03 | Mensual |
| Overspend alerts | 0 | Mensual |

### Calidad

| Métrica | Target | Frecuencia Medición |
|---------|--------|---------------------|
| Subagents success rate | ≥85% | Semanal |
| Harness false positives | <5% | Semanal |
| Finanzas deduplication accuracy | >95% | Bimensual |
| Garmin data sync failures | <2% | Diaria |

### Satisfacción Usuario (Manu)

| Métrica | Target | Método |
|---------|--------|--------|
| Respuestas útiles (útil/no útil) | ≥90% | Post-interaction feedback |
| Intervenciones manuales por fallo | <5/semana | Log tracking |
| "Lola me ahorró tiempo hoy" | ≥4 días/semana | End-of-week survey |

---

## 8. Restricciones & Trade-offs

### Restricciones Técnicas

1. **Max 5 subagents en paralelo** — Limitación OpenClaw actual
2. **No nested subagents** — Complejidad exponencial, debugging difícil
3. **Context window 200K tokens** — Suficiente para 99% casos, pero limita tasks muy largas
4. **API rate limits:**
   - Anthropic: No público, pero monitoreado
   - Google Gemini: 1500 RPD (free tier)
   - Brave Search: 2000/month (free tier)

### Trade-offs Fundamentales

| Decisión | Pro | Contra | Razón Elegida |
|----------|-----|--------|---------------|
| **Markdown over DB** | Git-friendly, human-readable, fácil backup | No queries complejas, no relations | Agent-first: Lola debe poder leer sus propios archivos |
| **Multi-model (Opus/Sonnet/Haiku/Flash)** | Optimiza coste, 13x saving en bulk tasks | Más complejidad config | Budget mensual limitado ($150) |
| **Filesystem-based workspace** | Simple, portable, versionable | No ACID, no concurrent writes | Single-agent primary, subagents coordinados |
| **6 capas seguridad** | Defense in depth, robusto | Latencia +500ms, complejidad | Security > speed para acciones externas |
| **Crons espaciados ≥30 min** | Evita resource contention | Menor paralelización | LLM tokens son cuello de botella |
| **Subagent depth 1** | Simple, debuggeable | Menos expresividad | 99% casos no necesitan depth >1 |

### Principios de Diseño

1. **Agent-first architecture** — Todo debe ser legible y editable por Lola
2. **Fail safe, not safe from failure** — Diseñar para recovery, no para prevenir todos los fallos
3. **Evidence before assertions** — Verificar antes de declarar "completado"
4. **Conserve memory first** — Memoria es identidad, protegerla es crítico
5. **One source of truth** — Cada pieza de conocimiento tiene exactamente un canonical home
6. **Delegation over blocking** — Spawns subagent en vez de bloquear main session
7. **Quiet by default** — Crons logean silenciosamente, solo alertan si crítico

---

## 9. Out of Scope (v1.0)

Explícitamente NO incluido en esta versión:

❌ **Mobile app nativa** — Telegram/Discord suficiente por ahora  
❌ **Multi-user support** — Diseñado para Manu exclusivamente  
❌ **Real-time collaboration** — Asíncrono por diseño  
❌ **Voice input (STT)** — Solo TTS output, no input voz  
❌ **Fine-tuning custom models** — Volumen insuficiente para justificar  
❌ **Blockchain/crypto integrations** — No requerido  
❌ **Social media posting** — Requiere approval manual siempre  
❌ **Email composition auto-send** — Siempre draft para review  

---

## 10. Aprobaciones

| Rol | Nombre | Fecha | Firma |
|-----|--------|-------|-------|
| **Product Owner** | Manuel León | 2026-03-24 | _Pending_ |
| **Technical Lead** | Lola (lolaopenclaw@gmail.com) | 2026-03-24 | ✅ |
| **Stakeholder** | Manuel León | 2026-03-24 | _Pending_ |

---

## 11. Referencias

- [OpenClaw Documentation](https://docs.openclaw.com)
- [Anthropic Claude API](https://docs.anthropic.com)
- [Google Gemini API](https://ai.google.dev)
- [SOUL.md](./SOUL.md) — Personalidad y principios
- [AGENTS.md](./AGENTS.md) — Reglas de sesión
- [USER.md](./USER.md) — Perfil de Manu
- [MEMORY.md](./MEMORY.md) — Índice de memoria
- [memory/decisions.md](./memory/decisions.md) — Decisiones técnicas
- [memory/advanced-harness-research.md](./memory/advanced-harness-research.md) — Investigación arneses

---

**Próxima revisión:** Q2 2026 (abril-junio)  
**Changelog:** [Ver memory/prd-changelog.md]

---

_Este PRD es un documento vivo. Evoluciona con el producto._
