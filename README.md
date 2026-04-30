# CVE-2026-31431 (Copy Fail) Mitigation Toolkit

This toolkit provides detection and remediation scripts for **CVE-2026-31431**, a high-severity local privilege escalation vulnerability in the Linux kernel crypto subsystem (`algif_aead`).

## Vulnerability Overview

- **CVE ID**: CVE-2026-31431
- **Name**: Copy Fail
- **Severity**: High (CVSS 7.8)
- **Description**: An incorrect "in-place operation" optimization in `algif_aead` allows a local low-privileged user to write controlled data to the page cache, leading to root privilege escalation.
- **Affected Kernels**: 4.14 onwards (until fixed in 6.18.22, 6.19.12, 7.0).

## Supported Systems

- **Architectures**: x86_64, aarch64 (ARM64)
- **OS Distributions**:
  - Ubuntu 18.04 / 20.04 / 22.04 / 24.04
  - RHEL / CentOS / Rocky Linux / AlmaLinux 7, 8, 9, 10
  - Debian 10 / 11 / 12
  - **Xinchuang OS (信创操作系统)**: Kylin (麒麟), UOS (统信), EulerOS, etc.

## Contents

- `check_cve_2026_31431.sh`: Detection script to check vulnerability status.
- `fix_cve_2026_31431.sh`: Remediation script to apply mitigation by disabling the affected module.

## Usage

### 1. Detection

Run the detection script to check if your system is vulnerable:

```bash
chmod +x check_cve_2026_31431.sh
./check_cve_2026_31431.sh
```

### 2. Remediation

Run the remediation script as root to apply the mitigation. The script will check for impact before proceeding.

```bash
chmod +x fix_cve_2026_31431.sh
sudo ./fix_cve_2026_31431.sh
```

**Note**: The mitigation involves disabling the `algif_aead` kernel module. If your applications rely on `AF_ALG` for AEAD encryption (e.g., some hardware-accelerated crypto tasks), ensure they have fallbacks or are not critical.

## References

- [CVE-2026-31431 (cve.org)](https://www.cve.org/CVERecord?id=CVE-2026-31431)
- [Linux Kernel Patch](https://git.kernel.org/stable/c/a664bf3d603dc3bdcf9ae47cc21e0daec706d7a5)

## Disclaimer

These scripts are provided "as is" without warranty of any kind. Use at your own risk. Always test in a non-production environment first.
