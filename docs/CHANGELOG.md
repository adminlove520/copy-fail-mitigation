# Changelog

All notable changes to this project will be documented in this file.

## [2.2.5] - 2026-05-06
### Added
- **Anolis OS Support**: Added native support for Anolis OS (龙蜥) in OS identification logic. It is now correctly identified as `rhel-like`.
- **Improved Compatibility**: Fixed `offline_kernel_download.sh` and `kernel_upgrade.sh` to handle Anolis OS 8.x and higher.

## [2.2.3] - 2026-05-06
### Added
- **Offline Kernel Upgrade**: Added `offline_kernel_download.sh` and `offline_kernel_install.sh` to support kernel patching for intranet/offline hosts, following the logic from the easyUpdate project.

## [2.2.2] - 2026-05-06
### Optimized (Production Rigor)
- **Environment Awareness**: Added container (Docker/LXC) detection; scripts now skip incompatible operations with clear guidance.
- **Safety Pre-checks**: `kernel_upgrade.sh` now checks for `/boot` disk space before proceeding to prevent incomplete installs.
- **Mitigation Hardening**: `fix.sh` now synchronizes changes to `initramfs` (via dracut/update-initramfs) to ensure protection during early boot.
- **Improved Reliability**: Refined module unloading logic to handle "in-use" states gracefully instead of failing.
- **Dependency Fallback**: Enhanced crypto probing to be more resilient to missing environment components.

## [2.2.0] - 2026-05-06
### Added
- **Kernel Upgrade Integration**: Added `upgrade` action to `fix.sh` to support permanent remediation via OS-specific package managers (dnf/yum/apt).
- **Built-in Component Warning**: Detection script now explicitly warns if `algif_aead` is built-in and recommends a kernel upgrade.
- **Improved OS Detection**: Enhanced `lib_common.sh` for better recognition of Rocky Linux, openEuler, and specific Xinchuang versions.
- **Documentation**: Updated READMEs to reflect the transition from a mitigation-only toolkit to a full remediation suite.

## [2.1.0] - 2026-04-30

### Fixed (Stability & Performance)
- **Anti-Hang Mechanism**: Re-implemented the unprivileged probe to be completely independent of shell environment sourcing or `su -` login shells, which were causing hangs on some distributions.
- **Double Timeout Protection**: 
  - Added a process-level `timeout` (Bash).
  - Added a socket-level `settimeout` (Python).
- **Asynchronous Logging**: Logging now runs in the background to prevent disk I/O from blocking script execution.
- **Robustness**: Refined the `nobody` user transition and log file permission handling for restricted environments.

## [2.0.0] - 2026-04-30

### Enhanced (Deep Verification)
- **Multi-Vector Probing**: Detection and verification now test multiple cryptographic interfaces (`aead`, `hash`, `skcipher`) and specific complex AEAD bindings used in real exploits.
- **Improved Reporting**: Detailed per-interface status reporting in `check.sh` and `verify_active.sh`.
- **Logic Refinement**: Unified the probing logic into `lib_common.sh` for consistency across all tools.
- **Safety**: Improved user switching and timeout handling for more reliable probing on restricted systems.

## [1.9.1] - 2026-04-30

### Fixed
- **Hanging Issue**: Fixed a critical bug where `check.sh` and `fix.sh` could hang during security checks on certain systems (e.g., Ubuntu 24.04). Replaced external `su`/`runuser` calls with an internal Python-based privilege dropping mechanism.
- **Improved Stability**: Added `timeout` to all external security commands and unified the unprivileged crypto check logic.

## [1.9.0] - 2026-04-30

### Optimized (Security & Reliability)
- **Robust Verification**: Improved the functional check logic to handle permission errors and kernel hangs more gracefully.
- **Log Management**: Standardized log file creation and permission handling across all scripts.

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
