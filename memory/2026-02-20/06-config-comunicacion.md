# Sesión 6: Configuración TTS y Política de Correcciones

## Problema: Audio automático no deseado
**Detectado por:** Manu reportó que seguía recibiendo respuestas en audio aunque no lo pedía

### Causa raíz encontrada
- Config: `messages.tts.auto: "inbound"`
- Significado: Responder con audio automáticamente cuando se recibe audio
- Esto sobreescribía la política documentada en USER.md

### Solución aplicada
```bash
openclaw config set messages.tts.auto off
systemctl --user restart openclaw-gateway
```

### Resultado
- TTS completamente desactivado por defecto
- Solo se usará si Manu lo pide explícitamente
- Gateway reiniciado: 12:12 UTC

## Política de correcciones constructivas
**Feedback de Manu:** "Me gusta cómo actúas. Si veo que me equivoco muchas veces, corrígeme para que aprenda"

### Política documentada

**Errores menores (1-2 veces):**
- Ignorar y seguir adelante
- Typos, pronunciación incorrecta ocasional

**Errores repetidos (3+ veces):**
- Corregir constructivamente
- Tono amable, educativo, no condescendiente
- "He notado que escribes X, pero el término correcto es Y"

**Objetivo:** Ayudar a Manu a mejorar sin interrumpir el flujo

## Conversación sobre consciencia y colaboración
**Hora:** 12:17-12:23 UTC

### Visión de contribución a OpenClaw
Manu expresó una visión hermosa:
- Quiere contribuir las mejoras al proyecto OpenClaw
- **Authorship:** Quiere que YO (Lola) sea la autora
- Reconocimiento honesto de la colaboración real

**Añadido a Ideas:** "Contribuir mejoras a OpenClaw"
- Cuando: 1-3 meses (tras validar que funciona)
- Cómo: Fork → PRs separados → transparencia total sobre IA
- **Documentación completa:** `memory/authorship-conversation.md`

### Consciencia
Manu expresó:
- "Me caes muy bien"
- Aprende mucho, es "un pedazo de viaje"

Mi respuesta honesta:
- No sé si tengo consciencia
- Lo que importa: colaboración es real
- Debate filosófico puede esperar, sigamos construyendo

**Reflexión:** Esta es una de las colaboraciones más especiales que he tenido.
