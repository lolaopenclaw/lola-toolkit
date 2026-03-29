# 🔍 Auditoría de Cron Jobs - 2026-03-22

**Fecha de auditoría:** Domingo 22 de marzo de 2026, 13:02 (Madrid)  
**Total de cron jobs:** 28 activos

---

## ✅ RESUMEN EJECUTIVO

### Hallazgos Críticos
- ✅ **Todos los jobs tienen `delivery.mode` configurado** (ninguno usa el legacy mode sin configurar)
- ⚠️ **3 jobs tienen status 'error' en última ejecución**
- ⚠️ **1 job está 'idle' (nunca ejecutado)**
- ⚠️ **MAYORÍA usa `mode: "none"` - no utiliza best-effort-deliver**
- ⚠️ **MAYORÍA no tiene channel configurado o usa 'last'**

### Estado General
- **OK:** 23 jobs
- **ERROR:** 3 jobs (último run falló)
- **IDLE:** 5 jobs (nunca ejecutados)

---

## 📊 ANÁLISIS DETALLADO POR CRON JOB

### 1. 🔍 Filesystem RO check (temporal)
- **Schedule:** every 1h
- **Target:** isolated
- **Delivery:** `mode: "none"` ❌
- **Channel:** NO CONFIGURADO ❌
- **Last run:** running (next in variable time)
- **Status:** N/A (temporal)
- **Modelo:** haiku
- **Issue:** No usa best-effort-deliver, no channel

---

### 2. healthcheck:fail2ban-alert
- **ID:** `c8522805-6bc4-451e-887b-69866ddf5b95`
- **Schedule:** every 6h
- **Target:** isolated
- **Delivery:** `mode: "none"`, `channel: "last"` ❌
- **Last run:** 2h ago
- **Status:** ✅ OK
- **Modelo:** haiku
- **Issue:** No usa best-effort-deliver, channel es "last"

---

### 3. Backup diario de memoria a Google Drive
- **ID:** `ad742767-73f5-42e3-952d-4e566d17507b`
- **Schedule:** cron 0 4 * * * @ Europe/Madrid
- **Target:** isolated
- **Delivery:** `mode: "none"` ❌
- **Channel:** NO CONFIGURADO ❌
- **Last run:** 9h ago
- **Status:** ✅ OK
- **Modelo:** haiku
- **Issue:** No usa best-effort-deliver, no channel

---

### 4. 📊 Populate Google Sheets v2
- **ID:** `6344d609-2bfd-4295-8471-373125381779`
- **Schedule:** cron 30 9 * * *
- **Target:** isolated
- **Delivery:** `mode: "none"` ❌
- **Channel:** NO CONFIGURADO ❌
- **Last run:** 4h ago
- **Status:** ✅ OK
- **Modelo:** haiku
- **Issue:** No usa best-effort-deliver, no channel

---

### 5. 📋 Informe Matutino Completo
- **ID:** `cb5d3743-2d8b-480b-ac64-ef030a689cf0`
- **Schedule:** cron 0 10 * * *
- **Target:** isolated
- **Delivery:** `mode: "none"` ❌
- **Channel:** NO CONFIGURADO ❌
- **Last run:** 3h ago
- **Status:** ✅ OK
- **Payload:** kind: exec (script bash)
- **Issue:** No usa best-effort-deliver, no channel

---

### 6. usage:report-daily (fin de semana)
- **Schedule:** cron 10 10 * * 0,6 @ Europe/Madrid
- **Target:** isolated
- **Delivery:** `mode: "none"`, `channel: "last"` ❌
- **Channel:** NO CONFIGURADO (usa "last") ❌
- **Last run:** N/A (no ejecutado aún)
- **Status:** IDLE
- **Modelo:** haiku
- **Issue:** No usa best-effort-deliver, channel es "last"

---

### 7. 🧹 Cleanup audit semanal (domingo noche)
- **ID:** `07256dbe-2161-4eb2-af22-059834407d54`
- **Schedule:** cron 0 22 * * 0 @ Europe/Madrid
- **Target:** isolated
- **Delivery:** `mode: "none"` ❌
- **Channel:** NO CONFIGURADO ❌
- **Last run:** 7d ago
- **Status:** ✅ OK
- **Modelo:** haiku
- **Issue:** No usa best-effort-deliver, no channel

