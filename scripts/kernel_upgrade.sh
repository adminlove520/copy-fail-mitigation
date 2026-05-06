#!/bin/bash
# CVE-2026-31431 Kernel Upgrade Script
# v2.2.2 - Production-grade Safety

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

[[ "$EUID" -ne 0 ]] && { log "${RED}" "Error: Must run as root."; exit 1; }

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]="CVE-2026-31431 (Copy Fail) 内核安全升级"
    T[container_skip]="[!] 检测到容器环境，无法在此升级内核。"
    T[backup_warn]="[!] 警告: 内核升级涉及系统底座变更，请务必确认已有快照或数据备份！"
    T[upgrading]="[*] 正在执行内核组件增量升级..."
    T[success]="[+] 内核升级包已安装。"
    T[reboot_msg]="[!] 重要: 必须执行 'reboot' 重启系统以切换至新内核！"
    T[confirm]="[?] 是否确认环境安全并执行内核升级? [y/N] "
else
    T[header]="CVE-2026-31431 (Copy Fail) Kernel Security Upgrade"
    T[container_skip]="[!] Container detected. Kernel cannot be upgraded from within."
    T[backup_warn]="[!] WARNING: Kernel upgrade is a major change. Ensure you have backups/snapshots!"
    T[upgrading]="[*] Performing incremental kernel components upgrade..."
    T[success]="[+] Kernel packages installed successfully."
    T[reboot_msg]="[!] IMPORTANT: You MUST 'reboot' to switch to the patched kernel!"
    T[confirm]="[?] Confirm environment is safe and proceed with upgrade? [y/N] "
fi

print_banner
echo -e "${BOLD}>>> ${T[header]}${NC}\n"

if is_container; then
    log "${RED}" "${T[container_skip]}"
    exit 0
fi

# Pre-checks
log "${YELLOW}" "${T[backup_warn]}"
read -p "${T[confirm]}" -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 1

check_boot_space || exit 1

print_step "UPGRADE" "${T[upgrading]}"

case $SYSTEM_TYPE in
    rhel-like)
        # Targeted upgrade only for kernel related packages to minimize impact
        $PKG_MANAGER clean all && $PKG_MANAGER makecache -y
        $PKG_MANAGER update -y kernel kernel-core kernel-modules kernel-devel kernel-headers 2>>"$LOG_FILE"
        ;;
    debian-like)
        $PKG_MANAGER update -y 2>>"$LOG_FILE"
        if [ -f /etc/uos-release ]; then
             $PKG_MANAGER install -y linux-image-$(uname -r) linux-headers-$(uname -r)
        else
             # Avoid full-upgrade to maintain stability
             $PKG_MANAGER install --only-upgrade -y linux-image-generic linux-headers-generic 2>>"$LOG_FILE"
        fi
        ;;
    *)
        log "${RED}" "Manual upgrade required for this distribution."
        exit 1
        ;;
esac

echo -e "\n${BOLD}---------------------------------------------------------------${NC}"
log "${GREEN}" "  ${T[success]}"
log "${YELLOW}" "  ${T[reboot_msg]}"
echo -e "${BOLD}---------------------------------------------------------------${NC}"

exit 0
