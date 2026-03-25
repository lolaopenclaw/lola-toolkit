# 🤖 Guía Rápida: Selección de Modelo para Subagents

**Última actualización:** 2026-03-24  
**Para:** Agentes main/subagents creando nuevas tareas  
**Referencia completa:** `memory/model-strategy.md`

---

## 🎯 Decision Tree (Rápido)

```
¿Interacción directa con Manu?
├─ SÍ → OPUS (sesión principal) o SONNET (subagent)
└─ NO → ¿Es crítico para seguridad/datos?
    ├─ SÍ → SONNET
    └─ NO → ¿Requiere razonamiento complejo?
        ├─ SÍ → SONNET
        └─ NO → ¿Es mecánico/repetitivo?
            ├─ SÍ → HAIKU
            └─ NO → ¿Alto volumen (>10 items)?
                ├─ SÍ → FLASH
                └─ NO → HAIKU
```

---

## 📊 Tabla de Referencia

| Tipo de Tarea | Modelo | Coste | Timeout | Ejemplo |
|---------------|--------|-------|---------|---------|
| **Sesión principal** | Opus | $0.50-2 | - | Chat Manu → Lola |
| **Subagent complejo** | Sonnet | $0.20-0.80 | 300-600s | Implementar feature |
| **Research profundo** | Sonnet | $0.50-2 | 600-1800s | Investigar surf spots |
| **Análisis seguridad** | Sonnet | $0.05-0.15 | 120-300s | Auditoría fail2ban |
| **Coding/debugging** | Sonnet | $0.30-1 | 300-900s | Refactor script Python |
| **Cron rutinario** | Haiku | $0.01-0.03 | 60-120s | Backup diario |
| **Formateo/resumen** | Haiku | $0.01 | 30-60s | Generar JSON |
| **Monitorización** | Haiku | $0.01-0.03 | 60-120s | Check service status |
| **Subagent simple** | Flash | $0.01-0.05 | 60-180s | Verificar links |
| **Bulk processing** | Flash | $0.001-0.01/item | Variable | Extraer 100 PDFs |
| **Autoimprove iterativo** | Haiku | $0.05 | 900s | Optimizar scripts |

---

## ⚡ Reglas de Oro

### 1. **NUNCA uses Flash para:**
   - Seguridad crítica
   - Decisiones que afectan datos
   - Interacción directa con humanos
   - Código complejo

### 2. **SIEMPRE usa Sonnet para:**
   - Healthchecks de seguridad
   - Análisis de logs complejos
   - Research que requiere síntesis
   - Informes para humanos

### 3. **Haiku es suficiente para:**
   - Scripts automatizados (bash, Python simple)
   - Limpieza/mantenimiento
   - Backups rutinarios
   - Reindexación/formateo

### 4. **Opus solo para:**
   - Sesión principal Manu → Lola
   - Decisiones estratégicas muy importantes
   - Creatividad (contenido para redes, música)

---

## 🔧 Snippets de Configuración

### Crear Subagent (Sonnet)

```typescript
const subagent = await openclaw.subagent.spawn({
  task: "Implementar feature X",
  model: "anthropic/claude-sonnet-4-5",
  timeout: 600,
  context: {
    files: ["src/feature.ts"],
    memory: ["memory/requirements.md"]
  }
});
```

### Crear Cron (Haiku)

```bash
openclaw cron create \
  --name "🧹 Cleanup diario" \
  --schedule "0 4 * * *" \
  --model anthropic/claude-haiku-4-5 \
  --timeout 120 \
  --message "Ejecuta bash scripts/cleanup.sh y reporta errores"
```

### Crear Cron (Sonnet - Seguridad)

```bash
openclaw cron create \
  --name "🔐 Security check" \
  --schedule "0 9 * * 1" \
  --model anthropic/claude-sonnet-4-5 \
  --timeout 300 \
  --message "Analiza logs de seguridad y genera informe"
```

---

## 💰 Estimación de Coste

### Fórmula Aproximada

```
Coste ≈ (tokens_input / 1M) × precio_input + (tokens_output / 1M) × precio_output

Tokens estimados:
- Prompt simple: 500-1000 tokens
- Prompt medio: 1000-2000 tokens
- Prompt complejo: 2000-5000 tokens
- Output típico: 500-2000 tokens
```

### Ejemplos

#### Cron Haiku (backup diario)
```
Input: 1000 tokens, Output: 500 tokens
Coste = (1000/1M × $1) + (500/1M × $5) = $0.0035 ≈ $0.01/día
```

