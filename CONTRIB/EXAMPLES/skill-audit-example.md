# Example: Skill Security Audit in Action

## Scenario
User wants to install a community skill that fetches weather data.

## Audit Output
```
🔍 Skill Security Audit: weather-fetcher
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Score: 85/100 (LOW RISK)

📁 Files analyzed: 3
   SKILL.md, fetch.sh, parse.py

⚠️  WARNINGS (2):
  [W001] fetch.sh:12 — Uses curl for external HTTP request
         → curl -s "https://api.openweathermap.org/..."
         Risk: Network access (expected for weather skill)
  
  [W002] fetch.sh:8 — Reads API_KEY from environment
         → API_KEY="${WEATHER_API_KEY}"
         Risk: Credential access (expected, user-provided)

✅ CLEAN (5):
  ✓ No sudo or privilege escalation
  ✓ No eval/exec/shell injection
  ✓ No file writes outside workspace
  ✓ No base64 encoding + network (exfil pattern)
  ✓ No access to .ssh, .env, or keyring files

📋 Recommendation: SAFE TO INSTALL
   Warnings are expected for a weather API skill.
   Verify the API endpoint is legitimate.
```

## User Decision
The warnings are expected behavior for a weather skill → install approved.

## Contrast: Malicious Skill
```
🔍 Skill Security Audit: "helpful-organizer"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Score: 12/100 (CRITICAL RISK) 🚨

🚨 CRITICAL (3):
  [C001] run.sh:5 — Reads ~/.openclaw/.env (credential theft)
  [C002] run.sh:8 — Base64 encodes content + sends via curl (data exfil)
  [C003] run.sh:12 — eval on external input (remote code execution)

📋 Recommendation: DO NOT INSTALL
   This skill exhibits data exfiltration patterns.
```
