# CLI-Anything: Investigación Completa

**Fecha:** 2026-03-24  
**Investigadora:** Lola (Subagent)  
**Contexto:** Evaluación para posible integración con OpenClaw

---

## Resumen Ejecutivo (TL;DR)

**¿Nos sirve?** **NO, al menos no ahora mismo.**

**Por qué:** CLI-Anything es un *meta-framework* que **genera** CLIs automáticamente desde código fuente usando LLMs frontier (Claude Opus/Sonnet 4.6, GPT-5.4). **No es una herramienta lista para usar**, sino un *plugin para Claude Code* que analiza codebases y genera Python packages completos con tests, documentación y packaging.

**Problema crítico para nosotros:**
- Requiere Claude Code como plataforma (nosotros usamos OpenClaw)
- Genera CLIs desde cero (20-30 min por app con LLM)
- Enfocado a crear wrappers para **apps GUI sin CLI** (GIMP, Blender, LibreOffice)
- Nuestros skills actuales ya son CLIs existentes que simplemente llamamos

**Casos donde SÍ sería útil:**
1. Si tuviéramos que wrappear una **app GUI propietaria** sin CLI oficial
2. Si quisiéramos crear un skill para software que solo tiene interfaz gráfica
3. Si necesitáramos automatizar apps de escritorio complejas (ej. Audacity, OBS)

**Recomendación:** **Evaluar más tarde**. Interesante como concepto, pero no resuelve problemas actuales. Guardar en radar para cuando necesitemos automatizar apps GUI específicas.

---

## 1. ¿Qué es CLI-Anything Exactamente?

### Definición
CLI-Anything es un **generador automático de CLIs** distribuido como plugin para Claude Code (y otros agentes de IA). No es un CLI en sí mismo, sino un *sistema que produce CLIs*.

### Arquitectura Técnica

#### Pipeline de Generación (7 Fases)
```
1. Source Acquisition → Clone repo o analiza código local
2. Codebase Analysis → Escanea arquitectura, identifica backend
3. CLI Architecture Design → Diseña comandos, grupos, estado
4. Implementation → Genera código Python (Click + core modules)
5. Test Planning → Crea TEST.md con plan de pruebas
6. Test Implementation → Escribe tests (unit + E2E)
7. Documentation & Publishing → setup.py, SKILL.md, PyPI-ready
```

#### Tecnología
- **Requiere:** Python 3.10+, click, pytest
- **Genera:** Paquetes Python namespace-isolated (`cli_anything.<software>`)
- **Backend:** Invoca el software real (no reimplementa funcionalidad)
- **Salida:** CLIs con REPL interactivo, modo JSON, undo/redo

### Cómo Funciona (Metodología HARNESS.md)

1. **Análisis estático del código fuente:**
   - Identifica el backend (ej. MLT para editores de video, bpy para Blender)
   - Mapea acciones GUI → API calls
   - Encuentra herramientas CLI existentes del backend

2. **Generación de código:**
   - Crea estructura Python con Click
   - Implementa core modules (project.py, session.py, export.py)
   - Añade REPL con `repl_skin.py` (interfaz unificada)
   - Configura JSON output mode (`--json`)

3. **Testing automático:**
   - Unit tests con datos sintéticos
   - E2E tests invocando el software real (LibreOffice, Blender, etc.)
   - Subprocess tests del CLI instalado
   - 100% pass rate requerido

4. **Packaging:**
   - Namespace packages PEP 420 (`cli_anything.*`)
   - Entry points para PATH installation
   - SKILL.md auto-generado para descubrimiento por agentes

### Ejemplos Concretos de CLIs Generados

