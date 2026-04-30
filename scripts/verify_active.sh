#!/bin/bash
# CVE-2026-31431 Active Verification Script (v1.6.0)
# Description: Creates a temp user, runs a functional exploit test, and cleans up.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

if [[ "$EUID" -ne 0 ]]; then
    echo "Error: This verification requires root to create/delete temporary users."
    exit 1
fi

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]=" CVE-2026-31431 (Copy Fail) 主动验证工具 v1.6.0"
    T[creating]="[*] 正在创建临时测试用户 (cve_verify_tmp)..."
    T[running]="[*] 正在以测试用户身份运行漏洞利用路径探测..."
    T[cleaning]="[*] 正在清理临时用户及环境..."
    T[vulnerable]="[!] 警告: 验证发现系统漏洞利用路径依然畅通！修复未生效。"
    T[safe]="[+] 验证成功: 系统已成功阻断漏洞利用路径。修复有效。"
else
    T[header]=" CVE-2026-31431 (Copy Fail) Active Verification v1.6.0"
    T[creating]="[*] Creating temporary test user (cve_verify_tmp)..."
    T[running]="[*] Running exploit path detection as test user..."
    T[cleaning]="[*] Cleaning up temporary user and environment..."
    T[vulnerable]="[!] WARNING: System is still VULNERABLE! Exploit path is open."
    T[safe]="[+] VERIFIED: System has blocked the exploit path. Mitigation is effective."
fi

echo "==============================================================="
echo "${T[header]}"
echo "==============================================================="

echo "${T[creating]}"
echo "${T[running]}"

RESULT=$(run_active_test)

echo "${T[cleaning]}"

echo "---------------------------------------------------------------"
if [[ "$RESULT" == "VULNERABLE" ]]; then
    log "${RED}" "${T[vulnerable]}"
else
    log "${GREEN}" "${T[safe]}"
fi
echo "==============================================================="

exit 0
