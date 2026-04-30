---
title: "CVE-2026-31431 Linux 内核 algif_aead 漏洞预警"
date: 2026-04-30
tags:
  - 漏洞预警
  - Linux内核
  - 安全
  - CVE-2026-31431
---

# CVE-2026-31431 Linux 内核 algif_aead 漏洞预警

## 漏洞基本信息

| 字段 | 内容 |
|------|------|
| **CVE ID** | CVE-2026-31431 |
| **标题** | crypto: algif_aead - Revert to operating out-of-place |
| **发布机构** | kernel.org |
| **严重程度** | HIGH (7.8) |
| **CVSS 3.1 向量** | CVSS:3.1/AV:L/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H |
| **发布日期** | 2026-04-22 |
| **更新日期** | 2026-04-27 |

## 漏洞描述

在 Linux 内核的 `crypto: algif_aead` 模块中发现一个安全漏洞。该漏洞源于对 commit `72548b093ee3` 的修改，该提交引入了 in-place（原地）加密操作模式。

**问题核心**：在 `algif_aead` 中，source（源）和 destination（目标）来自不同的内存映射（mappings），对它们进行 in-place 操作没有任何性能收益，反而增加了不必要的复杂性，可能导致内存安全问题。

**修复方案**：回退到 out-of-place（异地）操作模式，移除所有为 in-place 操作添加的复杂代码，直接复制关联数据（Associated Data）。

## 受影响版本

### Linux 内核

| 版本状态 | 版本范围 |
|----------|----------|
| **受影响** | kernel 4.14 及以上 |
| **不受影响** | 4.14 之前版本 |
| **不受影响** | 6.18.22 及后续版本 |
| **不受影响** | 6.19.12 及后续版本 |
| **不受影响** | 7.0 及后续版本 |

### 有问题提交范围

受影响的代码引入了以下提交范围：

- `72548b093ee38a6d4f2a19e6ef1948ae05c181f7` 到 `fafe0fa2995a0f7073c1c358d7d3145bcc9aedd8`
- `72548b093ee38a6d4f2a19e6ef1948ae05c181f7` 到 `ce42ee423e58dffa5ec03524054c9d8bfd4f6237`
- `72548b093ee38a6d4f2a19e6ef1948ae05c181f7` 到 `a664bf3d603dc3bdcf9ae47cc21e0daec706d7a5`

## CVSS 评分分析

| 指标 | 缩写 | 值 | 说明 |
|------|------|-----|------|
| Attack Vector | AV | L | 本地攻击（需本地访问） |
| Attack Complexity | AC | L | 低复杂度 |
| Privileges Required | PR | L | 需要低权限 |
| User Interaction | UI | N | 不需要用户交互 |
| Scope | S | U | 变更不影响其他组件 |
| Confidentiality | C | H | 高影响（可读取敏感数据） |
| Integrity | I | H | 高影响（可修改敏感数据） |
| Availability | A | H | 高影响（可拒绝服务） |

**解释**：攻击者可通过本地访问利用此漏洞，在受影响系统上实现任意代码执行或敏感数据访问。

## 修复补丁

官方已在以下提交中修复：

1. **https://git.kernel.org/stable/c/fafe0fa2995a0f7073c1c358d7d3145bcc9aedd8**
2. **https://git.kernel.org/stable/c/ce42ee423e58dffa5ec03524054c9d8bfd4f6237**
3. **https://git.kernel.org/stable/c/a664bf3d603dc3bdcf9ae47cc21e0daec706d7a5**

## 临时修复方案

如无法立即更新内核，可使用以下临时缓解措施：

### 方法一：禁用 algif_aead 模块

```bash
# 创建配置文件
echo "install algif_aead /bin/false" > /etc/modprobe.d/disable-algif-aead.conf

# 可选：立即卸载模块（如已加载）
rmmod algif_aead 2>/dev/null
```

### 方法二：阻止模块加载

```bash
# 在 /etc/modprobe.d/ 下创建 blacklist 文件
echo "blacklist algif_aead" >> /etc/modprobe.d/blacklist.conf
```

### 方法三：内核命令行参数

在 GRUB 启动参数中添加：

```
modprobe.blacklist=algif_aead
```

## 建议操作

1. **立即评估影响**：确认生产环境是否使用受影响的内核版本
2. **应用临时缓解**：如无法立即更新，先禁用 `algif_aead` 模块
3. **计划内核更新**：将内核更新到 6.18.22+、6.19.12+ 或 7.0+
4. **监控安全公告**：关注 Linux Kernel Security 邮件列表

## 参考链接

- [CVE 官方页面](https://www.cve.org/CVERecord?id=CVE-2026-31431)
- [oss-security 邮件列表](http://www.openwall.com/lists/oss-security/2026/04/29/23)
- [Kernel Patch Archive](https://copy.fail)
- [Linux Kernel Stable Tree](https://git.kernel.org/stable/)

## 相关漏洞

如关注此漏洞，可能也需要关注：

- Linux 内核 crypto 子系统的其他近期修复
- 同日期发布的其他 kernel.org CVE

---

*文档创建时间：2026-04-30*
*信息来源：CVE.org、Linux Kernel Mailing List*