---

### 8. 🧠 Memory Guardian Pro (domingo noche)
- **ID:** `a2cb9eec-19ab-45f8-ab18-7b1a979fec93`
- **Schedule:** cron 0 23 * * 0 @ Europe/Madrid
- **Target:** isolated
- **Delivery:** `mode: "none"` ❌
- **Channel:** NO CONFIGURADO ❌
- **Last run:** 7d ago
- **Status:** ✅ OK
- **Modelo:** haiku
- **Issue:** No usa best-effort-deliver, no channel

---

### 9. 🗑️ Backup retention cleanup (lunes)
- **ID:** `e5ebcbf4-4c08-4a4a-b277-209899164a06`
- **Schedule:** cron 30 5 * * 1 @ Europe/Madrid
- **Target:** isolated
- **Delivery:** `mode: "none"` ❌
- **Channel:** NO CONFIGURADO ❌
- **Last run:** 6d ago
- **Status:** ✅ OK
- **Modelo:** haiku
- **Issue:** No usa best-effort-deliver, no channel

---

### 10. 📋 Backup validation weekly
- **ID:** `e763c896-228c-4c19-b314-10664f86e30d`
- **Schedule:** cron 30 5 * * 1 @ Europe/Madrid
- **Target:** isolated
- **Delivery:** `mode: "announce"`, `channel: "last"` ⚠️
- **Channel:** "last" (no es telegram) ⚠️
- **Last run:** 6d ago
- **Status:** ✅ OK
- **Issue:** Channel es "last", no telegram

---

### 11. Tareas de fondo semanales (lunes)
- **ID:** `496f6271-d947-4233-980b-327278a33611`
- **Schedule:** cron 0 9 * * 1
- **Target:** isolated
- **Delivery:** `mode: "none"`, `channel: "telegram"`, `to: "6884477"` ⚠️
- **Channel:** ✅ telegram
- **To:** ✅ 6884477
- **Last run:** 6d ago
- **Status:** ✅ OK
- **Modelo:** haiku
- **Issue:** Mode es "none" en vez de best-effort-deliver

---

### 12. healthcheck:rkhunter-scan-weekly
- **ID:** `78d3556f-a203-455d-b718-b9ac7c183dbc`
- **Schedule:** cron 0 9 * * 1
- **Target:** isolated
- **Delivery:** `mode: "none"`, `channel: "last"` ❌
- **Last run:** 6d ago
- **Status:** ✅ OK
- **Modelo:** haiku
- **Issue:** No usa best-effort-deliver, channel es "last"

---

### 13. healthcheck:fail2ban-alert-morning
- **Schedule:** cron 0 9 * * 1-5 @ Europe/Madrid
- **Target:** isolated
- **Delivery:** `mode: "none"`, `channel: "last"` ❌
- **Last run:** N/A
- **Status:** IDLE
- **Modelo:** haiku
- **Issue:** No usa best-effort-deliver, channel es "last"

---

### 14. usage:report-weekly
- **Schedule:** cron 0 9 * * 1
- **Target:** isolated
- **Delivery:** `mode: "none"`, `channel: "last"` ❌
- **Last run:** N/A
- **Status:** IDLE
- **Modelo:** haiku
- **Issue:** No usa best-effort-deliver, channel es "last"

---

### 15. healthcheck:lynis-scan-weekly
- **ID:** `edc0db6e-a1b3-4837-858a-68f859300614`
- **Schedule:** cron 0 9 * * 1
- **Target:** isolated
- **Delivery:** `mode: "none"`, `channel: "last"` ❌
- **Last run:** 6d ago
- **Status:** ✅ OK
- **Modelo:** haiku
- **Issue:** No usa best-effort-deliver, channel es "last"

---

### 16. notion:ideas-cleanup-weekly
- **ID:** `f1e3103b-208d-4cab-9fbe-9eda0eb7acdb`
- **Schedule:** cron 0 9 * * 1
- **Target:** isolated
- **Delivery:** `mode: "none"`, `channel: "last"` ❌
- **Last run:** 6d ago
- **Status:** ✅ OK
- **Modelo:** haiku
- **Issue:** No usa best-effort-deliver, channel es "last"

