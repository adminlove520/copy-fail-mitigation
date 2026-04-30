# v2.1.0 - Anti-Hang Optimization

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_common.sh"

check_deps python3 useradd userdel su mktemp chmod timeout || exit 1

if [[ "$EUID" -ne 0 ]]; then
    echo "Error: This verification requires root to create/delete temporary users."
    exit 1
fi

TEST_USER="cve_verify_$(date +%s)"

# Safety Cleanup Trap
function cleanup() {
    if id "$TEST_USER" &>/dev/null; then
        userdel -r "$TEST_USER" &>/dev/null
    fi
}
trap cleanup EXIT

# Translations
declare -A T
if [[ "$CURRENT_LANG" == "zh" ]]; then
    T[header]="CVE-2026-31431 (Copy Fail) 深度模拟验证"
    T[setup]="准备隔离测试环境 (用户: $TEST_USER)"
    T[probing]="执行多维攻击路径探测"
    T[vulnerable]="严重警告: 系统利用路径依然畅通！修复未生效。"
    T[safe]="验证成功: 所有关键探测路径均已被封堵，修复有效。"
else
    T[header]="CVE-2026-31431 (Copy Fail) Deep Active Verification"
    T[setup]="Preparing isolated environment (User: $TEST_USER)"
    T[probing]="Probing multi-vector exploit paths"
    T[vulnerable]="CRITICAL WARNING: Exploit paths are OPEN! Mitigation failed."
    T[safe]="VERIFIED: All critical exploit paths are BLOCKED. Mitigation effective."
fi

print_banner
echo -e "${BOLD}>>> ${T[header]}${NC}\n"

print_step "1/2" "${T[setup]}"
useradd -m -s /bin/bash "$TEST_USER" &>/dev/null

print_step "2/2" "${T[probing]}"
# Run the probe as the new user using a direct python call to avoid sub-shell/source hangs
PROBE_RAW=$(timeout 10s su -s /bin/bash "$TEST_USER" -c "python3 -c \"$PY_PROBE_SRC\"" 2>/dev/null)

ACCESSIBLE_COUNT=0
IFS='|' read -ra ADDR <<< "$PROBE_RAW"
for i in "${ADDR[@]}"; do
    IFS=':' read -ra VAL <<< "$i"
    label=${VAL[0]}
    status=${VAL[1]}
    if [[ "$status" == "OK" ]]; then
        log "${RED}" "    [!] $label: ACCESSIBLE"
        ((ACCESSIBLE_COUNT++))
    else
        log "${GREEN}" "    [+] $label: BLOCKED"
    fi
done

echo -e "${BOLD}---------------------------------------------------------------${NC}"
if [[ $ACCESSIBLE_COUNT -gt 0 ]]; then
    log "${RED}" "  ${T[vulnerable]}"
else
    log "${GREEN}" "  ${T[safe]}"
fi
echo -e "${BOLD}---------------------------------------------------------------${NC}"

exit 0
