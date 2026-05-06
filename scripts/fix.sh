#!/bin/bash
# CVE-2026-31431 Mitigation Script (Module Blocklist)
# v2.2.1 - Focused on Mitigation only

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

check_deps python3 modprobe lsmod rm cat || exit 1

CONF_FILE="/etc/modprobe.d/disable-algif-aead.conf"

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]="CVE-2026-31431 (Copy Fail) 漏洞缓解 (模块阻断)"
    T[usage]="用法: $0 [apply|rollback] [-y]\n  apply    : 应用缓解措施 (禁用内核模块)\n  rollback : 还原系统配置"
    T[root_err]="错误: 必须以 root 权限运行。"
    T[mitigating]="[*] 正在应用内核模块级阻断规则..."
    T[unloading]="[*] 正在尝试卸载受影响的内核模块..."
    T[verifying]="[*] 执行有效性闭环验证..."
    T[success]="[+] 缓解成功: 漏洞探测已被阻断。"
    T[partial]="[!] 缓解受限: 接口仍可访问。检测到模块内置或正在使用，建议使用 scripts/kernel_upgrade.sh 进行升级。"
    T[rollback_done]="[+] 配置已还原。"
else
    T[header]="CVE-2026-31431 (Copy Fail) Mitigation (Module Blocklist)"
    T[usage]="Usage: $0 [apply|rollback] [-y]\n  apply    : Apply mitigation (Disable modules)\n  rollback : Restore configuration"
    T[root_err]="Error: Must run as root."
    T[mitigating]="[*] Applying kernel module blocklist..."
    T[unloading]="[*] Attempting to unload affected modules..."
    T[verifying]="[*] Performing closed-loop verification..."
    T[success]="[+] SUCCESS: Exploit path is now blocked."
    T[partial]="[!] LIMITED: Interface still accessible. Built-in detected or in-use. Use scripts/kernel_upgrade.sh instead."
    T[rollback_done]="[+] Configuration restored."
fi

[[ "$EUID" -ne 0 ]] && { log "${RED}" "${T[root_err]}"; exit 1; }

ACTION=${1:-apply}
[[ "$ACTION" == "-"* ]] && ACTION="apply"
FORCE=0
[[ "$*" == *"-y"* ]] && FORCE=1

function usage() {
    echo -e "${T[usage]}"
    exit 1
}

function do_apply() {
    print_step "MITIGATE" "${T[mitigating]}"
    cat <<EOF > "$CONF_FILE"
# Mitigation for CVE-2026-31431
install algif_aead /bin/false
install algif_hash /bin/false
install algif_skcipher /bin/false
EOF
    for mod in algif_aead algif_hash algif_skcipher; do
        modprobe -r "$mod" 2>/dev/null
    done
    echo 1 > /proc/sys/vm/drop_caches
    
    do_verify
}

function do_verify() {
    print_step "VERIFY" "${T[verifying]}"
    PROBE_RAW=$(check_unprivileged_crypto)
    ACCESSIBLE_COUNT=0
    IFS='|' read -ra ADDR <<< "$PROBE_RAW"
    for i in "${ADDR[@]}"; do
        IFS=':' read -ra VAL <<< "$i"
        [[ "${VAL[1]}" == "OK" ]] && ((ACCESSIBLE_COUNT++))
    done

    echo -e "${BOLD}---------------------------------------------------------------${NC}"
    if [[ $ACCESSIBLE_COUNT -eq 0 ]]; then
        log "${GREEN}" "  ${T[success]}"
    else
        log "${RED}" "  ${T[partial]}"
        is_builtin "algif_aead" && log "${RED}" "  [!] Built-in detected. Modprobe mitigation is NOT effective."
    fi
    echo -e "${BOLD}---------------------------------------------------------------${NC}"
}

print_banner
echo -e "${BOLD}>>> ${T[header]}${NC}\n"

case "$ACTION" in
    apply)
        do_apply
        ;;
    rollback)
        rm -f "$CONF_FILE"
        log "${GREEN}" "${T[rollback_done]}"
        ;;
    *) usage ;;
esac

exit 0