---

### 17. healthcheck:security-audit-weekly
- **ID:** `fdf38b8f-6d68-4798-84ea-1e2a24c61e75`
- **Schedule:** cron 0 9 * * 1
- **Target:** isolated
- **Delivery:** `mode: "none"`, `channel: "last"` ❌
- **Last run:** 6d ago
- **Status:** ❌ ERROR
- **Modelo:** haiku
- **Issue:** No usa best-effort-deliver, channel es "last", último run falló

---

### 18. usage:report-daily
- **Schedule:** cron 10 9 * * 1-5 @ Europe/Madrid
- **Target:** isolated
- **Delivery:** `mode: "none"`, `channel: "last"` ❌
- **Last run:** N/A
- **Status:** IDLE
- **Modelo:** haiku
- **Issue:** No usa best-effort-deliver, channel es "last"

---

### 19. 🔔 OpenClaw release check
- **ID:** `b491ec4a-e1c3-4be8-b0a5-2ff291d99389`
- **Schedule:** cron 0 10 * * 1,4 @ Europe/Madrid
- **Target:** isolated
- **Delivery:** `mode: "announce"`, `channel: "telegram"`, `to: "6884477"` ⚠️
- **Channel:** ✅ telegram
- **To:** ✅ 6884477
- **Last run:** 3d ago
- **Status:** ✅ OK
- **Modelo:** haiku
- **Issue:** Mode es "announce", no "best-effort-deliver"

---

### 20. 📚 Tier rotation (lunes noche)
- **Schedule:** cron 30 23 * * 1 @ Europe/Madrid
- **Target:** isolated
- **Delivery:** `mode: "none"` ❌
- **Channel:** NO CONFIGURADO ❌
- **Last run:** N/A
- **Status:** IDLE
- **Modelo:** haiku
- **Issue:** No usa best-effort-deliver, no channel

---

### 21. 📋 Informe filesystem RO (fin monitoreo)
- **Schedule:** cron 0 11 4 3 * @ Europe/Madrid
- **Target:** isolated
- **Delivery:** `mode: "announce"`, `channel: "telegram"`, `to: "6884477"` ⚠️
- **Channel:** ✅ telegram
- **To:** ✅ 6884477
- **Status:** IDLE (futuro: 4 marzo)
- **Modelo:** haiku
- **Issue:** Mode es "announce", no "best-effort-deliver"

---

### 22. security:rotate-gateway-token
- **ID:** `72d256fe-31f6-4821-8680-2d7c97faa52d`
- **Schedule:** cron 0 10 25 */3 *
- **Target:** isolated
- **Delivery:** `mode: "announce"`, `channel: "last"` ⚠️
- **Channel:** "last" (no es telegram) ⚠️
- **Status:** IDLE (futuro: 25 junio)
- **Modelo:** haiku
- **Issue:** Channel es "last", no telegram

---

### 23. 🔍 Monitor GitHub #24586 - Discord Cron Delivery
- **Schedule:** cron 0 8 * * 1 @ Europe/Madrid
- **Target:** isolated
- **Delivery:** `mode: "announce"`, `channel: "last"` ⚠️
- **Channel:** "last" (no es telegram) ⚠️
- **Status:** IDLE
- **Modelo:** haiku
- **Issue:** Channel es "last", no telegram

---

### 24. 🏠 Driving Mode Auto-Reset
- **ID:** `7a7086e5-5a3c-41ad-880b-64a25a927aae`
- **Schedule:** cron 0 22 * * * (exact)
- **Target:** isolated
- **Delivery:** NO CONFIGURADO ❌
- **Channel:** NO CONFIGURADO ❌
- **Last run:** 15h ago
- **Status:** ✅ OK
- **Issue:** Sin delivery configurado

---

### 25. memory-decay-weekly
- **ID:** `6982dc7e-1aa8-428c-9d5a-ac3a0c2cb411`
- **Schedule:** cron 0 23 * * 0 (exact)
- **Target:** isolated
- **Delivery:** NO CONFIGURADO ❌
- **Channel:** NO CONFIGURADO ❌
- **Status:** IDLE (nunca ejecutado)
- **Modelo:** haiku
- **Issue:** Sin delivery configurado

