#!/bin/bash
# CVE-2026-31431 Remediation Script (Optimized with i18n)
# Description: Applies or rolls back mitigation for CVE-2026-31431
# Supports: x86, ARM, Xinchuang OS, Standard Linux distros

set -o pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONF_FILE="/etc/modprobe.d/disable-algif-aead.conf"

# Language Detection
[[ "$LANG" == *"zh_CN"* ]] && CURRENT_LANG="zh" || CURRENT_LANG="en"

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]=" CVE-2026-31431 (Copy Fail) 修复脚本 v1.2"
    T[usage]="用法: $0 [apply|rollback] [-y]\n  apply    : 禁用 algif_aead 模块 (默认)\n  rollback : 重新启用 algif_aead 模块\n  -y       : 非交互模式"
    T[need_root]="错误: 请以 root 权限运行。"
    T[impact]="[*] 影响评估..."
    T[warn_use]="警告: algif_aead 当前正在使用 (引用计数: "
    T[warn_impact]="禁用此模块可能会影响使用 AF_ALG 加密接口的应用程序。"
    T[confirm]="是否继续应用缓解措施? [y/N] "
    T[cancelled]="修复已取消。"
    T[force]="检测到强制标记。正在继续..."
    T[applying]="[*] 正在应用缓解措施..."
    T[created]="[+] 已创建 "
    T[failed_create]="[!] 创建配置文件失败"
    T[unloading]="[*] 正在卸载模块..."
    T[unloaded]="[+] 模块卸载成功。"
    T[failed_unload]="[!] 无法卸载。将在下次重启后生效。"
    T[rolling_back]="[*] 正在回滚缓解措施..."
    T[removed]="[+] 已移除 "
    T[reload_hint]="[*] 您可能需要运行 'modprobe algif_aead' 重新加载。"
    T[no_conf]="[!] 未发现缓解配置，无需回滚。"
else
    T[header]=" CVE-2026-31431 (Copy Fail) Remediation Script v1.2"
    T[usage]="Usage: $0 [apply|rollback] [-y]\n  apply    : Disables algif_aead module (Default)\n  rollback : Re-enables algif_aead module\n  -y       : Non-interactive mode"
    T[need_root]="Error: Please run as root."
    T[impact]="[*] Impact Assessment..."
    T[warn_use]="Warning: algif_aead is in use (Ref: "
    T[warn_impact]="Disabling this module may affect apps using AF_ALG crypto interface."
    T[confirm]="Apply mitigation anyway? [y/N] "
    T[cancelled]="Remediation cancelled."
    T[force]="Force flag detected. Proceeding..."
    T[applying]="[*] Applying mitigation..."
    T[created]="[+] Created "
    T[failed_create]="[!] Failed to create config"
    T[unloading]="[*] Unloading module..."
    T[unloaded]="[+] Module unloaded successfully."
    T[failed_unload]="[!] Could not unload. Will take effect after reboot."
    T[rolling_back]="[*] Rolling back mitigation..."
    T[removed]="[+] Removed "
    T[reload_hint]="[*] You may need to run 'modprobe algif_aead' to reload."
    T[no_conf]="[!] No mitigation config found to remove."
fi

function usage() {
    echo -e "${T[usage]}"
    exit 1
}

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}${T[need_root]}${NC}"
    exit 1
fi

ACTION=${1:-apply}
[[ "$ACTION" == "-"* ]] && ACTION="apply"

FORCE=0
if [[ "$*" == *"-y"* || "$*" == *"--yes"* ]]; then
    FORCE=1
fi

echo "==============================================================="
echo "${T[header]}"
echo "==============================================================="

case "$ACTION" in
    apply)
        echo -e "${BLUE}${T[impact]}${NC}"
        LOADED=0
        if lsmod | grep -q "^algif_aead"; then
            LOADED=1
            REF_COUNT=$(lsmod | grep "^algif_aead" | awk '{print $3}')
            if [ "$REF_COUNT" -gt 0 ]; then
                echo -e "${YELLOW}${T[warn_use]}${REF_COUNT}).${NC}"
                echo "${T[warn_impact]}"
                if [ "$FORCE" -eq 0 ]; then
                    read -p "${T[confirm]}" res
                    if [[ ! "$res" =~ ^[yY]$ ]]; then
                        echo "${T[cancelled]}"
                        exit 0
                    fi
                else
                    echo "${T[force]}"
                fi
            fi
        fi

        echo -e "${BLUE}${T[applying]}${NC}"
        cat <<EOF > "$CONF_FILE"
# Mitigation for CVE-2026-31431 (Copy Fail)
# Created on $(date)
install algif_aead /bin/false
EOF
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}${T[created]}$CONF_FILE${NC}"
        else
            echo -e "${RED}${T[failed_create]}${NC}"
            exit 1
        fi

        if [ "$LOADED" -eq 1 ]; then
            echo -e "${BLUE}${T[unloading]}${NC}"
            modprobe -r algif_aead 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}${T[unloaded]}${NC}"
            else
                echo -e "${YELLOW}${T[failed_unload]}${NC}"
            fi
        fi
        ;;

    rollback)
        echo -e "${BLUE}${T[rolling_back]}${NC}"
        if [ -f "$CONF_FILE" ]; then
            rm -f "$CONF_FILE"
            echo -e "${GREEN}${T[removed]}$CONF_FILE${NC}"
            echo -e "${BLUE}${T[reload_hint]}${NC}"
        else
            echo -e "${YELLOW}${T[no_conf]}${NC}"
        fi
        ;;

    *)
        usage
        ;;
esac

echo "==============================================================="
exit 0
