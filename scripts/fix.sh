#!/bin/bash
# CVE-2026-31431 Remediation Script (Rigorous v1.5.0)
# Supports: x86, ARM, Xinchuang OS, Standard Linux distros

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

CONF_FILE="/etc/modprobe.d/disable-algif-aead.conf"

if [[ "$EUID" -ne 0 ]]; then
    echo "Error: Must run as root."
    exit 1
fi

ACTION=${1:-apply}
[[ "$ACTION" == "-"* ]] && ACTION="apply"

case "$ACTION" in
    apply)
        echo "[*] Applying Rigorous Mitigation..."
        
        # 1. Block algif_aead module
        echo "install algif_aead /bin/false" > "$CONF_FILE"
        # Also block potential secondary modules used in exploits
        echo "install algif_hash /bin/false" >> "$CONF_FILE"
        echo "install algif_skcipher /bin/false" >> "$CONF_FILE"
        
        # 2. Try to unload
        for mod in algif_aead algif_hash algif_skcipher; do
            modprobe -r "$mod" 2>/dev/null
        done
        
        # 3. Verification
        STATUS=$(check_unprivileged_crypto)
        if [[ "$STATUS" == "BLOCKED" || "$STATUS" == "PERMISSION_DENIED" ]]; then
            echo -e "\033[0;32m[+] SUCCESS: Mitigation effective for unprivileged users.\033[0m"
        else
            echo -e "\033[0;31m[!] FAILED: AF_ALG still accessible. Check if built-in or if other modules are providing AEAD.\033[0m"
            if is_builtin "algif_aead"; then
                echo "[!] Component is built-in. Consider using AppArmor/SELinux to block AF_ALG sockets."
            fi
        fi
        ;;
    rollback)
        rm -f "$CONF_FILE"
        echo "[+] Rollback complete."
        ;;
    *) echo "Usage: $0 [apply|rollback]"; exit 1 ;;
esac