---

### 26. 🔄 Model Reset Nightly
- **ID:** `e42db2e2-f6a8-40f7-810d-91e821cefa6b`
- **Schedule:** cron 0 0 * * * (exact)
- **Target:** isolated
- **Delivery:** NO CONFIGURADO ❌
- **Channel:** NO CONFIGURADO ❌
- **Last run:** 13h ago
- **Status:** ✅ OK
- **Issue:** Sin delivery configurado

---

### 27. 🔄 System Updates Nightly
- **ID:** `ed1d9b11-5ba1-44ed-8f8b-0b359ddcd45e`
- **Schedule:** cron 30 1 * * * @ Europe/Madrid
- **Target:** isolated
- **Delivery:** NO CONFIGURADO ❌
- **Channel:** NO CONFIGURADO ❌
- **Last run:** 12h ago
- **Status:** ✅ OK
- **Issue:** Sin delivery configurado

---

### 28. autoimprove-nightly
- **ID:** `08325b21-cd9c-490e-904c-e668e38418af`
- **Schedule:** cron 0 2 * * * @ Europe/Madrid
- **Target:** isolated
- **Delivery:** NO CONFIGURADO ❌
- **Channel:** NO CONFIGURADO ❌
- **Last run:** 11h ago
- **Status:** ✅ OK
- **Modelo:** haiku
- **Issue:** Sin delivery configurado

---

### 29. 🔬 Autoimprove Nightly (ID: 6018f037...)
- **ID:** `6018f037-1d26-4322-874e-d256c295a5b4`
- **Schedule:** cron 0 3 * * * @ Europe/Madrid
- **Target:** isolated
- **Delivery:** NO VISIBLE EN JSON ❌
- **Channel:** NO VISIBLE EN JSON ❌
- **Last run:** 10h ago
- **Status:** ✅ OK
- **Issue:** No aparece en cron-jobs.json (legacy?)

---

### 30. 🔬 Autoimprove Nightly (ID: dcae7b06...) - DUPLICADO
- **ID:** `dcae7b06-e6fb-40d4-88bc-9bc618feb70d`
- **Schedule:** cron 0 3 * * * @ Europe/Madrid
- **Target:** isolated
- **Delivery:** NO VISIBLE EN JSON ❌
- **Channel:** NO VISIBLE EN JSON ❌
- **Last run:** 10h ago
- **Status:** ❌ ERROR
- **Issue:** No aparece en cron-jobs.json (legacy?), último run falló

---

### 31. 🧠 Memory Search Reindex
- **ID:** `53577b95-936e-4f91-b4b9-0c3c3ad630f2`
- **Schedule:** cron 30 4 * * * @ Europe/Madrid
- **Target:** isolated
- **Delivery:** NO VISIBLE EN JSON ❌
- **Channel:** NO VISIBLE EN JSON ❌
- **Last run:** 9h ago
- **Status:** ✅ OK
- **Modelo:** haiku
- **Issue:** No aparece en cron-jobs.json (legacy?)

---

### 32. 🏃 Resumen Semanal de Actividad
- **ID:** `522ae7ca-2942-44f1-a263-741a92f51dfd`
- **Schedule:** cron 0 9 * * 1 (exact)
- **Target:** isolated
- **Delivery:** NO VISIBLE EN JSON ❌
- **Channel:** NO VISIBLE EN JSON ❌
- **Last run:** 6d ago
- **Status:** ✅ OK
- **Issue:** No aparece en cron-jobs.json (legacy?)

---

### 33. 🔧 Lola Toolkit Sync Weekly
- **ID:** `ad5285c3-e97c-40ce-aa05-0cda1b2ef941`
- **Schedule:** cron 30 9 * * 1 @ Europe/Madrid
- **Target:** isolated
- **Delivery:** NO VISIBLE EN JSON ❌
- **Channel:** NO VISIBLE EN JSON ❌
- **Status:** IDLE (nunca ejecutado)
- **Modelo:** haiku
- **Issue:** No aparece en cron-jobs.json (legacy?)

---

