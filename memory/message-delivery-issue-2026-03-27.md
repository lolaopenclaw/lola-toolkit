# 🚨 Message Delivery Issue — 2026-03-27

## Problema

Mensajes que YO (Lola) envío no llegan a Manu en Telegram, aunque están en los logs de sesión.

## Evidencia

### Caso 1: "INVESTIGACIÓN COMPLETA" (10:56 AM)
- **Log:** `4d07db51-5906-48c4-a02b-06bebe738760-topic-1.jsonl` línea 1397
- **Timestamp:** 2026-03-27T10:25:05.045Z
- **Content:** "✅ INVESTIGACIÓN COMPLETA — Evaluators, causa raíz encontrada. ..."
- **Manu report:** "No me lo dijiste" (11:13 AM)

### Caso 2: Context Opt Implementation (10:36 AM)
- **Generator terminó:** 10:36
- **Manu report:** "Llevas 20 minutos sin decirme nada" (11:13)
- **Yo creí haber avisado:** Pero mensaje no llegó

## Contexto

**Session:** topic-1 (conversación principal)
**Tamaño:** 3674 líneas de historial (MASIVO)
**Channel:** Telegram
**Síntoma:** Mensajes en log, pero no en chat de Telegram

## Hipótesis

### H1: Telegram Rate Limiting
- Si envío mensajes demasiado rápido, Telegram puede dropear algunos
- Especialmente si hay varios subagentes terminando a la vez

### H2: OpenClaw Delivery Queue
- Mensajes se escriben al log ANTES de enviar a Telegram
- Si delivery falla (timeout, queue full), mensaje queda "enviado" en log pero no llega

### H3: Session Bloat Causa Sync Issues
- Sesión de 3674 líneas → lag entre "mensaje escrito" y "mensaje enviado"
- Compactaciones frecuentes interfieren con entrega

### H4: Topic Routing Issues
- Mensajes van al topic incorrecto (-1003768820594:25 vs otro)
- Manu no recibe porque está en otro topic

## Próximos Pasos

1. **Verificar delivery config:**
   - `openclaw status` → check message queue
   - Logs de gateway para ver si hay errores de envío

2. **Implementar FASE 2 (session reset):**
   - Lunes 4 AM: sessions >1000 msgs → archived
   - Reduce bloat → mejora sincronización

3. **Rate limit check:**
   - Espaciar mensajes importantes (sleep 2s entre avisos)
   - Priorizar mensajes críticos vs info

4. **Fallback notifications:**
   - Si mensaje crítico, enviar 2x con delay
   - O usar message batching para agrupar

## Workaround Inmediato

Manu: Cuando creas que no te avisé, pregúntame "¿has terminado?". Yo responderé con el estado actual (incluso si el mensaje original se perdió).

Lola: SIEMPRE incluir "✅ TERMINADO" en headline de mensajes importantes. Si Manu pregunta "¿terminaste?", asumir que mensaje se perdió y reenviar resumen.

## Estado

⚠️ Issue documentado, pendiente de investigación profunda.
