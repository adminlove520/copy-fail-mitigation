#!/bin/bash
# CVE-2026-31431 Remediation Script
# Description: Applies mitigation for CVE-2026-31431 (Copy Fail)
# Author: Accio Assistant
# Date: 2026-04-30

set -o pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "==============================================================="
echo " CVE-2026-31431 (Copy Fail) Remediation Script"
echo "==============================================================="

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root.${NC}"
    exit 1
fi

# 1. Impact Assessment
echo "Checking for potential impact..."
LOADED=0
REF_COUNT=0
if lsmod | grep -q "^algif_aead"; then
    LOADED=1
    REF_COUNT=$(lsmod | grep "^algif_aead" | awk '{print $3}')
fi

if [ "$LOADED" -eq 1 ] && [ "$REF_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}Warning: algif_aead is currently in use (Ref count: $REF_COUNT).${NC}"
    echo "Disabling this module may affect applications using AF_ALG crypto interface."
    read -p "Do you want to proceed with mitigation? [y/N] " response
    if [[ ! "$response" =~ ^[yY]$ ]]; then
        echo "Remediation cancelled."
        exit 0
    fi
fi

# 2. Apply Mitigation
echo "Applying mitigation..."
CONF_FILE="/etc/modprobe.d/disable-algif-aead.conf"

cat <<EOF > "$CONF_FILE"
# Mitigation for CVE-2026-31431 (Copy Fail)
# Created by Remediation Script on $(date)
install algif_aead /bin/false
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Successfully created $CONF_FILE${NC}"
else
    echo -e "${RED}Failed to create $CONF_FILE${NC}"
    exit 1
fi

# 3. Attempt to unload module
if [ "$LOADED" -eq 1 ]; then
    echo "Attempting to unload algif_aead module..."
    modprobe -r algif_aead 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Module algif_aead successfully unloaded.${NC}"
    else
        echo -e "${YELLOW}Could not unload algif_aead (it might be in use or built-in).${NC}"
        echo "The mitigation will take effect after the next reboot or when the module is released."
    fi
fi

# 4. Verification
echo "---------------------------------------------------------------"
if [ -f "$CONF_FILE" ] && grep -q "install algif_aead /bin/false" "$CONF_FILE"; then
    echo -e "Verification: ${GREEN}MITIGATION APPLIED${NC}"
else
    echo -e "Verification: ${RED}MITIGATION FAILED${NC}"
fi

echo "==============================================================="
exit 0
