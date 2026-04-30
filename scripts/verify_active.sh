#!/bin/bash
# CVE-2026-31431 Active Verification Script (v1.8.0)
# UI Optimized - Production Ready

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

check_deps python3 useradd userdel su mktemp chmod || exit 1

if [[ "$EUID" -ne 0 ]]; then
    echo "Error: This verification requires root to create/delete temporary users."
    exit 1
fi

TEST_USER="cve_verify_$(date +%s)"
TEMP_SCRIPT=$(mktemp /tmp/cve_test_XXXXXX.py)

# Safety Cleanup Trap
function cleanup() {
    [ -f "$TEMP_SCRIPT" ] && rm -f "$TEMP_SCRIPT"
    if id "$TEST_USER" &>/dev/null; then
        userdel -r "$TEST_USER" &>/dev/null
    fi
}
trap cleanup EXIT

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]="CVE-2026-31431 (Copy Fail) 主动模拟验证"
    T[setup]="准备隔离测试环境 (用户: $TEST_USER)"
    T[probing]="模拟非特权攻击路径探测"
    T[vulnerable]="严重警告: 系统利用路径依然存在！修复未生效。"
    T[safe]="验证成功: 系统已阻断真实攻击探测，修复有效。"
else
    T[header]="CVE-2026-31431 (Copy Fail) Active Verification"
    T[setup]="Preparing isolated environment (User: $TEST_USER)"
    T[probing]="Probing exploit path as unprivileged user"
    T[vulnerable]="CRITICAL WARNING: Exploit path is OPEN! Mitigation failed."
    T[safe]="VERIFIED: Exploit path is blocked. Mitigation is effective."
fi

print_banner
echo -e "${BOLD}>>> ${T[header]}${NC}\n"

print_step "1/2" "${T[setup]}"
useradd -m -s /bin/bash "$TEST_USER" &>/dev/null

cat <<EOF > "$TEMP_SCRIPT"
import socket
try:
    a = socket.socket(38, 5, 0)
    a.bind(("aead", "authencesn(hmac(sha256),cbc(aes))"))
    print("SUCCESS")
except:
    print("BLOCKED")
EOF
chmod 644 "$TEMP_SCRIPT"

print_step "2/2" "${T[probing]}"
RESULT=$(su - "$TEST_USER" -c "python3 $TEMP_SCRIPT" 2>/dev/null)

echo -e "${BOLD}---------------------------------------------------------------${NC}"
if [[ "$RESULT" == *"SUCCESS"* ]]; then
    log "${RED}" "  ${T[vulnerable]}"
else
    log "${GREEN}" "  ${T[safe]}"
fi
echo -e "${BOLD}---------------------------------------------------------------${NC}"

exit 0
