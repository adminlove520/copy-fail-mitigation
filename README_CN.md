# CVE-2026-31431 (Copy Fail) 漏洞综合治理工具包

这是一个针对 Linux 内核本地提权漏洞 **CVE-2026-31431 (Copy Fail)** 的深度检测、缓解与永久修复工具包。

## 目录结构

```text
.
├── scripts/
│   ├── check.sh          # 深度多维检测脚本 (支持 i18n)
│   ├── fix.sh            # 缓解措施脚本 (模块阻断，支持 i18n)
│   ├── kernel_upgrade.sh # 永久修复脚本 (内核升级，支持 i18n)
│   ├── verify_active.sh  # 主动闭环审计脚本 (支持 i18n)
│   └── lib_common.sh     # 通用函数库与 OS 识别逻辑
├── docs/
│   ├── advisory_zh.md    # 漏洞预警详细文档 (中文)
│   └── CHANGELOG.md      # 更新日志
├── README.md             # 英文说明
└── README_CN.md          # 本文档
```

## 核心功能

- **深度检测**: 结合内核版本、发行版补丁（Backports）以及真实的 Socket 接口探测。
- **内核内置识别**: 针对内置组件（Built-in）发出强力预警，提示 `fix.sh` 缓解措施的局限性。
- **解耦治理策略**:
  - **临时缓解 (`fix.sh`)**: 通过 `modprobe` 禁用受影响的内核模块（aead/hash/skcipher）。
  - **永久修复 (`kernel_upgrade.sh`)**: 自动识别操作系统家族，通过包管理器在线升级内核。
  - **离线修复 (`offline_kernel_*.sh`)**: 针对内网主机，支持从联网主机预下载包并离线安装。
- **主动审计**: 模拟真实 Exploit 攻击路径，确保防护真正生效。

## 使用指引

### 1. 运行风险评估
```bash
bash scripts/check.sh
```

### 2. 应用临时缓解 (推荐作为第一步)
```bash
sudo bash scripts/fix.sh apply
```

### 3. 执行内核安全升级 (彻底修复)

#### A. 联网主机 (在线升级)
```bash
sudo bash scripts/kernel_upgrade.sh
```

#### B. 内网主机 (离线升级)
1. **在联网主机上** (需与目标主机 OS 一致):
   ```bash
   bash scripts/offline_kernel_download.sh
   ```
2. **拷贝** 整个项目目录到内网主机。
3. **在内网主机上**:
   ```bash
   sudo bash scripts/offline_kernel_install.sh
   ```

### 4. 主动审计验证
```bash
sudo bash scripts/verify_active.sh
```

## 免责声明
本工具仅供安全应急与研究使用。内核升级涉及系统稳定性，在生产环境操作前请务必进行充分测试并做好备份。
