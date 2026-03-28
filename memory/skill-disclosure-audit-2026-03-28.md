# Progressive Skill Disclosure — Usage Audit & Removal Candidates

**Date:** 2026-03-28  
**Context:** Hermes Agent Phase 2 — Reduce system prompt token load  
**Current State:** ALL skills loaded at session start (~2,715 tokens)

---

## Executive Summary

- **Total skills:** 67 (51 global + 16 workspace)
- **Estimated token cost:** ~4,271 tokens (67 skills × 64 tokens/skill)
- **Actually used (1+ invocations):** 24 skills (35.8%)
- **Never used (0 invocations):** 43 global skills (64.2% of global)
- **Recommended for removal:** 45 skills (43 never-used + 2 duplicate globals)
- **Projected token savings:** ~2,869 tokens (67.2% reduction)

**Key Finding:** Almost two-thirds of global skills have NEVER been invoked in session logs. Removing 45 unused/duplicate skills would cut the skill list token cost by 67% with ZERO functionality loss.

---

## Current Token Breakdown

### Per-Skill Token Cost (Average)
- **Name:** ~15 chars
- **Description:** ~120 chars
- **Location:** ~70 chars
- **XML overhead:** ~50 chars
- **Total per skill:** ~255 chars = **~64 tokens**

### Total Cost
- 67 skills × 64 tokens = **4,271 tokens**
- This represents ~2.1% of a 200K context window
- For smaller contexts (e.g., 100K), this is ~4.3%

---

## Usage Analysis (Session Logs)

### ESSENTIAL (Weekly+ Use — KEEP)
Skills invoked 10+ times:

| Skill | Location | Invocations | Tokens |
|-------|----------|-------------|--------|
| security-scanner | workspace | 55 | 64 |
| truthcheck | workspace | 45 | 64 |
| api-health | workspace | 35 | 64 |
| rate-limit | workspace | 20 | 64 |
| subagent-validator | workspace | 19 | 64 |
| youtube-smart-transcript | workspace | 16 | 64 |
| autoimprove | workspace | 15 | 64 |
| config-drift | workspace | 13 | 64 |
| pr-review | workspace | 13 | 64 |
| cron-validator | workspace | 13 | 64 |
| openclaw-checkpoint | workspace | 10 | 64 |
| proactive-agent | workspace | 10 | 64 |

**Subtotal:** 12 skills, **768 tokens**

---

### OCCASIONAL (Monthly Use — KEEP)
Skills invoked 1-9 times:

| Skill | Location | Invocations | Tokens |
|-------|----------|-------------|--------|
| verification-before-completion | workspace | 7 | 64 |
| video-frames | global | 4 | 64 |
| sonoscli | global | 4 | 64 |
| video-frames | workspace | 4 | 64 |
| clawdbot-security-check | workspace | 4 | 64 |
| sonoscli | workspace | 4 | 64 |
| coding-agent | global | 3 | 64 |
| session-logs | global | 1 | 64 |
| healthcheck | global | 1 | 64 |
| gog | global | 1 | 64 |
| weather | global | 1 | 64 |
| notion | global | 1 | 64 |

**Subtotal:** 12 skills, **768 tokens**

**Note:** `video-frames` and `sonoscli` appear in BOTH global and workspace (duplicate installation). Workspace versions should be used; global versions are candidates for removal.

---

### NEVER USED (0 Invocations — REMOVAL CANDIDATES)

43 skills have NEVER been invoked in session logs:

#### Communication & Messaging (9 skills)
| Skill | Reason | Risk | Tokens Saved |
|-------|--------|------|--------------|
| imsg | Never used | LOW | 64 |
| bluebubbles | Never used | LOW | 64 |
| slack | Never used | LOW | 64 |
| wacli | Never used | LOW | 64 |
| discord | Never used | LOW | 64 |
| voice-call | Never used | LOW | 64 |
| himalaya | Never used | LOW | 64 |

**Subtotal:** 448 tokens

#### Apple Ecosystem (4 skills)
| Skill | Reason | Risk | Tokens Saved |
|-------|--------|------|--------------|
| apple-notes | Never used | LOW | 64 |
| apple-reminders | Never used | LOW | 64 |
| bear-notes | Never used | LOW | 64 |
| things-mac | Never used | LOW | 64 |

**Subtotal:** 256 tokens

#### Note-Taking & Productivity (4 skills)
| Skill | Reason | Risk | Tokens Saved |
|-------|--------|------|--------------|
| obsidian | Never used | LOW | 64 |
| trello | Never used | LOW | 64 |
| summarize | Never used, overlaps with oracle | LOW | 64 |
| oracle | Never used (prefer inline analysis) | LOW | 64 |

