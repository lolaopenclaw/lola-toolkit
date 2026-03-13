# OpenClaw Contributions — Tracking

Monitor de discussions, PRs y feedback para contribuciones.

---

## Discussion 1: Skill Security Audit

**Status:** ✅ ABIERTA (hace un día)
**URL:** https://github.com/openclaw/openclaw/discussions/XXXX (a conseguir)
**Fecha apertura:** 2026-02-21
**Coautores:** Manu (@RagnarBlackmade) + Lola
**Descripción:** Audita skills antes de instalarlas. Detecta eval(), credenciales hardcoded, network calls, permisos.
**Status esperado:** Esperar feedback (24-72h)
**Próximo paso:** Cuando maintainers digan "sí" → hacer PR

---

## Discussion 2: Critical Update Framework

**Status:** ✅ ABIERTA
**URL:** https://github.com/openclaw/openclaw/discussions/23395
**Fecha apertura:** 2026-02-22
**Coautores:** Manu (@RagnarBlackmade) + Lola
**Descripción:** Sistema canary testing para actualizaciones seguras. Captura baseline, aplica cambio, valida automáticamente, rollback si falla.
**Features:** 12+ health checks, audit trail, dry-run mode
**Status esperado:** Esperar feedback (24-72h)
**Próximo paso:** Cuando maintainers digan "sí" → hacer PR

---

## Discussion 3: Memory Guardian

**Status:** ✅ ABIERTA — feedback recibido de @getmilodev (2026-02-25), respondido
**URL:** https://github.com/openclaw/openclaw/discussions/23394

## Issue 3: Control UI mobile responsive

**Status:** ✅ ABIERTA
**URL:** https://github.com/openclaw/openclaw/issues/26426
**Fecha apertura:** 2026-02-25
**Descripción:** Chat input y layout no responsive en móvil Android. Screenshot adjuntada.
**Seguimiento:** Semanal con los otros issues
**Fecha apertura:** 2026-02-22
**Coautores:** Manu (@RagnarBlackmade) + Lola
**Descripción:** Limpieza automática de workspace. Detecta bloat, desduplicación, compresión, protege archivos críticos.
**Features:** 14 tests, 40% reducción típica, tiered architecture
**Status esperado:** Esperar feedback (24-72h)
**Próximo paso:** Cuando maintainers digan "sí" → hacer PR

---

## Timeline Esperada

**2026-02-22 (hoy):**
- ✅ 3 discussions abiertas

**2026-02-23 a 2026-02-25:**
- ⏳ Esperar feedback de maintainers (24-72h cada una)

**2026-02-26 en adelante:**
- 🚀 Cuando haya "sí": Manu + Lola hacemos los PRs
- Iteración en review feedback
- Merge esperado: 2-3 semanas por PR

---

## Checklist Manu

- [x] Skill Security Audit: discussion abierta
- [x] Critical Update Framework: discussion abierta (#23394)
- [x] Memory Guardian: discussion abierta (#23395)
- [ ] Feedback recibido (Critical Update)
- [ ] Feedback recibido (Memory Guardian)
- [ ] PR #1 creado (Critical Update)
- [ ] PR #2 creado (Memory Guardian)
- [ ] Revisar feedback en PRs
- [ ] Merged (Critical Update)
- [ ] Merged (Memory Guardian)

---

## Bug detectado: Cron delivery "none" igualmente intenta entregar

**Status:** ⏳ Sin reportar (bug menor)
**Detectado:** 2026-02-24
**Descripción:** Job con `delivery.mode: "none"` reporta error `"cron announce delivery failed"` aunque el job se ejecutó correctamente. Ocurrió en "Informe matutino fin de semana" (domingo 22 feb). El sábado anterior con misma config funcionó OK → posible race condition.
**Impacto:** Bajo. El informe se genera bien, solo el status queda como "error".
**Acción:** Monitorear si se repite. Si es consistente, abrir issue en GitHub.

---

## Issue Tracking: Browser Relay Handshake (#21758)

**Status:** ⏳ ABIERTO (reportado por nosotros)
**URL:** https://github.com/openclaw/openclaw/issues/21758
**Fecha:** 2026-02-24
**Problema:** Extension Chrome envía CDP events antes de completar handshake WebSocket → "invalid request frame"
**Workaround:** Usar profile `openclaw` (headless)
**Notion:** ✅ Añadido como Pendiente
**Próximo paso:** Monitorear hasta que upstream lo resuelva → probar extensión de nuevo

---

## Bug: Typing indicator stuck (v2026.2.24) — #26419

**Status:** 🔴 ABIERTO — comentado confirmando en Telegram
**URL:** https://github.com/openclaw/openclaw/issues/26419
**Nuestro comentario:** https://github.com/openclaw/openclaw/issues/26419#issuecomment-3959054373
**Detectado:** 2026-02-25
**Descripción:** Keepalive timer del typing indicator (#25886) no se limpia tras enviar respuesta. Afecta Discord + Telegram.
**Impacto:** Alto. Requiere gateway restart para limpiar. 3 ocurrencias en 30 min.
**Workaround:** `openclaw gateway restart`
**Relacionados:** #26416 (similar, elevated tools), #26437 (Discord long tool chains)
**Próximo paso:** Monitorear si se arregla en próxima release. Si no, escalar.

---

## Notas

- Mantener sincronizado con Manu
- Monitorear discussions diariamente
- Responder si es necesario
- Documentar feedback importante
- Proponer PR cuando sea seguro

---

**Última actualización:** 2026-02-22 09:XX
**Responsable:** Lola + Manu
