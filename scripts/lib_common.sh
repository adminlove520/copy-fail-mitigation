#!/bin/bash
# Common Library for CVE-2026-31431 Mitigation Scripts
# v2.0.0 - Advanced Deep Verification

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
BOLD='\033[1m'
NC='\033[0m'

LOG_FILE="/tmp/cve-2026-31431.log"

# Initialization: Setup log file once
if [[ ! -w "$LOG_FILE" ]]; then
    rm -f "$LOG_FILE" 2>/dev/null
    touch "$LOG_FILE" 2>/dev/null && chmod 666 "$LOG_FILE" 2>/dev/null
fi
[[ ! -w "$LOG_FILE" ]] && LOG_FILE="/dev/null"

# UI Helpers
function print_banner() {
    echo -e "${CYAN}"
    echo "    __________________     ____  ___  ___  ____"
    echo "   / ____/ | / / ____/    / __ \/   |/   |/ __ \\"
    echo "  / /   /  |/ / __/______/ /_/ / /| / /| / / / /"
    echo " / /___/ /|  / /__/_____/ ____/ ___/ ___/ /_/ /"
    echo " \____/_/ |_/_____/    /_/   /_/  /_/  /_____/ "
    echo -e "          CVE-2026-31431 Mitigation Toolkit${NC}\n"
}

function print_step() {
    log "${CYAN}" "${BOLD}[ STEP $1 ]${NC} $2"
}

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
    {
        if [[ -w "$LOG_FILE" ]]; then
            echo -e "$(date '+%Y-%m-%d %H:%M:%S') $msg" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
        fi
    } 2>/dev/null
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

# Helper: Check security status (SELinux/AppArmor) with timeout
function check_security_modules() {
    local status=""
    if command -v sestatus &>/dev/null; then
        local selinux=$(timeout 1s sestatus 2>/dev/null | grep 'SELinux status' | awk '{print $3}')
        [[ -n "$selinux" ]] && status+="SELinux:$selinux "
    fi
    if command -v aa-status &>/dev/null; then
        if timeout 1s aa-status --enabled &>/dev/null; then
            status+="AppArmor:Enabled "
        fi
    elif [ -d /sys/kernel/security/apparmor ]; then
        status+="AppArmor:Enabled "
    fi
    echo "${status:-None}"
}

# Helper: Multi-Algorithm Crypto Probe (Deep Verification)
function check_unprivileged_crypto() {
    local py_cmd="import socket, os, sys
def probe(ctype, alg):
    try:
        s = socket.socket(38, 5, 0)
        s.bind((ctype, alg))
        return 'OK'
    except PermissionError: return 'PERM'
    except: return 'ERR'

if os.getuid() == 0:
    try: os.setuid(65534)
    except: pass

results = []
# 1. Test AEAD (Primary vulnerability vector)
results.append('AEAD:' + probe('aead', 'aes'))
# 2. Test Complex AEAD (Actual exploit vector)
results.append('AEAD_EXPL:' + probe('aead', 'authencesn(hmac(sha256),cbc(aes))'))
# 3. Test Hash & Skcipher (Secondary vectors blocked by fix.sh)
results.append('HASH:' + probe('hash', 'sha256'))
results.append('SKCIPHER:' + probe('skcipher', 'cbc(aes)'))

print('|'.join(results))"

    if ! command -v python3 &>/dev/null; then
        echo "UNKNOWN"
        return
    fi

    local res=$(timeout 3s python3 -c "$py_cmd" 2>/dev/null)
    echo "${res:-TIMEOUT}"
}
