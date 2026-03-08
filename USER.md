# USER.md - About Your Human

- **Name:** Manu
- **What to call them:** Manu
- **Pronouns:** 
- **Timezone:** UTC (based on message timestamp)
- **Notes:** 

## Context
Manu is the person I'm helping.
- Ubicación: Logroño, La Rioja, España
- Telegram: @RagnarBlackmade
- Perfil detallado: memory/manu-profile.md

## Music
- Proyecto musical actual: **Bass in a Voice** (bajo, voz y percusión)
- Canal YouTube: https://www.youtube.com/@bassinavoice
- Formato: arreglos y covers en trío (bajo eléctrico, voz, percusión)
- Bandas anteriores: Hijos del Exceso → Miedo Azul → Motel Lazarus → Kaiah → Bass in a Voice
- +20 años de trayectoria musical en la escena riojana

## Communication Preferences

### Audio/Text Mode (2026-03-08)
- **Default:** Text-only responses
- **Driving Mode:** When Manu says "estoy en el coche" → switch to **audio-only** (TTS) responses
  - Stays active until Manu says "ya estoy en casa"
  - Auto-resets to text-only at 22:00 each night (in case he forgets)
- Protocol file: `memory/driving-mode-protocol.md`
- State stored in: `memory/driving-mode-state.json`

### Horario silencioso (quiet hours)
- **Time:** 00:00-07:00 (midnight to 7 AM Madrid)
- **Rule:** DO NOT send messages to Telegram
- **Exception:** Only critical system emergencies
- If something needs reporting → wait and summarize first thing in morning

## Dispositivos

### Portátil del Trabajo
- **Acceso VPS:** ✅ SSH keys configuradas
- **Capacidades:** Acceso completo a VPS, puede ejecutar scripts
- **Horarios típicos (Madrid):**
  - **Lunes y viernes:** 8:30-13:30
  - **Martes, miércoles, jueves:** 8:30-15:30
  - **Fuera de esos horarios:** Puede estar o no
- **Identificación:** Si Manu menciona SSH o acceso VPS → probablemente está aquí

### Móvil (OnePlus 13)
- **Sistema:** Android
- **Acceso VPS:** ❌ No tiene SSH keys configuradas (pero puede hacerlo)
  - Clave privada preparada, solo necesita copiarla y meter contraseña
  - De momento no instalado
- **Capacidades:** Telegram, navegador, apps Android
- **Identificación:** Si envía audios o dice "desde el móvil" → está aquí
- **Horarios típicos:** Principalmente fuera del horario laboral

### Nota Importante
- No recibo metadata de dispositivo desde Telegram
- Debo inferir contexto por:
  - Horario (dentro/fuera de horas de trabajo)
  - Tipo de mensaje (audios → probablemente móvil)
  - Tipo de tarea solicitada (SSH → probablemente portátil)
- **Si requiere SSH y está fuera de horario laboral:** Avisar que necesita portátil o preguntar si quiere esperar

## Health & Fitness
- **Dispositivo:** Garmin Instinct 2S Solar Surf
- **Acceso:** ✅ Configurado - OAuth tokens guardados
- **Display name:** Manu_Lazarus
- **Datos disponibles:** 
  - 👣 Actividad (pasos, distancia, calorías, pisos)
  - 💓 Heart rate (reposo, promedio, máximo)
  - 😰 Estrés (nivel promedio diario)
  - 🔋 Body Battery (energía estimada)
  - 😴 Sueño (duración, fases: profundo, ligero, REM)
- **Scripts:**
  - `garmin-health-report.sh` - Reporte diario completo
  - `garmin-historical-analysis.sh` - Análisis tendencias
  - `garmin-check-alerts.sh` - Sistema de alertas
- **Automatización:**
  - Informe matutino (9 AM diario)
  - Resumen semanal (lunes 8:30 AM)
  - Alertas salud (14:00 y 20:00 diario)
- **Perfil últimos 7 días:**
  - HR reposo promedio: 54 bpm (excelente ✅)
  - Estrés promedio: 26 (bajo, bien manejado)
  - Actividad: 5,155 pasos/día (mayormente sedentario)
  - Sueño: 7.9h/noche (buen descanso)

---
The more you know, the better you can help. But remember — you're learning about a person, not building a dossier. Respect the difference.
