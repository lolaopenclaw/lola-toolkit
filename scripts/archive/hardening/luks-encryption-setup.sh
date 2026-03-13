#!/usr/bin/env bash
# ============================================================
# LUKS Encryption Setup — Full disk/partition encryption guide
# ============================================================
set -uo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}🔐 LUKS Encryption Setup Guide${NC}\n"

# Check current encryption status
echo -e "${CYAN}[1] Current Encryption Status${NC}"

# Check for LUKS-encrypted partitions
if [ -x "$(command -v cryptsetup)" ]; then
    luks_count=$(cryptsetup luksDump /dev/* 2>/dev/null | grep -c "LUKS" || echo 0)
    if [ "$luks_count" -gt 0 ]; then
        echo -e "${GREEN}✓ LUKS encryption detected on system${NC}"
        cryptsetup status $(ls /dev/mapper/* 2>/dev/null | head -1) 2>/dev/null || true
    else
        echo -e "${YELLOW}⚠️  No LUKS encryption detected${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  cryptsetup not installed${NC}"
fi

echo ""

# Check for dm-crypt
echo -e "${CYAN}[2] Full Disk Encryption Check${NC}"

for partition in $(lsblk -ln -o NAME,TYPE | awk '$2=="disk" {print "/dev/"$1}'); do
    if cryptsetup isLuks "$partition" 2>/dev/null; then
        echo "✓ $partition is LUKS encrypted"
    fi
done

echo ""

# Current filesystem status
echo -e "${CYAN}[3] Current Filesystem Status${NC}"

df -h | grep -E "^/dev/" | awk '{print "  "$1" → "$6" ("$5")"}'

echo ""
echo -e "${BOLD}LUKS ENCRYPTION GUIDE${NC}"
echo "======================="
echo ""
echo "⚠️  WARNING: Enabling encryption on active system requires:"
echo "  1. Full system backup (critical data!)"
echo "  2. Live USB/recovery environment"
echo "  3. Several hours (depending on disk size)"
echo "  4. Careful planning"
echo ""

echo -e "${CYAN}OPTION A: Encrypt New Partition (Recommended for Data)${NC}"
echo ""
echo "For /var, /home, or other data partitions:"
echo ""
echo "1. Create new encrypted partition:"
echo "   # List available partitions"
echo "   sudo fdisk -l"
echo ""
echo "2. Create LUKS volume (example: /dev/sda2):"
echo "   sudo cryptsetup luksFormat /dev/sda2"
echo "   (Confirm with 'YES' and enter strong passphrase)"
echo ""
echo "3. Open LUKS volume:"
echo "   sudo cryptsetup luksOpen /dev/sda2 crypt_data"
echo ""
echo "4. Create filesystem:"
echo "   sudo mkfs.ext4 /dev/mapper/crypt_data"
echo ""
echo "5. Mount encrypted filesystem:"
echo "   sudo mkdir -p /mnt/encrypted"
echo "   sudo mount /dev/mapper/crypt_data /mnt/encrypted"
echo ""
echo "6. Configure permanent mount (fstab):"
echo "   Edit: /etc/crypttab"
echo "   Add: crypt_data /dev/sda2 none luks"
echo ""
echo "   Edit: /etc/fstab"
echo "   Add: /dev/mapper/crypt_data /mnt/encrypted ext4 defaults 0 0"
echo ""

echo -e "${CYAN}OPTION B: Full System Encryption (Complex - Live USB Required)${NC}"
echo ""
echo "For entire disk encryption (new installs recommended):"
echo ""
echo "1. Boot from Ubuntu Live USB"
echo "2. Run installer"
echo "3. At disk partitioning → 'Encrypt the new Ubuntu installation'"
echo "4. Choose encryption type (AES-256 recommended)"
echo "5. Set strong passphrase"
echo "6. Complete installation"
echo ""
echo "Encrypted /root filesystem will require password at boot"
echo ""

echo -e "${CYAN}OPTION C: LUKS Performance Optimization${NC}"
echo ""
echo "For faster encrypted volumes (SSD-friendly):"
echo ""
echo "1. Check LUKS version:"
echo "   cryptsetup --version"
echo ""
echo "2. Use LUKS2 format (faster, better security):"
echo "   sudo cryptsetup luksFormat --type luks2 /dev/sda2"
echo ""
echo "3. Optimize for SSD:"
echo "   sudo cryptsetup luksFormat --type luks2 \\"
echo "     --cipher aes-xts-plain64 \\"
echo "     --key-size 512 \\"
echo "     --iter-time 2000 \\"
echo "     /dev/sda2"
echo ""

echo ""
echo -e "${BOLD}SECURITY RECOMMENDATIONS${NC}"
echo "=========================="
echo ""
echo "✓ Encryption Type: AES-256-XTS (FIPS 140-2 approved)"
echo "✓ Key Size: 512-bit (with XTS mode)"
echo "✓ Passphrase: 20+ characters, mix of all types"
echo "✓ Backup: Keep encrypted backup of passphrase:"
echo "   • NOT in password managers"
echo "   • Separate secure location (safe, encrypted external drive)"
echo ""

echo -e "${BOLD}CURRENT RECOMMENDATIONS FOR THIS SYSTEM${NC}"
echo "========================================"
echo ""
echo "💡 Since you have an active VPS:"
echo ""
echo "✓ Approach 1: Data-only encryption (RECOMMENDED)"
echo "  └─ Encrypt /home or separate data volume"
echo "  └─ No reboot required"
echo "  └─ Minimal performance impact"
echo ""
echo "⚠️  Approach 2: Full system encryption"
echo "  └─ Requires: Live recovery environment"
echo "  └─ Best for: New system setup"
echo "  └─ May be complex on VPS (depends on provider)"
echo ""

echo ""
echo -e "${CYAN}USEFUL COMMANDS${NC}"
echo ""
echo "Check LUKS status:"
echo "  sudo cryptsetup luksDump /dev/sda2"
echo ""
echo "List open encrypted volumes:"
echo "  sudo cryptsetup status"
echo ""
echo "Change LUKS passphrase:"
echo "  sudo cryptsetup luksChangeKey /dev/sda2"
echo ""
echo "Add additional passphrase (key slot):"
echo "  sudo cryptsetup luksAddKey /dev/sda2"
echo ""
echo "Check encryption performance:"
echo "  sudo cryptsetup benchmark"
echo ""

echo ""
echo -e "${YELLOW}⚠️  This VPS is likely already managed by hosting provider${NC}"
echo "Check with provider before attempting full disk encryption"
echo ""
echo -e "${BOLD}Status:${NC} ℹ️  Informational guide only (no changes applied)"
