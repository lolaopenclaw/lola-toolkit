# 📱 Comandos Telegram — OpenClaw 2026.3.13

**Actualizado:** 2026-03-14

---

## 🔧 Session Management

| Comando | Función |
|---------|---------|
| `/new` | Crear una sesión nueva |
| `/reset` | Resetear la conversación actual (borrar historial) |
| `/compact [instructions]` | Compactar el historial con instrucciones personalizadas |
| `/stop` | Detener la sesión actual |

---

## ⚙️ Options & Configuration

| Comando | Función |
|---------|---------|
| `/think <level>` | Activar reasoning (nivel: low/medium/high) |
| `/model <id>` | Cambiar modelo (haiku, sonnet, opus, etc.) |
| `/fast on/off` | Modo rápido (optimiza velocidad) |
| `/verbose on/off` | Modo verbose (salida detallada) |

---

## 📊 Status & Context

| Comando | Función |
|---------|---------|
| `/status` | Ver estado de la sesión (modelo, tokens, cache, etc.) |
| `/whoami` | Info sobre ti (usuario, configuración) |
| `/context` | Ver contexto cargado (MEMORY.md, archivos, etc.) |
| `/commands` | Listar todos los comandos disponibles (11 páginas) |

---

## 🧠 Skills (Herramientas Especializadas)

**Ejecutar:** `/skill <nombre> [input]`

| Skill | Función |
|-------|---------|
| `/1password` | Gestionar secretos con 1Password CLI |
| `/blogwatcher` | Monitorear blogs y feeds RSS/Atom |
| `/blucli` | Control BluOS (altavoces Bluesound) |
| `/camsnap` | Capturar frames de cámaras RTSP/ONVIF |
| `/clawhub` | Buscar, instalar, actualizar skills |
| `/coding_agent` | Delegar tareas de código a Codex/Claude Code |
| `/eightctl` | Control Eight Sleep (temperatura de cama) |
| `/gemini` | Gemini CLI (Q&A, generación, resúmenes) |
| `/gh_issues` | Gestionar issues de GitHub, spawn PRs |
| `/gifgrep` | Buscar y descargar GIFs |
| `/github` | GitHub CLI (issues, PRs, CI, code review) |
| `/gog` | Google Workspace (Gmail, Calendar, Drive, Docs, Sheets) |
| `/healthcheck` | Auditoría de seguridad y hardening |
| `/himalaya` | Gestionar emails via IMAP/SMTP |
| `/mcporter` | MCP servers/tools (HTTP o stdio) |
| `/nano_banana_pro` | Generar/editar imágenes con Gemini 3 Pro |
| `/nano_pdf` | Editar PDFs con instrucciones en lenguaje natural |
| `/notion` | API de Notion (páginas, bases de datos, bloques) |
| `/obsidian` | Trabajar con bóvedas Obsidian |
| `/openai_whisper` | Speech-to-text local (Whisper) |
| `/openhue` | Control Philips Hue (luces y escenas) |
| `/oracle` | Oracle CLI (prompt bundling, engines, sessions) |
| `/ordercli` | Foodora (historial de pedidos, estado) |
| `/sag` | ElevenLabs text-to-speech con UX style `say` |
| `/session_logs` | Buscar y analizar logs de sesiones antiguas |
| `/skill_creator` | Crear, mejorar, auditar skills |
| `/songsee` | Generar espectrogramas de audio |
| `/sonoscli` | Control Sonos (descubre, estatus, volumen, grouping) |
| `/spotify_player` | Reproducción en Spotify via terminal |
| `/tmux` | Control remoto de sesiones tmux |
| `/video_frames` | Extraer frames/clips de videos (ffmpeg) |
| `/wacli` | Enviar mensajes WhatsApp, sincronizar historial |
| `/weather` | Clima actual y pronósticos (wttr.in / Open-Meteo) |

---

## 🔬 Advanced Tools & Automation

| Comando | Función |
|---------|---------|
| `/autoimprove` | Iteración nightly auto-mejora (skills, scripts, memory) |
| `/clawdbot_self_security_audit` | Auditoría de seguridad de Clawdbot |
| `/openclaw_checkpoint` | Backup/restore estado de OpenClaw entre máquinas |
| `/pr_review` | Auto-review de PRs con IA |
| `/proactive_agent` | Patrón de agentes proactivos (WAL, Working Buffer, Crons) |
| `/truthcheck` | Fact-check y verificación de fuentes |
| `/verification_before_completion` | Protocolo de verificación pre-commit |

---

## 🔌 Docks (Integraciones de Canales)

| Comando | Función |
|---------|---------|
| `/dock_telegram` | Integración Telegram |
| `/dock_discord` | Integración Discord |
| `/dock_slack` | Integración Slack |

---

## 🔌 Plugins (Extensiones de Alto Riesgo)

| Comando | Función |
|---------|---------|
| `/pair` | Sincronización peer-to-peer (pairing) |
| `/phone` | Control de teléfono (cámara, pantalla, escritura) |
| `/voice` | ElevenLabs voice (configurar voz de iOS Talk Playback) |

---

## 📚 Management & Control

| Comando | Función |
|---------|---------|
| `/acp` | ACP harness (Codex/Claude Code en persistente) |
| `/focus <agent>` | Enfocar un agente específico |
| `/agents` | Listar agents activos |
| `/kill <agent>` | Terminar un agent |
| `/restart <service>` | Reiniciar servicio |

---

## 📻 Media & Communication

| Comando | Función |
|---------|---------|
| `/tts <text>` | Text-to-speech (Google TTS + 1.25x speed) |

---

## 💡 Notas

- **Niveles de reasoning:** `low` (rápido), `medium` (balanceado), `high` (profundo)
- **Modelos:** `haiku` (rápido/barato), `sonnet` (balanceado), `opus` (potente)
- **Skills:** Muchas requieren configuración previa (API keys, auth, etc.)
- **Plugins:** Alto riesgo — requieren permisos explícitos
- **Docks:** Para integrar con otros servicios (Discord, Slack, etc.)

---

**Total:** 80+ comandos disponibles
**Última actualización:** 2026-03-14 11:31 Madrid