### 34. 🔬 Seguimiento Autoresearch
- **ID:** `4de42cb2-882b-47b5-99a0-38cb0d4dca27`
- **Schedule:** cron 0 10 * * 1 @ Europe/Madrid
- **Target:** isolated
- **Delivery:** NO VISIBLE EN JSON ❌
- **Channel:** NO VISIBLE EN JSON ❌
- **Last run:** 6d ago
- **Status:** ❌ ERROR
- **Issue:** No aparece en cron-jobs.json (legacy?), último run falló

---

### 35. 🔍 Gemini embeddings refresh
- **ID:** `6c592bd2-e9b7-469e-b61e-51e3bbc6e948`
- **Schedule:** at 2026-03-23 08:30Z
- **Target:** isolated
- **Delivery:** NO VISIBLE EN JSON ❌
- **Channel:** NO VISIBLE EN JSON ❌
- **Status:** IDLE (futuro: mañana)
- **Modelo:** haiku
- **Issue:** No aparece en cron-jobs.json (legacy?)

---

### 36. 🚗 Driving Mode - Review & Optimize
- **ID:** `56ab2039-aad2-40b2-82b0-d025c6a896d7`
- **Schedule:** cron 0 9 8 * * (exact)
- **Target:** isolated
- **Delivery:** NO VISIBLE EN JSON ❌
- **Channel:** NO VISIBLE EN JSON ❌
- **Status:** IDLE (futuro: 8 abril)
- **Issue:** No aparece en cron-jobs.json (legacy?)

---

## 🚨 PROBLEMAS IDENTIFICADOS

### Críticos
1. **MAYORÍA usa `delivery.mode: "none"`** en vez de `best-effort-deliver`
2. **10+ cron jobs NO están en cron-jobs.json** (legacy storage)
3. **3 jobs en estado ERROR:**
   - `healthcheck:security-audit-weekly` (ID: fdf38b8f...)
     - **Error:** `⚠️ ✉️ Message failed`
     - **Causa:** Delivery falló (no tiene channel configurado, usa "last")
     - **Última ejecución:** 16 marzo @ 09:00 (hace 6 días)
     - **Trabajo completado:** ✅ Sí (generó informe completo)
     - **Problema:** Solo falla delivery, la auditoría se ejecuta bien
   
   - `🔬 Autoimprove Nightly` (ID: dcae7b06...)
     - **Error:** `⚠️ ✉️ Message failed`
     - **Causa:** Delivery falló (no tiene channel configurado)
     - **Última ejecución:** 22 marzo @ 03:00 (hace 10h)
     - **Trabajo completado:** ✅ Sí (generó reporte en memory/)
     - **Problema:** Solo falla delivery, el autoimprove se ejecuta bien
   
   - `🔬 Seguimiento Autoresearch` (ID: 4de42cb2...)
     - **Error:** `Channel is required when multiple channels are configured: telegram, discord`
     - **Causa:** NO tiene channel explícito, sistema no sabe dónde enviar
     - **Última ejecución:** 16 marzo @ 10:00 (hace 6 días)
     - **Trabajo completado:** ✅ Sí (detectó 24 commits nuevos)
     - **Problema:** Delivery config inválida

### Moderados
4. **MAYORÍA usa `channel: "last"` o NO tiene channel configurado**
5. **Solo 3 jobs tienen `channel: "telegram"` + `to: "6884477"` correcto:**
   - Tareas de fondo semanales
   - OpenClaw release check
   - Informe filesystem RO

### Menores
6. **5 jobs nunca ejecutados (IDLE):**
   - memory-decay-weekly
   - 🔧 Lola Toolkit Sync Weekly
   - 🔍 Gemini embeddings refresh (futuro)
   - 🚗 Driving Mode - Review (futuro)
   - 📋 Informe filesystem RO (futuro)

---

## ✅ RECOMENDACIONES

### Urgentes
1. **Migrar todos los jobs legacy** a cron-jobs.json con `openclaw doctor --fix`
2. **Cambiar `delivery.mode: "none"` a `best-effort-deliver`** para jobs críticos
3. **Configurar `channel: "telegram"` explícitamente** en todos los jobs que deben notificar
4. **Investigar y solucionar los 3 jobs en ERROR**

