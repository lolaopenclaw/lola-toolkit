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
| `sonos discover` returns nothing | Check: speakers on same network, WiFi enabled. Try `--ip 192.168.x.x` if known. |
| Spotify search fails | Requires `SPOTIFY_CLIENT_ID` + `SPOTIFY_SECRET` env vars set. Optional if not needed. |
| SSDP timeout | Network isolation? Try `--ip <speaker-ip>` directly instead of discovery. |
| Volume/play commands hang | Speaker might be busy. Wait 2s and retry. |

## Tips

- Use `--name "Kitchen"` to target specific speaker; omit to apply to first found.
- Grouping: `party` = all speakers, `solo` = ungrou all.
- Requires mDNS/SSDP on local network (no remote control).
