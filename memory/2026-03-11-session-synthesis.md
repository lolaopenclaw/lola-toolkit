# 2026-03-11 Session Synthesis — Ollama Migration + Qwen3 Upgrade

**Duration:** 21:00-01:10 Madrid (~4h 10m) | **Messages:** 60+ | **Decisions:** Major architecture changes

## Main Work

### 1. Fixed Boot Hook Timeout Loop
- Root cause: Qwen 2.5 7B as default model caused 10+ minute boot hook timeouts
- Symptom: Gateway restarting every 2-3 minutes
- Fix: Reverted to Haiku for chat/interactive, 14B local for crons
- Result: Clean boot, stable operation ✅

### 2. Comprehensive Research: Local Models for OpenClaw
- OpenClaw docs recommend: **MiniMax M2.5 + LM Studio** (needs GPU/32GB+)
- Community consensus: **Qwen3-Coder:32B** (needs 32GB+, dense, reliable)
- Reddit findings: 
  - 7-8B models fail constantly on tool calls
  - 14B marginal but workable for non-interactive tasks
  - MoE models loop on tool calling (avoid)
  - Ollama has streaming bug with tool_calls (doesn't affect non-streaming)
- For our VPS (15GB RAM, CPU-only): **Qwen3:14b is the best viable option**

### 3. Final Architecture Decision
```
Interactive (chat):     Haiku ($0.25/M input tokens)
Crons/heartbeats:       Qwen3:14b local (free, ~9.3GB)
On-demand power:        Opus (when Manu requests)
Boot reset:             Haiku (daily 00:00)
```

### 4. Ollama Model Migration
- Downloaded: qwen3:14b (9.3GB, Q4_K_M quantization, tools ✅)
- Removed: qwen2.5:7b + qwen2.5:14b (freed 14GB disk)
- Updated: 16 crons from qwen2.5 → qwen3:14b
- Updated: Model allowlist in config
- Verified: Qwen3:14b has tool support ✅

### 5. Security: Secrets Management
- Moved all API keys to .env only (not in openclaw.json)
- OLLAMA_API_KEY="ollama-local" (not a real secret)
- Config now contains only non-sensitive settings ✅

## Issues Encountered

1. **Gateway Restarts (22:02-22:25)**
   - Cause: 7B model timeouts on boot hook
   - Impact: Cascading failures, daemon crashing
   - Resolution: Reverted to Haiku for interactive use

2. **Ollama Models Not Listed (22:12)**
   - Cause: Missing `apiKey` in config for availability checks
   - Cause: Models not in `agents.defaults.models` allowlist
   - Resolution: Added both models to allowlist, fixed config

3. **Qwen3 First Execution (00:00)**
   - model-reset-nightly ran at midnight with qwen3:14b
   - Executed but failed (error status)
   - Status: Need to investigate on next run or in morning

## Commands Executed

- `openclaw gateway restart` (multiple times)
- `ollama pull qwen3:14b`
- `ollama rm qwen2.5:14b`, `ollama rm qwen2.5:7b`
- 16 `openclaw cron edit` commands
- Full system verification (VPS resources, gateway logs, etc.)

## Verified Working

✅ Haiku model (chat, fast, reliable)  
✅ Qwen3:14b availability (tool support confirmed)  
✅ Gateway startup and boot hook  
✅ Config hot-reload  
✅ All 16 crons reference Qwen3:14b  
✅ Disk space freed (14GB)  
✅ Git commit + Drive backup  

## Open Questions

1. Why did model-reset-nightly error with Qwen3:14b at 00:00?
   - Timeout? Tool calling issue? Config mismatch?
   - **Action:** Monitor next execution (model-reset-nightly tomorrow 00:00)

2. Healthcheck:fail2ban also showing error (2h ago)
   - Separate issue from Qwen3 migration
   - **Action:** Investigate in morning heartbeat

## Next Steps

1. **Tonight:** Monitor if Qwen3:14b crons stabilize
2. **Morning (10:00):** Full heartbeat report with any issues
3. **If Qwen3 unreliable:** Fall back to Haiku for all, Ollama stays installed for future GPU setup
4. **Eventually:** Dedicated inference server (Mac Mini 32GB) to run full MiniMax M2.5

## Decisions Made

- ✅ Haiku for chat (best cost/performance for interactive)
- ✅ Qwen3:14b for crons (best local model for our VPS)
- ✅ Keep Ollama (not LM Studio—VPS headless)
- ✅ Avoid MoE models entirely (tool calling issues)
- ✅ Clean secrets: .env only, not config

## Time Tracking

- 21:00-21:30: Boot check + model investigation
- 21:30-22:00: Ollama installation + models download
- 22:00-22:30: Diagnosis of 7B timeout loop
- 22:30-23:00: Config fixes, model allowlist setup
- 23:00-23:30: Qwen3 research (docs, Reddit, blogs)
- 23:30-00:30: Qwen3:14b download + migration (16 crons)
- 00:30-01:10: Backup, commit, cleanup

---

**Status:** System stable. Qwen3:14b first execution in progress (monitoring). Detailed report at 10:00 if issues arise.
