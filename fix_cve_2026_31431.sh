#!/bin/bash
# CVE-2026-31431 Remediation Script (Optimized)
# Description: Applies or rolls back mitigation for CVE-2026-31431
# Author: Accio Assistant
# Date: 2026-04-30

set -o pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONF_FILE="/etc/modprobe.d/disable-algif-aead.conf"

function usage() {
    echo "Usage: $0 [apply|rollback] [-y]"
    echo "  apply    : Disables algif_aead module (Default)"
    echo "  rollback : Re-enables algif_aead module"
    echo "  -y       : Non-interactive mode"
    exit 1
}

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root.${NC}"
    exit 1
fi

ACTION=${1:-apply}
FORCE=0
if [[ "$*" == *"-y"* || "$*" == *"--yes"* ]]; then
    FORCE=1
fi

echo "==============================================================="
echo " CVE-2026-31431 (Copy Fail) Remediation Script v1.1"
echo "==============================================================="

case "$ACTION" in
    apply)
        # 1. Impact Assessment
        echo -e "${BLUE}[*] Impact Assessment...${NC}"
        LOADED=0
        if lsmod | grep -q "^algif_aead"; then
            LOADED=1
            REF_COUNT=$(lsmod | grep "^algif_aead" | awk '{print $3}')
            if [ "$REF_COUNT" -gt 0 ]; then
                echo -e "${YELLOW}Warning: algif_aead is in use (Ref: $REF_COUNT).${NC}"
                if [ "$FORCE" -eq 0 ]; then
                    read -p "Apply mitigation anyway? [y/N] " res
                    [[ ! "$res" =~ ^[yY]$ ]] && exit 0
                fi
            fi
        fi

        # 2. Apply
        echo -e "${BLUE}[*] Applying mitigation...${NC}"
        cat <<EOF > "$CONF_FILE"
# Mitigation for CVE-2026-31431 (Copy Fail)
# Created on $(date)
install algif_aead /bin/false
EOF
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[+] Created $CONF_FILE${NC}"
        else
            echo -e "${RED}[!] Failed to create config${NC}"
            exit 1
        fi

        # 3. Unload
        if [ "$LOADED" -eq 1 ]; then
            echo -e "${BLUE}[*] Unloading module...${NC}"
            modprobe -r algif_aead 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}[+] Module unloaded successfully.${NC}"
            else
                echo -e "${YELLOW}[!] Could not unload. Will take effect after reboot.${NC}"
            fi
        fi
        ;;

    rollback)
        echo -e "${BLUE}[*] Rolling back mitigation...${NC}"
        if [ -f "$CONF_FILE" ]; then
            rm -f "$CONF_FILE"
            echo -e "${GREEN}[+] Removed $CONF_FILE${NC}"
            echo -e "${BLUE}[*] You may need to run 'modprobe algif_aead' to reload.${NC}"
        else
            echo -e "${YELLOW}[!] No mitigation config found to remove.${NC}"
        fi
        ;;

    *)
        usage
        ;;
esac

echo "==============================================================="
exit 0
