#!/bin/bash
# CVE-2026-31431 Remediation Script (Enhanced v1.4.0)
# v1.4.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

CONF_FILE="/etc/modprobe.d/disable-algif-aead.conf"

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]=" CVE-2026-31431 (Copy Fail) 深度修复工具 v1.4.0"
    T[step_config]="[1/3] 正在配置内核模块禁用规则..."
    T[step_unload]="[2/3] 正在尝试卸载受影响模块..."
    T[step_verify]="[3/3] 正在执行有效性闭环验证..."
    T[verify_success]="[+] 验证成功: 缓解措施已生效。"
    T[verify_failed]="[!] 验证失败: 接口仍可访问，请检查是否为内核内置模块。"
    T[reboot_hint]="[*] 提示: 模块可能被占用，建议重启系统以确保完全隔离。"
else
    T[header]=" CVE-2026-31431 (Copy Fail) Enhanced Remediation v1.4.0"
    T[step_config]="[1/3] Configuring kernel module block rules..."
    T[step_unload]="[2/3] Attempting to unload affected module..."
    T[step_verify]="[3/3] Performing closed-loop verification..."
    T[verify_success]="[+] VERIFIED: Mitigation is active and effective."
    T[verify_failed]="[!] FAILED: Interface still accessible. Check if module is built-in."
    T[reboot_hint]="[*] Hint: Module may be in use. Reboot is recommended for full isolation."
fi

[[ "$EUID" -ne 0 ]] && { log "${RED}" "Error: Must run as root."; exit 1; }

ACTION=${1:-apply}
FORCE=0
[[ "$*" == *"-y"* ]] && FORCE=1

echo "==============================================================="
echo "${T[header]}"
echo "==============================================================="

case "$ACTION" in
    apply)
        # 1. Config
        log "${BLUE}" "${T[step_config]}"
        echo "install algif_aead /bin/false" > "$CONF_FILE"
        
        # 2. Unload
        log "${BLUE}" "${T[step_unload]}"
        if lsmod | grep -q "^algif_aead"; then
            modprobe -r algif_aead 2>/dev/null
            if [ $? -ne 0 ]; then
                log "${YELLOW}" "${T[reboot_hint]}"
            fi
        fi

        # 3. Verify
        log "${BLUE}" "${T[step_verify]}"
        EFF_STATUS=$(check_crypto_accessible)
        if [[ "$EFF_STATUS" == "BLOCKED" ]]; then
            log "${GREEN}" "${T[verify_success]}"
        else
            log "${RED}" "${T[verify_failed]}"
        fi
        ;;
    rollback)
        [[ -f "$CONF_FILE" ]] && rm -f "$CONF_FILE" && log "${GREEN}" "[+] Rollback complete."
        ;;
    *) echo "Usage: $0 [apply|rollback]"; exit 1 ;;
esac
exit 0
