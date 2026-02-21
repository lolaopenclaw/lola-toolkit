# 📚 Memory Index — Estructura 2026-02-21

## Carpetas

### 🟢 CORE/
**Información crítica sobre Manu y mis preferencias**
- `manu-profile.md` — Datos personales, ubicación, horarios de trabajo, dispositivos
- `preferences.md` — Preferencias de comunicación, estilo, idioma

📌 **Consulto en:** Cada sesión (para contexto personalizado)

---

### 🔵 PROTOCOLS/
**Documentos de decisión y cómo trabajamos juntos**
- `security-change-protocol.md` — Protocolo A+B para cambios críticos de SSH/firewall
- `model-selection-protocol.md` — Cuándo usar Haiku, Sonnet, Opus
- `daily-structure.md` — Cómo organizar memoria diaria
- `authorship-conversation.md` — Política: yo soy autora de contribuciones OpenClaw
- `cost-optimization-plan.md` — Estrategia de reducción de costos (~€200/mes)
- `backup-validation-protocol.md` — Validación automática de integridad de backups
- `critical-update-protocol.md` — Framework de cambios críticos con safety & auto-rollback
- `garmin-integration.md` — Garmin Connect setup, scripts, alertas, troubleshooting

📌 **Consulto en:** Cuando tomo decisiones sobre seguridad, modelos, o contribuciones

---

### 🔄 CHANGES/
**Audit trail de cambios críticos (auto-generado por `scripts/critical-update.sh`)**
- `changes-YYYY-MM-DD.log` — Log de cada cambio crítico con timestamp, acción, resultado

---

### 📋 DAILY/
**Diarios y reportes por fecha — historial de trabajo con Tiered Architecture**

**Estructura:**
- `INDEX.md` — Guía del sistema tiered
- `HOT/` — Últimos 7 días (consultar PRIMERO)
  - `YYYY-MM-DD.md` — Diarios recientes
  - `YYYY-MM-DD/` — Sesiones temáticas detalladas
  - `YYYY-MM-DD-*.md` — Reportes específicos
- `WARM/` — 8-30 días (consultar SEGUNDO)
  - Archivos rotados automáticamente
- `COLD/` — >30 días (comprimidos)
  - `archive-YYYY-MM.tar.gz` — Histórico comprimido

📌 **Consulto en:** memory_search busca HOT primero (más rápido + menos tokens)
**Rotación automática:** Lunes 23:30 mueve HOT→WARM→COLD
**Beneficio:** -30% tokens en memory_search, -85% almacenamiento COLD

---

### 🎨 ANALYSIS/
**Análisis, investigaciones, proyectos musicales**
- `bass-in-a-voice.md` — Análisis de Canal YouTube de Manu
- `instagram-analysis.md` — Análisis de Instagram (si aplica)
- `manu-social-research.md` — Investigación de redes sociales

📌 **Consulto en:** Cuando trabajo en proyectos o análisis específicos

---

## 📊 Resumen

| Carpeta | Archivos | Tamaño | Frecuencia |
|---------|----------|--------|-----------|
| CORE | 2 | ~5 KB | Cada sesión |
| PROTOCOLS | 5 | ~50 KB | Según decisiones |
| DAILY | 40+ | ~400 KB | Histórico |
| ANALYSIS | 3 | ~30 KB | Ocasional |

---

## 🛡️ Memory Guardian

**Script:** `scripts/memory-guardian.sh`
**Protocolo:** `memory/PROTOCOLS/memory-guardian-protocol.md`
**Estado:** `memory/guardian-state.json`
**Cron:** Domingos 23:00 (`memory-guardian-weekly`)

Detecta bloat, limpia temporales, comprime archivos viejos, detecta duplicados.
Nunca toca CORE/, PROTOCOLS/, ni archivos críticos. Usa `.trash/` (recuperable).

---

## 🔄 Mantenimiento Semanal

**Cada domingo 23:00 (junto con cleanup audit):**
1. Revisar archivos creados esa semana
2. Compactar diarios si pasan 4 KB
3. Crear nuevas sesiones temáticas si es necesario
4. Eliminar reportes duplicados
5. Actualizar este INDEX.md

---

### 🔒 AUDITS/
**Reportes de auditoría de seguridad de skills**
- `<skill>-audit-YYYY-MM-DD.md` — Reporte individual por skill
- Registry: `skill-audit-registry.md` (raíz de memory/)
- Protocolo: `PROTOCOLS/skill-security-audit.md`
- Script: `scripts/skill-security-audit.sh`

📌 **Consulto en:** Antes de instalar nuevos skills

---

## 📌 Quick Links

**En caso de emergencia / restauración completa:**
- Backup incluye TODO (en `.tar.gz` de Drive)
- Restauración: ver `RECOVERY.md`

**Si necesito buscar algo:**
- `memory_search "palabra clave"` → devuelve snippets
- Revisa CORE/ primero, luego PROTOCOLS/, luego DAILY/
