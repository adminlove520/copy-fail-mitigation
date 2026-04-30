#!/bin/bash
# CVE-2026-31431 Detection Script (Rigorous v1.5.0)
# Supports: x86, ARM, Xinchuang OS, Standard Linux distros

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]=" CVE-2026-31431 (Copy Fail) 深度安全检测 v1.5.0"
    T[risk_unprivileged]="[!] 风险提示: 发现非特权用户可直接访问 AF_ALG 接口"
    T[perm_denied]="[+] 安全确认: 非特权用户已被限制访问 AF_ALG (即使内核存在漏洞也难以利用)"
    T[builtin_warning]="[!] 严重警告: 漏洞组件已编译进内核 (Built-in)，无法通过简单加载配置禁用，必须升级内核或使用更底层的安全防护"
else
    T[header]=" CVE-2026-31431 (Copy Fail) Rigorous Detection v1.5.0"
    T[risk_unprivileged]="[!] RISK: Unprivileged users can access AF_ALG interface"
    T[perm_denied]="[+] SAFE: Unprivileged access to AF_ALG is restricted (Exploit difficult)"
    T[builtin_warning]="[!] SEVERE WARNING: Vulnerable component is built-in. modprobe mitigation will FAIL. Kernel upgrade REQUIRED."
fi

echo "==============================================================="
echo "${T[header]}"
echo "==============================================================="

# 1. Base Info
log "" "${T[sys_info]}"
log "" "  - OS: ${OS_NAME}"
log "" "  - Kernel: $(uname -r)"

# 2. Kernel Version Check (Vulnerability Window)
VULNERABLE=0
K_VER=$(echo $KERNEL | grep -oP '^\d+\.\d+\.\d+' | head -n1)
[[ -z "$K_VER" ]] && K_VER=$(echo $KERNEL | cut -d'-' -f1)

if version_ge "$K_VER" "4.14" && (version_lt "$K_VER" "6.18.22" || ([[ "$K_VER" == 6.19* ]] && version_lt "$K_VER" "6.19.12")); then
    VULNERABLE=1
fi

# 3. Functional Exploitability Check (Most Critical)
log "" "${T[sec_status]}"
EFF_STATUS=$(check_unprivileged_crypto)

if [[ "$EFF_STATUS" == "ACCESSIBLE" ]]; then
    log "${RED}" "${T[risk_unprivileged]}"
    CAN_EXPLOIT=1
elif [[ "$EFF_STATUS" == "PERMISSION_DENIED" ]]; then
    log "${GREEN}" "${T[perm_denied]}"
    CAN_EXPLOIT=0
else
    CAN_EXPLOIT=1 # Assume vulnerable if unknown
fi

# 4. Built-in Check
BUILTIN=0
if is_builtin "algif_aead"; then
    BUILTIN=1
    log "${RED}" "${T[builtin_warning]}"
fi

# 5. Final Verdict
echo "---------------------------------------------------------------"
if [[ "$VULNERABLE" -eq 0 ]]; then
    log "${GREEN}" "Result: SAFE (Kernel version not affected)"
elif [[ "$CAN_EXPLOIT" -eq 0 ]]; then
    log "${YELLOW}" "Result: LOW RISK (Kernel vulnerable but interface restricted)"
else
    log "${RED}" "Result: VULNERABLE (Action required!)"
fi

exit 0
