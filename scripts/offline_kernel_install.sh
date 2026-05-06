#!/bin/bash
# CVE-2026-31431 Offline Kernel Install Script
# Run this on the INTRANET (OFFLINE) target host.
# v2.2.3 - Based on easyUpdate logic

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

PKG_DIR="${SCRIPT_DIR}/../packages_kernel"

[[ "$EUID" -ne 0 ]] && { log "${RED}" "Error: Must run as root."; exit 1; }

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]="CVE-2026-31431 内核包离线安装 (内网主机)"
    T[no_pkg]="[!] 错误: 未在 ${PKG_DIR} 发现离线包，请先在联网主机运行 download 脚本。"
    T[installing]="[*] 正在从本地目录安装内核补丁包..."
    T[success]="[+] 离线内核包安装成功。"
    T[reboot_msg]="[!] 重要: 必须重启系统以应用新内核补丁！"
    T[confirm]="[?] 确认从本地包安装内核补丁? [y/N] "
else
    T[header]="CVE-2026-31431 Offline Kernel Install (Intranet Host)"
    T[no_pkg]="[!] Error: No packages found in ${PKG_DIR}. Run download script on internet host first."
    T[installing]="[*] Installing kernel patch packages from local directory..."
    T[success]="[+] Offline kernel packages installed successfully."
    T[reboot_msg]="[!] IMPORTANT: You MUST 'reboot' to switch to the patched kernel!"
    T[confirm]="[?] Proceed with local kernel package installation? [y/N] "
fi

print_banner
echo -e "${BOLD}>>> ${T[header]}${NC}\n"

if [ ! -d "${PKG_DIR}" ] || [ -z "$(ls -A "${PKG_DIR}")" ]; then
    log "${RED}" "${T[no_pkg]}"
    exit 1
fi

if is_container; then
    log "${RED}" "Error: Kernel cannot be upgraded from within a container."
    exit 0
fi

read -p "${T[confirm]}" -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 1

check_boot_space || exit 1

print_step "INSTALL" "${T[installing]}"

case $SYSTEM_TYPE in
    rhel-like)
        # Using rpm to install local files
        rpm -ivh "${PKG_DIR}"/*.rpm --force --nodeps 2>>"$LOG_FILE"
        ;;
    debian-like)
        # Using dpkg to install local files
        dpkg -i "${PKG_DIR}"/*.deb 2>>"$LOG_FILE"
        apt-get install -f -y 2>/dev/null # Fix dependencies if possible
        ;;
    *)
        log "${RED}" "Unsupported system type for offline installation."
        exit 1
        ;;
esac

echo -e "\n${BOLD}---------------------------------------------------------------${NC}"
log "${GREEN}" "  ${T[success]}"
log "${YELLOW}" "  ${T[reboot_msg]}"
echo -e "${BOLD}---------------------------------------------------------------${NC}"

exit 0
