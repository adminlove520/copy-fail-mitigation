#!/bin/bash
# CVE-2026-31431 Kernel Upgrade Script
# v2.2.1 - Production-grade Kernel Patching

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]="CVE-2026-31431 (Copy Fail) 内核安全升级"
    T[root_err]="错误: 必须以 root 权限运行。"
    T[upgrading]="[*] 正在尝试通过 $PKG_MANAGER 升级内核及安全补丁..."
    T[success]="[+] 内核升级任务已提交。"
    T[reboot_msg]="[!] 重要: 必须执行 'reboot' 重启系统以使新内核生效！"
    T[unsupported]="[!] 错误: 当前发行版暂不支持自动内核升级，请手动执行。"
    T[confirm]="[?] 是否立即执行内核升级? [y/N] "
else
    T[header]="CVE-2026-31431 (Copy Fail) Kernel Security Upgrade"
    T[root_err]="Error: Must run as root."
    T[upgrading]="[*] Attempting kernel and security patch upgrade via $PKG_MANAGER..."
    T[success]="[+] Kernel upgrade task submitted successfully."
    T[reboot_msg]="[!] IMPORTANT: You MUST 'reboot' the system to apply the new kernel!"
    T[unsupported]="[!] Error: Automatic upgrade not supported for this distro. Please update manually."
    T[confirm]="[?] Proceed with kernel upgrade? [y/N] "
fi

[[ "$EUID" -ne 0 ]] && { log "${RED}" "${T[root_err]}"; exit 1; }

FORCE=0
[[ "$*" == *"-y"* ]] && FORCE=1

print_banner
echo -e "${BOLD}>>> ${T[header]}${NC}\n"

if [[ "$FORCE" -eq 0 ]]; then
    read -p "${T[confirm]}" -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

print_step "UPGRADE" "${T[upgrading]}"

case $SYSTEM_TYPE in
    rhel-like)
        # Targeted upgrade for known distributions
        if [ -f /etc/rocky-release ]; then
            log "${CYAN}" "Rocky Linux detected. Targeting Rocky 9.7+ patches."
        elif [ -f /etc/kylin-release ]; then
            log "${CYAN}" "Kylin OS detected. Checking for vendor patches."
        fi
        
        $PKG_MANAGER clean all && $PKG_MANAGER makecache -y
        # Upgrade core kernel components
        $PKG_MANAGER update -y kernel kernel-core kernel-modules kernel-devel kernel-headers || warn "Kernel update failed or already at latest."
        $PKG_MANAGER distro-sync -y
        ;;
    debian-like)
        $PKG_MANAGER update -y
        # Ubuntu/Debian/UOS
        if [ -f /etc/uos-release ]; then
             $PKG_MANAGER install -y linux-image-$(uname -r) linux-headers-$(uname -r)
        else
             $PKG_MANAGER upgrade -y linux-image-generic || $PKG_MANAGER install -y linux-image-generic
        fi
        ;;
    *)
        log "${RED}" "${T[unsupported]}"
        exit 1
        ;;
esac

echo -e "\n${BOLD}---------------------------------------------------------------${NC}"
log "${GREEN}" "  ${T[success]}"
log "${YELLOW}" "  ${T[reboot_msg]}"
echo -e "${BOLD}---------------------------------------------------------------${NC}"

exit 0