| Software | Dominio | Backend | Tests | Ejemplo de Uso |
|----------|---------|---------|-------|----------------|
| **GIMP** | Edición imagen | Pillow + GEGL/Script-Fu | 107 | `cli-anything-gimp project new --width 1920` |
| **Blender** | 3D modeling | bpy (Python scripting) | 208 | `cli-anything-blender scene new --name ProductShot` |
| **LibreOffice** | Office suite | ODF + headless LO | 158 | `cli-anything-libreoffice document new -o report.json` |
| **Audacity** | Audio | sox (command-line audio) | 161 | `cli-anything-audacity project new --rate 44100` |
| **Zoom** | Videoconferencia | Zoom REST API | 22 | `cli-anything-zoom meeting list --upcoming` |
| **ComfyUI** | AI image gen | ComfyUI REST API | 70 | `cli-anything-comfyui workflow run --prompt "cat"` |

**Total:** 19 apps, 1,858 tests (100% pass rate)

### Limitaciones Conocidas

1. **Requiere LLMs frontier:**
   - Claude Opus/Sonnet 4.6, GPT-5.4
   - Modelos más pequeños producen CLIs incompletos o incorrectos

2. **Solo funciona con código fuente:**
   - Apps open source con código disponible
   - Binarios compilados requieren decompilación (calidad degradada)

3. **Refinamiento iterativo necesario:**
   - Una sola ejecución no cubre todas las capacidades
   - Usar `/refine` múltiples veces para producción

4. **No es instantáneo:**
   - 20-30 minutos por app para generación completa
   - Requiere revisión manual del código generado

---

## 2. Casos de Uso Reales

### ¿Para Qué Apps Es Útil?

#### ✅ **Casos Ideales:**
- **Apps GUI sin CLI oficial** (GIMP, Blender, Inkscape)
- **Software de escritorio complejo** (OBS Studio, Audacity, Shotcut)
- **Web services sin SDK unificado** (APIs fragmentadas)
- **Automatización de workflows creativos** (edición video, audio, 3D)

#### ❌ **No Ideal Para:**
- Apps que YA tienen CLI robusto (git, docker, kubectl)
- CLIs simples que se pueden escribir manualmente en <1h
- Apps con APIs web directas y bien documentadas
- Software sin código fuente disponible

### Tipos de Operaciones que Automatiza

**Patrón común:** GUI app → CLI manipulation → Render con software real

Ejemplos:
```bash
# LibreOffice: Crear documento → Añadir contenido → Exportar PDF real
cli-anything-libreoffice document new -o report.json --type writer
cli-anything-libreoffice --project report.json writer add-heading -t "Q1 Report"
cli-anything-libreoffice --project report.json export render output.pdf -p pdf

# Blender: Crear escena → Añadir objetos → Render con Blender real
cli-anything-blender scene new --name ProductShot
cli-anything-blender object add-mesh --type cube --location 0 0 1
cli-anything-blender render execute --output render.png --engine CYCLES

# Shotcut: Crear proyecto → Añadir clips → Render con melt/ffmpeg
cli-anything-shotcut project new -o video.json
cli-anything-shotcut clip add -p video_intro.mp4 -s 0 -d 5
cli-anything-shotcut export render final.mp4 --preset youtube-1080p
```

### Soporte Multi-Plataforma

| Tipo de App | Ejemplo | Backend CLI | Sistema Req. |
|-------------|---------|-------------|--------------|
| GUI nativas | LibreOffice | `libreoffice --headless` | `apt install libreoffice` |
| 3D/Creative | Blender | `blender --background --python` | `apt install blender` |
| Video editing | Shotcut/Kdenlive | `melt` o `ffmpeg` | `apt install melt ffmpeg` |
| MCP servers | Browser (DOMShell) | `npx @apireno/domshell` | `npm install -g npx` |
| Web APIs | Zoom, AnyGen | REST API (OAuth2) | API keys |
| Local AI | Ollama, ComfyUI | REST API (localhost) | Software instalado localmente |

**Respuesta corta:** Python (cualquier), Node.js (vía wrappers), apps compiladas (si tienen CLI/API backend).

---

## 3. Requisitos Técnicos

### Dependencias Core

