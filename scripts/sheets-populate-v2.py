#!/usr/bin/env python3
"""
sheets-populate-v2.py — Definitive Google Sheets Population Script
==================================================================

Populates two Google Sheets with daily data:
  1. Consumo IA — AI usage costs and request counts
  2. Garmin Health — Health metrics from Garmin Connect

KEY DESIGN:
  - Uses `gog sheets update/append --values-json` for reliable columnar insertion
  - Numbers are inserted as JSON numbers → stored as real numbers in Sheets
  - Garmin data fetched via garminconnect Python library (most reliable)
  - Usage data parsed from daily usage reports in memory/
  - Idempotent: checks for existing rows before inserting
  - Can update existing rows (--force flag)
  - Can backfill historical data (--backfill flag)

USAGE:
  python3 sheets-populate-v2.py                      # Today's data (both sheets)
  python3 sheets-populate-v2.py --consumo-only       # Only Consumo IA
  python3 sheets-populate-v2.py --garmin-only        # Only Garmin Health
  python3 sheets-populate-v2.py --dry-run            # Show what would be inserted
  python3 sheets-populate-v2.py --date 2026-02-22    # Specific date
  python3 sheets-populate-v2.py --backfill 7         # Backfill last 7 days
  python3 sheets-populate-v2.py --force              # Overwrite existing rows
  python3 sheets-populate-v2.py --fix-format         # Fix number display format

CRON: Daily 9:30 AM Madrid (after usage report at 9:10 AM)
"""

import os
import sys
import json
import re
import subprocess
import argparse
from datetime import datetime, timedelta
from pathlib import Path

# === Configuration ===
WORKSPACE = Path.home() / ".openclaw" / "workspace"
CONSUMO_SHEET_ID = "1Fs9L4DNG81pzeLNSMDZhQsqqNwYz0TYMEQrAzCoSf6Y"
GARMIN_SHEET_ID = "1TP5z6qivyBmjXO0ToeufTDO3BiKaGf7WibkT4n7PyKk"
GOG_ACCOUNT = "lolaopenclaw@gmail.com"
SHEET_NAME = "Hoja 1"

# Column definitions
CONSUMO_HEADERS = ["Fecha", "Haiku ($)", "Sonnet ($)", "Opus ($)", "Gemini ($)", "Total ($)", "Requests"]
GARMIN_HEADERS = [
    "Fecha", "Pasos", "Distancia (km)", "Calorías", "HR Promedio",
    "HR Max", "HR Reposo", "Estrés", "Sueño (h)", "Sueño Profundo (h)",
    "Body Battery Max"
]


def log(msg, level="info"):
    icons = {"info": "  ", "ok": "✅", "warn": "⚠️ ", "err": "❌", "skip": "⏭️ "}
    print(f"{icons.get(level, '  ')} {msg}")


def run_gog(args, capture=True):
    """Run a gog CLI command with proper environment."""
    env = os.environ.copy()
    env["GOG_KEYRING_BACKEND"] = "file"
    
    # Load .env for GOG_KEYRING_PASSWORD
    env_file = Path.home() / ".openclaw" / ".env"
    if env_file.exists():
        with open(env_file) as f:
            for line in f:
                line = line.strip()
                if "=" in line and not line.startswith("#"):
                    key, val = line.split("=", 1)
                    env[key] = val

    cmd = ["gog"] + args + ["--account", GOG_ACCOUNT, "--no-input"]
    
    result = subprocess.run(cmd, capture_output=capture, text=True, env=env)
    if result.returncode != 0 and capture:
        log(f"gog error: {result.stderr}", "err")
    return result


def get_sheet_data(sheet_id, range_str, unformatted=False):
    """Get data from a sheet range."""
    args = ["sheets", "get", sheet_id, f"'{SHEET_NAME}'!{range_str}", "--json"]
    if unformatted:
        args += ["--render", "UNFORMATTED_VALUE"]
    result = run_gog(args)
    if result.returncode == 0:
        try:
            return json.loads(result.stdout)
        except json.JSONDecodeError:
            return None
    return None


def get_existing_dates(sheet_id):
    """Get all dates already in column A."""
    data = get_sheet_data(sheet_id, "A:A")
    dates = set()
    if data and "values" in data:
        for row in data["values"][1:]:  # Skip header
            if row:
                dates.add(row[0])
    return dates


def find_row_for_date(sheet_id, date_str):
    """Find the row number for a given date. Returns None if not found."""
    data = get_sheet_data(sheet_id, "A:A")
    if data and "values" in data:
        for i, row in enumerate(data["values"]):
            if row and row[0] == date_str:
                return i + 1  # 1-indexed
    return None


