#!/usr/bin/env python3
"""
GOG CLI Drive Sharing Automation
Automates sharing Google Drive folders using GOG CLI

Requirements:
  - gog CLI installed
  - GOG authentication configured (gog auth add)
  - Environment variables set:
    - GOG_ACCOUNT
    - GOG_KEYRING_BACKEND
    - GOG_KEYRING_PASSWORD

Usage:
  # Share single folder with one email
  python3 gog_drive_share_automation.py \
    --folder-id 1TWOlXn91l8P3voVehbYbB9sQVNirI2Z9 \
    --email user@example.com \
    --permission reader

  # Batch share with multiple emails
  python3 gog_drive_share_automation.py \
    --folder-id <id> \
    --emails user1@example.com,user2@example.com \
    --permission reader

  # Dry run (show what would happen)
  python3 gog_drive_share_automation.py \
    --folder-id <id> \
    --email user@example.com \
    --permission reader \
    --dry-run
"""

import subprocess
import sys
import json
import argparse
import os
from typing import List, Dict, Tuple

class GOGShareAutomation:
    """Automate Drive folder sharing using GOG CLI"""
    
    def __init__(self, dry_run=False, verbose=False):
        self.dry_run = dry_run
        self.verbose = verbose
        self.results = []
    
    def validate_environment(self) -> bool:
        """Validate GOG CLI and environment setup"""
        required_env = ['GOG_ACCOUNT', 'GOG_KEYRING_BACKEND', 'GOG_KEYRING_PASSWORD']
        missing = [var for var in required_env if not os.environ.get(var)]
        
        if missing:
            print(f"❌ Missing environment variables: {', '.join(missing)}", file=sys.stderr)
            return False
        
        # Check if gog is available
        result = subprocess.run(['which', 'gog'], capture_output=True)
        if result.returncode != 0:
            print("❌ GOG CLI not found in PATH", file=sys.stderr)
            return False
        
        if self.verbose:
            print(f"✓ Environment validated:")
            print(f"  - GOG_ACCOUNT: {os.environ['GOG_ACCOUNT']}")
            print(f"  - GOG_KEYRING_BACKEND: {os.environ['GOG_KEYRING_BACKEND']}")
        
        return True
    
    def get_file_info(self, file_id: str) -> Dict:
        """Get file metadata to verify it exists and see its name"""
        cmd = ['gog', 'drive', 'get', file_id, '--json', '--no-input']
        
        if self.verbose:
            print(f"📋 Getting file info: {file_id}")
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
            if result.returncode != 0:
                return {'error': result.stderr}
            return json.loads(result.stdout)
        except Exception as e:
            return {'error': str(e)}
    
    def share_folder(self, folder_id: str, email: str, permission: str = 'reader') -> Tuple[bool, str]:
        """
        Share a folder with an email address
        
        Args:
            folder_id: Google Drive folder ID
            email: Email address to share with
            permission: Permission level (reader, writer, commenter, organizer)
        
        Returns:
            (success: bool, message: str)
        """
        cmd = [
            'gog', 'drive', 'share', folder_id,
            '--email', email,
            '--role', permission,
            '--no-input'
        ]
        
        if self.verbose:
            print(f"🔗 Sharing {folder_id} with {email} ({permission})")
            print(f"   Command: {' '.join(cmd)}")
        
        if self.dry_run:
            return (True, f"[DRY-RUN] Would share with {email}")
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
            
            if result.returncode == 0:
                return (True, f"✓ Shared with {email} ({permission})")
            else:
                # Parse error message
                error_msg = result.stderr.strip()
                if 'cannotInviteNonGoogleUser' in error_msg:
                    return (False, f"✗ {email} is not a valid Google account")
                elif 'notFound' in error_msg:
                    return (False, f"✗ Folder {folder_id} not found")
                elif 'insufficientPermissions' in error_msg:
                    return (False, f"✗ Insufficient permissions to share")
                else:
                    return (False, f"✗ Error: {error_msg}")
        except subprocess.TimeoutExpired:
            return (False, "✗ Command timeout (>15s)")
        except Exception as e:
            return (False, f"✗ Exception: {str(e)}")
    
    def batch_share(self, folder_id: str, emails: List[str], permission: str = 'reader') -> Dict:
        """
        Share with multiple emails, showing progress
        
        Returns:
            Dictionary with success/failure counts and details
        """
        results = {
            'total': len(emails),
            'successful': 0,
            'failed': 0,
            'details': []
        }
        
        print(f"\n📦 Batch sharing folder: {folder_id}")
        print(f"   Recipients: {len(emails)}")
        print(f"   Permission: {permission}")
        print(f"   Dry-run: {self.dry_run}\n")
        
        for i, email in enumerate(emails, 1):
            success, msg = self.share_folder(folder_id, email, permission)
            results['details'].append({
                'email': email,
                'success': success,
                'message': msg
            })
            
            if success:
                results['successful'] += 1
                print(f"  [{i}/{len(emails)}] {msg}")
            else:
                results['failed'] += 1
                print(f"  [{i}/{len(emails)}] {msg}")
        
        print(f"\n📊 Summary:")
        print(f"   Successful: {results['successful']}/{results['total']}")
        print(f"   Failed: {results['failed']}/{results['total']}")
        
        return results

def main():
    parser = argparse.ArgumentParser(
        description='Automate Google Drive sharing using GOG CLI'
    )
    
    parser.add_argument('--folder-id', required=True,
                       help='Google Drive folder ID to share')
    parser.add_argument('--email', 
                       help='Email address to share with')
    parser.add_argument('--emails',
                       help='Comma-separated list of emails')
    parser.add_argument('--permission', default='reader',
                       choices=['reader', 'writer', 'commenter', 'organizer'],
                       help='Permission level (default: reader)')
    parser.add_argument('--dry-run', action='store_true',
                       help='Show what would happen without actually sharing')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Verbose output')
    
    args = parser.parse_args()
    
    # Collect emails
    emails = []
    if args.email:
        emails.append(args.email)
    if args.emails:
        emails.extend([e.strip() for e in args.emails.split(',')])
    
    if not emails:
        parser.error('Either --email or --emails must be provided')
    
    # Create automation instance
    automation = GOGShareAutomation(dry_run=args.dry_run, verbose=args.verbose)
    
    # Validate environment
    if not automation.validate_environment():
        sys.exit(1)
    
    # Get file info to verify folder exists
    file_info = automation.get_file_info(args.folder_id)
    if 'error' in file_info:
        print(f"❌ Failed to get folder info: {file_info['error']}", file=sys.stderr)
        sys.exit(1)
    
    if args.verbose:
        if 'file' in file_info and 'name' in file_info['file']:
            print(f"✓ Folder found: {file_info['file']['name']}\n")
    
    # Perform batch sharing
    results = automation.batch_share(args.folder_id, emails, args.permission)
    
    # Exit with error if any failed
    sys.exit(0 if results['failed'] == 0 else 1)

if __name__ == '__main__':
    main()