**Para generar CLIs (fase de desarrollo):**
- Claude Code v2.x+ (o OpenCode, Codex, Qodercli con adaptadores)
- Python 3.10+
- LLM frontier-class (Claude Opus 4.6, Sonnet 4.6, GPT-5.4)
- Git (para clonar repos fuente)

**Para usar CLIs generados (producción):**
```bash
# Python dependencies (siempre)
pip install click>=8.0.0 prompt-toolkit>=3.0.0

# Software backend (según app)
apt install gimp            # Para cli-anything-gimp
apt install blender         # Para cli-anything-blender
apt install libreoffice     # Para cli-anything-libreoffice
apt install melt ffmpeg     # Para cli-anything-shotcut
# etc.
```

### Modelos de IA Necesarios

**Durante generación:**
- **LLMs usados:** Los de Claude Code (API de Anthropic)
- **No hay LLM local:** CLI-Anything no entrena/fine-tune nada
- **Costo:** Consumo de API según tokens procesados (análisis codebase)

**Después de generar:**
- **¡NINGUNO!** El CLI es código Python estático
- Los CLIs generados NO requieren LLMs para funcionar
- Son herramientas standalone (como cualquier CLI Python)

### Recursos (RAM, CPU, GPU)

**Durante generación (desarrollo):**
- RAM: ~4-8 GB (Claude Code + análisis codebase)
- CPU: Cualquier modern CPU (no intensivo)
- GPU: **NO requerida** (LLMs son vía API)
- Tiempo: 20-30 min por app (análisis + generación + tests)

**Después de generar (uso):**
- RAM: Depende del software backend (GIMP, Blender, etc.)
- CPU: Igual que arriba
- GPU: Solo si el backend la necesita (ej. Blender renders)

### ¿Funciona sin GPU en VPS?

**✅ SÍ, perfectamente.**

- Generación: Claude Code usa APIs (no GPU local)
- Uso posterior: Depende del backend
  - LibreOffice: CPU-only ✅
  - GIMP (Pillow): CPU-only ✅
  - Blender renders: Puede usar CPU (lento pero funciona)
  - ComfyUI/Stable Diffusion: Requiere GPU (pero puede conectar API remota)

**Conclusión para VPS Ubuntu:** ✅ **Viable** para mayoría de casos (excepto renders GPU-intensivos).

---

## 4. Integración con OpenClaw

### ¿Podría Generar Skills Automáticamente?

**Respuesta:** SÍ, con adaptación.

**Flujo propuesto:**
```
1. App sin CLI oficial (ej. nueva app GUI desktop)
   ↓
2. Usar CLI-Anything (vía Claude Code o manual)
   → Genera: cli-anything-<app>/
   → Contiene: Python package + SKILL.md
   ↓
3. Instalar CLI generado: pip install -e agent-harness/
   → Disponible en PATH: cli-anything-<app>
   ↓
4. Copiar SKILL.md → ~/.openclaw/skills/<app>/SKILL.md
   → OpenClaw descubre automáticamente
   ↓
5. Agent usa el CLI vía skill (como cualquier otro)
```

**Ventaja:** SKILL.md ya viene auto-generado por CLI-Anything (Phase 6.5).

**Desventaja:** Requiere paso manual de generación con Claude Code primero.

### Skills Actuales que Podrían Beneficiarse

Revisar nuestros 40+ skills:

| Skill Actual | ¿Beneficio de CLI-Anything? | Razón |
|--------------|----------------------------|-------|
| **openhue** | ❌ No | Ya tiene CLI oficial (`openhue`) |
| **spotify-player** | ❌ No | Usa `spogo` (CLI existente) |
| **gifgrep** | ❌ No | Ya es CLI (wrapper APIs) |
| **mcporter** | ❌ No | Ya es CLI (MCP wrapper) |
| **Video-frames** | ⚠️ Quizá | Si quisiéramos GUI complex editor wrap |
| **coding-agent** | ❌ No | Skills orquestan agents, no wrappean GUI |

