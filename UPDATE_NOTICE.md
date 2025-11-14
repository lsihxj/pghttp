# 🔧 pghttp v1.0.0 - 安装脚本修复更新

## 更新日期
2025-11-14

## 问题说明

在某些 Windows 系统（特别是使用 GB2312/GBK 编码的系统）上，运行 `install.ps1` 时出现 PowerShell 解析错误：

```
表达式或语句中包含意外的标记"Next"
字符串缺少终止符
```

## 修复内容

### 主要改动
- ✅ 移除所有 Unicode 特殊字符（✓、✗、⚠）
- ✅ 替换为 ASCII 兼容的标记 ([OK], [ERROR], [WARNING])
- ✅ 简化字符串处理，避免编码问题
- ✅ 测试多种 Windows 编码环境

### 改进项
- ✅ 更好的跨系统兼容性
- ✅ 支持 GB2312/GBK/UTF-8 等多种编码
- ✅ 在 PowerShell 5.1 和 7.x 都能正常运行

## 新发布包信息

**文件**: `pghttp-1.0.0-win-x64.zip`  
**大小**: 25.5 KB  
**SHA256**: `7BB0FF79E40147B156DA8EF90FF58B1639DAE7A86AE95FCE722C9BBD23AB5A82`  
**位置**: `release/pghttp-1.0.0-win-x64.zip`

## 用户操作指南

### 如果你还未下载
✅ 直接下载最新的发布包即可，问题已修复。

### 如果你已下载旧版本并遇到错误

#### 选项 1: 重新下载（推荐）
下载最新的 `pghttp-1.0.0-win-x64.zip`，包含所有修复。

#### 选项 2: 只更新安装脚本
从项目中复制新版 `install.ps1` 到你的解压目录，替换旧文件。

#### 选项 3: 手动安装
参考发布包中的 `安装问题修复说明.txt`，按步骤手动安装。

## 功能验证

修复不影响任何功能，只改进了安装脚本的兼容性：
- ✅ 所有 HTTP 功能正常
- ✅ DLL 和 SQL 文件未改动
- ✅ 仅安装脚本文本显示优化

## 测试环境

已在以下环境测试通过：
- ✅ Windows 10 (UTF-8)
- ✅ Windows 11 (UTF-8)
- ✅ Windows Server 2019 (GB2312)
- ✅ PowerShell 5.1
- ✅ PowerShell 7.4

## 安装步骤（无变化）

```powershell
# 1. 解压文件
Expand-Archive pghttp-1.0.0-win-x64.zip

# 2. 进入目录
cd pghttp-1.0.0-win-x64

# 3. 以管理员身份运行
.\install.ps1

# 4. 在 PostgreSQL 中
CREATE EXTENSION pghttp;
```

## 校验和对比

### 旧版本
- SHA256: `8755D90B11535A9D2C8ABE700BA42C06ABA312FD809A9738A90FFFE23695CA20`

### 新版本（当前）
- SHA256: `7BB0FF79E40147B156DA8EF90FF58B1639DAE7A86AE95FCE722C9BBD23AB5A82`

## 附加说明

### 为什么会出现这个问题？
PowerShell 在解析脚本时，会根据系统默认编码读取文件。旧版脚本包含 UTF-8 特殊字符，在 GB2312 编码系统上无法正确解析。

### 如何避免类似问题？
1. PowerShell 脚本使用纯 ASCII 字符
2. 或明确保存为 UTF-8 with BOM
3. 在多种编码环境测试

## 技术支持

如仍遇到问题，请：
1. 查看 `INSTALL_RELEASE.md` 详细安装指南
2. 尝试手动安装方式
3. 检查 PostgreSQL 版本（需要 15.x）

## 文档更新

同步更新的文档：
- ✅ `INSTALL_RELEASE.md` - 添加编码问题说明
- ✅ `安装问题修复说明.txt` - 新增故障排除
- ✅ `BUGFIX_INSTALL_SCRIPT.md` - 详细修复记录

---

**更新类型**: Bug Fix（兼容性）  
**影响范围**: 仅安装脚本  
**功能变化**: 无  
**建议操作**: 如遇到安装错误，请使用最新版本

---

感谢你的反馈，帮助我们改进了跨系统兼容性！🙏
