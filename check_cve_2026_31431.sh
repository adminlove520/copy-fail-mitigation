#!/bin/bash
# CVE-2026-31431 Detection Script (Optimized)
# Description: Checks if the system is vulnerable to CVE-2026-31431 (Copy Fail)
# Supports: x86, ARM, Xinchuang OS, Standard Linux distros

set -o pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG_FILE="/tmp/cve-2026-31431-check.log"

function log() {
    echo -e "$1"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

echo "==============================================================="
echo " CVE-2026-31431 (Copy Fail) Detection Script v1.1"
echo "==============================================================="
echo "Log saved to: $LOG_FILE"
echo "" > "$LOG_FILE"

# 1. System Information
OS_ID=$(grep -i '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
OS_NAME=$(grep -i '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
ARCH=$(uname -m)
KERNEL=$(uname -r)

log "${BLUE}[*] System Info:${NC}"
log "  - OS: ${OS_NAME}"
log "  - Arch: ${ARCH}"
log "  - Kernel: ${KERNEL}"

# 2. Kernel Version Check
VULNERABLE=0

function version_ge() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" == "$2" ]
}

function version_lt() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" == "$1" ] && [ "$1" != "$2" ]
}

# Improved version parsing (handles kernels like 5.15.0-101-generic)
K_VER=$(echo $KERNEL | grep -oP '^\d+\.\d+\.\d+')
if [ -z "$K_VER" ]; then
    K_VER=$(echo $KERNEL | cut -d'-' -f1)
fi

# Primary version range check
if version_ge "$K_VER" "4.14"; then
    if version_lt "$K_VER" "6.18.22"; then
        VULNERABLE=1
    elif [[ "$K_VER" == 6.19* ]] && version_lt "$K_VER" "6.19.12"; then
        VULNERABLE=1
    fi
fi

# 3. Distro-specific patch check (Backports)
# Note: Distros often backport fixes. This is a heuristic.
PATCHED=0
if [[ "$OS_ID" == "ubuntu" ]]; then
    # Example check for Ubuntu (placeholder logic, would need specific version strings)
    # Ubuntu 24.04 fixed in 6.8.0-xx.yy
    if dpkg -l linux-image-$(uname -r) 2>/dev/null | grep -q "6.8.0-40"; then
        PATCHED=1
    fi
elif [[ "$OS_ID" == "rhel" || "$OS_ID" == "centos" || "$OS_ID" == "rocky" ]]; then
    # RHEL backports often use the same version number but different release
    if rpm -q kernel-$(uname -r) --changelog 2>/dev/null | grep -qi "CVE-2026-31431"; then
        PATCHED=1
    fi
fi

# 4. Mitigation Check
MITIGATED=0
if [ -f /etc/modprobe.d/disable-algif-aead.conf ]; then
    if grep -q "install algif_aead /bin/false" /etc/modprobe.d/disable-algif-aead.conf; then
        MITIGATED=1
    fi
fi

# 5. Module Check
LOADED=0
if lsmod | grep -q "^algif_aead"; then
    LOADED=1
fi

# 6. Summary Result
log "\n${BLUE}[*] Security Status:${NC}"
if [ "$MITIGATED" -eq 1 ]; then
    log "  - Status: ${GREEN}MITIGATED${NC} (Disabling config active)"
elif [ "$PATCHED" -eq 1 ]; then
    log "  - Status: ${GREEN}SAFE${NC} (Distro patch detected via changelog/version)"
elif [ "$VULNERABLE" -eq 1 ]; then
    if [ "$LOADED" -eq 1 ]; then
        log "  - Status: ${RED}VULNERABLE${NC} (Kernel version affected and module loaded)"
    else
        log "  - Status: ${YELLOW}POTENTIALLY VULNERABLE${NC} (Kernel version affected, module not loaded)"
    fi
else
    log "  - Status: ${GREEN}SAFE${NC} (Kernel version not in affected range)"
fi

log "---------------------------------------------------------------"
if [ "$LOADED" -eq 1 ]; then
    REF_COUNT=$(lsmod | grep "^algif_aead" | awk '{print $3}')
    log "  - Module algif_aead: LOADED (Ref count: $REF_COUNT)"
    if [ "$REF_COUNT" -gt 0 ]; then
        USERS=$(lsof 2>/dev/null | grep AF_ALG | awk '{print $1}' | sort -u | xargs)
        log "  - Active Users: ${USERS:-Unknown}"
    fi
else
    log "  - Module algif_aead: NOT LOADED"
fi

exit 0
