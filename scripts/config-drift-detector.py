#!/usr/bin/env python3
"""
Config Drift Detector for OpenClaw
Monitors critical configuration files for unexpected changes.
"""

import sys
import os
import json
import hashlib
import difflib
import re
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple
import shutil

# Define critical config files
CRITICAL_FILES = [
    "~/.openclaw/openclaw.json",
    "~/.openclaw/.env",
    "~/.openclaw/cron/jobs.json",
    "~/.openclaw/agents/main/agent/auth-profiles.json",
    "~/.config/systemd/user/openclaw-gateway.service"
]

BASELINE_DIR = Path.home() / ".openclaw/workspace/config-baselines"
BACKUP_DIR = Path.home() / ".openclaw/backups/config-drift"

class AlertLevel:
    INFO = "INFO"
    WARN = "WARN"
    CRITICAL = "CRITICAL"

class ConfigDriftDetector:
    def __init__(self):
        self.baseline_dir = BASELINE_DIR
        self.backup_dir = BACKUP_DIR
        self.baseline_dir.mkdir(parents=True, exist_ok=True)
        self.backup_dir.mkdir(parents=True, exist_ok=True)
    
    def _expand_path(self, path: str) -> Path:
        """Expand ~ and resolve path"""
        return Path(path).expanduser().resolve()
    
    def _get_baseline_path(self, filepath: Path) -> Path:
        """Get baseline file path for a config file"""
        # Use sanitized filename to avoid path traversal
        safe_name = str(filepath).replace("/", "_").replace("~", "")
        return self.baseline_dir / f"{safe_name}.baseline"
    
    def _get_backup_path(self, filepath: Path) -> Path:
        """Get backup file path"""
        safe_name = str(filepath).replace("/", "_").replace("~", "")
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        return self.backup_dir / f"{safe_name}.{timestamp}.backup"
    
    def _calculate_hash(self, filepath: Path) -> Optional[str]:
        """Calculate SHA256 hash of file"""
        if not filepath.exists():
            return None
        
        sha256 = hashlib.sha256()
        try:
            with open(filepath, 'rb') as f:
                for chunk in iter(lambda: f.read(4096), b""):
                    sha256.update(chunk)
            return sha256.hexdigest()
        except Exception as e:
            print(f"Error reading {filepath}: {e}", file=sys.stderr)
            return None
    
    def create_baseline(self, filepath: str) -> bool:
        """Create baseline snapshot for a config file"""
        path = self._expand_path(filepath)
        
        if not path.exists():
            print(f"⚠️  File does not exist: {path}")
            return False
        
        file_hash = self._calculate_hash(path)
        if not file_hash:
            return False
        
        baseline = {
            "file": str(path),
            "hash": file_hash,
            "size": path.stat().st_size,
            "created": datetime.now().isoformat(),
            "last_checked": datetime.now().isoformat()
        }
        
        baseline_path = self._get_baseline_path(path)
        with open(baseline_path, 'w') as f:
            json.dump(baseline, f, indent=2)
        
        print(f"✅ Baseline created: {path.name}")
        return True
    
    def _read_baseline(self, filepath: Path) -> Optional[Dict]:
        """Read baseline data"""
        baseline_path = self._get_baseline_path(filepath)
        if not baseline_path.exists():
            return None
        
        try:
            with open(baseline_path, 'r') as f:
                return json.load(f)
        except Exception as e:
            print(f"Error reading baseline: {e}", file=sys.stderr)
            return None
    
    def check_drift(self, filepath: str) -> Dict:
        """Check if file has drifted from baseline"""
        path = self._expand_path(filepath)
        
        # File deleted?
        if not path.exists():
            return {
                "changed": True,
                "level": AlertLevel.CRITICAL,
                "reason": "FILE DELETED",
                "diff": None,
                "baseline_exists": self._get_baseline_path(path).exists()
            }
        
        baseline = self._read_baseline(path)
        if not baseline:
            return {
                "changed": False,
                "level": AlertLevel.INFO,
                "reason": "No baseline exists (run 'config-drift init' first)",
                "diff": None,
                "baseline_exists": False
            }
        
        current_hash = self._calculate_hash(path)
        if current_hash == baseline["hash"]:
            # Update last_checked timestamp
            baseline["last_checked"] = datetime.now().isoformat()
            baseline_path = self._get_baseline_path(path)
            with open(baseline_path, 'w') as f:
                json.dump(baseline, f, indent=2)
            
            return {
                "changed": False,
                "level": AlertLevel.INFO,
                "reason": "No changes detected",
                "diff": None,
                "baseline_exists": True
            }
        
        # Hash changed - get diff
        diff_text = self._get_diff(path, baseline)
        classification = self._classify_changes(diff_text, path)
        
        return {
            "changed": True,
            "level": classification["level"],
            "reason": classification["reason"],
            "diff": diff_text,
            "baseline_exists": True,
            "patterns": classification.get("patterns", [])
        }
    
    def _get_diff(self, filepath: Path, baseline: Dict) -> str:
        """Generate unified diff between current and baseline"""
        # Read current file
        try:
            with open(filepath, 'r') as f:
                current_lines = f.readlines()
        except Exception as e:
            return f"Error reading current file: {e}"
        
        # Recreate baseline content from hash (we need to backup first)
        # For now, we'll note that we can't show exact diff without backup
        # In production, we should backup before baseline creation
        
        # Try to find most recent backup
        backup_pattern = str(filepath).replace("/", "_").replace("~", "")
        backup_files = sorted(self.backup_dir.glob(f"{backup_pattern}.*.backup"))
        
        if backup_files:
            try:
                with open(backup_files[-1], 'r') as f:
                    baseline_lines = f.readlines()
                
                diff = difflib.unified_diff(
                    baseline_lines,
                    current_lines,
                    fromfile=f"{filepath.name} (baseline)",
                    tofile=f"{filepath.name} (current)",
                    lineterm=''
                )
                return '\n'.join(diff)
            except:
                pass
        
        return f"Hash changed: {baseline['hash'][:8]} → {self._calculate_hash(filepath)[:8]}\n(No backup available for detailed diff)"
    
    def _classify_changes(self, diff_text: str, filepath: Path) -> Dict:
        """Classify changes as INFO/WARN/CRITICAL"""
        
        # Critical patterns
        critical_patterns = [
            (r'chmod.*777', "Insecure permissions (777)"),
            (r'sudo\s+', "Sudo command added"),
            (r'rm\s+-rf\s+/', "Dangerous rm -rf command"),
            (r'ExecStart=.*rm\s+-rf', "Dangerous command in systemd service"),
            (r'--password[=\s]', "Password in command line"),
        ]
        
        # Warning patterns
        warn_patterns = [
            (r'["\']?(?:api[_-]?key|token|secret|password)["\']?\s*[:=]\s*["\']?\w+', "New secret/API key"),
            (r'"model"\s*:\s*"[^"]*"', "Model changed"),
            (r'https?://[^\s]+', "New endpoint URL"),
            (r'ExecStart=.*', "SystemD command changed"),
            (r'OPENAI_API_KEY|ANTHROPIC_API_KEY', "API key variable changed"),
        ]
        
        # Info patterns (benign)
        info_patterns = [
            (r'#.*', "Comment added/changed"),
            (r'"(?:created|updated|last_checked)"', "Timestamp updated"),
            (r'^\s*$', "Whitespace change"),
        ]
        
        detected_patterns = []
        
        # Check critical first
        for pattern, desc in critical_patterns:
            if re.search(pattern, diff_text, re.MULTILINE | re.IGNORECASE):
                detected_patterns.append(desc)
                return {
                    "level": AlertLevel.CRITICAL,
                    "reason": f"Critical change detected: {desc}",
                    "patterns": detected_patterns
                }
        
        # Check warnings
        for pattern, desc in warn_patterns:
            if re.search(pattern, diff_text, re.MULTILINE | re.IGNORECASE):
                detected_patterns.append(desc)
        
        if detected_patterns:
            return {
                "level": AlertLevel.WARN,
                "reason": f"Suspicious changes: {', '.join(detected_patterns)}",
                "patterns": detected_patterns
            }
        
        # Default to INFO
        return {
            "level": AlertLevel.INFO,
            "reason": "Benign changes (comments, whitespace, timestamps)",
            "patterns": []
        }
    
    def alert(self, level: str, filepath: Path, changes: Dict) -> None:
        """Alert about changes (console + optional Telegram)"""
        
        icons = {
            AlertLevel.INFO: "ℹ️",
            AlertLevel.WARN: "⚠️",
            AlertLevel.CRITICAL: "🚨"
        }
        
        print(f"\n{icons[level]} {level}: Config drift detected")
        print(f"File: {filepath}")
        print(f"Reason: {changes['reason']}")
        
        if changes.get('patterns'):
            print(f"Patterns: {', '.join(changes['patterns'])}")
        
        if changes.get('diff'):
            print(f"\nDiff preview:")
            diff_lines = changes['diff'].split('\n')
            for line in diff_lines[:20]:  # Show first 20 lines
                print(f"  {line}")
            if len(diff_lines) > 20:
                print(f"  ... ({len(diff_lines) - 20} more lines)")
        
        if level == AlertLevel.CRITICAL:
            print(f"\n🔴 CRITICAL: Manual confirmation required!")
            print(f"   Approve: config-drift approve {filepath}")
            print(f"   Reject:  config-drift reject {filepath}")
            print(f"   Diff:    config-drift diff {filepath}")
        
        # TODO: Integrate with Telegram notification
        # For WARN and CRITICAL levels
    
    def update_baseline(self, filepath: str) -> bool:
        """Update baseline after confirming changes are OK"""
        path = self._expand_path(filepath)
        
        if not path.exists():
            print(f"⚠️  File does not exist: {path}")
            return False
        
        # Backup current file before updating baseline
        backup_path = self._get_backup_path(path)
        shutil.copy2(path, backup_path)
        print(f"📦 Backup created: {backup_path.name}")
        
        # Update baseline
        return self.create_baseline(str(path))
    
    def rollback(self, filepath: str) -> bool:
        """Rollback to last known good version"""
        path = self._expand_path(filepath)
        
        # Find most recent backup
        backup_pattern = str(path).replace("/", "_").replace("~", "")
        backup_files = sorted(self.backup_dir.glob(f"{backup_pattern}.*.backup"))
        
        if not backup_files:
            print(f"⚠️  No backup found for {path}")
            return False
        
        latest_backup = backup_files[-1]
        
        # Backup current (bad) version first
        bad_backup = self.backup_dir / f"{backup_pattern}.BAD.{datetime.now().strftime('%Y%m%d_%H%M%S')}.backup"
        shutil.copy2(path, bad_backup)
        print(f"📦 Current version backed up to: {bad_backup.name}")
        
        # Restore from backup
        shutil.copy2(latest_backup, path)
        print(f"✅ Restored from: {latest_backup.name}")
        
        # Update baseline to match restored version
        return self.create_baseline(str(path))
    
    def init_all(self) -> None:
        """Initialize baselines for all critical files"""
        print("Initializing baselines for all critical config files...\n")
        
        success_count = 0
        for filepath in CRITICAL_FILES:
            if self.create_baseline(filepath):
                success_count += 1
                # Also create initial backup
                path = self._expand_path(filepath)
                if path.exists():
                    backup_path = self._get_backup_path(path)
                    shutil.copy2(path, backup_path)
        
        print(f"\n✅ Initialized {success_count}/{len(CRITICAL_FILES)} baselines")
    
    def check_all(self) -> Dict[str, Dict]:
        """Check all critical files for drift"""
        results = {}
        
        for filepath in CRITICAL_FILES:
            result = self.check_drift(filepath)
            results[filepath] = result
            
            if result['changed']:
                path = self._expand_path(filepath)
                self.alert(result['level'], path, result)
        
        return results
    
    def show_diff(self, filepath: str) -> None:
        """Show detailed diff for a file"""
        path = self._expand_path(filepath)
        
        result = self.check_drift(filepath)
        
        if not result['changed']:
            print(f"ℹ️  No changes detected in {path.name}")
            return
        
        if result.get('diff'):
            print(f"\nDetailed diff for {path}:")
            print("=" * 80)
            print(result['diff'])
            print("=" * 80)
        else:
            print(f"⚠️  No diff available (missing backup)")

