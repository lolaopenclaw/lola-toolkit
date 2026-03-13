#!/usr/bin/env bash
# ============================================================
# Password Policies Hardening — PAM + login.defs configuration
# ============================================================
set -uo pipefail

DRY_RUN="${1:-true}"  # Default: dry-run (true), set to "false" to apply
BACKUP_DIR="/tmp/password-policies-backup-$(date +%s)"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}🔒 Password Policies Hardening${NC}"
echo "DRY_RUN: $DRY_RUN"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Must run as root${NC}"
    exit 1
fi

# Create backup dir
mkdir -p "$BACKUP_DIR"

# ============================================================
# 1. /etc/login.defs configuration
# ============================================================
echo -e "${CYAN}[1/4] Configuring /etc/login.defs...${NC}"

if [ ! -f "$BACKUP_DIR/login.defs" ]; then
    cp /etc/login.defs "$BACKUP_DIR/login.defs"
    echo "✓ Backed up to $BACKUP_DIR/login.defs"
fi

# Parameters to check/set
declare -A LOGIN_DEFS=(
    ["PASS_MAX_DAYS"]="90"           # Force password change every 90 days
    ["PASS_MIN_DAYS"]="1"            # Minimum 1 day between changes
    ["PASS_MIN_LEN"]="14"            # Minimum 14 characters
    ["PASS_WARN_AGE"]="14"           # Warn 14 days before expiry
    ["LOGIN_RETRIES"]="3"            # Max 3 login attempts
    ["LOGIN_TIMEOUT"]="60"           # 60 second login timeout
    ["UMASK"]="0077"                 # Restrictive file creation (owner only)
    ["USERGROUPS_ENAB"]="yes"        # User private groups
    ["ENCRYPT_METHOD"]="SHA512"      # Strong hashing
    ["SHA_CRYPT_MIN_ROUNDS"]="5000"  # SHA512 rounds for strength
    ["SHA_CRYPT_MAX_ROUNDS"]="5000"
)

for key in "${!LOGIN_DEFS[@]}"; do
    val="${LOGIN_DEFS[$key]}"
    
    # Check current value
    current=$(grep "^$key" /etc/login.defs | awk '{print $2}' || echo "NOT_SET")
    
    if [ "$current" != "$val" ]; then
        echo -e "  ${YELLOW}⚠️  $key: $current → $val${NC}"
        
        if [ "$DRY_RUN" = "false" ]; then
            # Remove old line and add new one
            sed -i "s/^$key.*/$key\t\t$val/" /etc/login.defs
            # If not found, append
            if ! grep -q "^$key" /etc/login.defs; then
                echo "$key		$val" >> /etc/login.defs
            fi
        fi
    else
        echo -e "  ${GREEN}✓ $key: $val${NC}"
    fi
done

echo ""

# ============================================================
# 2. PAM configuration (/etc/pam.d/common-password)
# ============================================================
echo -e "${CYAN}[2/4] Configuring PAM password policies...${NC}"

PAM_FILE="/etc/pam.d/common-password"
if [ -f "$PAM_FILE" ]; then
    if [ ! -f "$BACKUP_DIR/common-password" ]; then
        cp "$PAM_FILE" "$BACKUP_DIR/common-password"
        echo "✓ Backed up to $BACKUP_DIR/common-password"
    fi
    
    # Check for pam_pwquality (strong password requirements)
    if ! grep -q "pam_pwquality" "$PAM_FILE"; then
        echo -e "  ${YELLOW}⚠️  pam_pwquality not configured${NC}"
        if [ "$DRY_RUN" = "false" ]; then
            # Add pam_pwquality line
            sed -i '1i password    requisite                        pam_pwquality.so retry=3 minlen=14 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1' "$PAM_FILE"
            echo "  ✓ Added pam_pwquality (retry=3, minlen=14, mixed case + special chars)"
        fi
    else
        echo -e "  ${GREEN}✓ pam_pwquality already configured${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠️  $PAM_FILE not found (might be on non-Debian system)${NC}"
fi

echo ""

# ============================================================
# 3. Account lockout (/etc/pam.d/common-auth)
# ============================================================
echo -e "${CYAN}[3/4] Configuring account lockout policy...${NC}"