def update_row(sheet_id, row_num, values, num_cols):
    """Update a specific row with values."""
    col_letter = chr(ord('A') + num_cols - 1)
    range_str = f"'{SHEET_NAME}'!A{row_num}:{col_letter}{row_num}"
    json_values = json.dumps([values])
    
    result = run_gog([
        "sheets", "update", sheet_id, range_str,
        "--values-json", json_values,
        "--input", "USER_ENTERED"
    ])
    return result.returncode == 0


def append_row(sheet_id, values):
    """Append a new row to the sheet."""
    range_str = f"'{SHEET_NAME}'!A:Z"
    json_values = json.dumps([values])
    
    result = run_gog([
        "sheets", "append", sheet_id, range_str,
        "--values-json", json_values,
        "--input", "USER_ENTERED"
    ])
    return result.returncode == 0


def clear_range(sheet_id, range_str):
    """Clear a range in the sheet."""
    result = run_gog(["sheets", "clear", sheet_id, f"'{SHEET_NAME}'!{range_str}"])
    return result.returncode == 0


# ============================================================================
# CONSUMO IA DATA
# ============================================================================

def parse_usage_report(date_str):
    """Parse a usage report file and extract cost data."""
    search_paths = [
        WORKSPACE / "memory" / f"{date_str}-usage-report.md",
        WORKSPACE / "memory" / "DAILY" / "HOT" / f"{date_str}-usage-report.md",
        WORKSPACE / "memory" / "DAILY" / "HOT" / f"{date_str}-usage-report-final.md",
    ]
    
    usage_file = None
    for path in search_paths:
        if path.exists():
            usage_file = path
            break
    
    result = {"total": 0, "requests": 0, "haiku": 0, "sonnet": 0, "opus": 0, "gemini": 0}
    
    if not usage_file:
        log(f"No usage report found for {date_str}", "warn")
        return result
    
    log(f"Reading: {usage_file.name}")
    content = usage_file.read_text()
    
    # Split into sections by ### headers
    sections = re.split(r'###\s+', content)
    
    today_section = ""
    for s in sections:
        if re.match(r'(?i)consumo\s+(de\s+)?hoy', s):
            today_section = s
            break
    
    if today_section:
        # Extract total
        total_match = re.search(r'\$([0-9]+(?:\.[0-9]+)?)\s*(?:USD)?', today_section)
        if total_match:
            result["total"] = float(total_match.group(1))
        
        # Extract requests
        req_match = re.search(r'(?i)requests?\D*?(\d[\d,]*)', today_section)
        if req_match:
            result["requests"] = int(req_match.group(1).replace(",", ""))
        
        # Check model distribution
        modelo_match = re.search(r'(?i)modelo.*?(haiku|sonnet|opus|gemini).*?\((\d+)%\)', today_section)
        if modelo_match and result["total"] > 0:
            model = modelo_match.group(1).lower()
            pct = int(modelo_match.group(2)) / 100
            result[model] = round(result["total"] * pct, 2)
        
        # Per-model lines
        for model in ["haiku", "sonnet", "opus", "gemini"]:
            m = re.search(rf'(?i){model}[^\n]*\$([0-9]+(?:\.[0-9]+)?)', today_section)
            if m:
                result[model] = float(m.group(1))
    else:
        # Fallback: look for total
        hoy_match = re.search(r'(?i)(?:hoy|today)[:\s]*\$([0-9]+(?:\.[0-9]+)?)', content)
        if hoy_match:
            result["total"] = float(hoy_match.group(1))
        
        req_match = re.search(r'(?i)requests?\D*?(\d[\d,]*)', content)
        if req_match:
            result["requests"] = int(req_match.group(1).replace(",", ""))
    
    return result


def populate_consumo(date_str, dry_run=False, force=False):
    """Populate Consumo IA sheet for a given date."""
    print(f"\n📈 CONSUMO IA — {date_str}")
    print("─" * 40)
    
    # Check for existing row
    existing_row = find_row_for_date(CONSUMO_SHEET_ID, date_str)
    if existing_row and not force:
        log(f"Row already exists for {date_str} (row {existing_row}) — skipping", "skip")
        return True
    
    # Parse usage report
    data = parse_usage_report(date_str)
    
    log(f"Haiku: ${data['haiku']:.2f} | Sonnet: ${data['sonnet']:.2f} | "
        f"Opus: ${data['opus']:.2f} | Gemini: ${data['gemini']:.2f}")
    log(f"Total: ${data['total']:.2f} | Requests: {data['requests']}")
    
    # Build row values
    row = [date_str, data['haiku'], data['sonnet'], data['opus'], 
           data['gemini'], data['total'], data['requests']]
    
    if dry_run:
        log(f"[DRY RUN] Would insert: {json.dumps(row)}")
        return True
    
    if existing_row and force:
        log(f"Updating existing row {existing_row}")
        success = update_row(CONSUMO_SHEET_ID, existing_row, row, len(CONSUMO_HEADERS))
    else:
        success = append_row(CONSUMO_SHEET_ID, row)
    
    if success:
        log(f"Data inserted for {date_str}", "ok")
    else:
        log(f"Failed to insert data for {date_str}", "err")
    
    return success


