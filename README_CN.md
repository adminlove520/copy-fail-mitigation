# CVE-2026-31431 (Copy Fail) 漏洞缓解工具包

这是一个针对 Linux 内核本地提权漏洞 **CVE-2026-31431 (Copy Fail)** 的综合检测与缓解工具包。

## 目录结构

```text
.
├── scripts/
│   ├── check.sh        # 检测脚本 (支持 i18n)
│   ├── fix.sh          # 修复/回滚脚本 (支持 i18n)
│   └── lib_common.sh   # 通用函数库
├── docs/
│   ├── advisory_zh.md  # 漏洞预警详细文档 (中文)
│   └── CHANGELOG.md    # 更新日志
├── README.md           # 英文说明
└── README_CN.md        # 本文档
```

## 功能特点

- **多维检测**: 结合内核版本比对与发行版补丁（Backports）特征。
- **内核内置识别**: 自动检测受影响组件是否已编译进内核（Built-in），防止缓解措施失效。
- **安全修复**: 执行前进行影响评估，支持一键回滚。
- **国际化 (i18n)**: 自动识别系统语言（中/英），支持使用 `--zh` 或 `--en` 参数强制指定。
- **广泛兼容**: 支持 x86/ARM 架构，兼容通用发行版及信创操作系统（麒麟、统信、欧拉等）。

3. `verify_active.sh`: 主动闭环验证脚本 (新增)。
   - 自动创建一个临时普通用户 (`cve_verify_tmp`)。
   - 模拟漏洞利用脚本的攻击路径（非破坏性测试）。
   - 验证完成后自动清理用户，确保系统洁净。

## 使用指引

### 1. 运行检测
```bash
bash scripts/check.sh [--zh|--en]
```

### 2. 应用缓解措施 (推荐)
```bash
sudo bash scripts/fix.sh apply [-y] [--zh|--en]
```

### 3. 撤销修复 (回滚)
```bash
sudo bash scripts/fix.sh rollback [--zh|--en]
```

### 4. 主动闭环验证 (高可靠)
如果需要通过模拟真实攻击路径来验证修复效果：
```bash
sudo bash scripts/verify_active.sh
```

## 免责声明
本工具仅供安全应急与研究使用。在生产环境操作前请务必进行充分测试。
