# GitHub #33103 — Comment Ready to Post

**Issue:** Gateway restart infinite loop with zombie process
**Status:** IMPROVED in v2026.3.8

## Comment Body (copy-paste ready)

```markdown
## Status Update: v2026.3.8 (2026-03-09)

Reproducimos este issue hoy tras actualizar a v2026.3.8 y observamos **mejoras significativas**.

### Test: Config change → SIGUSR1 → Full restart

**v2026.3.8 Comportamiento:**

✅ Task draining antes de reiniciar (14 segundos esperando tasks)
✅ Config validation: detecta cambios antes de crashear  
✅ Restart limpio: restart counter = 1 (NO infinite loop)
✅ Gateway listening nuevamente sin errores de "port already in use"

### Conclusión
- **v2026.3.2:** Infinite loop (30+ restart attempts)
- **v2026.3.8:** Clean restart (counter = 1)

El fix de "Gateway/restart timeout recovery" y "Gateway/config restart guard" en v2026.3.8 **reduce significativamente el problema**.

**Status:** IMPROVED - No longer critical blocker, pero seguimos monitoreando.
```

## How to Post
1. Go to: https://github.com/openclaw/openclaw/issues/33103
2. Click "Comment"
3. Paste the markdown above
4. Click "Comment"

## When
- From your laptop (has GitHub auth)
- When you have time today/tomorrow
