# CVE-2026-31431 (Copy Fail) Vulnerability Remediation Toolkit

A production-grade toolkit for detection, mitigation, and permanent remediation of the Linux kernel privilege escalation vulnerability **CVE-2026-31431 (Copy Fail)**.

## Project Structure

```text
.
├── scripts/
│   ├── check.sh           # Multi-vector detection script (i18n supported)
│   ├── fix.sh             # Mitigation script (Module blocklist, i18n supported)
│   ├── kernel_upgrade.sh  # Permanent fix script (Kernel upgrade, i18n supported)
│   ├── verify_active.sh   # Active closed-loop verification script (i18n supported)
│   └── lib_common.sh      # Common libraries & OS detection logic
├── docs/
│   ├── advisory_zh.md     # Detailed vulnerability advisory (Chinese)
│   └── CHANGELOG.md       # Update history
├── README.md              # This document
└── README_CN.md           # Chinese documentation
```

## Key Features

- **Deep Detection**: Combines version checks with functional probing of `AF_ALG` sockets.
- **Built-in Detection**: Identifies if components are compiled directly into the kernel, where `fix.sh` mitigation might be insufficient.
- **Decoupled Remediation Strategy**:
  - **Temporary Mitigation (`fix.sh`)**: Block kernel modules via `modprobe`.
  - **Permanent Fix (`kernel_upgrade.sh`)**: Automates kernel upgrades via OS-specific package managers (dnf/yum/apt).
- **Active Verification**: Uses a temporary unprivileged user to simulate the exploit path.

## Usage Guide

### 1. Risk Assessment
```bash
bash scripts/check.sh
```

### 2. Apply Mitigation (Quick Protection)
```bash
sudo bash scripts/fix.sh apply
```

### 3. Execute Kernel Upgrade (Permanent Fix)
```bash
sudo bash scripts/kernel_upgrade.sh
```

### 4. Active Security Audit
```bash
sudo bash scripts/verify_active.sh
```

## Disclaimer
This toolkit is provided for security emergency response and research purposes only. Kernel upgrades may affect system stability; please test thoroughly in a staging environment before production use.
