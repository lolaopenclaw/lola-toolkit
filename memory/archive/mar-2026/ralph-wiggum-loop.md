# The Ralph Wiggum Loop

**Author:** Jeffrey Huntley
**Concept:** A pattern for making AI agents reliable by checking their work against something that **can't lie**.

---

## The Problem

When an AI agent builds something (code, document, config), it tends to:
- Declare "done" when it's not actually done
- Self-approve mediocre work
- Skip edge cases
- Overestimate quality of its own output

Asking the AI "is your work good?" is useless — it will almost always say yes. This is Anthropic's "poor self-evaluation" problem.

## The Solution: Loop Against Truth

The Ralph Wiggum Loop puts the agent in a **loop** where each iteration is checked against something **objective and deterministic** — something that literally cannot lie:

```
while true:
  1. Agent does work
  2. Run verifier (linter, type checker, test suite, etc.)
  3. If verifier passes → DONE
  4. If verifier fails → feed errors back to agent → goto 1
```

The name comes from Ralph Wiggum (The Simpsons) — the idea is even a "dumb" loop can produce great results if the verification is solid.

## Why It Works

The key insight is **separating generation from verification**:

| Generation (AI) | Verification (Deterministic) |
|---|---|
| Creative, non-deterministic | Rule-based, can't lie |
| Can hallucinate | Only reports facts |
| Biased toward "done" | Only passes if criteria met |
| Gets worse under pressure | Consistent every time |

The AI does the creative work. The verifier is the honest judge.

## Examples of Verifiers

| Task | Verifier | What it checks |
|---|---|---|
| Code | `shellcheck`, linter | Syntax, style, common bugs |
| Code | Test suite | Functional correctness |
| Code | Type checker (`tsc`) | Type safety |
| Code | Build system | Does it compile? |
| Config | Schema validator | Valid JSON/YAML? |
| API | HTTP status codes | Does endpoint respond? |
| Script | Exit code | Did it run without error? |
| Documentation | Link checker | No broken links? |
| Security | `git secrets` | No leaked tokens? |

## Comparison with Other Patterns

### vs. Adversarial Evaluation (Anthropic)
- **Ralph Wiggum:** Loop against deterministic tools (linters, tests)
- **Adversarial:** Loop against another LLM (evaluator agent)
- **Best:** Combine both — deterministic checks first, then LLM evaluation for subjective quality

### vs. Simple Retry
- **Simple retry:** "Try again" with no feedback
- **Ralph Wiggum:** "Try again, and here's exactly what failed" — targeted iteration

### vs. Human-in-the-Loop
- **HITL:** Human checks every step (slow, expensive)
- **Ralph Wiggum:** Automated checks, human only at the end (fast, cheap)

## How It Combines with Spec-Driven Development

This is where it gets powerful:

```
1. Define spec (OpenSpec, SpecKit, BMAD)
2. Generate code from spec
3. Run Ralph Wiggum Loop:
   - Lint → fix
   - Type check → fix
   - Test suite (generated from spec) → fix
   - Integration tests → fix
4. Run adversarial evaluator (LLM) for subjective quality
5. Done
```

The spec gives the agent a clear target. The loop ensures it actually hits it.

## Practical Example (Our System)

How we could apply this to a script:

```bash
# 1. Agent writes backup-memory.sh
# 2. Verifier chain:
bash -n scripts/backup-memory.sh          # Syntax check
shellcheck scripts/backup-memory.sh        # Style + bugs
bash scripts/backup-memory.sh --dry-run    # Functional test
# 3. If any fails → feed error to agent → iterate
# 4. If all pass → commit
```

## Limitations

- Only works for **objectively verifiable** tasks
- Subjective quality (design, writing style, UX) needs adversarial evaluation instead
- Can get stuck in infinite loops if the verifier is too strict or the task is impossible
- Need a **max iterations** cap (usually 5-15)

## The Full Picture

```
┌─────────────────────────────────────────────┐
│           Complete Quality Pipeline           │
├─────────────────────────────────────────────┤
│                                               │
│  1. Spec (OpenSpec) → defines what to build   │
│  2. Generator Agent → does the work           │
│  3. Ralph Wiggum Loop → deterministic checks  │
│     - linter, tests, type checker             │
│     - loop until all pass (max 10 iterations) │
│  4. Adversarial Evaluator → subjective checks │
│     - quality, completeness, edge cases       │
│  5. Human approval → final sign-off           │
│                                               │
└─────────────────────────────────────────────┘
```

---

## References

- **Jeffrey Huntley** — Original concept
- **Anthropic Blog** — "Building effective agents for long-running tasks" (March 2026)
- **OpenSpec / SpecKit / BMAD** — Spec-Driven Development frameworks
- **Video:** "Anthropic harness design for long-running agents" (9d5bzxVsocw)

---

**Last updated:** 2026-03-26
