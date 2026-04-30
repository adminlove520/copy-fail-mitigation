# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-04-30

### Optimized
- Improved kernel version parsing in `check_cve_2026_31431.sh`.
- Added heuristic check for distro-specific patches (Ubuntu/RHEL).
- Added logic to identify active users of `algif_aead` via `lsof`.
- Added logging functionality in detection script.
- Added `rollback` feature in `fix_cve_2026_31431.sh`.
- Added Chinese documentation (`README_CN.md`).

## [1.0.0] - 2026-04-30

### Added
- Initial release of CVE-2026-31431 (Copy Fail) mitigation toolkit.
- `check_cve_2026_31431.sh`: Detection script with kernel version and mitigation status check.
- `fix_cve_2026_31431.sh`: Remediation script to disable `algif_aead` module.
- Support for x86 and ARM architectures.
- Compatibility with regular Linux distributions and Xinchuang (信创) operating systems.
- Comprehensive README documentation.
