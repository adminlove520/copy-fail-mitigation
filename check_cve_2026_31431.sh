#!/bin/bash
# CVE-2026-31431 Detection Script (Optimized with i18n)
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

# Language Detection
[[ "$LANG" == *"zh_CN"* ]] && CURRENT_LANG="zh" || CURRENT_LANG="en"

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]=" CVE-2026-31431 (Copy Fail) 检测脚本 v1.2"
    T[log_saved]="日志已保存至: "
    T[sys_info]="[*] 系统信息:"
    T[os]="  - 操作系统: "
    T[arch]="  - 架构: "
    T[kernel]="  - 内核: "
    T[sec_status]="[*] 安全状态:"
    T[mitigated]="已缓解 (发现禁用配置)"
    T[patched]="安全 (检测到发行版补丁)"
    T[vulnerable]="存在漏洞 (内核版本受影响且模块已加载)"
    T[pot_vulnerable]="潜在风险 (内核版本受影响，模块未加载)"
    T[safe]="安全 (内核版本不在受影响范围)"
    T[mod_status]="  - algif_aead 模块: "
    T[loaded]="已加载 (引用计数: "
    T[not_loaded]="未加载"
    T[active_users]="  - 活跃用户: "
else
    T[header]=" CVE-2026-31431 (Copy Fail) Detection Script v1.2"
    T[log_saved]="Log saved to: "
    T[sys_info]="[*] System Info:"
    T[os]="  - OS: "
    T[arch]="  - Arch: "
    T[kernel]="  - Kernel: "
    T[sec_status]="[*] Security Status:"
    T[mitigated]="MITIGATED (Disabling config active)"
    T[patched]="SAFE (Distro patch detected)"
    T[vulnerable]="VULNERABLE (Kernel version affected and module loaded)"
    T[pot_vulnerable]="POTENTIALLY VULNERABLE (Kernel version affected, module not loaded)"
    T[safe]="SAFE (Kernel version not in affected range)"
    T[mod_status]="  - Module algif_aead: "
    T[loaded]="LOADED (Ref count: "
    T[not_loaded]="NOT LOADED"
    T[active_users]="  - Active Users: "
fi

function log() {
    echo -e "$1"
    # Strip ANSI colors for file log
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') $1" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
}

echo "==============================================================="
echo "${T[header]}"
echo "==============================================================="
log "${T[log_saved]}$LOG_FILE"
echo "" > "$LOG_FILE"

# 1. System Information
OS_ID=$(grep -i '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
OS_NAME=$(grep -i '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
ARCH=$(uname -m)
KERNEL=$(uname -r)

log "${BLUE}${T[sys_info]}${NC}"
log "${T[os]}${OS_NAME}"
log "${T[arch]}${ARCH}"
log "${T[kernel]}${KERNEL}"

# 2. Kernel Version Check
VULNERABLE=0

function version_ge() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" == "$2" ]
}

function version_lt() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" == "$1" ] && [ "$1" != "$2" ]
}

# Improved version parsing (handles kernels like 5.15.0-101-generic)
K_VER=$(echo $KERNEL | grep -oP '^\d+\.\d+\.\d+' | head -n1)
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
PATCHED=0
if [[ "$OS_ID" == "ubuntu" ]]; then
    if dpkg -l linux-image-$(uname -r) 2>/dev/null | grep -q "6.8.0-40"; then
        PATCHED=1
    fi
elif [[ "$OS_ID" == "rhel" || "$OS_ID" == "centos" || "$OS_ID" == "rocky" ]]; then
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
log "\n${BLUE}${T[sec_status]}${NC}"
if [ "$MITIGATED" -eq 1 ]; then
    log "  - Status: ${GREEN}${T[mitigated]}${NC}"
elif [ "$PATCHED" -eq 1 ]; then
    log "  - Status: ${GREEN}${T[patched]}${NC}"
elif [ "$VULNERABLE" -eq 1 ]; then
    if [ "$LOADED" -eq 1 ]; then
        log "  - Status: ${RED}${T[vulnerable]}${NC}"
    else
        log "  - Status: ${YELLOW}${T[pot_vulnerable]}${NC}"
    fi
else
    log "  - Status: ${GREEN}${T[safe]}${NC}"
fi

log "---------------------------------------------------------------"
if [ "$LOADED" -eq 1 ]; then
    REF_COUNT=$(lsmod | grep "^algif_aead" | awk '{print $3}')
    log "${T[mod_status]}${T[loaded]}${REF_COUNT})"
    if [ "$REF_COUNT" -gt 0 ]; then
        USERS=$(lsof 2>/dev/null | grep AF_ALG | awk '{print $1}' | sort -u | xargs)
        log "${T[active_users]}${USERS:-Unknown}"
    fi
else
    log "${T[mod_status]}${T[not_loaded]}"
fi

exit 0
