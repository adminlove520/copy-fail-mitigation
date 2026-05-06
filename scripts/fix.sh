#!/bin/bash
# CVE-2026-31431 Mitigation Script (Module Blocklist)
# v2.2.2 - Production-grade Mitigation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

check_deps python3 modprobe lsmod rm cat || exit 1

[[ "$EUID" -ne 0 ]] && { log "${RED}" "Error: Must run as root."; exit 1; }

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]="CVE-2026-31431 (Copy Fail) 漏洞缓解 (模块阻断)"
    T[container_skip]="[!] 检测到容器环境，跳过内核模块操作。"
    T[mitigating]="[*] 正在应用内核模块级阻断规则并更新配置..."
    T[in_use]="[!] 警告: 模块 %s 正在被使用，无法立即卸载，但阻断规则已生效。"
    T[initramfs]="[*] 正在同步更新 initramfs (此操作可能需要几分钟)..."
    T[success]="[+] 缓解成功: 探测已被阻断。建议重启以确保 initramfs 加载新规则。"
else
    T[header]="CVE-2026-31431 (Copy Fail) Mitigation (Module Blocklist)"
    T[container_skip]="[!] Container detected. Skipping kernel module operations."
    T[mitigating]="[*] Applying module blocklist and updating configuration..."
    T[in_use]="[!] WARNING: Module %s is in use and cannot be unloaded. Blocklist will apply on next load."
    T[initramfs]="[*] Updating initramfs (this may take a few minutes)..."
    T[success]="[+] SUCCESS: Exploit path blocked. Reboot recommended to apply initramfs changes."
fi

print_banner
echo -e "${BOLD}>>> ${T[header]}${NC}\n"

if is_container; then
    log "${YELLOW}" "${T[container_skip]}"
    exit 0
fi

CONF_FILE="/etc/modprobe.d/disable-algif-aead.conf"

function do_apply() {
    print_step "1/3" "${T[mitigating]}"
    cat <<EOF > "$CONF_FILE"
# Mitigation for CVE-2026-31431
blacklist algif_aead
blacklist algif_hash
blacklist algif_skcipher
install algif_aead /bin/false
install algif_hash /bin/false
install algif_skcipher /bin/false
EOF

    for mod in algif_aead algif_hash algif_skcipher; do
        if lsmod | grep -q "^${mod}"; then
            if ! modprobe -r "$mod" 2>/dev/null; then
                printf "${YELLOW}${T[in_use]}${NC}\n" "$mod"
            fi
        fi
    done

    # Update initramfs to ensure the blocklist is active early in the boot process
    print_step "2/3" "${T[initramfs]}"
    if command -v update-initramfs &>/dev/null; then
        update-initramfs -u 2>/dev/null
    elif command -v dracut &>/dev/null; then
        dracut -f --nocompress 2>/dev/null
    fi

    print_step "3/3" "Verification"
    PROBE_RAW=$(check_unprivileged_crypto)
    echo -e "${BOLD}---------------------------------------------------------------${NC}"
    if [[ "$PROBE_RAW" == *"OK"* ]]; then
        log "${RED}" "  [!] Mitigation partial. System reboot is MANDATORY."
    else
        log "${GREEN}" "  ${T[success]}"
    fi
    echo -e "${BOLD}---------------------------------------------------------------${NC}"
}

ACTION=${1:-apply}
case "$ACTION" in
    apply) do_apply ;;
    rollback) 
        rm -f "$CONF_FILE"
        log "${GREEN}" "[+] Configuration restored. Reboot to restore modules." 
        ;;
    *) echo "Usage: $0 [apply|rollback]"; exit 1 ;;
esac
