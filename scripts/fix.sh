#!/bin/bash
# CVE-2026-31431 Remediation Script (Optimized)
# v1.3.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

CONF_FILE="/etc/modprobe.d/disable-algif-aead.conf"

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]=" CVE-2026-31431 (Copy Fail) 修复脚本 v1.3"
    T[usage]="用法: $0 [apply|rollback] [-y]\n  apply    : 禁用 algif_aead 模块\n  rollback : 还原配置\n  -y       : 自动确认"
    T[need_root]="错误: 必须以 root 权限运行。"
    T[impact]="[*] 影响评估..."
    T[warn_use]="警告: 模块正在使用 (引用数: "
    T[confirm]="是否继续? [y/N] "
    T[applying]="[*] 正在应用缓解措施..."
    T[unloading]="[*] 正在尝试卸载模块..."
    T[builtin_err]="错误: 模块已编译进内核，无法通过配置文件禁用。请升级内核。"
    T[done]="[+] 操作完成。"
else
    T[header]=" CVE-2026-31431 (Copy Fail) Remediation Script v1.3"
    T[usage]="Usage: $0 [apply|rollback] [-y]\n  apply    : Disable algif_aead\n  rollback : Restore config\n  -y       : Auto-confirm"
    T[need_root]="Error: Must run as root."
    T[impact]="[*] Impact Assessment..."
    T[warn_use]="Warning: Module in use (Refs: "
    T[confirm]="Continue? [y/N] "
    T[applying]="[*] Applying mitigation..."
    T[unloading]="[*] Attempting to unload module..."
    T[builtin_err]="Error: Module is built-in. Disabling via modprobe won't work. Upgrade kernel."
    T[done]="[+] Operation completed."
fi

function usage() { echo -e "${T[usage]}"; exit 1; }
[[ "$EUID" -ne 0 ]] && { log "${RED}" "${T[need_root]}"; exit 1; }

ACTION=${1:-apply}
FORCE=0
[[ "$*" == *"-y"* ]] && FORCE=1

echo "==============================================================="
echo "${T[header]}"
echo "==============================================================="

case "$ACTION" in
    apply)
        if is_builtin "algif_aead"; then
            log "${RED}" "${T[builtin_err]}"
            exit 1
        fi
        
        log "${BLUE}" "${T[impact]}"
        if lsmod | grep -q "^algif_aead"; then
            REF=$(lsmod | grep "^algif_aead" | awk '{print $3}')
            if [ "$REF" -gt 0 ] && [ "$FORCE" -eq 0 ]; then
                log "${YELLOW}" "${T[warn_use]}$REF)"
                read -p "${T[confirm]}" res
                [[ ! "$res" =~ ^[yY]$ ]] && exit 0
            fi
        fi

        log "${BLUE}" "${T[applying]}"
        echo "install algif_aead /bin/false" > "$CONF_FILE"
        
        log "${BLUE}" "${T[unloading]}"
        modprobe -r algif_aead 2>/dev/null
        log "${GREEN}" "${T[done]}"
        ;;
    rollback)
        [[ -f "$CONF_FILE" ]] && rm -f "$CONF_FILE" && log "${GREEN}" "${T[done]}"
        ;;
    *) usage ;;
esac
exit 0