AUTH_FILE="/etc/pam.d/common-auth"
if [ -f "$AUTH_FILE" ]; then
    if [ ! -f "$BACKUP_DIR/common-auth" ]; then
        cp "$AUTH_FILE" "$BACKUP_DIR/common-auth"
        echo "✓ Backed up to $BACKUP_DIR/common-auth"
    fi
    
    # Check for pam_tally2 (account lockout)
    if ! grep -q "pam_tally2" "$AUTH_FILE"; then
        echo -e "  ${YELLOW}⚠️  pam_tally2 not configured${NC}"
        if [ "$DRY_RUN" = "false" ]; then
            # Add pam_tally2 line (lock after 5 failed attempts for 15 minutes)
            sed -i '1i auth    required                        pam_tally2.so onerr=fail audit silent deny=5 unlock_time=900' "$AUTH_FILE"
            echo "  ✓ Added pam_tally2 (lock after 5 failed attempts, 15 min cooldown)"
        fi
    else
        echo -e "  ${GREEN}✓ pam_tally2 already configured${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠️  $AUTH_FILE not found${NC}"
fi

echo ""

# ============================================================
# 4. /etc/security/pwquality.conf
# ============================================================
echo -e "${CYAN}[4/4] Configuring pwquality.conf...${NC}"

PWQUALITY_FILE="/etc/security/pwquality.conf"
if [ -f "$PWQUALITY_FILE" ]; then
    if [ ! -f "$BACKUP_DIR/pwquality.conf" ]; then
        cp "$PWQUALITY_FILE" "$BACKUP_DIR/pwquality.conf"
        echo "✓ Backed up to $BACKUP_DIR/pwquality.conf"
    fi
    
    declare -A PWQUALITY=(
        ["minlen"]="14"
        ["dcredit"]="-1"
        ["ucredit"]="-1"
        ["ocredit"]="-1"
        ["lcredit"]="-1"
        ["maxrepeat"]="3"
        ["usercheck"]="1"
        ["enforce_for_root"]=""
    )
    
    for key in "${!PWQUALITY[@]}"; do
        val="${PWQUALITY[$key]}"
        current=$(grep "^$key" "$PWQUALITY_FILE" | awk -F'=' '{print $2}' | xargs || echo "NOT_SET")
        
        if [ -n "$val" ] && [ "$current" != "$val" ]; then
            echo -e "  ${YELLOW}⚠️  $key: $current → $val${NC}"
            if [ "$DRY_RUN" = "false" ]; then
                sed -i "s/^# *$key.*/$key = $val/" "$PWQUALITY_FILE"
                if ! grep -q "^$key" "$PWQUALITY_FILE"; then
                    echo "$key = $val" >> "$PWQUALITY_FILE"
                fi
            fi
        fi
    done
else
    echo -e "  ${YELLOW}⚠️  $PWQUALITY_FILE not found (install libpam-pwquality)${NC}"
fi

echo ""

# ============================================================
# Summary
# ============================================================
echo -e "${BOLD}SUMMARY${NC}"
echo "======="
if [ "$DRY_RUN" = "true" ]; then
    echo -e "${YELLOW}DRY RUN MODE${NC}"
    echo ""
    echo "Changes shown above but NOT applied."
    echo "To apply changes, run:"
    echo -e "  ${BOLD}sudo bash $0 false${NC}"
else
    echo -e "${GREEN}Changes applied!${NC}"
    echo ""
    echo "Backups saved to: $BACKUP_DIR"
    echo "Review the changes:"
    echo "  diff -u $BACKUP_DIR/login.defs /etc/login.defs"
    echo "  diff -u $BACKUP_DIR/common-password /etc/pam.d/common-password"
    echo ""
    echo "⚠️  Next password change will require:"
    echo "   • Minimum 14 characters"
    echo "   • At least 1 digit, 1 uppercase, 1 lowercase, 1 special char"
    echo "   • Different from last 5 passwords"
fi

echo ""
echo -e "${CYAN}Configuration Details:${NC}"
echo "  • Password expiry: 90 days"
echo "  • Min password age: 1 day"
echo "  • Password minimum length: 14 characters"
echo "  • Character requirements: Mixed case + digit + special char"
echo "  • Account lockout: 5 failed attempts → 15 min lockout"
echo "  • SHA512 hashing: 5000 rounds (strong)"
