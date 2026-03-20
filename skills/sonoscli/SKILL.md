# NOTE: Replace placeholder values (YOUR_*, $USER, etc.) with your actual configuration

---
name: sonoscli
description: Control Sonos speakers (discover/status/play/volume/group).
homepage: https://sonoscli.sh
metadata: {"clawdbot":{"emoji":"🔊","requires":{"bins":["sonos"]},"install":[{"id":"go","kind":"go","module":"github.com/steipete/sonoscli/cmd/sonos@latest","bins":["sonos"],"label":"Install sonoscli (go)"}]}}
---

# Sonos CLI

Use `sonos` to control Sonos speakers on the local network.

## Quick Start

- `sonos discover` — Find all speakers
- `sonos status --name "Kitchen"` — Get speaker state
- `sonos play|pause|stop --name "Kitchen"`
- `sonos volume set 15 --name "Kitchen"`

## Common Tasks

- **Grouping:** `sonos group status|join|unjoin|party|solo`
- **Favorites:** `sonos favorites list|open`
- **Queue:** `sonos queue list|play|clear`
- **Spotify:** `sonos smapi search --service "Spotify" --category tracks "query"`

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `sonos discover` returns nothing | Check: speakers on same network, WiFi enabled. Try `--ip YOUR_IP` if known. |
| Spotify search fails | Requires `SPOTIFY_CLIENT_ID` + `SPOTIFY_SECRET` env vars set. Optional if not needed. |
| SSDP timeout | Network isolation? Try `--ip <speaker-ip>` directly instead of discovery. |
| Volume/play commands hang | Speaker might be busy. Wait 2s and retry. |

## Advanced Grouping

| Command | Effect |
|---------|--------|
| `sonos group party` | Add all speakers to group |
| `sonos group solo` | Remove all speakers from groups |
| `sonos group join <leader>` | Join <leader> speaker's group |
| `sonos group unjoin` | Leave current group |
| `sonos group list` | Show current grouping |

## Tips

- **Target:** Use `--name "Kitchen"` for specific speaker; omit to apply to first found.
- **Discovery:** Requires mDNS/SSDP on local network (no remote control).
- **Error recovery:** If commands hang, kill (Ctrl+C) and retry after 2-3 seconds.
- **Favorites:** `favorites open <name>` requires exact name match; use `list` first.
- **Spotify:** Optional — omit if Spotify not configured or not needed.

## Environment

- `SPOTIFY_CLIENT_ID` — (optional) Spotify track search
- `SPOTIFY_SECRET` — (optional) Spotify track search
- No credentials stored — safe to export env vars
