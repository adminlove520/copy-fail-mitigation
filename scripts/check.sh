#!/bin/bash
# CVE-2026-31431 Detection Script (Rigorous v1.7.0)
# Production Ready - Supports x86/ARM, Xinchuang OS, Standard Linux

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

check_deps python3 grep sed awk lsmod uname || exit 1

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]=" CVE-2026-31431 (Copy Fail) 深度安全检测 v1.7.0"
    T[sys_info]="[*] 系统分析:"
    T[sec_status]="[*] 安全机制检测:"
    T[risk_unprivileged]="[!] 风险: 非特权用户可直接访问 AF_ALG 接口"
    T[perm_denied]="[+] 安全: 非特权用户访问已受限"
    T[builtin_warning]="[!] 警告: 漏洞组件已内置于内核 (Built-in)"
    T[final_vulnerable]="结果: 【受影响】需要执行缓解脚本"
    T[final_low_risk]="结果: 【低风险】接口已受限，但建议应用补丁"
    T[final_safe]="结果: 【安全】系统不受此漏洞影响"
else
    T[header]=" CVE-2026-31431 (Copy Fail) Rigorous Detection v1.7.0"
    T[sys_info]="[*] System Info:"
    T[sec_status]="[*] Security Status:"
    T[risk_unprivileged]="[!] RISK: Unprivileged users can access AF_ALG"
    T[perm_denied]="[+] SAFE: Unprivileged access is restricted"
    T[builtin_warning]="[!] WARNING: Component is built-in to kernel"
    T[final_vulnerable]="Result: VULNERABLE - Action Required"
    T[final_low_risk]="Result: LOW RISK - Interface restricted"
    T[final_safe]="Result: SAFE"
fi

echo "==============================================================="
echo "${T[header]}"
echo "==============================================================="

# 1. Info gathering
log "" "${T[sys_info]}"
log "" "  - OS: ${OS_NAME}"
log "" "  - Kernel: $(uname -r)"
log "" "  - Security: $(check_security_modules)"

# 2. Kernel Window Check
VULNERABLE=0
K_VER=$(echo $(uname -r) | grep -oP '^\d+\.\d+\.\d+' | head -n1)
[[ -z "$K_VER" ]] && K_VER=$(echo $(uname -r) | cut -d'-' -f1)

if version_ge "$K_VER" "4.14" && (version_lt "$K_VER" "6.18.22" || ([[ "$K_VER" == 6.19* ]] && version_lt "$K_VER" "6.19.12")); then
    VULNERABLE=1
fi

# 3. Exploitability
log "" "${T[sec_status]}"
EFF_STATUS=$(check_unprivileged_crypto)
if [[ "$EFF_STATUS" == "ACCESSIBLE" ]]; then
    log "${RED}" "${T[risk_unprivileged]}"
    CAN_EXPLOIT=1
else
    log "${GREEN}" "${T[perm_denied]}"
    CAN_EXPLOIT=0
fi

# 4. Built-in
BUILTIN=0
if is_builtin "algif_aead"; then
    BUILTIN=1
    log "${YELLOW}" "${T[builtin_warning]}"
fi

# 5. Summary
echo "---------------------------------------------------------------"
if [[ "$VULNERABLE" -eq 0 ]]; then
    log "${GREEN}" "${T[final_safe]}"
elif [[ "$CAN_EXPLOIT" -eq 0 ]]; then
    log "${YELLOW}" "${T[final_low_risk]}"
else
    log "${RED}" "${T[final_vulnerable]}"
fi
echo "==============================================================="
exit 0
