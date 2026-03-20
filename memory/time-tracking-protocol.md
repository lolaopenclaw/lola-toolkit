# ⏱️ Time Tracking Protocol

**Problema:** Lola estima el tiempo fatal. Dice "casi una hora" cuando han pasado 15 minutos.
**Causa:** No consulta el reloj real. Estima "de cabeza" (que no funciona).
**Solución:** Usar SIEMPRE timestamps reales del servidor.

## Reglas

1. **Al empezar una tarea:** Guardar timestamp → `date +%s` (epoch seconds)
2. **Al reportar progreso:** Calcular diferencia real → `$(( $(date +%s) - START ))`
3. **NUNCA estimar de cabeza.** Si no tengo el timestamp de inicio, decir "no tengo el timestamp exacto"
4. **Para reportes:** Usar timestamps de los mensajes de Telegram (metadata del mensaje)

## Cómo calcular

```bash
# Al empezar:
START_TIME=$(date +%s)

# Al reportar:
ELAPSED=$(( $(date +%s) - START_TIME ))
MINUTES=$(( ELAPSED / 60 ))
echo "Tiempo real: ${MINUTES} minutos"
```

## Ejemplo correcto (sesión 2026-03-09)
- Manu dijo "ponte ya" a las 21:02 (msg 7058)
- Primer commit del framework: 21:08 (~6 min)
- Optimización HEARTBEAT completa: 21:10 (~8 min)
- Optimización AGENTS+USER+SOUL+MEMORY completa: 21:13 (~11 min)
- Crons configurados: 21:15 (~13 min)
- **Total real: 13 minutos** (no "casi una hora")

## Aplicar a estimaciones futuras
- Si una tarea similar tardó 13 min → estimar 15-20 min (margen)
- Registrar tiempos reales de tareas completadas para mejorar estimaciones
- Patrón autoimprove: medir → comparar con estimación → ajustar

## 📊 Benchmark de Procesamiento Local (VPS CPU-only, 2026-03-20)

### Ratios medidos (usar estos para estimar):
| Tarea | Ratio vs duración input | Ejemplo |
|-------|------------------------|---------|
| Whisper turbo (audio→texto) | 3x realtime | 86 min audio → ~4h |
| MediaPipe pose (vídeo→landmarks) | 0.5x realtime | 56 min vídeo → ~1h 50min |
| ffmpeg clip extraction | ~3s por clip | 76 clips → ~4 min |
| Sub-agente Sonnet (código) | 3-10 min típico | Script completo ~5 min |
| Sub-agente Sonnet (código complejo) | 10-15 min | Pipeline multi-script ~12 min |

### Fórmula de estimación:
```
Estimación = (duración_input × ratio) + 20% buffer
```

### Reglas:
1. **Consultar esta tabla** antes de dar estimaciones
2. **Vídeos >5 min:** añadir watchdog (riesgo de cuelgue en CPU)
3. **Batch >10 items:** riesgo de proceso muerto, monitorizar
4. **NUNCA usar 5x para Whisper turbo** — es 3x en esta VPS
5. **Actualizar ratios** cuando haya nuevos datos reales
