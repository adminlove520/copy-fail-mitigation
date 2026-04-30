# Changelog

All notable changes to this project will be documented in this file.

## [1.3.1] - 2026-04-30

### Added
- **Manual i18n Override**: Added `--zh` and `--en` command-line flags to all scripts to manually select the interface language.
- Refined argument parsing in `fix.sh` to handle optional flags alongside positional actions.

## [1.3.0] - 2026-04-30

### Optimized
- **Project Structure**: Organized files into `scripts/` and `docs/` directories for better maintainability.
- **Code Refactoring**: Extracted common functions into `scripts/lib_common.sh` to reduce duplication.
- **Robustness**: 
  - Added detection for built-in kernel modules.
  - Improved kernel version parsing.
  - Added ANSI color stripping for log files.
- **Documentation**: Simplified README files and renamed advisory files.

## [1.2.0] - 2026-04-30

### Added
- **i18n Support**: Added internationalization to both `check_cve_2026_31431.sh` and `fix_cve_2026_31431.sh`. The scripts now automatically detect the system language (`zh_CN` for Chinese, default to English).
- Updated documentation with i18n instructions.

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
