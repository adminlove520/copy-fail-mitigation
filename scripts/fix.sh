#!/bin/bash
# CVE-2026-31431 Remediation Script (Rigorous v1.7.0)
# Production Ready - Supports x86/ARM, Xinchuang OS, Standard Linux

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

check_deps python3 modprobe lsmod rm cat || exit 1

CONF_FILE="/etc/modprobe.d/disable-algif-aead.conf"

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]=" CVE-2026-31431 (Copy Fail) 深度修复工具 v1.7.0"
    T[root_err]="错误: 必须以 root 权限运行。"
    T[applying]="[*] 正在应用内核模块级阻断..."
    T[unloading]="[*] 正在尝试即时卸载相关模块..."
    T[verifying]="[*] 正在执行有效性闭环验证..."
    T[success]="[+] 修复成功: 漏洞路径已阻断。"
    T[fail]="[!] 修复失败: 接口仍可访问。请检查是否为内置内核模块。"
    T[reboot]="[*] 建议: 请重启系统或更新 initramfs 以确保规则持久化。"
    T[rollback]="[*] 正在移除缓解配置..."
else
    T[header]=" CVE-2026-31431 (Copy Fail) Remediation v1.7.0"
    T[root_err]="Error: Must run as root."
    T[applying]="[*] Applying kernel module blocklist..."
    T[unloading]="[*] Attempting to unload modules..."
    T[verifying]="[*] Performing closed-loop verification..."
    T[success]="[+] SUCCESS: Exploit path blocked."
    T[fail]="[!] FAILED: Interface still accessible. Check if component is built-in."
    T[reboot]="[*] Note: Reboot or update initramfs to ensure full isolation."
    T[rollback]="[*] Removing mitigation config..."
fi

[[ "$EUID" -ne 0 ]] && { log "${RED}" "${T[root_err]}"; exit 1; }

ACTION=${1:-apply}
[[ "$ACTION" == "-"* ]] && ACTION="apply"

echo "==============================================================="
echo "${T[header]}"
echo "==============================================================="

case "$ACTION" in
    apply)
        log "${BLUE}" "${T[applying]}"
        cat <<EOF > "$CONF_FILE"
# Mitigation for CVE-2026-31431
install algif_aead /bin/false
install algif_hash /bin/false
install algif_skcipher /bin/false
EOF
        
        log "${BLUE}" "${T[unloading]}"
        for mod in algif_aead algif_hash algif_skcipher; do
            modprobe -r "$mod" 2>/dev/null
        done
        
        log "${BLUE}" "${T[verifying]}"
        STATUS=$(check_unprivileged_crypto)
        if [[ "$STATUS" == "BLOCKED" || "$STATUS" == "PERMISSION_DENIED" ]]; then
            log "${GREEN}" "${T[success]}"
            log "${YELLOW}" "${T[reboot]}"
        else
            log "${RED}" "${T[fail]}"
            is_builtin "algif_aead" && log "${RED}" "[!] Built-in detected. Modprobe won't work."
        fi
        ;;
    rollback)
        log "${BLUE}" "${T[rollback]}"
        rm -f "$CONF_FILE"
        log "${GREEN}" "[+] Done."
        ;;
    *) echo "Usage: $0 [apply|rollback]"; exit 1 ;;
esac
exit 0
