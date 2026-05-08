#!/bin/bash
# Common Library for CVE-2026-31431 Mitigation Scripts
# v2.2.0 - OS Enhanced & Fix Logic

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
BOLD='\033[1m'
NC='\033[0m'

LOG_FILE="/tmp/cve-2026-31431.log"

# OS Identification & Package Manager
SYSTEM_TYPE="unknown"
PKG_MANAGER="unknown"

function identify_system() {
    if [ -f /etc/rocky-release ] || grep -qi 'rocky' /etc/os-release 2>/dev/null; then
        SYSTEM_TYPE="rhel-like"; PKG_MANAGER="dnf"
    elif [ -f /etc/kylin-release ]; then
        SYSTEM_TYPE="rhel-like"; PKG_MANAGER="yum"
    elif [ -f /etc/openeuler-release ]; then
        SYSTEM_TYPE="rhel-like"; PKG_MANAGER="dnf"
    elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ] || [ -f /etc/rhel-release ] || [ -f /etc/almalinux-release ] || [ -f /etc/anolis-release ]; then
        SYSTEM_TYPE="rhel-like"; PKG_MANAGER="yum"
        command -v dnf &>/dev/null && PKG_MANAGER="dnf"
    elif [ -f /etc/debian_version ] || [ -f /etc/ubuntu-release ] || [ -f /etc/uos-release ]; then
        SYSTEM_TYPE="debian-like"; PKG_MANAGER="apt"
    fi
}
identify_system

# ... (rest of lib_common.sh initialization) ...

# Helper: Check if vendor patch exists in changelog (Fix for False Positives)
function check_vendor_patch() {
    local cve="CVE-2026-31431"
    if command -v rpm &>/dev/null; then
        # Check running kernel package first
        local current_k=$(uname -r)
        if rpm -q --changelog "kernel-$(uname -r)" 2>/dev/null | grep -qi "$cve"; then
            return 0
        fi
        # Fallback to general kernel package
        if rpm -q --changelog kernel 2>/dev/null | grep -qi "$cve"; then
            return 0
        fi
    fi
    if command -v apt-get &>/dev/null && [ -f /usr/share/doc/linux-image-$(uname -r)/changelog.Debian.gz ]; then
        zgrep -qi "$cve" /usr/share/doc/linux-image-$(uname -r)/changelog.Debian.gz && return 0
    fi
    return 1
}
function init_log() {
    # If log exists and not writable, try to recreate it
    if [[ -e "$LOG_FILE" && ! -w "$LOG_FILE" ]]; then
        rm -f "$LOG_FILE" 2>/dev/null
    fi
    # Only touch if it doesn't exist
    [[ ! -e "$LOG_FILE" ]] && touch "$LOG_FILE" 2>/dev/null && chmod 666 "$LOG_FILE" 2>/dev/null
    [[ ! -w "$LOG_FILE" ]] && LOG_FILE="/dev/null"
}
init_log

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
    # Ensure we don't block on logging
    if [[ "$LOG_FILE" != "/dev/null" ]]; then
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') $msg" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE" 2>/dev/null &
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

# Helper: Check security status (SELinux/AppArmor) with timeout
function check_security_modules() {
    local status=""
    if command -v sestatus &>/dev/null; then
        local selinux=$(timeout 2s sestatus 2>/dev/null | grep 'SELinux status' | awk '{print $3}')
        [[ -n "$selinux" ]] && status+="SELinux:$selinux "
    fi
    if command -v aa-status &>/dev/null; then
        if timeout 2s aa-status --enabled &>/dev/null; then
            status+="AppArmor:Enabled "
        fi
    elif [ -d /sys/kernel/security/apparmor ]; then
        status+="AppArmor:Enabled "
    fi
    echo "${status:-None}"
}

# Environment Checks
function is_container() {
    [ -f /.dockerenv ] && return 0
    grep -qE "docker|lxc|containerd" /proc/1/cgroup 2>/dev/null && return 0
    return 1
}

# Helper: Check disk space for kernel upgrade (requires ~200MB in /boot)
function check_boot_space() {
    local boot_space=$(df -m /boot | tail -1 | awk '{print $4}')
    if [ "$boot_space" -lt 200 ]; then
        log "${RED}" "Error: Insufficient space in /boot (found ${boot_space}MB, need >200MB)."
        return 1
    fi
    return 0
}

# Helper: Python Probe Source (Optimized for error handling)
PY_PROBE_SRC="import socket, os, sys
def probe(ctype, alg):
    try:
        s = socket.socket(38, 5, 0)
        s.settimeout(2)
        s.bind((ctype, alg))
        return 'OK'
    except PermissionError: return 'PERM'
    except Exception: return 'ERR'

if os.getuid() == 0:
    try: os.setuid(65534)
    except: pass

res = []
res.append('AEAD:' + probe('aead', 'aes'))
res.append('AEAD_EXPL:' + probe('aead', 'authencesn(hmac(sha256),cbc(aes))'))
res.append('HASH:' + probe('hash', 'sha256'))
res.append('SKCIPHER:' + probe('skcipher', 'cbc(aes)'))
print('|'.join(res))"

# Helper: Multi-Algorithm Crypto Probe (Deep Verification)
function check_unprivileged_crypto() {
    if ! command -v python3 &>/dev/null; then
        echo "UNKNOWN"
        return
    fi

    # Run probe with double timeout (process + internal socket timeout)
    local res=$(timeout 5s python3 -c "$PY_PROBE_SRC" 2>/dev/null)
    echo "${res:-TIMEOUT}"
}
