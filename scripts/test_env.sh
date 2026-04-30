#!/bin/bash
# Integrated Test Script for CVE-2026-31431 Toolkit
# Run this inside a WSL distribution as root.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

cd "$BASE_DIR" || exit 1

echo "--- [TEST 1: Detection] ---"
bash scripts/check.sh --en

echo -e "\n--- [TEST 2: Remediation - Rollback first] ---"
bash scripts/fix.sh rollback --en

echo -e "\n--- [TEST 3: Remediation - Apply] ---"
bash scripts/fix.sh apply --en

echo -e "\n--- [TEST 4: Active Verification] ---"
bash scripts/verify_active.sh --en