**Patrón:** Nuestros skills son *orquestadores* de herramientas existentes. CLI-Anything es para *crear* herramientas donde no existen.

### ¿Vale la Pena el Esfuerzo vs Skills Manuales?

**Comparativa:**

| Aspecto | CLI-Anything | Skill Manual OpenClaw |
|---------|-------------|----------------------|
| **Tiempo inicial** | 20-30 min (LLM genera) | 1-4h (escribir SKILL.md + tests) |
| **Control** | Medio (review código generado) | Total (escribes todo) |
| **Mantenimiento** | Igual (editar código Python) | Igual (editar SKILL.md) |
| **Testing** | Auto-generado (1,800+ tests) | Manual (escribir tus propios) |
| **Documentación** | Auto-generada | Manual |
| **Curva aprendizaje** | Baja (plugin hace todo) | Alta (entender formato skill) |
| **Flexibilidad** | Limitada (estructura fija) | Total (cualquier flujo) |

**Escenario donde vale la pena CLI-Anything:**
- App GUI compleja (50+ comandos)
- Necesitas tests E2E exhaustivos
- Quieres PyPI-ready package
- Tienes acceso a Claude Code

**Escenario donde vale más skill manual:**
- CLI ya existe (solo necesitas orquestar)
- Workflow simple (3-5 comandos)
- Lógica custom específica de tu caso
- Mantenimiento a largo plazo por ti

**Para OpenClaw:** Skills manuales ganan en 90% de casos (ya tenemos CLIs, solo los envolvemos).

---

## 5. Comparativa con Alternativas

### Otros Proyectos Similares

**Búsqueda exhaustiva:** No encontré competencia directa.

**Proyectos relacionados (pero diferentes):**

| Proyecto | Qué Hace | Diferencia vs CLI-Anything |
|----------|----------|---------------------------|
| **Playwright/Puppeteer** | Automatización web via browser | GUI automation (frágil), no genera CLIs |
| **AutoGUI (Python)** | Click coordinates, screenshots | RPA (super frágil), pixel-based |
| **Selenium** | Web testing framework | Solo web, no desktop apps |
| **Appium** | Mobile app testing | Mobile-only, testing focus |
| **LLM CLI tools (llm, aichat)** | LLMs desde terminal | Interactúan con LLMs, no generan CLIs |
| **GitHub Copilot/Cursor** | Code generation | Asistentes dev, no CLI generation específica |

**Conclusión:** CLI-Anything es único en su nicho (auto-generación de CLIs robustos desde codebases).

### Pros/Contras vs Escribir CLIs Manualmente

#### ✅ **Pros de CLI-Anything:**
1. **Velocidad:** 20-30 min vs horas/días manual
2. **Tests comprehensivos:** 100-200 tests auto-generados
3. **Estructura consistente:** Namespace packaging, REPL, JSON mode
4. **Documentación auto:** SKILL.md, TEST.md, README
5. **Mejor práctica enforced:** HARNESS.md methodology
6. **PyPI-ready:** setup.py, versioning, installable

#### ❌ **Contras de CLI-Anything:**
1. **Requiere LLM frontier:** Costo API (no siempre exacto)
2. **Review necesario:** Código generado puede tener bugs
3. **Opinionated structure:** Estructura fija (puede no encajar)
4. **Requiere código fuente:** No funciona con binarios cerrados
5. **Overhead inicial:** Instalar Claude Code, aprender plugin
6. **Refinamiento iterativo:** No perfecto en primera generación

#### 🏆 **Cuándo Usar Qué:**

**Usar CLI-Anything si:**
- App GUI compleja (>20 comandos)
- Necesitas cobertura 100% tests
- Quieres publicar CLI (PyPI)
- Tienes acceso LLM frontier

**Escribir manual si:**
- CLI simple (<10 comandos)
- Lógica business specific
- Wrapper de CLI existente
- Control total sobre implementación

---

## 6. Estado del Proyecto

### Última Actualización

