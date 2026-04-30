#!/bin/bash
# CVE-2026-31431 Remediation Script (Rigorous v1.9.1)
# UI Optimized - Production Ready

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

check_deps python3 modprobe lsmod rm cat || exit 1

CONF_FILE="/etc/modprobe.d/disable-algif-aead.conf"

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]="CVE-2026-31431 (Copy Fail) 深度修复工具"
    T[root_err]="错误: 必须以 root 权限运行。"
    T[applying]="正在应用内核模块级阻断规则..."
    T[unloading]="正在卸载受影响的内核模块..."
    T[verifying]="执行修复效果闭环验证..."
    T[success]="修复成功: 漏洞利用路径已切断。"
    T[fail]="修复失败: 接口仍可访问，请检查是否为内核内置组件。"
    T[reboot]="提示: 请重启系统或更新 initramfs 以确保隔离完全。"
    T[rollback]="正在移除修复配置，恢复原始设置..."
else
    T[header]="CVE-2026-31431 (Copy Fail) Remediation Tool"
    T[root_err]="Error: Must run as root."
    T[applying]="Applying kernel module blocklist..."
    T[unloading]="Unloading affected kernel modules..."
    T[verifying]="Performing closed-loop verification..."
    T[success]="SUCCESS: Exploit path is now blocked."
    T[fail]="FAILED: Interface is still accessible. Check if built-in."
    T[reboot]="Note: Reboot or update initramfs to ensure full isolation."
    T[rollback]="Removing mitigation configuration..."
fi

[[ "$EUID" -ne 0 ]] && { log "${RED}" "${T[root_err]}"; exit 1; }

ACTION=${1:-apply}
[[ "$ACTION" == "-"* ]] && ACTION="apply"

print_banner
echo -e "${BOLD}>>> ${T[header]}${NC}\n"

case "$ACTION" in
    apply)
        print_step "1/3" "${T[applying]}"
        cat <<EOF > "$CONF_FILE"
# Mitigation for CVE-2026-31431
install algif_aead /bin/false
install algif_hash /bin/false
install algif_skcipher /bin/false
EOF
        
        print_step "2/3" "${T[unloading]}"
        for mod in algif_aead algif_hash algif_skcipher; do
            modprobe -r "$mod" 2>/dev/null
        done
        
        print_step "3/3" "${T[verifying]}"
        STATUS=$(check_unprivileged_crypto)
        echo -e "${BOLD}---------------------------------------------------------------${NC}"
        if [[ "$STATUS" == "BLOCKED" || "$STATUS" == "PERMISSION_DENIED" ]]; then
            log "${GREEN}" "  ${T[success]}"
            log "${YELLOW}" "  ${T[reboot]}"
        else
            log "${RED}" "  ${T[fail]}"
            is_builtin "algif_aead" && log "${RED}" "  [!] Built-in detected. Modprobe won't work."
        fi
        echo -e "${BOLD}---------------------------------------------------------------${NC}"
        ;;
    rollback)
        log "${BLUE}" "${T[rollback]}"
        rm -f "$CONF_FILE"
        log "${GREEN}" "[+] Configuration restored."
        ;;
    *) echo "Usage: $0 [apply|rollback]"; exit 1 ;;
esac
exit 0
