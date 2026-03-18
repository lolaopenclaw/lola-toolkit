#!/usr/bin/env bash
# memory-decay.sh — Weekly synthesis with Hot/Warm/Cold tiering
# Run: bash scripts/memory-decay.sh [--dry-run]
# Called by weekly heartbeat cron
set -euo pipefail

ENTITIES_DIR="${HOME}/.openclaw/workspace/memory/entities"
DRY_RUN="${1:-}"
NOW=$(date +%s)
DAY_SECS=86400

log() { echo "[$(date +%H:%M:%S)] $1"; }

# Calculate tier for a fact based on lastAccessed and accessCount
get_tier() {
    local last_accessed="$1"
    local access_count="$2"
    
    local last_ts
    last_ts=$(date -d "$last_accessed" +%s 2>/dev/null || echo 0)
    local age_days=$(( (NOW - last_ts) / DAY_SECS ))
    
    # High-frequency facts resist decay
    local freq_bonus=0
    if [ "$access_count" -ge 10 ]; then
        freq_bonus=14  # 2 weeks grace
    elif [ "$access_count" -ge 5 ]; then
        freq_bonus=7   # 1 week grace
    fi
    
    local effective_age=$(( age_days - freq_bonus ))
    [ "$effective_age" -lt 0 ] && effective_age=0
    
    if [ "$effective_age" -le 7 ]; then
        echo "HOT"
    elif [ "$effective_age" -le 30 ]; then
        echo "WARM"
    else
        echo "COLD"
    fi
}

process_entity() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    local entity_name
    entity_name=$(python3 -c "import json; d=json.load(open('$json_file')); print(d.get('entity_name','Unknown'))")
    
    log "Processing: $entity_name ($json_file)"
    
    # Extract facts with tiers
    DRY_RUN="$DRY_RUN" JSON_FILE="$json_file" MD_FILE="$md_file" python3 << PYEOF
import json, os
from datetime import datetime, timedelta, timezone

json_path = os.environ.get("JSON_FILE", "")
md_path = os.environ.get("MD_FILE", "")
dry = os.environ.get("DRY_RUN", "")

with open(json_path) as f:
    data = json.load(f)

now = datetime.now(timezone.utc)
hot, warm, cold = [], [], []

for fact in data.get("facts", []):
    if fact.get("status") != "active":
        continue
    
    last = fact.get("lastAccessed", "2020-01-01")
    try:
        last_dt = datetime.strptime(last, "%Y-%m-%d").replace(tzinfo=timezone.utc)
    except:
        last_dt = datetime(2020, 1, 1, tzinfo=timezone.utc)
    
    age_days = (now - last_dt).days
    ac = fact.get("accessCount", 0)
    
    # Frequency resistance
    freq_bonus = 14 if ac >= 10 else (7 if ac >= 5 else 0)
    effective_age = max(0, age_days - freq_bonus)
    
    tier = "HOT" if effective_age <= 7 else ("WARM" if effective_age <= 30 else "COLD")
    
    if tier == "HOT":
        hot.append(fact)
    elif tier == "WARM":
        warm.append(fact)
    else:
        cold.append(fact)

# Sort within tiers by accessCount desc
hot.sort(key=lambda f: f.get("accessCount", 0), reverse=True)
warm.sort(key=lambda f: f.get("accessCount", 0), reverse=True)
cold.sort(key=lambda f: f.get("accessCount", 0), reverse=True)

# Report
print(f"  HOT:  {len(hot)} facts")
print(f"  WARM: {len(warm)} facts")
print(f"  COLD: {len(cold)} facts")

# Generate summary.md content (Hot + Warm only)
entity_type = data.get("entity_type", "entity")
entity_name = data.get("entity_name", "Unknown")

lines = [f"# {entity_name} — Summary", ""]
lines.append(f"**Type:** {entity_type}  ")
lines.append(f"**Last synthesized:** {now.strftime('%Y-%m-%d')}  ")
lines.append(f"**Tiers:** {len(hot)} hot, {len(warm)} warm, {len(cold)} cold")
lines.append("")

if hot:
    lines.append("## 🔥 Hot (recent / frequent)")
    lines.append("")
    for f in hot:
        cat = f.get("category", "")
        lines.append(f"- **[{cat}]** {f['fact']}")
    lines.append("")

if warm:
    lines.append("## 🌡️ Warm (8-30 days)")
    lines.append("")
    for f in warm:
        cat = f.get("category", "")
        lines.append(f"- **[{cat}]** {f['fact']}")
    lines.append("")

if cold:
    lines.append(f"## ❄️ Cold ({len(cold)} facts omitted)")
    lines.append("")
    lines.append(f"_{len(cold)} facts not accessed in 30+ days. Available in items.json._")
    lines.append("")

lines.append("---")
lines.append(f"")
lines.append(f"See \`{json_path.split('/')[-1]}\` for all {len(hot)+len(warm)+len(cold)} facts.")

content = "\n".join(lines)

if dry == "--dry-run":
    print(f"\n  [DRY RUN] Would write {len(lines)} lines to summary")
    print(f"  Preview (first 5 lines):")
    for l in lines[:5]:
        print(f"    {l}")
else:
    with open(md_path, "w") as f:
        f.write(content)
    print(f"  ✅ Written: {md_path}")
PYEOF
}

# Main
log "Memory Decay — Weekly Synthesis"
log "Mode: ${DRY_RUN:-LIVE}"
echo ""

# Find all entity JSON files
find "$ENTITIES_DIR" -name "*.json" -not -name "README*" | sort | while read -r json_file; do
    process_entity "$json_file"
    echo ""
done

log "Done! Summaries rewritten with tiering applied."
