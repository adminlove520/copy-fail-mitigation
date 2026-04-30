#!/bin/bash
# Common Library for CVE-2026-31431 Mitigation Scripts
# v1.7.0 - Production Ready

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG_FILE="/tmp/cve-2026-31431.log"
# Ensure log file is writable
if [ -f "$LOG_FILE" ] && [ ! -w "$LOG_FILE" ]; then
    rm -f "$LOG_FILE" 2>/dev/null
fi
touch "$LOG_FILE" 2>/dev/null && chmod 666 "$LOG_FILE" 2>/dev/null

# Language Detection & Override
[[ "$LANG" == *"zh_CN"* ]] && CURRENT_LANG="zh" || CURRENT_LANG="en"
for arg in "$@"; do
    case "$arg" in
        --zh) CURRENT_LANG="zh" ;;
        --en) CURRENT_LANG="en" ;;
    esac
done

# OS Identification
OS_ID=$(grep -i '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
OS_ID_LIKE=$(grep -i '^ID_LIKE=' /etc/os-release | cut -d= -f2 | tr -d '"')
OS_NAME=$(grep -i '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')

# Helper: Log messages
function log() {
    local color=$1
    local msg=$2
    echo -e "${color}${msg}${NC}"
    # Strip ANSI colors for file log
    # Skip logging if we don't have write permission (e.g. running as sub-user)
    if [ -w "$LOG_FILE" ]; then
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') $msg" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
    fi
}

# Helper: Check dependencies
function check_deps() {
    local deps=("$@")
    local missing=()
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    if [ ${#missing[@]} -ne 0 ]; then
        log "${RED}" "Missing required commands: ${missing[*]}"
        return 1
    fi
    return 0
}

# Helper: Version comparison
function version_ge() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" == "$2" ]
}

function version_lt() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" == "$1" ] && [ "$1" != "$2" ]
}

# Helper: Check if module is built-in
function is_builtin() {
    local module=$1
    if [ -f "/lib/modules/$(uname -r)/modules.builtin" ]; then
        grep -q "${module}.ko" "/lib/modules/$(uname -r)/modules.builtin" && return 0
    fi
    if [ -f "/boot/config-$(uname -r)" ]; then
        grep -q "CONFIG_CRYPTO_USER_API_AEAD=y" "/boot/config-$(uname -r)" && return 0
    fi
    return 1
}

# Helper: Check security status (SELinux/AppArmor)
function check_security_modules() {
    local status=""
    if command -v sestatus &>/dev/null; then
        status+="SELinux: $(sestatus | grep 'SELinux status' | awk '{print $3}') "
    fi
    if command -v aa-status &>/dev/null; then
        status+="AppArmor: Loaded "
    elif [ -d /sys/kernel/security/apparmor ]; then
        status+="AppArmor: Enabled "
    fi
    echo "${status:-None}"
}

# Helper: Functional check logic (shared by check and verify)
function check_unprivileged_crypto() {
    # Use a more realistic binding string from the exploit to avoid false negatives
    local cmd="import socket; 
try:
    a = socket.socket(38, 5, 0)
    # This specific complex AEAD binding is common in exploits
    a.bind(('aead', 'authencesn(hmac(sha256),cbc(aes))'))
    print('ACCESSIBLE')
except Exception as e:
    # If the module is blocked, it usually throws OSError/Protocol not supported
    # If the algorithm is missing, it throws FileNotFoundError
    # We treat any failure as BLOCKED if it was accessible before
    print('BLOCKED')
"
    if ! command -v python3 &>/dev/null; then
        echo "UNKNOWN"
        return
    fi

    if [[ "$EUID" -eq 0 ]]; then
        # Try as 'nobody' if root
        local target_user="nobody"
        id "$target_user" &>/dev/null || target_user="root" # Fallback if nobody doesn't exist (rare)
        su -s /bin/bash "$target_user" -c "python3 -c \"$cmd\"" 2>/dev/null
    else
        python3 -c "$cmd" 2>/dev/null
    fi
}