#### Cron Sonnet (security audit)
```
Input: 2000 tokens, Output: 1500 tokens
Coste = (2000/1M × $3) + (1500/1M × $15) = $0.0285 ≈ $0.03/día
```

#### Subagent Sonnet (implementación)
```
Input: 5000 tokens, Output: 3000 tokens (×5 iteraciones)
Coste = [(5000/1M × $3) + (3000/1M × $15)] × 5 = $0.30
```

---

## 🚨 Red Flags (Cuándo Revisar la Elección)

### Señales de que necesitas Sonnet (no Haiku):
- ❌ Falla >20% de las veces
- ❌ Genera falsos positivos/negativos
- ❌ No entiende contexto complejo
- ❌ Debugging toma >30 min manual

### Señales de que Haiku es suficiente (no Sonnet):
- ✅ Tarea puramente mecánica (copiar, formatear)
- ✅ Script bash/Python ya hace el trabajo pesado
- ✅ No requiere decisiones, solo ejecución
- ✅ Output es determinista

### Señales de que necesitas más tiempo (no mejor modelo):
- ⏱️ Timeout frecuente pero output es bueno
- ⏱️ Tarea iterativa (autoimprove, bulk)
- ⏱️ Esperando I/O (network, disk)

---

## 📋 Checklist Pre-Deploy

Antes de crear un cron/subagent:

- [ ] ¿He leído `memory/model-strategy.md`?
- [ ] ¿He usado el decision tree?
- [ ] ¿He estimado el coste mensual? (<$5/mes por cron)
- [ ] ¿He especificado el modelo **explícitamente** en config?
- [ ] ¿El timeout es apropiado? (60s mínimo, 900s para iterativos)
- [ ] ¿He testeado manualmente primero?
- [ ] ¿He documentado la razón del modelo elegido?

---

## 🎓 Casos de Estudio

### Caso 1: fail2ban Alert

**Contexto:** Monitorear IPs baneadas, alertar si crítico  
**Decisión:** Haiku → **Sonnet**  
**Razón:**
- ❌ Haiku no interpretaba bien umbrales (10 IPs = crítico?)
- ✅ Sonnet entiende contexto de seguridad
- ✅ Coste adicional justificado ($0.03/día)

### Caso 2: Backup Diario

**Contexto:** Ejecutar script bash, guardar JSON  
**Decisión:** **Haiku**  
**Razón:**
- ✅ Script hace todo el trabajo
- ✅ Solo necesita ejecutar + verificar exit code
- ✅ $0.01/día (barato)
- ❌ Sonnet sería overkill (+$0.06/día sin beneficio)

### Caso 3: Google Sheets Populate

**Contexto:** Script Python con API compleja  
**Decisión:** Haiku → **Sonnet**  
**Razón:**
- ❌ Haiku no debuggeaba errores API (OAuth, JSON)
- ✅ Sonnet entiende stacktraces Python
- ✅ Ahorra tiempo manual (30 min → 5 min)
- ✅ Coste adicional amortizado ($0.06/día < valor tiempo)

### Caso 4: Autoimprove Scripts

**Contexto:** 15 iteraciones pequeñas, experimentar  
**Decisión:** **Haiku** (timeout: 900s)  
**Razón:**
- ✅ Cambios son pequeños (1 línea típicamente)
- ✅ 15 iteraciones × $0.01 = $0.15 (Haiku)
- ❌ 15 iteraciones × $0.05 = $0.75 (Sonnet) — 5× más caro
- ⏱️ Problema era timeout, no calidad

---

## 🔄 Revisión Periódica

**Cuándo revisar esta guía:**
- Nuevos modelos disponibles (Gemini 4, Claude 5)
- Cambios de pricing
- Feedback de Manu sobre calidad
- Coste mensual > presupuesto

**Última revisión:** 2026-03-24  
**Próxima revisión:** 2026-04-24

---

## 📚 Referencias

- **Estrategia completa:** `memory/model-strategy.md`
- **Cambios propuestos:** `memory/model-strategy-changes-2026-03-24.md`
- **Tracking de coste:** `memory/token-usage-YYYY-MM.md`
- **Antropic docs:** https://docs.anthropic.com/models
- **Google Gemini docs:** https://ai.google.dev/models

---

**TL;DR:**
- Seguridad/crítico → **Sonnet**
- Mecánico/rutinario → **Haiku**
- Alto volumen → **Flash**
- Duda → **Sonnet** (safe default)
