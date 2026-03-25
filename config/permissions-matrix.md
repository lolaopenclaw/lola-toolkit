# Permissions Matrix - OpenClaw Security Audit

**Generated:** 2026-03-24  
**Purpose:** Document tool/skill permissions to identify excessive access and security risks

---

## Core Tools (Built-in)

| Tool | Read | Write | Execute | Network | Elevated | Risk Level | Notes |
|------|------|-------|---------|---------|----------|------------|-------|
| `read` | ✅ Full FS | ❌ | ❌ | ❌ | ❌ | 🟡 Medium | Can read sensitive files (~/.ssh, ~/.env) |
| `write` | ❌ | ✅ Full FS | ❌ | ❌ | ❌ | 🟠 High | Can overwrite any file, no trash safety |
| `edit` | ✅ Target file | ✅ Target file | ❌ | ❌ | ❌ | 🟡 Medium | Safer than write (precise edits only) |
| `exec` | ❌ | ❌ | ✅ Shell | ✅ Indirect | ⚠️ Optional | 🔴 Critical | Full shell access, approval system present |
| `process` | ❌ | ✅ stdin | ✅ Control | ❌ | ❌ | 🟠 High | Manage background processes |
| `browser` | ✅ DOM | ✅ Forms | ✅ JS eval | ✅ Full web | ❌ | 🟠 High | Can interact with authenticated sessions |
| `canvas` | ✅ Render | ❌ | ✅ JS eval | ✅ URLs | ❌ | 🟡 Medium | Node canvas control |
| `message` | ❌ | ✅ External | ❌ | ✅ Telegram/Discord | ❌ | 🟠 High | Can send messages as user |
| `image` | ✅ Images | ❌ | ❌ | ✅ Vision API | ❌ | 🟢 Low | Read-only vision analysis |
| `image_generate` | ❌ | ✅ Media dir | ❌ | ✅ Gen API | ❌ | 🟢 Low | Generates images, limited write scope |
| `pdf` | ✅ PDFs | ❌ | ❌ | ✅ LLM API | ❌ | 🟢 Low | Read-only PDF analysis |
| `web_search` | ❌ | ❌ | ❌ | ✅ Brave API | ❌ | 🟢 Low | Search only, no write |
| `web_fetch` | ✅ HTTP | ❌ | ❌ | ✅ HTTP | ❌ | 🟢 Low | Fetch content, no execution |
| `tts` | ❌ | ✅ Audio gen | ❌ | ✅ TTS API | ❌ | 🟢 Low | Text-to-speech only |
| `sessions_yield` | ❌ | ❌ | ❌ | ❌ | ❌ | 🟢 Low | Control flow only |

---

## Skills (Subset Analysis)

### 🔴 Critical Risk (Full System Access)

| Skill | Permissions | Risk Vector | Mitigation |
|-------|-------------|-------------|------------|
| `coding-agent` | Full workspace, exec, git | Malicious code injection, data exfil | ✅ Sandboxed, no ~/clawd access |
| `openclaw-checkpoint` | Read/write workspace, git, cron | Config tampering, credential leak | ✅ Git remote required, SSH keys |
| `healthcheck` | Read /etc, exec sysadmin cmds | System config exposure | ✅ Read-only by default |
| `github` | GH API, repo access via `gh` | PR manipulation, token use | ⚠️ Requires `gh auth`, token scope review |

### 🟠 High Risk (External Communication)

| Skill | Permissions | Risk Vector | Mitigation |
|-------|-------------|-------------|------------|
| `message` tools | Telegram/Discord/WhatsApp | Impersonation, spam | ✅ User approval for external messages |
| `wacli` | WhatsApp history + send | Privacy leak, spam | ⚠️ Needs rate limiting |
| `himalaya` | IMAP/SMTP full access | Email exfil, phishing | ⚠️ Credentials in config, no MFA |
| `gog` | Google Workspace (Gmail/Cal/Drive) | Data leak, unauthorized actions | ⚠️ OAuth tokens, scope review needed |

### 🟡 Medium Risk (Data Access)

| Skill | Permissions | Risk Vector | Mitigation |
|-------|-------------|-------------|------------|
| `obsidian` | Vault read/write | Note tampering | ✅ Limited to vault path |
| `1password` | CLI secret injection | Secret exposure | ✅ Requires desktop app + biometric |
| `session-logs` | Historical chat logs | Privacy leak (old convos) | ✅ jq filtering, no write |
| `tmux` | Session control, pane scraping | Terminal hijack | ✅ Local only, no remote |

### 🟢 Low Risk (Read-only / Limited Scope)

