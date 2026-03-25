#!/usr/bin/env python3
"""
Rate Limit Monitor for OpenClaw APIs
Tracks usage, detects threshold breaches, and sends Telegram alerts.
"""

import json
import os
import sys
from datetime import datetime, timezone, timedelta
from pathlib import Path
import subprocess
import re

# Paths
WORKSPACE = Path.home() / ".openclaw" / "workspace"
LOGS_DIR = WORKSPACE / "logs"
MEMORY_DIR = WORKSPACE / "memory"
METRICS_FILE = LOGS_DIR / "rate-limit-metrics.jsonl"
STATUS_FILE = MEMORY_DIR / "rate-limit-status.json"

# Rate limits configuration
LIMITS_CONFIG = {
    "brave_search": {
        "limit": 2000,
        "reset_period": "monthly",
        "threshold_warning": 0.80,  # 80%
        "threshold_critical": 0.95,  # 95%
        "check_interval": "6h"
    },
    "google_gemini": {
        "limit": 1000,  # Daily quota variable
        "reset_period": "daily",
        "threshold_warning": 0.80,
        "threshold_critical": 0.95,
        "check_interval": "2h"
    },
    "google_sheets": {
        "limit": 100,
        "reset_period": "100s",
        "threshold_warning": 0.80,
        "threshold_critical": 0.95,
        "check_interval": "2h"
    },
    "google_drive": {
        "limit": 1000,
        "reset_period": "100s",
        "threshold_warning": 0.80,
        "threshold_critical": 0.95,
        "check_interval": "2h"
    },
    "openai_whisper": {
        "limit": 50.0,  # USD monthly
        "reset_period": "monthly",
        "threshold_warning": 0.80,
        "threshold_critical": 0.95,
        "check_interval": "24h",
        "unit": "usd"
    },
    "anthropic": {
        "limit": 10,  # 429 responses per day
        "reset_period": "daily",
        "threshold_warning": 0.50,  # More aggressive for 429s
        "threshold_critical": 0.80,
        "check_interval": "1h",
        "unit": "429s"
    }
}


