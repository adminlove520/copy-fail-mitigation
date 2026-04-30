#!/bin/bash
# v2.1.0 - Anti-Hang Optimization

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

check_deps python3 modprobe lsmod rm cat || exit 1

CONF_FILE="/etc/modprobe.d/disable-algif-aead.conf"

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]="CVE-2026-31431 (Copy Fail) 深度修复与验证"
    T[root_err]="错误: 必须以 root 权限运行。"
    T[applying]="正在应用内核模块级阻断规则..."
    T[unloading]="正在卸载相关内核模块..."
    T[verifying]="执行深度有效性闭环验证..."
    T[success]="修复成功: 所有漏洞利用路径已切断。"
    T[partial]="部分生效: 部分接口仍可访问，建议检查内置模块或重启。"
    T[fail]="修复失败: 关键接口仍可访问，请立即更新内核。"
    T[reboot]="提示: 请重启系统或更新 initramfs 以确保隔离完全。"
    T[rollback]="正在移除修复配置，恢复原始设置..."
else
    T[header]="CVE-2026-31431 (Copy Fail) Deep Remediation & Verification"
    T[root_err]="Error: Must run as root."
    T[applying]="Applying kernel module blocklist..."
    T[unloading]="Unloading related kernel modules..."
    T[verifying]="Performing deep closed-loop verification..."
    T[success]="SUCCESS: All exploit paths are now blocked."
    T[partial]="PARTIAL: Some paths still open. Reboot recommended."
    T[fail]="FAILED: Critical interface still accessible. Update kernel."
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
        PROBE_RAW=$(check_unprivileged_crypto)
        
        ACCESSIBLE_COUNT=0
        IFS='|' read -ra ADDR <<< "$PROBE_RAW"
        for i in "${ADDR[@]}"; do
            IFS=':' read -ra VAL <<< "$i"
            status=${VAL[1]}
            [[ "$status" == "OK" ]] && ((ACCESSIBLE_COUNT++))
        done

        echo -e "${BOLD}---------------------------------------------------------------${NC}"
        if [[ $ACCESSIBLE_COUNT -eq 0 ]]; then
            log "${GREEN}" "  ${T[success]}"
            log "${YELLOW}" "  ${T[reboot]}"
        elif [[ $ACCESSIBLE_COUNT -lt ${#ADDR[@]} ]]; then
            log "${YELLOW}" "  ${T[partial]}"
            log "${RED}" "  [!] Accessible paths: $ACCESSIBLE_COUNT"
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
