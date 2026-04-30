#!/bin/bash
# CVE-2026-31431 Detection Script
# Description: Checks if the system is vulnerable to CVE-2026-31431 (Copy Fail)
# Author: Accio Assistant
# Date: 2026-04-30

set -o pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "==============================================================="
echo " CVE-2026-31431 (Copy Fail) Detection Script"
echo "==============================================================="

# 1. System Information
OS_ID=$(grep -i '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
OS_NAME=$(grep -i '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
ARCH=$(uname -m)
KERNEL=$(uname -r)

echo -e "OS: ${OS_NAME} (${OS_ID})"
echo -e "Arch: ${ARCH}"
echo -e "Kernel: ${KERNEL}"

# 2. Kernel Version Check
# Affected: 4.14 <= version < 6.18.22, 6.19.12, 7.0
VULNERABLE=0

function version_ge() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" == "$2" ]
}

function version_lt() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" == "$1" ] && [ "$1" != "$2" ]
}

# Simplify version for comparison (remove -generic, etc.)
K_VER=$(echo $KERNEL | cut -d'-' -f1)

if version_ge "$K_VER" "4.14"; then
    if version_lt "$K_VER" "6.18.22"; then
        VULNERABLE=1
    elif [[ "$K_VER" == 6.19* ]] && version_lt "$K_VER" "6.19.12"; then
        VULNERABLE=1
    fi
fi

# 3. Mitigation Check
MITIGATED=0
if [ -f /etc/modprobe.d/disable-algif-aead.conf ]; then
    if grep -q "install algif_aead /bin/false" /etc/modprobe.d/disable-algif-aead.conf; then
        MITIGATED=1
    fi
fi

# 4. Module Check
LOADED=0
if lsmod | grep -q "^algif_aead"; then
    LOADED=1
fi

# 5. Result
echo "---------------------------------------------------------------"
if [ "$MITIGATED" -eq 1 ]; then
    echo -e "Status: ${GREEN}MITIGATED${NC} (Mitigation config found)"
elif [ "$VULNERABLE" -eq 1 ]; then
    if [ "$LOADED" -eq 1 ]; then
        echo -e "Status: ${RED}VULNERABLE${NC} (Kernel version affected and module loaded)"
    else
        echo -e "Status: ${YELLOW}POTENTIALLY VULNERABLE${NC} (Kernel version affected, module not loaded)"
    fi
else
    echo -e "Status: ${GREEN}SAFE${NC} (Kernel version not in affected range)"
fi

echo "---------------------------------------------------------------"
if [ "$LOADED" -eq 1 ]; then
    REF_COUNT=$(lsmod | grep "^algif_aead" | awk '{print $3}')
    echo -e "Module algif_aead is LOADED (Ref count: $REF_COUNT)"
else
    echo -e "Module algif_aead is NOT LOADED"
fi

exit 0
