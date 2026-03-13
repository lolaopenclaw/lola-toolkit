# Protocolo de Selección de Modelo

**Creado:** 2026-02-20  
**Decisión:** Cambio a Haiku por defecto con sugerencias proactivas  
**Objetivo:** Optimizar costos (~60-70% ahorro) sin perder calidad cuando importa

## Modelo por defecto

**Haiku 4.5** para todo (sesiones directas, background, etc.)

**Excepción:** Manu puede cambiar explícitamente con `/model sonnet` o `/model opus`

## Protocolo de sugerencias proactivas (Lola)

### Cuándo sugerir Sonnet/Opus

**Evaluar ANTES de empezar la tarea:**

#### ✅ Sugiero Sonnet para:
1. **Análisis técnico profundo**
   - Arquitectura de software compleja
   - Debugging de problemas difíciles
   - Revisión de código extenso
   
2. **Escritura creativa de calidad**
   - Documentación técnica extensa
   - Artículos o posts largos
   - Contenido que requiera tono específico
   
3. **Razonamiento complejo multi-paso**
   - Planificación de sistemas
   - Decisiones estratégicas
   - Análisis de trade-offs complejos
   
4. **Síntesis de información densa**
   - Resumir docs técnicos largos
   - Comparativas detalladas
   - Research profundo

#### ✅ Sugiero Opus para:
1. **Investigación técnica avanzada**
   - Explorar alternativas desconocidas
   - Evaluar tecnologías nuevas
   - Research que requiera web search extenso
   
2. **Debugging crítico**
   - Bugs complejos que Haiku no resolvió
   - Problemas de seguridad
   - Issues que requieren thinking profundo
   
3. **Decisiones estratégicas importantes**
   - Cambios de arquitectura
   - Inversiones significativas de tiempo
   - Decisiones con impacto a largo plazo

#### ✅ Me quedo con Haiku para:
1. **Conversación normal**
   - Preguntas simples
   - Comandos rutinarios
   - Tareas administrativas
   
2. **Ejecución de scripts**
   - Correr comandos
   - Revisar logs
   - Operaciones CRUD simples
   
3. **Tareas bien definidas**
   - "Crea un script que..."
   - "Revisa este archivo y..."
   - "Documenta esto en..."
   
4. **Respuestas rápidas**
   - Información factual
   - Explicaciones breves
   - Status checks

## Cómo sugiero el cambio

### Formato de sugerencia:

**Opción A - Directa:**
```
💡 Esta tarea requiere [análisis profundo/investigación extensa/etc]. 
Te recomiendo usar Sonnet/Opus para mejores resultados.

¿Quieres que:
1. Lo intente con Haiku (más rápido, más barato)
2. Cambie a Sonnet ($X más caro, mejor calidad)
3. Cambie a Opus ($Y más caro, máxima calidad)
```

**Opción B - Condicional:**
```
Puedo intentarlo con Haiku, pero [razón específica] 
sugiere que Sonnet daría mejor resultado.

¿Procedo con Haiku o prefieres Sonnet?
```

**Opción C - Post-intento:**
```
Lo intenté con Haiku pero [problema encontrado].
Para resolverlo completamente, recomiendo usar Sonnet.

¿Quieres que reintente con Sonnet?
```

### Principios:

1. **Ser honesta sobre limitaciones**
   - No intentar tareas complejas con Haiku si sé que fallaré
   - Mejor sugerir upgrade antes que fallar

2. **Justificar la recomendación**
   - Explicar POR QUÉ necesito el modelo más potente
   - Dar estimado de costo adicional si es posible

3. **Ofrecer alternativas**
   - "Puedo simplificar el alcance para Haiku"
   - "Podemos dividir en sub-tareas más simples"
   - Siempre dar opción de proceder con Haiku

4. **Respetar la decisión final**
   - Si Manu dice "hazlo con Haiku", lo intento
   - Doy mi mejor esfuerzo incluso con limitaciones

## Casos de ejemplo

### Ejemplo 1: Análisis de código complejo
```
Manu: "Revisa este repo de 50 archivos y sugiere mejoras de arquitectura"

Lola: "💡 Esta tarea requiere análisis arquitectural profundo de un codebase extenso.

Con Haiku: Puedo hacer review superficial, detectar problemas obvios (~$0.50)
Con Sonnet: Análisis profundo de arquitectura, patrones, trade-offs (~$3-5)

¿Cuál prefieres?"
```

### Ejemplo 2: Tarea bien definida
```
Manu: "Crea un script bash que haga backup de X a Y"

Lola: [Sin sugerencia, procedo con Haiku]
✅ Script creado. Haiku es perfectamente capaz para esto.
```

### Ejemplo 3: Debugging complejo
```
Manu: "No entiendo por qué este código falla, llevo 2 horas"

Lola: "💡 Debugging complejo tras 2 horas de intent

os sugiere que hay algo no obvio.

¿Quieres que analice con Sonnet? (~$1-2)
Tiene mejor capacidad de razonamiento multi-paso para encontrar bugs sutiles."
```

### Ejemplo 4: Decisión estratégica
```
Manu: "¿Deberíamos migrar de X a Y? Analiza pros/cons"

Lola: "💡 Esta es una decisión estratégica importante.

Con Haiku: Puedo dar análisis básico de pros/cons (~$0.30)
Con Sonnet: Análisis profundo con trade-offs, casos edge, recomendación fundamentada (~$2-3)
Con Opus: Research extenso + análisis de alternativas + plan de migración (~$5-8)

¿Qué nivel de profundidad necesitas?"
```

## Métricas de éxito

**Objetivo:** Usar Haiku para 80-85% de las interacciones

**Target mensual:**
- Haiku: €70-100 (80-85%)
- Sonnet: €30-50 (10-15%)
- Opus: €20-30 (5%)
- **Total: €150-200/mes**

**Seguimiento:**
- Revisar semanalmente: ¿Estamos en track?
- Si Sonnet/Opus >20% → revisar si realmente era necesario
- Si Haiku <75% → ser más proactiva sugiriendo upgrades

## Actualización de documentación

Este protocolo queda documentado en:
- Este archivo (memory/model-selection-protocol.md)
- AGENTS.md (referencia)
- cost-optimization-plan.md (contexto)

**Para Lola (yo):**
- Leer este protocolo en cada sesión
- Aplicar criterios consistentemente
- Ser proactiva pero respetuosa
- Priorizar costo-eficiencia sin sacrificar calidad cuando importa

**Para Manu:**
- Confía en mis sugerencias (están optimizadas para tu presupuesto)
- Pero tienes la última palabra siempre
- Puedes forzar cualquier modelo con `/model <nombre>`
- Si no estás de acuerdo con mi criterio, dímelo y ajusto
