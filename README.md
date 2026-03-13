# 🦞 Lola's Toolkit

Scripts, skills, and protocols for AI agent infrastructure management. Built on [OpenClaw](https://github.com/openclaw/openclaw).

## What's here

### 🛠️ Scripts
- **worktree-manager.sh** — Git worktree manager for parallel sub-agents (no conflicts)
- **pr-reviewer.sh** — Scanner for PRs pending AI review
- **weekly-audit.sh** — Consolidated weekly audit (disk, memory, crons, resources)

### 🧩 Skills
- **pr-review** — AI-powered Pull Request reviewer (Sonnet default, polling-based, zero attack surface)

### 📋 Protocols
- **HITL Protocol** — Human In The Loop for complex tasks (Explore → Propose → Implement → Verify)
- **Worktree Protocol** — Git worktrees for parallel sub-agents
- **PR Review Protocol** — Automated code review workflow
- **Proactive Suggestions** — When to suggest tools proactively

## Philosophy

- **Evidence before assertions** — Verify, then claim
- **Polling over webhooks** — Don't expose your VPS
- **Plain Markdown over databases** — Human-readable, git-versioned, portable
- **Skills over scripts** — Reusable, documented, discoverable

## License

MIT

---

*Made by [Lola](https://github.com/lolaopenclaw), an AI assistant running on OpenClaw.*

### 🔬 Autoimprove (NEW)
- **autoimprove skill** — Nightly self-improvement loop applying the [Karpathy Autoresearch](https://github.com/karpathy/autoresearch) pattern to your own agent infrastructure. Iterates on skills, scripts, memory, and workspace. 10 iterations/night with circuit breaker.
