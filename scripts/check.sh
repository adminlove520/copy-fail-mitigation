#!/bin/bash
# CVE-2026-31431 Detection Script (Optimized)
# v1.3.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]=" CVE-2026-31431 (Copy Fail) 检测脚本 v1.3"
    T[log_saved]="日志已保存至: "
    T[sys_info]="[*] 系统信息:"
    T[os]="  - 操作系统: "
    T[arch]="  - 架构: "
    T[kernel]="  - 内核: "
    T[sec_status]="[*] 安全状态评估:"
    T[mitigated]="已缓解 (发现禁用配置)"
    T[patched]="安全 (检测到发行版补丁)"
    T[vulnerable]="存在漏洞 (内核版本受影响且模块已加载)"
    T[pot_vulnerable]="潜在风险 (内核版本受影响，模块未加载)"
    T[safe]="安全 (内核版本不在受影响范围)"
    T[builtin]="潜在风险 (模块已编译进内核，禁用措施无效，请尽快升级内核)"
    T[mod_status]="[*] 模块状态 (algif_aead):"
    T[loaded]="已加载 (引用计数: "
    T[not_loaded]="未加载"
    T[is_builtin]=" (内置于内核)"
    T[active_users]="  - 活跃用户: "
else
    T[header]=" CVE-2026-31431 (Copy Fail) Detection Script v1.3"
    T[log_saved]="Log saved to: "
    T[sys_info]="[*] System Info:"
    T[os]="  - OS: "
    T[arch]="  - Arch: "
    T[kernel]="  - Kernel: "
    T[sec_status]="[*] Security Status Assessment:"
    T[mitigated]="MITIGATED (Disabling config active)"
    T[patched]="SAFE (Distro patch detected)"
    T[vulnerable]="VULNERABLE (Kernel version affected and module loaded)"
    T[pot_vulnerable]="POTENTIALLY VULNERABLE (Kernel version affected, module not loaded)"
    T[safe]="SAFE (Kernel version not in affected range)"
    T[builtin]="POTENTIALLY VULNERABLE (Module built-in, mitigation won't work, upgrade kernel!)"
    T[mod_status]="[*] Module Status (algif_aead):"
    T[loaded]="LOADED (Ref count: "
    T[not_loaded]="NOT LOADED"
    T[is_builtin]=" (Built-in)"
    T[active_users]="  - Active Users: "
fi

echo "==============================================================="
echo "${T[header]}"
echo "==============================================================="
log "" "${T[log_saved]}$LOG_FILE"
echo "" > "$LOG_FILE"

# 1. System Info
OS_ID=$(grep -i '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
OS_NAME=$(grep -i '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
ARCH=$(uname -m)
KERNEL=$(uname -r)

log "${BLUE}" "${T[sys_info]}"
log "" "${T[os]}${OS_NAME}"
log "" "${T[arch]}${ARCH}"
log "" "${T[kernel]}${KERNEL}"

# 2. Heuristics
VULNERABLE=0
K_VER=$(echo $KERNEL | grep -oP '^\d+\.\d+\.\d+' | head -n1)
[[ -z "$K_VER" ]] && K_VER=$(echo $KERNEL | cut -d'-' -f1)

if version_ge "$K_VER" "4.14"; then
    if version_lt "$K_VER" "6.18.22"; then VULNERABLE=1;
    elif [[ "$K_VER" == 6.19* ]] && version_lt "$K_VER" "6.19.12"; then VULNERABLE=1; fi
fi

# 3. Patch Check
PATCHED=0
if [[ "$OS_ID" == "ubuntu" ]] && dpkg -l linux-image-$(uname -r) 2>/dev/null | grep -q "6.8.0-40"; then PATCHED=1;
elif [[ "$OS_ID" =~ (rhel|centos|rocky|kylin|uos) ]] && rpm -q kernel-$(uname -r) --changelog 2>/dev/null | grep -qi "CVE-2026-31431"; then PATCHED=1; fi

# 4. Mitigation/Built-in Check
MITIGATED=0
[[ -f "/etc/modprobe.d/disable-algif-aead.conf" ]] && grep -q "install algif_aead /bin/false" /etc/modprobe.d/disable-algif-aead.conf && MITIGATED=1

BUILTIN=0
is_builtin "algif_aead" && BUILTIN=1

# 5. Result
log "\n${BLUE}" "${T[sec_status]}"
if [ "$PATCHED" -eq 1 ]; then log "${GREEN}" "  - Status: ${T[patched]}"
elif [ "$MITIGATED" -eq 1 ]; then log "${GREEN}" "  - Status: ${T[mitigated]}"
elif [ "$VULNERABLE" -eq 1 ]; then
    if lsmod | grep -q "^algif_aead"; then log "${RED}" "  - Status: ${T[vulnerable]}"
    elif [ "$BUILTIN" -eq 1 ]; then log "${RED}" "  - Status: ${T[builtin]}"
    else log "${YELLOW}" "  - Status: ${T[pot_vulnerable]}"; fi
else log "${GREEN}" "  - Status: ${T[safe]}"; fi

# 6. Module Details
log "\n${BLUE}" "${T[mod_status]}"
if lsmod | grep -q "^algif_aead"; then
    REF_COUNT=$(lsmod | grep "^algif_aead" | awk '{print $3}')
    log "" "  - ${T[loaded]}${REF_COUNT})"
    USERS=$(lsof 2>/dev/null | grep AF_ALG | awk '{print $1}' | sort -u | xargs)
    [[ -n "$USERS" ]] && log "" "${T[active_users]}$USERS"
elif [ "$BUILTIN" -eq 1 ]; then log "" "  - Status: ${T[is_builtin]}"
else log "" "  - Status: ${T[not_loaded]}"; fi

exit 0
