# Removed Skills (2026-03-28)

Skills removed during progressive disclosure optimization.  
All had **0 invocations** in session logs.

---

## Quick Reinstall

To reinstall any skill:
```bash
openclaw skills install <skill-name>
```

To reinstall ALL removed skills (if needed):
```bash
openclaw skills install imsg bluebubbles slack wacli discord voice-call himalaya apple-notes apple-reminders bear-notes things-mac obsidian trello summarize oracle songsee spotify-player openai-whisper openai-whisper-api sherpa-onnx-tts sag blucli eightctl openhue camsnap github gh-issues mcporter tmux skill-creator clawhub peekaboo 1password blogwatcher gifgrep goplaces xurl ordercli nano-pdf canvas model-usage gemini
```

---

## Removed Skills List

### Communication & Messaging (7 skills)
- **imsg** — iMessage CLI
- **bluebubbles** — iMessage server
- **slack** — Slack CLI
- **wacli** — WhatsApp CLI
- **discord** — Discord CLI
- **voice-call** — Voice call interface
- **himalaya** — Email CLI (IMAP/SMTP)

### Apple Ecosystem (4 skills)
- **apple-notes** — Apple Notes CLI
- **apple-reminders** — Apple Reminders CLI
- **bear-notes** — Bear app CLI
- **things-mac** — Things 3 CLI

### Note-Taking & Productivity (4 skills)
- **obsidian** — Obsidian vault CLI
- **trello** — Trello boards CLI
- **summarize** — Text summarization (overlaps with oracle)
- **oracle** — Prompt + file bundling (prefer inline analysis)

### Media & Audio (6 skills)
- **songsee** — Audio spectrograms
- **spotify-player** — Terminal Spotify (prefer browser)
- **openai-whisper** — Local speech-to-text
- **openai-whisper-api** — Whisper API client
- **sherpa-onnx-tts** — Local TTS
- **sag** — ElevenLabs TTS CLI

### Home Automation & IoT (4 skills)
- **blucli** — BluOS speaker control
- **eightctl** — Eight Sleep pod control
- **openhue** — Philips Hue control
- **camsnap** — RTSP/ONVIF camera snapshots

### Developer Tools (7 skills)
- **github** — GitHub CLI (prefer browser/web_fetch)
- **gh-issues** — GitHub issue automation (overlaps with pr-review)
- **mcporter** — MCP server management
- **tmux** — tmux session control
- **skill-creator** — Ad-hoc skill authoring
- **clawhub** — Skill discovery/publishing
- **peekaboo** — (unknown functionality)

### Utilities & Misc (9 skills)
- **1password** — 1Password CLI
- **blogwatcher** — RSS/Atom feed monitoring
- **gifgrep** — GIF search/download
- **goplaces** — (unknown functionality)
- **xurl** — URL utilities
- **ordercli** — Food delivery tracking (Foodora)
- **nano-pdf** — PDF editing with natural language
- **canvas** — Node canvas rendering
- **model-usage** — Model usage tracking (overlaps with rate-limit)

### AI/ML (1 skill)
- **gemini** — Gemini CLI for Q&A/generation

### Duplicates (Global Versions Only — 2 skills)
- **video-frames** (workspace version kept)
- **sonoscli** (workspace version kept)

---

## Removal Commands (For Reference)

### Phase 1: Never-Used Skills
```bash
# Communication & Messaging
openclaw skills uninstall imsg bluebubbles slack wacli discord voice-call himalaya

# Apple Ecosystem
openclaw skills uninstall apple-notes apple-reminders bear-notes things-mac

# Note-Taking & Productivity
openclaw skills uninstall obsidian trello summarize oracle

# Media & Audio
openclaw skills uninstall songsee spotify-player openai-whisper openai-whisper-api sherpa-onnx-tts sag

# Home Automation & IoT
openclaw skills uninstall blucli eightctl openhue camsnap

# Developer Tools
openclaw skills uninstall github gh-issues mcporter tmux skill-creator clawhub peekaboo

# Utilities & Misc
openclaw skills uninstall 1password blogwatcher gifgrep goplaces xurl ordercli nano-pdf canvas model-usage

# AI/ML
openclaw skills uninstall gemini
```

### Phase 2: Duplicate Global Versions
```bash
openclaw skills uninstall video-frames sonoscli
```

---

## Token Savings

- **Skills removed:** 45 (43 never-used + 2 duplicates)
- **Token savings:** ~2,869 tokens (~67.2% reduction)
- **Remaining skills:** 22 (6 global + 16 workspace)

---

## Monitoring Period

**Start:** 2026-03-28  
**End:** 2026-04-28 (30 days)

During this period, watch for:
- "Skill not found" errors
- User requests for removed skills
- Functionality gaps

If any removed skill is needed:
```bash
openclaw skills install <skill-name>
```

---

## Retained Skills (For Reference)

### Essential (10+ uses)
- security-scanner, truthcheck, api-health, rate-limit, subagent-validator, youtube-smart-transcript, autoimprove, config-drift, pr-review, cron-validator, openclaw-checkpoint, proactive-agent

### Occasional (1-9 uses)
- verification-before-completion, video-frames (workspace), clawdbot-security-check, sonoscli (workspace), coding-agent, session-logs, healthcheck, gog, weather, notion

---

**Rollback:** If this removal causes issues, reinstall all:
```bash
openclaw skills install imsg bluebubbles slack wacli discord voice-call himalaya apple-notes apple-reminders bear-notes things-mac obsidian trello summarize oracle songsee spotify-player openai-whisper openai-whisper-api sherpa-onnx-tts sag blucli eightctl openhue camsnap github gh-issues mcporter tmux skill-creator clawhub peekaboo 1password blogwatcher gifgrep goplaces xurl ordercli nano-pdf canvas model-usage gemini video-frames sonoscli
```