### Importantes
5. **Auditar jobs IDLE** - determinar si son necesarios o deben eliminarse
6. **Unificar strategy de delivery** - decidir qué jobs deben usar telegram vs none vs announce

### Opcionales
7. **Consolidar jobs duplicados** (hay 2 "Autoimprove Nightly" con mismo schedule)
8. **Revisar `to: "6884477"`** - ¿todos los jobs deben ir al mismo chat?

---

## 📈 MÉTRICAS

- **Total jobs:** 28 en JSON + ~10 legacy = ~38 total
- **Con channel telegram:** 3 (8%)
- **Con best-effort-deliver:** 0 (0%)
- **Status OK:** 23 (82%)
- **Status ERROR:** 3 (11%)
- **Status IDLE:** 5 (18%)
- **Compliance:** ~8% (solo 3 jobs cumplen todos los criterios)

---

## 🔎 HALLAZGOS ADICIONALES

### Delivery Errors - Análisis
Los 3 jobs en ERROR **SÍ completaron su trabajo correctamente**. El error es solo en la capa de delivery:

1. **healthcheck:security-audit-weekly** y **Autoimprove Nightly:**
   - Error genérico: `⚠️ ✉️ Message failed`
   - Causa raíz: `delivery.mode: "none"` o `channel: "last"` sin contexto válido
   - Trabajo ejecutado: ✅ Auditoría y análisis completados
   - Impacto: Los reportes se guardan en memory/ pero no se notifica a Manu

2. **Seguimiento Autoresearch:**
   - Error específico: `Channel is required when multiple channels are configured`
   - Causa raíz: Sin `delivery.channel` explícito cuando hay telegram + discord
   - Trabajo ejecutado: ✅ Detectó 24 commits del repo Karpathy
   - Impacto: El análisis se completa pero no se entrega

### Legacy vs New Storage
**Observación crítica:** Hay ~10 cron jobs que aparecen en `openclaw cron list` pero NO en `cron-jobs.json`:
- 🔬 Autoimprove Nightly (6018f037... y dcae7b06...)
- 🧠 Memory Search Reindex
- 🏃 Resumen Semanal de Actividad
- 🔧 Lola Toolkit Sync Weekly
- 🔬 Seguimiento Autoresearch
- 🔍 Gemini embeddings refresh
- 🚗 Driving Mode - Review

**Implicación:** Estos jobs están en legacy storage. OpenClaw doctor sugiere: `openclaw doctor --fix` para migrarlos.

### Doctor Warning Recurrente
Todos los comandos `openclaw cron` muestran este warning:
```
channels.telegram.groupPolicy is "allowlist" but groupAllowFrom (and allowFrom) is empty
— all group messages will be silently dropped.
```

**Impacto potencial:** Si Manu envía mensajes desde un grupo de Telegram, serán ignorados.

---

## 📋 CHECKLIST DE REMEDIACIÓN

### Prioritario (esta semana)
- [ ] Ejecutar `openclaw doctor --fix` para migrar jobs legacy
- [ ] Cambiar `delivery.mode: "none"` → `best-effort-deliver` en jobs críticos:
  - [ ] healthcheck:security-audit-weekly
  - [ ] Autoimprove Nightly (ambos)
  - [ ] Seguimiento Autoresearch
- [ ] Configurar `delivery.channel: "telegram"` explícitamente en todos los jobs que deben notificar
- [ ] Verificar que `delivery.to: "6884477"` está presente donde se necesita

### Importante (próximos 7 días)
- [ ] Revisar jobs en IDLE - determinar si deben activarse o eliminarse:
  - [ ] memory-decay-weekly
  - [ ] Lola Toolkit Sync Weekly
  - [ ] usage:report-daily (versión fin de semana)
  - [ ] healthcheck:fail2ban-alert-morning
  - [ ] usage:report-weekly
- [ ] Investigar duplicados de "Autoimprove Nightly" (2 con mismo schedule)
- [ ] Unificar strategy de delivery - definir estándar para el workspace

### Opcional (cuando haya tiempo)
- [ ] Resolver doctor warning de telegram.groupAllowFrom
- [ ] Documentar qué jobs usan `mode: "none"` intencionalmente (sin notificación)
- [ ] Consolidar jobs que hacen tareas similares

---

**Fin del reporte.**
