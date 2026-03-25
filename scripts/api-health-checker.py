#!/home/mleon/.openclaw/workspace/scripts/api-health-venv/bin/python3
"""
API Health Checker for OpenClaw
Monitors critical APIs, handles failover, and alerts on status changes.
"""

import json
import os
import sys
import time
import subprocess
import shutil
from pathlib import Path
from datetime import datetime, timezone, timedelta
from typing import Dict, Optional, Tuple
import requests

# Expand home directory in paths
def expand_path(path: str) -> Path:
    return Path(os.path.expanduser(path))

# Load configuration
CONFIG_PATH = expand_path("~/.openclaw/workspace/config/api-health-config.json")
ENV_FILE = expand_path("~/.openclaw/.env")

class APIHealthChecker:
    def __init__(self):
        self.config = self.load_config()
        self.env_vars = self.load_env()
        self.status_file = expand_path(self.config["status"]["file"])
        self.history_file = expand_path(self.config["status"]["history_file"])
        self.log_file = expand_path(self.config["logging"]["log_file"])
        self.current_status = self.load_status()
        
    def load_config(self) -> dict:
        """Load API health configuration"""
        try:
            with open(CONFIG_PATH) as f:
                return json.load(f)
        except Exception as e:
            self.log_error(f"Failed to load config: {e}")
            sys.exit(1)
    
    def load_env(self) -> dict:
        """Load environment variables from .env file"""
        env = {}
        try:
            with open(ENV_FILE) as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        env[key.strip()] = value.strip()
        except Exception as e:
            self.log_error(f"Failed to load .env: {e}")
        return env
    
    def load_status(self) -> dict:
        """Load current API status"""
        if self.status_file.exists():
            try:
                with open(self.status_file) as f:
                    return json.load(f)
            except:
                pass
        return {"apis": {}, "last_check": None, "failover_active": False}
    
    def save_status(self):
        """Save current status to file"""
        self.status_file.parent.mkdir(parents=True, exist_ok=True)
        with open(self.status_file, 'w') as f:
            json.dump(self.current_status, f, indent=2)
    
    def log(self, message: str, level: str = "INFO"):
        """Append to log file with rotation"""
        timestamp = datetime.now(timezone.utc).isoformat()
        log_entry = f"[{timestamp}] [{level}] {message}\n"
        
        # Console output
        print(log_entry.strip())
        
        # File logging
        if not self.config["logging"]["enabled"]:
            return
            
        self.log_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Rotate if needed
        if self.log_file.exists():
            size_mb = self.log_file.stat().st_size / (1024 * 1024)
            if size_mb > self.config["logging"]["max_size_mb"]:
                backup = self.log_file.with_suffix('.log.old')
                shutil.move(self.log_file, backup)
        
        with open(self.log_file, 'a') as f:
            f.write(log_entry)
    
    def log_error(self, message: str):
        self.log(message, "ERROR")
    
    def is_quiet_hours(self) -> bool:
        """Check if we're in quiet hours"""
        if not self.config["alerting"]["quiet_hours"]["enabled"]:
            return False
        
        import pytz
        tz = pytz.timezone(self.config["alerting"]["quiet_hours"]["timezone"])
        now = datetime.now(tz)
        
        start = datetime.strptime(self.config["alerting"]["quiet_hours"]["start"], "%H:%M").time()
        end = datetime.strptime(self.config["alerting"]["quiet_hours"]["end"], "%H:%M").time()
        
        current_time = now.time()
        
        # Handle overnight range
        if start > end:
            return current_time >= start or current_time <= end
        else:
            return start <= current_time <= end
    
    def check_anthropic(self) -> Dict:
        """Check Anthropic API health"""
        api_config = self.config["apis"]["anthropic"]
        
        try:
            # Ping the API endpoint - accept 401/405 as "reachable"
            # (OpenClaw uses OAuth tokens, not standard API keys)
            start = time.time()
            response = requests.post(
                api_config["endpoint"],
                headers={
                    "anthropic-version": "2023-06-01",
                    "content-type": "application/json"
                },
                json={"model": "claude-sonnet-4-5", "messages": [{"role": "user", "content": "hi"}], "max_tokens": 1},
                timeout=api_config["timeout_seconds"]
            )
            latency = int((time.time() - start) * 1000)
            
            # 401/405 = API is reachable (auth is handled by OpenClaw internally)
            if response.status_code in (200, 401, 403, 405):
                return {"status": "up", "latency": latency, "error": None}
            else:
                return {"status": "degraded", "latency": latency, "error": f"HTTP {response.status_code}"}
                
        except requests.exceptions.Timeout:
            return {"status": "down", "error": "Timeout", "latency": api_config["timeout_seconds"] * 1000}
        except Exception as e:
            return {"status": "down", "error": str(e), "latency": 0}
    
    def check_google(self) -> Dict:
        """Check Google Gemini API health"""
        api_config = self.config["apis"]["google"]
        
        try:
            api_key = self.env_vars.get("GOOGLE_API_KEY") or self.env_vars.get("GEMINI_API_KEY")
            if not api_key:
                return {"status": "down", "error": "API key not found", "latency": 0}
            
            url = f"{api_config['endpoint']}?key={api_key}"
            
            start = time.time()
            response = requests.get(url, timeout=api_config["timeout_seconds"])
            latency = int((time.time() - start) * 1000)
            
            if response.status_code == 200:
                data = response.json()
                # Verify we got models back
                if "models" in data and len(data["models"]) > 0:
                    return {"status": "up", "latency": latency, "error": None}
                else:
                    return {"status": "degraded", "latency": latency, "error": "No models returned"}
            else:
                return {"status": "degraded", "latency": latency, "error": f"HTTP {response.status_code}"}
                
        except requests.exceptions.Timeout:
            return {"status": "down", "error": "Timeout", "latency": api_config["timeout_seconds"] * 1000}
        except Exception as e:
            return {"status": "down", "error": str(e), "latency": 0}
    
    def check_telegram(self) -> Dict:
        """Check Telegram Bot API health"""
        api_config = self.config["apis"]["telegram"]
        
        try:
            bot_token = self.env_vars.get("TELEGRAM_BOT_TOKEN")
            if not bot_token:
                return {"status": "down", "error": "Bot token not found", "latency": 0}
            
            url = f"{api_config['endpoint']}/bot{bot_token}/getMe"
            
            start = time.time()
            response = requests.get(url, timeout=api_config["timeout_seconds"])
            latency = int((time.time() - start) * 1000)
            
            if response.status_code == 200:
                data = response.json()
                if data.get("ok"):
                    return {"status": "up", "latency": latency, "error": None}
                else:
                    return {"status": "degraded", "latency": latency, "error": "API returned ok=false"}
            else:
                return {"status": "degraded", "latency": latency, "error": f"HTTP {response.status_code}"}
                
        except requests.exceptions.Timeout:
            return {"status": "down", "error": "Timeout", "latency": api_config["timeout_seconds"] * 1000}
        except Exception as e:
            return {"status": "down", "error": str(e), "latency": 0}
    
    def check_github(self) -> Dict:
        """Check GitHub API health"""
        api_config = self.config["apis"]["github"]
        
        try:
            url = f"{api_config['endpoint']}/rate_limit"
            headers = {}
            
            # Try to use GitHub token if available
            gh_token = self.env_vars.get("GITHUB_TOKEN") or self.env_vars.get("GH_TOKEN")
            if gh_token:
                headers["Authorization"] = f"token {gh_token}"
            
            start = time.time()
            response = requests.get(url, headers=headers, timeout=api_config["timeout_seconds"])
            latency = int((time.time() - start) * 1000)
            
            if response.status_code == 200:
                return {"status": "up", "latency": latency, "error": None}
            else:
                return {"status": "degraded", "latency": latency, "error": f"HTTP {response.status_code}"}
                
        except requests.exceptions.Timeout:
            return {"status": "down", "error": "Timeout", "latency": api_config["timeout_seconds"] * 1000}
        except Exception as e:
            return {"status": "down", "error": str(e), "latency": 0}
    
    def check_garmin(self) -> Dict:
        """Check Garmin API health (basic ping)"""
        api_config = self.config["apis"]["garmin"]
        
        try:
            # Simple HEAD request to check connectivity
            url = "https://connect.garmin.com"
            
            start = time.time()
            response = requests.head(url, timeout=api_config["timeout_seconds"])
            latency = int((time.time() - start) * 1000)
            
            if response.status_code < 500:  # Any non-server-error is OK
                return {"status": "up", "latency": latency, "error": None}
            else:
                return {"status": "degraded", "latency": latency, "error": f"HTTP {response.status_code}"}
                
        except requests.exceptions.Timeout:
            return {"status": "down", "error": "Timeout", "latency": api_config["timeout_seconds"] * 1000}
        except Exception as e:
            return {"status": "down", "error": str(e), "latency": 0}
    
    def check_brave(self) -> Dict:
        """Check Brave Search API health"""
        api_config = self.config["apis"]["brave"]
        
        try:
            api_key = self.env_vars.get("BRAVE_SEARCH_API_KEY") or self.env_vars.get("BRAVE_API_KEY")
            if not api_key:
                return {"status": "down", "error": "API key not found", "latency": 0}
            
            headers = {
                "Accept": "application/json",
                "X-Subscription-Token": api_key
            }
            
            params = {"q": "test", "count": 1}
            
            start = time.time()
            response = requests.get(
                api_config["endpoint"],
                headers=headers,
                params=params,
                timeout=api_config["timeout_seconds"]
            )
            latency = int((time.time() - start) * 1000)
            
            if response.status_code == 200:
                return {"status": "up", "latency": latency, "error": None}
            else:
                return {"status": "degraded", "latency": latency, "error": f"HTTP {response.status_code}"}
                
        except requests.exceptions.Timeout:
            return {"status": "down", "error": "Timeout", "latency": api_config["timeout_seconds"] * 1000}
        except Exception as e:
            return {"status": "down", "error": str(e), "latency": 0}
    
    def check_api(self, api_name: str) -> Dict:
        """Check specific API and return status"""
        check_methods = {
            "anthropic": self.check_anthropic,
            "google": self.check_google,
            "telegram": self.check_telegram,
            "github": self.check_github,
            "garmin": self.check_garmin,
            "brave": self.check_brave
        }
        
        if api_name not in check_methods:
            return {"status": "unknown", "error": f"No check method for {api_name}", "latency": 0}
        
        self.log(f"Checking {api_name}...")
        result = check_methods[api_name]()
        result["timestamp"] = datetime.now(timezone.utc).isoformat()
        result["api"] = api_name
        
        self.log(f"{api_name}: {result['status']} (latency: {result['latency']}ms)")
        
        return result
    
    def send_telegram_alert(self, message: str):
        """Send alert via Telegram"""
        if not self.config["alerting"]["telegram_enabled"]:
            return
        
        if self.is_quiet_hours():
            self.log("Skipping alert (quiet hours)", "INFO")
            return
        
        try:
            bot_token = self.env_vars.get("TELEGRAM_BOT_TOKEN")
            chat_id = self.config["alerting"]["telegram_chat_id"]
            
            if not bot_token or not chat_id:
                self.log_error("Telegram credentials missing")
                return
            
            url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
            data = {
                "chat_id": chat_id,
                "text": f"🚨 API Health Alert\n\n{message}",
                "parse_mode": "HTML"
            }
            
            response = requests.post(url, json=data, timeout=10)
            if response.status_code == 200:
                self.log(f"Alert sent: {message[:50]}...")
            else:
                self.log_error(f"Failed to send alert: HTTP {response.status_code}")
                
        except Exception as e:
            self.log_error(f"Failed to send Telegram alert: {e}")
    
    def backup_openclaw_config(self) -> bool:
        """Backup openclaw.json before modifications"""
        try:
            config_path = expand_path(self.config["failover"]["openclaw_config_path"])
            backup_path = expand_path(self.config["failover"]["backup_path"])
            
            backup_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(config_path, backup_path)
            
            self.log(f"Backed up config to {backup_path}")
            return True
        except Exception as e:
            self.log_error(f"Failed to backup config: {e}")
            return False
    
    def modify_openclaw_config(self, changes: dict) -> bool:
        """Modify openclaw.json with specific changes"""
        try:
            config_path = expand_path(self.config["failover"]["openclaw_config_path"])
            
            with open(config_path) as f:
                openclaw_config = json.load(f)
            
            # Apply changes
            for key_path, value in changes.items():
                keys = key_path.split(".")
                target = openclaw_config
                for key in keys[:-1]:
                    target = target[key]
                target[keys[-1]] = value
            
            # Save
            with open(config_path, 'w') as f:
                json.dump(openclaw_config, f, indent=2)
            
            self.log(f"Modified OpenClaw config: {changes}")
            return True
        except Exception as e:
            self.log_error(f"Failed to modify config: {e}")
            return False
    
    def restore_openclaw_config(self) -> bool:
        """Restore openclaw.json from backup"""
        try:
            config_path = expand_path(self.config["failover"]["openclaw_config_path"])
            backup_path = expand_path(self.config["failover"]["backup_path"])
            
            if not backup_path.exists():
                self.log_error("No backup found to restore")
                return False
            
            shutil.copy2(backup_path, config_path)
            self.log(f"Restored config from backup")
            return True
        except Exception as e:
            self.log_error(f"Failed to restore config: {e}")
            return False
    
    def restart_gateway(self) -> bool:
        """Restart OpenClaw gateway"""
        try:
            self.log("Restarting OpenClaw gateway...")
            
            # Run pre-restart validator if exists
            validator_path = expand_path("~/.openclaw/workspace/scripts/pre-restart-validator.sh")
            if validator_path.exists():
                result = subprocess.run([str(validator_path)], capture_output=True, text=True)
                if result.returncode != 0:
                    self.log_error(f"Pre-restart validator failed: {result.stderr}")
                    return False
            
            # Restart via openclaw CLI
            result = subprocess.run(
                ["openclaw", "gateway", "restart"],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                self.log("Gateway restarted successfully")
                return True
            else:
                self.log_error(f"Gateway restart failed: {result.stderr}")
                return False
                
        except Exception as e:
            self.log_error(f"Failed to restart gateway: {e}")
            return False
    
    def failover_to_google(self):
        """Switch from Anthropic to Google Gemini"""
        self.log("FAILOVER: Switching to Google Gemini", "WARN")
        
        # Backup config
        if not self.backup_openclaw_config():
            self.log_error("Failover aborted: backup failed")
            return
        
        # Modify config to use Google
        changes = {
            "agents.defaults.model.primary": "google/gemini-3-flash-preview"
        }
        
        if not self.modify_openclaw_config(changes):
            self.log_error("Failover aborted: config modification failed")
            return
        
        # Restart gateway
        if not self.restart_gateway():
            self.log_error("Failover failed: gateway restart failed")
            # Attempt restore
            self.restore_openclaw_config()
            return
        
        # Update status
        self.current_status["failover_active"] = True
        self.current_status["failover_timestamp"] = datetime.now(timezone.utc).isoformat()
        self.current_status["failover_reason"] = "anthropic_down"
        self.save_status()
        
        # Alert
        self.send_telegram_alert(
            "⚠️ <b>Failover activado</b>\n\n"
            "Anthropic API caída. Cambiado a Google Gemini.\n"
            "Monitoreo continuo activo."
        )
    
    def restore_from_failover(self):
        """Restore from failover back to Anthropic"""
        self.log("RESTORE: Switching back to Anthropic", "INFO")
        
        # Restore config
        if not self.restore_openclaw_config():
            self.log_error("Restore failed: config restoration failed")
            return
        
        # Restart gateway
        if not self.restart_gateway():
            self.log_error("Restore failed: gateway restart failed")
            return
        
        # Update status
        self.current_status["failover_active"] = False
        self.current_status["failover_restored_at"] = datetime.now(timezone.utc).isoformat()
        self.save_status()
        
        # Alert
        self.send_telegram_alert(
            "✅ <b>Failover restaurado</b>\n\n"
            "Anthropic API operativa de nuevo. Volviendo a configuración normal."
        )
    
    def check_all_apis(self):
        """Check all configured APIs"""
        results = {}
        
        for api_name in self.config["apis"].keys():
            result = self.check_api(api_name)
            results[api_name] = result
            
            # Check for state changes
            old_status = self.current_status["apis"].get(api_name, {}).get("status")
            new_status = result["status"]
            
            if old_status != new_status:
                self.log(f"State change: {api_name} {old_status} → {new_status}", "WARN")
                
                # Send alert on state change
                if self.config["alerting"]["only_on_state_change"]:
                    priority = self.config["apis"][api_name]["priority"]
                    emoji = "🔴" if new_status == "down" else "🟡" if new_status == "degraded" else "🟢"
                    
                    message = (
                        f"{emoji} <b>{api_name.upper()}</b> ({priority})\n"
                        f"Estado: {old_status or 'unknown'} → <b>{new_status}</b>\n"
                        f"Latencia: {result['latency']}ms"
                    )
                    
                    if result.get("error"):
                        message += f"\nError: {result['error']}"
                    
                    self.send_telegram_alert(message)
        
        # Update status
        self.current_status["apis"] = results
        self.current_status["last_check"] = datetime.now(timezone.utc).isoformat()
        self.save_status()
        
        # Handle failover logic
        anthropic_status = results.get("anthropic", {}).get("status")
        google_status = results.get("google", {}).get("status")
        
        if self.config["failover"]["enabled"]:
            # Trigger failover if Anthropic down and Google up
            if anthropic_status == "down" and google_status == "up":
                if not self.current_status["failover_active"]:
                    self.failover_to_google()
            
            # Restore if Anthropic back up and failover active
            elif anthropic_status == "up" and self.current_status["failover_active"]:
                # Check if enough time has passed (avoid flapping)
                if self.config["failover"]["auto_restore"]:
                    failover_time = datetime.fromisoformat(
                        self.current_status.get("failover_timestamp", datetime.now(timezone.utc).isoformat())
                    )
                    elapsed = (datetime.now(timezone.utc) - failover_time).total_seconds() / 60
                    
                    if elapsed >= self.config["failover"]["restore_after_minutes"]:
                        self.restore_from_failover()
        
        return results
    
    def run_check(self, api_name: Optional[str] = None):
        """Run health check for specific API or all APIs"""
        if api_name:
            result = self.check_api(api_name)
            print(json.dumps(result, indent=2))
        else:
            results = self.check_all_apis()
            print(json.dumps(results, indent=2))
    
    def get_status(self):
        """Display current status"""
        print(json.dumps(self.current_status, indent=2))
    
    def run_interactive(self):
        """Interactive mode for testing"""
        print("API Health Checker - Interactive Mode")
        print("=" * 50)
        
        while True:
            print("\nCommands:")
            print("  1. Check all APIs")
            print("  2. Check specific API")
            print("  3. Show status")
            print("  4. Force failover")
            print("  5. Force restore")
            print("  6. Send test alert")
            print("  q. Quit")
            
            choice = input("\n> ").strip()
            
            if choice == "1":
                self.check_all_apis()
            elif choice == "2":
                api = input("API name: ").strip()
                if api in self.config["apis"]:
                    self.check_api(api)
                else:
                    print(f"Unknown API: {api}")
            elif choice == "3":
                self.get_status()
            elif choice == "4":
                self.failover_to_google()
            elif choice == "5":
                self.restore_from_failover()
            elif choice == "6":
                self.send_telegram_alert("Test alert from API Health Checker")
            elif choice.lower() == "q":
                break


def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description="OpenClaw API Health Checker")
    parser.add_argument("--check", help="Check specific API or 'all'")
    parser.add_argument("--status", action="store_true", help="Show current status")
    parser.add_argument("--interactive", action="store_true", help="Interactive mode")
    
    args = parser.parse_args()
    
    checker = APIHealthChecker()
    
    if args.status:
        checker.get_status()
    elif args.check:
        if args.check == "all":
            checker.run_check()
        else:
            checker.run_check(args.check)
    elif args.interactive:
        checker.run_interactive()
    else:
        # Default: check all APIs
        checker.run_check()


if __name__ == "__main__":
    main()
