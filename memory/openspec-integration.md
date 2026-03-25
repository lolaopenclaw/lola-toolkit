# OpenSpec Integration

**Status:** ✅ Implementado (2026-03-25)  
**Purpose:** Spec-Driven Development con TypeScript para scripts/skills del workspace

---

## ¿Qué es OpenSpec?

Framework de **Spec-Driven Development** que usa **TypeScript** como lenguaje de especificación.

**Workflow normal:** Spec → Código  
**Nuestro workflow:** Código → Spec (documentando lo que ya existe)

---

## Estructura

```
workspace/
  specs/                              # Especificaciones TypeScript
    index.ts                          # Barrel export
    README.md                         # Documentación
    garmin-health-report.spec.ts      # Ejemplo 1
    truthcheck.spec.ts                # Ejemplo 2
    ...
  openspec.config.ts                  # Config de OpenSpec
  scripts/
    openspec-helpers.sh               # Utilidades CLI
```

---

## Comandos

```bash
# Validar todas las specs
bash scripts/openspec-helpers.sh validate

# Listar specs disponibles
bash scripts/openspec-helpers.sh list

# Crear nueva spec desde template
bash scripts/openspec-helpers.sh add <nombre>

# Generar docs (TODO: configurar)
bash scripts/openspec-helpers.sh docs
```

---

## Convenciones

1. **Un archivo por componente**: `<nombre>.spec.ts`
2. **Interfaces input/output**: Siempre exportar con nombres claros
3. **JSDoc comments**: Para descripciones (se usan en docs generadas)
4. **Function stubs**: `throw new Error('Implementation via ...')` para indicar dónde vive el código real
5. **Index export**: Añadir a `specs/index.ts` cada nueva spec

---

## Ejemplo: Añadir una nueva spec

```bash
# 1. Crear desde template
bash scripts/openspec-helpers.sh add spotify-control

# 2. Editar specs/spotify-control.spec.ts
# 3. Validar
bash scripts/openspec-helpers.sh validate
```

O manualmente:

```typescript
/**
 * Spotify Control Spec
 * 
 * Control Spotify playback via spogo CLI.
 */

export interface SpotifyControlInput {
  /** Action to perform */
  action: 'play' | 'pause' | 'next' | 'prev' | 'volume';
  
  /** Volume level (0-100, only for volume action) */
  volume?: number;
}

export interface SpotifyControlOutput {
  /** Current track info */
  track: {
    title: string;
    artist: string;
    album: string;
  };
  
  /** Playback state */
  state: 'playing' | 'paused';
  
  /** Current volume (0-100) */
  volume: number;
}

/**
 * Control Spotify playback
 */
export async function controlSpotify(
  input: SpotifyControlInput
): Promise<SpotifyControlOutput> {
  throw new Error('Implementation via: spogo (see skills/spotify-player)');
}
```

---

## Specs Actuales

1. **garmin-health-report** — Reporte diario de métricas Garmin
2. **truthcheck** — Verificación de claims y fact-checking

---

## Roadmap

- [x] Setup inicial (OpenSpec + TypeScript)
- [x] Specs de ejemplo (garmin-health-report, truthcheck)
- [x] CLI helpers (validate, list, add)
- [ ] Configurar generación de docs (OpenAPI/Swagger)
- [ ] Añadir specs para más scripts/skills importantes
- [ ] Validación en runtime (opcional)
- [ ] Cron nocturno: validar specs vs código real

---

## Por qué hacemos esto

1. **Aprendizaje**: Manu va a usar OpenSpec en el curro — esto le ayuda a practicar
2. **Documentación viviente**: Las specs son código, no se desactualizan
3. **Contratos claros**: Inputs/outputs explícitos para cada componente
4. **Validación**: Podemos detectar cambios breaking en scripts/skills

---

## Notas

- **No generamos código desde specs** (nuestro código ya existe)
- **Sí documentamos código con specs** (spec-after en vez de spec-first)
- **Para nuevos componentes**: Intentar hacer spec-first cuando sea posible
- **OpenSpec != OpenAPI**: OpenSpec usa TypeScript; OpenAPI usa YAML/JSON

---

**Última actualización:** 2026-03-25  
**Docs:** specs/README.md  
**Helper script:** scripts/openspec-helpers.sh
