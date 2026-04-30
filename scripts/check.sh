#!/bin/bash
# CVE-2026-31431 Detection Script (Enhanced v1.4.0)
# Supports: x86, ARM, Xinchuang OS, Standard Linux distros

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]=" CVE-2026-31431 (Copy Fail) 深度兼容性检测 v1.4.0"
    T[sys_info]="[*] 系统环境分析:"
    T[sec_status]="[*] 安全有效性验证:"
    T[eff_mitigated]="[+] 验证成功: 缓解措施有效 (AF_ALG 接口已阻断)"
    T[eff_vulnerable]="[!] 验证失败: 接口仍可访问 (缓解措施未生效或未安装)"
    T[eff_unknown]="[-] 验证中性: 无法进行功能性验证 (缺少 Python/Perl)"
    T[distro_match]="  - 匹配发行版家族: "
    T[patch_detected]="[+] 检测到厂商后向移植补丁 (Backport)"
    T[mitigation_active]="[+] 发现内核模块禁用配置"
else
    T[header]=" CVE-2026-31431 (Copy Fail) Enhanced Detection v1.4.0"
    T[sys_info]="[*] System Environment Analysis:"
    T[sec_status]="[*] Security Effectiveness Verification:"
    T[eff_mitigated]="[+] VERIFIED: Mitigation is EFFECTIVE (AF_ALG blocked)"
    T[eff_vulnerable]="[!] FAILED: Interface still ACCESSIBLE (Mitigation NOT working)"
    T[eff_unknown]="[-] NEUTRAL: Functional verification skipped (Missing Python/Perl)"
    T[distro_match]="  - Matched Distro Family: "
    T[patch_detected]="[+] Vendor backport patch detected"
    T[mitigation_active]="[+] Kernel module disabling config found"
fi

echo "==============================================================="
echo "${T[header]}"
echo "==============================================================="
log "" "${T[sys_info]}"
log "" "  - OS: ${OS_NAME}"
log "" "${T[distro_match]}${OS_ID_LIKE:-$OS_ID}"
log "" "  - Kernel: $(uname -r)"

# 1. Backport Patch Detection (Enhanced for Xinchuang)
PATCHED=0
log "" "[*] Checking for vendor patches..."
if is_distro "ubuntu") && dpkg -l linux-image-$(uname -r) 2>/dev/null | grep -qE "6.8.0-40|5.15.0-110"; then
    PATCHED=1
elif is_distro "fedora" || is_distro "rhel"; then
    if rpm -q kernel-$(uname -r) --changelog 2>/dev/null | grep -qi "CVE-2026-31431"; then
        PATCHED=1
    fi
elif [[ "$OS_ID" =~ (kylin|uos|openEuler|anolis) ]]; then
    # Specific Xinchuang checks
    if command -v nkvers &>/dev/null && nkvers | grep -qi "CVE-2026-31431"; then PATCHED=1; fi
    if rpm -q kernel --changelog 2>/dev/null | grep -qi "CVE-2026-31431"; then PATCHED=1; fi
fi

[[ "$PATCHED" -eq 1 ]] && log "${GREEN}" "${T[patch_detected]}"

# 2. Mitigation Config Check
MITIGATED=0
if [[ -f "/etc/modprobe.d/disable-algif-aead.conf" ]] && grep -q "install algif_aead /bin/false" /etc/modprobe.d/disable-algif-aead.conf; then
    MITIGATED=1
    log "${GREEN}" "${T[mitigation_active]}"
fi

# 3. Functional Verification (The REAL Test)
log "" "${T[sec_status]}"
EFF_STATUS=$(check_crypto_accessible)

if [[ "$EFF_STATUS" == "BLOCKED" ]]; then
    log "${GREEN}" "${T[eff_mitigated]}"
    FINAL_RESULT="SAFE"
elif [[ "$EFF_STATUS" == "ACCESSIBLE" ]]; then
    if [[ "$PATCHED" -eq 1 ]]; then
        log "${YELLOW}" "[-] Note: Patch detected but interface still accessible (expected for patches as they fix logic, not block access)"
        FINAL_RESULT="PATCHED"
    else
        log "${RED}" "${T[eff_vulnerable]}"
        FINAL_RESULT="VULNERABLE"
    fi
else
    log "${YELLOW}" "${T[eff_unknown]}"
    FINAL_RESULT="UNDETERMINED"
fi

echo "---------------------------------------------------------------"
log "" "Final Result: $FINAL_RESULT"
exit 0
