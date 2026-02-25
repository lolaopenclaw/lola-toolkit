# BOOT.md

Check gateway status and report to Manu via Telegram:

1. Verify OpenClaw gateway is running: `systemctl status openclaw-gateway`
2. Check for any crashes in the last 10 minutes: `journalctl --user -u openclaw-gateway --since "10 minutes ago" --no-pager -q`
3. Check recent reboots: `last reboot | head -3`
4. Send a message to Manu (6884477) with:
   - Current time (Madrid timezone)
   - Boot reason (clean restart, system reboot, or crash)
   - Gateway status (running/down)
   - Any errors from logs

Keep the message brief and factual. If all is well, just confirm "Gateway up and running ✅".
