# Knowledge Graph — Entidades Estructuradas

**Implementado:** 2026-03-18  
**Formato:** JSON atómico con schema

## Estructura (PARA)

```
entities/
├── projects/          # Proyectos activos (con objetivo/deadline)
├── areas/
│   ├── people/        # Personas (relaciones duraderas)
│   └── companies/     # Empresas / Organizaciones
├── resources/         # Temas de referencia
└── archives/          # Proyectos/personas inactivos
```

## Schema — Atomic Facts

Cada entidad tiene:
- **summary.md** — Overview conciso (cargado primero)
- **items.json** — Array de facts atómicos

### items.json Schema

```json
{
  "id": "entity-001",
  "fact": "Descripción breve de la información",
  "category": "milestone|relationship|status|preference|context",
  "timestamp": "2026-03-18",
  "source": "memory/2026-03-18.md",
  "status": "active|superseded",
  "supersededBy": null,
  "relatedEntities": ["areas/people/manu", "projects/lola-toolkit"],
  "lastAccessed": "2026-03-18",
  "accessCount": 1
}
```

### Categories

- **milestone**: Eventos importantes (creación, cambio de rol, etc.)
- **relationship**: Conexiones entre entidades
- **status**: Estado actual (en proceso, completado, bloqueado)
- **preference**: Preferencias de cómo trabajar/comunicar
- **context**: Información contextual general

### Status

- **active**: Hecho actual, en uso
- **superseded**: Obsoleto, reemplazado por otro fact (ver `supersededBy`)

## Tiering (Memory Decay)

En **summary.md**, facts se ordenan por tier:

### Hot (último 7 días)
- Accedidos recientemente o creados hace poco
- Prominentes en summary.md

### Warm (8-30 días)
- Información intermedia
- Incluida en summary.md pero con menor prioridad

### Cold (30+ días sin acceso)
- Omitida de summary.md
- Sigue disponible en items.json
- Acceder a un fact Cold lo reactiva a Hot

## Búsqueda

Con `memory_search` (ahora usando OpenAI embeddings):

```bash
# Buscar en entities
memory_search "Manu preferencias de comunicación"
memory_search "proyectos activos 2026"
```

Los resultados incluyen path + line numbers para referencia directa.

## Workflow

1. **Crear entidad** — New folder + summary.md + items.json
2. **Usar en conversaciones** — memory_search encuentra facts
3. **Actualizar** — Añadir nuevo fact a items.json (nunca borrar)
4. **Semanal** — Reescribir summary.md (aplica tiering: Hot/Warm/Cold)

## Nota Importante

**Sin romper nada:**
- Archivos .md existentes (MEMORY.md, memoria/diaria/) quedan como están
- Entities es **paralelo** — se usan ambos sistemas mientras migramos
- Gradual: entities crece, .md decrece lentamente
- Si entities falla, always fallback a memory_search en .md

---

Source: memory/entities/README.md
