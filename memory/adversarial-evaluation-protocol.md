# Adversarial Evaluation Protocol

**Created:** 2026-03-26
**Source:** Anthropic's harness design for long-running agents (March 2026)

---

## When to Use

| Task type | Evaluator? | Why |
|-----------|-----------|-----|
| New scripts/features | ✅ Yes | Code needs QA |
| Autoimprove nightly | ✅ Yes | Prevents self-approval bias |
| Documentation (PRD, specs) | ✅ Yes | Subjective quality |
| Config/cron changes | ❌ No | Directly verifiable |
| Info search / analysis | ❌ No | No "output" to evaluate |

## Pattern

```
1. Generator subagent → produces work
2. Evaluator subagent → critiques with objective criteria (scores 1-5)
3. If score < 3 on any criteria → Generator gets feedback, iterates
4. If all scores ≥ 3 → Deliver to user
```

## Evaluator Prompt Template

The evaluator MUST:
- Be skeptical by default (assume work is incomplete)
- Use gradable criteria (1-5 scores), never just "looks good"
- Check for: completeness, correctness, edge cases, documentation, error handling
- Reference existing standards (best practices, style guides)
- NOT praise — only identify problems and score

## Criteria by Task Type

### Code/Scripts
1. **Correctness** — Does it work? Edge cases handled?
2. **Error handling** — What happens when things fail?
3. **Documentation** — Comments, README, usage examples?
4. **Integration** — Fits with existing system? No conflicts?
5. **Security** — No secrets, no unsafe operations?

### Documentation
1. **Accuracy** — Matches reality?
2. **Completeness** — Anything missing?
3. **Clarity** — Non-technical person understands value?
4. **Consistency** — No contradictions with other docs?
5. **Actionability** — Reader knows what to do next?

### System Audit
1. **Coverage** — All areas examined?
2. **Evidence** — Claims backed by data/examples?
3. **Prioritization** — Issues ranked by impact?
4. **Actionability** — Clear fix for each finding?
5. **Honesty** — Not sugar-coating problems?

## Cost Optimization

- Generator: Sonnet (good enough for most work)
- Evaluator: Sonnet (skepticism doesn't need Opus)
- Only use Opus for evaluating Opus-generated work on critical tasks