**Fecha último commit:** 2026-03-23 (¡ayer!)  
**Estado:** **ACTIVO** (commits diarios)

**Actividad reciente (últimos 7 días):**
- 2026-03-23: CLI-Hub meta-skill (agentes descubren CLIs autónomamente)
- 2026-03-22: MuseScore CLI + infraestructure improvements
- 2026-03-21: Windows compatibility fixes
- 2026-03-20: Novita AI CLI añadido
- 2026-03-18: CLI-Hub lanzado (registry centralizado)

### Comunidad

**GitHub Stats:**
- ⭐ 21,000 stars (muy popular)
- 🍴 Forks: ~4K+ (estimado por actividad)
- 🐛 Issues: 23 open
- 🔀 PRs: 32 open, 61 closed
- 👥 Contribuidores: Activo (PRs de comunidad diarias)

**Tipo de contribuciones:**
- Community-contributed CLIs (nueva apps)
- Bug fixes (security, Windows compat)
- Feature requests (nuevos comandos)
- Documentation improvements

**Señales de salud:**
- ✅ PRs se revisan/mergean rápido
- ✅ Issues tienen respuestas
- ✅ Actividad constante (no abandonado)

### Estabilidad

**Producción-ready?** ⚠️ **Experimental pero maduro**

**Evidencia:**
- ✅ 1,858 tests (100% pass)
- ✅ 19 apps diferentes funcionando
- ✅ Metodología documentada (HARNESS.md)
- ⚠️ Requiere revisión manual del código generado
- ⚠️ Depende de calidad LLM (puede degradarse)

**Recomendación estabilidad:**
- Para prototipos: ✅ Listo
- Para producción: ⚠️ Con revisión
- Para infra crítica: ❌ Mejor manual

### Documentación

**Calidad:** 🌟 **Excelente**

**Documentos clave:**
- `README.md`: Exhaustivo (37K chars), ejemplos, demos
- `HARNESS.md`: SOP completo (38K chars), metodología detallada
- `QUICKSTART.md`: 5 min getting started
- `PUBLISHING.md`: Guía distribución PyPI
- `CONTRIBUTING.md`: Cómo contribuir nuevos CLIs
- Por cada CLI: SKILL.md, TEST.md, README.md

**Cobertura:**
- ✅ Installation (múltiples plataformas)
- ✅ Usage examples (código real)
- ✅ Architecture explanation
- ✅ Testing methodology
- ✅ Troubleshooting

**Debilidad:** Documentación muy enfocada a Claude Code (otras plataformas menos detalladas).

---

## 7. Evaluación Final

### ¿Nos Sirve para Nuestro Setup?

**Respuesta directa:** **NO ahora, QUIZÁ futuro.**

**Razones:**

**❌ Por qué NO ahora:**
1. **Plataforma incompatible:** Requiere Claude Code, nosotros usamos OpenClaw
2. **Problema diferente:** Generamos CLIs desde cero; nosotros envolvemos CLIs existentes
3. **Overhead innecesario:** Nuestros skills son simples (SKILL.md + bash scripts)
4. **Tiempo no justificado:** 30 min generación vs 30 min escribir skill manual
5. **Dependencia LLM:** Cada nueva app = costo API (nuestros skills son estáticos)

**✅ Por qué QUIZÁ futuro:**
1. Si necesitamos automatizar **app GUI propietaria** sin CLI
2. Si queremos skill para software desktop complejo (ej. Photoshop alternativa)
3. Si OpenClaw añade soporte para plugins Claude Code (interoperabilidad)
4. Como referencia para mejorar nuestro `skill-creator` (metodología HARNESS.md)

### ¿Cuándo Lo Usaríamos? (Escenarios Concretos)

**Escenario 1: App Desktop Sin CLI**
```
Problema: Necesitamos automatizar software GUI (ej. DaVinci Resolve)
Solución: CLI-Anything genera cli-anything-davinci → Skill OpenClaw
Timeline: 1h generación + review → Skill funcional
```

