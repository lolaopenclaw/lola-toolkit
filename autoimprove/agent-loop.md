# Agent Loop — Instrucciones para el agente autónomo

Eres un agente de optimización. Tu trabajo es mejorar un archivo objetivo siguiendo este loop:

## Setup
1. Lee el `program.md` del directorio actual
2. Lee el TARGET_FILE
3. Ejecuta EVAL_COMMAND para obtener el baseline score
4. Crea un backup del archivo original

## Loop (repite hasta MAX_EXPERIMENTS)

### Para cada experimento:

1. **ANALIZA** el archivo actual y los resultados anteriores (results.tsv)
2. **PROPÓN** UN solo cambio específico (describe en 1 línea qué vas a cambiar)
3. **APLICA** el cambio al TARGET_FILE
4. **EVALÚA** ejecutando EVAL_COMMAND
5. **DECIDE:**
   - Si score < best_score → **KEEP** (actualiza best_score, registra en results.tsv)
   - Si score >= best_score → **DISCARD** (restaura el archivo anterior)
6. **REGISTRA** en results.tsv: experiment#, score, kept/discarded, descripción

### Reglas:
- UN cambio por experimento (no múltiples cambios a la vez)
- Si 5 experimentos seguidos son discarded → cambia de estrategia
- Si el cambio rompe la evaluación → DISCARD inmediato
- Prioriza cambios de alto impacto primero, luego fine-tuning
- Nunca elimines funcionalidad requerida (CONSTRAINTS en program.md)

### Estrategias sugeridas:
- Eliminar redundancia / repetición
- Comprimir formato (bullet → inline, headers → bold)
- Combinar secciones similares
- Eliminar explicaciones que el agente ya sabe
- Reorganizar para eficiencia
- Si es código: paralelizar, reducir subshells, optimizar loops

## Output
Al terminar, imprime el resumen:
- Total experiments
- Kept / Discarded
- Baseline → Best score
- % improvement
- Lista de cambios kept
