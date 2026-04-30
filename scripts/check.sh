#!/bin/bash
# CVE-2026-31431 Detection Script (Deep v2.0.0)
# UI Optimized - Production Ready

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

check_deps python3 grep sed awk lsmod uname || exit 1

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]="CVE-2026-31431 (Copy Fail) 深度多维检测"
    T[sys_info]="基础环境分析"
    T[sec_status]="多维接口安全深度探测"
    T[final_vulnerable]="最终结果: 【 受影响 (VULNERABLE) 】"
    T[final_low_risk]="最终结果: 【 低风险 (LOW RISK) 】"
    T[final_safe]="最终结果: 【 安全 (SAFE) 】"
    T[recom_vulnerable]="建议: 立即执行修复脚本 scripts/fix.sh apply"
    T[recom_low_risk]="建议: 虽然接口受限，但强烈建议应用补丁或重启以确保防护生效"
    T[recom_safe]="说明: 系统当前不受此漏洞威胁"
    T[probe_res]="  - 接口探测结果:"
else
    T[header]="CVE-2026-31431 (Copy Fail) Deep Multi-vector Detection"
    T[sys_info]="System Environment Analysis"
    T[sec_status]="Multi-vector Interface Security Probing"
    T[final_vulnerable]="Final Result: [ VULNERABLE ]"
    T[final_low_risk]="Final Result: [ LOW RISK ]"
    T[final_safe]="Final Result: [ SAFE ]"
    T[recom_vulnerable]="Action: Run scripts/fix.sh apply immediately"
    T[recom_low_risk]="Action: Interface restricted but patch/reboot is recommended"
    T[recom_safe]="Note: System is currently not vulnerable"
    T[probe_res]="  - Probe Results:"
fi

print_banner
echo -e "${BOLD}>>> ${T[header]}${NC}\n"

# 1. Info gathering
print_step "1/3" "${T[sys_info]}"
log "" "  - OS: ${OS_NAME}"
log "" "  - Kernel: $(uname -r)"
log "" "  - Security: $(check_security_modules)"

# 2. Kernel Window Check
VULNERABLE_VERSION=0
K_VER=$(echo $(uname -r) | grep -oP '^\d+\.\d+\.\d+' | head -n1)
[[ -z "$K_VER" ]] && K_VER=$(echo $(uname -r) | cut -d'-' -f1)

if version_ge "$K_VER" "4.14" && (version_lt "$K_VER" "6.18.22" || ([[ "$K_VER" == 6.19* ]] && version_lt "$K_VER" "6.19.12")); then
    VULNERABLE_VERSION=1
fi

# 3. Deep Probing
print_step "2/3" "${T[sec_status]}"
PROBE_RAW=$(check_unprivileged_crypto)
log "" "${T[probe_res]}"

CAN_EXPLOIT=0
IFS='|' read -ra ADDR <<< "$PROBE_RAW"
for i in "${ADDR[@]}"; do
    IFS=':' read -ra VAL <<< "$i"
    label=${VAL[0]}
    status=${VAL[1]}
    if [[ "$status" == "OK" ]]; then
        log "${RED}" "    [!] $label: ACCESSIBLE"
        CAN_EXPLOIT=1
    elif [[ "$status" == "PERM" ]]; then
        log "${YELLOW}" "    [+] $label: PERMISSION DENIED"
    else
        log "${GREEN}" "    [+] $label: BLOCKED/ERROR"
    fi
done

BUILTIN=0
if is_builtin "algif_aead"; then
    BUILTIN=1
    log "${YELLOW}" "  [!] Component is built-in to kernel."
fi

# 5. Summary
print_step "3/3" "Summary Report"
echo -e "${BOLD}---------------------------------------------------------------${NC}"
if [[ "$VULNERABLE_VERSION" -eq 0 ]]; then
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
