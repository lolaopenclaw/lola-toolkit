#!/usr/bin/env python3
"""
Cron Job Validator
Validates OpenClaw cron jobs before deployment to catch errors early.
"""

import json
import re
import os
import sys
import subprocess
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any, Optional, Tuple
import argparse

try:
    from croniter import croniter
except ImportError:
    croniter = None


class CronValidator:
    """Validates OpenClaw cron job configurations"""
    
    def __init__(self, workspace_path: Optional[Path] = None):
        self.workspace = workspace_path or Path.home() / ".openclaw" / "workspace"
        self.env_file = Path.home() / ".openclaw" / ".env"
        self.env_vars = self._load_env_vars()
        self.validation_dir = self.workspace / "cron-validation-reports"
        self.validation_dir.mkdir(exist_ok=True)
        
    def _load_env_vars(self) -> Dict[str, str]:
        """Load environment variables from .env file"""
        env_vars = {}
        if not self.env_file.exists():
            return env_vars
            
        with open(self.env_file) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                if '=' in line:
                    key, value = line.split('=', 1)
                    env_vars[key.strip()] = value.strip()
        return env_vars
    
    def validate_schedule(self, schedule_obj: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate cron schedule expression
        Returns: {valid: bool, error: str or None}
        """
        kind = schedule_obj.get('kind')
        
        if kind == 'cron':
            expr = schedule_obj.get('expr')
            if not expr:
                return {'valid': False, 'error': 'Missing cron expression'}
            
            # Validate cron expression
            if croniter is None:
                return {'valid': True, 'error': None, 'warning': 'croniter not installed, skipping validation'}
            
            try:
                croniter(expr)
                return {'valid': True, 'error': None}
            except Exception as e:
                return {'valid': False, 'error': f'Invalid cron expression "{expr}": {str(e)}'}
        
        elif kind == 'at':
            # ISO timestamp validation
            timestamp = schedule_obj.get('atMs') or schedule_obj.get('at')
            if not timestamp:
                return {'valid': False, 'error': 'Missing timestamp for "at" schedule'}
            
            try:
                if isinstance(timestamp, str):
                    datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
                return {'valid': True, 'error': None}
            except Exception as e:
                return {'valid': False, 'error': f'Invalid timestamp: {str(e)}'}
        
        elif kind == 'every':
            every_ms = schedule_obj.get('everyMs')
            if not every_ms or not isinstance(every_ms, (int, float)):
                return {'valid': False, 'error': 'Invalid everyMs value'}
            if every_ms < 60000:  # Less than 1 minute
                return {'valid': True, 'error': None, 'warning': 'Schedule runs very frequently (< 1 min)'}
            return {'valid': True, 'error': None}
        
        else:
            return {'valid': False, 'error': f'Unknown schedule kind: {kind}'}
    
    def validate_scripts(self, payload_obj: Dict[str, Any]) -> Dict[str, Any]:
        """
        Check if referenced scripts exist and are executable
        Returns: {valid: bool, missing: [paths], warnings: []}
        """
        missing = []
        warnings = []
        
        # Extract script references from payload
        message = payload_obj.get('message', '')
        
        # Look for script paths
        script_patterns = [
            r'scripts/([a-zA-Z0-9_\-\.]+)',
            r'skills/([a-zA-Z0-9_\-/\.]+/SKILL\.md)',
        ]
        
        found_scripts = set()
        for pattern in script_patterns:
            matches = re.findall(pattern, message)
            found_scripts.update(matches)
        
        # Also check for direct file references
        words = message.split()
        for word in words:
            if '/' in word and any(word.endswith(ext) for ext in ['.sh', '.py', '.js']):
                found_scripts.add(word.strip('`"\''))
        
        # Validate each script
        for script_path in found_scripts:
            # Try both relative to workspace and absolute
            paths_to_check = [
                self.workspace / script_path,
                Path(script_path).expanduser()
            ]
            
            found = False
            for path in paths_to_check:
                if path.exists():
                    found = True
                    # Check if executable
                    if not os.access(path, os.X_OK):
                        warnings.append(f'{script_path} exists but is not executable')
                    break
            
            if not found and script_path:  # Only report if it looks like a real path
                missing.append(script_path)
        
        return {
            'valid': len(missing) == 0,
            'missing': missing,
            'warnings': warnings
        }
    
    def validate_dependencies(self, payload_text: str) -> Dict[str, Any]:
        """
        Check if required dependencies are installed
        Returns: {valid: bool, missing: [deps], warnings: []}
        """
        missing = []
        warnings = []
        
        # Python imports
        python_imports = re.findall(r'import\s+([a-zA-Z0-9_\.]+)', payload_text)
        python_imports += re.findall(r'from\s+([a-zA-Z0-9_\.]+)\s+import', payload_text)
        
        for module in python_imports:
            base_module = module.split('.')[0]
            if base_module not in ['os', 'sys', 'json', 're', 'datetime', 'pathlib']:  # stdlib
                try:
                    subprocess.run(
                        ['python3', '-c', f'import {base_module}'],
                        capture_output=True,
                        check=True,
                        timeout=5
                    )
                except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
                    missing.append(f'python:{base_module}')
        
        # Node modules
        node_requires = re.findall(r'require\([\'"]([a-zA-Z0-9_\-\./@]+)[\'"]\)', payload_text)
        for module in node_requires:
            if not module.startswith('.'):  # Not a local module
                try:
                    subprocess.run(
                        ['npm', 'list', '-g', module],
                        capture_output=True,
                        check=True,
                        timeout=5
                    )
                except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
                    warnings.append(f'node:{module} not found in global npm packages')
        
        # Binary commands
        binary_patterns = [
            r'\b(openclaw|gh|git|jq|curl|wget|rsync|rg|fd|bat)\s',
            r'sudo\s+([a-z\-]+)',
        ]
        
        binaries = set()
        for pattern in binary_patterns:
            matches = re.findall(pattern, payload_text)
            binaries.update(matches)
        
        for binary in binaries:
            if binary in ['sudo', 'openclaw']:  # Skip these
                continue
            try:
                subprocess.run(
                    ['which', binary],
                    capture_output=True,
                    check=True,
                    timeout=5
                )
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
                missing.append(f'binary:{binary}')
        
        return {
            'valid': len(missing) == 0,
            'missing': missing,
            'warnings': warnings
        }
    
    def validate_env_vars(self, payload_text: str) -> Dict[str, Any]:
        """
        Check if referenced environment variables exist
        Returns: {valid: bool, missing: [vars], warnings: []}
        """
        missing = []
        warnings = []
        
        # Find env var references
        patterns = [
            r'\$([A-Z_][A-Z0-9_]*)',  # $VAR
            r'\$\{([A-Z_][A-Z0-9_]*)\}',  # ${VAR}
            r'process\.env\.([A-Z_][A-Z0-9_]*)',  # process.env.VAR
            r'os\.getenv\([\'"]([A-Z_][A-Z0-9_]*)[\'"]',  # os.getenv("VAR")
        ]
        
        found_vars = set()
        for pattern in patterns:
            matches = re.findall(pattern, payload_text)
            found_vars.update(matches)
        
        # Check against .env file and system env
        for var in found_vars:
            if var not in self.env_vars and var not in os.environ:
                # Check if it's a commonly available system var
                if var in ['HOME', 'USER', 'PATH', 'SHELL', 'PWD', 'HOSTNAME']:
                    continue
                missing.append(var)
        
        return {
            'valid': len(missing) == 0,
            'missing': missing,
            'warnings': warnings
        }
    
    def dry_run(self, payload_obj: Dict[str, Any]) -> Dict[str, Any]:
        """
        Simulate execution without side-effects
        Returns: {valid: bool, warnings: []}
        """
        warnings = []
        kind = payload_obj.get('kind')
        
        if kind == 'systemEvent':
            text = payload_obj.get('text', '')
            # Check for empty placeholders
            if '${' in text or '{' in text:
                warnings.append('Possible unfilled placeholder in systemEvent text')
            if not text.strip():
                return {'valid': False, 'warnings': ['Empty systemEvent text']}
        
        elif kind == 'agentTurn':
            message = payload_obj.get('message', '')
            if not message.strip():
                return {'valid': False, 'warnings': ['Empty agentTurn message']}
            
            # Check for common issues
            if 'TODO' in message.upper():
                warnings.append('Message contains TODO marker')
            if len(message) > 10000:
                warnings.append('Very long message (>10k chars), may hit context limits')
        
        return {'valid': True, 'warnings': warnings}
    
    def validate_job(self, job: Dict[str, Any]) -> Dict[str, Any]:
        """
        Run all validations on a cron job
        Returns: complete validation report
        """
        report = {
            'job_id': job.get('id', 'unknown'),
            'job_name': job.get('name', 'unknown'),
            'timestamp': datetime.now().isoformat(),
            'overall_valid': True,
            'errors': [],
            'warnings': [],
            'checks': {}
        }
        
        # 1. Schedule validation
        schedule = job.get('schedule', {})
        schedule_result = self.validate_schedule(schedule)
        report['checks']['schedule'] = schedule_result
        if not schedule_result['valid']:
            report['overall_valid'] = False
            report['errors'].append(f"Schedule: {schedule_result['error']}")
        if schedule_result.get('warning'):
            report['warnings'].append(f"Schedule: {schedule_result['warning']}")
        
        # 2. Script validation
        payload = job.get('payload', {})
        script_result = self.validate_scripts(payload)
        report['checks']['scripts'] = script_result
        if not script_result['valid']:
            report['overall_valid'] = False
            for missing in script_result['missing']:
                report['errors'].append(f"Missing script: {missing}")
        report['warnings'].extend([f"Script: {w}" for w in script_result.get('warnings', [])])
        
        # 3. Dependency validation
        payload_text = json.dumps(payload)
        dep_result = self.validate_dependencies(payload_text)
        report['checks']['dependencies'] = dep_result
        if not dep_result['valid']:
            report['overall_valid'] = False
            for missing in dep_result['missing']:
                report['errors'].append(f"Missing dependency: {missing}")
        report['warnings'].extend([f"Dependency: {w}" for w in dep_result.get('warnings', [])])
        
        # 4. Environment variables validation
        env_result = self.validate_env_vars(payload_text)
        report['checks']['env_vars'] = env_result
        if not env_result['valid']:
            # Don't fail validation, just warn
            for missing in env_result['missing']:
                report['warnings'].append(f"Missing env var: {missing}")
        
        # 5. Dry-run simulation
        dryrun_result = self.dry_run(payload)
        report['checks']['dry_run'] = dryrun_result
        if not dryrun_result['valid']:
            report['overall_valid'] = False
            report['errors'].extend([f"Dry-run: {w}" for w in dryrun_result.get('warnings', [])])
        else:
            report['warnings'].extend([f"Dry-run: {w}" for w in dryrun_result.get('warnings', [])])
        
        return report
    
    def generate_report(self, report: Dict[str, Any], output_path: Optional[Path] = None) -> Path:
        """
        Save validation report to disk
        Returns: path to saved report
        """
        if output_path is None:
            date_str = datetime.now().strftime('%Y-%m-%d')
            job_id = report['job_id']
            filename = f"{date_str}-{job_id}.json"
            output_path = self.validation_dir / filename
        
        with open(output_path, 'w') as f:
            json.dump(report, f, indent=2)
        
        return output_path
    
    def notify_telegram(self, report: Dict[str, Any], telegram_id: Optional[str] = None):
        """
        Send Telegram notification for critical failures
        """
        if report['overall_valid'] and len(report['warnings']) == 0:
            return  # No need to notify for clean validation
        
        # Build notification message
        job_name = report['job_name']
        status = "⚠️ WARNINGS" if report['overall_valid'] else "❌ VALIDATION FAILED"
        
        message = f"**Cron Validation: {status}**\n\n"
        message += f"Job: {job_name}\n"
        message += f"ID: {report['job_id']}\n\n"
        
        if report['errors']:
            message += "**Errors:**\n"
            for error in report['errors']:
                message += f"• {error}\n"
            message += "\n"
        
        if report['warnings']:
            message += "**Warnings:**\n"
            for warning in report['warnings'][:5]:  # Limit to 5
                message += f"• {warning}\n"
            if len(report['warnings']) > 5:
                message += f"... and {len(report['warnings']) - 5} more\n"
        
        # Use openclaw message command to send
        try:
            target = telegram_id or "6884477"  # Default to Manu
            subprocess.run(
                ['openclaw', 'message', 'send', '--target', target, '--message', message],
                capture_output=True,
                timeout=10
            )
        except Exception as e:
            print(f"Failed to send Telegram notification: {e}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(description='Validate OpenClaw cron jobs')
    parser.add_argument('--job-json', help='Path to job JSON file or inline JSON')
    parser.add_argument('--job-id', help='Cron job ID to validate (requires openclaw)')
    parser.add_argument('--validate-all', action='store_true', help='Validate all enabled cron jobs')
    parser.add_argument('--no-notify', action='store_true', help='Skip Telegram notifications')
    parser.add_argument('--output', help='Output report path')
    parser.add_argument('--telegram-id', help='Telegram user ID for notifications')
    parser.add_argument('--force', action='store_true', help='Force validation even if job looks valid')
    
    args = parser.parse_args()
    
    validator = CronValidator()
    
    # Get job(s) to validate
    jobs = []
    
    if args.job_json:
        # Load from file or parse inline JSON
        if os.path.exists(args.job_json):
            with open(args.job_json) as f:
                job = json.load(f)
        else:
            job = json.loads(args.job_json)
        jobs.append(job)
    
    elif args.job_id:
        # Fetch from openclaw
        result = subprocess.run(
            ['openclaw', 'cron', 'list', '--json'],
            capture_output=True,
            text=True,
            timeout=30
        )
        if result.returncode != 0:
            print(f"Error: Failed to list cron jobs: {result.stderr}", file=sys.stderr)
            sys.exit(1)
        
        cron_data = json.loads(result.stdout)
        jobs = [j for j in cron_data['jobs'] if j['id'] == args.job_id]
        if not jobs:
            print(f"Error: Job ID {args.job_id} not found", file=sys.stderr)
            sys.exit(1)
    
    elif args.validate_all:
        # Fetch all jobs
        result = subprocess.run(
            ['openclaw', 'cron', 'list', '--json'],
            capture_output=True,
            text=True,
            timeout=30
        )
        if result.returncode != 0:
            print(f"Error: Failed to list cron jobs: {result.stderr}", file=sys.stderr)
            sys.exit(1)
        
        cron_data = json.loads(result.stdout)
        jobs = [j for j in cron_data['jobs'] if j.get('enabled', True)]
    
    else:
        parser.print_help()
        sys.exit(1)
    
    # Validate each job
    all_valid = True
    for job in jobs:
        report = validator.validate_job(job)
        
        # Save report
        output_path = args.output
        if args.validate_all:
            output_path = None  # Auto-generate per job
        report_path = validator.generate_report(report, output_path)
        
        # Print summary
        status = "✅ PASS" if report['overall_valid'] else "❌ FAIL"
        print(f"{status} {report['job_name']} ({report['job_id']})")
        
        if report['errors']:
            for error in report['errors']:
                print(f"  ERROR: {error}")
        
        if report['warnings']:
            for warning in report['warnings'][:3]:
                print(f"  WARN: {warning}")
            if len(report['warnings']) > 3:
                print(f"  ... and {len(report['warnings']) - 3} more warnings")
        
        print(f"  Report: {report_path}")
        print()
        
        # Send notification if critical
        if not args.no_notify and (not report['overall_valid'] or len(report['errors']) > 0):
            validator.notify_telegram(report, args.telegram_id)
        
        if not report['overall_valid']:
            all_valid = False
    
    # Exit with appropriate code
    sys.exit(0 if all_valid else 1)


if __name__ == '__main__':
    main()