def main():
    if len(sys.argv) < 2:
        print("Usage: config-drift-detector.py <command> [args]")
        print("\nCommands:")
        print("  init                    - Initialize baselines for all config files")
        print("  check                   - Check all files for drift")
        print("  check <file>            - Check specific file")
        print("  approve <file>          - Approve changes and update baseline")
        print("  reject <file>           - Reject changes and rollback")
        print("  diff <file>             - Show detailed diff")
        sys.exit(1)
    
    detector = ConfigDriftDetector()
    command = sys.argv[1]
    
    if command == "init":
        detector.init_all()
    
    elif command == "check":
        if len(sys.argv) > 2:
            # Check specific file
            filepath = sys.argv[2]
            result = detector.check_drift(filepath)
            if result['changed']:
                path = detector._expand_path(filepath)
                detector.alert(result['level'], path, result)
            else:
                print(f"✅ No changes detected")
        else:
            # Check all
            results = detector.check_all()
            
            # Summary
            changed = sum(1 for r in results.values() if r['changed'])
            critical = sum(1 for r in results.values() if r.get('level') == AlertLevel.CRITICAL)
            
            print(f"\n{'='*80}")
            print(f"Summary: {changed}/{len(CRITICAL_FILES)} files changed")
            if critical > 0:
                print(f"🚨 {critical} CRITICAL changes require manual confirmation")
            else:
                print(f"✅ No critical changes detected")
    
    elif command == "approve":
        if len(sys.argv) < 3:
            print("Usage: config-drift approve <file>")
            sys.exit(1)
        filepath = sys.argv[2]
        if detector.update_baseline(filepath):
            print(f"✅ Changes approved and baseline updated")
        else:
            print(f"❌ Failed to update baseline")
            sys.exit(1)
    
    elif command == "reject":
        if len(sys.argv) < 3:
            print("Usage: config-drift reject <file>")
            sys.exit(1)
        filepath = sys.argv[2]
        if detector.rollback(filepath):
            print(f"✅ Changes rejected and file rolled back")
        else:
            print(f"❌ Failed to rollback")
            sys.exit(1)
    
    elif command == "diff":
        if len(sys.argv) < 3:
            print("Usage: config-drift diff <file>")
            sys.exit(1)
        filepath = sys.argv[2]
        detector.show_diff(filepath)
    
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)

if __name__ == "__main__":
    main()
