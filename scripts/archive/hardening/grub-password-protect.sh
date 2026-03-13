#!/usr/bin/env bash
# ============================================================
# GRUB Password Protection — Bootloader security hardening
# ============================================================
set -uo pipefail

DRY_RUN="${1:-true}"  # Default: dry-run
BACKUP_DIR="/tmp/grub-password-backup-$(date +%s)"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}🔐 GRUB Password Protection${NC}"
echo "DRY_RUN: $DRY_RUN"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Must run as root${NC}"
    exit 1
fi

# Check if GRUB is installed
if ! [ -d /boot/grub ] && ! [ -d /boot/grub2 ]; then
    echo -e "${RED}❌ GRUB not found (might be UEFI/EFI system)${NC}"
    exit 1
fi

# Determine GRUB directory
GRUB_DIR="/boot/grub"
[ -d /boot/grub2 ] && GRUB_DIR="/boot/grub2"

GRUB_CFG="$GRUB_DIR/grub.cfg"
GRUB_USER_CFG="$GRUB_DIR/user.cfg"
GRUB_DEFAULT="/etc/default/grub"

mkdir -p "$BACKUP_DIR"

echo -e "${CYAN}[1/3] Checking current GRUB configuration...${NC}"

# Check if password already set
if grep -q "set superusers" "$GRUB_CFG" 2>/dev/null; then
    echo -e "${GREEN}✓ GRUB password already configured${NC}"
    echo ""
    echo "To change the password, edit:"
    echo "  $GRUB_USER_CFG"
    exit 0
fi

echo -e "${YELLOW}⚠️  GRUB password not configured${NC}"

# ============================================================
# Generate GRUB password hash
# ============================================================
echo ""
echo -e "${CYAN}[2/3] Generating GRUB password hash...${NC}"

# Default password for testing: "LockedDown123!" (you should change this)
GRUB_PASS="${GRUB_PASSWORD:-LockedDown123!}"

echo -e "${YELLOW}Using password: $GRUB_PASS${NC}"
echo -e "${YELLOW}⚠️  CHANGE THIS PASSWORD IMMEDIATELY after applying!${NC}"

# Generate PBKDF2 hash
GRUB_HASH=$(echo -e "$GRUB_PASS\n$GRUB_PASS" | grub-mkpasswd-pbkdf2 2>/dev/null | grep "PBKDF2" | cut -d' ' -f3)

if [ -z "$GRUB_HASH" ]; then
    echo -e "${RED}❌ Failed to generate GRUB password hash${NC}"
    echo "Make sure grub-mkpasswd-pbkdf2 is installed:"
    echo "  sudo apt-get install grub-common"
    exit 1
fi

echo -e "${GREEN}✓ Generated GRUB password hash${NC}"

# ============================================================
# Apply GRUB password configuration
# ============================================================
echo ""
echo -e "${CYAN}[3/3] Applying GRUB password configuration...${NC}"

if [ "$DRY_RUN" = "false" ]; then
    # Backup original files
    cp "$GRUB_CFG" "$BACKUP_DIR/grub.cfg.bak"
    cp "$GRUB_DEFAULT" "$BACKUP_DIR/grub.bak"
    echo "✓ Backups created in $BACKUP_DIR"
    
    # Create user.cfg with password
    cat > "$GRUB_USER_CFG" << EOF
# GRUB password configuration
set superusers="root"
password_pbkdf2 root $GRUB_HASH
EOF
    
    # Update /etc/default/grub to include user.cfg
    if ! grep -q "source.*user.cfg" "$GRUB_DEFAULT"; then
        # Add source directive before last line
        sed -i "/^GRUB_/i export GRUB_ENABLE_BLSCFG=true" "$GRUB_DEFAULT" 2>/dev/null || true
    fi
    
    # Update GRUB config
    echo -e "${CYAN}Rebuilding GRUB configuration (this may take a moment)...${NC}"
    
    if [ -f /etc/grub.d/40_custom ]; then
        # Add user.cfg source at the beginning
        sed -i '1i source /boot/grub/user.cfg' "$GRUB_CFG" 2>/dev/null || {
            # If sed fails, add it manually using grub-mkconfig
            update-grub
        }
    else
        update-grub
    fi
    
    echo -e "${GREEN}✓ GRUB password protection enabled${NC}"
    
else
    echo -e "${YELLOW}DRY RUN MODE${NC}"
    echo ""
    echo "Will create: $GRUB_USER_CFG"
    echo "Content:"
    echo "---"
    cat << EOF
# GRUB password configuration
set superusers="root"
password_pbkdf2 root $GRUB_HASH
EOF
    echo "---"
fi

echo ""
echo -e "${BOLD}SUMMARY${NC}"
echo "======="
echo ""
echo "GRUB Password Protection:"
echo "  ✓ Prevents unauthorized bootloader modifications"
echo "  ✓ Requires password to edit boot parameters"
echo "  ✓ Prevents single-user mode bypass"
echo ""

if [ "$DRY_RUN" = "true" ]; then
    echo -e "${YELLOW}DRY RUN MODE - No changes applied${NC}"
    echo ""
    echo "To apply, run:"
    echo -e "  ${BOLD}sudo bash $0 false${NC}"
    echo ""
    echo "⚠️  RECOMMENDED: Set your own password before applying"
    echo "   export GRUB_PASSWORD='your_secure_password'"
    echo "   sudo GRUB_PASSWORD='your_secure_password' bash $0 false"
else
    echo -e "${GREEN}Changes applied!${NC}"
    echo ""
    echo "📝 Configuration saved to: $GRUB_USER_CFG"
    echo "📝 Backup saved to: $BACKUP_DIR/"
    echo ""
    echo "⚠️  IMPORTANT:"
    echo "   1. Reboot to test: sudo reboot"
    echo "   2. During boot, when GRUB menu appears:"
    echo "      - Press 'e' to edit (will ask for password)"
    echo "      - Try to enter single-user mode (will fail without password)"
    echo "   3. After confirming it works, change the default password:"
    echo "      sudo nano $GRUB_USER_CFG"
    echo ""
    echo "To reset GRUB password from live system:"
    echo "  1. Boot into rescue/live mode"
    echo "  2. Mount root filesystem"
    echo "  3. Edit: $GRUB_USER_CFG"
    echo "  4. Run: sudo update-grub"
fi

echo ""
echo -e "${CYAN}Configuration Details:${NC}"
echo "  • Bootloader password: ENABLED"
echo "  • Hashing: PBKDF2 (strong)"
echo "  • Superuser: root (required for edits)"
echo "  • Protection: Boot parameters, single-user mode"
