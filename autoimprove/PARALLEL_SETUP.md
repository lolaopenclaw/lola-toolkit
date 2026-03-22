# Parallel Autoimprove Setup — Phase 2.3

**Implemented:** 2026-03-22  
**Status:** Active (3 agents running nightly)

## Overview

Transformed autoimprove from **1 agent, 10 iterations/night** to **3 specialized agents, 45+ iterations/night**.

## Architecture

### Agent 1: Scripts (3:00 AM)
- **ID:** dcae7b06-e6fb-40d4-88bc-9bc618feb70d
- **Instructions:** `autoimprove/nightly-scripts.md`
- **Focus:** `/home/mleon/.openclaw/workspace/scripts/*.sh`
- **Program:** `programs/backup-speed`
- **Metrics:** execution time + error handling + code quality
- **Max iterations:** 15/night

### Agent 2: Skills (3:05 AM)
- **ID:** 8d65b575-5023-4160-bbc3-45ac449f17d3
- **Instructions:** `autoimprove/nightly-skills.md`
- **Focus:** HEARTBEAT.md, AGENTS.md, skills documentation
- **Programs:** `programs/heartbeat-efficiency`, `programs/agents-tokens`
- **Metrics:** token count + clarity + actionability
- **Max iterations:** 15/night

### Agent 3: Memory (3:10 AM)
- **ID:** 881d2943-dc39-4bf4-b1cf-6344ff6bbf53
- **Instructions:** `autoimprove/nightly-memory.md`
- **Focus:** MEMORY.md index, memory/*.md organization
- **Program:** `programs/memory-index`
- **Metrics:** token count + index coverage + duplication
- **Max iterations:** 15/night
- **Special:** Sunday cleanup (archive old files, reindex)

## Key Features

✅ **Parallel execution:** 3 agents run simultaneously (staggered 5min apart)  
✅ **Specialized targets:** Each agent focuses on its domain  
✅ **Experiment logging:** Every test logged to `experiment-log.jsonl`  
✅ **Cost aware:** Haiku model (~$0.15/night total)  
✅ **Safe:** No cross-contamination between agents  
✅ **Delivery:** Best-effort Telegram delivery to 6884477  

## Experiment Protocol (All Agents)

1. Read context and program.md
2. Run baseline eval.sh (composite score)
3. If score already low → SKIP
4. Propose small change
5. Apply change
6. Run eval.sh → new score
7. Log experiment: `bash autoimprove/log-experiment.sh <target> "<change>" <before> <after> <kept|discarded>`
8. If improved → KEEP (git commit)
9. If worse → DISCARD (restore)
10. Repeat up to 15 iterations
11. Report summary

## Safety Rules

**Scripts Agent:**
- NEVER remove error handling
- NEVER introduce dangerous patterns (rm -rf /, sudo rm)
- Syntax check must pass

**Skills Agent:**
- NEVER remove required section headers
- NEVER remove critical keywords
- Must preserve all functionality

**Memory Agent:**
- NEVER remove critical system knowledge
- NEVER remove recent events (< 30 days)
- Must preserve index coverage

## Monitoring

### Check cron status
```bash
openclaw cron list | grep "Autoimprove"
```

### View experiment log
```bash
cat autoimprove/experiment-log.jsonl | tail -20
```

### Dashboard (weekly summary)
```bash
bash autoimprove/dashboard.sh
```

### Run history
```bash
openclaw cron runs --id dcae7b06-e6fb-40d4-88bc-9bc618feb70d --limit 5
openclaw cron runs --id 8d65b575-5023-4160-bbc3-45ac449f17d3 --limit 5
openclaw cron runs --id 881d2943-dc39-4bf4-b1cf-6344ff6bbf53 --limit 5
```

## Manual Override

To run a specific agent manually:
```bash
# Scripts
cat autoimprove/nightly-scripts.md

# Skills
cat autoimprove/nightly-skills.md

# Memory
cat autoimprove/nightly-memory.md

# Original unified (fallback)
cat autoimprove/nightly.md
```

## Cost Estimate

| Agent | Model | Est. Cost/Night |
|-------|-------|----------------|
| Scripts | Haiku | ~$0.05 |
| Skills | Haiku | ~$0.05 |
| Memory | Haiku | ~$0.05 |
| **Total** | | **~$0.15/night** |

**Monthly:** ~$4.50  
**3x increase** from previous $0.05/night (1 agent)

## Success Metrics

Target (Phase 2 goals):
- ✅ 50+ experiments/night (currently 45 max, will scale)
- ✅ 15+ improvements/week
- ✅ Composite eval.sh metrics
- ✅ Experiment log (JSONL)
- ✅ Dashboard for weekly review

## Legacy

**Disabled cron:** 6018f037-1d26-4322-874e-d256c295a5b4 (old unified autoimprove)  
**Preserved file:** `autoimprove/nightly.md` (fallback/manual)

## Next Steps (Phase 2.4+)

- [ ] Apply "loop gordo" to lola-toolkit repo (100+ experiments)
- [ ] Dashboard visualization (Canvas or formatted text)
- [ ] Multi-agent collaboration (agents suggest targets to each other)
- [ ] Adaptive iteration count (more iterations if high success rate)

---

*Part of Master Plan Phase 2.3 (memory/2026-03-22-master-plan.md)*
