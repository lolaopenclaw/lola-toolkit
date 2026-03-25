#!/usr/bin/env python3
"""
fix-cron-delivery.py
Fix all crons with incorrect delivery configuration
"""

import json
import sys
from pathlib import Path
from datetime import datetime

CRON_FILE = Path.home() / ".openclaw" / "cron" / "jobs.json"
GROUP_ID = "-1003768820594"

# Topic mapping based on cron name/purpose
TOPIC_RULES = [
    # (keyword, topic_id, topic_name)
    ("garmin", 28, "Salud & Garmin"),
    ("health", 28, "Salud & Garmin"),
    ("security", 29, "Seguridad & Audits"),
    ("finanzas", 26, "Finanzas"),
    ("sheets", 26, "Finanzas"),
    ("informe matutino", 24, "Reportes Diarios"),
    # Default: Sistema & Logs (25)
]

def get_topic_for_cron(name: str) -> tuple[int, str]:
    """Determine topic ID and name from cron name."""
    name_lower = name.lower()
    
    for keyword, topic_id, topic_name in TOPIC_RULES:
        if keyword in name_lower:
            return topic_id, topic_name
    
    # Default
    return 25, "Sistema & Logs"

def fix_delivery(job: dict) -> tuple[dict, bool]:
    """
    Fix delivery config for a job.
    Returns: (updated_job, was_changed)
    """
    delivery = job.get("delivery", {})
    changed = False
    
    # Check if needs fixing
    needs_fix = (
        delivery.get("to") == "6884477" or
        delivery.get("channel") == "last"
    )
    
    if not needs_fix:
        return job, False
    
    # Determine topic
    topic_id, topic_name = get_topic_for_cron(job.get("name", ""))
    
    # Fix delivery
    new_delivery = {
        "mode": delivery.get("mode", "none"),
        "channel": "telegram",
        "to": f"{GROUP_ID}:{topic_id}",
        "bestEffort": delivery.get("bestEffort", True)
    }
    
    job["delivery"] = new_delivery
    
    return job, True

def main():
    if not CRON_FILE.exists():
        print(f"❌ Cron file not found: {CRON_FILE}", file=sys.stderr)
        return 1
    
    # Backup
    backup_path = CRON_FILE.with_suffix(f".json.bak.{datetime.now().strftime('%Y%m%d-%H%M%S')}")
    backup_path.write_bytes(CRON_FILE.read_bytes())
    print(f"✅ Backup created: {backup_path}")
    print()
    
    # Load
    with CRON_FILE.open() as f:
        data = json.load(f)
    
    # Fix jobs
    fixed_count = 0
    fixed_jobs = []
    
    for i, job in enumerate(data.get("jobs", [])):
        updated_job, changed = fix_delivery(job)
        data["jobs"][i] = updated_job
        
        if changed:
            fixed_count += 1
            fixed_jobs.append({
                "name": job.get("name", "Unknown"),
                "id": job.get("id", "")[:8],
                "old_to": job.get("delivery", {}).get("to", "N/A"),
                "old_channel": job.get("delivery", {}).get("channel", "N/A"),
                "new_to": updated_job["delivery"]["to"],
                "topic_name": updated_job["delivery"]["to"].split(":")[-1]
            })
    
    # Save
    with CRON_FILE.open("w") as f:
        json.dump(data, f, indent=2)
    
    print(f"✅ Fixed {fixed_count} cron(s)")
    print()
    
    if fixed_count > 0:
        print("📊 Changes:")
        print()
        for job_info in fixed_jobs:
            # Get topic name from ID
            topic_id = int(job_info["new_to"].split(":")[-1])
            topic_names = {
                24: "📊 Reportes Diarios",
                25: "🔧 Sistema & Logs",
                26: "💰 Finanzas",
                28: "🏃 Salud & Garmin",
                29: "🛡️ Seguridad & Audits"
            }
            topic_name = topic_names.get(topic_id, f"Topic {topic_id}")
            
            print(f"  • {job_info['name']} (ID: {job_info['id']})")
            print(f"    FROM: to={job_info['old_to']}, channel={job_info['old_channel']}")
            print(f"    TO:   to={job_info['new_to']} ({topic_name})")
            print()
    
    print("🔄 Changes saved to:", CRON_FILE)
    print("📦 Backup available at:", backup_path)
    print()
    print("⚠️  Gateway restart required:")
    print("    openclaw gateway restart")
    print()
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