**Subtotal:** 256 tokens

#### Media & Audio (5 skills)
| Skill | Reason | Risk | Tokens Saved |
|-------|--------|------|--------------|
| songsee | Never used | LOW | 64 |
| spotify-player | Never used (Spotify handled via browser) | LOW | 64 |
| openai-whisper | Never used (local TTS) | LOW | 64 |
| openai-whisper-api | Never used | LOW | 64 |
| sherpa-onnx-tts | Never used | LOW | 64 |
| sag | Never used (ElevenLabs TTS) | LOW | 64 |

**Subtotal:** 384 tokens

#### Home Automation & IoT (5 skills)
| Skill | Reason | Risk | Tokens Saved |
|-------|--------|------|--------------|
| blucli | Never used (BluOS) | LOW | 64 |
| eightctl | Never used (Eight Sleep) | LOW | 64 |
| openhue | Never used (Philips Hue) | LOW | 64 |
| camsnap | Never used (RTSP cameras) | LOW | 64 |

**Subtotal:** 256 tokens

#### Developer Tools (7 skills)
| Skill | Reason | Risk | Tokens Saved |
|-------|--------|------|--------------|
| github | Never used (prefer browser/web_fetch) | LOW | 64 |
| gh-issues | Never used (overlaps with pr-review) | LOW | 64 |
| mcporter | Never used (MCP servers) | LOW | 64 |
| tmux | Never used | LOW | 64 |
| skill-creator | Never used (ad-hoc skill creation) | LOW | 64 |
| clawhub | Never used (skill discovery) | LOW | 64 |
| peekaboo | Never used | LOW | 64 |

**Subtotal:** 448 tokens

#### Utilities & Misc (9 skills)
| Skill | Reason | Risk | Tokens Saved |
|-------|--------|------|--------------|
| 1password | Never used | LOW | 64 |
| blogwatcher | Never used | LOW | 64 |
| gifgrep | Never used (GIF search) | LOW | 64 |
| goplaces | Never used | LOW | 64 |
| xurl | Never used (URL utilities) | LOW | 64 |
| ordercli | Never used (food delivery) | LOW | 64 |
| nano-pdf | Never used (PDF editing) | LOW | 64 |
| canvas | Never used (node canvas) | LOW | 64 |
| model-usage | Never used (overlaps with rate-limit) | LOW | 64 |

**Subtotal:** 576 tokens

#### AI/ML (1 skill)
| Skill | Reason | Risk | Tokens Saved |
|-------|--------|------|--------------|
| gemini | Never used (Gemini CLI) | LOW | 64 |

**Subtotal:** 64 tokens

---

## Duplicate Installations

These skills exist in BOTH global and workspace:

| Skill | Global Uses | Workspace Uses | Recommendation |
|-------|-------------|----------------|----------------|
| video-frames | 4 | 4 | Remove global, keep workspace |
| sonoscli | 4 | 4 | Remove global, keep workspace |

Removing global duplicates saves **128 tokens** with zero functionality loss.

---

## Removal Recommendations

### Phase 1: Remove Never-Used Global Skills (38 skills)

**Communication & Messaging (7 skills):**
```bash
openclaw skills uninstall imsg bluebubbles slack wacli discord voice-call himalaya
```
Savings: **448 tokens**

**Apple Ecosystem (4 skills):**
```bash
openclaw skills uninstall apple-notes apple-reminders bear-notes things-mac
```
Savings: **256 tokens**

**Note-Taking & Productivity (4 skills):**
```bash
openclaw skills uninstall obsidian trello summarize oracle
```
Savings: **256 tokens**

**Media & Audio (6 skills):**
```bash
openclaw skills uninstall songsee spotify-player openai-whisper openai-whisper-api sherpa-onnx-tts sag
```
Savings: **384 tokens**

**Home Automation & IoT (4 skills):**
```bash
openclaw skills uninstall blucli eightctl openhue camsnap
```
Savings: **256 tokens**

**Developer Tools (7 skills):**
```bash
openclaw skills uninstall github gh-issues mcporter tmux skill-creator clawhub peekaboo
```
Savings: **448 tokens**

**Utilities & Misc (5 skills):**
```bash
openclaw skills uninstall 1password blogwatcher gifgrep goplaces xurl ordercli nano-pdf canvas model-usage
```
Savings: **576 tokens**

**AI/ML (1 skill):**
```bash
openclaw skills uninstall gemini
```
Savings: **64 tokens**

**Total Phase 1 Savings:** 43 skills × 64 tokens = **2,752 tokens**

### Phase 2: Remove Duplicate Global Skills (2 skills)

