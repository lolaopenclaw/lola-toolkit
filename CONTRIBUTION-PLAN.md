# OpenClaw Contribution Plan

## Overview

Strategy for contributing back to the OpenClaw community with tools and frameworks developed during real-world usage on a personal VPS setup.

## Contributions (Priority Order)

| # | Contribution | Why First | Effort | Impact |
|---|-------------|-----------|--------|--------|
| 1 | **Skill Security Audit** | Already generic, smallest scope | Low | High |
| 2 | **Memory Management** | Most universally useful | Medium | High |
| 3 | **Critical Update Framework** | DevOps value, partially generic | Medium | Medium |
| 4 | **Recovery System** | Valuable but needs most genericization | High | High |
| 5 | **Health Monitoring (Garmin)** | Niche but unique, needs Garmin account | Medium | Low-Medium |

## Current State Assessment

### ✅ Already Generic
- `skill-security-audit.sh` — Uses `$OPENCLAW_WORKSPACE` env var, clean structure

### ⚠️ Partially Generic (needs minor work)
- `critical-update.sh` — Uses `$WORKSPACE` but defaults to hardcoded path
- `semantic-search.sh` / `semantic-search.js` — Needs env var defaults

### ❌ Hardcoded (needs significant work)
- `memory-guardian.sh` — Hardcoded `/home/mleon/.openclaw/workspace`
- `restore.sh` — User-specific paths, Spanish docs
- `garmin-health-report.sh` — Tightly coupled to specific `.env` layout

## Genericization Checklist

For every script:
- [ ] Replace hardcoded paths → `${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}`
- [ ] Replace hardcoded user paths → `${HOME}` or configurable
- [ ] Translate comments/output to English (keep Spanish as optional)
- [ ] Add `--help` flag with usage examples
- [ ] Add configuration file support (optional `.env` or config)
- [ ] Remove any personal data references
- [ ] Test on clean Ubuntu 22.04+ environment

## PR Strategy

### Before Any PR
1. **Research** — Check OpenClaw GitHub for:
   - Existing similar features
   - Open issues requesting these features
   - Contributing guidelines (CONTRIBUTING.md)
   - Code style and conventions
2. **Engage** — Open a Discussion or Issue first:
   - "Would the community benefit from X?"
   - Share the problem it solves
   - Get maintainer buy-in before coding

### PR Structure (One per Feature)
Each PR should include:
- `scripts/<tool-name>.sh` — The tool itself
- `docs/<tool-name>.md` — Documentation with examples
- Tests (if test framework exists)
- Updated README if applicable

### PR Order
1. **Skill Security Audit** — Cleanest, smallest, most immediately useful
2. **Memory Guardian** — After genericizing, high value for all users
3. **Critical Update** — DevOps-focused users will appreciate
4. **Recovery** — Complex but important for reliability
5. **Garmin Health** — Optional/niche, last priority

## Timeline

| Week | Action |
|------|--------|
| 1 | Research OpenClaw repo, issues, community culture |
| 1 | Fork repo, set up development environment |
| 2 | Genericize skill-security-audit.sh, write English docs |
| 2 | Open first Discussion/Issue for skill security |
| 3 | Submit first PR (skill security) |
| 3 | Start genericizing memory-guardian.sh |
| 4+ | Iterate on feedback, continue with next PRs |

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Maintainers don't want these features | Open Discussion first, don't invest time before buy-in |
| Code style doesn't match | Study existing codebase first, follow their patterns |
| Too many PRs at once | One at a time, wait for merge before next |
| Breaking changes in OpenClaw | Keep contributions modular, no core changes |

## Success Criteria

- [ ] At least 1 PR merged
- [ ] Positive maintainer feedback
- [ ] Other users adopting the tools
- [ ] Established as a trusted contributor
