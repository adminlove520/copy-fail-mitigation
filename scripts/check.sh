#!/bin/bash
# CVE-2026-31431 Detection Script (Rigorous v1.9.1)
# UI Optimized - Production Ready

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

check_deps python3 grep sed awk lsmod uname || exit 1

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]="CVE-2026-31431 (Copy Fail) 深度安全检测"
    T[sys_info]="基础环境分析"
    T[sec_status]="内核与接口安全检测"
    T[risk_unprivileged]="[!] 风险提示: 非特权用户可直接访问 AF_ALG 接口"
    T[perm_denied]="[+] 安全确认: 非特权用户访问已受限"
    T[builtin_warning]="[!] 严重警告: 漏洞组件已编译进内核 (Built-in)，缓解脚本将无效"
    T[final_vulnerable]="最终结果: 【 受影响 (VULNERABLE) 】"
    T[final_low_risk]="最终结果: 【 低风险 (LOW RISK) 】"
    T[final_safe]="最终结果: 【 安全 (SAFE) 】"
    T[recom_vulnerable]="建议: 立即执行修复脚本 scripts/fix.sh apply"
    T[recom_low_risk]="建议: 虽然接口已受限，但强烈建议更新内核以彻底修复"
    T[recom_safe]="说明: 系统当前不受此漏洞威胁"
else
    T[header]="CVE-2026-31431 (Copy Fail) Rigorous Detection"
    T[sys_info]="System Environment Analysis"
    T[sec_status]="Kernel & Interface Security Check"
    T[risk_unprivileged]="[!] RISK: Unprivileged users can access AF_ALG"
    T[perm_denied]="[+] SAFE: Unprivileged access is restricted"
    T[builtin_warning]="[!] WARNING: Component is built-in. Mitigation will FAIL."
    T[final_vulnerable]="Final Result: [ VULNERABLE ]"
    T[final_low_risk]="Final Result: [ LOW RISK ]"
    T[final_safe]="Final Result: [ SAFE ]"
    T[recom_vulnerable]="Action: Run scripts/fix.sh apply immediately"
    T[recom_low_risk]="Action: Update kernel to address the root cause"
    T[recom_safe]="Note: System is currently not vulnerable"
fi

print_banner
echo -e "${BOLD}>>> ${T[header]}${NC}\n"

# 1. Info gathering
print_step "1/3" "${T[sys_info]}"
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
print_step "2/3" "${T[sec_status]}"
EFF_STATUS=$(check_unprivileged_crypto)
if [[ "$EFF_STATUS" == "ACCESSIBLE" ]]; then
    log "${RED}" "  ${T[risk_unprivileged]}"
    CAN_EXPLOIT=1
else
    log "${GREEN}" "  ${T[perm_denied]}"
    CAN_EXPLOIT=0
fi

BUILTIN=0
if is_builtin "algif_aead"; then
    BUILTIN=1
    log "${YELLOW}" "  ${T[builtin_warning]}"
fi

# 5. Summary
print_step "3/3" "Summary Report"
echo -e "${BOLD}---------------------------------------------------------------${NC}"
if [[ "$VULNERABLE" -eq 0 ]]; then
    log "${GREEN}" "  ${T[final_safe]}"
    log "" "  ${T[recom_safe]}"
elif [[ "$CAN_EXPLOIT" -eq 0 ]]; then
    log "${YELLOW}" "  ${T[final_low_risk]}"
    log "" "  ${T[recom_low_risk]}"
else
    log "${RED}" "  ${T[final_vulnerable]}"
    log "" "  ${T[recom_vulnerable]}"
fi
echo -e "${BOLD}---------------------------------------------------------------${NC}"
exit 0
