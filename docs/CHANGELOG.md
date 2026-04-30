# Changelog

All notable changes to this project will be documented in this file.

## [1.8.0] - 2026-04-30

### Optimized (UI & UX)
- **Professional UI**: Added an ASCII art banner and a structured "Step-by-Step" progress indicator to all scripts.
- **Enhanced Readability**: Standardized color-coded status reporting and final result summaries.
- **Improved Robustness**:
  - Silenced logging errors when running as unprivileged users (e.g., in `verify_active.sh`).
  - Refined the "Final Verdict" logic for better clarity.
- **Verified on WSL**: Fully tested on WSL2 (Kali Linux) to ensure compatibility with modern environments.

## [1.7.0] - 2026-04-30

### Optimized (Production Ready)
- **Security & Reliability**:
  - Implemented `trap` in `verify_active.sh` for guaranteed cleanup of temporary users and scripts even if interrupted.
  - Switched to `mktemp` for safer temporary file handling.
  - Added comprehensive dependency checks (`check_deps`) for all required system binaries.
- **Enhanced Visibility**:
  - Added detection of active security modules (SELinux/AppArmor) to provide context on why an exploit might be blocked despite a vulnerable kernel.
  - Improved logging with ANSI color stripping for file-based logs.
- **Code Refactoring**:
  - Centralized OS identification and functional crypto checking in `lib_common.sh`.
  - Standardized versioning and headers across all scripts.
- **Exploit Analysis Update**: Optimized socket probing logic to match the exact sequence found in real-world exploits.

## [1.6.0] - 2026-04-30

### Added
- **Active Verification Script (`verify_active.sh`)**: Implemented an automated end-to-end verification tool.
  - Creates a temporary user (`cve_verify_tmp`).
  - Executes a non-destructive version of the AF_ALG exploit path (targeting the exact socket/bind used in real exploits).
  - Automatically cleans up the temporary user account and home directory.
- Updated `lib_common.sh` with `run_active_test` helper.

## [1.5.0] - 2026-04-30

### Optimized (Based on Exploit Analysis)
- **Unprivileged Access Check**: The detection script now specifically checks if a **non-privileged user** (e.g., `nobody`) can create AF_ALG sockets. This is the exact initial step required by the exploit.
- **Broader Mitigation**: The remediation script now also disables `algif_hash` and `algif_skcipher` as a defense-in-depth measure, as complex AEAD algorithms used in exploits often rely on these.
- **Rigorous Verdict**: Improved the final result logic:
  - `SAFE`: Kernel version not affected.
  - `LOW RISK`: Kernel vulnerable but interface restricted (e.g., via existing security policies).
  - `VULNERABLE`: Direct exploit path confirmed.
- **Code Hardening**: Replaced `accept()`-only checks with full `socket(38, 5, 0).bind()` tests as seen in the exploit.

## [1.4.0] - 2026-04-30

### Optimized
- **Functional Verification**: Added "Closed-loop Verification" logic using Python/Perl to test if the AF_ALG interface is actually blocked. This ensures the mitigation is *effective*, not just *configured*.
- **Enhanced Compatibility**:
  - Improved OS identification using `ID_LIKE` for better coverage of Xinchuang OS (Kylin, UOS, openEuler, Anolis).
  - Added explicit backport patch detection for specific Xinchuang versions and general RHEL/Ubuntu kernels.
- **Workflow**: Automated the verification step as part of the remediation process.

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
