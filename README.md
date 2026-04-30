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
- **i18n**: Automatic English/Chinese language detection.
- **Support**: x86/ARM, Standard Linux, and Xinchuang OS (Kylin, UOS, etc.).

## Usage

### 1. Detection
```bash
bash scripts/check.sh
```

### 2. Mitigation (Apply)
```bash
sudo bash scripts/fix.sh apply
```

### 3. Restore (Rollback)
```bash
sudo bash scripts/fix.sh rollback
```

## License
MIT