# ============================================================================
# GARMIN HEALTH DATA
# ============================================================================

def load_garmin_client():
    """Load Garmin Connect client with stored tokens."""
    env_file = Path.home() / ".openclaw" / ".env"
    tokens = None
    with open(env_file) as f:
        for line in f:
            if line.startswith('GARMIN_TOKENS='):
                tokens = line.split('=', 1)[1].strip()
                break
    
    if not tokens:
        log("No GARMIN_TOKENS in .env", "err")
        return None
    
    try:
        from garminconnect import Garmin
        client = Garmin()
        client.garth.loads(tokens)
        client.display_name = "Manu_Lazarus"
        return client
    except Exception as e:
        log(f"Failed to load Garmin client: {e}", "err")
        return None


def fetch_garmin_data(client, activity_date_str, sleep_date_str=None):
    """Fetch all Garmin health data for a given date."""
    if sleep_date_str is None:
        # Sleep is typically reported on the next day (wake-up date)
        d = datetime.strptime(activity_date_str, "%Y-%m-%d")
        sleep_date_str = (d + timedelta(days=1)).strftime("%Y-%m-%d")
    
    result = {
        "date": activity_date_str,
        "steps": 0, "distance_km": 0, "calories": 0,
        "hr_avg": 0, "hr_max": 0, "hr_resting": 0,
        "stress": 0, "sleep_total": 0, "sleep_deep": 0,
        "battery_max": 0,
    }
    
    # Activity summary
    try:
        summary = client.get_user_summary(activity_date_str)
        result["steps"] = summary.get("totalSteps", 0) or 0
        result["distance_km"] = round((summary.get("totalDistanceMeters", 0) or 0) / 1000, 2)
        result["calories"] = int(summary.get("activeKilocalories", 0) or 0)
    except Exception as e:
        log(f"Activity fetch error: {e}", "warn")
    
    # Heart rate
    try:
        hr = client.get_heart_rates(activity_date_str)
        if hr:
            result["hr_resting"] = hr.get("restingHeartRate", 0) or 0
            if "heartRateValues" in hr:
                values = [v[1] for v in hr["heartRateValues"] if v and v[1] and v[1] > 30]
                if values:
                    result["hr_avg"] = round(sum(values) / len(values))
                    result["hr_max"] = max(values)
    except Exception as e:
        log(f"HR fetch error: {e}", "warn")
    
    # Stress
    try:
        stats = client.get_stats(activity_date_str)
        if stats:
            result["stress"] = stats.get("averageStressLevel", 0) or 0
    except Exception as e:
        log(f"Stress fetch error: {e}", "warn")
    
    # Body Battery
    try:
        battery = client.get_body_battery(activity_date_str)
        if battery:
            charged = [b.get("charged", 0) for b in battery if b.get("charged")]
            if charged:
                result["battery_max"] = max(charged)
    except Exception as e:
        log(f"Battery fetch error: {e}", "warn")
    
    # Sleep (from wake-up date)
    try:
        sleep = client.get_sleep_data(sleep_date_str)
        if sleep and "dailySleepDTO" in sleep:
            s = sleep["dailySleepDTO"]
            if s.get("sleepTimeSeconds"):
                result["sleep_total"] = round(s["sleepTimeSeconds"] / 3600, 1)
                result["sleep_deep"] = round(s.get("deepSleepSeconds", 0) / 3600, 1)
    except Exception as e:
        log(f"Sleep fetch error: {e}", "warn")
    
    return result