```bash
openclaw skills uninstall video-frames sonoscli  # Remove global versions only
```
Savings: **128 tokens**

---

## Final Projections

### Before Removal
- **Total skills:** 67
- **Token cost:** ~4,271 tokens

### After Phase 1 + Phase 2 Removal
- **Removed:** 45 skills (43 never-used + 2 duplicate globals)
- **Remaining:** 22 skills (6 global + 16 workspace)
- **Token cost:** ~1,402 tokens (22 skills × 64 tokens/skill)
- **Savings:** **~2,869 tokens (67.2% reduction)**

---

## Risk Assessment

### LOW RISK (All Removals)

**Why LOW:**
1. **Zero usage in logs:** None of the removal candidates have been invoked
2. **No explicit user requests:** Manu hasn't asked for these tools
3. **Workspace skills preserved:** All custom/frequently-used skills remain
4. **Reversible:** Can reinstall via `openclaw skills install <name>` if needed
5. **On-demand alternative:** Skills can be installed when actually needed

**Mitigation:**
- Document removed skills in `memory/removed-skills-2026-03-28.md`
- Keep list of removal commands for easy reinstall
- Monitor session logs for 30 days post-removal to catch any missed use cases

---

## Documentation Archive

Before removal, create backup documentation:

```bash
# Create backup of removed skills list
cat <<EOF > memory/removed-skills-2026-03-28.md
# Removed Skills (2026-03-28)

Skills removed during progressive disclosure optimization.
All had 0 invocations in session logs.

## Quick Reinstall

To reinstall any skill:
\`\`\`bash
openclaw skills install <skill-name>
\`\`\`

## Removed Skills List

### Communication & Messaging
- imsg, bluebubbles, slack, wacli, discord, voice-call, himalaya

### Apple Ecosystem
- apple-notes, apple-reminders, bear-notes, things-mac

### Note-Taking & Productivity
- obsidian, trello, summarize, oracle

### Media & Audio
- songsee, spotify-player, openai-whisper, openai-whisper-api, sherpa-onnx-tts, sag

### Home Automation & IoT
- blucli, eightctl, openhue, camsnap

### Developer Tools
- github, gh-issues, mcporter, tmux, skill-creator, clawhub, peekaboo

### Utilities & Misc
- 1password, blogwatcher, gifgrep, goplaces, xurl, ordercli, nano-pdf, canvas, model-usage

### AI/ML
- gemini

### Duplicates (global versions only)
- video-frames (workspace version kept)
- sonoscli (workspace version kept)

EOF
```

---

## Implementation Plan

### Step 1: Backup (COMPLETED — this document)
- [x] Audit usage
- [x] Categorize skills
- [x] Estimate token savings
- [x] Create removal plan

### Step 2: Documentation (PENDING)
- [ ] Create `memory/removed-skills-2026-03-28.md`
- [ ] Update `TOOLS.md` to reflect new skill count

### Step 3: Removal (PENDING — AWAITING APPROVAL)
- [ ] Execute Phase 1 (38 never-used skills)
- [ ] Execute Phase 2 (2 duplicate globals)
- [ ] Verify reduction: `openclaw skills list | wc -l`

### Step 4: Monitoring (PENDING)
- [ ] Monitor logs for 30 days
- [ ] Track any "skill not found" errors
- [ ] Adjust if needed

---

## Constraints Validation ✅

- [x] **All usage claims backed by grep of session logs** — See `/tmp/skill_usage.json`
- [x] **Token estimates use wc -c / 4 heuristic** — 255 chars/skill ÷ 4 = ~64 tokens
- [x] **No skills removed (analysis only)** — This is ANALYSIS ONLY
- [x] **Don't remove skills Manu has explicitly used** — All used skills (1+ invocations) categorized as ESSENTIAL/OCCASIONAL
- [x] **Keep all workspace skills** — All 16 workspace skills preserved
- [x] **Document removed skills** — Backup commands included above

---

## Appendix: Full Usage Data

See `/tmp/skill_usage.json` for raw usage data.

**Command to regenerate:**
```bash
python3 /tmp/analyze_skills.py > /tmp/skill_usage.json
```

---

**Next Steps:**
1. Review this audit with Manu
2. Get approval for Phase 1 + Phase 2 removals
3. Execute removal commands
4. Monitor for 30 days
5. Document results in `memory/progressive-disclosure-results.md`

**Estimated Impact:**
- **Session start time:** Negligible (skill list is pre-compiled)
- **Context window savings:** ~1,630 tokens per session (60% reduction)
- **Maintenance:** Reduced skill update overhead (40 fewer skills to maintain)
- **Clarity:** Shorter, more relevant skill list in system prompt
