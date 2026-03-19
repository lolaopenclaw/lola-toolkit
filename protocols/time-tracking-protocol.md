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