def populate_garmin(date_str, dry_run=False, force=False, client=None):
    """Populate Garmin Health sheet for a given date."""
    print(f"\n💓 GARMIN HEALTH — {date_str}")
    print("─" * 50)
    
    # Check for existing row
    existing_row = find_row_for_date(GARMIN_SHEET_ID, date_str)
    if existing_row and not force:
        log(f"Row already exists for {date_str} (row {existing_row}) — skipping", "skip")
        return True
    
    # Fetch Garmin data
    if client is None:
        client = load_garmin_client()
    if client is None:
        return False
    
    data = fetch_garmin_data(client, date_str)
    
    log(f"👣 Steps: {data['steps']} | 📏 Distance: {data['distance_km']}km | 🔥 Cal: {data['calories']}")
    log(f"💓 HR: avg={data['hr_avg']} max={data['hr_max']} rest={data['hr_resting']}")
    log(f"😴 Sleep: {data['sleep_total']}h (deep: {data['sleep_deep']}h)")
    log(f"😰 Stress: {data['stress']} | 🔋 Battery: {data['battery_max']}")
    
    # Build row values
    row = [
        date_str, data['steps'], data['distance_km'], data['calories'],
        data['hr_avg'], data['hr_max'], data['hr_resting'], data['stress'],
        data['sleep_total'], data['sleep_deep'], data['battery_max']
    ]
    
    if dry_run:
        log(f"[DRY RUN] Would insert: {json.dumps(row)}")
        return True
    
    if existing_row and force:
        log(f"Updating existing row {existing_row}")
        success = update_row(GARMIN_SHEET_ID, existing_row, row, len(GARMIN_HEADERS))
    else:
        success = append_row(GARMIN_SHEET_ID, row)
    
    if success:
        log(f"Data inserted for {date_str}", "ok")
    else:
        log(f"Failed to insert data for {date_str}", "err")
    
    return success


# ============================================================================
# FORMAT FIXING
# ============================================================================

def fix_number_format(sheet_id, range_str):
    """Apply proper number format to remove trailing commas."""
    # Use gog sheets format to set number format
    result = run_gog([
        "sheets", "format", sheet_id, f"'{SHEET_NAME}'!{range_str}",
        "--number-format", "#,##0.##"
    ])
    if result.returncode == 0:
        log(f"Format applied to {range_str}", "ok")
    else:
        log(f"Format failed for {range_str}", "warn")


# ============================================================================
# MAIN
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description="Populate Google Sheets with daily data")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be inserted")
    parser.add_argument("--consumo-only", action="store_true", help="Only populate Consumo IA")
    parser.add_argument("--garmin-only", action="store_true", help="Only populate Garmin Health")
    parser.add_argument("--date", type=str, help="Specific date (YYYY-MM-DD)")
    parser.add_argument("--backfill", type=int, help="Backfill last N days")
    parser.add_argument("--force", action="store_true", help="Overwrite existing rows")
    parser.add_argument("--fix-format", action="store_true", help="Fix number display format")
    parser.add_argument("--clean-garmin", action="store_true", help="Clean and re-populate all Garmin data")
    
    args = parser.parse_args()
    
    do_consumo = not args.garmin_only
    do_garmin = not args.consumo_only
    
    print(f"📊 Google Sheets Population v2 — {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    if args.dry_run:
        print("🔍 MODE: DRY RUN (no data will be written)")
    
    # Determine dates to process
    if args.backfill:
        dates = []
        for i in range(args.backfill, 0, -1):
            d = (datetime.now() - timedelta(days=i)).strftime("%Y-%m-%d")
            dates.append(d)
        dates.append(datetime.now().strftime("%Y-%m-%d"))
    elif args.date:
        dates = [args.date]
    else:
        dates = [datetime.now().strftime("%Y-%m-%d")]
    
    # Load Garmin client once if needed
    garmin_client = None
    if do_garmin:
        garmin_client = load_garmin_client()
        if garmin_client is None:
            log("Cannot load Garmin client — skipping Garmin", "err")
            do_garmin = False
    
    # Process each date
    success_count = 0
    fail_count = 0
    
    for date_str in dates:
        if do_consumo:
            try:
                if populate_consumo(date_str, dry_run=args.dry_run, force=args.force):
                    success_count += 1
                else:
                    fail_count += 1
            except Exception as e:
                log(f"Consumo error for {date_str}: {e}", "err")
                fail_count += 1
        
        if do_garmin:
            try:
                if populate_garmin(date_str, dry_run=args.dry_run, force=args.force, client=garmin_client):
                    success_count += 1
                else:
                    fail_count += 1
            except Exception as e:
                log(f"Garmin error for {date_str}: {e}", "err")
                fail_count += 1
    
    # Fix format if requested
    if args.fix_format and not args.dry_run:
        print("\n🔧 Fixing number formats...")
        # Consumo: columns B-F are dollar amounts, G is count
        fix_number_format(CONSUMO_SHEET_ID, "B2:F100")
        fix_number_format(CONSUMO_SHEET_ID, "G2:G100")
        # Garmin: all numeric columns
        fix_number_format(GARMIN_SHEET_ID, "B2:K100")
    
    print(f"\n{'=' * 60}")
    print(f"✅ Done — {success_count} successful, {fail_count} failed — {datetime.now().strftime('%H:%M:%S')}")
    
    return 0 if fail_count == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
