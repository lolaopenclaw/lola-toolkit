#!/bin/bash
#
# GOG CLI Drive Sharing Automation (Bash version)
# Automates sharing Google Drive folders using GOG CLI
#
# Usage:
#   ./gog_drive_share_automation.sh \
#     --folder-id <id> \
#     --email user@example.com \
#     --permission reader
#
#   ./gog_drive_share_automation.sh \
#     --folder-id <id> \
#     --emails "user1@example.com,user2@example.com" \
#     --permission reader

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
FOLDER_ID=""
EMAILS=()
PERMISSION="reader"
DRY_RUN=0
VERBOSE=0

# Functions
print_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

print_verbose() {
    if [[ $VERBOSE -eq 1 ]]; then
        echo -e "${YELLOW}📝 $1${NC}"
    fi
}

validate_environment() {
    local missing=()
    
    for var in GOG_ACCOUNT GOG_KEYRING_BACKEND GOG_KEYRING_PASSWORD; do
        if [[ -z "${!var:-}" ]]; then
            missing+=("$var")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Missing environment variables: ${missing[*]}"
        return 1
    fi
    
    if ! command -v gog &> /dev/null; then
        print_error "GOG CLI not found in PATH"
        return 1
    fi
    
    print_verbose "Environment validated:"
    print_verbose "  - GOG_ACCOUNT: $GOG_ACCOUNT"
    print_verbose "  - GOG_KEYRING_BACKEND: $GOG_KEYRING_BACKEND"
    
    return 0
}

get_file_info() {
    local folder_id=$1
    
    print_verbose "Getting file info: $folder_id"
    
    if ! gog drive get "$folder_id" --json --no-input 2>/dev/null; then
        return 1
    fi
}

share_folder() {
    local folder_id=$1
    local email=$2
    local permission=$3
    
    print_verbose "Sharing $folder_id with $email ($permission)"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        print_info "[DRY-RUN] Would share with $email"
        return 0
    fi
    
    local output
    local exit_code
    
    output=$(gog drive share "$folder_id" \
        --email "$email" \
        --role "$permission" \
        --no-input 2>&1) || exit_code=$?
    
    exit_code=${exit_code:-0}
    
    if [[ $exit_code -eq 0 ]]; then
        print_success "Shared with $email ($permission)"
        return 0
    else
        # Parse error message
        if echo "$output" | grep -q "cannotInviteNonGoogleUser"; then
            print_error "$email is not a valid Google account"
        elif echo "$output" | grep -q "notFound"; then
            print_error "Folder $folder_id not found"
        elif echo "$output" | grep -q "insufficientPermissions"; then
            print_error "Insufficient permissions to share"
        else
            print_error "Failed to share: $output"
        fi
        return 1
    fi
}

batch_share() {
    local folder_id=$1
    shift
    local emails=("$@")
    
    print_info "Batch sharing folder: $folder_id"
    echo "   Recipients: ${#emails[@]}"
    echo "   Permission: $PERMISSION"
    echo "   Dry-run: $([ $DRY_RUN -eq 1 ] && echo 'Yes' || echo 'No')"
    echo ""
    
    local successful=0
    local failed=0
    local count=1
    
    for email in "${emails[@]}"; do
        if share_folder "$folder_id" "$email" "$PERMISSION"; then
            ((successful++))
        else
            ((failed++))
        fi
        echo "  [$count/${#emails[@]}]"
        ((count++))
    done
    
    echo ""
    echo "📊 Summary:"
    echo "   Successful: $successful/${#emails[@]}"
    echo "   Failed: $failed/${#emails[@]}"
    
    return $([ $failed -eq 0 ] && echo 0 || echo 1)
}

show_help() {
    cat << 'HELP'
GOG CLI Drive Sharing Automation (Bash)

USAGE:
  ./gog_drive_share_automation.sh [OPTIONS]

OPTIONS:
  --folder-id ID              Google Drive folder ID (required)
  --email EMAIL               Email to share with (can be used multiple times)
  --emails LIST               Comma-separated emails
  --permission PERM           Permission level: reader|writer|commenter|organizer
                             (default: reader)
  --dry-run                   Show what would happen without actually sharing
  --verbose                   Verbose output
  --help                      Show this help message

EXAMPLES:
  # Share with single email
  ./gog_drive_share_automation.sh \
    --folder-id 1ABC123xyz \
    --email user@example.com

  # Share with multiple emails
  ./gog_drive_share_automation.sh \
    --folder-id 1ABC123xyz \
    --emails "user1@example.com,user2@example.com" \
    --permission reader

  # Dry run
  ./gog_drive_share_automation.sh \
    --folder-id 1ABC123xyz \
    --email user@example.com \
    --dry-run

ENVIRONMENT VARIABLES:
  GOG_ACCOUNT              Gmail account (required)
  GOG_KEYRING_BACKEND      Keyring backend (required, should be 'file')
  GOG_KEYRING_PASSWORD     Keyring password (required)

HELP
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --folder-id)
            FOLDER_ID="$2"
            shift 2
            ;;
        --email)
            EMAILS+=("$2")
            shift 2
            ;;
        --emails)
            IFS=',' read -ra EMAIL_ARRAY <<< "$2"
            for email in "${EMAIL_ARRAY[@]}"; do
                EMAILS+=("${email// /}")  # Trim spaces
            done
            shift 2
            ;;
        --permission)
            PERMISSION="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --verbose)
            VERBOSE=1
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate inputs
if [[ -z "$FOLDER_ID" ]]; then
    print_error "--folder-id is required"
    show_help
    exit 1
fi

if [[ ${#EMAILS[@]} -eq 0 ]]; then
    print_error "Either --email or --emails must be provided"
    show_help
    exit 1
fi

# Validate environment
if ! validate_environment; then
    exit 1
fi

# Verify folder exists
print_verbose "Verifying folder exists..."
if ! get_file_info "$FOLDER_ID" > /dev/null 2>&1; then
    print_error "Failed to access folder: $FOLDER_ID"
    exit 1
fi

print_success "Folder found"
echo ""

# Perform batch sharing
batch_share "$FOLDER_ID" "${EMAILS[@]}"
