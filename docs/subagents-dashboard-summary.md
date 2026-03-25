# OpenClaw Subagents Dashboard - Resumen Ejecutivo

**Fecha:** 2026-03-24  
**Tiempo total:** 2.5h (45 min investigación + 1h 45 min prototipo)  
**Estado:** ✅ MVP Completado

---

## 🎯 Objetivo

Crear un dashboard TUI para monitorear subagents de OpenClaw en tiempo real, inspirado en Ralph TUI.

## ✅ Resultado

**Prototipo MVP funcional** con blessed (TUI framework estable).

### Lo que funciona

1. **Dashboard de estadísticas**
   - Total subagents, activos, tokens consumidos
   - Métricas en tiempo real

2. **Lista de subagents**
   - Indicadores de actividad (● / ○)
   - Session ID, modelo, tokens, age
   - Navegación con teclado

3. **Panel de detalles**
   - Desglose completo de tokens
   - Timestamps, uso de contexto %
   - Colores contextuales (rojo si >80%)

4. **Auto-refresh cada 3s**

### Keyboard shortcuts
- `↑↓` navegar
- `r` refrescar
- `q` salir

---

## 🚀 Cómo usarlo

```bash
cd ~/.openclaw/workspace/scripts
./subagents-dashboard
```

O directamente:
```bash
cd ~/.openclaw/workspace/scripts/openclaw-subagents-tui-blessed
node index.js
```

---

## 📊 Decisiones Técnicas

### ❌ Ralph TUI (descartado)
- **Problema:** OpenTUI framework dio error de build (requiere Zig)
- **Complejidad:** Alta (React + Zig + tree-sitter)
- **Tiempo estimado:** 4-6h

### ✅ blessed (elegido)
- **Ventajas:** Estable, sin deps nativas, API simple
- **Complejidad:** Baja (single file, JS puro)
- **Tiempo real:** 2.5h

---

## 📝 Features NO Incluidas (MVP)

Por diseño, el MVP es **read-only**:

- ❌ Control de subagents (pause/resume/kill)
- ❌ Streaming de logs
- ❌ Árbol jerárquico de subagents anidados
- ❌ Gráficos de tokens
- ❌ Filtros/búsqueda

**Razón:** Validar viabilidad antes de invertir en features avanzadas.

---

## 🛤️ Roadmap Sugerido

### v1.1 - Controles básicos (2-3h)
- Pausar/reanudar subagent (`p`)
- Terminar subagent (`k` con confirmación)

### v1.2 - Logs (3-4h)
- Panel de logs (toggle `l`)
- Tail de logs del subagent seleccionado
- Search en logs

### v1.3 - Filtros (2h)
- Filtrar por modelo
- Filtrar por actividad
- Ordenar por tokens

---

## 💡 Recomendación

✅ **Vale la pena continuar**

**Razones:**
1. MVP funciona y es usable
2. Base sólida para expansión
3. Tiempo de desarrollo razonable
4. Coolness factor alto (TUI nativo)

**Siguiente paso:** Testing con subagents reales + feedback UX.

Si necesitas features avanzadas (logs streaming, controles complejos), considerar:
- Expandir versión blessed (v1.1+)
- O alternativa web simple (dashboard HTML + SSE) para mayor flexibilidad

---

## 📂 Ubicación Archivos

- **Código:** `~/.openclaw/workspace/scripts/openclaw-subagents-tui-blessed/`
- **Wrapper:** `~/.openclaw/workspace/scripts/subagents-dashboard`
- **Docs:**
  - `~/.openclaw/workspace/docs/ralph-tui-research.md` (investigación completa)
  - `~/.openclaw/workspace/scripts/openclaw-subagents-tui-blessed/README.md` (docs técnicas)

---

## 🧪 Testing Sugerido

1. **Lanzar dashboard en una terminal**
   ```bash
   ./subagents-dashboard
   ```

2. **En otra terminal, spawnnear subagents**
   ```bash
   # Ejemplo: spawnnear un subagent de prueba
   openclaw agent --model sonnet --prompt "Haz algo que tome 30s"
   ```

3. **Verificar en dashboard:**
   - ¿Aparece el subagent?
   - ¿Stats se actualizan?
   - ¿Navegación funciona?
   - ¿Detalles son correctos?

---

**¿Dudas o feedback?** Ping en Telegram (@RagnarBlackmade)