class RateLimitMonitor:
    def __init__(self):
        self.now = datetime.now(timezone.utc)
        self.status = self.load_status()
        
    def load_status(self):
        """Load current status from JSON file"""
        if STATUS_FILE.exists():
            with open(STATUS_FILE) as f:
                return json.load(f)
        return {}
    
    def save_status(self):
        """Save status to JSON file"""
        STATUS_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(STATUS_FILE, 'w') as f:
            json.dump(self.status, f, indent=2)
    
    def log_metric(self, api, metrics):
        """Append metric to JSONL log"""
        METRICS_FILE.parent.mkdir(parents=True, exist_ok=True)
        
        entry = {
            "timestamp": self.now.isoformat(),
            "api": api,
            **metrics
        }
        
        with open(METRICS_FILE, 'a') as f:
            f.write(json.dumps(entry) + '\n')
        
        # Keep only last 30 days
        self.cleanup_old_metrics()
    
    def cleanup_old_metrics(self):
        """Remove metrics older than 30 days"""
        if not METRICS_FILE.exists():
            return
        
        cutoff = self.now - timedelta(days=30)
        
        with open(METRICS_FILE, 'r') as f:
            lines = f.readlines()
        
        filtered = []
        for line in lines:
            try:
                entry = json.loads(line)
                ts = datetime.fromisoformat(entry['timestamp'].replace('Z', '+00:00'))
                if ts >= cutoff:
                    filtered.append(line)
            except:
                continue
        
        with open(METRICS_FILE, 'w') as f:
            f.writelines(filtered)
    
    def check_brave_search(self):
        """Check Brave Search API usage"""
        api = "brave_search"
        
        # Try to get from logs (search for web_search tool calls in recent logs)
        # For now, use stored counter
        current = self.status.get(api, {})
        used = current.get('used', 0)
        limit = LIMITS_CONFIG[api]['limit']
        
        # Check if we need to reset (monthly)
        last_check = current.get('last_check', '')
        if last_check:
            last_dt = datetime.fromisoformat(last_check.replace('Z', '+00:00'))
            # Reset if we're in a new month
            if last_dt.month != self.now.month or last_dt.year != self.now.year:
                used = 0
        
        percentage = (used / limit * 100) if limit > 0 else 0
        
        metrics = {
            "used": used,
            "limit": limit,
            "pct": round(percentage, 2)
        }
        
        self.status[api] = {
            **metrics,
            "last_check": self.now.isoformat(),
            "quota_reset": self.get_next_reset(LIMITS_CONFIG[api]['reset_period'])
        }
        
        self.log_metric(api, metrics)
        self.alert_if_threshold(api, used, limit, percentage)
        
        return metrics
    
    def check_google_quota(self):
        """Check Google APIs quotas (Gemini, Sheets, Drive)"""
        # For Gemini, Sheets, Drive - track locally
        for service in ["google_gemini", "google_sheets", "google_drive"]:
            current = self.status.get(service, {})
            used = current.get('used', 0)
            limit = LIMITS_CONFIG[service]['limit']
            
            # Check if we need to reset
            last_check = current.get('last_check', '')
            if last_check:
                last_dt = datetime.fromisoformat(last_check.replace('Z', '+00:00'))
                reset_period = LIMITS_CONFIG[service]['reset_period']
                
                if reset_period == "daily" and last_dt.date() != self.now.date():
                    used = 0
                elif reset_period == "100s":
                    # For short periods, just reset if >100s elapsed
                    if (self.now - last_dt).total_seconds() > 100:
                        used = 0
            
            percentage = (used / limit * 100) if limit > 0 else 0
            
            metrics = {
                "used": used,
                "limit": limit,
                "pct": round(percentage, 2)
            }
            
            self.status[service] = {
                **metrics,
                "last_check": self.now.isoformat(),
                "quota_reset": self.get_next_reset(LIMITS_CONFIG[service]['reset_period'])
            }
            
            self.log_metric(service, metrics)
            self.alert_if_threshold(service, used, limit, percentage)
    
    def check_openai_usage(self):
        """Check OpenAI API usage (Whisper)"""
        api = "openai_whisper"
        
        # Track locally - would need OpenAI usage API for real data
        current = self.status.get(api, {})
        cost = current.get('used', 0.0)
        limit = LIMITS_CONFIG[api]['limit']
        
        # Check monthly reset
        last_check = current.get('last_check', '')
        if last_check:
            last_dt = datetime.fromisoformat(last_check.replace('Z', '+00:00'))
            if last_dt.month != self.now.month or last_dt.year != self.now.year:
                cost = 0.0
        
        percentage = (cost / limit * 100) if limit > 0 else 0
        
        metrics = {
            "used": cost,
            "limit": limit,
            "pct": round(percentage, 2),
            "unit": "usd"
        }
        
        self.status[api] = {
            **metrics,
            "last_check": self.now.isoformat(),
            "quota_reset": self.get_next_reset(LIMITS_CONFIG[api]['reset_period'])
        }
        
        self.log_metric(api, metrics)
        self.alert_if_threshold(api, cost, limit, percentage)
        
        return metrics
    
    def check_anthropic_rate_limits(self):
        """Check Anthropic 429 responses in logs"""
        api = "anthropic"
        
        # Count 429s in journalctl from last 24h
        try:
            cmd = [
                'journalctl',
                '--user',
                '-u', 'openclaw-gateway.service',
                '--since', '24 hours ago',
                '--no-pager'
            ]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
            
            # Count 429 occurrences
            count_429 = len(re.findall(r'429|rate.?limit', result.stdout, re.IGNORECASE))
            
        except Exception as e:
            print(f"Warning: Could not check journalctl: {e}", file=sys.stderr)
            count_429 = 0
        
        limit = LIMITS_CONFIG[api]['limit']
        percentage = (count_429 / limit * 100) if limit > 0 else 0
        
        metrics = {
            "used": count_429,
            "limit": limit,
            "pct": round(percentage, 2),
            "unit": "429s"
        }
        
        self.status[api] = {
            **metrics,
            "last_check": self.now.isoformat(),
            "quota_reset": self.get_next_reset(LIMITS_CONFIG[api]['reset_period'])
        }
        
        self.log_metric(api, metrics)
        self.alert_if_threshold(api, count_429, limit, percentage)
        
        return metrics
    
    def get_next_reset(self, period):
        """Calculate next quota reset time"""
        if period == "monthly":
            # Next month, day 1, 00:00
            if self.now.month == 12:
                next_reset = datetime(self.now.year + 1, 1, 1, tzinfo=timezone.utc)
            else:
                next_reset = datetime(self.now.year, self.now.month + 1, 1, tzinfo=timezone.utc)
        elif period == "daily":
            # Tomorrow 00:00
            next_reset = (self.now + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
        elif period == "100s":
            next_reset = self.now + timedelta(seconds=100)
        else:
            next_reset = self.now
        
        return next_reset.isoformat()
    
    def alert_if_threshold(self, api, current, limit, percentage):
        """Send Telegram alert if threshold exceeded"""
        config = LIMITS_CONFIG.get(api, {})
        threshold_warning = config.get('threshold_warning', 0.80) * 100
        threshold_critical = config.get('threshold_critical', 0.95) * 100
        
        # Check if already alerted recently (avoid spam)
        last_alert = self.status.get(api, {}).get('last_alert', '')
        if last_alert:
            last_alert_dt = datetime.fromisoformat(last_alert.replace('Z', '+00:00'))
            # Don't alert again within 6 hours
            if (self.now - last_alert_dt).total_seconds() < 6 * 3600:
                return
        
        unit = config.get('unit', 'requests')
        reset_period = config.get('reset_period', 'unknown')
        
        message = None
        emoji = None
        
        if percentage >= threshold_critical:
            emoji = "🚨"
            level = "CRITICAL"
            message = f"{emoji} **{level}: Rate Limit Alert - {api.replace('_', ' ').title()}**\n\n"
            message += f"**Usage:** {current}/{limit} {unit} ({percentage:.1f}%)\n"
            message += f"**Status:** CRITICAL threshold exceeded (>{threshold_critical:.0f}%)\n"
            message += f"**Reset:** {reset_period}\n\n"
            message += "**Actions:**\n"
            
            if api == "brave_search":
                message += "• Consider upgrading Brave Search plan\n"
                message += "• Reduce search frequency\n"
                message += "• Cache search results when possible"
            elif "google" in api:
                message += "• Review Google Cloud quota settings\n"
                message += "• Implement request batching\n"
                message += "• Consider quota increase"
            elif api == "openai_whisper":
                message += "• Review Whisper API usage\n"
                message += "• Consider local Whisper model\n"
                message += "• Check for unnecessary transcriptions"
            elif api == "anthropic":
                message += "• Too many 429 responses detected\n"
                message += "• Implement exponential backoff\n"
                message += "• Consider tier upgrade"
            
        elif percentage >= threshold_warning:
            emoji = "⚠️"
            level = "WARNING"
            message = f"{emoji} **{level}: Rate Limit Alert - {api.replace('_', ' ').title()}**\n\n"
            message += f"**Usage:** {current}/{limit} {unit} ({percentage:.1f}%)\n"
            message += f"**Status:** Warning threshold exceeded (>{threshold_warning:.0f}%)\n"
            message += f"**Reset:** {reset_period}\n\n"
            message += f"Monitor usage carefully. Critical threshold at {threshold_critical:.0f}%."
        
        if message:
            # Send via openclaw message tool
            try:
                # Write alert to a temp file for openclaw to pick up
                alert_file = MEMORY_DIR / "rate-limit-alert-pending.json"
                with open(alert_file, 'w') as f:
                    json.dump({
                        "timestamp": self.now.isoformat(),
                        "api": api,
                        "level": level,
                        "message": message,
                        "current": current,
                        "limit": limit,
                        "percentage": percentage
                    }, f, indent=2)
                
                # Update last alert time
                if api in self.status:
                    self.status[api]['last_alert'] = self.now.isoformat()
                
                print(f"Alert generated for {api}: {level} ({percentage:.1f}%)")
                
            except Exception as e:
                print(f"Error generating alert: {e}", file=sys.stderr)
    
    def increment_counter(self, api, amount=1):
        """Increment usage counter for an API"""
        if api not in self.status:
            self.status[api] = {
                "used": 0,
                "limit": LIMITS_CONFIG.get(api, {}).get('limit', 0),
                "last_check": self.now.isoformat()
            }
        
        self.status[api]['used'] = self.status[api].get('used', 0) + amount
        
        # Recalculate percentage
        limit = self.status[api].get('limit', 0)
        used = self.status[api]['used']
        self.status[api]['pct'] = round((used / limit * 100) if limit > 0 else 0, 2)
        
        self.save_status()
    
    def run_checks(self):
        """Run all configured checks"""
        print(f"Running rate limit checks at {self.now.isoformat()}")
        
        self.check_brave_search()
        self.check_google_quota()
        self.check_openai_usage()
        self.check_anthropic_rate_limits()
        
        self.save_status()
        print("Checks complete. Status saved.")


def main():
    if len(sys.argv) > 1:
        command = sys.argv[1]
        
        monitor = RateLimitMonitor()
        
        if command == "check":
            # Run all checks
            monitor.run_checks()
        
        elif command == "increment":
            # Increment counter: rate-limit-monitor.py increment brave_search 1
            if len(sys.argv) < 3:
                print("Usage: rate-limit-monitor.py increment <api> [amount]", file=sys.stderr)
                sys.exit(1)
            
            api = sys.argv[2]
            amount = int(sys.argv[3]) if len(sys.argv) > 3 else 1
            
            monitor.increment_counter(api, amount)
            print(f"Incremented {api} by {amount}")
        
        elif command == "reset":
            # Reset counter: rate-limit-monitor.py reset brave_search
            if len(sys.argv) < 3:
                print("Usage: rate-limit-monitor.py reset <api>", file=sys.stderr)
                sys.exit(1)
            
            api = sys.argv[2]
            
            if api in monitor.status:
                monitor.status[api]['used'] = 0
                monitor.status[api]['pct'] = 0.0
                monitor.save_status()
                print(f"Reset {api} counter to 0")
            else:
                print(f"API {api} not found in status", file=sys.stderr)
                sys.exit(1)
        
        else:
            print(f"Unknown command: {command}", file=sys.stderr)
            print("Usage: rate-limit-monitor.py [check|increment|reset]", file=sys.stderr)
            sys.exit(1)
    
    else:
        # Default: run checks
        monitor = RateLimitMonitor()
        monitor.run_checks()


if __name__ == "__main__":
    main()