| Skill | Permissions | Risk Vector | Mitigation |
|-------|-------------|-------------|------------|
| `weather` | wttr.in API | None (public data) | ✅ No API key, read-only |
| `blogwatcher` | RSS/Atom feeds | None (public feeds) | ✅ Read-only |
| `spotify-player` | Spotify API (play/search) | Playlist manipulation | ✅ OAuth scoped |
| `openhue` | Hue bridge control | Light control | ✅ Local network only |
| `sonoscli` | Sonos speaker control | Audio playback | ✅ Local network only |

---

## Permission Audit Findings

### ⚠️ Excessive Permissions

1. **`write` tool** — No trash safety, can overwrite critical files
   - **Recommendation:** Implement automatic backup before write or enforce `trash` first
   
2. **`exec` tool** — Full shell access
   - **Mitigation:** ✅ Approval system exists (allow-once/allow-always/deny)
   - **Recommendation:** Audit `allow-always` list regularly
   
3. **`browser` tool** — Can access authenticated sessions (cookies)
   - **Risk:** Profile="user" mode uses real browser with logins
   - **Recommendation:** Document when to use `profile="user"` vs default isolated browser
   
4. **`message` tool** — Can send as user without confirmation
   - **Current:** "Ask first" policy in AGENTS.md
   - **Recommendation:** Enforce programmatic confirmation before external send

### 🔒 Well-Scoped Permissions

- ✅ `read` / `edit` — Precise, no unnecessary write
- ✅ `image` / `pdf` / `web_fetch` — Read-only, no side effects
- ✅ `sessions_yield` — Control flow only, no data access
- ✅ `tts` — Single-purpose, limited scope

### 🚨 Missing Safeguards

1. **No rate limiting** on `message`, `wacli`, `himalaya`
   - **Impact:** Spam, abuse, account suspension
   - **Solution:** Implement per-tool rate limits (see `skills/rate-limit`)

2. **No secret scanner** on `exec` output
   - **Impact:** Credentials/keys in shell output exposed to LLM
   - **Solution:** Run `security-scanner.py` on tool output before logging

3. **No spending cap enforcement**
   - **Impact:** Cost overruns from API abuse
   - **Solution:** Runtime governance in `security-scanner.py` (see config)

---

## Recommended Hardening

### Immediate (P0)

1. ✅ **Security scanner** — Implemented in this PR
2. ⚠️ **Audit `gh auth` token scope** — Minimize permissions
3. ⚠️ **Review `allow-always` exec list** — Remove stale entries
4. ⚠️ **Rotate Google OAuth tokens** — 3-month cadence

### Short-term (P1)

5. Implement rate limiting on external message tools
6. Add pre-write backup for `write` tool (optional trash integration)
7. Document browser profile security (user vs isolated)
8. Create `memory/approved-external-actions.md` log

### Long-term (P2)

9. Tool-level capability system (read/write/exec/network flags)
10. Least-privilege skill execution (sandbox per skill)
11. Audit logging for sensitive operations (delete, external send)
12. MCP integration for tool permission declarations

---

## Skill-Specific Notes

### `coding-agent`
- **Never** run in `~/clawd` workspace (corruption risk)
- Sandboxed to temp dirs or project dirs only
- Can spawn Codex/Claude Code/Pi — inherits same restrictions

### `openclaw-checkpoint`
- Backs up entire workspace + agents
- Git remote access = credential exposure risk
- SSH keys should use passphrase + agent
- Multi-agent backup flag awareness needed

### `gh-issues`
- Spawns sub-agents to implement fixes → code injection vector
- PR creation = GitHub API write access
- Review comment monitoring = potential for automated spam if compromised

### `1password`
- Desktop app integration required (biometric)
- `op` CLI can inject secrets → must be read-only in logs
- Never log `op` output directly

### `gog` (Google Workspace)
- OAuth scope: Gmail, Calendar, Drive, Contacts, Sheets, Docs
- Keyring backend: file (encrypted with GOG_KEYRING_PASSWORD)
- Token refresh = network call, can fail

---

## Security Model Summary

| Layer | Status | Coverage |
|-------|--------|----------|
| Prompt Injection Detection | ✅ Implemented | Incoming text |
| PII/Secrets Scanning | ✅ Implemented | Outgoing text |
| Runtime Governance | ✅ Implemented | Loop + spend |
| Exec Approval System | ✅ Built-in | Elevated commands |
| Tool Permission Docs | ✅ This file | All tools/skills |
| Rate Limiting | ⚠️ Partial | `rate-limit` skill |
| Audit Logging | ⚠️ Manual | `security-detections.log` |
| Least Privilege | ❌ Not enforced | Future: capability system |

---

**Last Updated:** 2026-03-24  
**Next Review:** 2026-06-24 (3 months)  
**Owner:** Lola (lolaopenclaw@gmail.com)
