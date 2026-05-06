#!/bin/bash
# CVE-2026-31431 Offline Kernel Download Script
# Run this on an INTERNET-CONNECTED host with the SAME OS as the target.
# v2.2.3 - Based on easyUpdate logic

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

PKG_DIR="${SCRIPT_DIR}/../packages_kernel"
mkdir -p "${PKG_DIR}"

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]="CVE-2026-31431 内核包离线下载 (互联网主机)"
    T[downloading]="[*] 正在下载适用于 ${OS_NAME} 的内核修复包到 ${PKG_DIR}..."
    T[success]="[+] 下载完成。请将整个项目目录（含 packages_kernel）拷贝到内网主机，并运行 scripts/offline_kernel_install.sh"
    T[err_pkg]="[!] 错误: 无法获取软件包列表或下载失败。"
else
    T[header]="CVE-2026-31431 Offline Kernel Download (Internet Host)"
    T[downloading]="[*] Downloading kernel patch packages for ${OS_NAME} to ${PKG_DIR}..."
    T[success]="[+] Download complete. Copy the project folder (including packages_kernel) to the intranet host and run scripts/offline_kernel_install.sh"
    T[err_pkg]="[!] Error: Failed to fetch package list or download failed."
fi

print_banner
echo -e "${BOLD}>>> ${T[header]}${NC}\n"

print_step "DOWNLOAD" "${T[downloading]}"

case $SYSTEM_TYPE in
    rhel-like)
        # We need kernel, kernel-core, kernel-modules, kernel-devel, kernel-headers
        # Using dnf/yum download-only
        if command -v dnf &>/dev/null; then
            dnf install -y 'dnf-command(download)' 2>/dev/null
            dnf download --resolve --destdir="${PKG_DIR}" kernel kernel-core kernel-modules kernel-devel kernel-headers || \
            dnf download --resolve --destdir="${PKG_DIR}" kernel kernel-devel kernel-headers
        else
            yum install -y yum-utils 2>/dev/null
            yumdownloader --resolve --destdir="${PKG_DIR}" kernel kernel-devel kernel-headers
        fi
        ;;
    debian-like)
        # Using apt download
        cd "${PKG_DIR}"
        apt-get update
        if [ -f /etc/uos-release ]; then
             apt-get download linux-image-$(uname -r) linux-headers-$(uname -r)
        else
             apt-get download linux-image-generic linux-headers-generic
        fi
        cd - >/dev/null
        ;;
    *)
        log "${RED}" "Manual download required: unsupported system type."
        exit 1
        ;;
esac

if [ "$(ls -A "${PKG_DIR}")" ]; then
    echo -e "\n${BOLD}---------------------------------------------------------------${NC}"
    log "${GREEN}" "  ${T[success]}"
    ls -lh "${PKG_DIR}"
    echo -e "${BOLD}---------------------------------------------------------------${NC}"
else
    log "${RED}" "${T[err_pkg]}"
    exit 1
fi

exit 0
