# CVE-2026-31431 (Copy Fail) Mitigation Toolkit

This toolkit provides tools for detection and remediation of the Linux kernel vulnerability **CVE-2026-31431 (Copy Fail)**.

## Project Structure

```text
.
├── scripts/
│   ├── check.sh        # Detection script (i18n supported)
│   ├── fix.sh          # Mitigation/Rollback script (i18n supported)
│   └── lib_common.sh   # Shared functions & library
├── docs/
│   ├── advisory_zh.md  # Detailed vulnerability advisory (Chinese)
│   └── CHANGELOG.md    # Change history
├── README.md           # This file
└── README_CN.md        # Documentation in Chinese
```

## Features

- **Robust Detection**: Heuristic kernel version check + distro-specific backport detection.
- **Built-in Awareness**: Detects if the vulnerable component is compiled into the kernel (making standard module disabling ineffective).
- **Safe Remediation**: Impact assessment before disabling modules; support for rollback.
- **i18n**: Automatic English/Chinese language detection (Override with `--zh` or `--en`).
- **Support**: x86/ARM, Standard Linux, and Xinchuang OS (Kylin, UOS, etc.).

3. `verify_active.sh`: Active closed-loop verification (New).
   - Automatically creates a temporary unprivileged user (`cve_verify_tmp`).
   - Simulates the exploit's attack path (non-destructive test).
   - Cleans up the user and environment afterward.

## Usage

### 1. Detection
```bash
bash scripts/check.sh [--zh|--en]
```

### 2. Mitigation (Apply)
```bash
sudo bash scripts/fix.sh apply [-y] [--zh|--en]
```

### 3. Restore (Rollback)
```bash
sudo bash scripts/fix.sh rollback [--zh|--en]
```

### 4. Active Verification (Highly Reliable)
To verify the mitigation by simulating a real attack path:
```bash
sudo bash scripts/verify_active.sh
```

## License
MIT
