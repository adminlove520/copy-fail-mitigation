#!/bin/bash
# Common Library for CVE-2026-31431 Mitigation Scripts

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG_FILE="/tmp/cve-2026-31431.log"

# Language Detection & Override
[[ "$LANG" == *"zh_CN"* ]] && CURRENT_LANG="zh" || CURRENT_LANG="en"
for arg in "$@"; do
    case "$arg" in
        --zh) CURRENT_LANG="zh" ;;
        --en) CURRENT_LANG="en" ;;
    esac
done

# OS Identification (Enhanced)
OS_ID=$(grep -i '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
OS_ID_LIKE=$(grep -i '^ID_LIKE=' /etc/os-release | cut -d= -f2 | tr -d '"')
OS_NAME=$(grep -i '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')

# Helper: Active Exploit Verification with Temp User
function run_active_test() {
    local test_user="cve_verify_tmp"
    local test_script="/tmp/cve_test.py"
    local result="FAILED"

    # 1. Create a non-privileged test user
    if ! id "$test_user" &>/dev/null; then
        useradd -m "$test_user" &>/dev/null
    fi

    # 2. Prepare a non-destructive exploit test script
    # This script tries the exact socket/bind/accept sequence from the exploit
    cat <<EOF > "$test_script"
import socket, sys
try:
    a = socket.socket(38, 5, 0)
    # Try the specific exploit binding
    a.bind(("aead", "authencesn(hmac(sha256),cbc(aes))"))
    # If we reach here, the interface is accessible
    print("INTERFACE_ACCESSIBLE")
except Exception as e:
    print(f"BLOCKED")
EOF
    chmod 644 "$test_script"

    # 3. Run as temp user
    if command -v python3 &>/dev/null; then
        res=$(su - "$test_user" -c "python3 $test_script" 2>/dev/null)
        if [[ "$res" == *"INTERFACE_ACCESSIBLE"* ]]; then
            result="VULNERABLE"
        else
            result="SAFE"
        fi
    fi

    # 4. Cleanup
    rm -f "$test_script"
    userdel -r "$test_user" &>/dev/null
    
    echo "$result"
}
function is_distro() {
    local target=$1
    [[ "$OS_ID" == "$target" || "$OS_ID_LIKE" == *"$target"* ]]
}

# Helper: Check if AF_ALG AEAD is accessible as unprivileged user
function check_unprivileged_crypto() {
    local cmd="import socket; 
try:
    s = socket.socket(38, 5, 0)
    s.bind(('aead', 'aes'))
    print('ACCESSIBLE')
except PermissionError:
    print('PERMISSION_DENIED')
except Exception:
    print('BLOCKED')
"
    if [[ "$EUID" -eq 0 ]] && id nobody &>/dev/null; then
        # If we are root, test as 'nobody'
        if command -v python3 &>/dev/null; then
            su -s /bin/bash nobody -c "python3 -c \"$cmd\"" 2>/dev/null
        else
            echo "UNKNOWN"
        fi
    else
        # Test as current user
        if command -v python3 &>/dev/null; then
            python3 -c "$cmd" 2>/dev/null
        else
            echo "UNKNOWN"
        fi
    fi
}
function log() {
    local color=$1
    local msg=$2
    echo -e "${color}${msg}${NC}"
    # Strip ANSI colors for file log
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') $msg" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
}

# Helper: Version comparison
function version_ge() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" == "$2" ]
}

function version_lt() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" == "$1" ] && [ "$1" != "$2" ]
}

# Heuristic: Check if module is built-in
function is_builtin() {
    local module=$1
    if [ -f "/lib/modules/$(uname -r)/modules.builtin" ]; then
        grep -q "${module}.ko" "/lib/modules/$(uname -r)/modules.builtin"
        return $?
    fi
    # Fallback to checking kconfig if available
    if [ -f "/boot/config-$(uname -r)" ]; then
        grep -q "CONFIG_CRYPTO_USER_API_AEAD=y" "/boot/config-$(uname -r)"
        return $?
    fi
    return 1
}
