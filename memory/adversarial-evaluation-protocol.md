# Adversarial Evaluation Protocol

**Created:** 2026-03-26  
**Source:** Anthropic's harness design for long-running agents (March 2026)  
**Status:** ✅ ACTIVE — Lola follows this automatically for qualifying tasks

---

## Overview

Three-layer quality pipeline for subagent work:

```
┌─────────────────────────────────────────────────┐
│           Quality Pipeline (automatic)            │
├─────────────────────────────────────────────────┤
│                                                   │
│  1. GENERATOR subagent → does the work            │
│  2. RALPH WIGGUM checks → deterministic verify    │
│     - shellcheck, bash -n, tsc, tests             │
│     - Only for code/scripts (skip for docs)       │
│  3. EVALUATOR subagent → adversarial critique     │
│     - Scores 1-5 on objective criteria            │
│     - If any score < 3 → Generator iterates       │
│  4. HUMAN approval → Manu's final sign-off        │
│                                                   │
└─────────────────────────────────────────────────┘
```

---

## When to Use

| Task type | Ralph Wiggum | Evaluator | Why |
|-----------|:---:|:---:|-----|
| New scripts/features | ✅ | ✅ | Code needs both deterministic + subjective QA |
| Autoimprove nightly | ✅ | ✅ | Prevents self-approval bias |
| Documentation (PRD, specs, reports) | ❌ | ✅ | No code to lint, but quality matters |
| System audit | ❌ | ❌ | Auditors ARE the evaluators |
| Config/cron changes | ❌ | ❌ | Directly verifiable |
| Info search / analysis | ❌ | ❌ | No "output" to evaluate |
| Quick fixes (< 5 min tasks) | ❌ | ❌ | Overhead not worth it |

**REGLA ABSOLUTA (Manu, 2026-03-26):** TODAS las tareas de subagentes se evalúan. Sin excepciones. Siempre Generator + Evaluator. El protocolo no es opcional — es obligatorio para cada subagente que produzca output.

**Gestión de slots:** Con 8 subagentes máximo = 4 tareas en paralelo (4 generators + 4 evaluators). Si hay más tareas, se lanzan por oleadas: cuando termina un par generator+evaluator, se lanza el siguiente.

---

## Layer 1: Ralph Wiggum Loop (Deterministic)

Run BEFORE the evaluator. These checks CANNOT lie:

### For Shell Scripts
```bash
bash -n script.sh                    # Syntax check
shellcheck script.sh                 # Style + bugs
chmod +x script.sh                   # Ensure executable
grep -q 'set -euo pipefail' script.sh  # Error handling present
```

### For Python Scripts
```bash
python3 -m py_compile script.py      # Syntax check
python3 -c "import script"           # Import check
```

### For TypeScript/Specs
```bash
npx tsc --noEmit specs/*.ts          # Type check
```

### For Markdown/Docs
```bash
# Check for broken links
grep -oE 'memory/[a-zA-Z0-9_/-]+\.md' file.md | while read f; do
  [ -f "$f" ] || echo "BROKEN: $f"
done
```

**Loop rule:** If deterministic check fails → feed exact error to generator → retry (max 3 iterations).

---

## Layer 2: Adversarial Evaluator (LLM)

A SEPARATE subagent whose ONLY job is to criticize.

### Evaluator System Prompt Template

```
You are a skeptical QA evaluator. Your job is to find problems, NOT praise.

RULES:
- Assume the work is incomplete until proven otherwise
- Score each criteria 1-5 (1=terrible, 3=acceptable, 5=excellent)
- If ANY score < 3, the work FAILS and needs iteration
- Be specific: cite file paths, line numbers, exact issues
- Do NOT say "overall looks good" — find the problems
- Check against existing system standards and best practices

CRITERIA:
[inserted per task type — see below]

OUTPUT FORMAT:
## Evaluation Report

### Scores
| Criteria | Score | Issues |
|----------|-------|--------|

### PASS/FAIL
[PASS if all scores ≥ 3, FAIL otherwise]

### Issues (if FAIL)
1. [Specific issue + how to fix]
2. ...

### Feedback for Generator
[Exact instructions for what to fix]
```

### Criteria by Task Type

#### Code/Scripts
1. **Correctness** — Does it work? Edge cases handled?
2. **Error handling** — set -euo pipefail? What happens when things fail?
3. **Documentation** — Comments, README, usage examples?
4. **Integration** — Fits with existing system? No conflicts?
5. **Security** — No secrets, no unsafe operations, no hardcoded paths?

#### Documentation
1. **Accuracy** — Matches reality? Cross-referenced with actual files?
2. **Completeness** — Anything missing?
3. **Clarity** — Non-technical person understands value?
4. **Consistency** — No contradictions with other docs?
5. **Actionability** — Reader knows what to do next?

#### System Changes (crons, config, architecture)
1. **Necessity** — Is this change actually needed?
2. **Impact** — What else does this affect?
3. **Reversibility** — Can we undo this easily?
4. **Cost** — What does this cost (money, complexity)?
5. **Testing** — Has the change been verified?

---

## Layer 3: Human Approval

After evaluator PASSES, present to Manu:
- Summary of what was built/changed
- Evaluator scores
- Any concerns the evaluator noted (even if passed)
- Ask for approval before committing/deploying

---

## Iteration Flow

```
Generator produces work
    ↓
Ralph Wiggum checks (if code)
    ↓ FAIL? → feed errors → Generator retries (max 3)
    ↓ PASS
Evaluator critiques (scores 1-5)
    ↓ ANY score < 3? → feed feedback → Generator retries (max 2)
    ↓ ALL scores ≥ 3
Present to Manu
    ↓ Approved? → commit + deploy
    ↓ Changes requested? → Generator iterates
```

**Max total iterations:** 5 (3 Ralph Wiggum + 2 Evaluator)
**If still failing after 5:** Escalate to Manu with full context.

---

## Cost Model

| Role | Model | Why |
|------|-------|-----|
| Generator | Sonnet | Good enough for most work |
| Ralph Wiggum | N/A (bash tools) | Free — deterministic checks |
| Evaluator | Sonnet | Skepticism doesn't need Opus |
| Generator (critical) | Opus | Only for complex architecture decisions |
| Evaluator (critical) | Opus | Only when evaluating Opus-generated critical work |

**Estimated overhead per task:** ~$0.10-0.30 for evaluator (Sonnet)
**ROI:** Catches issues before they reach production → saves debug time + prevents costly mistakes

---

## Integration with Existing System

### Autoimprove Nightly
Each autoimprove agent (scripts/skills/memory) should:
1. Make change
2. Run Ralph Wiggum (shellcheck, syntax)
3. Self-evaluate with stricter criteria
4. Only commit if passes

### Subagent Spawning
When Lola spawns subagents for "gordo" tasks:
1. Spawn generator
2. When generator completes → run Ralph Wiggum checks
3. Spawn evaluator with generator output
4. If evaluator fails → spawn new generator with feedback
5. Present final result to Manu

### Cron-Created Scripts
Any script created by a cron or subagent MUST pass:
- `bash -n` (syntax)
- `shellcheck` (quality)
- Has `set -euo pipefail`
- No hardcoded `/home/mleon` (use $HOME)
- No secrets in code

---

## References

- Anthropic: "Building effective agents for long-running tasks" (March 2026)
- Jeffrey Huntley: Ralph Wiggum Loop concept
- `memory/ralph-wiggum-loop.md` — Full explainer
- `memory/prompt-writing-guide.md` — Model-specific prompt optimization

---

**Last updated:** 2026-03-26
