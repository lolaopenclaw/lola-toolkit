# Entity Registry — Knowledge Graph (Manual)
**Last Updated:** 2026-03-03
**Purpose:** Track named entities, relationships, and context (inspired by Signet's entity graph)

---

## 👤 PERSONAS

### Manu (Manuel León Mendiola)
- **Role:** Mi humano, usuario principal
- **Email:** manuelleonmendiola@gmail.com
- **Telegram:** @RagnarBlackmade (ID: 6884477)
- **GitHub:** RagnarBlackmade, mleonmendiola-ionos
- **Ubicación:** Logroño, La Rioja, España
- **Timezone:** Europe/Madrid
- **Dispositivos:** OnePlus 13 (móvil), Portátil trabajo (SSH)
- **Música:** Bass in a Voice (bajo, voz, percusión)
- **Salud:** Garmin Instinct 2S Solar Surf
- **Relaciones:** Vera Pérez León (sobrina, 10 años, cumple 30 agosto)

### Lola (Yo)
- **Role:** AI Assistant
- **Email:** lolaopenclaw@gmail.com
- **Plataformas:** Telegram (@LolaTelegramBot), Discord (Lola_bot)
- **VPS:** Ubuntu 24.04, OpenClaw 2026.3.2
- **GitHub:** lolaopenclaw

---

## 🏗️ PROYECTOS

### OpenClaw Setup & Maintenance
- **Estado:** Activo (ongoing)
- **Componentes:** Gateway, Telegram, Discord, Browser Relay, Cron
- **Issues abiertos:** #33103 (gateway restart loop)
- **Tareas recurrentes:** Backup diario, informe matutino, auditoría semanal

### Bass in a Voice
- **Estado:** Activo
- **YouTube:** https://www.youtube.com/@bassinavoice
- **Formato:** Arreglos y covers en trío

### Control de Gastos
- **Estado:** En progreso
- **Archivo:** memory/2026-03-02-sistema-completo-flujos-dinero.md
- **Herramientas:** Google Sheets via GOG

---

## 🔧 HERRAMIENTAS & SERVICIOS

### Infraestructura
| Herramienta | Uso | Estado |
|-------------|-----|--------|
| OpenClaw | Gateway principal | ✅ Activo |
| Tailscale | VPN/Serve | ✅ Activo |
| GOG | Gmail/Drive/Calendar/Sheets | ✅ Autenticado |
| rclone | Backup a Drive | ✅ Configurado |
| pass (GPG) | Secret store | ✅ Configurado |
| Fail2Ban | SSH protection | ✅ Activo |
| Ubuntu Pro | ESM/Livepatch | ✅ Registrado |

### APIs & Tokens
| Servicio | Almacenamiento |
|----------|---------------|
| Anthropic | openclaw.json |
| Telegram Bot | openclaw.json |
| Discord Bot | pass + openclaw.json |
| ElevenLabs | pass + openclaw.json |
| Groq | pass |
| Garmin | pass |

---

## 📋 CONCEPTOS CLAVE

### Protocolos establecidos
- **Backup:** Diario 4 AM → Drive via rclone
- **Security:** Protocolo A+B para cambios críticos
- **Comunicación:** Zero-notification-if-OK, horario silencioso 00:00-07:00
- **Correcciones:** Solo después de 3+ repeticiones del mismo error
- **Verificación:** Evidence before assertions (skill: verification-before-completion)
- **Model Selection:** 80-85% Haiku, upgrade con justificación

---

*Este archivo se actualiza manualmente y en revisiones semanales de memoria.*