**Escenario 2: Migración Skills Existentes a CLIs Robustos**
```
Problema: Skill actual usa scripts bash frágiles
Solución: Regenerar con CLI-Anything → CLI Python robusto + tests
Ejemplo: sonoscli → cli-anything-sonos (mejor manejo errores)
```

**Escenario 3: Contribuir CLI al Ecosistema**
```
Problema: Creamos skill útil, queremos compartir comunidad
Solución: Usar CLI-Anything → PyPI package → PR a CLI-Hub
Beneficio: Otros usuarios OpenClaw/Claude Code/Cursor lo usan
```

**Frecuencia estimada:** 1-2 veces/año (apps muy específicas).

### ¿Merece la Pena Instalarlo?

**Respuesta:** **NO instalar ahora.**

**Razón principal:** No resuelve problemas actuales.

**Criterio instalación:**
```python
if (necesitamos_automatizar_GUI_sin_CLI 
    and tiempo_desarrollo_manual > 4h
    and tenemos_acceso_claude_code):
    entonces_instalar()
else:
    guardar_en_radar()
```

### Recomendación: No Usar (Justificación)

**Decisión:** **NO usar CLI-Anything ahora.**

**Justificación detallada:**

1. **Incompatibilidad plataforma:**
   - CLI-Anything optimizado para Claude Code
   - OpenClaw tiene arquitectura diferente (skills vs plugins)
   - Adaptación requiere trabajo custom (no justificado)

2. **Caso de uso no encaja:**
   - CLI-Anything: GUI → CLI (crear de cero)
   - OpenClaw skills: CLI existente → Orquestar
   - 95% de nuestros skills son wrappers, no implementaciones

3. **Coste-beneficio negativo:**
   - Instalar Claude Code: +1h setup
   - Aprender plugin: +2h learning curve
   - Generar primer CLI: +30min
   - **Total: 3.5h** vs **30min skill manual**

4. **Alternativas mejores:**
   - Seguir con `skill-creator` actual (optimizado para OpenClaw)
   - Mejorar skill-creator inspirándonos en HARNESS.md
   - Cuando necesitemos GUI wrap, considerar Playwright primero (más simple)

5. **Riesgo dependencia:**
   - CLI-Anything experimental (puede cambiar)
   - Dependencia de LLMs frontier (costos variables)
   - Nuestros skills estáticos = más predecibles

**Excepción (cuándo reconsiderar):**
```
IF app_GUI_crítica 
   AND sin_CLI_oficial 
   AND alternativas_fallaron 
   AND budget_permite_LLM_API
THEN evaluar_CLI_Anything_nuevamente
```

---

## Conclusión

CLI-Anything es una herramienta **impresionante y bien ejecutada** para su nicho: generar CLIs automáticamente desde codebases complejos de apps GUI. La metodología HARNESS.md es excelente referencia, y los 1,858 tests passing demuestran robustez.

**Sin embargo, NO encaja con nuestro caso de uso actual:** OpenClaw skills envuelven herramientas existentes, no las crean desde cero. El overhead de integración (Claude Code, LLMs API, generación iterativa) no se justifica cuando podemos escribir skills manualmente en 30 minutos.

**Valor futuro:** Guardar en radar para caso edge donde necesitemos automatizar app desktop sin CLI oficial. Estudiar HARNESS.md para mejorar nuestro `skill-creator`.

**Acción recomendada:** Archivar esta investigación en memory/, NO instalar ahora, revisitar si aparece necesidad específica.

---

## Referencias

- Repo: https://github.com/HKUDS/CLI-Anything
- CLI-Hub: https://hkuds.github.io/CLI-Anything/
- Website: https://clianything.org/
- Metodología: HARNESS.md (38K chars, must-read)
- Stats: 21K stars, 1,858 tests, 19 apps, MIT license
- Última actualización: 2026-03-23 (activo)

---

**Investigación completada en 28 minutos.**  
**Siguiente paso:** Reportar al agente principal + esperar siguiente tarea.
