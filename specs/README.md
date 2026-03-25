# OpenSpec Specifications

Este directorio contiene especificaciones TypeScript de los componentes del workspace (scripts, skills, crons).

## ¿Por qué OpenSpec?

- **Documentación viviente**: Los tipos TypeScript son la spec, la doc se genera automáticamente
- **Validación**: Podemos validar inputs/outputs en runtime
- **Spec-Driven Development**: Define primero el contrato, luego implementa
- **Aprendizaje**: Práctica para usar OpenSpec en el curro

## Estructura

```
specs/
  index.ts                          # Barrel export
  README.md                         # Este archivo
  garmin-health-report.spec.ts      # Spec de garmin-health-report
  truthcheck.spec.ts                # Spec de truthcheck
  ...
```

## Convenciones

1. **Un archivo por componente**: `<nombre>.spec.ts`
2. **Interfaces input/output**: Siempre exportar
3. **JSDoc comments**: Para descripciones (se usan en la doc generada)
4. **Function stubs**: `throw new Error('Implementation via ...')` para indicar dónde vive el código real

## Cómo añadir una nueva spec

```typescript
/**
 * Mi Tool Spec
 * 
 * Descripción de qué hace la tool.
 */

export interface MiToolInput {
  /** Param 1 description */
  param1: string;
  
  /** Param 2 description (optional) */
  param2?: number;
}

export interface MiToolOutput {
  /** Result description */
  result: string;
  
  /** Timestamp */
  timestamp: string;
}

/**
 * Execute mi tool
 */
export async function executeMiTool(input: MiToolInput): Promise<MiToolOutput> {
  throw new Error('Implementation via: scripts/mi-tool.sh');
}
```

## Comandos útiles

```bash
# Instalar OpenSpec (ya hecho)
npm install -D openspec

# Generar docs (TODO: configurar openspec.config.ts)
npx openspec generate

# Validar specs
npx tsc --noEmit specs/*.ts
```

## Roadmap

- [ ] Configurar `openspec.config.ts`
- [ ] Generar docs automáticas
- [ ] Añadir specs para más scripts/skills
- [ ] Integrar validación en runtime (opcional)
- [ ] Cron nocturno: validar specs vs código real

## Notas

- Estamos haciendo "spec-after" (código → spec) en vez de "spec-first" (spec → código)
- Está bien: lo importante es tener la spec como fuente de verdad
- Cuando construyas algo nuevo, intenta hacerlo spec-first
